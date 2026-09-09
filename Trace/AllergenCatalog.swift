//
//  AllergenCatalog.swift
//  Trace
//
//  The bundled Open Food Facts allergen taxonomy, reduced to the tag IDs and
//  English names the picker needs.
//

import Foundation

/// One pickable tag.
struct Allergen: Identifiable, Hashable {

    /// The Open Food Facts tag ID, e.g. "en:milk".
    let id: String

    /// The English name, e.g. "Milk".
    let name: String
}

enum AllergenCatalog {

    /// Read once at first use. The file ships with the app and never changes
    /// underneath us.
    static let all: [Allergen] = load()

    /// The display name for a tag ID.
    ///
    /// Falls back to the tag itself, de-slugified, because a product declares
    /// tags from the whole Open Food Facts taxonomy and the picker only offers
    /// the ones this catalog carries.
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

    /// "en:none" means "no allergens declared" in the taxonomy. It is a
    /// statement about a product, not something a person avoids, so it never
    /// belongs in the picker.
    private static let excludedTagIDs: Set<String> = ["en:none"]

    /// Parses `allergens.json`, which maps each tag ID to a `name` object
    /// keyed by language code. A tag with no English name is skipped: there
    /// would be nothing to show the user.
    ///
    /// Walked as untyped JSON rather than decoded into a model, so one entry
    /// in an unexpected shape costs that entry and not the whole catalog.
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

    /// The taxonomy stores names lowercased. Only the first letter is raised:
    /// `.capitalized` would turn "sulphur dioxide and sulphites" into a title.
    var sentenceCased: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
