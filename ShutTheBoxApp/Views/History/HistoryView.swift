import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Turn History")
                .font(.headline)
                .foregroundColor(.white)
            ForEach(store.turnLogs) { log in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: log.event.systemImage)
                                .foregroundColor(log.event.tint)
                            Text(log.message)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        Text(log.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            List(store.turnLogs) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: log.event.systemImage)
                            .foregroundColor(log.event.tint)
                        Text(log.message)
                    }
                    Text(log.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
            }
        }
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
