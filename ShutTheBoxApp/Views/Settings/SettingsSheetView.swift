import SwiftUI

struct SettingsSheetView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Theme")) {
                    Picker("Theme", selection: $themeManager.theme) {
                        ForEach(ThemeOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }

                Section(header: Text("Tile Range")) {
                    Stepper(value: Binding(get: { store.options.tileRange.upperBound }, set: { newValue in
                        store.updateOptions { options in
                            options.tileRange = store.options.tileRange.lowerBound...max(store.options.tileRange.lowerBound, newValue)
                        }
                        store.tiles = GameLogic.initialTiles(range: store.options.tileRange)
                    }), in: 9...24) {
                        Text("Tiles: 1-\(store.options.tileRange.upperBound)")
                    }
                }

                Section(header: Text("Rules")) {
                    Picker("One-Die Rule", selection: Binding(get: { store.options.oneDieRule }, set: { newValue in
                        store.updateOptions { $0.oneDieRule = newValue }
                    })) {
                        ForEach(OneDieRule.allCases) { rule in
                            Text(rule.title).tag(rule)
                        }
                    }

                    Picker("Scoring Mode", selection: Binding(get: { store.options.scoringMode }, set: { newValue in
                        store.updateOptions { $0.scoringMode = newValue }
                    })) {
                        ForEach(ScoringMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }

                    Toggle("Require Confirmation", isOn: Binding(get: { store.options.requireConfirmation }, set: { newValue in
                        store.updateOptions { $0.requireConfirmation = newValue }
                    }))

                    Toggle("Instant Win", isOn: Binding(get: { store.options.instantWin }, set: { newValue in
                        store.updateOptions { $0.instantWin = newValue }
                    }))
                }

                Section(header: Text("Learning")) {
                    Toggle("Enable Learning Games", isOn: Binding(get: { store.options.enableLearningGames }, set: { value in
                        store.updateOptions { $0.enableLearningGames = value }
                    }))

                    Toggle("Auto Retry", isOn: Binding(get: { store.options.autoRetry }, set: { value in
                        store.updateOptions { $0.autoRetry = value }
                    }))
                }

                Section(header: Text("Header")) {
                    Toggle("Show Details", isOn: Binding(get: { store.options.showHeaderDetails }, set: { value in
                        store.updateOptions { $0.showHeaderDetails = value }
                    }))
                }

                Section(header: Text("About")) {
                    LabeledContent("Version", value: Bundle.main.versionString)
                    LabeledContent("Last Updated", value: Bundle.main.buildDateString)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

private extension Bundle {
    var versionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let date = Date()
        return formatter.string(from: date)
    }
}
