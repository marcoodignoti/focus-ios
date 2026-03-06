import SwiftUI

struct ContentView: View {
    @State private var selectedPage = 0

    var body: some View {
        TabView(selection: $selectedPage) {
            TimerView()
                .tag(0)
                .ignoresSafeArea()

            FocusCalendarView()
                .tag(1)
                .ignoresSafeArea()
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(FocusModesStore())
        .environment(FocusHistoryStore())
        .environment(UIStateStore())
}

