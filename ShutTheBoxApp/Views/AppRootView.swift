import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.06, blue: 0.15), Color(red: 0.08, green: 0.09, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HeaderView(isCompact: isCompact)
                    .environmentObject(store)

                ScrollView {
                    VStack(spacing: 24) {
                        if store.options.showLearningGames && store.showLearning {
                            LearningGameBoardView()
                        } else {
                            GameBoardView(isCompact: isCompact)
                        }

                        PlayersView()
                            .environmentObject(store)
                            .padding(.horizontal)

                        HistoryView()
                            .environmentObject(store)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { store.showSettings },
                    set: { value in
                        if value != store.showSettings {
                            store.toggleSettings()
                        }
                    }
                )
            ) {
                SettingsSheetView()
                    .environmentObject(store)
                    .environmentObject(themeManager)
            }
            .sheet(
                isPresented: Binding(
                    get: { store.showHistory },
                    set: { value in
                        if value != store.showHistory {
                            store.toggleHistory()
                        }
                    }
                )
            ) {
                HistorySheetView().environmentObject(store)
            }
            .sheet(
                isPresented: Binding(
                    get: { store.showInstructions },
                    set: { value in
                        if value != store.showInstructions {
                            store.toggleInstructions()
                        }
                    }
                )
            ) {
                InstructionsView().environmentObject(store)
            }
            .sheet(
                isPresented: Binding(
                    get: { store.showWinners },
                    set: { value in
                        if value != store.showWinners {
                            store.toggleWinners()
                        }
                    }
                )
            ) {
                WinnersView().environmentObject(store)
            }
            .sheet(isPresented: Binding(get: { store.options.showLearningGames && store.showLearning }, set: { value in store.showLearning = value })) {
                LearningGameSheetView().environmentObject(store)
            }
        }
        .onAppear {
            themeManager.applyCurrentTheme()
        }
    }
}
