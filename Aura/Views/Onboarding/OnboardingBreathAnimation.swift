import SwiftUI

struct OnboardingBreathAnimation: View {
    @State private var startDate = Date()
    @State private var engine = BreathParticleEngine()

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            let breathState = Self.computeBreath(elapsed: elapsed)

            VStack(spacing: 24) {
                Canvas { context, size in
                    engine.update(elapsed: elapsed, size: size, breathScale: breathState.scale)

                    for particle in engine.particles {
                        let rect = CGRect(
                            x: particle.x - particle.size,
                            y: particle.y - particle.size,
                            width: particle.size * 2,
                            height: particle.size * 2
                        )

                        let color = Color(
                            red: particle.r.clamped01,
                            green: particle.g.clamped01,
                            blue: particle.b.clamped01
                        )

                        context.fill(
                            Ellipse().path(in: rect),
                            with: .color(color.opacity(particle.opacity.clamped01))
                        )
                    }
                }

                Text(breathState.inhaling ? "Breathe in..." : "Let it go...")
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(Color.auraText.opacity(0.5))
                    .animation(.easeInOut(duration: 0.8), value: breathState.inhaling)
            }
        }
        .onAppear {
            startDate = Date()
            engine.reset()
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

private struct BreathParticle {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var tx: Double
    var ty: Double
    var r: Double
    var g: Double
    var b: Double
    var size: Double
    var opacity: Double
    var baseOpacity: Double
    var phase: Double
}

private final class BreathParticleEngine {
    private(set) var particles: [BreathParticle] = []

    private var lastElapsed: Double?

    private let springStiffness = 0.03
    private let damping = 0.92
    private let microMotionScale = 0.9
    private let ringRatios: [Double] = [0.36, 0.64, 0.9]
    private let pointsPerRing = 20

    func reset() {
        particles.removeAll(keepingCapacity: true)
        lastElapsed = nil
    }

    func update(elapsed: Double, size: CGSize, breathScale: Double) {
        guard size.width > 0, size.height > 0 else { return }

        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let baseRadius = min(size.width, size.height) * 0.42
        let anchors = generateAnchors(center: center, baseRadius: baseRadius, breathScale: breathScale, time: elapsed)

        if particles.isEmpty {
            bootstrapParticles(anchors: anchors)
        } else {
            for i in particles.indices {
                let target = anchors[i % anchors.count]
                particles[i].tx = target.x
                particles[i].ty = target.y
            }
        }

        let dt: Double
        if let lastElapsed {
            dt = max(1.0 / 120.0, min(elapsed - lastElapsed, 1.0 / 20.0))
        } else {
            dt = 1.0 / 60.0
        }
        lastElapsed = elapsed

        for i in particles.indices {
            let dx = particles[i].tx - particles[i].x
            let dy = particles[i].ty - particles[i].y

            particles[i].vx = (particles[i].vx + dx * springStiffness) * damping
            particles[i].vy = (particles[i].vy + dy * springStiffness) * damping

            let phase = particles[i].phase
            let microX = sin(elapsed * 1.5 + phase) * microMotionScale
            let microY = cos(elapsed * 1.2 + phase * 0.7) * microMotionScale

            particles[i].x += particles[i].vx + microX * 0.04
            particles[i].y += particles[i].vy + microY * 0.04

            let breatheGlow = 0.03 * (sin(elapsed * 1.1 + phase) * 0.5 + 0.5)
            let targetOpacity = particles[i].baseOpacity + breatheGlow
            particles[i].opacity += (targetOpacity - particles[i].opacity) * min(1.0, dt * 10.0)
        }
    }

    private func bootstrapParticles(anchors: [CGPoint]) {
        let palette = Self.calmPalette

        particles = anchors.enumerated().map { i, anchor in
            let color = palette[i % palette.count]
            return BreathParticle(
                x: anchor.x + Double.random(in: -6...6),
                y: anchor.y + Double.random(in: -6...6),
                vx: 0,
                vy: 0,
                tx: anchor.x,
                ty: anchor.y,
                r: color.r,
                g: color.g,
                b: color.b,
                size: Double.random(in: 2.2...4.6),
                opacity: Double.random(in: 0.16...0.3),
                baseOpacity: Double.random(in: 0.16...0.28),
                phase: Double.random(in: 0...(2 * .pi))
            )
        }
    }

    private func generateAnchors(center: CGPoint, baseRadius: CGFloat, breathScale: Double, time: Double) -> [CGPoint] {
        var anchors: [CGPoint] = []

        for (ringIndex, ratio) in ringRatios.enumerated() {
            let ringBase = Double(baseRadius) * ratio * breathScale

            for point in 0..<pointsPerRing {
                let angle = Double(point) / Double(pointsPerRing) * 2 * .pi
                let ripple = sin(time * 1.3 + angle * 2 + Double(ringIndex)) * Double(baseRadius) * 0.02
                let r = ringBase + ripple

                anchors.append(
                    CGPoint(
                        x: center.x + cos(angle) * r,
                        y: center.y + sin(angle) * r
                    )
                )
            }
        }

        return anchors
    }

    private static let calmPalette: [(r: Double, g: Double, b: Double)] = [
        (139.0 / 255.0, 164.0 / 255.0, 184.0 / 255.0),
        (163.0 / 255.0, 184.0 / 255.0, 200.0 / 255.0),
        (194.0 / 255.0, 209.0 / 255.0, 219.0 / 255.0)
    ]
}

private extension Double {
    var clamped01: Double { min(max(self, 0), 1) }
}
