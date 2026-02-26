import SwiftUI

enum Mood: String, CaseIterable, Codable, Identifiable {
    case joy, calm, anxiety, sadness, anger

    var id: String { rawValue }

    var label: String {
        switch self {
        case .joy: "Joy"
        case .calm: "Calm"
        case .anxiety: "Anxiety"
        case .sadness: "Sadness"
        case .anger: "Anger"
        }
    }

    var colors: [Color] {
        switch self {
        case .joy:     [Color(hex: "D4A574"), Color(hex: "C4956A"), Color(hex: "E8C9A0")]
        case .calm:    [Color(hex: "8BA4B8"), Color(hex: "A3B8C8"), Color(hex: "C2D1DB")]
        case .anxiety: [Color(hex: "9B8EA8"), Color(hex: "B5A8C0"), Color(hex: "7D7289")]
        case .sadness: [Color(hex: "6B7B8D"), Color(hex: "5A6A7D"), Color(hex: "8895A3")]
        case .anger:   [Color(hex: "B07060"), Color(hex: "C4806E"), Color(hex: "8B5E52")]
        }
    }

    var color: Color { colors[0] }

    var icon: String {
        switch self {
        case .joy: "sun.max.fill"
        case .calm: "drop.fill"
        case .anxiety: "bolt.fill"
        case .sadness: "cloud.rain.fill"
        case .anger: "flame.fill"
        }
    }

    static func dominant(from scores: [Mood: Double]) -> Mood {
        scores.max(by: { $0.value < $1.value })?.key ?? .calm
    }
}
