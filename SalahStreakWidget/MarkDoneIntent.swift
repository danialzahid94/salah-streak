import AppIntents
import WidgetKit
import Foundation

/// Interactive widget intent to mark a prayer as done directly from the widget.
struct MarkDoneIntent: AppIntent {
    static var title = LocalizedStringKey("Mark Prayer Done")

    @Parameter(title: "Prayer")
    var prayer: String

    func perform() async throws -> some IntentResult {
        guard var data = WidgetPrayerData.shared else { return }

        var updated = data.prayers
        if let idx = updated.firstIndex(where: { $0.prayer == prayer && $0.status == "pending" }) {
            updated[idx] = WidgetPrayerData.WidgetPrayerEntry(
                prayer: updated[idx].prayer,
                status: "done",
                scheduledTime: updated[idx].scheduledTime,
                windowEnd: updated[idx].windowEnd
            )
        }

        WidgetPrayerData.shared = WidgetPrayerData(
            prayers: updated,
            currentStreak: data.currentStreak,
            updatedAt: Date()
        )

        WidgetCenter.shared.reloadAllTimelines()
        return
    }
}

struct SalahStreakWidgetConfiguration: WidgetConfigurationIntent {
    static var title = LocalizedStringKey("SalahStreak Widget")
    static var description = IntentDescription("Shows your prayer status and streak.")
}
