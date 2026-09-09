//
//  Restriction.swift
//  Trace
//
//  What the user avoids, and how hard they avoid it.
//

import Foundation

/// How seriously a match should be taken.
///
/// `severe` is what lets the verdict logic count "may contain" traces even
/// when the global toggle is off.
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

/// One saved avoidance. `tagID` is the Open Food Facts tag ("en:milk"), which
/// is what the verdict logic matches on; `name` is only ever for display.
struct Restriction: Identifiable, Codable, Hashable {

    var id: String { tagID }

    let tagID: String
    let name: String
    var severity: Severity
}

/// Everything the Profile screen owns, as one value.
///
/// Kept together on purpose: a Firestore implementation can read and write it
/// as a single document without the store growing a method per field.
struct RestrictionSettings: Codable, Equatable {
    var restrictions: [Restriction] = []
    var countsMayContain = false
}
