// bundled allergen taxonomy: tag ids and english names

import Foundation

// one pickable tag
struct Allergen: Identifiable, Hashable {

    // tag id, e.g. "en:milk"
    let id: String

    // english display name
    let name: String
}

enum AllergenCatalog {

    // read once at first use, ships with the app
    static let all: [Allergen] = load()

    // display name for a tag id, falling back to the de-slugified tag
    static func displayName(forTagID tagID: String) -> String {
        let normalized = tagID.trimmed.lowercased()

        if let known = byTagID[normalized] {
            return known.name
        }

        let bare: String
        if let colon = normalized.lastIndex(of: ":") {
            bare = String(normalized[normalized.index(after: colon)...])
        } else {
            bare = normalized
        }

        return bare.replacingOccurrences(of: "-", with: " ").sentenceCased
    }

    private static let byTagID: [String: Allergen] = Dictionary(
        all.map { ($0.id.lowercased(), $0) },
        uniquingKeysWith: { first, _ in first }
    )

    // "en:none" describes a product, not something a person avoids
    private static let excludedTagIDs: Set<String> = ["en:none"]

    // parses allergens.json as untyped json, so one bad entry costs only itself
    private static func load() -> [Allergen] {
        guard let url = Bundle.main.url(forResource: "allergens", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        let allergens = root.compactMap { tagID, value -> Allergen? in
            guard !excludedTagIDs.contains(tagID),
                  let entry = value as? [String: Any],
                  let names = entry["name"] as? [String: Any],
                  let english = (names["en"] as? String)?.trimmed,
                  !english.isEmpty else {
                return nil
            }
            return Allergen(id: tagID, name: english.sentenceCased)
        }

        return allergens.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}

private extension String {

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // raises the first letter only, .capitalized would title-case
    var sentenceCased: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
