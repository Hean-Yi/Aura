# Aura

Aura is a SwiftUI emotion-journaling app built for the Swift Student Challenge 2026.  
Users draw on a canvas, the app infers mood from stroke behavior, and renders mood-specific particle patterns.

## Features

- Non-verbal emotion check-in through drawing
- Real-time mood inference from stroke metrics (speed, pressure, rhythm)
- Mood-specific particle visuals (Joy, Calm, Anxiety, Sadness, Anger)
- Onboarding flow with interactive particle animations
- Gallery + Insights views backed by SwiftData

## Tech Stack

- Swift 5
- SwiftUI
- SwiftData
- Zero third-party dependencies

## Project Structure

- `Aura/Engine/` core analysis and particle logic
- `Aura/Views/` screens and onboarding flows
- `Aura/Models/` mood and persistence models
- `Aura/Utilities/` shared helpers/extensions
- `Aura/Assets.xcassets/` app assets

## Build

```bash
xcodebuild -project Aura.xcodeproj -scheme Aura -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Or open in Xcode:

```bash
open Aura.xcodeproj
```

## Notes

- Target: iOS 26.2
- Default actor isolation: `MainActor`
