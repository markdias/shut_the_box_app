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

                Section(header: Text("Tiles")) {
                    Picker("Highest tile", selection: Binding(get: { store.options.maxTile }, set: { newValue in
                        store.updateOptions { $0.maxTile = newValue }
                    })) {
                        Text("1 – 9").tag(9)
                        Text("1 – 10").tag(10)
                        Text("1 – 12").tag(12)
                        if store.options.allowsMadness {
                            Text("1 – 56").tag(56)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Rules")) {
                    Picker("One-die rule", selection: Binding(get: { store.options.oneDieRule }, set: { newValue in
                        store.updateOptions { $0.oneDieRule = newValue }
                    })) {
                        ForEach(OneDieRule.allCases) { rule in
                            VStack(alignment: .leading) {
                                Text(rule.title)
                                Text(rule.helpText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(rule)
                        }
                    }

                    Picker("Scoring mode", selection: Binding(get: { store.options.scoringMode }, set: { newValue in
                        store.updateOptions { $0.scoringMode = newValue }
                    })) {
                        ForEach(ScoringMode.allCases) { mode in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title)
                                Text(mode.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.inline)

                    if store.options.scoringMode == .targetRace {
                        Stepper(value: Binding(get: { store.options.targetGoal }, set: { newValue in
                            store.updateOptions { $0.targetGoal = max(10, newValue) }
                        }), in: 10...300, step: 5) {
                            Text("Target goal: \(store.options.targetGoal)")
                        }
                    }

                    Toggle("Require confirmation", isOn: Binding(get: { store.options.requireConfirmation }, set: { newValue in
                        store.updateOptions { $0.requireConfirmation = newValue }
                    }))

                    Toggle("Instant win on shut", isOn: Binding(get: { store.options.instantWinOnShut }, set: { newValue in
                        store.updateOptions { $0.instantWinOnShut = newValue }
                    }))
                    .disabled(store.options.scoringMode == .instantWin)

                    Toggle("Auto-retry on failure", isOn: Binding(get: { store.options.autoRetry }, set: { value in
                        store.updateOptions { $0.autoRetry = value }
                    }))
                }

                Section(header: Text("Interface")) {
                    Toggle("Show header details", isOn: Binding(get: { store.options.showHeaderDetails }, set: { value in
                        store.updateOptions { $0.showHeaderDetails = value }
                    }))

                    Toggle("Show learning games", isOn: Binding(get: { store.options.showLearningGames }, set: { value in
                        store.updateOptions { $0.showLearningGames = value }
                    }))

                    Toggle("Show code tools", isOn: Binding(get: { store.options.showCodeTools }, set: { value in
                        store.updateOptions { $0.showCodeTools = value }
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
