import SwiftUI

struct TodaySummarySheet: View {
    let cards: [PrayerCardModel]

    var body: some View {
        List {
            Section("Today's Prayers") {
                ForEach(cards, id: \.prayer) { card in
                    HStack {
                        Image(systemName: card.prayer.icon)
                            .foregroundStyle(stateColor(card.state))
                            .frame(width: 24)
                        Text(card.prayer.displayName)
                        Spacer()
                        Text(statusLabel(card.state))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(stateColor(card.state))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Summary")
    }

    private func stateColor(_ state: PrayerCardState) -> Color {
        switch state {
        case .done:    return Theme.stateDone
        case .active:  return Theme.stateActive
        case .warning: return Theme.stateWarning
        case .missed:  return Theme.stateMissed
        case .future:  return Theme.stateFuture
        case .qada:     return Theme.stateQada
        }
    }

    private func statusLabel(_ state: PrayerCardState) -> String {
        switch state {
        case .done:    return "Done"
        case .active:  return "Active"
        case .warning: return "Warning"
        case .missed:  return "Missed"
        case .future:  return "Upcoming"
        case .qada:     return "Qada"
        }
    }
}
