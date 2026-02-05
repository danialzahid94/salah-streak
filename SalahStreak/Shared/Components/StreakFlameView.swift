import SwiftUI

struct StreakFlameView: View {
    let streak: Int

    @State private var flicker: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .scaleEffect(flicker ? 1.0 : 0.92)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: flicker)

            Text("\(streak)")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.primary)
        }
        .onAppear { flicker = true }
    }
}
