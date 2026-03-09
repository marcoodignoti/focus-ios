import SwiftUI

@main
struct FocusApp: App {
    @State private var modesStore   = FocusModesStore()
    @State private var historyStore = FocusHistoryStore()
    @State private var uiStore      = UIStateStore()
    @State private var achievementStore = AchievementStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(modesStore)
                .environment(historyStore)
                .environment(uiStore)
                .environment(achievementStore)
        }
    }
}


