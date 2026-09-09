//
//  Verdict.swift
//  Trace
//
//  The four answers a scan can produce.
//

import SwiftUI

/// Which of the five tiers in CLAUDE.md produced a match.
///
/// Carried on the verdict so the Why card can name the field and not just the
/// ingredient: "listed in this product's declared allergens" says something
/// different from "listed in this product's additives".
enum MatchSource: String, Hashable, CaseIterable {
    case allergens
    case traces
    case ingredients
    case ingredientAnalysis
    case additives

    /// Worded to drop into the Why sentence.
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

enum Verdict {

    /// Matched something the user avoids. `matched` is the item as it should
    /// read on screen; `source` is the tier that caught it.
    case contains(matched: String, source: MatchSource)

    case clear
    case unknown

    /// Open Food Facts had nothing for the barcode, or the lookup never
    /// completed. There is no product to talk about, so the band carries the
    /// scanned code instead.
    case notFound

    var title: String {
        switch self {
        case .contains(let matched, _): return "Contains \(matched.lowercased())"
        case .clear: return "No match found"
        case .unknown: return "Not enough data"
        case .notFound: return "No product found"
        }
    }

    /// The one place a verdict color is allowed.
    ///
    /// `notFound` deliberately takes ink rather than a verdict color: nothing
    /// was checked, so nothing is being claimed about the product.
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

    var reason: String {
        switch self {
        case .contains(let matched, let source):
            // `matched` arrives sentence-cased from the catalog, so it is used
            // as written: `.capitalized` would title-case "sulphur dioxide and
            // sulphites".
            return "\(matched) is listed in this product's \(source.phrase)."
        case .clear:
            return "None of your avoided ingredients appear in this product."
        case .unknown:
            return "This product has no ingredient list on file."
        case .notFound:
            return "Nothing came back for this barcode. It may not be in Open "
                + "Food Facts yet, or the lookup did not go through."
        }
    }

    /// The term to highlight in the ingredient list.
    var matchedItem: String? {
        switch self {
        case .contains(let matched, _): return matched
        case .clear, .unknown, .notFound: return nil
        }
    }
}
