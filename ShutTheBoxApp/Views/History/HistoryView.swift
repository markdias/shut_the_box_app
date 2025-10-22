import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: GameStore

    private var recentRoundEntries: [RoundHistoryEntry] {
        let previewCount = min(3, store.roundHistory.count)
        return Array(store.roundHistory.suffix(previewCount).reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !store.roundHighlights.isEmpty {
                HistorySectionHeader(title: "Round Insights")
                RoundHighlightsView(highlights: store.roundHighlights)
            }

            if !store.roundHistory.isEmpty {
                HistorySectionHeader(title: "Round Totals")
                RoundHistoryPreview(entries: recentRoundEntries)
                if store.roundHistory.count > recentRoundEntries.count {
                    Text("Open the history sheet to browse the full archive.")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            HistorySectionHeader(title: "Turn History")
            if store.turnLogs.isEmpty {
                Text("Roll the dice to start building the log.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            } else {
                ForEach(store.turnLogs) { log in
                    TurnLogRow(log: log)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct HistorySheetView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if !store.roundHighlights.isEmpty {
                        HistorySectionHeader(title: "Round Insights", color: .primary)
                        RoundHighlightsView(
                            highlights: store.roundHighlights,
                            textColor: .primary,
                            containerColor: Color.primary.opacity(0.08)
                        )
                    }

                    if !store.roundHistory.isEmpty {
                        HistorySectionHeader(title: "Round Totals", color: .primary)
                        VStack(spacing: 16) {
                            ForEach(store.roundHistory.reversed()) { entry in
                                RoundHistoryCard(
                                    entry: entry,
                                    textColor: .primary,
                                    containerColor: Color.primary.opacity(0.08)
                                )
                            }
                        }
                    }

                    HistorySectionHeader(title: "Turn History", color: .primary)
                    if store.turnLogs.isEmpty {
                        Text("Rolls, moves, busts, and wins will appear here as they happen.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.turnLogs) { log in
                                TurnLogRow(
                                    log: log,
                                    textColor: .primary,
                                    backgroundColor: Color.primary.opacity(0.08)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

private struct HistorySectionHeader: View {
    let title: String
    var color: Color = .white

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(color)
    }
}

private struct RoundHighlightsView: View {
    let highlights: [RoundStatHighlight]
    var textColor: Color = .white
    var containerColor: Color = Color.white.opacity(0.08)

    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(highlights) { highlight in
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: highlight.icon)
                        .font(.headline)
                        .foregroundColor(textColor)
                        .padding(10)
                        .background(containerColor)
                        .clipShape(Circle())

                    Text(highlight.title.uppercased())
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(0.6))
                    Text(highlight.value)
                        .font(.title3.weight(.bold))
                        .foregroundColor(textColor)
                    Text(highlight.detail)
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(containerColor)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

private struct RoundHistoryPreview: View {
    let entries: [RoundHistoryEntry]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(entries) { entry in
                RoundHistoryCard(entry: entry)
            }
        }
    }
}

private struct RoundHistoryCard: View {
    let entry: RoundHistoryEntry
    var textColor: Color = .white
    var containerColor: Color = Color.white.opacity(0.06)

    private var winnerText: String? {
        let names = entry.winnerNames
        guard !names.isEmpty else { return nil }
        let label = names.count == 1 ? "Winner" : "Winners"
        return "\(label): \(names.joined(separator: ", "))"
    }

    private var winnerIds: Set<UUID> { Set(entry.winningPlayerIds) }

    var body: some View {
        RoundHistoryContent(entry: entry, winnerIds: winnerIds, winnerText: winnerText, textColor: textColor)
            .padding()
            .background(containerColor)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct RoundHistoryContent: View {
    let entry: RoundHistoryEntry
    let winnerIds: Set<UUID>
    let winnerText: String?
    let textColor: Color

    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Round \(entry.roundNumber)")
                        .font(.headline)
                        .foregroundColor(textColor)
                    if let winnerText {
                        Text(winnerText)
                            .font(.subheadline)
                            .foregroundColor(textColor.opacity(0.75))
                    }
                }
                Spacer()
                Label {
                    Text("Total \(entry.totalScore)")
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: entry.didShut ? "crown.fill" : "sum")
                }
                .foregroundColor(textColor)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(entry.playerResults) { result in
                    PlayerScoreChip(result: result, isWinner: winnerIds.contains(result.id), textColor: textColor)
                }
            }
        }
    }
}

private struct PlayerScoreChip: View {
    let result: RoundPlayerResult
    let isWinner: Bool
    let textColor: Color

    private var backgroundColor: Color {
        if isWinner {
            return Color.green.opacity(0.22)
        }
        return textColor.opacity(0.08)
    }

    private var borderColor: Color {
        isWinner ? Color.green.opacity(0.5) : textColor.opacity(0.15)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(result.name)
                .font(.caption2.weight(.semibold))
                .foregroundColor(textColor.opacity(0.75))
                .lineLimit(1)
            Text(result.scoreDescription)
                .font(.callout.weight(.bold))
                .foregroundColor(textColor)
            if let tiles = result.tilesShut {
                Text("\(tiles) tiles")
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.6))
            }
            if isWinner && result.score == 0 {
                Text("Shut the box")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.green.opacity(0.85))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

private struct TurnLogRow: View {
    let log: TurnLog
    var textColor: Color = .white
    var backgroundColor: Color = Color.white.opacity(0.06)

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: log.event.systemImage)
                        .foregroundColor(log.event.tint)
                    Text(log.message)
                        .foregroundColor(textColor)
                }
                .font(.subheadline)

                Text(log.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.6))
            }
            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension TurnEvent {
    var systemImage: String {
        switch self {
        case .roll: return "die.face.6"
        case .move: return "square.grid.3x3.fill"
        case .bust: return "exclamationmark.triangle"
        case .win: return "crown.fill"
        case .info: return "info.circle"
        case .cheat: return "wand.and.rays"
        }
    }

    var tint: Color {
        switch self {
        case .roll: return .mint
        case .move: return .blue
        case .bust: return .orange
        case .win: return .yellow
        case .info: return .gray
        case .cheat: return .purple
        }
    }
}
