import SwiftUI

/// A modern, perfectly aligned timer display using native SwiftUI transitions.
struct TimerDisplayView: View {
    let totalSeconds: Double
    let timeRemaining: Double

    private var displayedSeconds: Int {
        max(0, Int(ceil(timeRemaining)))
    }

    private var minutes: Int { displayedSeconds / 60 }
    private var seconds: Int { displayedSeconds % 60 }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Minutes - using monospacedDigit to prevent horizontal jitter
            Text(String(format: "%02d", minutes))
                .font(.system(size: 90, weight: .bold, design: .rounded).monospacedDigit())
            
            // Colon - fixed width and carefully aligned
            Text(":")
                .font(.system(size: 90, weight: .bold, design: .rounded))
                // Optical adjustment for SF Rounded colon vertical center
                .baselineOffset(6)
                .frame(width: 24)
            
            // Seconds
            Text(String(format: "%02d", seconds))
                .font(.system(size: 90, weight: .bold, design: .rounded).monospacedDigit())
        }
        .foregroundStyle(.white)
        // The magic for smooth rolling numbers (iOS 17+)
        .contentTransition(.numericText(value: Double(displayedSeconds)))
        // Use a snappy animation for the roll
        .animation(.snappy(duration: 0.3, extraBounce: 0), value: displayedSeconds)
        // Fixed frame to ensure the container doesn't shift
        .frame(height: 100)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Remaining time")
        .accessibilityValue("\(minutes) minutes and \(seconds) seconds")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 50) {
            TimerDisplayView(totalSeconds: 1500, timeRemaining: 1500)
            TimerDisplayView(totalSeconds: 1500, timeRemaining: 1245)
        }
    }
}
