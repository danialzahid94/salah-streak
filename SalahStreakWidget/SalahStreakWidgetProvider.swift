import WidgetKit
import Foundation

struct SalahStreakWidgetEntry: TimelineEntry {
    let date: Date
    let prayerData: WidgetPrayerData?
}

struct SalahStreakWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> SalahStreakWidgetEntry {
        SalahStreakWidgetEntry(date: Date(), prayerData: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SalahStreakWidgetEntry) -> Void) {
        completion(SalahStreakWidgetEntry(date: Date(), prayerData: WidgetPrayerData.shared))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalahStreakWidgetEntry>) -> Void) {
        let now = Date()
        let data = WidgetPrayerData.shared

        // Build refresh times at each prayer window boundary
        var dates: [Date] = [now]
        if let prayers = data?.prayers {
            for p in prayers {
                if p.windowEnd > now { dates.append(p.windowEnd) }
                let scheduled = p.scheduledTime
                if scheduled > now { dates.append(scheduled) }
            }
        }
        // Also refresh every 15 minutes as fallback
        dates.append(now.addingTimeInterval(900))

        let entries = dates.sorted().map { SalahStreakWidgetEntry(date: $0, prayerData: data) }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}
