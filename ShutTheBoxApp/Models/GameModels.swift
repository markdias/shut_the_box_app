import Foundation

enum GamePhase: String, Codable, CaseIterable {
    case setup
    case playing
    case roundComplete
}

enum OneDieRule: String, Codable, CaseIterable, Identifiable {
    case never
    case onlyWhenSevenOrLower
    case always

    var id: String { rawValue }
    var title: String {
        switch self {
        case .never: return "Never"
        case .onlyWhenSevenOrLower: return "≤ 7"
        case .always: return "Always"
        }
    }
}

enum ScoringMode: String, Codable, CaseIterable, Identifiable {
    case lowestTotal
    case highestShutCount
    case customTarget

    var id: String { rawValue }
    var title: String {
        switch self {
        case .lowestTotal: return "Lowest Total"
        case .highestShutCount: return "Most Tiles"
        case .customTarget: return "Target Score"
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
        case .neon: return "Neon"
        case .matrix: return "Matrix"
        case .classic: return "Classic"
        case .tabletop: return "Tabletop"
        }
    }

    var cssClass: String { "theme-\(rawValue)" }
}

struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var lastScore: Int
    var totalScore: Int
    var hintsEnabled: Bool

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.lastScore = 0
        self.totalScore = 0
        self.hintsEnabled = true
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

struct TurnLog: Identifiable, Codable {
    let id: UUID
    let playerId: UUID
    let message: String
    let timestamp: Date

    init(id: UUID = UUID(), playerId: UUID, message: String, timestamp: Date = Date()) {
        self.id = id
        self.playerId = playerId
        self.message = message
        self.timestamp = timestamp
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

struct GameOptions: Codable {
    var tileRange: ClosedRange<Int>
    var oneDieRule: OneDieRule
    var scoringMode: ScoringMode
    var targetScore: Int
    var requireConfirmation: Bool
    var showHeaderDetails: Bool
    var instantWin: Bool
    var enableLearningGames: Bool
    var autoRetry: Bool
    var cheatCodes: Set<String>

    static let `default` = GameOptions(
        tileRange: 1...12,
        oneDieRule: .onlyWhenSevenOrLower,
        scoringMode: .lowestTotal,
        targetScore: 50,
        requireConfirmation: true,
        showHeaderDetails: true,
        instantWin: true,
        enableLearningGames: false,
        autoRetry: false,
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
}
