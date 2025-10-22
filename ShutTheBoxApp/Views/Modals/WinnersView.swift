import SwiftUI

struct WinnersView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    private var winnersHavePerfectScore: Bool {
        store.winners.contains { $0.score == 0 }
    }

    private var lowestWinningScore: Int {
        store.winners.map(\.score).min() ?? 0
    }

    private var celebrationHeadline: String {
        if winnersHavePerfectScore {
            return store.winners.count > 1 ? "Shared Shut!" : "Box Shut!"
        }
        return store.winners.count > 1 ? "Shared Victory" : "Round Winner"
    }

    private var celebrationMessage: String {
        guard !store.winners.isEmpty else {
            return "Keep rolling until someone closes every tile."
        }

        if winnersHavePerfectScore {
            if store.winners.count > 1 {
                let names = formattedWinnerNames()
                return "\(names) each cleared the board for a perfect 0!"
            }
            if let winner = store.winners.first {
                return "\(winner.playerName) closed every tile for a flawless finish!"
            }
        }

        if store.winners.count > 1 {
            let names = formattedWinnerNames()
            return "\(names) share the lowest remainder of \(lowestWinningScore)."
        }

        if let winner = store.winners.first {
            return "\(winner.playerName) wins with a remainder of \(winner.score)."
        }

        return "An unforgettable round!"
    }

    private var celebrationFooter: String {
        if winnersHavePerfectScore {
            return "A shut box triggers an instant celebration across the table."
        }
        if store.winners.count > 1 {
            return "Ties split the honours when scores match."
        }
        return "Lowest totals take the round when tiles remain."
    }

    private var celebrationAccent: Color {
        winnersHavePerfectScore ? Color.mint : Color.orange
    }

    private func formattedWinnerNames() -> String {
        let names = store.winners.map { $0.playerName.trimmingCharacters(in: .whitespacesAndNewlines) }
        return names.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var body: some View {
        NavigationStack {
            List {
                if store.winners.isEmpty {
                    Section {
                        NoWinnerPlaceholder()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        WinCelebrationView(
                            headline: celebrationHeadline,
                            message: celebrationMessage,
                            winners: store.winners,
                            accent: celebrationAccent
                        )
                        .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                        .listRowBackground(Color.clear)
                    } footer: {
                        Text(celebrationFooter)
                    }

                    Section("Winning Lineup") {
                        ForEach(store.winners) { winner in
                            WinnerRow(winner: winner, accent: celebrationAccent)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Round Winners")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

private struct WinnerRow: View {
    let winner: WinnerSummary
    let accent: Color

    private var scoreLabel: String {
        winner.score == 0 ? "Perfect shut" : "Score \(winner.score)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(winner.playerName)
                    .font(.headline)
                Spacer()
                Text(scoreLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(accent)
            }

            HStack(spacing: 6) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Tiles shut: \(winner.tilesShut)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(winner.date, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

private struct NoWinnerPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "die.face.1")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No winner this round")
                .font(.headline)
            Text("Keep rolling until someone shuts the box or claims the lowest score.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WinCelebrationView: View {
    let headline: String
    let message: String
    let winners: [WinnerSummary]
    var accent: Color

    @State private var animateGlow = false

    private var highlightNames: String {
        winners
            .map { $0.playerName.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private var lowestScore: Int? {
        winners.map(\.score).min()
    }

    private var highlightScoreLine: String? {
        guard let score = lowestScore else { return nil }
        if score == 0 {
            return "Perfect shut the box!"
        }
        return "Lowest score: \(score)"
    }

    private var accentGradient: [Color] {
        [
            accent.opacity(0.95),
            accent.opacity(0.75),
            Color.white.opacity(0.25)
        ]
    }

    private var accessibilityDescription: String {
        var components: [String] = [headline, message]
        if !highlightNames.isEmpty {
            components.append("Winners: \(highlightNames)")
        }
        if let scoreLine = highlightScoreLine {
            components.append(scoreLine)
        }
        return components.joined(separator: ". ")
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(accent.opacity(animateGlow ? 0.95 : 0.55), lineWidth: 3)
                        .shadow(color: accent.opacity(0.45), radius: 18)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animateGlow)
                )
                .shadow(color: accent.opacity(0.45), radius: 24, x: 0, y: 12)

            SparkleField(accent: accent, animate: animateGlow)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .allowsHitTesting(false)

            VStack(spacing: 14) {
                Label {
                    Text(headline)
                        .font(.title2.weight(.heavy))
                        .multilineTextAlignment(.center)
                } icon: {
                    Image(systemName: "trophy.fill")
                        .font(.title)
                }
                .foregroundColor(.white)

                Text(message)
                    .font(.callout.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.white.opacity(0.92))

                if !highlightNames.isEmpty {
                    Text(highlightNames)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.25))
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                }

                if let scoreLine = highlightScoreLine {
                    Text(scoreLine)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(Color.white.opacity(0.9))
                }
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .onAppear { animateGlow = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityDescription))
    }
}

private struct SparkleField: View {
    let accent: Color
    let animate: Bool

    private let positions: [CGPoint] = [
        CGPoint(x: 0.15, y: 0.2),
        CGPoint(x: 0.25, y: 0.75),
        CGPoint(x: 0.5, y: 0.1),
        CGPoint(x: 0.65, y: 0.6),
        CGPoint(x: 0.85, y: 0.25),
        CGPoint(x: 0.75, y: 0.85),
        CGPoint(x: 0.35, y: 0.55),
        CGPoint(x: 0.1, y: 0.65)
    ]

    var body: some View {
        GeometryReader { proxy in
            let baseSize = min(proxy.size.width, proxy.size.height)
            ForEach(Array(positions.enumerated()), id: \.offset) { index, point in
                let iconSize = baseSize * (0.08 + (Double(index).truncatingRemainder(dividingBy: 3) * 0.02))
                Image(systemName: "sparkles")
                    .font(.system(size: iconSize))
                    .foregroundColor(index.isMultiple(of: 2) ? accent.opacity(0.8) : Color.white.opacity(0.85))
                    .position(x: proxy.size.width * point.x, y: proxy.size.height * point.y)
                    .scaleEffect(animate ? 1.2 : 0.7)
                    .opacity(animate ? 0.85 : 0.4)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .animation(
                        .easeInOut(duration: 2.2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: animate
                    )
            }
        }
    }
}
