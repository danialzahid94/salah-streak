import SwiftUI
import SwiftData

struct BadgesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BadgesViewModel()

    var body: some View {
        NavigationStack {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacingSmall) {
                ForEach(viewModel.badges) { badge in
                    BadgeTile(badge: badge)
                        .onTapGesture { 
                            viewModel.selectBadge(badge)
                        }
                }
            }
            .padding(Theme.spacing)
            .navigationTitle("Badges")
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
        .sheet(item: $viewModel.selectedBadge) { badge in
            BadgeDetailView(badge: badge)
        }
        .onAppear {
            viewModel.onAppear(context: modelContext)
        }
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
