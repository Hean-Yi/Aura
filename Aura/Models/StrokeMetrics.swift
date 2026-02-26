import Foundation

// MARK: - Welford Online Statistics

struct RunningStatistics {
    private(set) var count: Int = 0
    private var m2: Double = 0
    private(set) var mean: Double = 0

    mutating func push(_ value: Double) {
        count += 1
        let delta = value - mean
        mean += delta / Double(count)
        let delta2 = value - mean
        m2 += delta * delta2
    }

    var stddev: Double {
        count < 2 ? 1.0 : sqrt(m2 / Double(count - 1))
    }

    func zScore(for value: Double) -> Double {
        let s = stddev
        guard s > 1e-9 else { return 0 }
        return (value - mean) / s
    }

    mutating func reset() {
        count = 0; m2 = 0; mean = 0
    }
}

// MARK: - Russell Circumplex Intermediate

struct ValenceArousal {
    var valence: Double = 0   // -1 (negative) … +1 (positive)
    var arousal: Double = 0   // -1 (low) … +1 (high)
}

// MARK: - Stroke Metrics

struct StrokeMetrics {
    var instantSpeed: CGFloat = 0
    var averageSpeed: CGFloat = 0
    var speedVariance: CGFloat = 0
    var pressure: CGFloat = 0.5
    var curvature: CGFloat = 0
    var strokeDensity: CGFloat = 0
    var directionChanges: Int = 0
    var pauseFrequency: CGFloat = 0
    var touchArea: CGFloat = 0
    var downwardRatio: CGFloat = 0.5

    // New fields for Russell model
    var jitter: CGFloat = 0
    var averageCurvature: CGFloat = 0
    var angularity: CGFloat = 0
    var strokeCount: Int = 0
    var speedTrend: CGFloat = 0
    var pressureVariance: CGFloat = 0
    var hasPencil: Bool = false
}

struct StrokeMetricsSummary: Codable, Hashable {
    var totalPoints: Int = 0
    var averageSpeed: CGFloat = 0
    var averagePressure: CGFloat = 0.5
    var coveragePercent: CGFloat = 0
}

struct TouchPoint {
    var location: CGPoint
    var timestamp: Date
    var force: CGFloat
    var strokeID: Int = 0
}
