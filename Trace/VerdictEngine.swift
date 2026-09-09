//
//  VerdictEngine.swift
//  Trace
//
//  The matching engine. Pure: same product and same restrictions always give
//  the same verdict, with nothing read from storage or the network.
//

import Foundation

enum VerdictEngine {

    /// Checks a product against what the user avoids.
    ///
    /// The five tiers run in the order CLAUDE.md sets out and stop at the
    /// first match, so the most direct evidence wins: a declared allergen is
    /// reported as a declared allergen even when the same item also shows up
    /// further down in the additives.
    static func evaluate(
        product: Product,
        restrictions: [Restriction],
        countTraces: Bool
    ) -> Verdict {

        // 1. Declared allergens.
        if let hit = first(of: restrictions, in: product.allergensTags) {
            return .contains(matched: hit.name, source: .allergens)
        }

        // 2. Traces, but only for restrictions that asked to hear about them:
        // a severe restriction always does, everyone else only when the
        // global toggle is on.
        let traceSensitive = restrictions.filter { countTraces || $0.severity == .severe }
        if let hit = first(of: traceSensitive, in: product.tracesTags)
            ?? first(of: traceSensitive, in: tokens(of: product.tracesFromIngredients)) {
            return .contains(matched: hit.name, source: .traces)
        }

        // 3. Ingredient tags.
        if let hit = first(of: restrictions, in: product.ingredientsTags) {
            return .contains(matched: hit.name, source: .ingredients)
        }

        // 4. Ingredient analysis.
        if let hit = first(of: restrictions, in: product.ingredientsAnalysisTags) {
            return .contains(matched: hit.name, source: .ingredientAnalysis)
        }

        // 5. Additives.
        if let hit = first(of: restrictions, in: product.additivesTags) {
            return .contains(matched: hit.name, source: .additives)
        }

        // Nothing matched, which only means "clear" if there was something to
        // check. Otherwise the honest answer is that we do not know.
        return hasSomethingToCheck(product) ? .clear : .unknown
    }

    // MARK: - Matching

    /// The first restriction present in `tags`.
    ///
    /// Ordered by the user's own list rather than by the product's tags, so a
    /// tie resolves the same way every time no matter how Open Food Facts
    /// happens to order its fields.
    private static func first(
        of restrictions: [Restriction],
        in tags: [String]?
    ) -> Restriction? {
        guard let tags, !tags.isEmpty else { return nil }

        let present = Set(tags.map(normalized))
        return restrictions.first { !forms(of: $0).isDisjoint(with: present) }
    }

    /// `traces_from_ingredients` is one free-text field rather than a list, so
    /// it is split before being matched like any other tag source.
    private static func tokens(of field: String?) -> [String]? {
        guard let field else { return nil }

        let pieces = field
            .split(separator: ",")
            .map(String.init)
            .filter { !normalized($0).isEmpty }

        return pieces.isEmpty ? nil : pieces
    }

    /// The tag ID plus its bare form. Tag lists carry "en:milk", while the
    /// free-text trace field is just as likely to say "milk"; whole values are
    /// compared either way, so "en:milk" never matches "en:coconut-milk".
    private static func forms(of restriction: Restriction) -> Set<String> {
        let tag = normalized(restriction.tagID)
        guard let colon = tag.lastIndex(of: ":") else { return [tag] }
        return [tag, String(tag[tag.index(after: colon)...])]
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Enough to go on

    /// CLAUDE.md names exactly three fields here. Nothing else counts: a
    /// product carrying only additives still has no ingredient list behind it,
    /// so it cannot be called clear.
    private static func hasSomethingToCheck(_ product: Product) -> Bool {
        isPresent(product.allergensTags)
            || isPresent(product.ingredientsTags)
            || product.ingredientText != nil
    }

    private static func isPresent(_ tags: [String]?) -> Bool {
        guard let tags else { return false }
        return !tags.isEmpty
    }
}
