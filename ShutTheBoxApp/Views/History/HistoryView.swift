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
                        Text(log.message)
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
                    Text(log.message)
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
