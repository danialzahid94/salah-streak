import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()
    @State private var showBadgeAlert: Badge?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingLarge) {
                    headerSection
                    prayerList
                }
                .padding(.horizontal, Theme.spacing)
                .padding(.top, Theme.spacingSmall)
            }
            .background(.background)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { viewModel.onAppear(context: modelContext) }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: viewModel.newBadges) { _, badges in
            if let badge = badges.first {
                showBadgeAlert = badge
            }
        }
        .sheet(item: $showBadgeAlert) { badge in
            BadgeUnlockView(badge: badge)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Spacer()
            DailyProgressRing(completed: viewModel.completedCount)
            Spacer()
            StreakFlameView(streak: viewModel.currentStreak)
            Spacer()
        }
        .padding(.vertical, Theme.spacingSmall)
    }

    // MARK: - Prayer Cards

    private var prayerList: some View {
        VStack(spacing: Theme.spacingSmall) {
            ForEach(viewModel.prayerCards.indices, id: \.self) { index in
                PrayerCard(model: viewModel.prayerCards[index]) {
                    viewModel.markPrayerDone(index)
                }
            }
        }
    }
}

// MARK: - Badge Unlock Sheet

private struct BadgeUnlockView: View {
    let badge: Badge

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Theme.spacingLarge) {
            Spacer()
            Image(systemName: badge.icon)
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)
            Text("Badge Unlocked!")
                .font(.system(size: 24, weight: .bold))
            Text(badge.title)
                .font(.system(size: 20, weight: .semibold))
            Text(badge.description)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button("Continue") { dismiss() }
                .font(.system(size: 16, weight: .semibold))
                .padding(.vertical, 14)
                .padding(.horizontal, 40)
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer()
        }
    }
}
