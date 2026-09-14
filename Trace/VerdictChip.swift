// the verdict, small enough for a summary row

import SwiftUI

// outside the result band, the only place a verdict color appears
struct VerdictChip: View {

    enum Size {
        // history rows
        case small
        // today's last-scan card
        case regular

        var text: CGFloat { self == .small ? 12 : 13 }
        var horizontalPadding: CGFloat { self == .small ? 8 : 10 }
        var radius: CGFloat { self == .small ? 6 : 8 }
    }

    let verdict: Verdict
    var size: Size = .regular

    var body: some View {
        Text(verdict.chipLabel)
            .font(.system(size: size.text, weight: .bold))
            .foregroundStyle(verdict.color)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, 4)
            // derived from the verdict, so notFound gets a chip too
            .background(verdict.color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: size.radius, style: .continuous))
    }
}
