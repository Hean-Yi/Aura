import SwiftUI
import Charts

struct MoodDistributionChart: View {
    var entries: [AuraEntry]

    var body: some View {
        Chart {
            ForEach(Mood.allCases) { mood in
                let count = entries.filter { $0.dominantMood == mood.rawValue }.count
                BarMark(
                    x: .value("Mood", mood.label),
                    y: .value("Count", count)
                )
                .foregroundStyle(mood.color.gradient)
                .cornerRadius(6)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 180)
    }
}

struct WeekHeatStrip: View {
    var entries: [AuraEntry]

    private var last7Days: [Date] {
        (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: .now)
        }.reversed()
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(last7Days, id: \.self) { day in
                let entry = entries.first {
                    Calendar.current.isDate($0.date, inSameDayAs: day)
                }
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(entry?.mood.color ?? Color.gray.opacity(0.2))
                        .frame(height: 32)

                    Text(day, format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                        .foregroundStyle(Color.auraText.opacity(0.5))
                }
            }
        }
    }
}
