// whole-word search, for marking a match inside ingredient text

import Foundation

enum WordMatch {

    // every whole-word range of term in text, so milk does not match buttermilk
    static func ranges(of term: String, in text: String) -> [Range<String.Index>] {
        guard !term.isEmpty, !text.isEmpty else { return [] }

        let escaped = NSRegularExpression.escapedPattern(for: term)
        let pattern = "(?<![\\p{L}\\p{N}])" + escaped + "(?![\\p{L}\\p{N}])"

        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return []
        }

        let whole = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: whole).compactMap { Range($0.range, in: text) }
    }
}
