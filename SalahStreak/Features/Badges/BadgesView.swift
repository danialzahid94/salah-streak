import SwiftUI
import SwiftData

struct BadgesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allStats: [UserStats]

    @State private var selectedBadge: Badge?

    private var badges: [Badge] {
        guard let stats = allStats.first else { return allBadgeDefinitions.map { badge(from: $0, unlocked: false) } }
        return allBadgeDefinitions.map { badge(from: $0, unlocked: stats.badgesUnlocked.contains($0.id)) }
    }

    var body: some View {
        NavigationStack {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacingSmall) {
                ForEach(badges) { badge in
                    BadgeTile(badge: badge)
                        .onTapGesture { selectedBadge = badge }
                }
            }
            .padding(Theme.spacing)
            .navigationTitle("Badges")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailView(badge: badge)
        }
    }

    // MARK: - Helpers

    private static let definitions: [(id: String, title: String, description: String, icon: String)] = [
        ("first_prayer",  "First Prayer",  "Complete your very first prayer.",             "star"),
        ("perfect_day",   "Perfect Day",   "Complete all 5 prayers in a single day.",     "checkmark.seal"),
        ("week_warrior",  "Week Warrior",  "Maintain a 7-day streak.",                    "flame"),
        ("month_master",  "Month Master",  "Maintain a 30-day streak.",                   "trophy"),
        ("early_bird",    "Early Bird",    "Complete 10 Fajr prayers on time.",           "sunrise"),
        ("consistent",    "Consistent",    "Complete 50 total prayers.",                  "heart.fill"),
    ]

    private var allBadgeDefinitions: [(id: String, title: String, description: String, icon: String)] { Self.definitions }

    private func badge(from def: (id: String, title: String, description: String, icon: String), unlocked: Bool) -> Badge {
        Badge(id: def.id, title: def.title, description: def.description, icon: def.icon, isUnlocked: unlocked)
    }
}

// MARK: - BadgeTile

private struct BadgeTile: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: badge.icon)
                .font(.system(size: 36))
                .foregroundStyle(badge.isUnlocked ? Theme.accent : .gray)
            Text(badge.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(badge.isUnlocked ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .background(badge.isUnlocked ? Theme.cardBG : Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(badge.isUnlocked ? Theme.accent.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - BadgeDetailView

private struct BadgeDetailView: View {
    let badge: Badge
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.spacingLarge) {
                Spacer()
                Image(systemName: badge.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(badge.isUnlocked ? Theme.accent : .gray)
                Text(badge.title)
                    .font(.system(size: 24, weight: .bold))
                Text(badge.description)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text(badge.isUnlocked ? "Unlocked" : "Locked")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(badge.isUnlocked ? Theme.stateDone : Theme.stateFuture)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(badge.isUnlocked ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
