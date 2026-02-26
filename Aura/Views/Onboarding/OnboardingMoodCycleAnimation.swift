import Combine
import SwiftUI

struct OnboardingMoodCycleAnimation: View {
    @State private var activeMoodIndex = 0
    @State private var startDate = Date()
    @State private var engine = MoodCycleEngine()

    private let moods = Mood.allCases
    private let timer = Timer.publish(every: 1.8, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            let canvasHeight = max(220, proxy.size.height * 0.55)

            VStack(spacing: 18) {
                HStack(spacing: 20) {
                    ForEach(0..<moods.count, id: \.self) { index in
                        let mood = moods[index]
                        let isActive = index == activeMoodIndex

                        VStack(spacing: 8) {
                            Image(systemName: mood.icon)
                                .font(.system(size: isActive ? 28 : 20))
                                .foregroundStyle(mood.color.opacity(isActive ? 1.0 : 0.3))

                            Text(mood.label)
                                .font(.system(size: 10, design: .serif))
                                .foregroundStyle(Color.auraText.opacity(isActive ? 0.8 : 0.25))
                        }
                        .animation(.easeInOut(duration: 0.5), value: activeMoodIndex)
                    }
                }

                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let elapsed = timeline.date.timeIntervalSince(startDate)
                        engine.update(elapsed: elapsed, size: size)

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
                }
                .frame(maxWidth: .infinity)
                .frame(height: canvasHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 8)
        }
        .onAppear {
            startDate = Date()
            activeMoodIndex = 0
            engine.reset(to: moods[activeMoodIndex])
        }
        .onReceive(timer) { _ in
            activeMoodIndex = (activeMoodIndex + 1) % moods.count
            engine.requestTransition(to: moods[activeMoodIndex])
        }
    }
}

private struct MoodParticle {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var tx: Double
    var ty: Double
    var r: Double
    var g: Double
    var b: Double
    var tr: Double
    var tg: Double
    var tb: Double
    var size: Double
    var opacity: Double
    var phase: Double
    var boost: Double
}

private final class MoodCycleEngine {
    private(set) var particles: [MoodParticle] = []

    private var currentMood: Mood = .joy
    private var pendingMood: Mood?
    private var lastElapsed: Double?

    private var center: CGPoint = .zero
    private var radius: CGFloat = 32

    private let particleCount = 40
    private let springStiffness = 0.03
    private let damping = 0.92
    private let microMotionScale = 1.0
    private let colorLerpDuration = 0.8

    func reset(to mood: Mood) {
        currentMood = mood
        pendingMood = nil
        lastElapsed = nil
        particles.removeAll(keepingCapacity: true)
    }

    func requestTransition(to mood: Mood) {
        guard mood != currentMood else { return }
        pendingMood = mood
    }

    func update(elapsed: Double, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        center = CGPoint(x: size.width * 0.5, y: size.height * 0.52)
        radius = min(size.width, size.height) * 0.46

        if particles.isEmpty {
            bootstrapParticles(time: elapsed)
        }

        if let nextMood = pendingMood {
            transitionTo(mood: nextMood, time: elapsed)
            pendingMood = nil
        }

        let dt: Double
        if let lastElapsed {
            dt = max(1.0 / 120.0, min(elapsed - lastElapsed, 1.0 / 20.0))
        } else {
            dt = 1.0 / 60.0
        }
        lastElapsed = elapsed

        let colorStep = min(dt / colorLerpDuration, 1.0)

        for i in particles.indices {
            let dx = particles[i].tx - particles[i].x
            let dy = particles[i].ty - particles[i].y

            particles[i].vx = (particles[i].vx + dx * springStiffness) * damping
            particles[i].vy = (particles[i].vy + dy * springStiffness) * damping

            let phase = particles[i].phase
            let microX = sin(elapsed * 1.5 + phase) * microMotionScale
            let microY = cos(elapsed * 1.2 + phase * 0.7) * microMotionScale

            var jitterX = 0.0
            var jitterY = 0.0
            if currentMood == .anxiety {
                let jitterAmp = 0.9
                jitterX = sin(elapsed * 10.0 + phase * 1.9) * jitterAmp
                jitterY = cos(elapsed * 11.5 + phase * 2.3) * jitterAmp
            }

            particles[i].x += particles[i].vx + microX * 0.05 + jitterX * 0.08
            particles[i].y += particles[i].vy + microY * 0.05 + jitterY * 0.08

            particles[i].r += (particles[i].tr - particles[i].r) * colorStep
            particles[i].g += (particles[i].tg - particles[i].g) * colorStep
            particles[i].b += (particles[i].tb - particles[i].b) * colorStep

            particles[i].boost = max(0, particles[i].boost - dt * 1.25)
            let restOpacity = 0.2 + 0.06 * (sin(elapsed * 0.9 + phase) * 0.5 + 0.5)
            let targetOpacity = restOpacity + particles[i].boost * (0.4 - restOpacity)
            particles[i].opacity += (targetOpacity - particles[i].opacity) * min(1.0, dt * 10.0)
        }
    }

    private func bootstrapParticles(time: Double) {
        let anchors = generateAnchors(mood: currentMood, center: center, radius: radius, time: time)
        let palette = Self.palette(for: currentMood)

        particles = (0..<particleCount).map { i in
            let anchor = anchors[i % max(anchors.count, 1)]
            let color = palette[i % max(palette.count, 1)]
            let spread = Double(radius) * 0.28
            let angle = Double(i) / Double(particleCount) * 2.0 * .pi

            return MoodParticle(
                x: anchor.x + cos(angle) * Double.random(in: -spread...spread),
                y: anchor.y + sin(angle) * Double.random(in: -spread...spread),
                vx: 0,
                vy: 0,
                tx: anchor.x,
                ty: anchor.y,
                r: color.r,
                g: color.g,
                b: color.b,
                tr: color.r,
                tg: color.g,
                tb: color.b,
                size: Double.random(in: 2.2...4.8),
                opacity: Double.random(in: 0.16...0.3),
                phase: Double.random(in: 0...(2.0 * .pi)),
                boost: 0
            )
        }
    }

    private func transitionTo(mood: Mood, time: Double) {
        let anchors = generateAnchors(mood: mood, center: center, radius: radius, time: time)
        guard !anchors.isEmpty, !particles.isEmpty else {
            currentMood = mood
            return
        }

        var available = anchors
        let palette = Self.palette(for: mood)

        for i in particles.indices {
            let point = CGPoint(x: particles[i].x, y: particles[i].y)
            let selectedAnchor: CGPoint

            if let idx = nearestAnchorIndex(to: point, in: available) {
                selectedAnchor = available.remove(at: idx)
            } else {
                selectedAnchor = anchors[i % anchors.count]
            }

            particles[i].tx = selectedAnchor.x
            particles[i].ty = selectedAnchor.y

            let targetColor = palette[i % max(palette.count, 1)]
            particles[i].tr = targetColor.r
            particles[i].tg = targetColor.g
            particles[i].tb = targetColor.b
            particles[i].boost = 1.0
        }

        currentMood = mood
    }

    private func nearestAnchorIndex(to point: CGPoint, in anchors: [CGPoint]) -> Int? {
        guard !anchors.isEmpty else { return nil }

        var bestIndex = 0
        var bestDist = Double.greatestFiniteMagnitude

        for i in anchors.indices {
            let dx = point.x - anchors[i].x
            let dy = point.y - anchors[i].y
            let d2 = dx * dx + dy * dy
            if d2 < bestDist {
                bestDist = d2
                bestIndex = i
            }
        }

        return bestIndex
    }

    private func generateAnchors(mood: Mood, center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        switch mood {
        case .joy:
            joyAnchors(center: center, radius: radius, time: time)
        case .calm:
            calmAnchors(center: center, radius: radius, time: time)
        case .anxiety:
            anxietyAnchors(center: center, radius: radius, time: time)
        case .sadness:
            sadnessAnchors(center: center, radius: radius, time: time)
        case .anger:
            angerAnchors(center: center, radius: radius, time: time)
        }
    }

    private func joyAnchors(center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        var anchors: [CGPoint] = []
        let petalCount = 8
        let pointsPerPetal = 5
        let rotation = time * 0.18

        for petal in 0..<petalCount {
            let baseAngle = Double(petal) / Double(petalCount) * 2.0 * .pi + rotation
            for p in 0..<pointsPerPetal {
                let t = Double(p) / Double(pointsPerPetal - 1)
                let bend = sin(t * .pi) * 0.25
                let r = Double(radius) * (0.22 + 0.78 * t * (0.6 + 0.4 * sin(t * .pi)))
                let angle = baseAngle + bend
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

    private func calmAnchors(center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        var anchors: [CGPoint] = []
        let rings: [Double] = [0.36, 0.64, 0.9]
        let pointsPerRing = 13

        for (ringIndex, ratio) in rings.enumerated() {
            let baseRadius = Double(radius) * ratio
            for p in 0..<pointsPerRing {
                let angle = Double(p) / Double(pointsPerRing) * 2.0 * .pi
                let ripple = sin(time * 1.3 + angle * 2.0 + Double(ringIndex)) * Double(radius) * 0.03
                let r = baseRadius + ripple
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

    private func anxietyAnchors(center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        var nodes: [CGPoint] = []
        for i in 0..<15 {
            let h1 = hash(i, seed: 19)
            let h2 = hash(i, seed: 53)
            let jitter = sin(time * 9.0 + Double(i) * 1.3) * Double(radius) * 0.08

            let x = center.x + (h1 - 0.5) * Double(radius) * 1.8 + jitter
            let y = center.y + (h2 - 0.5) * Double(radius) * 1.8 - jitter * 0.6
            nodes.append(CGPoint(x: x, y: y))
        }

        var anchors = nodes
        var pair = 0
        while anchors.count < particleCount {
            let a = nodes[pair % nodes.count]
            let b = nodes[(pair * 7 + 3) % nodes.count]
            let t = 0.35 + 0.3 * hash(pair, seed: 97)
            let mx = a.x + (b.x - a.x) * t
            let my = a.y + (b.y - a.y) * t
            let shake = sin(time * 12.0 + Double(pair)) * Double(radius) * 0.03
            anchors.append(CGPoint(x: mx + shake, y: my - shake * 0.7))
            pair += 1
        }

        return Array(anchors.prefix(particleCount))
    }

    private func sadnessAnchors(center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        var anchors: [CGPoint] = []
        let streamCount = 5
        let pointsPerStream = 8

        for stream in 0..<streamCount {
            let baseX = center.x + (Double(stream) - Double(streamCount - 1) / 2.0) * Double(radius) * 0.36
            let flowOffset = fmod(time * 0.22 + Double(stream) * 0.11, 1.0)

            for p in 0..<pointsPerStream {
                let t = Double(p) / Double(pointsPerStream - 1)
                var y = center.y - Double(radius) * 0.95 + (t + flowOffset) * Double(radius) * 1.9
                if y > center.y + Double(radius) * 0.95 {
                    y -= Double(radius) * 1.9
                }

                let x = baseX + sin(t * 2.4 + Double(stream) * 0.8) * Double(radius) * 0.05
                anchors.append(CGPoint(x: x, y: y))
            }
        }

        return anchors
    }

    private func angerAnchors(center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        var anchors: [CGPoint] = []
        let spikeCount = 5
        let pointsPerSpike = 8
        let pulse = 1.0 + 0.16 * sin(time * 5.2)

        for spike in 0..<spikeCount {
            let baseAngle = Double(spike) / Double(spikeCount) * 2.0 * .pi
            for p in 0..<pointsPerSpike {
                let t = Double(p) / Double(pointsPerSpike - 1)
                let fork = t > 0.72 ? (t - 0.72) * 0.85 : 0
                let branch = p % 2 == 0 ? fork : -fork
                let angle = baseAngle + branch
                let r = Double(radius) * t * pulse

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

    private func hash(_ value: Int, seed: Int) -> Double {
        let mixed = (value &* 1103515245 &+ seed &* 12345) & 0x7fffffff
        return Double(mixed % 10_000) / 10_000.0
    }

    private static func palette(for mood: Mood) -> [(r: Double, g: Double, b: Double)] {
        switch mood {
        case .joy:
            [(212.0 / 255.0, 165.0 / 255.0, 116.0 / 255.0),
             (196.0 / 255.0, 149.0 / 255.0, 106.0 / 255.0),
             (232.0 / 255.0, 201.0 / 255.0, 160.0 / 255.0)]
        case .calm:
            [(139.0 / 255.0, 164.0 / 255.0, 184.0 / 255.0),
             (163.0 / 255.0, 184.0 / 255.0, 200.0 / 255.0),
             (194.0 / 255.0, 209.0 / 255.0, 219.0 / 255.0)]
        case .anxiety:
            [(155.0 / 255.0, 142.0 / 255.0, 168.0 / 255.0),
             (181.0 / 255.0, 168.0 / 255.0, 192.0 / 255.0),
             (125.0 / 255.0, 114.0 / 255.0, 137.0 / 255.0)]
        case .sadness:
            [(107.0 / 255.0, 123.0 / 255.0, 141.0 / 255.0),
             (90.0 / 255.0, 106.0 / 255.0, 125.0 / 255.0),
             (136.0 / 255.0, 149.0 / 255.0, 163.0 / 255.0)]
        case .anger:
            [(176.0 / 255.0, 112.0 / 255.0, 96.0 / 255.0),
             (196.0 / 255.0, 128.0 / 255.0, 110.0 / 255.0),
             (139.0 / 255.0, 94.0 / 255.0, 82.0 / 255.0)]
        }
    }
}

private extension Double {
    var clamped01: Double { min(max(self, 0), 1) }
}
