import SwiftUI

struct PlayerSettingsSection: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        Section(header: Text("Players")) {
            if store.players.isEmpty {
                Text("Add at least one player to begin a game.")
                    .foregroundStyle(.secondary)
            }

            ForEach(store.players) { player in
                PlayerSettingsRow(player: player)
            }

            Button(action: store.addPlayer) {
                Label("Add Player", systemImage: "plus")
            }
        }
    }
}

private struct PlayerSettingsRow: View {
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
                TextField("Player Name", text: $name)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)

                Toggle("Hints", isOn: Binding(get: { player.hintsEnabled }, set: { store.updatePlayer(player, hintsEnabled: $0) }))
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            HStack {
                Label("Last: \(player.lastScore)", systemImage: "clock.arrow.circlepath")
                Spacer()
                Label("Total: \(player.totalScore)", systemImage: "sum")
                Spacer()
                Label("Unfinished: \(player.unfinishedTurns)", systemImage: "flag")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Button(role: .destructive) {
                store.removePlayer(player)
            } label: {
                Label("Remove Player", systemImage: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 6)
        .onChange(of: name) { newValue in
            guard newValue != player.name else { return }
            store.updatePlayer(player, name: newValue)
        }
        .onChange(of: player.name) { newValue in
            guard newValue != name else { return }
            name = newValue
        }
    }
}
