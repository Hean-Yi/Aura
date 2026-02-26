import Foundation

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
}
