import Foundation
import SwiftUI
import SwiftData
import Combine

@Observable
final class BadgesViewModel {
    // MARK: - Published State
    var badges: [Badge] = []
    var selectedBadge: Badge?
    
    // MARK: - Private
    private var modelContext: ModelContext?
    private var stats: UserStats?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Badge Definitions
    private static let badgeDefinitions: [(id: String, title: String, description: String, icon: String)] = [
        ("first_prayer",  "First Prayer",  "Complete your very first prayer.",             "star"),
        ("perfect_day",   "Perfect Day",   "Complete all 5 prayers in a single day.",     "checkmark.seal"),
        ("week_warrior",  "Week Warrior",  "Maintain a 7-day streak.",                    "flame"),
        ("month_master",  "Month Master",  "Maintain a 30-day streak.",                   "trophy"),
        ("early_bird",    "Early Bird",    "Complete 10 Fajr prayers on time.",           "sunrise"),
        ("consistent",    "Consistent",    "Complete 50 total prayers.",                  "heart.fill"),
    ]
    
    // MARK: - Lifecycle
    
    func onAppear(context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        guard let context = modelContext else { return }
        
        let statsDescriptor = FetchDescriptor<UserStats>()
        self.stats = try? context.fetch(statsDescriptor).first
        
        computeBadges()
    }
    
    // MARK: - Computations
    
    private func computeBadges() {
        let unlockedBadgeIds = stats?.badgesUnlocked ?? []
        
        badges = Self.badgeDefinitions.map { definition in
            Badge(
                id: definition.id,
                title: definition.title,
                description: definition.description,
                icon: definition.icon,
                isUnlocked: unlockedBadgeIds.contains(definition.id)
            )
        }
    }
    
    // MARK: - Public Methods
    
    func selectBadge(_ badge: Badge) {
        selectedBadge = badge
    }
    
    func deselectBadge() {
        selectedBadge = nil
    }
    
    func refresh() {
        loadData()
    }
}
