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
                        if store.options.enableLearningGames && store.showLearning {
                            LearningGameBoardView()
                        } else {
                            GameBoardView(isCompact: isCompact)
                        }

                        PlayersView()
                            .environmentObject(store)
                            .padding(.horizontal)

                        if store.options.showHeaderDetails {
                            HistoryView()
                                .environmentObject(store)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .sheet(isPresented: $store.showSettings) {
                SettingsSheetView()
                    .environmentObject(store)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $store.showHistory) { HistorySheetView().environmentObject(store) }
            .sheet(isPresented: $store.showInstructions) { InstructionsView().environmentObject(store) }
            .sheet(isPresented: $store.showWinners) { WinnersView().environmentObject(store) }
            .sheet(isPresented: Binding(get: { store.options.enableLearningGames && store.showLearning }, set: { value in store.showLearning = value })) {
                LearningGameSheetView().environmentObject(store)
            }
        }
        .onAppear {
            themeManager.applyCurrentTheme()
        }
    }
}
