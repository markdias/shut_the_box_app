import SwiftUI

struct LearningGameBoardView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selectedGame: LearningGame = LearningGame.defaultGames.first!

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LearningGame.defaultGames) { game in
                        Button {
                            selectedGame = game
                        } label: {
                            VStack(alignment: .leading) {
                                Text(game.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(game.description)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                            .frame(width: 220, alignment: .leading)
                            .background(selectedGame == game ? Color.blue.opacity(0.4) : Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal)
            }

            LearningGameDetailView(game: selectedGame)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding()
    }
}

struct LearningGameDetailView: View {
    let game: LearningGame

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(game.title)
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            Text(game.description)
                .foregroundColor(.white.opacity(0.8))
            Divider().background(Color.white.opacity(0.2))
            switch game.id {
            case "shapes": ShapesLearningView()
            case "dice": DiceLearningView()
            case "dots": DotsLearningView()
            case "math": MathLearningView()
            case "words": WordLearningView()
            default: EmptyView()
            }
        }
    }
}

private struct ShapesLearningView: View {
    @State private var shapeCount: Int = Int.random(in: 1...6)
    var body: some View {
        VStack(spacing: 12) {
            Text("How many shapes do you see?")
            HStack(spacing: 12) {
                ForEach(0..<shapeCount, id: \.self) { _ in
                    Circle()
                        .fill(Color.pink.opacity(0.7))
                        .frame(width: 32, height: 32)
                }
            }
            Button("Shuffle") { shapeCount = Int.random(in: 1...6) }
                .buttonStyle(NeonButtonStyle())
        }
        .foregroundColor(.white)
    }
}

private struct DiceLearningView: View {
    @State private var value: Int = Int.random(in: 1...6)
    var body: some View {
        VStack(spacing: 12) {
            Text("Name this die face")
            DiceView(value: value)
            Button("Roll") { value = Int.random(in: 1...6) }
                .buttonStyle(NeonButtonStyle())
        }
        .foregroundColor(.white)
    }
}

private struct DotsLearningView: View {
    @State private var dots: Int = Int.random(in: 1...12)
    var body: some View {
        VStack(spacing: 12) {
            Text("Count the glowing dots")
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(28)), count: 4), spacing: 12) {
                ForEach(0..<dots, id: \.self) { _ in
                    Circle()
                        .fill(Color.cyan.opacity(0.8))
                        .frame(width: 24, height: 24)
                }
            }
            Button("Flash") { dots = Int.random(in: 1...12) }
                .buttonStyle(NeonButtonStyle())
        }
        .foregroundColor(.white)
    }
}

private struct MathLearningView: View {
    @State private var operands: (Int, Int) = (Int.random(in: 1...6), Int.random(in: 1...6))
    var body: some View {
        VStack(spacing: 12) {
            Text("Solve the sum")
            Text("\(operands.0) + \(operands.1) = ?")
                .font(.title)
            Button("Reveal") {
                operands = (Int.random(in: 1...6), Int.random(in: 1...6))
            }
            .buttonStyle(NeonButtonStyle())
        }
        .foregroundColor(.white)
    }
}

private struct WordLearningView: View {
    @State private var word: String = WordLearningView.words.randomElement() ?? "Box"
    var body: some View {
        VStack(spacing: 12) {
            Text("Say the word aloud")
            Text(word)
                .font(.largeTitle.weight(.bold))
            Button("New Word") {
                word = WordLearningView.words.randomElement() ?? word
            }
            .buttonStyle(NeonButtonStyle())
        }
        .foregroundColor(.white)
    }

    private static let words = ["Dice", "Tiles", "Add", "Win", "Box", "Score"]
}

struct LearningGameSheetView: View {
    var body: some View {
        NavigationStack {
            LearningGameBoardView()
                .navigationTitle("Learning Games")
        }
    }
}

extension LearningGame {
    static let defaultGames: [LearningGame] = [
        LearningGame(id: "shapes", title: "Shapes", description: "Count the number of glowing shapes."),
        LearningGame(id: "dice", title: "Dice", description: "Identify the die face and totals."),
        LearningGame(id: "dots", title: "Dots", description: "Quickly count the sparkling dots."),
        LearningGame(id: "math", title: "Math", description: "Practice addition with dice totals."),
        LearningGame(id: "words", title: "Words", description: "Sound out the dice-themed words."),
    ]
}
