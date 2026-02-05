import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date) private var logs: [DailyLog]
    @Query private var allStats: [UserStats]

    private var stats: UserStats? { allStats.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingLarge) {
                    summaryCards
                    weeklyActivityGrid
                    prayerBreakdown
                }
                .padding(.horizontal, Theme.spacing)
                .padding(.top, Theme.spacingSmall)
            }
            .background(.background)
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacingSmall) {
            StatCard(title: "Current Streak", value: "\(stats?.currentStreak ?? 0)", icon: "flame.fill", color: .orange)
            StatCard(title: "Best Streak",    value: "\(stats?.bestStreak ?? 0)",    icon: "trophy.fill",  color: .yellow)
            StatCard(title: "Total Prayers",  value: "\(stats?.totalPrayers ?? 0)",  icon: "heart.fill",   color: .red)
            StatCard(title: "Freezes",        value: "\(stats?.freezesAvailable ?? 0)", icon: "snowflake", color: .blue)
        }
    }

    // MARK: - Weekly Activity Grid

    private var weeklyActivityGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.system(size: 17, weight: .semibold))

            let grid = computeWeeklyGrid()
            let dayLabels = computeDayLabels()

            // Day-label header row
            HStack(spacing: 4) {
                Color.clear.frame(width: 52)
                ForEach(0..<7, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }

            // One row per prayer
            ForEach(PrayerType.allCases) { prayer in
                HStack(spacing: 4) {
                    Text(prayer.displayName)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .leading)

                    ForEach(0..<7, id: \.self) { dayIndex in
                        let prayerIdx = PrayerType.allCases.firstIndex(of: prayer) ?? 0
                        ActivityCell(status: grid[dayIndex][prayerIdx])
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: Theme.stateDone,    label: "Done")
                LegendItem(color: Theme.stateMissed,  label: "Missed")
                LegendItem(color: Color(.systemGray4), label: "Upcoming")
                LegendItem(color: Color(.systemGray6), label: "No data")
            }
            .padding(.top, 4)
        }
        .padding(Theme.spacing)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    // MARK: - Prayer Breakdown

    private var prayerBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prayer Breakdown")
                .font(.system(size: 17, weight: .semibold))

            ForEach(PrayerType.allCases) { prayer in
                let total = prayerCount(for: prayer)
                HStack {
                    Image(systemName: prayer.icon)
                        .foregroundStyle(Theme.stateActive)
                        .frame(width: 24)
                    Text(prayer.displayName)
                    Spacer()
                    Text("\(total)")
                        .font(.system(size: 15, weight: .semibold))
                }
                .padding(.vertical, 6)
            }
        }
        .padding(Theme.spacing)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    // MARK: - Helpers

    /// Returns a 7-element array (Mon→Sun), each containing 5 CellStatus values (one per prayer).
    private func computeWeeklyGrid() -> [[CellStatus]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        return (0..<7).map { offset -> [CellStatus] in
            let day = cal.date(byAdding: .day, value: -(6 - offset), to: today)!
            let log = logs.first { cal.startOfDay(for: $0.date) == day }

            return PrayerType.allCases.map { prayer -> CellStatus in
                guard let entry = log?.entries.first(where: { $0.prayer == prayer }) else {
                    return .noData
                }
                switch entry.status {
                case .done:    return .done
                case .missed:  return .missed
                default:       return .upcoming
                }
            }
        }
    }

    private func computeDayLabels() -> [String] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: -(6 - offset), to: today)!
            return fmt.string(from: day)
        }
    }

    private func prayerCount(for prayer: PrayerType) -> Int {
        logs.reduce(0) { sum, log in
            sum + log.entries.filter { $0.prayer == prayer && $0.status == .done }.count
        }
    }
}

// MARK: - Supporting Types

enum CellStatus {
    case done, missed, upcoming, noData
}

private struct ActivityCell: View {
    let status: CellStatus

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(cellColor)
    }

    private var cellColor: Color {
        switch status {
        case .done:      return Theme.stateDone
        case .missed:    return Theme.stateMissed
        case .upcoming:  return Color(.systemGray4)
        case .noData:    return Color(.systemGray6)
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 24, weight: .bold))
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}
