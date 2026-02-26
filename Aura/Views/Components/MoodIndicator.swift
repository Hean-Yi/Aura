import SwiftUI

struct MoodIndicator: View {
    let mood: Mood
    @Environment(\.colorSchemeContrast) var contrast

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(mood.color)
                .frame(width: 10, height: 10)

            Text(mood.label)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(Color.auraText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current mood: \(mood.label)")
    }
}
