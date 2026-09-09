//
//  RestrictionPickerView.swift
//  Trace
//
//  Searchable multi-select over the bundled allergen catalog. Laid out from
//  the Figma frame trace-onboarding-2.
//

import SwiftUI

struct RestrictionPickerView: View {

    /// Seeded from what is already saved, so the sheet opens on the current
    /// selection and Cancel really does discard.
    @State private var selection: Set<String>
    @State private var query = ""

    private static let placeholder = "Search allergens or additives..."

    private let onDone: (Set<String>) -> Void

    @Environment(\.dismiss) private var dismiss

    init(selected: Set<String>, onDone: @escaping (Set<String>) -> Void) {
        _selection = State(initialValue: selected)
        self.onDone = onDone
    }

    private var matches: [Allergen] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return AllergenCatalog.all }

        return AllergenCatalog.all.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            searchField
            list
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 17))
                .foregroundStyle(Theme.muted)

            Spacer()

            Text("Add restrictions")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.ink)

            Spacer()

            Button("Done") {
                onDone(selection)
                dismiss()
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, Theme.sideMargin)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Theme.muted)

            // The placeholder is drawn rather than passed to TextField: the
            // built-in one uses the system placeholder color, which is far
            // fainter than muted and barely legible on surface.
            ZStack(alignment: .leading) {
                if query.isEmpty {
                    Text(Self.placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                }

                TextField("", text: $query)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.ink)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel(Self.placeholder)
            }

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                }
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
        .padding(.horizontal, Theme.sideMargin)
    }

    @ViewBuilder
    private var list: some View {
        if matches.isEmpty {
            VStack {
                Text("Nothing matches \"\(query)\"")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, Theme.sideMargin)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(matches) { allergen in
                        row(allergen)
                    }
                }
                .padding(.horizontal, Theme.sideMargin)
                .padding(.bottom, 24)
            }
        }
    }

    private func row(_ allergen: Allergen) -> some View {
        let isSelected = selection.contains(allergen.id)

        return Button {
            if isSelected {
                selection.remove(allergen.id)
            } else {
                selection.insert(allergen.id)
            }
        } label: {
            HStack {
                Text(allergen.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 12)

                checkbox(isSelected: isSelected)
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func checkbox(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(isSelected ? Theme.ink : Theme.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(isSelected ? Theme.ink : Theme.hairline, lineWidth: 1)
            }
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.surface)
                }
            }
            .frame(width: 24, height: 24)
    }
}

#Preview {
    RestrictionPickerView(selected: ["en:milk", "en:soybeans"]) { _ in }
}
