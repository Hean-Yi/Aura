import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentStep = 0

    private let steps = [
        OnboardingStep(
            title: "Your emotions are\nnot just words.",
            subtitle: "They are light, movement, and form."
        ),
        OnboardingStep(
            title: "Touch the canvas.\nLet your feelings flow.",
            subtitle: "No labels. No choices. Just you."
        ),
        OnboardingStep(
            title: "Each day, one Aura.",
            subtitle: "A diary only you can read."
        )
    ]

    var body: some View {
        ZStack {
            Color.auraBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 16) {
                    Text(steps[currentStep].title)
                        .font(.system(.title, design: .serif))
                        .foregroundStyle(Color.auraText)
                        .multilineTextAlignment(.center)
                        .id(currentStep)
                        .transition(.opacity)

                    Text(steps[currentStep].subtitle)
                        .font(.system(.body, design: .default))
                        .foregroundStyle(Color.auraText.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .id("sub\(currentStep)")
                        .transition(.opacity)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Progress dots
                progressDots

                // Continue button
                continueButton
                    .padding(.bottom, 60)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentStep)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { i in
                Circle()
                    .fill(i == currentStep ? Color.auraText : Color.auraText.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var continueButton: some View {
        Button {
            if currentStep < steps.count - 1 {
                currentStep += 1
            } else {
                isComplete = true
            }
        } label: {
            Text(currentStep < steps.count - 1 ? "Continue" : "Begin")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color.auraText)
                .frame(width: 200)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

private struct OnboardingStep {
    let title: String
    let subtitle: String
}
