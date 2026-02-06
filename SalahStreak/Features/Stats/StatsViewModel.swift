import Foundation
import SwiftUI
import SwiftData
import Combine

@Observable
final class StatsViewModel {
    // MARK: - Published State
    var summaryStats: SummaryStats = SummaryStats()
    var weeklyGrid: [[CellStatus]] = []
    var dayLabels: [String] = []
    var prayerBreakdown: [PrayerBreakdownItem] = []
    
    // MARK: - Private
    private var modelContext: ModelContext?
    private var logs: [DailyLog] = []
    private var stats: UserStats?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    func onAppear(context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        guard let context = modelContext else { return }
        
        // Fetch all stats
        let statsDescriptor = FetchDescriptor<UserStats>()
        self.stats = try? context.fetch(statsDescriptor).first
        
        // Fetch all logs sorted by date
        let logsDescriptor = FetchDescriptor<DailyLog>(sortBy: [SortDescriptor(\DailyLog.date)])
        self.logs = (try? context.fetch(logsDescriptor)) ?? []
        
        // Compute all derived state
        computeSummaryStats()
        computeWeeklyGrid()
        computeDayLabels()
        computePrayerBreakdown()
    }
    
    // MARK: - Computations
    
    private func computeSummaryStats() {
        summaryStats = SummaryStats(
            currentStreak: stats?.currentStreak ?? 0,
            bestStreak: stats?.bestStreak ?? 0,
            totalPrayers: stats?.totalPrayers ?? 0,
            freezesAvailable: stats?.freezesAvailable ?? 0
        )
    }
    
    private func computeWeeklyGrid() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        weeklyGrid = (0..<7).map { offset -> [CellStatus] in
            let day = cal.date(byAdding: .day, value: -(6 - offset), to: today)!
            let log = logs.first { cal.startOfDay(for: $0.date) == day }
            
            return PrayerType.allCases.map { prayer -> CellStatus in
                guard let entry = log?.safeEntries.first(where: { $0.prayer == prayer }) else {
                    return .noData
                }
                switch entry.status {
                case .done:    return .done
                case .missed:  return .missed
                case .qada:    return .qada
                default:       return .upcoming
                }
            }
        }
    }
    
    private func computeDayLabels() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        
        dayLabels = (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: -(6 - offset), to: today)!
            return fmt.string(from: day)
        }
    }
    
    private func computePrayerBreakdown() {
        prayerBreakdown = PrayerType.allCases.map { prayer in
            let count = logs.reduce(0) { sum, log in
                sum + log.safeEntries.filter { $0.prayer == prayer && ($0.status == .done || $0.status == .qada) }.count
            }
            return PrayerBreakdownItem(prayer: prayer, count: count)
        }
    }
    
    // MARK: - Public Methods
    
    func refresh() {
        loadData()
    }
}

// MARK: - Supporting Types

struct SummaryStats {
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var totalPrayers: Int = 0
    var freezesAvailable: Int = 0
}

struct PrayerBreakdownItem: Identifiable {
    let id = UUID()
    let prayer: PrayerType
    let count: Int
}
