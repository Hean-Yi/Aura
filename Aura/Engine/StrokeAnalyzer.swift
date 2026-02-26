import Foundation

@Observable
class StrokeAnalyzer {
    private var points: [TouchPoint] = []
    private var allPoints: [TouchPoint] = []
    private var speeds: [CGFloat] = []
    private var smoothedScores: [Mood: Double] = [:]
    private var lastMoodChangeTime: Date?
    private var canvasSize: CGSize = CGSize(width: 400, height: 800)

    private let emaAlpha: CGFloat = 0.15
    private let moodSwitchDelay: TimeInterval = 0.8

    func setCanvasSize(_ size: CGSize) {
        canvasSize = size
    }

    func addPoint(_ location: CGPoint, timestamp: Date, force: CGFloat = 0.5) {
        let point = TouchPoint(location: location, timestamp: timestamp, force: force)
        points.append(point)
        allPoints.append(point)
    }

    func endStroke() {
        points.removeAll()
    }

    func reset() {
        points.removeAll()
        allPoints.removeAll()
        speeds.removeAll()
        smoothedScores.removeAll()
        lastMoodChangeTime = nil
    }

    func computeMetrics() -> StrokeMetrics {
        guard allPoints.count >= 2 else { return StrokeMetrics() }

        var metrics = StrokeMetrics()
        var totalSpeed: CGFloat = 0
        var speedValues: [CGFloat] = []
        var dirChanges = 0
        var downwardCount = 0
        var totalMovements = 0
        var pauseCount = 0

        var minX: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude

        for i in 1..<allPoints.count {
            let prev = allPoints[i - 1]
            let curr = allPoints[i]
            let dist = prev.location.distance(to: curr.location)
            let dt = curr.timestamp.timeIntervalSince(prev.timestamp)

            guard dt > 0 else { continue }

            let speed = dist / CGFloat(dt)
            speedValues.append(speed)
            totalSpeed += speed

            if curr.location.y > prev.location.y { downwardCount += 1 }
            totalMovements += 1

            if dt > 0.3 { pauseCount += 1 }

            minX = min(minX, curr.location.x)
            maxX = max(maxX, curr.location.x)
            minY = min(minY, curr.location.y)
            maxY = max(maxY, curr.location.y)
        }

        // Direction changes
        for i in 2..<allPoints.count {
            let v1 = allPoints[i - 1].location - allPoints[i - 2].location
            let v2 = allPoints[i].location - allPoints[i - 1].location
            let dot = v1.dx * v2.dx + v1.dy * v2.dy
            let mag1 = v1.magnitude
            let mag2 = v2.magnitude
            if mag1 > 0 && mag2 > 0 {
                let cosAngle = dot / (mag1 * mag2)
                if cosAngle < 0 { dirChanges += 1 }
            }
        }

        let avgSpeed = speedValues.isEmpty ? 0 : totalSpeed / CGFloat(speedValues.count)
        let variance = speedValues.isEmpty ? 0 : speedValues.reduce(0) { $0 + pow($1 - avgSpeed, 2) } / CGFloat(speedValues.count)

        let totalTime = allPoints.last!.timestamp.timeIntervalSince(allPoints.first!.timestamp)
        let canvasArea = max(canvasSize.width * canvasSize.height, 1)
        let coveredArea = (maxX - minX) * (maxY - minY)

        metrics.instantSpeed = speedValues.last ?? 0
        metrics.averageSpeed = avgSpeed
        metrics.speedVariance = variance
        metrics.pressure = allPoints.map(\.force).reduce(0, +) / CGFloat(allPoints.count)
        metrics.strokeDensity = CGFloat(allPoints.count) / max(coveredArea, 1) * 1000
        metrics.directionChanges = dirChanges
        metrics.pauseFrequency = totalTime > 0 ? CGFloat(pauseCount) / CGFloat(totalTime) : 0
        metrics.touchArea = coveredArea / canvasArea
        metrics.downwardRatio = totalMovements > 0 ? CGFloat(downwardCount) / CGFloat(totalMovements) : 0.5

        // Curvature from last 3 points
        if allPoints.count >= 3 {
            let p1 = allPoints[allPoints.count - 3].location
            let p2 = allPoints[allPoints.count - 2].location
            let p3 = allPoints[allPoints.count - 1].location
            let v1 = p2 - p1
            let v2 = p3 - p2
            let cross = abs(v1.dx * v2.dy - v1.dy * v2.dx)
            let denom = v1.magnitude * v2.magnitude
            metrics.curvature = denom > 0 ? cross / denom : 0
        }

        return metrics
    }

    func computeMoodScores() -> [Mood: Double] {
        let m = computeMetrics()
        let normSpeed = min(m.averageSpeed / 1000, 1.0)
        let normVariance = min(m.speedVariance / 500000, 1.0)
        let normDirChanges = min(CGFloat(m.directionChanges) / 50, 1.0)
        let normDensity = min(m.strokeDensity / 10, 1.0)
        let normPause = min(m.pauseFrequency / 2, 1.0)
        let normCurvature = min(m.curvature, 1.0)
        let normPressure = m.pressure
        let normArea = m.touchArea

        var scores: [Mood: Double] = [:]

        // Joy: medium-high speed, smooth curves, large area, stable
        let joySpeed = 1.0 - abs(normSpeed - 0.55) * 2
        scores[.joy] = Double(
            max(0, joySpeed) * 3 +
            normCurvature * 2 +
            normArea * 2 +
            (1.0 - normVariance) * 1
        )

        // Calm: low speed, very low variance, pauses, smooth
        scores[.calm] = Double(
            (1.0 - normSpeed) * 3 +
            (1.0 - normVariance) * 3 +
            normPause * 2 +
            (1.0 - normDirChanges) * 1
        )

        // Anxiety: high variance, frequent direction changes, dense small area
        scores[.anxiety] = Double(
            normVariance * 3 +
            normDirChanges * 3 +
            normDensity * (1.0 - normArea) * 2 +
            normPause * 1
        )

        // Sadness: very low speed, downward, small area, sparse
        scores[.sadness] = Double(
            (1.0 - normSpeed) * 3 +
            m.downwardRatio * 2 +
            (1.0 - normArea) * 2 +
            (1.0 - normDensity) * 2
        )

        // Anger: very high speed, high pressure, straight lines, dense
        scores[.anger] = Double(
            normSpeed * 3 +
            normPressure * 3 +
            (1.0 - normCurvature) * 2 +
            normDensity * 1
        )

        return scores
    }

    func smoothScores(_ raw: [Mood: Double]) -> [Mood: Double] {
        var result: [Mood: Double] = [:]
        for mood in Mood.allCases {
            let prev = smoothedScores[mood] ?? 0
            let new = raw[mood] ?? 0
            result[mood] = emaAlpha * new + (1.0 - emaAlpha) * prev
        }
        smoothedScores = result
        return result
    }

    func shouldSwitchMood(to newMood: Mood, current: Mood) -> Bool {
        guard newMood != current else { return false }
        let now = Date()
        if let lastChange = lastMoodChangeTime {
            if now.timeIntervalSince(lastChange) >= moodSwitchDelay {
                lastMoodChangeTime = now
                return true
            }
            return false
        }
        lastMoodChangeTime = now
        return true
    }

    func makeSummary() -> StrokeMetricsSummary {
        let m = computeMetrics()
        return StrokeMetricsSummary(
            totalPoints: allPoints.count,
            averageSpeed: m.averageSpeed,
            averagePressure: m.pressure,
            coveragePercent: m.touchArea
        )
    }

    func makeScoresDict() -> [String: Double] {
        let scores = smoothedScores.isEmpty ? computeMoodScores() : smoothedScores
        var dict: [String: Double] = [:]
        for (mood, score) in scores {
            dict[mood.rawValue] = score
        }
        return dict
    }
}