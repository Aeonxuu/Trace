// the four answers a scan can produce

import SwiftUI

// which of the five tiers matched, so the why card can name the field
enum MatchSource: String, Codable, Hashable, CaseIterable {
    case allergens
    case traces
    case ingredients
    case ingredientAnalysis
    case additives

    // worded to drop into the why sentence
    var phrase: String {
        switch self {
        case .allergens: return "declared allergens"
        case .traces: return "may-contain traces"
        case .ingredients: return "ingredient list"
        case .ingredientAnalysis: return "ingredient analysis"
        case .additives: return "additives"
        }
    }
}

// one matched restriction, attributed to the earliest tier that caught it
struct VerdictMatch: Codable, Hashable {
    let name: String
    let source: MatchSource
}

enum Verdict: Codable, Hashable {

    // matches in tier order, never empty
    case contains(matches: [VerdictMatch])

    case clear
    case unknown

    // nothing came back, so the band carries the barcode instead
    case notFound

    var title: String {
        switch self {
        case .contains(let matches):
            return "Contains " + Self.sentenceList(matches.map { $0.name.lowercased() })
        case .clear: return "No match found"
        case .unknown: return "Not enough data"
        case .notFound: return "No product found"
        }
    }

    // the one place a verdict color is allowed, notFound takes ink instead
    var color: Color {
        switch self {
        case .contains: return Theme.contains
        case .clear: return Theme.clear
        case .unknown: return Theme.unknown
        case .notFound: return Theme.ink
        }
    }

    var iconName: String {
        switch self {
        case .contains: return "exclamationmark.triangle"
        case .clear: return "checkmark.circle"
        case .unknown: return "questionmark.circle"
        case .notFound: return "barcode.viewfinder"
        }
    }

    // why card body, one line per match
    var reasonLines: [String] {
        switch self {
        case .contains(let matches):
            // names arrive sentence-cased, .capitalized would title-case them
            return matches.map { "\($0.name) is listed in this product's \($0.source.phrase)." }
        case .clear:
            return ["None of your avoided ingredients appear in this product."]
        case .unknown:
            return ["This product has no ingredient list on file."]
        case .notFound:
            return ["Nothing came back for this barcode. It may not be in Open "
                + "Food Facts yet, or the lookup did not go through."]
        }
    }

    // "milk", "milk and peanuts", "milk, peanuts and soy"
    private static func sentenceList(_ items: [String]) -> String {
        guard let last = items.last else { return "" }

        switch items.count {
        case 1: return last
        case 2: return items[0] + " and " + last
        default: return items.dropLast().joined(separator: ", ") + " and " + last
        }
    }

    // short form for the chips on today and history
    var chipLabel: String {
        switch self {
        case .contains: return "Flagged"
        case .clear: return "No match"
        case .unknown: return "No data"
        case .notFound: return "Not found"
        }
    }

    // whether this verdict flagged something, for counting
    var isContains: Bool {
        if case .contains = self { return true }
        return false
    }

    // every term to highlight in the ingredient list
    var matchedItems: [String] {
        switch self {
        case .contains(let matches): return matches.map(\.name)
        case .clear, .unknown, .notFound: return []
        }
    }
}
