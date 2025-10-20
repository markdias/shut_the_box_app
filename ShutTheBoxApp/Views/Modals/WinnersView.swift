import SwiftUI

struct WinnersView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(store.winners) { winner in
                VStack(alignment: .leading, spacing: 6) {
                    Text(winner.playerName)
                        .font(.headline)
                    Text("Score: \(winner.score) · Tiles: \(winner.tilesShut)")
                        .font(.subheadline)
                    Text(winner.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Round Winners")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}
