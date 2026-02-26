import SwiftUI

struct AuraParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var targetPosition: CGPoint
    var velocity: CGVector = CGVector(dx: 0, dy: 0)
    var color: Color
    var opacity: CGFloat = 0.3
    var size: CGFloat = 4
    var life: CGFloat = 1.0
    var phase: CGFloat = CGFloat.random(in: 0...(.pi * 2))
    var birthTime: Date = .now
}

@Observable
class ParticleSystem {
    var particles: [AuraParticle] = []
    private let maxParticles = 1200
    private let dampingFactor: CGFloat = 0.92
    private let springStiffness: CGFloat = 0.03
    private let microMotionScale: CGFloat = 1.5

    func spawnParticles(at point: CGPoint, count: Int, mood: Mood, anchors: [CGPoint]) {
        for _ in 0..<count {
            let colorSet = mood.colors
            let color = colorSet.randomElement() ?? mood.color
            let nearest = nearestAnchor(to: point, in: anchors)

            let particle = AuraParticle(
                position: point + CGVector(
                    dx: CGFloat.random(in: -8...8),
                    dy: CGFloat.random(in: -8...8)
                ),
                targetPosition: nearest,
                color: color,
                opacity: CGFloat.random(in: 0.15...0.4),
                size: CGFloat.random(in: 2...6)
            )
            particles.append(particle)
        }
        enforceLimit()
    }

    func update(time: Double, mood: Mood) {
        for i in particles.indices {
            // Spring force toward target
            let dx = particles[i].targetPosition.x - particles[i].position.x
            let dy = particles[i].targetPosition.y - particles[i].position.y
            let springForce = CGVector(dx: dx * springStiffness, dy: dy * springStiffness)

            // Micro-motion based on phase
            let phase = particles[i].phase
            let microX = sin(time * 1.5 + phase) * microMotionScale
            let microY = cos(time * 1.2 + phase * 0.7) * microMotionScale

            particles[i].velocity = (particles[i].velocity + springForce) * dampingFactor
            particles[i].velocity = particles[i].velocity + CGVector(dx: microX * 0.05, dy: microY * 0.05)
            particles[i].position = particles[i].position + particles[i].velocity

            // Decay life
            particles[i].life -= 0.0008
        }
        particles.removeAll { $0.life <= 0 }
    }

    func transitionToAnchors(_ newAnchors: [CGPoint], mood: Mood) {
        let colors = mood.colors
        for i in particles.indices {
            let nearest = nearestAnchor(to: particles[i].position, in: newAnchors)
            particles[i].targetPosition = nearest
            particles[i].color = colors.randomElement() ?? mood.color
            particles[i].opacity = 0.5 // briefly brighter during transition
            particles[i].life = max(particles[i].life, 0.7)
        }

        // Fade opacity back after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            for i in self.particles.indices {
                self.particles[i].opacity = CGFloat.random(in: 0.15...0.4)
            }
        }
    }

    func reassignTargets(_ anchors: [CGPoint]) {
        guard !anchors.isEmpty else { return }
        for i in particles.indices {
            let nearest = nearestAnchor(to: particles[i].position, in: anchors)
            particles[i].targetPosition = nearest
            particles[i].life = max(particles[i].life, 0.8)
        }
    }

    func clear() {
        particles.removeAll()
    }

    func recolorToCalm() {
        let colors = Mood.calm.colors
        for i in particles.indices {
            particles[i].color = colors.randomElement() ?? Mood.calm.color
            particles[i].life = max(particles[i].life, 0.5)
            particles[i].opacity = CGFloat.random(in: 0.15...0.35)
        }
    }

    private func enforceLimit() {
        if particles.count > maxParticles {
            particles.removeFirst(particles.count - maxParticles)
        }
    }

    private func nearestAnchor(to point: CGPoint, in anchors: [CGPoint]) -> CGPoint {
        guard !anchors.isEmpty else { return point }
        return anchors.min(by: { point.distance(to: $0) < point.distance(to: $1) })!
    }
}