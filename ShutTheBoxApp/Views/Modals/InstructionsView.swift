import SwiftUI

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Play")
                        .font(.title.weight(.bold))

                    Group {
                        Text("Core Gameplay")
                            .font(.headline)
                        bullet("Setup options, add players, and keep previous scores thanks to automatic persistence.")
                        bullet("Roll automatically chooses two dice unless the one-die rule allows a single die.")
                        bullet("Tap open tiles whose sum matches the roll. Enable confirmation to avoid mis-taps.")
                        bullet("Rounds close once every player has no legal moves. Ties appear in the winner modal.")
                    }

                    Group {
                        Text("Rules & Scoring")
                            .font(.headline)
                        bullet("Adjust highest tile, one-die timing, and scoring mode inside Settings → Rules.")
                        bullet("Instant-win on shut ends the round immediately when the board is cleared.")
                        bullet("Target mode tracks cumulative totals until someone reaches the goal.")
                    }

                    Group {
                        Text("Assistive Tools")
                            .font(.headline)
                        bullet("Global hints highlight every legal tile combination; per-player hints tailor coaching.")
                        bullet("Best-move glow matches the auto-play path for hands-free demos.")
                        bullet("Cheat codes unlock perfect rolls, giant boards, and visible auto-play takeovers.")
                    }

                    Group {
                        Text("Learning Corner")
                            .font(.headline)
                        bullet("Switch to the Learning Games tab for phonics, shapes, dice flashcards, and math mixers.")
                        bullet("Progress and selected games persist so returning to the main board is a single tap.")
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
