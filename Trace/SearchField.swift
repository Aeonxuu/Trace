//
//  SearchField.swift
//  Trace
//
//  Laid out from the Figma search field on trace-onboarding-2.
//

import SwiftUI

struct SearchField: View {

    let placeholder: String

    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Theme.muted)

            // The placeholder is drawn rather than passed to TextField: the
            // built-in one uses the system placeholder color, which is far
            // fainter than muted and barely legible on surface.
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                }

                TextField("", text: $text)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.ink)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel(placeholder)
            }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }
}
