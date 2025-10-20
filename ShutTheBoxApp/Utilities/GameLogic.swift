import Foundation

enum GameLogic {
    static func initialTiles(range: ClosedRange<Int>) -> [Tile] {
        range.map { Tile(id: $0, value: $0, isShut: false, isSelected: false) }
    }

    static func generateRoll(using options: GameOptions, tiles: [Tile]) -> DiceRoll {
        let remaining = tiles.filter { !$0.isShut }
        let highest = remaining.map { $0.value }.max() ?? 0
        let canUseOneDie = shouldUseOneDie(rule: options.oneDieRule, highestTile: highest)
        if canUseOneDie {
            return DiceRoll(first: Int.random(in: 1...6), second: nil)
        } else {
            return DiceRoll(first: Int.random(in: 1...6), second: Int.random(in: 1...6))
        }
    }

    static func shouldUseOneDie(rule: OneDieRule, highestTile: Int) -> Bool {
        switch rule {
        case .never: return false
        case .always: return true
        case .onlyWhenSevenOrLower: return highestTile <= 6
        }
    }

    static func isTileSelectable(_ tile: Tile, in tiles: [Tile], pendingRoll: DiceRoll) -> Bool {
        guard !tile.isShut else { return false }
        let currentSelection = tiles.filter { $0.isSelected && !$0.isShut }
        let newSelection = currentSelection + [tile]
        return validateSelection(newSelection, roll: pendingRoll)
    }

    static func validateSelection(_ tiles: [Tile], roll: DiceRoll) -> Bool {
        let sum = tiles.reduce(0) { $0 + $1.value }
        return sum == roll.total
    }

    static func availableCombinations(for roll: DiceRoll, tiles: [Tile]) -> [[Tile]] {
        let openTiles = tiles.filter { !$0.isShut }
        return CombinationGenerator.combinations(for: roll.total, tiles: openTiles)
    }

    static func isBoxShut(tiles: [Tile]) -> Bool {
        tiles.allSatisfy { $0.isShut }
    }

    static func remainingScore(tiles: [Tile]) -> Int {
        tiles.filter { !$0.isShut }.reduce(0) { $0 + $1.value }
    }
}
