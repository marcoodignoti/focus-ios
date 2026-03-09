import SwiftUI

struct ContentView: View {
    @State private var selectedPage = 0

    var body: some View {
        // Vertical paging: Home+Calendar (page 0) above Stats (page 1)
        // User swipes UP from home to reveal statistics
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Page 0 — Home (Timer) + Calendar horizontal pager
                TabView(selection: $selectedPage) {
                    TimerView()
                        .tag(0)
                        .ignoresSafeArea()

                    FocusCalendarView()
                        .tag(1)
                        .ignoresSafeArea()
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .containerRelativeFrame(.vertical)

                // Page 1 — Statistics (below, reached by swiping up)
                StatsView()
                    .containerRelativeFrame(.vertical)
            }
        }
        .scrollTargetBehavior(.paging)
        .defaultScrollAnchor(.top)       // start at the top page (Home)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}
