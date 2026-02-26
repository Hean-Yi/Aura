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

    var moodScores: [String: Double] {
        (try? JSONDecoder().decode([String: Double].self, from: moodScoresData)) ?? [:]
    }

    var mood: Mood {
        Mood(rawValue: dominantMood) ?? .calm
    }

    var strokeSummary: StrokeMetricsSummary {
        (try? JSONDecoder().decode(StrokeMetricsSummary.self, from: strokeSummaryData)) ?? StrokeMetricsSummary()
    }
}
