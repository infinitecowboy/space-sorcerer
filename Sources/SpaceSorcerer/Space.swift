import Foundation

struct Space {
    let displayID: String
    let spaceID: Int
    let spaceName: String
    let spaceIndex: Int       // 1-based global index
    let isCurrentSpace: Bool
    let isFullScreen: Bool
}

enum DisplayStyle: String, CaseIterable, Identifiable {
    case dots = "dots"
    case named = "named"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dots: return "Dots"
        case .named: return "Named"
        }
    }
}
