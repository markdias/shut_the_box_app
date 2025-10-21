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
    @Published private(set) var bestMove: [Tile] = []
    @Published private(set) var completedRoundScore: Int?
    @Published var cheatInput: String = ""
    @Published private(set) var autoPlayEnabled: Bool = false

    // Derived computed values
    var activePlayer: Player? { players[safe: currentPlayerIndex] }
    var shutTilesCount: Int { tiles.filter { $0.isShut }.count }
    var selectedTiles: [Tile] { tiles.filter { $0.isSelected && !$0.isShut } }
    var remainingTilesSum: Int { tiles.filter { !$0.isShut }.reduce(0) { $0 + $1.value } }
    var legalCombinations: [[Tile]] { GameLogic.availableCombinations(for: pendingRoll, tiles: tiles) }
    var hintsActive: Bool {
        guard showHints else { return false }
        return activePlayer?.hintsEnabled ?? true
    }
    var hintedTileIds: Set<Int> { GameLogic.legalTileIds(for: pendingRoll, tiles: tiles) }
    var progressPercent: Double {
        guard options.maxTile > 0 else { return 0 }
        return (Double(shutTilesCount) / Double(options.maxTile)) * 100
    }

    private let storage = StorageProvider()
    private var riggedRoll: DiceRoll?
    private var currentRoundScores: [UUID: RoundScore]
    private var hasMigratedHintPreferences: Bool = false

    private enum TurnResolution {
        case bust
        case manual
        case shut
        case instant
    }

    init() {
        let restoredSnapshot: GameSettingsSnapshot? = storage.restore(key: .snapshot)
        self.hasMigratedHintPreferences = storage.restoreBool(key: .hintsMigration) ?? false

        if let snapshot = restoredSnapshot {
            self.options = snapshot.options
            self.players = snapshot.players
            self.tiles = snapshot.tiles.isEmpty ? GameLogic.initialTiles(range: snapshot.options.tileRange) : snapshot.tiles
            self.phase = snapshot.phase
            self.round = max(snapshot.round, 1)
            self.currentPlayerIndex = snapshot.players.firstIndex { $0.id == snapshot.currentPlayerId } ?? 0
            self.pendingRoll = snapshot.pendingRoll
            self.turnLogs = snapshot.turnLogs
            self.winners = snapshot.winners
            self.previousWinner = snapshot.previousWinner
            self.currentRoundScores = snapshot.currentRoundScores
            self.completedRoundScore = snapshot.completedRoundScore
        } else {
            self.options = .default
            self.players = [Player(name: "Player 1"), Player(name: "Player 2")]
            self.tiles = GameLogic.initialTiles(range: GameOptions.default.tileRange)
            self.phase = .setup
            self.round = 1
            self.currentPlayerIndex = 0
            self.pendingRoll = DiceRoll()
            self.turnLogs = []
            self.winners = []
            self.previousWinner = nil
            self.currentRoundScores = [:]
            self.completedRoundScore = nil
        }

        migrateHintPreferencesIfNeeded(restoredSnapshot: restoredSnapshot)
        normalizeOptions()
        refreshBestMove()
        Task { await persistSnapshot() }
    }

    // MARK: - Intents

    func toggleSettings() { showSettings.toggle() }
    func toggleHistory() { showHistory.toggle() }

    func toggleHints() {
        showHints.toggle()
        if showHints {
            ensureHintsEnabledForLegacyPlayers()
        }
        Task { await persistSnapshot() }
    }

    func toggleLearning() {
        guard options.showLearningGames else {
            showLearning = false
            return
        }
        showLearning.toggle()
        Task { await persistSnapshot() }
    }

    func toggleInstructions() { showInstructions.toggle() }
    func toggleWinners() { showWinners.toggle() }

    func toggleAutoPlay() {
        autoPlayEnabled.toggle()
        if autoPlayEnabled {
            showHints = true
        }
        Task { await persistSnapshot() }
    }

    func updateOptions(_ update: (inout GameOptions) -> Void) {
        update(&options)
        normalizeOptions()
        if phase != .playing {
            tiles = GameLogic.initialTiles(range: options.tileRange)
            pendingRoll = DiceRoll()
        }
        if !options.showLearningGames {
            showLearning = false
        }
        refreshBestMove()
        Task { await persistSnapshot() }
    }

    func submitCheatCode() {
        let trimmed = cheatInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        cheatInput = ""
        guard let code = CheatCode(rawValue: trimmed) else {
            recordLog(message: "Unknown code \(trimmed)", event: .info)
            return
        }
        applyCheat(code)
    }

    func addPlayer() {
        players.append(Player(name: "Player \(players.count + 1)"))
        Task { await persistSnapshot() }
    }

    func removePlayer(_ player: Player) {
        guard players.count > 1 else { return }
        players.removeAll { $0.id == player.id }
        if currentPlayerIndex >= players.count { currentPlayerIndex = 0 }
        currentRoundScores[player.id] = nil
        Task { await persistSnapshot() }
    }

    func updatePlayer(_ player: Player, name: String? = nil, hintsEnabled: Bool? = nil) {
        guard let idx = players.firstIndex(where: { $0.id == player.id }) else { return }
        if let name { players[idx].name = name }
        if let hintsEnabled { players[idx].hintsEnabled = hintsEnabled }
        Task { await persistSnapshot() }
    }

    func startGame() {
        phase = .playing
        round = max(round, 1)
        currentPlayerIndex = 0
        currentRoundScores.removeAll()
        tiles = GameLogic.initialTiles(range: options.tileRange)
        pendingRoll = DiceRoll()
        bestMove = []
        completedRoundScore = nil
        turnLogs.removeAll()
        showInstructions = false
        showWinners = false
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
        riggedRoll = nil
        bestMove = []
        currentRoundScores.removeAll()
        autoPlayEnabled = false
        showLearning = false
        completedRoundScore = nil
        for idx in players.indices {
            players[idx].lastScore = 0
            players[idx].totalScore = 0
            players[idx].unfinishedTurns = 0
        }
        Task { await persistSnapshot() }
    }

    func rollDice(force value: DiceRoll? = nil) {
        if phase != .playing {
            startGame()
        }
        let nextRoll = value ?? GameLogic.generateRoll(using: options, tiles: tiles, preferredRiggedRoll: riggedRoll)
        riggedRoll = nil
        pendingRoll = nextRoll
        refreshBestMove()
        recordLog(message: "Rolled \(nextRoll.valuesDescription)", event: .roll)

        let combos = legalCombinations
        if combos.isEmpty {
            recordLog(message: "No available moves", event: .bust)
            completeTurn(score: GameLogic.remainingScore(tiles: tiles), tilesClosed: shutTilesCount, didShut: false, resolution: .bust)
        } else if autoPlayEnabled {
            Task { @MainActor in await performAutoPlayMove(using: combos) }
        } else {
            Task { await persistSnapshot() }
        }
    }

    func toggleTile(_ tile: Tile) {
        guard phase == .playing else { return }
        guard pendingRoll.total > 0 else { return }
        guard GameLogic.isTileSelectable(tile, in: tiles, pendingRoll: pendingRoll) else { return }
        guard let idx = tiles.firstIndex(where: { $0.id == tile.id }) else { return }

        tiles[idx].isSelected.toggle()
        if GameLogic.validateSelection(selectedTiles, roll: pendingRoll) {
            confirmSelection()
        }
    }

    func confirmSelection() {
        guard phase == .playing else { return }
        let selection = selectedTiles
        guard !selection.isEmpty else { return }
        guard GameLogic.validateSelection(selection, roll: pendingRoll) else { return }

        let closedValues = selection.map { $0.value }.sorted()
        for tile in selection {
            if let idx = tiles.firstIndex(where: { $0.id == tile.id }) {
                tiles[idx].isShut = true
                tiles[idx].isSelected = false
            }
        }

        recordLog(message: "Closed tiles \(closedValues.map(String.init).joined(separator: ", "))", event: .move)
        pendingRoll = DiceRoll()
        refreshBestMove()

        if GameLogic.isBoxShut(tiles: tiles) {
            completeTurn(score: 0, tilesClosed: options.maxTile, didShut: true, resolution: .shut)
        } else {
            Task { await persistSnapshot() }
            if autoPlayEnabled {
                rollDice()
            }
        }
    }

    func cancelSelection() {
        for idx in tiles.indices {
            tiles[idx].isSelected = false
        }
    }

    func endTurn() {
        guard phase == .playing else { return }
        cancelSelection()
        let score = GameLogic.remainingScore(tiles: tiles)
        let closed = shutTilesCount
        let didShut = GameLogic.isBoxShut(tiles: tiles)
        recordLog(message: "Turn ended with score \(score)", event: .info)
        completeTurn(score: score, tilesClosed: closed, didShut: didShut, resolution: didShut ? .shut : .manual)
    }

    func forceDoubleSixCheat() {
        riggedRoll = DiceRoll(first: 6, second: 6)
        recordLog(message: "Secret double-six armed", event: .cheat)
    }

    func exportScores() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let export = ScoreExport(round: round,
                                 phase: phase,
                                 theme: ThemeManager.persistedTheme(),
                                 players: players,
                                 currentRoundScores: currentRoundScores)
        guard let data = try? encoder.encode(export) else { return nil }
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("shut-the-box-scores.json")
        try? data.write(to: url)
        return url
    }

    // MARK: - Private helpers

    private func performAutoPlayMove(using combinations: [[Tile]]) async {
        try? await Task.sleep(nanoseconds: 350_000_000)
        if pendingRoll.total == 0 { return }
        let move = bestMove.isEmpty ? combinations.first ?? [] : bestMove
        for tile in move {
            if let idx = tiles.firstIndex(where: { $0.id == tile.id }) {
                tiles[idx].isSelected = true
            }
        }
        confirmSelection()
    }

    private func completeTurn(score: Int, tilesClosed: Int, didShut: Bool, resolution: TurnResolution) {
        guard let player = activePlayer else { return }
        let lastTurnTiles = tiles

        var updatedPlayer = player
        updatedPlayer.lastScore = score
        updatedPlayer.totalScore += score
        if score > 0 { updatedPlayer.unfinishedTurns += 1 }

        if let idx = players.firstIndex(where: { $0.id == player.id }) {
            players[idx] = updatedPlayer
        }

        currentRoundScores[player.id] = RoundScore(score: score, tilesShut: tilesClosed)
        bestMove = []

        switch resolution {
        case .bust:
            recordLog(message: "Bust for \(player.name). Remaining: \(score)", event: .bust)
        case .manual:
            recordLog(message: "Stored \(score) for \(player.name)", event: .info)
        case .shut:
            recordLog(message: "Shut the box!", event: .win)
        case .instant:
            recordLog(message: "Instant victory", event: .win)
        }

        if options.instantWinOnShut && didShut {
            finalizeInstantWin(for: updatedPlayer, tilesClosed: tilesClosed, lastTurnTiles: lastTurnTiles, score: score)
            return
        }

        advanceToNextPlayerOrFinalize(lastTurnTiles: lastTurnTiles, score: score)
        Task { await persistSnapshot() }
    }

    private func finalizeInstantWin(for player: Player, tilesClosed: Int, lastTurnTiles: [Tile], score: Int) {
        let summary = WinnerSummary(playerName: player.name, score: 0, tilesShut: tilesClosed)
        winners = [summary]
        previousWinner = summary
        let shouldShowPopup = players.count > 1
        showWinners = shouldShowPopup
        phase = .roundComplete
        round += 1
        currentRoundScores.removeAll()
        currentPlayerIndex = 0
        tiles = lastTurnTiles
        pendingRoll = DiceRoll()
        completedRoundScore = score
        scheduleAutoRetryIfNeeded(showingPopup: shouldShowPopup, didShut: true)
        Task { await persistSnapshot() }
    }

    private func advanceToNextPlayerOrFinalize(lastTurnTiles: [Tile], score: Int) {
        if currentRoundScores.count >= players.count {
            finalizeRound(lastTurnTiles: lastTurnTiles, score: score)
            return
        }

        tiles = GameLogic.initialTiles(range: options.tileRange)
        pendingRoll = DiceRoll()
        completedRoundScore = nil
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }

    private func finalizeRound(lastTurnTiles: [Tile], score: Int) {
        phase = .roundComplete
        round += 1
        currentPlayerIndex = 0
        tiles = lastTurnTiles
        completedRoundScore = score

        let summaries = roundSummaries()
        winners = summaries
        previousWinner = summaries.first
        let shouldShowPopup = players.count > 1
        showWinners = shouldShowPopup
        let singlePlayerShutBox = players.count == 1 && (summaries.first?.score ?? 0) == 0
        scheduleAutoRetryIfNeeded(showingPopup: shouldShowPopup, didShut: singlePlayerShutBox)
        currentRoundScores.removeAll()
        pendingRoll = DiceRoll()
        Task { await persistSnapshot() }
    }

    private func scheduleAutoRetryIfNeeded(showingPopup: Bool, didShut: Bool) {
        guard !showingPopup else { return }
        guard options.autoRetry || autoPlayEnabled else { return }
        guard players.count == 1 else { return }
        guard didShut else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            startGame()
        }
    }

    private func roundSummaries() -> [WinnerSummary] {
        guard !currentRoundScores.isEmpty else { return [] }

        switch options.scoringMode {
        case .lowestRemainder, .instantWin:
            let best = currentRoundScores.values.map { $0.score }.min() ?? 0
            let winners = players.filter { currentRoundScores[$0.id]?.score == best }
            return winners.map { player in
                let data = currentRoundScores[player.id] ?? RoundScore(score: 0, tilesShut: 0)
                return WinnerSummary(playerName: player.name, score: data.score, tilesShut: data.tilesShut)
            }
        case .targetRace:
            let contenders = players.filter { $0.totalScore >= options.targetGoal }
            if contenders.isEmpty {
                let best = currentRoundScores.values.map { $0.score }.min() ?? 0
                return players.filter { currentRoundScores[$0.id]?.score == best }.map { player in
                    let data = currentRoundScores[player.id] ?? RoundScore(score: 0, tilesShut: 0)
                    return WinnerSummary(playerName: player.name, score: data.score, tilesShut: data.tilesShut)
                }
            }
            let minimum = contenders.map { $0.totalScore }.min() ?? options.targetGoal
            return contenders.filter { $0.totalScore == minimum }.map { player in
                let data = currentRoundScores[player.id] ?? RoundScore(score: 0, tilesShut: 0)
                return WinnerSummary(playerName: player.name, score: data.score, tilesShut: data.tilesShut)
            }
        }
    }

    private func refreshBestMove() {
        bestMove = GameLogic.bestMove(for: pendingRoll, tiles: tiles)
    }

    private func normalizeOptions() {
        if options.scoringMode == .instantWin {
            options.instantWinOnShut = true
        }
        if !options.cheatCodes.contains(.madness) {
            options.maxTile = min(options.maxTile, 12)
        }
        if options.requireConfirmation {
            options.requireConfirmation = false
        }
    }

    private func applyCheat(_ code: CheatCode) {
        switch code {
        case .madness:
            updateOptions { options in
                options.maxTile = 56
                options.cheatCodes.insert(.madness)
            }
            tiles = GameLogic.initialTiles(range: options.tileRange)
        case .full:
            updateOptions { options in
                options.cheatCodes.insert(.full)
            }
            recordLog(message: "Perfect-roll rigging engaged", event: .cheat)
        case .takeover:
            updateOptions { options in
                options.cheatCodes.insert(.takeover)
                options.autoRetry = true
            }
            autoPlayEnabled = true
            showHints = true
            startGame()
            recordLog(message: "Auto-play takeover active", event: .cheat)
        }
    }

    private func recordLog(message: String, event: TurnEvent, playerId: UUID? = nil) {
        let id = playerId ?? activePlayer?.id ?? UUID()
        turnLogs.append(TurnLog(playerId: id, message: message, event: event))
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
            theme: ThemeManager.persistedTheme(),
            currentRoundScores: currentRoundScores,
            completedRoundScore: completedRoundScore
        )
        storage.persist(snapshot, key: .snapshot)
    }

    private func migrateHintPreferencesIfNeeded(restoredSnapshot: GameSettingsSnapshot?) {
        guard !hasMigratedHintPreferences else { return }
        defer {
            hasMigratedHintPreferences = true
            storage.persist(true, key: .hintsMigration)
        }
        guard restoredSnapshot != nil else { return }
        guard !players.isEmpty else { return }
        guard !players.contains(where: { $0.hintsEnabled }) else { return }
        for idx in players.indices {
            players[idx].hintsEnabled = true
        }
    }

    private func ensureHintsEnabledForLegacyPlayers() {
        guard !hasMigratedHintPreferences else { return }
        guard !players.isEmpty else {
            hasMigratedHintPreferences = true
            storage.persist(true, key: .hintsMigration)
            return
        }
        if !players.contains(where: { $0.hintsEnabled }) {
            for idx in players.indices {
                players[idx].hintsEnabled = true
            }
        }
        hasMigratedHintPreferences = true
        storage.persist(true, key: .hintsMigration)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct ScoreExport: Codable {
    let round: Int
    let phase: GamePhase
    let theme: ThemeOption
    let players: [Player]
    let currentRoundScores: [UUID: RoundScore]
}

private extension DiceRoll {
    var valuesDescription: String {
        values.map(String.init).joined(separator: ", ")
    }
}
