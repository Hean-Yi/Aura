import SwiftUI

struct MoodRadarChart: View {
    let scores: [Mood: Double]
    let dominantMood: Mood

    private let moods = Mood.allCases
    private let gridLevels = 3

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 36

            // Grid lines
            for level in 1...gridLevels {
                let r = radius * CGFloat(level) / CGFloat(gridLevels)
                let gridPath = polygonPath(center: center, radius: r)
                context.stroke(gridPath, with: .color(Color.auraText.opacity(0.1)), lineWidth: 1)
            }

            // Axis lines
            for i in 0..<moods.count {
                let angle = angleFor(index: i)
                let end = point(center: center, radius: radius, angle: angle)
                var axis = Path()
                axis.move(to: center)
                axis.addLine(to: end)
                context.stroke(axis, with: .color(Color.auraText.opacity(0.08)), lineWidth: 1)
            }

            // Data polygon
            let maxScore = max(scores.values.max() ?? 1, 0.001)
            let dataPath = dataPolygonPath(center: center, radius: radius, maxScore: maxScore)
            context.fill(dataPath, with: .color(dominantMood.color.opacity(0.2)))
            context.stroke(dataPath, with: .color(dominantMood.color.opacity(0.7)), lineWidth: 2)

            // Vertex dots
            for i in 0..<moods.count {
                let mood = moods[i]
                let value = scores[mood] ?? 0
                let normalized = CGFloat(value / maxScore)
                let angle = angleFor(index: i)
                let pt = point(center: center, radius: radius * normalized, angle: angle)
                let dotRect = CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)
                context.fill(Path(ellipseIn: dotRect), with: .color(mood.color))
            }
        }
        .overlay { labels }
        .aspectRatio(1, contentMode: .fit)
    }

    private var labels: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 8

            ForEach(Array(moods.enumerated()), id: \.element) { i, mood in
                let angle = angleFor(index: i)
                let pt = point(center: center, radius: radius, angle: angle)

                VStack(spacing: 2) {
                    Image(systemName: mood.icon)
                        .font(.caption2)
                    Text(mood.label)
                        .font(.system(.caption2, design: .serif))
                }
                .foregroundStyle(mood.color)
                .position(pt)
            }
        }
    }

    // MARK: - Geometry helpers

    private func angleFor(index: Int) -> CGFloat {
        let slice = CGFloat.pi * 2 / CGFloat(moods.count)
        return slice * CGFloat(index) - .pi / 2 // start from top
    }

    private func point(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

    private func polygonPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for i in 0..<moods.count {
            let angle = angleFor(index: i)
            let pt = point(center: center, radius: radius, angle: angle)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }

    private func dataPolygonPath(center: CGPoint, radius: CGFloat, maxScore: Double) -> Path {
        var path = Path()
        for i in 0..<moods.count {
            let mood = moods[i]
            let value = scores[mood] ?? 0
            let normalized = CGFloat(value / maxScore)
            let angle = angleFor(index: i)
            let pt = point(center: center, radius: radius * normalized, angle: angle)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}
