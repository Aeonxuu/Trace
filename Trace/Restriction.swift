// what the user avoids, and how hard

import Foundation

// severe is what lets traces count while the global toggle is off
enum Severity: String, Codable, CaseIterable, Hashable {
    case avoid
    case severe

    var label: String {
        switch self {
        case .avoid: return "Avoid"
        case .severe: return "Severe"
        }
    }
}

// one saved avoidance, tagID is matched on and name is only for display
struct Restriction: Identifiable, Codable, Hashable {

    var id: String { tagID }

    let tagID: String
    let name: String
    var severity: Severity
}

// everything profile owns as one value, so firestore can write one document
struct RestrictionSettings: Codable, Equatable {
    var restrictions: [Restriction] = []
    var countsMayContain = false
}
