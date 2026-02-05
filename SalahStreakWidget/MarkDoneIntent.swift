import AppIntents
import SwiftUI
import WidgetKit

/// Interactive widget intent to mark a prayer as done directly from the widget.
struct MarkDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Prayer Done"

    @Parameter(title: "Prayer")
    var prayer: String

    init() {}

    init(prayer: String) {
        self.prayer = prayer
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let data = WidgetPrayerData.shared else {
            return .result(dialog: "No prayer data available")
        }

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
        return .result(dialog: "\(prayer.capitalized) prayer marked as done")
    }
}
