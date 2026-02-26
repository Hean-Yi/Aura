import Foundation
import SwiftData

@Model
class AuraEntry {
    var id: UUID
    var date: Date
    var moodScoresData: Data
    var dominantMood: String
    var canvasSnapshot: Data
    var strokeSummaryData: Data
    var duration: TimeInterval

    init(
        date: Date,
        moodScores: [String: Double],
        dominantMood: Mood,
        canvasSnapshot: Data,
        strokeSummary: StrokeMetricsSummary,
        duration: TimeInterval
    ) {
        self.id = UUID()
        self.date = date
        self.moodScoresData = (try? JSONEncoder().encode(moodScores)) ?? Data()
        self.dominantMood = dominantMood.rawValue
        self.canvasSnapshot = canvasSnapshot
        self.strokeSummaryData = (try? JSONEncoder().encode(strokeSummary)) ?? Data()
        self.duration = duration
    }

    @Transient private var _cachedMoodScores: [String: Double]?
    @Transient private var _cachedStrokeSummary: StrokeMetricsSummary?

    var moodScores: [String: Double] {
        if let cached = _cachedMoodScores { return cached }
        let decoded = (try? JSONDecoder().decode([String: Double].self, from: moodScoresData)) ?? [:]
        _cachedMoodScores = decoded
        return decoded
    }

    var mood: Mood {
        Mood(rawValue: dominantMood) ?? .calm
    }

    var strokeSummary: StrokeMetricsSummary {
        if let cached = _cachedStrokeSummary { return cached }
        let decoded = (try? JSONDecoder().decode(StrokeMetricsSummary.self, from: strokeSummaryData)) ?? StrokeMetricsSummary()
        _cachedStrokeSummary = decoded
        return decoded
    }
}
