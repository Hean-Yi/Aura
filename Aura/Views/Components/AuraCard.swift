import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AuraCard: View {
    let entry: AuraEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage = UIImage(data: entry.canvasSnapshot) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(entry.mood.color.opacity(0.3))
                    .frame(height: 140)
                    .overlay {
                        Image(systemName: entry.mood.icon)
                            .font(.title)
                            .foregroundStyle(entry.mood.color)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.mood.label)
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(entry.mood.color)

                Text(entry.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(Color.auraText.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(Color.auraBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(entry.mood.color.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Aura created on \(entry.date.formatted(date: .abbreviated, time: .omitted)), mood: \(entry.mood.label)")
        .accessibilityHint("Double tap to view full aura")
    }
}
