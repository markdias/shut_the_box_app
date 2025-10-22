import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    var body: some View {
        VStack(spacing: 24) {
            if store.players.count > 1 {
                TurnStatusView(isCompact: isCompact)
            }
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
    private let glowPadding: CGFloat = 8

    var body: some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .inset(by: -glowPadding)
                    .stroke(glowColor, lineWidth: isActive ? 3 : 0)
                    .shadow(color: glowColor.opacity(isActive ? 0.6 : 0), radius: isActive ? 18 : 0)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.2), value: isActive)
            }
    }
}

private struct TurnStatusView: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    private var activePlayerName: String {
        let trimmed = store.activePlayer?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Player" : trimmed
    }

    private var possessiveName: String {
        if activePlayerName.lowercased().hasSuffix("s") {
            return "\(activePlayerName)'"
        }
        return "\(activePlayerName)'s"
    }

    private var statusMessage: String {
        switch store.phase {
        case .setup:
            return "\(activePlayerName) is up first."
        case .playing:
            if store.pendingRoll.total > 0 {
                return "Select tiles totalling \(store.pendingRoll.total)."
            }
            return "\(activePlayerName) can roll the dice."
        case .roundComplete:
            if store.showWinners {
                return "Review the results before starting the next round."
            }
            return "\(activePlayerName) will start round \(store.round)."
        }
    }

    private var startButtonTitle: String {
        switch store.phase {
        case .roundComplete:
            return "Start Next Round"
        case .setup, .playing:
            return "Start \(possessiveName) Go"
        }
    }

    private var buttonAccessibilityLabel: Text {
        switch store.phase {
        case .roundComplete:
            if store.showWinners {
                return Text("Close the results summary before starting the next round")
            }
            return Text("Start the next round for \(activePlayerName)")
        case .setup, .playing:
            if store.canRollDice {
                return Text("Start \(activePlayerName)'s turn")
            }
            if store.pendingRoll.total > 0 {
                return Text("Select tiles totalling \(store.pendingRoll.total) before rolling again")
            }
            return Text("Wait to continue \(activePlayerName)'s turn")
        }
    }

    private var shouldShowStartButton: Bool {
        store.phase != .playing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(activePlayerName)'s Turn")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if shouldShowStartButton {
                Button(action: { store.rollDice() }) {
                    Label(startButtonTitle, systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NeonButtonStyle())
                .disabled(!store.canRollDice)
                .opacity(store.canRollDice ? 1 : 0.6)
                .accessibilityLabel(buttonAccessibilityLabel)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 24 : 28, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 24 : 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: store.canRollDice)
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
                if let celebration = soloCelebrationSummary {
                    WinCelebrationView(
                        headline: soloCelebrationHeadline,
                        message: soloCelebrationMessage(for: celebration),
                        winners: [celebration],
                        accent: Color.mint
                    )
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else if showBoxNotShutBanner {
                    DidNotShutBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Button(action: { store.rollDice() }) {
                    Group {
                        if store.phase == .roundComplete {
                            CompletedRoundDiceView(
                                roll: finalRoundRoll,
                                score: finalRoundScore,
                                size: isCompact ? 96 : 120
                            )
                        } else {
                            HStack(spacing: 16) {
                                DiceView(value: store.pendingRoll.first, size: dieSize)
                                if showSecondDie {
                                    DiceView(value: store.pendingRoll.second, size: dieSize)
                                }
                            }
                        }
                    }
                    .padding(.top, overlayClearance)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canRoll)
                .opacity(canRoll ? 1 : 0.6)
                .accessibilityLabel(rollAccessibilityLabel)
                .accessibilityAddTraits(.isButton)
            }
            .animation(.easeInOut(duration: 0.25), value: showBoxNotShutBanner)

            if store.canAdjustDieMode {
                DiceModeToggle(isCompact: isCompact)
                    .transition(.opacity)
            }

            if store.phase == .roundComplete {
                if let rollSummary = finalRoundRollSummary {
                    Text("Last roll: \(rollSummary)")
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .transition(.opacity)
                }

                if let score = finalRoundScore {
                    Text("Round score: \(score)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .transition(.opacity)
                }
            }

            if let helperText = nextActionMessage {
                Text(helperText)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))
            }

        }
    }

    private var canRoll: Bool { store.canRollDice }

    private var dieSize: CGFloat { isCompact ? 96 : 120 }

    private var showSecondDie: Bool {
        store.activeDieMode == .double || store.pendingRoll.second != nil
    }

    private var finalRoundRoll: DiceRoll? {
        guard store.phase == .roundComplete else { return nil }
        return store.completedRoundRoll
    }

    private var finalRoundScore: Int? {
        guard store.phase == .roundComplete else { return nil }
        return store.completedRoundScore
    }

    private var finalRoundRollSummary: String? {
        finalRoundRoll?.equationDescription
    }

    private var finalRoundRollSpeech: String? {
        finalRoundRoll?.spokenDescription
    }

    private var trayTitle: String {
        switch store.phase {
        case .setup:
            return "Roll the Dice to Begin"
        case .playing:
            return "Roll the Dice"
        case .roundComplete:
            return canRoll ? "Start the Next Round" : "Round Complete"
        }
    }

    private var nextActionMessage: String? {
        switch store.phase {
        case .setup:
            return "Tap the dice to roll and start the game."
        case .playing:
            return canRoll
                ? "Tap the dice to roll again."
                : "Select tiles totalling \(store.pendingRoll.total) to continue."
        case .roundComplete:
            if canRoll {
                return "Tap the dice to begin the next round."
            }
            if store.showWinners {
                return "Review the results, then close the summary to continue."
            }
            return nil
        }
    }

    private var rollAccessibilityLabel: Text {
        switch store.phase {
        case .setup:
            return Text("Tap to start the game by rolling the dice")
        case .playing:
            if canRoll {
                let modeDescription = store.activeDieMode == .single ? "one die" : "two dice"
                return Text("Tap to roll \(modeDescription) again")
            }
            return Text("Resolve the current selection before rolling again")
        case .roundComplete:
            if canRoll {
                return finalRoundAccessibilityLabel(action: "Tap to start the next round")
            }
            if store.showWinners {
                return finalRoundAccessibilityLabel(action: "Close the results summary before starting the next round")
            }
            return finalRoundAccessibilityLabel(action: "Wait for the next round to begin")
        }
    }

    private var soloCelebrationSummary: WinnerSummary? {
        guard store.players.count == 1 else { return nil }
        guard store.phase == .roundComplete else { return nil }
        guard (store.completedRoundScore ?? Int.max) == 0 else { return nil }
        if let summary = store.previousWinner {
            return summary
        }
        if let player = store.players.first {
            return WinnerSummary(playerName: player.name, score: 0, tilesShut: store.options.maxTile)
        }
        return nil
    }

    private var soloCelebrationHeadline: String { "Box Shut!" }

    private func soloCelebrationMessage(for summary: WinnerSummary) -> String {
        let trimmedName = summary.playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmedName.isEmpty ? "Player" : trimmedName
        if summary.tilesShut >= store.options.maxTile {
            return "\(displayName) closed every tile for a flawless finish!"
        }
        return "\(displayName) shut the box with \(summary.tilesShut) tiles!"
    }

    private var overlayClearance: CGFloat {
        if soloCelebrationSummary != nil {
            return isCompact ? 96 : 112
        }
        return bannerClearance
    }

    private var showBoxNotShutBanner: Bool {
        guard store.players.count == 1 else { return false }
        guard store.phase == .roundComplete else { return false }
        guard soloCelebrationSummary == nil else { return false }
        return (store.players.first?.lastScore ?? 0) > 0
    }

    private var bannerClearance: CGFloat { isCompact ? 44 : 52 }

    private func finalRoundAccessibilityLabel(action: String) -> Text {
        var components: [String] = []

        if let rollSpeech = finalRoundRollSpeech,
           let roll = finalRoundRoll,
           !roll.values.isEmpty {
            var description = "Last roll showing \(rollSpeech)"
            description += " for a total of \(roll.total)"
            components.append(description)
        }

        if let score = finalRoundScore {
            components.append("Round score \(score)")
        }

        components.append(action)

        return Text(components.joined(separator: ". ") + ".")
    }
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

private struct DiceModeToggle: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    private var selection: Binding<DiceMode> {
        Binding(
            get: { store.dieMode },
            set: { store.setDieMode($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dice mode")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))

            Picker("Dice mode", selection: selection) {
                ForEach(DiceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: .infinity)
            .tint(Color.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Choose how many dice to roll")
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

private struct CompletedRoundDiceView: View {
    let roll: DiceRoll?
    let score: Int?
    let size: CGFloat

    private var faceValues: [Int?] {
        guard let roll = roll else { return [nil, nil] }
        let values = roll.values
        if values.count >= 2 {
            return Array(values.prefix(2)).map { Optional($0) }
        }
        if let first = values.first {
            return [first, nil]
        }
        return [nil, nil]
    }

    var body: some View {
        let faces = faceValues
        HStack(spacing: 16) {
            ForEach(Array(faces.enumerated()), id: \.offset) { entry in
                CompletedRoundDieFace(value: entry.element, size: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: Text {
        var components: [String] = []

        if let roll = roll,
           !roll.values.isEmpty,
           let spoken = roll.spokenDescription {
            var description = "Last roll showing \(spoken)"
            description += " for a total of \(roll.total)"
            components.append(description)
        }

        if let score = score {
            components.append("Round score \(score)")
        }

        if components.isEmpty {
            components.append("Review the last roll")
        }

        return Text(components.joined(separator: ". ") + ".")
    }
}

private struct CompletedRoundDieFace: View {
    let value: Int?
    let size: CGFloat

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
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 14)
        .opacity((value == nil) ? 0.45 : 1)
        .accessibilityHidden(true)
    }
}

private struct DicePipView: View {
    let value: Int

    private static let pipColor = Color(red: 0.93, green: 0.99, blue: 0.90)

    private static let pipPositions: [Int: [CGPoint]] = [
        1: [CGPoint(x: 0.5, y: 0.5)],
        2: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.75)],
        3: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.75)],
        4: [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25), CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.75, y: 0.75)],
        5: [
            CGPoint(x: 0.25, y: 0.25),
            CGPoint(x: 0.75, y: 0.25),
            CGPoint(x: 0.5, y: 0.5),
            CGPoint(x: 0.25, y: 0.75),
            CGPoint(x: 0.75, y: 0.75)
        ],
        6: [
            CGPoint(x: 0.25, y: 0.25),
            CGPoint(x: 0.75, y: 0.25),
            CGPoint(x: 0.25, y: 0.5),
            CGPoint(x: 0.75, y: 0.5),
            CGPoint(x: 0.25, y: 0.75),
            CGPoint(x: 0.75, y: 0.75)
        ]
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            if let positions = Self.pipPositions[value] {
                let pipSize = size * 0.2
                ZStack {
                    ForEach(Array(positions.enumerated()), id: \.offset) { entry in
                        let position = entry.element
                        Circle()
                            .fill(Self.pipColor)
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
}

private extension DiceRoll {
    var spokenDescription: String? {
        switch values.count {
        case 2:
            return "\(values[0]) and \(values[1])"
        case 1:
            if let first = values.first { return "\(first)" }
            return nil
        default:
            return nil
        }
    }

    var equationDescription: String? {
        let faces = values
        guard !faces.isEmpty else { return nil }
        let joined = faces.map(String.init).joined(separator: " + ")
        if faces.count > 1 {
            return "\(joined) = \(faces.reduce(0, +))"
        }
        return joined
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
