import SwiftUI

struct OnboardingParticleAnimation: View {
    @State private var particles: [OBParticle] = []
    @State private var startDate = Date()

    private let count = 30

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                let cx = size.width * 0.5
                let cy = size.height * 0.5
                let traceR = min(size.width, size.height) * 0.28

                // Finger trace arc
                let sweep = elapsed.truncatingRemainder(dividingBy: 4.0) / 4.0 * .pi * 2
                for i in 0..<40 {
                    let frac = Double(i) / 40.0
                    let angle = sweep - .pi * 0.8 * frac - .pi / 2
                    let x = cx + cos(angle) * traceR
                    let y = cy + sin(angle) * traceR
                    let rect = CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5)
                    context.fill(Ellipse().path(in: rect),
                                 with: .color(Color.auraText.opacity((1 - frac) * 0.3)))
                }

                // Particles converging
                for p in particles {
                    let age = elapsed - p.spawn
                    guard age > 0 else { continue }
                    let t = min(age / 2.0, 1.0)
                    let e = t * t * (3 - 2 * t)
                    let px = (p.sx + (p.tx - p.sx) * e) * size.width
                    let py = (p.sy + (p.ty - p.sy) * e) * size.height
                    let alpha = min(age / 0.3, 1.0) * 0.35
                    let rect = CGRect(x: px - 3, y: py - 3, width: 6, height: 6)
                    context.fill(Ellipse().path(in: rect),
                                 with: .color(p.color.opacity(alpha)))
                }
            }
        }
        .onAppear { spawn() }
    }

    private func spawn() {
        let colors = Mood.joy.colors
        particles = (0..<count).map { i in
            let angle = Double.random(in: 0...(2 * .pi))
            let dist = 0.28 + Double.random(in: -0.05...0.05)
            let tAngle = Double(i) / Double(count) * 2 * .pi
            let tDist = Double.random(in: 0.03...0.12)
            return OBParticle(
                sx: 0.5 + cos(angle) * dist, sy: 0.5 + sin(angle) * dist,
                tx: 0.5 + cos(tAngle) * tDist, ty: 0.5 + sin(tAngle) * tDist,
                color: colors.randomElement()!, spawn: Double(i) * 0.1
            )
        }
    }
}

private struct OBParticle {
    let sx, sy, tx, ty: Double
    let color: Color
    let spawn: Double
}
