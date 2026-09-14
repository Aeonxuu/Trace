// the matching engine, pure: same inputs always give the same verdict

import Foundation

nonisolated enum VerdictEngine {

    // checks a product against what the user avoids, tier by tier
    static func evaluate(
        product: Product,
        restrictions: [Restriction],
        countTraces: Bool
    ) -> Verdict {

        var matches: [VerdictMatch] = []
        var reported: Set<String> = []

        // tiers do not return, so reported keeps one restriction from listing twice
        func collect(_ candidates: [Restriction], in tags: [String]?, as source: MatchSource) {
            for restriction in all(of: candidates, in: tags)
            where reported.insert(restriction.tagID).inserted {
                matches.append(VerdictMatch(name: restriction.name, source: source))
            }
        }

        // 1. declared allergens
        collect(restrictions, in: product.allergensTags, as: .allergens)

        // 2. traces, for severe restrictions or when the toggle is on
        let traceSensitive = restrictions.filter { countTraces || $0.severity == .severe }
        collect(traceSensitive, in: product.tracesTags, as: .traces)
        collect(traceSensitive, in: tokens(of: product.tracesFromIngredients), as: .traces)

        // 3, 4, 5. ingredients, analysis, additives
        collect(restrictions, in: product.ingredientsTags, as: .ingredients)
        collect(restrictions, in: product.ingredientsAnalysisTags, as: .ingredientAnalysis)
        collect(restrictions, in: product.additivesTags, as: .additives)

        if !matches.isEmpty {
            return .contains(matches: matches)
        }

        // nothing matched only means clear if there was something to check
        return hasSomethingToCheck(product) ? .clear : .unknown
    }

    // MARK: - matching

    // every restriction present in tags, ordered by the user's own list
    private static func all(
        of restrictions: [Restriction],
        in tags: [String]?
    ) -> [Restriction] {
        guard let tags, !tags.isEmpty else { return [] }

        let present = Set(tags.map(normalized))
        return restrictions.filter { !forms(of: $0).isDisjoint(with: present) }
    }

    // traces_from_ingredients is free text, so it is split before matching
    private static func tokens(of field: String?) -> [String]? {
        guard let field else { return nil }

        let pieces = field
            .split(separator: ",")
            .map(String.init)
            .filter { !normalized($0).isEmpty }

        return pieces.isEmpty ? nil : pieces
    }

    // tag id plus bare form, compared whole so en:milk misses en:coconut-milk
    private static func forms(of restriction: Restriction) -> Set<String> {
        let tag = normalized(restriction.tagID)
        guard let colon = tag.lastIndex(of: ":") else { return [tag] }
        return [tag, String(tag[tag.index(after: colon)...])]
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - enough to go on

    // exactly the three fields CLAUDE.md names, nothing else counts
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
