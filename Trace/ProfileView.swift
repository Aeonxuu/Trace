//
//  ProfileView.swift
//  Trace
//
//  Saved restrictions, the trace toggle, and the rows waiting on Firebase.
//

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject private var model: RestrictionsModel
    @State private var isPicking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Profile")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Theme.ink)

                avoidedCard
                traceToggleCard
                accountCard
                legalCard

                Text("Trace v1.0 · Student project")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, Theme.sideMargin)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.paper.ignoresSafeArea())
        .sheet(isPresented: $isPicking) {
            RestrictionPickerView(selected: model.selectedTagIDs) { selection in
                model.apply(selection: selection)
            }
            .presentationDetents([.large])
            .sheetCornerRadius(Theme.sheetRadius)
        }
    }

    // MARK: - Avoided ingredients

    private var avoidedCard: some View {
        card {
            Text("Avoided ingredients")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.ink)

            HStack(spacing: 8) {
                addButton

                if model.restrictions.isEmpty {
                    Text("None selected")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                }

                Spacer(minLength: 0)
            }

            if !model.restrictions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(model.restrictions.enumerated()), id: \.element.id) { index, restriction in
                        if index > 0 { divider }
                        restrictionRow(restriction)
                    }
                }
            }
        }
    }

    private var addButton: some View {
        Button {
            isPicking = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))

                Text("Add")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Theme.surface)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.ink)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func restrictionRow(_ restriction: Restriction) -> some View {
        HStack(spacing: 10) {
            Text(restriction.name)
                .font(.system(size: 17))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            SeverityControl(severity: severity(of: restriction))
                .frame(width: 130)

            Button {
                model.remove(restriction)
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(restriction.name)")
        }
        .padding(.vertical, 10)
    }

    private func severity(of restriction: Restriction) -> Binding<Severity> {
        Binding(
            get: { restriction.severity },
            set: { model.setSeverity($0, for: restriction) }
        )
    }

    // MARK: - Trace toggle

    private var traceToggleCard: some View {
        card(spacing: 0) {
            Toggle(isOn: $model.countsMayContain) {
                Text("Count may contain warnings")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            .tint(Theme.ink)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Waiting on Firebase
    //
    // Static rows. Nothing here does anything until the Firebase phase.

    private var accountCard: some View {
        card(spacing: 0) {
            staticRow("Email", trailing: .value("sarah.chen@example.com"))
            divider
            staticRow("Sign out", trailing: .chevron)
            divider
            staticRow("Delete account", trailing: .chevron)
        }
    }

    private var legalCard: some View {
        card(spacing: 0) {
            staticRow("Terms of Use", trailing: .chevron)
            divider
            staticRow("Privacy Policy", trailing: .chevron)
            divider
            staticRow("FAQs", trailing: .chevron)
        }
    }

    private enum RowTrailing {
        case chevron
        case value(String)
    }

    /// Deliberately not a Button: these rows are placeholders, and a row that
    /// depresses under a finger promises something the app cannot do yet.
    private func staticRow(_ label: String, trailing: RowTrailing) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)

            Spacer(minLength: 0)

            switch trailing {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.muted)

            case .value(let value):
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
    }

    // MARK: - Card shell

    private func card<Content: View>(
        spacing: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: spacing, content: content)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

/// Two-segment severity control.
///
/// Hand-built rather than `Picker(.segmented)`: that styles only through
/// `UISegmentedControl.appearance()`, which is process-wide, and its default
/// palette sets two near-identical greys against each other.
///
/// The track sits on paper so it reads as recessed into the white card, and
/// carries no border: nothing else on this screen is outlined.
private struct SeverityControl: View {

    @Binding var severity: Severity

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Severity.allCases, id: \.self) { option in
                segment(option)
            }
        }
        .padding(2)
        .frame(height: 30)
        .background(
            Theme.paper,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func segment(_ option: Severity) -> some View {
        let isSelected = option == severity

        return Button {
            severity = option
        } label: {
            Text(option.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.surface : Theme.muted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Theme.ink)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    ProfileView()
        .environmentObject(RestrictionsModel())
}
