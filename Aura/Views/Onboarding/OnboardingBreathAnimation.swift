import SwiftUI

struct OnboardingBreathAnimation: View {
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            let breathState = Self.computeBreath(elapsed: elapsed)

            VStack(spacing: 24) {
                Canvas { context, size in
                    let cx = size.width * 0.5
                    let cy = size.height * 0.5
                    let maxR = min(size.width, size.height) * 0.4

                    for ring in 0..<3 {
                        let frac = Double(ring + 1) / 3.0
                        let r = maxR * frac * breathState.scale
                        let alpha = (1.0 - frac * 0.3) * 0.25
                        let rect = CGRect(x: cx - r, y: cy - r,
                                          width: r * 2, height: r * 2)
                        context.stroke(
                            Ellipse().path(in: rect),
                            with: .color(Mood.calm.color.opacity(alpha)),
                            lineWidth: 1.5
                        )
                    }

                    let dotR = 3.0 * breathState.scale + 2.0
                    let dotRect = CGRect(x: cx - dotR, y: cy - dotR,
                                         width: dotR * 2, height: dotR * 2)
                    context.fill(Ellipse().path(in: dotRect),
                                 with: .color(Mood.calm.color.opacity(0.4)))
                }

                Text(breathState.inhaling ? "Breathe in..." : "Let it go...")
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(Color.auraText.opacity(0.5))
                    .animation(.easeInOut(duration: 0.8), value: breathState.inhaling)
            }
        }
    }

    private static func computeBreath(elapsed: Double) -> (scale: Double, inhaling: Bool) {
        let cycle = elapsed.truncatingRemainder(dividingBy: 6.0)
        let inhaling = cycle < 3.0
        let phase = inhaling ? cycle / 3.0 : (cycle - 3.0) / 3.0
        let scale: Double
        if inhaling {
            scale = 0.5 + 0.5 * sin(phase * .pi / 2)
        } else {
            scale = 1.0 - 0.5 * sin(phase * .pi / 2)
        }
        return (scale, inhaling)
    }
}
