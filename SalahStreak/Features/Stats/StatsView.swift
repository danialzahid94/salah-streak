import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatsViewModel()

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear(context: modelContext)
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacingSmall) {
            StatCard(title: "Current Streak", value: "\(viewModel.summaryStats.currentStreak)", icon: "flame.fill", color: .orange)
            StatCard(title: "Best Streak",    value: "\(viewModel.summaryStats.bestStreak)",    icon: "trophy.fill",  color: .yellow)
            StatCard(title: "Total Prayers",  value: "\(viewModel.summaryStats.totalPrayers)",  icon: "heart.fill",   color: .red)
            StatCard(title: "Freezes",        value: "\(viewModel.summaryStats.freezesAvailable)", icon: "snowflake", color: .blue)
        }
    }

    // MARK: - Weekly Activity Grid

    private var weeklyActivityGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.system(size: 17, weight: .semibold))

            // Day-label header row
            HStack(spacing: 4) {
                Color.clear.frame(width: 52)
                ForEach(0..<7, id: \.self) { i in
                    Text(viewModel.dayLabels.indices.contains(i) ? viewModel.dayLabels[i] : "")
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
                        let status = viewModel.weeklyGrid.indices.contains(dayIndex) && viewModel.weeklyGrid[dayIndex].indices.contains(prayerIdx) 
                            ? viewModel.weeklyGrid[dayIndex][prayerIdx] 
                            : .noData
                        ActivityCell(status: status)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: Theme.stateDone,    label: "Done")
                LegendItem(color: Theme.stateQada,    label: "Qaza")
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

            ForEach(viewModel.prayerBreakdown) { item in
                HStack {
                    Image(systemName: item.prayer.icon)
                        .foregroundStyle(Theme.stateActive)
                        .frame(width: 24)
                    Text(item.prayer.displayName)
                    Spacer()
                    Text("\(item.count)")
                        .font(.system(size: 15, weight: .semibold))
                }
                .padding(.vertical, 6)
            }
        }
        .padding(Theme.spacing)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

// MARK: - Supporting Types

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
        case .qada:      return Theme.stateQada
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
