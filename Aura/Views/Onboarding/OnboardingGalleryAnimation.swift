import SwiftUI

struct OnboardingGalleryAnimation: View {
    @State private var appeared = [false, false, false]

    private let cards: [(mood: Mood, daysAgo: Int)] = [
        (.joy, 1), (.calm, 3), (.sadness, 5)
    ]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<3) { index in
                cardView(index: index)
                    .offset(y: appeared[index] ? floatOffset(index) : 60)
                    .opacity(appeared[index] ? 1 : 0)
            }
        }
        .onAppear {
            for i in 0..<3 {
                withAnimation(.easeOut(duration: 0.7).delay(Double(i) * 0.25)) {
                    appeared[i] = true
                }
            }
        }
    }

    private func floatOffset(_ index: Int) -> CGFloat {
        CGFloat(index % 2 == 0 ? -4 : 4)
    }

    @ViewBuilder
    private func cardView(index: Int) -> some View {
        let card = cards[index]
        VStack(spacing: 10) {
            Image(systemName: card.mood.icon)
                .font(.system(size: 22))
                .foregroundStyle(card.mood.color)

            RoundedRectangle(cornerRadius: 4)
                .fill(card.mood.color.opacity(0.15))
                .frame(height: 40)

            Text("\(card.daysAgo)d ago")
                .font(.system(size: 9, design: .serif))
                .foregroundStyle(Color.auraText.opacity(0.35))
        }
        .padding(12)
        .frame(width: 90, height: 130)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.auraText.opacity(0.05))
                .stroke(card.mood.color.opacity(0.15), lineWidth: 1)
        )
    }
}
