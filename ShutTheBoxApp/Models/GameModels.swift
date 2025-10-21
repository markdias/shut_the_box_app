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
            return "Switch to a single die once tiles 7–9 are closed."
        case .whenRemainderLessThanSix:
            return "Use a single die when the sum of open tiles is under six."
        case .never:
            return "Always roll two dice."
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
    var turnLogs: [TurnLog]
    var winners: [WinnerSummary]
    var round: Int
    var previousWinner: WinnerSummary?
    var theme: ThemeOption
    var currentRoundScores: [UUID: RoundScore] = [:]
    var completedRoundScore: Int?
    var completedRoundRoll: DiceRoll?
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
