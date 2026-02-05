import SwiftUI

struct PrayerCard: View {
    let model: PrayerCardModel
    let onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 14) {
            iconView
            infoView
            Spacer()
            statusIcon
        }
        .padding(14)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(borderColor, lineWidth: model.state == .active || model.state == .warning ? 1.5 : 0)
        )
        .scaleEffect(pulseScale)
        .onTapGesture(perform: onTap)
        .onChange(of: model.state) { _, _ in resetPulse() }
        .onAppear { startPulse() }
    }

    // MARK: - Sub-views

    private var iconView: some View {
        Image(systemName: model.prayer.icon)
            .font(.system(size: 22))
            .foregroundStyle(stateColor)
            .frame(width: 32)
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.prayer.displayName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(model.state == .missed ? Theme.stateMissed : .primary)
            Text(formattedTime)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    private var statusIcon: some View {
        Group {
            switch model.state {
            case .done:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.stateDone)
            case .missed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Theme.stateMissed)
            case .active, .warning:
                Image(systemName: "circle")
                    .foregroundStyle(stateColor)
            case .future:
                Image(systemName: "circle")
                    .foregroundStyle(Theme.stateFuture)
            }
        }
        .font(.system(size: 22))
    }

    // MARK: - Helpers

    private var cardBackground: some ShapeStyle {
        model.state == .done ? Color.green.opacity(0.08) : Theme.cardBG
    }

    private var borderColor: Color {
        model.state == .warning ? Theme.stateWarning : Theme.stateActive
    }

    private var stateColor: Color {
        switch model.state {
        case .active:  return Theme.stateActive
        case .warning: return Theme.stateWarning
        case .done:    return Theme.stateDone
        case .missed:  return Theme.stateMissed
        case .future:  return Theme.stateFuture
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: model.scheduledTime)
    }

    // MARK: - Pulse animation

    private func startPulse() {
        guard model.state == .active || model.state == .warning else { return }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.03
        }
    }

    private func resetPulse() {
        pulseScale = 1.0
        startPulse()
    }
}
