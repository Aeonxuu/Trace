//
//  WordMatch.swift
//  Trace
//
//  Whole-word search, for marking a matched item inside ingredient text.
//

import Foundation

enum WordMatch {

    /// Every range where `term` appears in `text` as a whole word,
    /// case-insensitively.
    ///
    /// A word ends at anything that is not a letter or a digit, so a term
    /// still matches at the start or end of the text and next to punctuation,
    /// while "milk" no longer matches inside "Buttermilk".
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
