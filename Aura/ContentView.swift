import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [AuraEntry]

    var body: some View {
        if hasCompletedOnboarding {
            mainTabView
                .onAppear { seedSampleDataIfNeeded() }
        } else {
            OnboardingView(isComplete: $hasCompletedOnboarding)
                .onChange(of: hasCompletedOnboarding) {
                    if hasCompletedOnboarding {
                        seedSampleDataIfNeeded()
                    }
                }
        }
    }

    private var mainTabView: some View {
        TabView {
            CanvasView()
                .tabItem { Label("Create", systemImage: "circle.dotted") }

            GalleryView()
                .tabItem { Label("Gallery", systemImage: "square.grid.2x2") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
        }
        .tint(Color.auraText)
    }
}

extension ContentView {
    private func seedSampleDataIfNeeded() {
        guard entries.isEmpty else { return }

        let cal = Calendar.current
        let sampleMoods: [(Mood, Int)] = [
            (.calm, -6),
            (.joy, -5),
            (.sadness, -4),
            (.calm, -3),
            (.anxiety, -2),
            (.joy, -1),
            (.anger, 0),
        ]

        for (mood, dayOffset) in sampleMoods {
            let date = cal.date(byAdding: .day, value: dayOffset, to: .now)!
            let snapshot = generateSampleSnapshot(for: mood)
            let scores = sampleScores(for: mood)

            let entry = AuraEntry(
                date: date,
                moodScores: scores,
                dominantMood: mood,
                canvasSnapshot: snapshot,
                strokeSummary: StrokeMetricsSummary(
                    totalPoints: Int.random(in: 200...500),
                    averageSpeed: CGFloat.random(in: 100...600),
                    averagePressure: 0.5,
                    coveragePercent: CGFloat.random(in: 0.2...0.6)
                ),
                duration: TimeInterval.random(in: 30...120)
            )
            modelContext.insert(entry)
        }
    }

    private func sampleScores(for mood: Mood) -> [String: Double] {
        var scores: [String: Double] = [:]
        for m in Mood.allCases {
            scores[m.rawValue] = m == mood ? Double.random(in: 6...9) : Double.random(in: 1...4)
        }
        return scores
    }

    private func generateSampleSnapshot(for mood: Mood) -> Data {
        let size = CGSize(width: 200, height: 200)
        let gen = PatternGenerator()
        let center = CGPoint(x: 100, y: 100)
        let anchors = gen.generateAnchors(for: mood, center: center, radius: 80)

        let renderer = ImageRenderer(content:
            Canvas { context, sz in
                context.fill(
                    Path(CGRect(origin: .zero, size: sz)),
                    with: .color(Color.auraBackground)
                )
                let colors = mood.colors
                for anchor in anchors {
                    let color = colors.randomElement() ?? mood.color
                    let s = CGFloat.random(in: 2...5)
                    let rect = CGRect(
                        x: anchor.x - s / 2,
                        y: anchor.y - s / 2,
                        width: s, height: s
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(color.opacity(0.3))
                    )
                }
            }
            .frame(width: size.width, height: size.height)
        )
        renderer.scale = 2.0
        #if canImport(UIKit)
        if let img = renderer.uiImage, let data = img.pngData() {
            return data
        }
        #endif
        return Data()
    }
}
