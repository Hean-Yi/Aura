import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentStep = 0

    private let steps = [
        OnboardingStep(
            title: "Your emotions\nhave shape",
            subtitle: "Draw freely. Particles will find their form.",
            animation: .particles
        ),
        OnboardingStep(
            title: "Five moods,\none canvas",
            subtitle: "Speed, pressure, rhythm — your strokes reveal how you feel.",
            animation: .moodCycle
        ),
        OnboardingStep(
            title: "Breathe when\nyou need to",
            subtitle: "A gentle guide to bring you back to calm.",
            animation: .breath
        ),
        OnboardingStep(
            title: "Each day,\none Aura",
            subtitle: "A diary only you can read.",
            animation: .gallery
        )
    ]

    var body: some View {
        ZStack {
            Color.auraBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Animation area (~55% height)
                animationView
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .id(currentStep)
                    .transition(.opacity)

                // Text + controls area
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text(steps[currentStep].title)
                            .font(.system(.title, design: .serif))
                            .foregroundStyle(Color.auraText)
                            .multilineTextAlignment(.center)
                            .id("title\(currentStep)")
                            .transition(.opacity)

                        Text(steps[currentStep].subtitle)
                            .font(.system(.callout, design: .default))
                            .foregroundStyle(Color.auraText.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .id("sub\(currentStep)")
                            .transition(.opacity)
                    }
                    .padding(.horizontal, 36)

                    progressDots

                    continueButton
                        .padding(.bottom, 50)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }

    @ViewBuilder
    private var animationView: some View {
        switch steps[currentStep].animation {
        case .particles:
            OnboardingParticleAnimation()
        case .moodCycle:
            OnboardingMoodCycleAnimation()
        case .breath:
            OnboardingBreathAnimation()
        case .gallery:
            OnboardingGalleryAnimation()
        }
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

private enum AnimationType {
    case particles, moodCycle, breath, gallery
}

private struct OnboardingStep {
    let title: String
    let subtitle: String
    let animation: AnimationType
}
