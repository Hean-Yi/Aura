import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AuraDetailView: View {
    let entry: AuraEntry

    private var moodScoresTyped: [Mood: Double] {
        var result: [Mood: Double] = [:]
        for (key, value) in entry.moodScores {
            if let mood = Mood(rawValue: key) {
                result[mood] = value
            }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                snapshotImage
                moodHeader
                radarSection
                detailsSection
            }
            .padding(.bottom, 40)
        }
        .background(Color.auraBackground.ignoresSafeArea())
        .navigationTitle(entry.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private var snapshotImage: some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(data: entry.canvasSnapshot) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
        }
        #endif
    }

    private var moodHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.mood.icon)
                .font(.title2)
                .foregroundStyle(entry.mood.color)
            Text(entry.mood.label)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Color.auraText)
        }
    }

    private var radarSection: some View {
        VStack(spacing: 8) {
            Text("Emotion Blend")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(Color.auraText.opacity(0.5))

            MoodRadarChart(scores: moodScoresTyped, dominantMood: entry.mood)
                .frame(height: 260)
                .padding(.horizontal, 24)
        }
    }

    private var detailsSection: some View {
        HStack(spacing: 32) {
            detailItem(label: "Date", value: entry.date.formatted(date: .abbreviated, time: .omitted))
            detailItem(label: "Duration", value: formatDuration(entry.duration))
        }
        .padding(.top, 8)
    }

    private func detailItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.auraText.opacity(0.4))
            Text(value)
                .font(.system(.callout, design: .serif))
                .foregroundStyle(Color.auraText)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s"
    }
}
