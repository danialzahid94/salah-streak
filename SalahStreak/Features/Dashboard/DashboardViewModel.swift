import Foundation
import SwiftUI
import SwiftData

@Observable
final class DashboardViewModel {
    // MARK: - State
    var prayerCards: [PrayerCardModel] = []
    var currentStreak: Int = 0
    var completedCount: Int = 0
    var newBadges: [Badge] = []

    // MARK: - Private
    private var dailyLog: DailyLog?
    private var userStats: UserStats?
    private var userSettings: UserSettings?
    private var modelContext: ModelContext?
    private var timer: Timer?

    private let prayerTimeService  = DependencyContainer.shared.prayerTimeService
    private let notificationService = DependencyContainer.shared.notificationService
    private let streakService      = DependencyContainer.shared.streakService
    private let badgeService       = DependencyContainer.shared.badgeService

    // MARK: - Lifecycle

    func onAppear(context: ModelContext) {
        self.modelContext = context
        loadData()
        startTimer()
    }

    func onDisappear() {
        stopTimer()
    }

    // MARK: - Actions

    @MainActor
    func markPrayerDone(_ cardIndex: Int) {
        guard cardIndex < prayerCards.count else { return }
        let card = prayerCards[cardIndex]
        guard card.state != .done else { return }

        // Update the entry
        if let entry = dailyLog?.entries.first(where: { $0.prayer == card.prayer }) {
            entry.status = .done
            entry.performedAt = Date()
            entry.source = .app

            // Cancel remaining notifications for this prayer
            notificationService.cancelNotifications(for: card.prayer, on: Calendar.current.startOfDay(for: Date()))

            // Haptic
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // Update stats
        userStats?.totalPrayers += 1

        // Check badges
        if let stats = userStats, let log = dailyLog {
            newBadges = badgeService.checkAndAwardBadges(stats: stats, dailyLog: log)
        }

        try? modelContext?.save()
        rebuildCards()
    }

    // MARK: - Private

    private func loadData() {
        guard let ctx = modelContext else { return }

        let dailyLogRepo   = DailyLogRepository(context: ctx)
        let statsRepo      = UserStatsRepository(context: ctx)

        self.dailyLog   = try? dailyLogRepo.fetchOrCreate(for: Date())
        self.userStats  = try? statsRepo.fetchOrCreate()
        self.userSettings = try? statsRepo.fetchOrCreateSettings()

        // If no entries yet today, generate them from prayer times
        if dailyLog?.entries.isEmpty == true {
            generateTodayEntries()
        }

        rebuildCards()
        currentStreak = userStats?.currentStreak ?? 0
    }

    private func generateTodayEntries() {
        guard let settings = userSettings, let lat = settings.latitude, let lng = settings.longitude else { return }

        let windows = prayerTimeService.prayerWindows(
            for: Date(),
            latitude: lat,
            longitude: lng,
            method: settings.calculationMethod,
            madhab: settings.madhab
        )

        for w in windows {
            let entry = PrayerEntry(prayer: w.prayer, scheduledDate: w.scheduledTime, windowStart: w.start, windowEnd: w.end)
            entry.dailyLog = dailyLog
            dailyLog?.entries.append(entry)
            modelContext?.insert(entry)
        }

        // Schedule notifications
        notificationService.schedulePrayerNotifications(for: windows, on: Calendar.current.startOfDay(for: Date()))

        try? modelContext?.save()
    }

    private func rebuildCards() {
        let now = Date()
        prayerCards = (dailyLog?.entries ?? []).sorted { $0.scheduledDate < $1.scheduledDate }.map { entry in
            let state: PrayerCardState
            switch entry.status {
            case .done:    state = .done
            case .missed:  state = .missed
            case .pending, .qada:
                if now < entry.windowStart {
                    state = .future
                } else if now > entry.windowEnd {
                    state = .missed
                } else {
                    let remaining = entry.windowEnd.timeIntervalSince(now)
                    state = remaining < 600 ? .warning : .active  // warning if < 10 min left
                }
            }
            return PrayerCardModel(prayer: entry.prayer, state: state, scheduledTime: entry.scheduledDate, windowEnd: entry.windowEnd)
        }
        completedCount = dailyLog?.completedCount ?? 0
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60) { [weak self] _ in
            self?.rebuildCards()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - PrayerCardModel

struct PrayerCardModel {
    let prayer: PrayerType
    let state: PrayerCardState
    let scheduledTime: Date
    let windowEnd: Date
}
