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

    var insight: String {
        switch self {
        case .joy: "Your strokes carry warmth and openness — a sign of positive energy flowing through you."
        case .calm: "Slow, smooth movements reflect a centered mind. You're in a grounded state."
        case .anxiety: "Rapid, scattered patterns suggest restless energy. Your body is signaling a need to slow down."
        case .sadness: "Gentle, downward strokes hint at heaviness. It's okay to sit with this feeling."
        case .anger: "Sharp, forceful marks reveal intense energy seeking release."
        }
    }

    var tips: [String] {
        switch self {
        case .joy: [
            "Share this energy — reach out to someone you care about",
            "Capture this moment in a few written words to revisit later"
        ]
        case .calm: [
            "Try slow deep breathing to sustain this peace",
            "Gentle stretching can deepen this relaxation"
        ]
        case .anxiety: [
            "Place one hand on your chest and breathe in for 4, hold for 4, out for 6",
            "Name 5 things you can see right now to anchor yourself"
        ]
        case .sadness: [
            "A short walk outside, even 5 minutes, can gently shift your state",
            "Listen to a song that lets you feel without rushing past it"
        ]
        case .anger: [
            "Squeeze and release your fists slowly — let the tension drain out",
            "Splash cold water on your face to activate your body's calm reflex"
        ]
        }
    }

    static func dominant(from scores: [Mood: Double]) -> Mood {
        scores.max(by: { $0.value < $1.value })?.key ?? .calm
    }
}
