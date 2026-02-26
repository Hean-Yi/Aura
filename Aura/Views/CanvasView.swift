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
    @State private var isBreathing = false
    @State private var breathingStart: Double = 0
    @State private var breathingDrawTime: Double = 0
    @State private var breathingPhase2 = false
    @State private var lastDrawTimestamp: Double = 0
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ZStack {
            Color.auraBackground.ignoresSafeArea()

            canvasLayer

            VStack {
                if isBreathing {
                    breathingPrompt
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else if hasDrawn {
                    MoodIndicator(mood: currentMood)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                if hasDrawn && !isBreathing {
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
            .animation(.easeInOut(duration: 0.6), value: isBreathing)
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

                // Guide dot during breathing
                if isBreathing {
                    let guidePos = breathingGuidePosition(canvasSize: size, time: now)
                    // Outer glow
                    let glowRect = CGRect(x: guidePos.x - 20, y: guidePos.y - 20, width: 40, height: 40)
                    context.fill(Path(ellipseIn: glowRect), with: .color(Mood.calm.color.opacity(0.12)))
                    // Inner dot
                    let dotRect = CGRect(x: guidePos.x - 6, y: guidePos.y - 6, width: 12, height: 12)
                    context.fill(Path(ellipseIn: dotRect), with: .color(Mood.calm.color.opacity(0.6)))
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
                if isBreathing {
                    // Phase 1: track cumulative draw time
                    if !breathingPhase2 {
                        let now = animationTime
                        if lastDrawTimestamp > 0 {
                            let delta = min(now - lastDrawTimestamp, 0.1)
                            if delta > 0 { breathingDrawTime += delta }
                        }
                        lastDrawTimestamp = now

                        if breathingDrawTime >= 5 {
                            enterBreathingPhase2()
                        }
                    }
                    spawnBreathingParticles(at: value.location)
                } else {
                    strokeAnalyzer.addPoint(value.location, timestamp: Date())
                    spawnParticles(at: value.location)
                    updateMoodInference()
                }
            }
            .onEnded { _ in
                if isBreathing && !breathingPhase2 {
                    lastDrawTimestamp = 0
                }
                if !isBreathing {
                    strokeAnalyzer.endStroke()
                }
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

            if currentMood.isIntense {
                Button {
                    startBreathing()
                } label: {
                    Image(systemName: "wind")
                        .font(.body)
                        .foregroundStyle(Mood.calm.color)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Start breathing guide")
                .transition(.scale.combined(with: .opacity))
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

        if isBreathing {
            if breathingPhase2 {
                // Phase 2: pulsating concentric circles
                let elapsed = animationTime - breathingStart
                let breathFactor = currentBreathFactor(elapsed: elapsed)
                let anchors = patternGenerator.breathingAnchors(
                    center: center, baseRadius: radius, breathFactor: 0.4 + 0.6 * breathFactor
                )
                particleSystem.reassignTargets(anchors)
                currentAnchors = anchors

                // Check completion
                if elapsed >= Self.totalBreathingDuration {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isBreathing = false
                        breathingPhase2 = false
                    }
                    currentMood = .calm
                }
            } else {
                // Phase 1: calm anchors while user draws
                currentAnchors = patternGenerator.generateAnchors(
                    for: .calm, center: center, radius: radius, time: animationTime
                )
            }
        } else {
            currentAnchors = patternGenerator.generateAnchors(
                for: currentMood, center: center, radius: radius, time: animationTime
            )
        }

        particleSystem.update(time: animationTime, mood: isBreathing ? .calm : currentMood)
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
        isBreathing = false
        breathingDrawTime = 0
        breathingPhase2 = false
        lastDrawTimestamp = 0
    }
}

// MARK: - Breathing Guide
extension CanvasView {
    private static let breathCycleDuration: Double = 14 // 4 + 4 + 6
    private static let totalCycles: Int = 4
    private static let totalBreathingDuration: Double = breathCycleDuration * Double(totalCycles) + 2 // +2s outro

    private var breathingElapsed: Double {
        guard isBreathing else { return 0 }
        return animationTime - breathingStart
    }

    private var breathingPrompt: some View {
        Text(breathingText)
            .font(.system(.callout, design: .serif))
            .foregroundStyle(Mood.calm.color)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.8), value: breathingText)
            .padding(.top, 8)
    }

    private var breathingText: String {
        if !breathingPhase2 {
            return "Follow the light..."
        }
        let elapsed = animationTime - breathingStart
        let totalActive = Self.breathCycleDuration * Double(Self.totalCycles)
        if elapsed >= totalActive { return "You're here. You're okay." }
        let phase = elapsed.truncatingRemainder(dividingBy: Self.breathCycleDuration)
        if phase < 4 { return "Breathe in..." }
        if phase < 8 { return "Hold gently..." }
        return "Let it go..."
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: 0.6)) {
            isBreathing = true
            breathingStart = animationTime
            breathingDrawTime = 0
            breathingPhase2 = false
            lastDrawTimestamp = 0
        }
        particleSystem.recolorToCalm()
        currentMood = .calm
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let radius = min(canvasSize.width, canvasSize.height) * 0.35
        currentAnchors = patternGenerator.generateAnchors(
            for: .calm, center: center, radius: radius, time: animationTime
        )
        particleSystem.transitionToAnchors(currentAnchors, mood: .calm)
    }

    private func enterBreathingPhase2() {
        breathingPhase2 = true
        breathingStart = animationTime // reset timer for phase 2 cycles
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let radius = min(canvasSize.width, canvasSize.height) * 0.35
        let anchors = patternGenerator.breathingAnchors(
            center: center, baseRadius: radius, breathFactor: 0.4
        )
        particleSystem.reassignTargets(anchors)
        currentAnchors = anchors
    }

    private func breathingGuidePosition(canvasSize: CGSize, time: Double) -> CGPoint {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let baseRadius: CGFloat = min(canvasSize.width, canvasSize.height) * 0.25

        if breathingPhase2 {
            let elapsed = time - breathingStart
            let breathFactor = currentBreathFactor(elapsed: elapsed)
            let r = baseRadius * (0.4 + 0.6 * breathFactor)
            let a = CGFloat(elapsed) * (.pi * 2 / 4.0) - .pi / 2
            return CGPoint(
                x: center.x + CoreGraphics.cos(a) * r,
                y: center.y + CoreGraphics.sin(a) * r
            )
        } else {
            // Phase 1: fixed orbit for user to follow
            let elapsed = time - breathingStart
            guard elapsed > 0 else { return center }
            let r = baseRadius * 0.7
            let a = CGFloat(elapsed) * (.pi * 2 / 4.0) - .pi / 2
            return CGPoint(
                x: center.x + CoreGraphics.cos(a) * r,
                y: center.y + CoreGraphics.sin(a) * r
            )
        }
    }

    private func currentBreathFactor(elapsed: Double) -> CGFloat {
        let phase = max(elapsed, 0).truncatingRemainder(dividingBy: Self.breathCycleDuration)
        if phase < 4 {
            // Inhale: 0 → 1
            return CGFloat(phase / 4.0)
        } else if phase < 8 {
            // Hold: 1
            return 1.0
        } else {
            // Exhale: 1 → 0
            return CGFloat(1.0 - (phase - 8.0) / 6.0)
        }
    }

    private func spawnBreathingParticles(at point: CGPoint) {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let radius = min(canvasSize.width, canvasSize.height) * 0.35
        let anchors = patternGenerator.generateAnchors(
            for: .calm, center: center, radius: radius, time: animationTime
        )
        particleSystem.spawnParticles(at: point, count: 3, mood: .calm, anchors: anchors)
    }
}