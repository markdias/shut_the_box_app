import SwiftUI
import UIKit

struct HeaderView: View {
    @EnvironmentObject private var store: GameStore
    let isCompact: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shut the Box")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    Text(phaseSummary)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                if isCompact {
                    Menu {
                        headerActions
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                } else {
                    HStack(spacing: 12) {
                        headerActions
                    }
                }
            }
            .padding(.horizontal)

            if !isCompact && store.options.showHeaderDetails {
                HStack(spacing: 12) {
                    StatusChip(title: "Active Player", value: store.activePlayer?.name ?? "-")
                    StatusChip(title: "Players", value: "\(store.players.count)")
                    StatusChip(title: "Tiles Shut", value: "\(store.shutTilesCount)")
                    StatusChip(title: "Hints", value: store.showHints ? "On" : "Off")
                    if let winner = store.previousWinner {
                        StatusChip(title: "Previous Winner", value: winner.playerName)
                    }
                }
                .padding(.horizontal)
            }

            if store.options.showCodeTools {
                CheatCodeToolbar()
                    .padding(.horizontal)
            }

            if store.autoPlayEnabled {
                AutoPlayBanner()
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(colors: [Color(red: 0.12, green: 0.1, blue: 0.28).opacity(0.9), Color(red: 0.1, green: 0.16, blue: 0.34).opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
    }

    @ViewBuilder
    private var headerActions: some View {
        HeaderButton(title: "Show Settings", icon: "gearshape.fill") { store.toggleSettings() }
        HeaderButton(title: "Show History", icon: "clock.fill") { store.toggleHistory() }
        HeaderButton(title: store.showHints ? "Hide Hints" : "Show Hints", icon: "lightbulb.fill") { store.toggleHints() }
        if store.options.showLearningGames {
            HeaderButton(title: "More Games", icon: "gamecontroller.fill") { store.toggleLearning() }
        }
        HeaderButton(title: "Save Scores", icon: "square.and.arrow.down.fill") { exportScores() }
        HeaderButton(title: "Reset", icon: "gobackward") { store.resetGame() }
        HeaderButton(title: "End Turn", icon: "flag.checkered") { store.endTurn() }
        HeaderButton(title: "How to Play", icon: "questionmark.circle") { store.toggleInstructions() }
    }

    private func exportScores() {
        guard let url = store.exportScores() else { return }
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.presentedWindowRoot?.present(activity, animated: true)
    }
}

private extension HeaderView {
    var phaseSummary: String {
        if store.players.count > 1 {
            return "Round \(store.round) · Phase: \(store.phaseDisplay) · \(activePlayerDisplayName)"
        }
        return "Round \(store.round) · Phase: \(store.phaseDisplay)"
    }

    var activePlayerDisplayName: String {
        let trimmed = store.activePlayer?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fallback = trimmed.isEmpty ? "Player" : trimmed
        return fallback
    }
}

private struct CheatCodeToolbar: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        HStack(spacing: 12) {
            TextField("Enter code", text: $store.cheatInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button("Apply") { store.submitCheatCode() }
                .buttonStyle(NeonButtonStyle())
        }
    }
}

private struct AutoPlayBanner: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        HStack {
            Label("Auto-play running", systemImage: "sparkles")
            Spacer()
            Button("Stop") { store.toggleAutoPlay() }
                .buttonStyle(SecondaryButtonStyle())
        }
        .font(.footnote.weight(.semibold))
        .foregroundColor(.white)
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension GameStore {
    var phaseDisplay: String {
        switch phase {
        case .setup: return "Setup"
        case .playing: return "Playing"
        case .roundComplete: return "Round Complete"
        }
    }
}

struct StatusChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct HeaderButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.footnote.weight(.semibold))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
    }
}

private extension UIApplication {
    var presentedWindowRoot: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}
