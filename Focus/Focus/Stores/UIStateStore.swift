import Foundation
import Observation

@Observable
@MainActor
class UIStateStore {
    var isModeSelectionVisible = false
    var isRulerVisible         = false
    var isAddSessionVisible    = false
    var selectedDate: Date     = Date()
}
