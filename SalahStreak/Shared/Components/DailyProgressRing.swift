import SwiftUI

struct DailyProgressRing: View {
    let completed: Int
    let total: Int = 5

    private var progress: Double { Double(min(completed, total)) / Double(total) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.cardBG, lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [Theme.stateActive, Theme.stateDone],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: completed)

            Text("\(completed)/\(total)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
        }
        .frame(width: 72, height: 72)
    }
}
