import Foundation
import SwiftUI
import SwiftData
import WidgetKit

@Observable
final class DashboardViewModel {
    // MARK: - State
    var prayerCards: [PrayerCardModel] = []
    var currentStreak: Int = 0
    var completedCount: Int = 0
    var newBadges: [Badge] = []
    var showQadaSheet: Bool = false
    var qadaCardIndex: Int? = nil

    // MARK: - Private
    private var dailyLog: DailyLog?
    private var userStats: UserStats?
    private var userSettings: UserSettings?
    private var modelContext: ModelContext?
    private var timer: Timer?

    private static var hasRefreshedLocationThisLaunch = false

    private let prayerTimeService  = DependencyContainer.shared.prayerTimeService
    private let notificationService = DependencyContainer.shared.notificationService
    private let streakService      = DependencyContainer.shared.streakService
    private let badgeService       = DependencyContainer.shared.badgeService

    // MARK: - Lifecycle

    func onAppear(context: ModelContext) {
        self.modelContext = context
        loadData()
        startTimer()

        if !DashboardViewModel.hasRefreshedLocationThisLaunch {
            DashboardViewModel.hasRefreshedLocationThisLaunch = true
            Task { [weak self] in
                await self?.refreshLocationIfNeeded()
            }
        }
    }

    func onDisappear() {
        stopTimer()
    }

    // MARK: - Actions

    @MainActor
    func markPrayerDone(_ cardIndex: Int) {
        guard cardIndex < prayerCards.count else { return }
        let card = prayerCards[cardIndex]

        // Tap on a done prayer → undo it
        if card.state == .done {
            undoMarkDone(card.prayer)
            return
        }

        // Tap on a qada prayer → undo it
        if card.state == .qada {
            undoMarkQada(card.prayer)
            return
        }

        // Tap on a missed prayer → show qada confirmation dialog
        if card.state == .missed {
            qadaCardIndex = cardIndex
            showQadaSheet = true
            return
        }

        // Only allow marking done while the prayer window is open
        guard card.state == .active || card.state == .warning else { return }

        if let entry = dailyLog?.entries.first(where: { $0.prayer == card.prayer }) {
            entry.status = .done
            entry.performedAt = Date()
            entry.source = .app

            notificationService.cancelNotifications(for: card.prayer, on: Calendar.current.startOfDay(for: Date()))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        userStats?.totalPrayers += 1

        if let stats = userStats, let log = dailyLog {
            newBadges = badgeService.checkAndAwardBadges(stats: stats, dailyLog: log)
        }

        try? modelContext?.save()
        syncWidgetData()
        rebuildCards()
    }

    @MainActor
    func markPrayerQada(_ cardIndex: Int) {
        guard cardIndex < prayerCards.count else { return }
        let card = prayerCards[cardIndex]

        if let entry = dailyLog?.entries.first(where: { $0.prayer == card.prayer }) {
            entry.status = .qada
            entry.performedAt = Date()

            notificationService.cancelNotifications(for: card.prayer, on: Calendar.current.startOfDay(for: Date()))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        userStats?.totalPrayers += 1

        if let stats = userStats, let log = dailyLog {
            newBadges = badgeService.checkAndAwardBadges(stats: stats, dailyLog: log)
        }

        try? modelContext?.save()
        syncWidgetData()
        rebuildCards()
    }

    private func undoMarkDone(_ prayer: PrayerType) {
        guard let entry = dailyLog?.entries.first(where: { $0.prayer == prayer }) else { return }

        entry.status = .pending
        entry.performedAt = nil
        userStats?.totalPrayers -= 1

        // Reschedule notifications if still within the prayer window
        if entry.windowEnd > Date() {
            let window = PrayerWindow(prayer: prayer, start: entry.windowStart, end: entry.windowEnd, scheduledTime: entry.scheduledDate)
            notificationService.schedulePrayerNotifications(for: [window], on: Calendar.current.startOfDay(for: Date()))
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        try? modelContext?.save()
        syncWidgetData()
        rebuildCards()
    }

    private func undoMarkQada(_ prayer: PrayerType) {
        guard let entry = dailyLog?.entries.first(where: { $0.prayer == prayer }) else { return }

        entry.status = .missed
        entry.performedAt = nil
        userStats?.totalPrayers -= 1

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        try? modelContext?.save()
        syncWidgetData()
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

        // Generate entries on first load; recompute times on subsequent loads
        // so that changes to calculation method / madhab take effect immediately.
        if dailyLog?.entries.isEmpty == true {
            generateTodayEntries()
        } else {
            updateTodayEntryTimes()
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

    private func updateTodayEntryTimes() {
        guard let settings = userSettings, let lat = settings.latitude, let lng = settings.longitude else { return }

        let windows = prayerTimeService.prayerWindows(
            for: Date(),
            latitude: lat,
            longitude: lng,
            method: settings.calculationMethod,
            madhab: settings.madhab
        )

        for entry in dailyLog?.entries ?? [] {
            if let window = windows.first(where: { $0.prayer == entry.prayer }) {
                entry.scheduledDate = window.scheduledTime
                entry.windowStart   = window.start
                entry.windowEnd     = window.end
            }
        }

        // Reschedule notifications for prayers still pending
        let pendingWindows = windows.filter { window in
            (dailyLog?.entries.first(where: { $0.prayer == window.prayer })?.status == .pending) ?? false
        }
        if !pendingWindows.isEmpty {
            notificationService.schedulePrayerNotifications(for: pendingWindows, on: Calendar.current.startOfDay(for: Date()))
        }

        try? modelContext?.save()
    }

    private func rebuildCards() {
        let now = Date()
        prayerCards = (dailyLog?.entries ?? []).sorted { $0.scheduledDate < $1.scheduledDate }.map { entry in
            let state: PrayerCardState
            switch entry.status {
            case .done:    state = .done
            case .missed:  state = .missed
            case .qada:    state = .qada
            case .pending:
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
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.rebuildCards()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func syncWidgetData() {
        let entries = (dailyLog?.entries ?? []).sorted { $0.scheduledDate < $1.scheduledDate }.map {
            WidgetPrayerData.WidgetPrayerEntry(
                prayer: $0.prayer.rawValue,
                status: $0.status.rawValue,
                scheduledTime: $0.scheduledDate,
                windowEnd: $0.windowEnd
            )
        }
        WidgetPrayerData.shared = WidgetPrayerData(
            prayers: entries,
            currentStreak: userStats?.currentStreak ?? 0,
            updatedAt: Date()
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

    @MainActor
    private func refreshLocationIfNeeded() async {
        let locationSvc = DependencyContainer.shared.locationService

        if locationSvc.authorizationStatus == .granted {
            do {
                let coord = try await locationSvc.requestLocation()
                userSettings?.latitude  = coord.latitude
                userSettings?.longitude = coord.longitude

                userSettings?.cityName = await locationSvc.getCityName(for: coord)

                try? modelContext?.save()
                loadData()
                syncWidgetData()
                return
            } catch {
                // Location request timed out — fall through to geocoding retry
            }
        }

        // Retry geocoding with existing coordinates if city is still nil
        if userSettings?.cityName == nil,
           let lat = userSettings?.latitude,
           let lng = userSettings?.longitude {
            userSettings?.cityName = await locationSvc.getCityName(for: Coordinate(latitude: lat, longitude: lng))
            try? modelContext?.save()
        }
    }
}

// MARK: - PrayerCardModel

struct PrayerCardModel {
    let prayer: PrayerType
    let state: PrayerCardState
    let scheduledTime: Date
    let windowEnd: Date
}
