import Foundation
import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    // Published state
    @Published private(set) var options: GameOptions
    @Published private(set) var players: [Player]
    @Published private(set) var tiles: [Tile]
    @Published private(set) var phase: GamePhase
    @Published private(set) var round: Int
    @Published private(set) var currentPlayerIndex: Int
    @Published private(set) var pendingRoll: DiceRoll
    @Published private(set) var turnLogs: [TurnLog]
    @Published private(set) var winners: [WinnerSummary]
    @Published private(set) var previousWinner: WinnerSummary?
    @Published private(set) var showSettings: Bool = false
    @Published private(set) var showHistory: Bool = false
    @Published private(set) var showHints: Bool = false
    @Published private(set) var showLearning: Bool = false
    @Published private(set) var showInstructions: Bool = false
    @Published private(set) var showWinners: Bool = false

    // Derived computed values
    var activePlayer: Player? { players[safe: currentPlayerIndex] }
    var shutTilesCount: Int { tiles.filter { $0.isShut }.count }
    var selectedTiles: [Tile] { tiles.filter { $0.isSelected && !$0.isShut } }
    var remainingTilesSum: Int { tiles.filter { !$0.isShut }.reduce(0) { $0 + $1.value } }

    private let storage = StorageProvider()

    init() {
        if let snapshot: GameSettingsSnapshot = storage.restore(key: .snapshot) {
            self.options = snapshot.options
            self.players = snapshot.players
            self.tiles = snapshot.tiles
            self.phase = snapshot.phase
            self.round = snapshot.round
            self.currentPlayerIndex = snapshot.players.firstIndex { $0.id == snapshot.currentPlayerId } ?? 0
            self.pendingRoll = snapshot.pendingRoll
            self.turnLogs = snapshot.turnLogs
            self.winners = snapshot.winners
            self.previousWinner = snapshot.previousWinner
        } else {
            self.options = .default
            self.players = [Player(name: "Player 1"), Player(name: "Player 2")]
            self.tiles = GameLogic.initialTiles(range: .default)
            self.phase = .setup
            self.round = 1
            self.currentPlayerIndex = 0
            self.pendingRoll = DiceRoll()
            self.turnLogs = []
            self.winners = []
            self.previousWinner = nil
        }
        Task { await persistSnapshot() }
    }

    // MARK: - Intents

    func toggleSettings() { showSettings.toggle() }
    func toggleHistory() { showHistory.toggle() }
    func toggleHints() { showHints.toggle() }
    func toggleLearning() { showLearning.toggle() }
    func toggleInstructions() { showInstructions.toggle() }
    func toggleWinners() { showWinners.toggle() }

    func updateOptions(_ update: (inout GameOptions) -> Void) {
        update(&options)
        Task { await persistSnapshot() }
    }

    func addPlayer() {
        players.append(Player(name: "Player \(players.count + 1)"))
        Task { await persistSnapshot() }
    }

    func removePlayer(_ player: Player) {
        guard players.count > 1 else { return }
        players.removeAll { $0.id == player.id }
        if currentPlayerIndex >= players.count { currentPlayerIndex = 0 }
        Task { await persistSnapshot() }
    }

    func updatePlayer(_ player: Player, name: String? = nil, hintsEnabled: Bool? = nil) {
        guard let idx = players.firstIndex(where: { $0.id == player.id }) else { return }
        if let name { players[idx].name = name }
        if let hintsEnabled { players[idx].hintsEnabled = hintsEnabled }
        Task { await persistSnapshot() }
    }

    func startGame() {
        tiles = GameLogic.initialTiles(range: options.tileRange)
        pendingRoll = DiceRoll()
        phase = .playing
        round = max(round, 1)
        currentPlayerIndex = 0
        turnLogs.removeAll()
        showInstructions = false
        Task { await persistSnapshot() }
    }

    func resetGame() {
        tiles = GameLogic.initialTiles(range: options.tileRange)
        phase = .setup
        round = 1
        currentPlayerIndex = 0
        pendingRoll = DiceRoll()
        turnLogs.removeAll()
        winners.removeAll()
        previousWinner = nil
        for idx in players.indices {
            players[idx].lastScore = 0
            players[idx].totalScore = 0
        }
        Task { await persistSnapshot() }
    }

    func rollDice(force value: DiceRoll? = nil) {
        let nextRoll = value ?? GameLogic.generateRoll(using: options, tiles: tiles)
        pendingRoll = nextRoll
        let rollMessage = "Rolled \(nextRoll.values.map(String.init).joined(separator: ", "))"
        turnLogs.append(TurnLog(playerId: activePlayer?.id ?? UUID(), message: rollMessage))

        if GameLogic.availableCombinations(for: nextRoll, tiles: tiles).isEmpty {
            turnLogs.append(TurnLog(playerId: activePlayer?.id ?? UUID(), message: "No available moves"))
            evaluateEndOfTurn(using: nextRoll)
        } else {
            Task { await persistSnapshot() }
        }
    }

    func toggleTile(_ tile: Tile) {
        guard phase == .playing else { return }
        guard pendingRoll.total > 0 else { return }
        guard GameLogic.isTileSelectable(tile, in: tiles, pendingRoll: pendingRoll) else { return }
        if let idx = tiles.firstIndex(where: { $0.id == tile.id }) {
            tiles[idx].isSelected.toggle()
        }
    }

    func confirmSelection() {
        let selected = selectedTiles
        guard !selected.isEmpty else { return }
        guard GameLogic.validateSelection(selected, roll: pendingRoll) else { return }
        for tile in selected {
            if let idx = tiles.firstIndex(where: { $0.id == tile.id }) {
                tiles[idx].isShut = true
                tiles[idx].isSelected = false
            }
        }
        let completedRoll = pendingRoll
        pendingRoll = DiceRoll()
        evaluateEndOfTurn(using: completedRoll)
    }

    func cancelSelection() {
        for idx in tiles.indices {
            tiles[idx].isSelected = false
        }
    }

    func endTurn() {
        cancelSelection()
        let completedRoll = pendingRoll
        pendingRoll = DiceRoll()
        evaluateEndOfTurn(using: completedRoll)
        if phase == .playing {
            advanceToNextPlayer()
        }
    }

    func exportScores() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(players) else { return nil }
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("ShutTheBoxScores.json")
        try? data.write(to: url)
        return url
    }

    // MARK: - Private helpers

    private func evaluateEndOfTurn(using roll: DiceRoll) {
        if GameLogic.isBoxShut(tiles: tiles) {
            handleRoundWin(score: 0)
            Task { await persistSnapshot() }
            return
        }

        if GameLogic.availableCombinations(for: roll, tiles: tiles).isEmpty {
            let score = GameLogic.remainingScore(tiles: tiles)
            handleRoundWin(score: score)
            Task { await persistSnapshot() }
            return
        }

        Task { await persistSnapshot() }
    }

    private func handleRoundWin(score: Int) {
        guard let player = activePlayer else { return }
        var updatedPlayer = player
        updatedPlayer.lastScore = score
        updatedPlayer.totalScore += score
        if let idx = players.firstIndex(where: { $0.id == player.id }) {
            players[idx] = updatedPlayer
        }
        let winner = WinnerSummary(playerName: player.name, score: score, tilesShut: shutTilesCount)
        winners.insert(winner, at: 0)
        previousWinner = winner
        phase = .roundComplete
        showWinners = true
        round += 1
        turnLogs.append(TurnLog(playerId: player.id, message: "Round won with score \(score)"))
        pendingRoll = DiceRoll()
    }

    private func advanceToNextPlayer() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        if currentPlayerIndex == 0 {
            round += 1
        }
    }

    private func persistSnapshot() async {
        let snapshot = GameSettingsSnapshot(
            options: options,
            players: players,
            tiles: tiles,
            phase: phase,
            currentPlayerId: activePlayer?.id,
            pendingRoll: pendingRoll,
            turnLogs: turnLogs,
            winners: winners,
            round: round,
            previousWinner: previousWinner,
            theme: ThemeManager.persistedTheme()
        )
        storage.persist(snapshot, key: .snapshot)
    }

}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension ClosedRange where Bound == Int {
    static let `default`: ClosedRange<Int> = 1...12
}
