import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    var body: some View {
        VStack(spacing: 24) {
            AttentionContainer(isActive: diceNeedsAttention, cornerRadius: isCompact ? 24 : 28) {
                DiceTrayView(isCompact: isCompact)
            }
            AttentionContainer(isActive: tilesNeedAttention, cornerRadius: isCompact ? 20 : 24) {
                TileGridView(isCompact: isCompact)
            }
            ProgressCardsView(isCompact: isCompact)
            EndTurnBar()
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

private extension GameBoardView {
    var diceNeedsAttention: Bool {
        switch store.phase {
        case .setup, .roundComplete:
            return true
        case .playing:
            return store.pendingRoll.total == 0 && store.selectedTiles.isEmpty
        }
    }

    var tilesNeedAttention: Bool {
        store.phase == .playing && store.pendingRoll.total > 0
    }
}

private struct AttentionContainer<Content: View>: View {
    let isActive: Bool
    let cornerRadius: CGFloat
    @ViewBuilder var content: Content

    private var glowColor: Color { Color.green.opacity(0.8) }

    var body: some View {
        content
            .overlay(alignment: .center) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor, lineWidth: isActive ? 3 : 0)
                    .shadow(color: glowColor.opacity(isActive ? 0.6 : 0), radius: isActive ? 18 : 0)
                    .padding(isActive ? -8 : 0)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.2), value: isActive)
            }
    }
}

struct DiceTrayView: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(trayTitle)
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            ZStack(alignment: .top) {
                if showBoxNotShutBanner {
                    DidNotShutBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Button(action: { store.rollDice() }) {
                    HStack(spacing: 16) {
                        DiceView(value: store.pendingRoll.first, size: isCompact ? 96 : 120)
                        DiceView(value: store.pendingRoll.second, size: isCompact ? 96 : 120)
                    }
                    .padding(.top, bannerClearance)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canRoll)
                .opacity(canRoll ? 1 : 0.6)
                .accessibilityLabel(rollAccessibilityLabel)
                .accessibilityAddTraits(.isButton)
            }
            .animation(.easeInOut(duration: 0.25), value: showBoxNotShutBanner)

            if store.phase == .setup || store.phase == .playing {
                Text(helperMessage)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))
            }

            if store.pendingRoll.total > 0 {
                Text(store.options.oneDieRule.helpText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private var canRoll: Bool {
        switch store.phase {
        case .setup:
            return true
        case .playing:
            return store.pendingRoll.total == 0 && store.selectedTiles.isEmpty
        case .roundComplete:
            return false
        }
    }

    private var trayTitle: String {
        switch store.phase {
        case .setup:
            return "Roll the Dice to Begin"
        case .playing:
            return "Roll the Dice"
        case .roundComplete:
            return "Round Complete"
        }
    }

    private var helperMessage: String {
        if canRoll {
            if store.phase == .setup {
                return "Tap the dice to roll and start the game."
            }
            return "Tap the dice to roll again."
        }
        return "Select tiles totalling \(store.pendingRoll.total) to continue."
    }

    private var rollAccessibilityLabel: Text {
        if canRoll {
            if store.phase == .setup {
                return Text("Tap to start the game by rolling the dice")
            } else {
                return Text("Tap to roll the dice again")
            }
        }
        return Text("Resolve the current selection before rolling again")
    }

    private var showBoxNotShutBanner: Bool {
        guard store.players.count == 1 else { return false }
        guard store.phase == .roundComplete else { return false }
        return (store.players.first?.lastScore ?? 0) > 0
    }

    private var bannerClearance: CGFloat { isCompact ? 44 : 52 }
}

private struct DidNotShutBanner: View {
    var body: some View {
        Label {
            Text("Did not shut the box")
                .textCase(.uppercase)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.36, blue: 0.42), Color(red: 0.88, green: 0.13, blue: 0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                )
        )
        .foregroundColor(.white)
        .shadow(color: Color.red.opacity(0.45), radius: 16, x: 0, y: 10)
        .padding(.horizontal, 4)
        .allowsHitTesting(false)
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
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1.5)
                )

            if let value, (1...6).contains(value) {
                DicePipView(value: value)
                    .frame(width: size * 0.7, height: size * 0.7)
            } else {
                Text("?")
                    .font(.system(size: size * 0.48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 14)
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
            let pipSize = size * 0.2
            let positions = Self.pipPositions[value, default: []]
            ZStack {
                ForEach(Array(positions.enumerated()), id: \.offset) { entry in
                    let position = entry.element
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.25), radius: pipSize * 0.4, x: 0, y: pipSize * 0.2)
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
            return LinearGradient(colors: [Color.green.opacity(0.65), Color.green.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if isBestMove {
            return LinearGradient(colors: [Color.cyan.opacity(0.45), Color.blue.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var outlineColor: Color {
        if tile.isSelected {
            return Color.green.opacity(0.9)
        } else if isHinted {
            return Color.cyan.opacity(0.7)
        } else {
            return Color.white.opacity(0.2)
        }
    }

    private var glowColor: Color {
        if tile.isSelected {
            return Color.green.opacity(0.55)
        } else if isHinted {
            return Color.cyan.opacity(0.5)
        } else {
            return Color.black.opacity(0.2)
        }
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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(cards, id: \.title) { card in
                        ProgressCard(title: card.title, value: card.value)
                    }
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct EndTurnBar: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        if store.phase == .playing {
            Button(action: store.endTurn) {
                Label("End Turn", systemImage: "flag.checkered")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.top, 8)
        }
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
