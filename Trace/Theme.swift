//
//  Theme.swift
//  Trace
//
//  Design tokens. The single source of truth for color and metrics.
//

import SwiftUI

enum Theme {

    // MARK: - Surfaces and text

    static let ink = Color(hex: 0x101A2E)
    static let paper = Color(hex: 0xF7F8FA)
    static let surface = Color(hex: 0xFFFFFF)
    static let muted = Color(hex: 0x6B7689)

    /// Row dividers inside cards. Taken from the Figma result screen; not one
    /// of the named tokens in CLAUDE.md.
    static let hairline = Color(hex: 0xE5E7EB)

    /// Ink lifted just enough to read as a well on an ink surface, for the
    /// scan card's icon. From the Figma Today frame; also not a named token.
    static let inkWell = Color(hex: 0x1D2A44)

    // MARK: - Verdicts
    //
    // These appear only on verdicts. Never on buttons or other UI.

    static let contains = Color(hex: 0xC81E3A)
    static let clear = Color(hex: 0x0E7C5A)
    static let unknown = Color(hex: 0xE5952B)

    // MARK: - Metrics

    static let cardRadius: CGFloat = 14
    static let sheetRadius: CGFloat = 24
    static let sideMargin: CGFloat = 20
}

private extension Color {

    /// Builds a color from a 24-bit RGB literal, so the tokens above read
    /// the same here as they do in the design file.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
