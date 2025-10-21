import Foundation

enum GameLogic {
    static func initialTiles(range: ClosedRange<Int>) -> [Tile] {
        range.map { Tile(id: $0, value: $0, isShut: false, isSelected: false) }
    }

    static func generateRoll(
        using options: GameOptions,
        tiles: [Tile],
        preferredRiggedRoll: DiceRoll? = nil,
        dieMode: DiceMode
    ) -> DiceRoll {
        if let preferredRiggedRoll {
            return preferredRiggedRoll
        }

        let remaining = tiles.filter { !$0.isShut }
        let allowSingleDie = shouldUseOneDie(rule: options.oneDieRule, tiles: remaining)
        let resolvedMode: DiceMode = allowSingleDie ? dieMode : .double

        if options.cheatCodes.contains(.full),
           let rigged = riggedRollForPerfectMove(tiles: remaining, prefersSingleDie: resolvedMode == .single) {
            return rigged
        }

        switch resolvedMode {
        case .single:
            return DiceRoll(first: Int.random(in: 1...6), second: nil)
        case .double:
            return DiceRoll(first: Int.random(in: 1...6), second: Int.random(in: 1...6))
        }
    }

    static func shouldUseOneDie(rule: OneDieRule, tiles: [Tile]) -> Bool {
        let openTiles = tiles.filter { !$0.isShut }
        let highest = openTiles.map { $0.value }.max() ?? 0
        let remainder = openTiles.reduce(0) { $0 + $1.value }

        switch rule {
        case .afterTopTilesShut:
            return highest <= 6
        case .whenRemainderLessThanSix:
            return remainder < 6
        case .never:
            return false
        }
    }

    static func isTileSelectable(_ tile: Tile, in tiles: [Tile], pendingRoll: DiceRoll) -> Bool {
        guard !tile.isShut else { return false }
        if tile.isSelected { return true }
        guard pendingRoll.total > 0 else { return false }

        let openTiles = tiles.filter { !$0.isShut }
        let currentSelection = openTiles.filter { $0.isSelected }
        let updatedSelection = currentSelection + [tile]
        let updatedTotal = updatedSelection.reduce(0) { $0 + $1.value }

        guard updatedTotal <= pendingRoll.total else { return false }

        let selectionIds = Set(updatedSelection.map { $0.id })
        let combos = CombinationGenerator.combinations(for: pendingRoll.total, tiles: openTiles)
        return combos.contains { combo in
            let comboIds = Set(combo.map { $0.id })
            return selectionIds.isSubset(of: comboIds)
        }
    }

    static func validateSelection(_ tiles: [Tile], roll: DiceRoll) -> Bool {
        guard roll.total > 0 else { return false }
        let sum = tiles.reduce(0) { $0 + $1.value }
        return sum == roll.total
    }

    static func availableCombinations(for roll: DiceRoll, tiles: [Tile]) -> [[Tile]] {
        guard roll.total > 0 else { return [] }
        let openTiles = tiles.filter { !$0.isShut }
        return CombinationGenerator.combinations(for: roll.total, tiles: openTiles)
    }

    static func isBoxShut(tiles: [Tile]) -> Bool {
        tiles.allSatisfy { $0.isShut }
    }

    static func remainingScore(tiles: [Tile]) -> Int {
        tiles.filter { !$0.isShut }.reduce(0) { $0 + $1.value }
    }

    static func bestMove(for roll: DiceRoll, tiles: [Tile]) -> [Tile] {
        guard roll.total > 0 else { return [] }
        let candidates = availableCombinations(for: roll, tiles: tiles)
        guard !candidates.isEmpty else { return [] }

        let openSet = Set(tiles.filter { !$0.isShut }.map { $0.id })

        return candidates.max { lhs, rhs in
            score(for: lhs, amongOpenTileIds: openSet, tiles: tiles, roll: roll) <
            score(for: rhs, amongOpenTileIds: openSet, tiles: tiles, roll: roll)
        } ?? []
    }

    static func legalTileIds(for roll: DiceRoll, tiles: [Tile]) -> Set<Int> {
        guard roll.total > 0 else { return [] }
        let combos = availableCombinations(for: roll, tiles: tiles)
        return Set(combos.flatMap { $0.map { $0.id } })
    }

    static func riggedRollForPerfectMove(tiles: [Tile], prefersSingleDie: Bool) -> DiceRoll? {
        guard !tiles.isEmpty else { return nil }
        let openTiles = tiles.filter { !$0.isShut }

        let totals = (1...12).reversed()
        for total in totals {
            let combos = CombinationGenerator.combinations(for: total, tiles: openTiles)
            guard !combos.isEmpty else { continue }
            if prefersSingleDie, total <= 6, let roll = DiceRoll.make(total: total) {
                return roll
            }
            if let bestCombo = combos.max(by: { lhs, rhs in lhs.count < rhs.count }) {
                if let roll = DiceRoll.make(total: bestCombo.reduce(0) { $0 + $1.value }) {
                    return roll
                }
            }
        }
        return nil
    }

    private static func score(for combination: [Tile], amongOpenTileIds openIds: Set<Int>, tiles: [Tile], roll: DiceRoll) -> Int {
        let comboSum = combination.reduce(0) { $0 + $1.value }
        let remaining = tiles.filter { openIds.contains($0.id) && !combination.contains($0) }
        let remainderSum = remaining.reduce(0) { $0 + $1.value }
        let diversity = Set(combination.map { $0.value }).count

        // Higher is better.
        return comboSum * 100 - remainderSum * 10 + diversity
    }
}

private extension DiceRoll {
    static func make(total: Int) -> DiceRoll? {
        guard total > 0 else { return nil }
        if total <= 6 {
            return DiceRoll(first: max(total, 1), second: nil)
        }

        for first in stride(from: min(6, total - 1), through: 1, by: -1) {
            let second = total - first
            if second <= 6 { return DiceRoll(first: first, second: second) }
        }
        return nil
    }
}
