import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    var body: some View {
        VStack(spacing: 24) {
            DiceTrayView(isCompact: isCompact)
            TileGridView(isCompact: isCompact)
            if store.options.requireConfirmation {
                SelectionActionBar(isCompact: isCompact)
            }
            ProgressCardsView(isCompact: isCompact)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

struct DiceTrayView: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text(store.phase == .setup ? "Start Game" : "Current Roll")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            HStack(spacing: 16) {
                DiceView(value: store.pendingRoll.first, size: isCompact ? 72 : 88)
                DiceView(value: store.pendingRoll.second, size: isCompact ? 72 : 88)
            }

            Group {
                if isCompact {
                    VStack(spacing: 12) {
                        actionButtons
                    }
                } else {
                    HStack(spacing: 12) {
                        actionButtons
                    }
                }
            }

            if store.pendingRoll.total > 0 {
                Text(store.options.oneDieRule.helpText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button(action: store.startGame) {
            Label("Start Game", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(NeonButtonStyle())

        Button(action: { store.rollDice() }) {
            Label(store.pendingRoll.total == 0 ? "Roll to Begin" : "Roll Again", systemImage: "die.face.5")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(NeonButtonStyle())

        Button(action: store.endTurn) {
            Label("End Turn", systemImage: "flag.checkered")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

struct DiceView: View {
    let value: Int?
    let size: CGFloat

    init(value: Int?, size: CGFloat = 88) {
        self.value = value
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.12))
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            if let value, (1...6).contains(value) {
                DicePipView(value: value)
                    .frame(width: size * 0.68, height: size * 0.68)
            } else {
                Text("?")
                    .font(.system(size: size * 0.48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: Text {
        if let value, (1...6).contains(value) {
            return Text("Die showing \(value)")
        } else {
            return Text("Die awaiting roll")
        }
    }
}

private struct DicePipView: View {
    let value: Int

    private static let pipPositions: [Int: [CGPoint]] = [
        1: [CGPoint(x: 0.5, y: 0.5)],
        2: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.75)],
        3: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.75)],
        4: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25), CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.75, y: 0.75)],
        5: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.75, y: 0.75)],
        6: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25), CGPoint(x: 0.25, y: 0.5), CGPoint(x: 0.75, y: 0.5), CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.75, y: 0.75)]
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let pipSize = size * 0.18
            let positions = Self.pipPositions[value, default: []]
            ZStack {
                ForEach(Array(positions.enumerated()), id: \.offset) { entry in
                    let position = entry.element
                    Circle()
                        .fill(Color.white)
                        .frame(width: pipSize, height: pipSize)
                        .position(
                            x: proxy.size.width * position.x,
                            y: proxy.size.height * position.y
                        )
                }
            }
        }
    }
}

struct TileGridView: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: isCompact ? 3 : 6)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(store.tiles) { tile in
                TileView(
                    tile: tile,
                    isHinted: store.hintsActive && store.hintedTileIds.contains(tile.id),
                    isBestMove: store.hintsActive && store.bestMove.contains(where: { $0.id == tile.id })
                )
                .onTapGesture { store.toggleTile(tile) }
                .onLongPressGesture { store.toggleTile(tile) }
                .simultaneousGesture(TapGesture(count: 2).onEnded {
                    if tile.value == 12 { store.forceDoubleSixCheat() }
                })
            }
        }
    }
}

struct TileView: View {
    let tile: Tile
    let isHinted: Bool
    let isBestMove: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(tileBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(outlineColor, lineWidth: tile.isSelected ? 4 : 1)
                )
                .frame(height: 64)

            Text("\(tile.value)")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
        }
        .shadow(color: glowColor, radius: tile.isSelected ? 18 : 8, x: 0, y: tile.isSelected ? 12 : 4)
    }

    private var tileBackground: LinearGradient {
        if tile.isShut {
            return LinearGradient(colors: [Color.green.opacity(0.4), Color.green.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if tile.isSelected {
            return LinearGradient(colors: [Color.blue.opacity(0.5), Color.cyan.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if isBestMove {
            return LinearGradient(colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var outlineColor: Color {
        if tile.isSelected {
            return .white.opacity(0.85)
        } else if isHinted {
            return Color.cyan.opacity(0.7)
        } else {
            return Color.white.opacity(0.2)
        }
    }

    private var glowColor: Color {
        if tile.isSelected {
            return Color.blue.opacity(0.6)
        } else if isHinted {
            return Color.cyan.opacity(0.5)
        } else {
            return Color.black.opacity(0.2)
        }
    }
}

struct SelectionActionBar: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    private var hasSelection: Bool { !store.selectedTiles.isEmpty }
    private var canConfirm: Bool { GameLogic.validateSelection(store.selectedTiles, roll: store.pendingRoll) }

    var body: some View {
        Group {
            if isCompact {
                VStack(spacing: 12) { buttons }
            } else {
                HStack(spacing: 12) { buttons }
            }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        Button(action: store.confirmSelection) {
            Label("Confirm", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(NeonButtonStyle())
        .disabled(!canConfirm)

        Button(action: store.cancelSelection) {
            Label("Clear", systemImage: "xmark.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(!hasSelection)
    }
}

struct ProgressCardsView: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    private var cards: [(title: String, value: String)] {
        [
            ("Tiles Shut", "\(store.shutTilesCount)/\(store.tiles.count)"),
            ("Selected Total", "\(store.selectedTiles.reduce(0) { $0 + $1.value })"),
            ("Roll Combos", "\(GameLogic.availableCombinations(for: store.pendingRoll, tiles: store.tiles).count)"),
            ("Progress", String(format: "%.0f%%", store.progressPercent))
        ]
    }

    var body: some View {
        Group {
            if isCompact {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(cards, id: \.title) { card in
                            ProgressCard(title: card.title, value: card.value, width: 160)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            } else {
                HStack(spacing: 16) {
                    ForEach(cards, id: \.title) { card in
                        ProgressCard(title: card.title, value: card.value)
                    }
                }
            }
        }
    }
}

struct ProgressCard: View {
    let title: String
    let value: String
    var width: CGFloat? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding()
        .frame(width: width, alignment: .leading)
        .frame(maxWidth: width == nil ? .infinity : width, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct NeonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: Color.purple.opacity(0.4), radius: 16, x: 0, y: 8)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}
