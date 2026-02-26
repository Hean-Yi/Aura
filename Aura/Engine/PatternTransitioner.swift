import SwiftUI

struct PatternTransitioner {
    private let transitionDuration: Double = 1.5

    func transition(
        particles: inout [AuraParticle],
        to newAnchors: [CGPoint],
        mood: Mood
    ) {
        guard !newAnchors.isEmpty else { return }
        let colors = mood.colors

        for i in particles.indices {
            let nearest = findNearest(particles[i].position, in: newAnchors)
            particles[i].targetPosition = nearest
            particles[i].color = colors.randomElement() ?? mood.color
            particles[i].opacity = 0.5
            particles[i].life = max(particles[i].life, 0.7)
        }
    }

    private func findNearest(_ point: CGPoint, in anchors: [CGPoint]) -> CGPoint {
        anchors.min(by: { point.distance(to: $0) < point.distance(to: $1) }) ?? point
    }
}
