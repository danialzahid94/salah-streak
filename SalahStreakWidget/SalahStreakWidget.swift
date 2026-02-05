import WidgetKit
import SwiftUI

struct SalahStreakWidget: Widget {
    let kind: String = "com.danial.SalahStreak.widget"

    var body: some WidgetContent {
        Intent<SalahStreakWidgetConfiguration>()
            .provider(SalahStreakWidgetProvider())
            .view(SalahStreakWidgetEntryView.init)
            .modifiers {
                $0.widgetURL(nil)
            }
    }
}

// MARK: - Widget Bundle

@main
struct SalahStreakWidgetBundle: WidgetBundle {
    var body: some WidgetContent {
        SalahStreakWidget()
    }
}
