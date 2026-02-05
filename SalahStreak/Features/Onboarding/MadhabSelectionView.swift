import SwiftUI

struct MadhabSelectionView: View {
    let onNext: (MadhabType) -> Void

    @State private var selected: MadhabType = .shafi

    var body: some View {
        VStack(spacing: Theme.spacingLarge) {
            Spacer()

            Image(systemName: "book.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)

            Text("Select Your Madhab")
                .font(.system(size: 28, weight: .bold))

            Text("This affects the calculation of Asr prayer time.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(MadhabType.allCases) { madhab in
                    MadhabOption(madhab: madhab, isSelected: selected == madhab) {
                        selected = madhab
                    }
                }
            }

            Button("Continue") { onNext(selected) }
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

private struct MadhabOption: View {
    let madhab: MadhabType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text(madhab.displayName)
                .font(.system(size: 16, weight: .medium))
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.accent)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 260)
        .background(isSelected ? Theme.accent.opacity(0.1) : Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Theme.accent : Color.clear, lineWidth: 1.5)
        )
        .contentShape(.rect)
        .onTapGesture(perform: onTap)
    }
}
