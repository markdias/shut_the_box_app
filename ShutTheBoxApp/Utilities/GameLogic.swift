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

    static func winningProbability(for tiles: [Tile], options: GameOptions) -> Double {
        var calculator = ProbabilityCalculator(options: options)
        return calculator.evaluate(using: tiles)
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

private struct ProbabilityCalculator {
    struct RollOutcome {
        let total: Int
        let probability: Double
    }

    private static let singleDieOutcomes: [RollOutcome] = (1...6).map { value in
        RollOutcome(total: value, probability: 1.0 / 6.0)
    }

    private static let doubleDieOutcomes: [RollOutcome] = [
        (2, 1), (3, 2), (4, 3), (5, 4), (6, 5), (7, 6), (8, 5), (9, 4), (10, 3), (11, 2), (12, 1)
    ].map { total, count in
        RollOutcome(total: total, probability: Double(count) / 36.0)
    }

    private struct CombinationKey: Hashable {
        let mask: UInt64
        let total: Int
    }

    let options: GameOptions
    private var probabilityCache: [UInt64: Double] = [:]
    private var combinationCache: [CombinationKey: [UInt64]] = [:]

    mutating func evaluate(using tiles: [Tile]) -> Double {
        let mask = openMask(from: tiles)
        return probability(forMask: mask)
    }

    private mutating func probability(forMask mask: UInt64) -> Double {
        if mask == 0 { return 1 }
        if let cached = probabilityCache[mask] { return cached }

        var best: Double = 0
        if allowSingleDie(mask: mask) {
            best = max(best, probability(for: .single, mask: mask))
        }
        best = max(best, probability(for: .double, mask: mask))

        probabilityCache[mask] = best
        return best
    }

    private mutating func probability(for mode: DiceMode, mask: UInt64) -> Double {
        let outcomes = mode == .single ? Self.singleDieOutcomes : Self.doubleDieOutcomes
        let values = openValues(for: mask)
        guard !values.isEmpty else { return 1 }

        var totalProbability: Double = 0

        for outcome in outcomes {
            let combinations = combinationMasks(for: outcome.total, mask: mask, values: values)
            guard !combinations.isEmpty else { continue }

            var bestForRoll: Double = 0
            for combo in combinations {
                let remainingMask = mask & ~combo
                let probability = probability(forMask: remainingMask)
                bestForRoll = max(bestForRoll, probability)
            }

            totalProbability += outcome.probability * bestForRoll
        }

        return totalProbability
    }

    private func openMask(from tiles: [Tile]) -> UInt64 {
        tiles.reduce(into: UInt64(0)) { partial, tile in
            guard !tile.isShut else { return }
            guard tile.value > 0 else { return }
            let bit = UInt64(1) << UInt64(tile.value - 1)
            partial |= bit
        }
    }

    private func openValues(for mask: UInt64) -> [Int] {
        guard mask != 0 else { return [] }
        var values: [Int] = []
        var bitIndex = 0
        var workingMask = mask
        while workingMask != 0 {
            if workingMask & 1 == 1 {
                values.append(bitIndex + 1)
            }
            workingMask >>= 1
            bitIndex += 1
        }
        return values
    }

    private func allowSingleDie(mask: UInt64) -> Bool {
        let values = openValues(for: mask)
        let highest = values.max() ?? 0
        let remainder = values.reduce(0, +)

        switch options.oneDieRule {
        case .afterTopTilesShut:
            return highest <= 6 && highest > 0
        case .whenRemainderLessThanSix:
            return remainder < 6 && remainder > 0
        case .never:
            return false
        }
    }

    private mutating func combinationMasks(for total: Int, mask: UInt64, values: [Int]) -> [UInt64] {
        guard total > 0 else { return [] }
        let key = CombinationKey(mask: mask, total: total)
        if let cached = combinationCache[key] { return cached }

        var results: [UInt64] = []
        let sortedValues = values.sorted()

        func search(index: Int, remaining: Int, currentMask: UInt64) {
            if remaining == 0 {
                results.append(currentMask)
                return
            }
            guard remaining > 0 else { return }
            guard index < sortedValues.count else { return }

            for nextIndex in index..<sortedValues.count {
                let value = sortedValues[nextIndex]
                if value > remaining { break }
                let bit = UInt64(1) << UInt64(value - 1)
                guard mask & bit != 0 else { continue }
                search(index: nextIndex + 1, remaining: remaining - value, currentMask: currentMask | bit)
            }
        }

        search(index: 0, remaining: total, currentMask: 0)
        combinationCache[key] = results
        return results
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
