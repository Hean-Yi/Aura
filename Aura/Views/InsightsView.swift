import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \AuraEntry.date, order: .reverse) private var entries: [AuraEntry]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraBackground.ignoresSafeArea()

                if entries.isEmpty {
                    emptyState
                } else {
                    scrollContent
                }
            }
            .navigationTitle("Insights")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

extension InsightsView {
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.largeTitle)
                .foregroundStyle(Color.auraText.opacity(0.3))
            Text("Create some Auras to see insights")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color.auraText.opacity(0.5))
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Mood distribution chart
                insightCard(title: "Mood Distribution") {
                    MoodDistributionChart(entries: entries)
                }

                // Week heat strip
                insightCard(title: "This Week") {
                    WeekHeatStrip(entries: entries)
                }

                // Stats row
                insightCard(title: "Stats") {
                    statsRow
                }
            }
            .padding()
        }
    }

    private func insightCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Color.auraText)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.auraText.opacity(0.08), lineWidth: 1)
        )
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            statItem(value: "\(entries.count)", label: "Total Auras")
            statItem(value: "\(streakDays)", label: "Day Streak")
            statItem(value: dominantMoodLabel, label: "Top Mood")
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Color.auraText)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.auraText.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var streakDays: Int {
        var streak = 0
        var checkDate = Date.now
        let cal = Calendar.current
        for _ in 0..<30 {
            if entries.contains(where: { cal.isDate($0.date, inSameDayAs: checkDate) }) {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    private var dominantMoodLabel: String {
        let counts = Dictionary(grouping: entries, by: { $0.dominantMood })
        return counts.max(by: { $0.value.count < $1.value.count })
            .flatMap { Mood(rawValue: $0.key)?.label } ?? "—"
    }
}
