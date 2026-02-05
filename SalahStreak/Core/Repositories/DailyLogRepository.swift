import Foundation
import SwiftData

final class DailyLogRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchOrCreate(for date: Date) throws -> DailyLog {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let log = DailyLog(date: startOfDay)
        context.insert(log)
        return log
    }

    func fetchLogs(from startDate: Date, to endDate: Date) throws -> [DailyLog] {
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date >= startDate && $0.date <= endDate },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }
}
