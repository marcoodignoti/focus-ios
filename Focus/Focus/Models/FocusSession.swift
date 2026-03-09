import Foundation
import Combine

struct FocusSession: Identifiable, Codable, Equatable {
    var id: String
    var modeId: String
    var modeTitle: String
    var color: String         // hex color string, e.g. "#0A84FF"
    var startTime: Double     // Unix timestamp in milliseconds
    var duration: Int         // minutes

    var startDate: Date {
        Date(timeIntervalSince1970: startTime / 1000)
    }
}
