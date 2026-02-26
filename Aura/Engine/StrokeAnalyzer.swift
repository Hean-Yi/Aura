import Foundation

@Observable
class StrokeAnalyzer {
    // MARK: - Sliding Window & State

    private var windowPoints: [TouchPoint] = []
    private var currentStrokeID: Int = 0
    private let windowDuration: TimeInterval = 5.0

    // Adaptive normalization (Welford online algorithm)
    private var speedStats = RunningStatistics()
    private var pressureStats = RunningStatistics()
    private var curvatureStats = RunningStatistics()
    private var jitterStats = RunningStatistics()
    private var angularityStats = RunningStatistics()
    private var dirChangeStats = RunningStatistics()
    private var areaStats = RunningStatistics()
    private var speedVarianceStats = RunningStatistics()

    // Metrics cache
    private var cachedMetrics: StrokeMetrics?
    private var metricsDirty = true

    // EMA state
    private var smoothedScores: [Mood: Double] = [:]
    private var lastMoodChangeTime: Date?
    private var canvasSize: CGSize = CGSize(width: 400, height: 800)

    private let emaAlpha: CGFloat = 0.35
    private let moodSwitchDelay: TimeInterval = 0.6

    // Russell circumplex mood centers (valence, arousal)
    private let moodCenters: [Mood: ValenceArousal] = [
        .joy:     ValenceArousal(valence: 0.7, arousal: 0.4),
        .calm:    ValenceArousal(valence: 0.4, arousal: -0.6),
        .anxiety: ValenceArousal(valence: -0.4, arousal: 0.6),
        .sadness: ValenceArousal(valence: -0.5, arousal: -0.7),
        .anger:   ValenceArousal(valence: -0.8, arousal: 0.9),
    ]
    private let gaussianSigma: Double = 0.6

    // MARK: - Public API

    func setCanvasSize(_ size: CGSize) {
        canvasSize = size
    }

    func addPoint(_ location: CGPoint, timestamp: Date, force: CGFloat = 0.5) {
        let point = TouchPoint(
            location: location, timestamp: timestamp,
            force: force, strokeID: currentStrokeID
        )
        windowPoints.append(point)
        metricsDirty = true

        // Feed running statistics for adaptive normalization
        if windowPoints.count >= 2 {
            let prev = windowPoints[windowPoints.count - 2]
            let dist = prev.location.distance(to: location)
            let dt = timestamp.timeIntervalSince(prev.timestamp)
            if dt > 0 && prev.strokeID == currentStrokeID {
                speedStats.push(Double(dist / CGFloat(dt)))
            }
        }
        pressureStats.push(Double(force))
    }

    func endStroke() {
        currentStrokeID += 1
        metricsDirty = true
    }

    func reset() {
        windowPoints.removeAll()
        currentStrokeID = 0
        smoothedScores.removeAll()
        lastMoodChangeTime = nil
        cachedMetrics = nil
        metricsDirty = true
        speedStats.reset()
        pressureStats.reset()
        curvatureStats.reset()
        jitterStats.reset()
        angularityStats.reset()
        dirChangeStats.reset()
        areaStats.reset()
        speedVarianceStats.reset()
    }

    // MARK: - Window Management

    private func pruneWindow() {
        guard let latest = windowPoints.last else { return }
        let cutoff = latest.timestamp.addingTimeInterval(-windowDuration)
        windowPoints.removeAll { $0.timestamp < cutoff }
    }

    // MARK: - Metrics Computation (window-based)

    func computeMetrics() -> StrokeMetrics {
        if !metricsDirty, let cached = cachedMetrics { return cached }
        pruneWindow()
        guard windowPoints.count >= 2 else { return StrokeMetrics() }

        var metrics = StrokeMetrics()
        var speedValues: [CGFloat] = []
        var dirChanges = 0
        var angularCount = 0
        var totalTriplets = 0
        var downwardCount = 0
        var totalMovements = 0
        var pauseCount = 0
        var curvatureSum: CGFloat = 0
        var curvatureCount = 0
        var hasPencilInput = false

        var minX: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude

        // Include first point in bounds
        minX = min(minX, windowPoints[0].location.x)
        maxX = max(maxX, windowPoints[0].location.x)
        minY = min(minY, windowPoints[0].location.y)
        maxY = max(maxY, windowPoints[0].location.y)

        // Pass 1: speeds, bounds, basic stats
        for i in 1..<windowPoints.count {
            let prev = windowPoints[i - 1]
            let curr = windowPoints[i]

            // Skip across stroke boundaries
            guard prev.strokeID == curr.strokeID else { continue }

            let dist = prev.location.distance(to: curr.location)
            let dt = curr.timestamp.timeIntervalSince(prev.timestamp)
            guard dt > 0 else { continue }

            let speed = dist / CGFloat(dt)
            speedValues.append(speed)

            if curr.location.y > prev.location.y { downwardCount += 1 }
            totalMovements += 1
            if dt > 0.3 { pauseCount += 1 }
            if abs(curr.force - 0.5) > 0.01 { hasPencilInput = true }

            minX = min(minX, curr.location.x)
            maxX = max(maxX, curr.location.x)
            minY = min(minY, curr.location.y)
            maxY = max(maxY, curr.location.y)
        }

        // Pass 2: direction changes, curvature, angularity
        for i in 2..<windowPoints.count {
            let p0 = windowPoints[i - 2]
            let p1 = windowPoints[i - 1]
            let p2 = windowPoints[i]

            guard p0.strokeID == p1.strokeID && p1.strokeID == p2.strokeID else { continue }

            let v1 = p1.location - p0.location
            let v2 = p2.location - p1.location
            let mag1 = v1.magnitude
            let mag2 = v2.magnitude
            guard mag1 > 0 && mag2 > 0 else { continue }

            let dot = v1.dx * v2.dx + v1.dy * v2.dy
            let cosAngle = dot / (mag1 * mag2)
            if cosAngle < 0 { dirChanges += 1 }
            if cosAngle < -0.5 { angularCount += 1 }
            totalTriplets += 1

            let cross = abs(v1.dx * v2.dy - v1.dy * v2.dx)
            curvatureSum += cross / (mag1 * mag2)
            curvatureCount += 1
        }

        let avgSpeed = speedValues.isEmpty ? 0 : speedValues.reduce(0, +) / CGFloat(speedValues.count)
        let variance = speedValues.isEmpty ? 0 :
            speedValues.reduce(0) { $0 + pow($1 - avgSpeed, 2) } / CGFloat(speedValues.count)

        // Jitter: std dev of consecutive speed differences
        var jitter: CGFloat = 0
        if speedValues.count >= 3 {
            var diffs: [CGFloat] = []
            for i in 1..<speedValues.count {
                diffs.append(abs(speedValues[i] - speedValues[i - 1]))
            }
            let meanDiff = diffs.reduce(0, +) / CGFloat(diffs.count)
            jitter = sqrt(diffs.reduce(0) { $0 + pow($1 - meanDiff, 2) } / CGFloat(diffs.count))
        }

        // Speed trend: second half avg minus first half avg
        var speedTrend: CGFloat = 0
        if speedValues.count >= 4 {
            let mid = speedValues.count / 2
            let firstHalf = speedValues[..<mid].reduce(0, +) / CGFloat(mid)
            let secondHalf = speedValues[mid...].reduce(0, +) / CGFloat(speedValues.count - mid)
            speedTrend = secondHalf - firstHalf
        }

        // Pressure variance
        let forces = windowPoints.map(\.force)
        let avgPressure = forces.reduce(0, +) / CGFloat(forces.count)
        let pressureVar = forces.reduce(0) { $0 + pow($1 - avgPressure, 2) } / CGFloat(forces.count)

        let totalTime = windowPoints.last!.timestamp.timeIntervalSince(windowPoints.first!.timestamp)
        let canvasArea = max(canvasSize.width * canvasSize.height, 1)
        let coveredArea = max((maxX - minX) * (maxY - minY), 0)
        let strokeIDs = Set(windowPoints.map(\.strokeID))

        metrics.instantSpeed = speedValues.last ?? 0
        metrics.averageSpeed = avgSpeed
        metrics.speedVariance = variance
        metrics.pressure = avgPressure
        metrics.strokeDensity = CGFloat(windowPoints.count) / max(coveredArea, 1) * 1000
        metrics.directionChanges = dirChanges
        metrics.pauseFrequency = totalTime > 0 ? CGFloat(pauseCount) / CGFloat(totalTime) : 0
        metrics.touchArea = coveredArea / canvasArea
        metrics.downwardRatio = totalMovements > 0 ? CGFloat(downwardCount) / CGFloat(totalMovements) : 0.5
        metrics.curvature = curvatureCount > 0 ? curvatureSum / CGFloat(curvatureCount) : 0
        metrics.jitter = jitter
        metrics.averageCurvature = metrics.curvature
        metrics.angularity = totalTriplets > 0 ? CGFloat(angularCount) / CGFloat(totalTriplets) : 0
        metrics.strokeCount = strokeIDs.count
        metrics.speedTrend = speedTrend
        metrics.pressureVariance = pressureVar
        metrics.hasPencil = hasPencilInput

        // Feed adaptive stats
        curvatureStats.push(Double(metrics.curvature))
        jitterStats.push(Double(jitter))
        angularityStats.push(Double(metrics.angularity))
        dirChangeStats.push(Double(dirChanges))
        areaStats.push(Double(metrics.touchArea))
        speedVarianceStats.push(Double(variance))

        cachedMetrics = metrics
        metricsDirty = false
        return metrics
    }

    // MARK: - Russell Circumplex Mood Scoring

    func computeMoodScores() -> [Mood: Double] {
        let m = computeMetrics()

        // Phase A: Features → Valence-Arousal via z-score normalization
        let zSpeed = clampZ(speedStats.zScore(for: Double(m.averageSpeed)))
        let zPressure = clampZ(pressureStats.zScore(for: Double(m.pressure)))
        let zSpeedVar = clampZ(speedVarianceStats.zScore(for: Double(m.speedVariance)))
        let zJitter = clampZ(jitterStats.zScore(for: Double(m.jitter)))
        let zCurvature = clampZ(curvatureStats.zScore(for: Double(m.curvature)))
        let zAngularity = clampZ(angularityStats.zScore(for: Double(m.angularity)))
        let zDirChanges = clampZ(dirChangeStats.zScore(for: Double(m.directionChanges)))
        let zArea = clampZ(areaStats.zScore(for: Double(m.touchArea)))

        var arousal: Double
        if m.hasPencil {
            // With Apple Pencil: pressure contributes to arousal
            arousal = 0.4 * zSpeed + 0.3 * zPressure + 0.2 * zSpeedVar + 0.1 * zJitter
        } else {
            // No pencil: drop pressure, redistribute weights
            arousal = 0.55 * zSpeed + 0.3 * zSpeedVar + 0.15 * zJitter
        }

        let valence = 0.4 * zCurvature - 0.3 * zAngularity
            + 0.2 * (1.0 - zDirChanges) + 0.1 * zArea

        // Clamp to [-1, 1]
        let clampedArousal = max(-1, min(1, arousal))
        let clampedValence = max(-1, min(1, valence))

        // Phase B: VA → mood scores via Gaussian distance
        let sigmaSquared = gaussianSigma * gaussianSigma
        var scores: [Mood: Double] = [:]

        for mood in Mood.allCases {
            guard let center = moodCenters[mood] else { continue }
            let dv = clampedValence - center.valence
            let da = clampedArousal - center.arousal
            let distSq = dv * dv + da * da
            scores[mood] = exp(-distSq / (2.0 * sigmaSquared))
        }

        return scores
    }

    // MARK: - Smoothing (softmax + EMA)

    func smoothScores(_ raw: [Mood: Double]) -> [Mood: Double] {
        // Softmax normalization (subtract max for numerical stability)
        let maxScore = raw.values.max() ?? 0
        var expScores: [Mood: Double] = [:]
        var expSum: Double = 0
        for mood in Mood.allCases {
            let e = exp((raw[mood] ?? 0) - maxScore)
            expScores[mood] = e
            expSum += e
        }
        var normalized: [Mood: Double] = [:]
        for mood in Mood.allCases {
            normalized[mood] = (expScores[mood] ?? 0) / max(expSum, 1e-9)
        }

        // EMA blending
        var result: [Mood: Double] = [:]
        let defaultPrior = 1.0 / Double(Mood.allCases.count)
        for mood in Mood.allCases {
            let prev = smoothedScores[mood] ?? defaultPrior
            let new = normalized[mood] ?? 0
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
            totalPoints: windowPoints.count,
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

    // MARK: - Helpers

    /// Maps z-score to [-1, 1] range by clamping to ±2 then halving
    private func clampZ(_ z: Double) -> Double {
        max(-2, min(2, z)) / 2.0
    }
}
