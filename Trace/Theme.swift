// design tokens, the single source of truth for color and metrics

import SwiftUI

enum Theme {

    // MARK: - surfaces and text

    static let ink = Color(hex: 0x101A2E)
    static let paper = Color(hex: 0xF7F8FA)
    static let surface = Color(hex: 0xFFFFFF)
    static let muted = Color(hex: 0x6B7689)

    // row dividers inside cards, not a named token in CLAUDE.md
    static let hairline = Color(hex: 0xE5E7EB)

    // ink lifted for the scan card's icon well, also not a named token
    static let inkWell = Color(hex: 0x1D2A44)

    // MARK: - verdicts
    //
    // only on verdicts, never on buttons or other ui

    static let contains = Color(hex: 0xC81E3A)
    static let clear = Color(hex: 0x0E7C5A)
    static let unknown = Color(hex: 0xE5952B)

    // MARK: - metrics

    static let cardRadius: CGFloat = 14
    static let sheetRadius: CGFloat = 24
    static let sideMargin: CGFloat = 20
}

private extension Color {

    // builds a color from a 24-bit rgb literal
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
