import SwiftUI
import AVFoundation

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
                            VStack(alignment: .leading, spacing: 6) {
                                Text(game.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(game.description)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                            .frame(width: 240, alignment: .leading)
                            .background(selectedGame == game ? Color.blue.opacity(0.35) : Color.white.opacity(0.08))
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
        VStack(alignment: .leading, spacing: 16) {
            Text(game.title)
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            Text(game.description)
                .foregroundColor(.white.opacity(0.8))
            Divider().background(Color.white.opacity(0.2))
            switch game.id {
            case "word-sound": WordSoundBuilderView()
            case "shape-explorer": ShapeExplorerView()
            case "dice-detective": DiceDotDetectiveView()
            case "secret-flash": SecretDotFlashView()
            case "math-mixer": MathMixerView()
            default: EmptyView()
            }
        }
    }
}

private final class SpeechHelper: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}

private struct WordSoundBuilderView: View {
    @StateObject private var speech = SpeechHelper()
    @State private var wordLength: Int = 4
    @State private var usePremiumVoice: Bool = false
    @State private var currentWord: String = WordSoundBuilderView.wordsByLength[4]?.randomElement() ?? "tile"
    @State private var status: String = "Tap a tile to hear the sound."

    private var letters: [String] { currentWord.map { String($0).uppercased() } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(value: $wordLength, in: 2...6, step: 1) {
                Text("Word length: \(wordLength) letters")
            }
            .onChange(of: wordLength) { _ in generateWord() }

            Toggle("Stream premium Voice RSS", isOn: $usePremiumVoice)
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
                .onChange(of: usePremiumVoice) { enabled in
                    status = enabled ? "Premium voice requests fallback to on-device speech in offline mode." : "Using system speech engine."
                }

            HStack(spacing: 10) {
                ForEach(letters, id: \.self) { letter in
                    Button(action: { speak(letter) }) {
                        Text(letter)
                            .font(.title.bold())
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }

            Button("Say the whole word") { speak(currentWord) }
                .buttonStyle(NeonButtonStyle())

            Button("New word") { generateWord() }
                .buttonStyle(SecondaryButtonStyle())

            Text(status)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
        }
        .foregroundColor(.white)
    }

    private func speak(_ text: String) {
        speech.speak(text)
        status = "Playing \(text.uppercased())"
    }

    private func generateWord() {
        let word = WordSoundBuilderView.wordsByLength[wordLength]?.randomElement() ?? currentWord
        currentWord = word
        status = "Loaded \(word.uppercased())."
    }

    private static let wordsByLength: [Int: [String]] = {
        let source = [
            "go", "hi", "add", "sum", "tile", "glow", "dice", "roll", "math", "shape", "sound", "mix", "grid",
            "flash", "hint", "score", "total", "learn", "study", "swift", "touch", "count", "number", "target"
        ]
        return Dictionary(grouping: source) { $0.count }
    }()
}

private struct ShapeExplorerView: View {
    private enum ShapeType: String, CaseIterable, Identifiable {
        case polygon
        case quadrilateral
        case circle
        case ellipse

        var id: String { rawValue }
        var label: String {
            switch self {
            case .polygon: return "Polygon"
            case .quadrilateral: return "Quadrilateral"
            case .circle: return "Circle"
            case .ellipse: return "Ellipse"
            }
        }

        var funFact: String {
            switch self {
            case .polygon: return "Regular polygons share equal angles and sides."
            case .quadrilateral: return "Quadrilaterals always have interior angles that add to 360°."
            case .circle: return "Every point on a circle sits the same distance from the center."
            case .ellipse: return "Ellipses have two foci that reveal their stretched shape."
            }
        }
    }

    @State private var shapeType: ShapeType = .polygon
    @State private var sides: Int = 5
    @State private var tappedVertices: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Shape", selection: $shapeType) {
                ForEach(ShapeType.allCases) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if shapeType == .polygon {
                Stepper(value: $sides, in: 3...10) {
                    Text("Sides: \(sides)")
                }
                .onChange(of: sides) { _ in tappedVertices.removeAll() }
            }

            GeometryReader { geometry in
                ZStack {
                    shapePath(in: geometry.size)
                        .stroke(Color.cyan.opacity(0.7), lineWidth: 3)
                        .background(shapeFill)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    ForEach(Array(vertexPoints(in: geometry.size).enumerated()), id: \.offset) { index, point in
                        Circle()
                            .fill(tappedVertices.contains(index) ? Color.green.opacity(0.8) : Color.white.opacity(0.9))
                            .frame(width: 18, height: 18)
                            .position(point)
                            .shadow(color: .cyan.opacity(0.4), radius: 6)
                            .onTapGesture {
                                if tappedVertices.contains(index) {
                                    tappedVertices.remove(index)
                                } else {
                                    tappedVertices.insert(index)
                                }
                            }
                    }
                }
            }
            .frame(height: 220)

            Text("Tapped vertices: \(tappedVertices.count)")
                .font(.headline)
                .foregroundColor(.white)

            Text(shapeType.funFact)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
        }
        .foregroundColor(.white)
    }

    private func vertexPoints(in size: CGSize) -> [CGPoint] {
        switch shapeType {
        case .polygon:
            return regularPolygonPoints(sides: sides, in: size)
        case .quadrilateral:
            return quadrilateralPoints(in: size)
        case .circle, .ellipse:
            return regularPolygonPoints(sides: 12, in: size)
        }
    }

    private func shapePath(in size: CGSize) -> Path {
        switch shapeType {
        case .polygon:
            let points = regularPolygonPoints(sides: sides, in: size)
            return Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
                path.closeSubpath()
            }
        case .quadrilateral:
            let points = quadrilateralPoints(in: size)
            return Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
                path.closeSubpath()
            }
        case .circle:
            return Path(ellipseIn: CGRect(x: 20, y: 20, width: size.width - 40, height: size.width - 40))
        case .ellipse:
            return Path(ellipseIn: CGRect(x: 20, y: 40, width: size.width - 40, height: size.height - 80))
        }
    }

    private var shapeFill: some View {
        LinearGradient(colors: [Color.blue.opacity(0.25), Color.purple.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func regularPolygonPoints(sides: Int, in size: CGSize) -> [CGPoint] {
        guard sides > 2 else { return [] }
        let radius = min(size.width, size.height) / 2.5
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        return (0..<sides).map { index in
            let angle = (Double(index) / Double(sides)) * (2 * Double.pi) - Double.pi / 2
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius
            return CGPoint(x: x, y: y)
        }
    }

    private func quadrilateralPoints(in size: CGSize) -> [CGPoint] {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let offsets = [CGPoint(x: -120, y: -60), CGPoint(x: 140, y: -40), CGPoint(x: 100, y: 80), CGPoint(x: -140, y: 60)]
        return offsets.map { CGPoint(x: center.x + $0.x * 0.5, y: center.y + $0.y * 0.5) }
    }
}

private struct DiceDotDetectiveView: View {
    @State private var diceCount: Int = 2
    @State private var guess: Int?
    @State private var revealed: Bool = false
    @State private var diceValues: [Int] = []
    @State private var feedback: String = "Make a prediction and reveal the dice."

    private var totalRange: ClosedRange<Int> { diceCount...diceCount * 6 }
    private var gridColumns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 8), count: 6) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(value: $diceCount, in: 1...6) {
                Text("Dice: \(diceCount)")
            }
            .onChange(of: diceCount) { _ in reset() }

            Text("Pick your predicted total")
                .foregroundColor(.white.opacity(0.8))

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(Array(totalRange), id: \.self) { value in
                    Button {
                        guess = value
                    } label: {
                        Text("\(value)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(guess == value ? Color.blue.opacity(0.6) : Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Reveal Dice") { reveal() }
                    .buttonStyle(NeonButtonStyle())
                    .disabled(guess == nil)

                Button("Reset") { reset() }
                    .buttonStyle(SecondaryButtonStyle())
            }

            if revealed {
                HStack(spacing: 16) {
                    ForEach(diceValues.indices, id: \.self) { index in
                        DiceView(value: diceValues[index], size: 64)
                    }
                }
            }

            Text(feedback)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
        }
        .foregroundColor(.white)
    }

    private func reveal() {
        diceValues = (0..<diceCount).map { _ in Int.random(in: 1...6) }
        revealed = true
        let total = diceValues.reduce(0, +)
        if total == guess {
            feedback = "Great ears! You nailed the total of \(total)."
        } else {
            feedback = "The dice sum to \(total). Try again!"
        }
    }

    private func reset() {
        diceValues.removeAll()
        guess = nil
        revealed = false
        feedback = "Make a prediction and reveal the dice."
    }
}

private struct SecretDotFlashView: View {
    @State private var minDots: Int = 4
    @State private var maxDots: Int = 12
    @State private var flashDuration: Double = 1.5
    @State private var activeDots: [CGPoint] = []
    @State private var isVisible: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Stepper("Min dots: \(minDots)", value: $minDots, in: 1...maxDots)
                Stepper("Max dots: \(maxDots)", value: $maxDots, in: minDots...36)
            }

            VStack(alignment: .leading) {
                Text("Flash time: \(String(format: "%.1f", flashDuration))s")
                    .foregroundColor(.white.opacity(0.8))
                Slider(value: $flashDuration, in: 0.5...3, step: 0.1)
                    .accentColor(.cyan)
            }

            Button(isVisible ? "Hiding..." : "Start Flash") {
                startFlash()
            }
            .buttonStyle(NeonButtonStyle())
            .disabled(isVisible)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 200)

                if isVisible {
                    ForEach(activeDots.indices, id: \.self) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .position(activeDots[index])
                    }
                } else {
                    Text("Dots hidden. Tap start to flash again.")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .foregroundColor(.white)
    }

    private func startFlash() {
        let count = Int.random(in: minDots...maxDots)
        activeDots = generateDots(count: count)
        isVisible = true
        Task {
            try? await Task.sleep(nanoseconds: UInt64(flashDuration * 1_000_000_000))
            withAnimation(.easeInOut) {
                isVisible = false
            }
        }
    }

    private func generateDots(count: Int) -> [CGPoint] {
        var positions: [CGPoint] = []
        let size = CGSize(width: 280, height: 180)
        var attempts = 0
        while positions.count < count && attempts < 500 {
            attempts += 1
            let point = CGPoint(x: CGFloat.random(in: 20...(size.width - 20)), y: CGFloat.random(in: 20...(size.height - 20)))
            if positions.allSatisfy({ hypot($0.x - point.x, $0.y - point.y) > 24 }) {
                positions.append(point)
            }
        }
        return positions
    }
}

private struct MathMixerView: View {
    private enum Operation: String, CaseIterable, Identifiable {
        case addition = "+"
        case subtraction = "−"
        case multiplication = "×"
        case division = "÷"

        var id: String { rawValue }

        func evaluate(a: Int, b: Int) -> Double {
            switch self {
            case .addition: return Double(a + b)
            case .subtraction: return Double(a - b)
            case .multiplication: return Double(a * b)
            case .division: return Double(a) / Double(max(b, 1))
            }
        }
    }

    private enum Difficulty: String, CaseIterable, Identifiable {
        case starter
        case advanced

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    @State private var operation: Operation = .addition
    @State private var difficulty: Difficulty = .starter
    @State private var operands: (Int, Int) = MathMixerView.generateOperands(for: .addition, difficulty: .starter)
    @State private var showAnswer: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Operation", selection: $operation) {
                ForEach(Operation.allCases) { op in
                    Text(op.rawValue).tag(op)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: operation) { _ in roll() }

            Picker("Difficulty", selection: $difficulty) {
                ForEach(Difficulty.allCases) { diff in
                    Text(diff.label).tag(diff)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: difficulty) { _ in roll() }

            Text("What is \(operands.0) \(operation.rawValue) \(operands.1)?")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            if showAnswer {
                Text(answerText)
                    .font(.headline)
                    .foregroundColor(.mint)
            }

            HStack(spacing: 12) {
                Button(showAnswer ? "Hide Answer" : "Reveal Answer") {
                    withAnimation { showAnswer.toggle() }
                }
                .buttonStyle(NeonButtonStyle())

                Button("New Equation") { roll() }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .foregroundColor(.white)
    }

    private var answerText: String {
        let result = operation.evaluate(a: operands.0, b: operands.1)
        if operation == .division {
            return String(format: "= %.2f", result)
        }
        return "= \(Int(result))"
    }

    private func roll() {
        operands = MathMixerView.generateOperands(for: operation, difficulty: difficulty)
        showAnswer = false
    }

    private static func generateOperands(for operation: Operation, difficulty: Difficulty) -> (Int, Int) {
        let range: ClosedRange<Int>
        switch (operation, difficulty) {
        case (.addition, .starter): range = 1...12
        case (.addition, .advanced): range = 10...36
        case (.subtraction, .starter): range = 1...12
        case (.subtraction, .advanced): range = 10...48
        case (.multiplication, .starter): range = 1...12
        case (.multiplication, .advanced): range = 6...18
        case (.division, .starter): range = 1...12
        case (.division, .advanced): range = 6...24
        }

        var a = Int.random(in: range)
        var b = Int.random(in: range)

        if operation == .subtraction && b > a { swap(&a, &b) }
        if operation == .division {
            b = max(1, b)
            a = b * Int.random(in: 1...(difficulty == .starter ? 6 : 12))
        }
        return (a, b)
    }
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
        LearningGame(id: "word-sound", title: "Word Sound Builder", description: "Tap letters to hear phonetics and build confident readers."),
        LearningGame(id: "shape-explorer", title: "Shape Explorer", description: "Count glowing vertices while exploring polygons and curves."),
        LearningGame(id: "dice-detective", title: "Dice Dot Detective", description: "Predict totals, reveal dice, and celebrate quick mental maths."),
        LearningGame(id: "secret-flash", title: "Secret Dot Flash", description: "Flash non-overlapping dots for subitising practice."),
        LearningGame(id: "math-mixer", title: "Math Mixer", description: "Mix operations and difficulties, then reveal answers on demand."),
    ]
}
