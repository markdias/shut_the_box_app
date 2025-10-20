import SwiftUI

struct PlayersView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Players")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: store.addPlayer) {
                    Label("Add Player", systemImage: "plus")
                }
                .buttonStyle(NeonButtonStyle())
            }

            ForEach(store.players) { player in
                PlayerRow(player: player)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct PlayerRow: View {
    @EnvironmentObject private var store: GameStore
    let player: Player
    @State private var name: String

    init(player: Player) {
        self.player = player
        _name = State(initialValue: player.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Name", text: $name, prompt: Text("Player Name"))
                    .onSubmit { store.updatePlayer(player, name: name) }
                Toggle("Hints", isOn: Binding(get: { player.hintsEnabled }, set: { store.updatePlayer(player, hintsEnabled: $0) }))
                    .labelsHidden()
                Button(role: .destructive) { store.removePlayer(player) } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
            .foregroundColor(.white)

            HStack {
                StatChip(label: "Last", value: "\(player.lastScore)")
                StatChip(label: "Total", value: "\(player.totalScore)")
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct StatChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
