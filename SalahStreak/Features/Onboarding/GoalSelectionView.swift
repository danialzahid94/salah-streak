import SwiftUI

struct GoalSelectionView: View {
    let onFinish: (Bool) -> Void

    @State private var notificationsEnabled = true

    var body: some View {
        VStack(spacing: Theme.spacingLarge) {
            Spacer()

            Image(systemName: "bell.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)

            Text("Stay on Track")
                .font(.system(size: 28, weight: .bold))

            Text("Enable smart reminders to help you maintain your prayer streak.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Toggle("Prayer Reminders", isOn: $notificationsEnabled)
                .padding(14)
                .frame(width: 260)
                .background(Theme.cardBG)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("Get Started") { onFinish(notificationsEnabled) }
                .font(.system(size: 16, weight: .semibold))
                .padding(.vertical, 14)
                .frame(width: 260)
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
    }
}
