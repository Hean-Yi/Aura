import Combine
import SwiftUI

struct OnboardingMoodCycleAnimation: View {
    @State private var activeMoodIndex = 0
    @State private var particles: [(x: Double, y: Double, size: Double, opacity: Double)] = []
    @State private var startDate = Date()

    private let moods = Mood.allCases
    private let timer = Timer.publish(every: 1.8, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 32) {
            HStack(spacing: 20) {
                ForEach(0..<5) { index in
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
                    let mood = moods[activeMoodIndex]
                    let colors = mood.colors

                    for (i, p) in particles.enumerated() {
                        let drift = sin(elapsed * 1.5 + Double(i) * 0.7) * 0.02
                        let px = (p.x + drift) * size.width
                        let py = (p.y + drift * 0.5) * size.height
                        let rect = CGRect(x: px - p.size, y: py - p.size,
                                          width: p.size * 2, height: p.size * 2)
                        let color = colors[i % colors.count]
                        context.fill(Ellipse().path(in: rect),
                                     with: .color(color.opacity(p.opacity)))
                    }
                }
            }
            .frame(height: 100)
        }
        .onAppear { regenerateParticles() }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                activeMoodIndex = (activeMoodIndex + 1) % moods.count
            }
            regenerateParticles()
        }
    }

    private func regenerateParticles() {
        particles = (0..<20).map { _ in
            (x: Double.random(in: 0.15...0.85),
             y: Double.random(in: 0.1...0.9),
             size: Double.random(in: 2...5),
             opacity: Double.random(in: 0.15...0.35))
        }
    }
}
