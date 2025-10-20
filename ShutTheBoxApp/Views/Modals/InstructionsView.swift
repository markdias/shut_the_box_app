import SwiftUI

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Play")
                        .font(.title.weight(.bold))
                    Text("Roll the dice, shut tiles that add up to the total, and race to finish with the lowest score. Use hints for strategy inspiration and explore learning games for younger players.")
                    Text("Key Rules")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 8) {
                        bullet("Players take turns rolling two dice and shutting tiles that match the sum.")
                        bullet("When only low tiles remain, the one-die rule can change depending on settings.")
                        bullet("If no moves remain, add the uncovered tiles for the round score.")
                        bullet("Instant-win tiles and cheat codes mirror the web version for parity.")
                    }
                }
                .padding()
            }
            .navigationTitle("Instructions")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done", action: dismiss.callAsFunction) }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
}
