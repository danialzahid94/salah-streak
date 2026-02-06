import SwiftUI
import WidgetKit
import AppIntents

struct SalahStreakWidgetEntryView: View {
    var entry: SalahStreakWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        content
            .containerBackground(Color(.systemBackground), for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:       SmallWidgetView(data: entry.prayerData)
        case .systemMedium:      MediumWidgetView(data: entry.prayerData)
        case .accessoryCircular: CircularProgressWidget(data: entry.prayerData)
        case .accessoryInline:   InlinePrayerWidget(data: entry.prayerData)
        default:                 SmallWidgetView(data: entry.prayerData)
        }
    }
}

// MARK: - Small Widget

private struct SmallWidgetView: View {
    let data: WidgetPrayerData?

    var body: some View {
        VStack(spacing: 8) {
            if let current = data?.currentPrayer {
                Button(intent: MarkDoneIntent(prayer: current.prayer)) {
                    VStack(spacing: 2) {
                        Text(current.prayer.capitalized)
                            .font(.system(size: 20, weight: .bold))
                        Text("ends \(timeString(until: current.windowEnd))")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("Tap to mark done")
                            .font(.system(size: 11))
                            .foregroundStyle(.blue)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text("All Done")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.green)
            }

            Divider()

            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(data?.currentStreak ?? 0)")
                    .font(.system(size: 16, weight: .bold))

                Spacer()

                Text("\(data?.completedCount ?? 0)/5")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.blue)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget

private struct MediumWidgetView: View {
    let data: WidgetPrayerData?

    var body: some View {
        HStack(spacing: 0) {
            // Left: streak + progress
            VStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.orange)
                Text("\(data?.currentStreak ?? 0)")
                    .font(.system(size: 28, weight: .bold))
                Text("streak")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)

            Divider()

            // Right: prayer list — each row is tappable via intent
            VStack(alignment: .leading, spacing: 4) {
                ForEach(data?.prayers ?? [], id: \.prayer) { p in
                    Button(intent: MarkDoneIntent(prayer: p.prayer)) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(statusColor(p.status))
                                .frame(width: 10, height: 10)
                            Text(p.prayer.capitalized)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            if p.status == "done" {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 12))
                            } else if p.status == "qada" {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.yellow)
                                    .font(.system(size: 12))
                            } else {
                                Text(shortTime(p.scheduledTime))
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 14)
        }
        .padding()
    }
}

// MARK: - Lock Screen Widgets

private struct InlinePrayerWidget: View {
    let data: WidgetPrayerData?

    var body: some View {
        if let current = data?.currentPrayer {
            Text("\(current.prayer.capitalized) ends in \(timeString(until: current.windowEnd))")
        } else {
            Text("All prayers done today")
        }
    }
}

private struct CircularProgressWidget: View {
    let data: WidgetPrayerData?

    private var progress: Double { Double(data?.completedCount ?? 0) / 5.0 }

    var body: some View {
        Gauge(value: progress) {
            Text("\(data?.completedCount ?? 0)")
                .font(.system(size: 12, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

// MARK: - Helpers

private func timeString(until date: Date) -> String {
    let seconds = Int(date.timeIntervalSinceNow)
    guard seconds > 0 else { return "now" }
    let mins = seconds / 60
    if mins < 60 { return "\(mins)m" }
    return "\(mins / 60)h \(mins % 60)m"
}

private func shortTime(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: date)
}

private func statusColor(_ status: String) -> Color {
    switch status {
    case "done":    return .green
    case "missed":  return .red
    case "pending": return .blue
    case "qada":    return .yellow
    default:        return .gray
    }
}
