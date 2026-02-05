import WidgetKit
import SwiftUI
import AppIntents

/// Empty configuration intent — our widget has no user-configurable parameters.
struct SalahStreakWidgetConfig: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "SalahStreak Widget"
}

struct SalahStreakWidget: Widget {
    let kind: String = "com.danial.SalahStreak.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SalahStreakWidgetConfig.self, provider: SalahStreakWidgetProvider()) { entry in
            SalahStreakWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
    }
}

@main
struct SalahStreakWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalahStreakWidget()
    }
}
