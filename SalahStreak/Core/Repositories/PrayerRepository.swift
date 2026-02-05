import Foundation
import SwiftData

final class PrayerRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func insert(_ entry: PrayerEntry) {
        context.insert(entry)
    }

    func delete(_ entry: PrayerEntry) {
        context.delete(entry)
    }

    func fetchEntries(for date: Date) throws -> [PrayerEntry] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<PrayerEntry>(
            predicate: #Predicate { $0.scheduledDate >= startOfDay && $0.scheduledDate < endOfDay }
        )
        return try context.fetch(descriptor)
    }
}
