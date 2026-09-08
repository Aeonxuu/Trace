//
//  Verdict.swift
//  Trace
//
//  The three answers a scan can produce.
//

import SwiftUI

enum Verdict {

    /// Matched something the user avoids. The payload is the matched item.
    case contains(String)
    case clear
    case unknown

    var title: String {
        switch self {
        case .contains(let item): return "Contains \(item)"
        case .clear: return "No matches"
        case .unknown: return "Not enough data"
        }
    }

    /// The one place a verdict color is allowed.
    var color: Color {
        switch self {
        case .contains: return Theme.contains
        case .clear: return Theme.clear
        case .unknown: return Theme.unknown
        }
    }

    var iconName: String {
        switch self {
        case .contains: return "exclamationmark.triangle"
        case .clear: return "checkmark.circle"
        case .unknown: return "questionmark.circle"
        }
    }

    var reason: String {
        switch self {
        case .contains(let item):
            return "\(item.capitalized) is listed as a declared allergen."
        case .clear:
            return "Nothing you avoid appears in this product."
        case .unknown:
            return "This product has no ingredient or allergen data to check."
        }
    }

    /// The term to highlight in the ingredient list.
    var matchedItem: String? {
        switch self {
        case .contains(let item): return item
        case .clear, .unknown: return nil
        }
    }
}
