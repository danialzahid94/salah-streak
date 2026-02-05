import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date) private var logs: [DailyLog]
    @Query private var allStats: [UserStats]

    private var stats: UserStats? { allStats.first }
    private var weeklyData: [DayStats] { computeWeeklyData() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingLarge) {
                    summaryCards
                    weeklyChart
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

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.system(size: 17, weight: .semibold))

            Chart(weeklyData) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Prayers", day.count)
                )
                .foregroundStyle(day.color)
            }
            .chartYAxis {
                AxisMarks(values: [0, 1, 2, 3, 4, 5])
            }
            .frame(height: 160)
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

    private func computeWeeklyData() -> [DayStats] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { offset -> DayStats in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let log = logs.first { cal.startOfDay(for: $0.date) == day }
            let count = log?.completedCount ?? 0
            let label = DateFormatter.dayLabel.string(from: day)
            let color: Color = count == 5 ? Theme.stateDone : count > 0 ? .orange : Theme.stateMissed
            return DayStats(label: label, count: count, color: color)
        }
    }

    private func prayerCount(for prayer: PrayerType) -> Int {
        logs.reduce(0) { sum, log in
            sum + log.entries.filter { $0.prayer == prayer && $0.status == .done }.count
        }
    }
}

// MARK: - Supporting Types

struct DayStats: Identifiable {
    let label: String
    let count: Int
    let color: Color
    var id: String { label }
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

private extension DateFormatter {
    static let dayLabel: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()
}
