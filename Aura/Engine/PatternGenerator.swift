import Foundation

struct PatternGenerator {
    func generateAnchors(for mood: Mood, center: CGPoint, radius: CGFloat, time: Double = 0) -> [CGPoint] {
        switch mood {
        case .joy:     return joyAnchors(center: center, radius: radius, time: time)
        case .calm:    return calmAnchors(center: center, radius: radius, time: time)
        case .anxiety: return anxietyAnchors(center: center, radius: radius, time: time)
        case .sadness: return sadnessAnchors(center: center, radius: radius, time: time)
        case .anger:   return angerAnchors(center: center, radius: radius, time: time)
        }
    }

    // Joy — sunflower / radiating petals
    private func joyAnchors(center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        var anchors: [CGPoint] = []
        let petalCount = 10
        let rotation = CGFloat(time * 0.008)

        for i in 0..<petalCount {
            let baseAngle = CGFloat(i) / CGFloat(petalCount) * .pi * 2 + rotation
            for j in 0..<10 {
                let t = CGFloat(j) / 10.0
                let breathe = 1.0 + 0.05 * sin(CGFloat(time * 2.0) + CGFloat(i))
                let r = radius * t * (0.5 + 0.5 * sin(t * .pi)) * breathe
                let angle = baseAngle + sin(t * .pi) * 0.3
                anchors.append(CGPoint(
                    x: center.x + cos(angle) * r,
                    y: center.y + sin(angle) * r
                ))
            }
        }
        return anchors
    }

    // Calm — concentric ripples
    private func calmAnchors(center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        var anchors: [CGPoint] = []
        let ringCount = 4
        let pointsPerRing = 24

        for ring in 0..<ringCount {
            let baseR = CGFloat(ring + 1) / CGFloat(ringCount) * radius
            let ripple = 3.0 * sin(CGFloat(time * 1.5) + CGFloat(ring) * 1.2)
            let r = baseR + ripple

            for p in 0..<pointsPerRing {
                let angle = CGFloat(p) / CGFloat(pointsPerRing) * .pi * 2
                anchors.append(CGPoint(
                    x: center.x + cos(angle) * r,
                    y: center.y + sin(angle) * r
                ))
            }
        }
        return anchors
    }

    // Anxiety — fractured triangular grid
    private func anxietyAnchors(center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        var anchors: [CGPoint] = []
        let nodeCount = 20
        let seed = Int(time * 0.5)

        for i in 0..<nodeCount {
            let hash = Double((i * 7 + seed * 13) % 997) / 997.0
            let hash2 = Double((i * 11 + seed * 17) % 991) / 991.0
            let jitter = 2.0 * sin(time * 3.0 + Double(i))

            let x = center.x + CGFloat(hash - 0.5) * radius * 2 + CGFloat(jitter)
            let y = center.y + CGFloat(hash2 - 0.5) * radius * 2 + CGFloat(jitter * 0.7)
            anchors.append(CGPoint(x: x, y: y))
        }

        let nodes = anchors
        for i in 0..<nodes.count {
            for j in (i+1)..<nodes.count {
                if nodes[i].distance(to: nodes[j]) < radius * 0.8 {
                    anchors.append(nodes[i].lerp(to: nodes[j], t: 0.5))
                }
            }
        }
        return anchors
    }

    // Sadness — falling rain streaks
    private func sadnessAnchors(center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        var anchors: [CGPoint] = []
        let streamCount = 6
        let pointsPerStream = 15

        for s in 0..<streamCount {
            let baseX = center.x + CGFloat(s - streamCount / 2) * (radius * 0.4)
            let curve = 8.0 * sin(CGFloat(s) * 0.5)

            for p in 0..<pointsPerStream {
                let t = CGFloat(p) / CGFloat(pointsPerStream)
                let fallOffset = CGFloat(fmod(time * 0.3 + Double(s) * 0.2, 1.0))
                let y = center.y - radius + t * radius * 2 + fallOffset * 20
                let x = baseX + curve * t
                anchors.append(CGPoint(x: x, y: y))
            }
        }
        return anchors
    }

    // Breathing — static concentric circles scaled by breathFactor
    func breathingAnchors(center: CGPoint, baseRadius: CGFloat, breathFactor: CGFloat) -> [CGPoint] {
        var anchors: [CGPoint] = []
        let ringCount = 4
        let pointsPerRing = 24

        for ring in 0..<ringCount {
            let r = CGFloat(ring + 1) / CGFloat(ringCount) * baseRadius * breathFactor
            for p in 0..<pointsPerRing {
                let angle = CGFloat(p) / CGFloat(pointsPerRing) * .pi * 2
                anchors.append(CGPoint(
                    x: center.x + cos(angle) * r,
                    y: center.y + sin(angle) * r
                ))
            }
        }
        return anchors
    }

    // Anger — sharp radiating spikes
    private func angerAnchors(center: CGPoint, radius: CGFloat, time: Double) -> [CGPoint] {
        var anchors: [CGPoint] = []
        let spikeCount = 6
        let pointsPerSpike = 12

        for s in 0..<spikeCount {
            let baseAngle = CGFloat(s) / CGFloat(spikeCount) * .pi * 2
            let spikeLen = radius * CGFloat(0.6 + 0.4 * Double((s * 3 + 7) % 11) / 11.0)
            let pulse = 1.0 + 0.2 * sin(CGFloat(time * 5.0) + CGFloat(s))

            for p in 0..<pointsPerSpike {
                let t = CGFloat(p) / CGFloat(pointsPerSpike)
                let r = spikeLen * t * pulse
                let fork = t > 0.8 ? (t - 0.8) * 0.4 : 0
                let angle = baseAngle + fork * (p % 2 == 0 ? 1 : -1)
                anchors.append(CGPoint(
                    x: center.x + cos(angle) * r,
                    y: center.y + sin(angle) * r
                ))
            }
        }
        return anchors
    }
}