import WidgetKit
import AppIntents
import Foundation

struct SalahStreakWidgetEntry: TimelineEntry {
    let date: Date
    let prayerData: WidgetPrayerData?
}

struct SalahStreakWidgetProvider: AppIntentTimelineProvider {
    typealias Intent = SalahStreakWidgetConfig
    typealias Entry  = SalahStreakWidgetEntry

    func recommendations() -> [AppIntentRecommendation<SalahStreakWidgetConfig>] {
        []
    }

    func placeholder(in context: Context) -> SalahStreakWidgetEntry {
        SalahStreakWidgetEntry(date: Date(), prayerData: nil)
    }

    func snapshot(for configuration: SalahStreakWidgetConfig, in context: Context) async -> SalahStreakWidgetEntry {
        SalahStreakWidgetEntry(date: Date(), prayerData: WidgetPrayerData.shared)
    }

    func timeline(for configuration: SalahStreakWidgetConfig, in context: Context) async -> Timeline<SalahStreakWidgetEntry> {
        let now = Date()
        let data = WidgetPrayerData.shared

        var dates: [Date] = [now]
        if let prayers = data?.prayers {
            for p in prayers {
                if p.windowEnd > now    { dates.append(p.windowEnd) }
                if p.scheduledTime > now { dates.append(p.scheduledTime) }
            }
        }
        // Fallback: refresh every 15 minutes
        dates.append(now.addingTimeInterval(900))

        let entries = dates.sorted().map { SalahStreakWidgetEntry(date: $0, prayerData: data) }
        return Timeline(entries: entries, policy: .atEnd)
    }
}
