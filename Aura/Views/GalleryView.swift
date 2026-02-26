import SwiftUI
import SwiftData

struct GalleryView: View {
    @Query(sort: \AuraEntry.date, order: .reverse) private var entries: [AuraEntry]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraBackground.ignoresSafeArea()

                if entries.isEmpty {
                    emptyState
                } else {
                    scrollContent
                }
            }
            .navigationTitle("Gallery")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "circle.dotted")
                .font(.largeTitle)
                .foregroundStyle(Color.auraText.opacity(0.3))
            Text("No Auras yet")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color.auraText.opacity(0.5))
        }
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(entries) { entry in
                    AuraCard(entry: entry)
                }
            }
            .padding()
        }
    }
}