// history tab, from the figma frame trace-history

import SwiftUI

struct HistoryView: View {

    // one list narrowed in place, not three
    private enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case flagged = "Flagged"
        case notFound = "Not found"

        var id: String { rawValue }

        func matches(_ record: ScanRecord) -> Bool {
            switch self {
            case .all:
                return true
            case .flagged:
                return record.verdict.isContains
            case .notFound:
                if case .notFound = record.verdict { return true }
                return false
            }
        }
    }

    @EnvironmentObject private var history: ScanHistoryModel
    @StateObject private var reopener = RecordReopener()

    @State private var filter = Filter.all
    @State private var query = ""

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var visible: [ScanRecord] {
        history.records.filter { record in
            guard filter.matches(record) else { return false }
            guard !trimmedQuery.isEmpty else { return true }
            return record.displayName.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("History")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, Theme.sideMargin)

            SearchField(placeholder: "Search by product name", text: $query)
                .padding(.horizontal, Theme.sideMargin)

            filterRow
            list
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.paper.ignoresSafeArea())
        .task { await history.loadIfNeeded() }
        .scanResultSheet($reopener.result)
    }

    // MARK: - filters

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases) { option in
                    filterChip(option)
                }
            }
            .padding(.horizontal, Theme.sideMargin)
        }
    }

    private func filterChip(_ option: Filter) -> some View {
        let isSelected = option == filter

        return Button {
            filter = option
        } label: {
            Text(option.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.surface : Theme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.ink : Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                .overlay {
                    if !isSelected {
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - list

    @ViewBuilder
    private var list: some View {
        if visible.isEmpty {
            emptyState
        } else {
            List {
                ForEach(visible) { record in
                    row(record)
                        // half the 10pt gap per row
                        .listRowInsets(EdgeInsets(
                            top: 5,
                            leading: Theme.sideMargin,
                            bottom: 5,
                            trailing: Theme.sideMargin
                        ))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                history.remove(record)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
        }
    }

    private func row(_ record: ScanRecord) -> some View {
        Button {
            reopener.open(record)
        } label: {
            HStack(spacing: 12) {
                thumbnail(record)

                VStack(alignment: .leading, spacing: 2) {
                    Text(record.displayName)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let brands = record.brands, !brands.isEmpty {
                            Text(brands).lineLimit(1)
                            Text("•")
                        }

                        Text(Self.relativeDate(record.scannedAt))
                            .layoutPriority(1)
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VerdictChip(verdict: record.verdict, size: .small)
            }
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func thumbnail(_ record: ScanRecord) -> some View {
        AsyncImage(url: URL(string: record.imageURL ?? "")) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            ZStack {
                Theme.paper
                Image(systemName: "photo")
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - empty

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundStyle(Theme.muted)

            Text(emptyMessage)
                .font(.system(size: 15))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Theme.sideMargin)
    }

    // says which of the three is empty: the log, the search, or the filter
    private var emptyMessage: String {
        if history.records.isEmpty {
            return "Nothing scanned yet."
        }

        if !trimmedQuery.isEmpty {
            return "No scans match \"\(trimmedQuery)\"."
        }

        switch filter {
        case .all: return "Nothing scanned yet."
        case .flagged: return "Nothing flagged yet."
        case .notFound: return "Every barcode so far was recognized."
        }
    }

    // MARK: - dates

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter
    }()

    private static func relativeDate(_ date: Date) -> String {
        let text = relativeFormatter.localizedString(for: date, relativeTo: Date())
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}

#Preview {
    HistoryView()
        .environmentObject(ScanHistoryModel())
}
