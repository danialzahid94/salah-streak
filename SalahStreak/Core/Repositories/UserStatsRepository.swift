import Foundation
import SwiftData

final class UserStatsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchOrCreate() throws -> UserStats {
        let descriptor = FetchDescriptor<UserStats>()
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let stats = UserStats()
        context.insert(stats)
        return stats
    }

    func fetchOrCreateSettings() throws -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let settings = UserSettings()
        context.insert(settings)
        return settings
    }
}
