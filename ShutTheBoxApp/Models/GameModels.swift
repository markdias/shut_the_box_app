import Foundation

enum GamePhase: String, Codable, CaseIterable {
    case setup
    case playing
    case roundComplete
}

enum OneDieRule: String, Codable, CaseIterable, Identifiable {
    case afterTopTilesShut
    case whenRemainderLessThanSix
    case never

    var id: String { rawValue }

    var title: String {
        switch self {
        case .afterTopTilesShut:
            return "After Top Tiles Shut"
        case .whenRemainderLessThanSix:
            return "When Remainder < 6"
        case .never:
            return "Never"
        }
    }

    var helpText: String {
        switch self {
        case .afterTopTilesShut:
            return "A single die becomes available once tiles 7–9 are closed. Use the toggle under the dice to keep rolling two."
        case .whenRemainderLessThanSix:
            return "A single die becomes available when the sum of open tiles is under six. Use the toggle under the dice to keep rolling two."
        case .never:
            return "Always roll two dice."
        }
    }
}

enum DiceMode: String, Codable, CaseIterable, Identifiable {
    case single
    case double

    var id: String { rawValue }

    var title: String {
        switch self {
        case .single:
            return "1 Die"
        case .double:
            return "2 Dice"
        }
    }
}

enum ScoringMode: String, Codable, CaseIterable, Identifiable {
    case lowestRemainder
    case targetRace
    case instantWin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lowestRemainder:
            return "Lowest Remainder"
        case .targetRace:
            return "Cumulative Target"
        case .instantWin:
            return "Instant Win"
        }
    }

    var subtitle: String {
        switch self {
        case .lowestRemainder:
            return "Score the fewest leftover pips."
        case .targetRace:
            return "First to reach the target total wins."
        case .instantWin:
            return "Any shut box ends the round immediately."
        }
    }
}

enum ThemeOption: String, Codable, CaseIterable, Identifiable {
    case neon
    case matrix
    case classic
    case tabletop

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .neon:
            return "Neon Glow"
        case .matrix:
            return "Matrix Grid"
        case .classic:
            return "Classic Wood"
        case .tabletop:
            return "Tabletop Felt"
        }
    }
}

struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var lastScore: Int
    var totalScore: Int
    var unfinishedTurns: Int
    var hintsEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        lastScore: Int = 0,
        totalScore: Int = 0,
        unfinishedTurns: Int = 0,
        hintsEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.lastScore = lastScore
        self.totalScore = totalScore
        self.unfinishedTurns = unfinishedTurns
        self.hintsEnabled = hintsEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case lastScore
        case totalScore
        case unfinishedTurns
        case hintsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        lastScore = try container.decodeIfPresent(Int.self, forKey: .lastScore) ?? 0
        totalScore = try container.decodeIfPresent(Int.self, forKey: .totalScore) ?? 0
        unfinishedTurns = try container.decodeIfPresent(Int.self, forKey: .unfinishedTurns) ?? 0
        hintsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hintsEnabled) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(lastScore, forKey: .lastScore)
        try container.encode(totalScore, forKey: .totalScore)
        try container.encode(unfinishedTurns, forKey: .unfinishedTurns)
        try container.encode(hintsEnabled, forKey: .hintsEnabled)
    }
}

struct Tile: Identifiable, Codable, Hashable {
    let id: Int
    var value: Int
    var isShut: Bool
    var isSelected: Bool
}

struct DiceRoll: Codable {
    var first: Int?
    var second: Int?

    var total: Int { (first ?? 0) + (second ?? 0) }
    var values: [Int] { [first, second].compactMap { $0 } }
}

enum TurnEvent: String, Codable {
    case roll
    case move
    case bust
    case win
    case info
    case cheat
}

struct TurnLog: Identifiable, Codable {
    let id: UUID
    let playerId: UUID
    let message: String
    let timestamp: Date
    let event: TurnEvent

    init(id: UUID = UUID(), playerId: UUID, message: String, event: TurnEvent, timestamp: Date = Date()) {
        self.id = id
        self.playerId = playerId
        self.message = message
        self.timestamp = timestamp
        self.event = event
    }
}

struct WinnerSummary: Identifiable, Codable {
    let id: UUID
    let playerName: String
    let score: Int
    let tilesShut: Int
    let date: Date

    init(id: UUID = UUID(), playerName: String, score: Int, tilesShut: Int, date: Date = Date()) {
        self.id = id
        self.playerName = playerName
        self.score = score
        self.tilesShut = tilesShut
        self.date = date
    }
}

struct RoundPlayerResult: Identifiable, Codable {
    let id: UUID
    let name: String
    let score: Int?
    let tilesShut: Int?

    init(id: UUID, name: String, score: Int?, tilesShut: Int?) {
        self.id = id
        self.name = name
        self.score = score
        self.tilesShut = tilesShut
    }

    var scoreDescription: String {
        guard let score else { return "—" }
        return String(score)
    }
}

struct RoundHistoryEntry: Identifiable, Codable {
    let id: UUID
    let roundNumber: Int
    let completedAt: Date
    let totalScore: Int
    let winningPlayerIds: [UUID]
    let playerResults: [RoundPlayerResult]

    init(
        id: UUID = UUID(),
        roundNumber: Int,
        completedAt: Date = Date(),
        totalScore: Int,
        winningPlayerIds: [UUID],
        playerResults: [RoundPlayerResult]
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.completedAt = completedAt
        self.totalScore = totalScore
        self.winningPlayerIds = winningPlayerIds
        self.playerResults = playerResults
    }

    var winnerNames: [String] {
        winningPlayerIds.compactMap { displayName(for: $0) }
    }

    var didShut: Bool {
        playerResults.contains { $0.score == 0 }
    }

    func displayName(for playerId: UUID) -> String? {
        playerResults.first(where: { $0.id == playerId })?.name
    }
}

struct RoundStatHighlight: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let icon: String
}

struct RoundHistoryStats {
    struct Momentum {
        let recentAverage: Double
        let overallAverage: Double

        var delta: Double { recentAverage - overallAverage }
    }

    let entries: [RoundHistoryEntry]

    var totalRounds: Int { entries.count }

    private var totalScoreSum: Int {
        entries.reduce(0) { $0 + $1.totalScore }
    }

    var averageTotal: Double? {
        guard totalRounds > 0 else { return nil }
        return Double(totalScoreSum) / Double(totalRounds)
    }

    var cleanShutCount: Int {
        entries.filter { $0.didShut }.count
    }

    var cleanShutRate: Double? {
        guard totalRounds > 0 else { return nil }
        return Double(cleanShutCount) / Double(totalRounds)
    }

    var bestRound: RoundHistoryEntry? {
        entries.min(by: { lhs, rhs in lhs.totalScore < rhs.totalScore })
    }

    var topWinner: (names: [String], wins: Int)? {
        guard !entries.isEmpty else { return nil }
        var counts: [UUID: Int] = [:]
        var nameLookup: [UUID: String] = [:]

        for entry in entries {
            for winnerId in entry.winningPlayerIds {
                counts[winnerId, default: 0] += 1
                if let name = entry.displayName(for: winnerId) {
                    nameLookup[winnerId] = name
                }
            }
        }

        guard let maxWins = counts.values.max(), maxWins > 0 else { return nil }
        let bestIds = counts.filter { $0.value == maxWins }.map { $0.key }
        let names = bestIds.compactMap { nameLookup[$0] }
        guard !names.isEmpty else { return nil }
        return (names.sorted(), maxWins)
    }

    var longestWinStreak: (name: String, length: Int)? {
        guard !entries.isEmpty else { return nil }
        var streakId: UUID?
        var streakLength = 0
        var bestId: UUID?
        var bestLength = 0
        var nameLookup: [UUID: String] = [:]

        let ordered = entries.sorted { $0.completedAt < $1.completedAt }
        for entry in ordered {
            if let winnerId = entry.winningPlayerIds.first, entry.winningPlayerIds.count == 1 {
                if streakId == winnerId {
                    streakLength += 1
                } else {
                    streakId = winnerId
                    streakLength = 1
                }
                if streakLength > bestLength {
                    bestLength = streakLength
                    bestId = winnerId
                }
                if let name = entry.displayName(for: winnerId) {
                    nameLookup[winnerId] = name
                }
            } else {
                streakId = nil
                streakLength = 0
            }
        }

        guard let resolvedId = bestId,
              let resolvedName = nameLookup[resolvedId],
              bestLength > 1 else { return nil }
        return (resolvedName, bestLength)
    }

    var momentum: Momentum? {
        guard totalRounds >= 3, let overall = averageTotal else { return nil }
        let recent = entries.suffix(3)
        let recentAverage = Double(recent.reduce(0) { $0 + $1.totalScore }) / Double(recent.count)
        return Momentum(recentAverage: recentAverage, overallAverage: overall)
    }

    var highlights: [RoundStatHighlight] {
        guard !entries.isEmpty else { return [] }

        var items: [RoundStatHighlight] = []
        items.append(
            RoundStatHighlight(
                title: "Rounds Logged",
                value: "\(totalRounds)",
                detail: "Captured totals since the last reset",
                icon: "clock.badge.checkmark"
            )
        )

        if let averageTotal {
            items.append(
                RoundStatHighlight(
                    title: "Average Total",
                    value: String(format: "%.1f", averageTotal),
                    detail: "Lower leftovers mean stronger play",
                    icon: "sum"
                )
            )
        }

        if let rate = cleanShutRate {
            let percentage = Int(round(rate * 100))
            items.append(
                RoundStatHighlight(
                    title: "Clean Shuts",
                    value: "\(cleanShutCount)",
                    detail: "\(percentage)% of rounds ended in a shut box",
                    icon: "sparkles"
                )
            )
        }

        if let leader = topWinner {
            let nameText = leader.names.joined(separator: ", ")
            items.append(
                RoundStatHighlight(
                    title: "Win Leader",
                    value: nameText,
                    detail: "\(leader.wins) round wins",
                    icon: "crown"
                )
            )
        }

        if let streak = longestWinStreak {
            items.append(
                RoundStatHighlight(
                    title: "Hot Streak",
                    value: streak.name,
                    detail: "\(streak.length) solo wins in a row",
                    icon: "flame"
                )
            )
        }

        if let momentum {
            let delta = momentum.delta
            let trend = delta < 0 ? "Improving" : "Cooling"
            let formattedDelta = String(format: "%@%.1f", delta >= 0 ? "+" : "", delta)
            items.append(
                RoundStatHighlight(
                    title: "Momentum",
                    value: trend,
                    detail: "Last 3 avg \(String(format: "%.1f", momentum.recentAverage)) (\(formattedDelta) vs overall)",
                    icon: delta < 0 ? "arrow.down.right" : "arrow.up.right"
                )
            )
        }

        if let bestRound {
            let winners = bestRound.winnerNames.joined(separator: ", ")
            items.append(
                RoundStatHighlight(
                    title: "Best Round",
                    value: "Round \(bestRound.roundNumber)",
                    detail: "Total \(bestRound.totalScore) – \(winners.isEmpty ? "No winner" : winners)",
                    icon: "target"
                )
            )
        }

        return items
    }
}

struct LearningGame: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
}

struct RoundScore: Codable {
    var score: Int
    var tilesShut: Int
}

enum CheatCode: String, Codable, CaseIterable, Identifiable {
    case full
    case madness
    case takeover

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .full:
            return "Full"
        case .madness:
            return "Madness"
        case .takeover:
            return "Takeover"
        }
    }

    var description: String {
        switch self {
        case .full:
            return "Rig rolls toward perfect clears."
        case .madness:
            return "Unlock the giant 56-tile board."
        case .takeover:
            return "Enable auto-play, auto-retry, and hints."
        }
    }
}

struct GameOptions: Codable {
    var maxTile: Int
    var oneDieRule: OneDieRule
    var scoringMode: ScoringMode
    var targetGoal: Int
    var instantWinOnShut: Bool
    var requireConfirmation: Bool
    var autoRetry: Bool
    var showHeaderDetails: Bool
    var showCodeTools: Bool
    var showLearningGames: Bool
    var cheatCodes: Set<CheatCode>

    static let `default` = GameOptions(
        maxTile: 12,
        oneDieRule: .afterTopTilesShut,
        scoringMode: .lowestRemainder,
        targetGoal: 100,
        instantWinOnShut: true,
        requireConfirmation: false,
        autoRetry: false,
        showHeaderDetails: true,
        showCodeTools: false,
        showLearningGames: false,
        cheatCodes: []
    )
}

struct GameSettingsSnapshot: Codable {
    var options: GameOptions
    var players: [Player]
    var tiles: [Tile]
    var phase: GamePhase
    var currentPlayerId: UUID?
    var pendingRoll: DiceRoll
    var dieMode: DiceMode = .double
    var turnLogs: [TurnLog]
    var winners: [WinnerSummary]
    var round: Int
    var previousWinner: WinnerSummary?
    var theme: ThemeOption
    var currentRoundScores: [UUID: RoundScore] = [:]
    var completedRoundScore: Int?
    var completedRoundRoll: DiceRoll?
    var roundHistory: [RoundHistoryEntry] = []

    private enum CodingKeys: String, CodingKey {
        case options
        case players
        case tiles
        case phase
        case currentPlayerId
        case pendingRoll
        case dieMode
        case turnLogs
        case winners
        case round
        case previousWinner
        case theme
        case currentRoundScores
        case completedRoundScore
        case completedRoundRoll
        case roundHistory
    }

    init(
        options: GameOptions,
        players: [Player],
        tiles: [Tile],
        phase: GamePhase,
        currentPlayerId: UUID?,
        pendingRoll: DiceRoll,
        dieMode: DiceMode = .double,
        turnLogs: [TurnLog],
        winners: [WinnerSummary],
        round: Int,
        previousWinner: WinnerSummary?,
        theme: ThemeOption,
        currentRoundScores: [UUID: RoundScore] = [:],
        completedRoundScore: Int?,
        completedRoundRoll: DiceRoll?,
        roundHistory: [RoundHistoryEntry] = []
    ) {
        self.options = options
        self.players = players
        self.tiles = tiles
        self.phase = phase
        self.currentPlayerId = currentPlayerId
        self.pendingRoll = pendingRoll
        self.dieMode = dieMode
        self.turnLogs = turnLogs
        self.winners = winners
        self.round = round
        self.previousWinner = previousWinner
        self.theme = theme
        self.currentRoundScores = currentRoundScores
        self.completedRoundScore = completedRoundScore
        self.completedRoundRoll = completedRoundRoll
        self.roundHistory = roundHistory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        options = try container.decode(GameOptions.self, forKey: .options)
        players = try container.decode([Player].self, forKey: .players)
        tiles = try container.decode([Tile].self, forKey: .tiles)
        phase = try container.decode(GamePhase.self, forKey: .phase)
        currentPlayerId = try container.decodeIfPresent(UUID.self, forKey: .currentPlayerId)
        pendingRoll = try container.decode(DiceRoll.self, forKey: .pendingRoll)
        dieMode = try container.decodeIfPresent(DiceMode.self, forKey: .dieMode) ?? .double
        turnLogs = try container.decode([TurnLog].self, forKey: .turnLogs)
        winners = try container.decodeIfPresent([WinnerSummary].self, forKey: .winners) ?? []
        round = try container.decodeIfPresent(Int.self, forKey: .round) ?? 1
        previousWinner = try container.decodeIfPresent(WinnerSummary.self, forKey: .previousWinner)
        theme = try container.decodeIfPresent(ThemeOption.self, forKey: .theme) ?? .neon
        currentRoundScores = try container.decodeIfPresent([UUID: RoundScore].self, forKey: .currentRoundScores) ?? [:]
        completedRoundScore = try container.decodeIfPresent(Int.self, forKey: .completedRoundScore)
        completedRoundRoll = try container.decodeIfPresent(DiceRoll.self, forKey: .completedRoundRoll)
        roundHistory = try container.decodeIfPresent([RoundHistoryEntry].self, forKey: .roundHistory) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(options, forKey: .options)
        try container.encode(players, forKey: .players)
        try container.encode(tiles, forKey: .tiles)
        try container.encode(phase, forKey: .phase)
        try container.encodeIfPresent(currentPlayerId, forKey: .currentPlayerId)
        try container.encode(pendingRoll, forKey: .pendingRoll)
        try container.encode(dieMode, forKey: .dieMode)
        try container.encode(turnLogs, forKey: .turnLogs)
        try container.encode(winners, forKey: .winners)
        try container.encode(round, forKey: .round)
        try container.encodeIfPresent(previousWinner, forKey: .previousWinner)
        try container.encode(theme, forKey: .theme)
        try container.encode(currentRoundScores, forKey: .currentRoundScores)
        try container.encodeIfPresent(completedRoundScore, forKey: .completedRoundScore)
        try container.encodeIfPresent(completedRoundRoll, forKey: .completedRoundRoll)
        try container.encode(roundHistory, forKey: .roundHistory)
    }
}

extension GameOptions {
    var tileRange: ClosedRange<Int> { 1...maxTile }

    var allowsMadness: Bool { maxTile > 12 }

    mutating func applyCheatCodes(_ codes: Set<CheatCode>) {
        cheatCodes = codes
        if codes.contains(.madness) {
            maxTile = max(maxTile, 56)
        } else {
            maxTile = min(maxTile, 12)
        }
    }
}
