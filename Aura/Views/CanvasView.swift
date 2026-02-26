import SwiftUI
import SwiftData

struct CanvasView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var particleSystem = ParticleSystem()
    @State private var strokeAnalyzer = StrokeAnalyzer()
    @State private var patternGenerator = PatternGenerator()
    @State private var currentMood: Mood = .calm
    @State private var currentAnchors: [CGPoint] = []
    @State private var animationTime: Double = 0
    @State private var canvasSize: CGSize = .zero
    @State private var showSaveConfirmation = false
    @State private var creationStartTime: Date = .now
    @State private var hasDrawn = false
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ZStack {
            Color.auraBackground.ignoresSafeArea()

            canvasLayer

            VStack {
                if hasDrawn {
                    MoodIndicator(mood: currentMood)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                if hasDrawn {
                    saveButton
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if !hasDrawn {
                    Text("draw freely")
                        .font(.system(.callout, design: .serif))
                        .foregroundStyle(Color.auraText.opacity(0.3))
                        .padding(.bottom, 40)
                }
            }
            .padding(.top, 16)
            .animation(.easeInOut(duration: 0.5), value: hasDrawn)
        }
        .overlay {
            if showSaveConfirmation {
                saveConfirmationOverlay
            }
        }
    }

    private var canvasLayer: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                if canvasSize != size {
                    DispatchQueue.main.async {
                        canvasSize = size
                        strokeAnalyzer.setCanvasSize(size)
                    }
                }

                let now = timeline.date.timeIntervalSinceReferenceDate
                DispatchQueue.main.async {
                    animationTime = now
                    updateParticles()
                }

                for particle in particleSystem.particles {
                    let opacityMult: CGFloat = contrast == .increased ? 1.5 : 1.0
                    let rect = CGRect(
                        x: particle.position.x - particle.size / 2,
                        y: particle.position.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color.opacity(particle.opacity * opacityMult))
                    )
                }
            }
            .gesture(drawGesture)
        }
        .accessibilityLabel("Drawing canvas")
        .accessibilityHint("Draw freely to express your emotions. The app will interpret your mood from your drawing.")
    }

    private var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !hasDrawn {
                    hasDrawn = true
                    creationStartTime = .now
                }
                strokeAnalyzer.addPoint(value.location, timestamp: Date())
                spawnParticles(at: value.location)
                updateMoodInference()
            }
            .onEnded { _ in
                strokeAnalyzer.endStroke()
            }
    }

    private var saveButton: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.easeInOut(duration: 0.4)) {
                    resetCanvas()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.body)
                    .foregroundStyle(Color.auraText)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Clear canvas")

            Button {
                saveAura()
            } label: {
                Text("Save Aura")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color.auraText)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(.bottom, 30)
    }

    private var saveConfirmationOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: currentMood.icon)
                .font(.largeTitle)
                .foregroundStyle(currentMood.color)

            Text("Aura Saved")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Color.auraText)
        }
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Logic
extension CanvasView {
    private func spawnParticles(at point: CGPoint) {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let radius = min(canvasSize.width, canvasSize.height) * 0.35
        if currentAnchors.isEmpty {
            currentAnchors = patternGenerator.generateAnchors(
                for: currentMood, center: center, radius: radius, time: animationTime
            )
        }
        particleSystem.spawnParticles(at: point, count: 3, mood: currentMood, anchors: currentAnchors)
    }

    private func updateParticles() {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let radius = min(canvasSize.width, canvasSize.height) * 0.35
        currentAnchors = patternGenerator.generateAnchors(
            for: currentMood, center: center, radius: radius, time: animationTime
        )
        particleSystem.update(time: animationTime, mood: currentMood)
    }

    private func updateMoodInference() {
        let raw = strokeAnalyzer.computeMoodScores()
        let smoothed = strokeAnalyzer.smoothScores(raw)
        let newMood = Mood.dominant(from: smoothed)

        if strokeAnalyzer.shouldSwitchMood(to: newMood, current: currentMood) {
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) * 0.35
            let newAnchors = patternGenerator.generateAnchors(
                for: newMood, center: center, radius: radius, time: animationTime
            )
            particleSystem.transitionToAnchors(newAnchors, mood: newMood)
            currentAnchors = newAnchors
            currentMood = newMood
        }
    }

    private func saveAura() {
        let duration = Date.now.timeIntervalSince(creationStartTime)
        let summary = strokeAnalyzer.makeSummary()
        let scoresDict = strokeAnalyzer.makeScoresDict()

        // Generate a snapshot from the particle state
        let snapshotData = renderSnapshot()

        let entry = AuraEntry(
            date: .now,
            moodScores: scoresDict,
            dominantMood: currentMood,
            canvasSnapshot: snapshotData,
            strokeSummary: summary,
            duration: duration
        )
        modelContext.insert(entry)

        withAnimation(.spring(duration: 0.6)) {
            showSaveConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSaveConfirmation = false }
            resetCanvas()
        }
    }

    private func renderSnapshot() -> Data {
        let size = CGSize(width: 400, height: 400)
        let renderer = ImageRenderer(content:
            Canvas { context, sz in
                context.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(Color.auraBackground))
                for particle in particleSystem.particles {
                    let rect = CGRect(
                        x: particle.position.x * sz.width / max(canvasSize.width, 1) - particle.size / 2,
                        y: particle.position.y * sz.height / max(canvasSize.height, 1) - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color.opacity(particle.opacity))
                    )
                }
            }
            .frame(width: size.width, height: size.height)
        )
        renderer.scale = 2.0
        #if canImport(UIKit)
        if let uiImage = renderer.uiImage, let data = uiImage.pngData() {
            return data
        }
        #endif
        return Data()
    }

    private func resetCanvas() {
        particleSystem.clear()
        strokeAnalyzer.reset()
        currentMood = .calm
        currentAnchors = []
        hasDrawn = false
    }
}