import Foundation

enum CombinationGenerator {
    static func combinations(for target: Int, tiles: [Tile]) -> [[Tile]] {
        let values = tiles.sorted { $0.value < $1.value }
        var result: [[Tile]] = []
        var current: [Tile] = []
        search(start: 0, target: target, tiles: values, current: &current, result: &result)
        return result
    }

    private static func search(start: Int, target: Int, tiles: [Tile], current: inout [Tile], result: inout [[Tile]]) {
        if target == 0 {
            result.append(current)
            return
        }
        guard target > 0 else { return }
        var index = start
        while index < tiles.count {
            let tile = tiles[index]
            current.append(tile)
            search(start: index + 1, target: target - tile.value, tiles: tiles, current: &current, result: &result)
            current.removeLast()
            index += 1
        }
    }
}
