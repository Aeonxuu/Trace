// today tab, from the figma frame trace-today

import SwiftUI

struct TodayView: View {

    // switches the shell to the scan tab, owned by RootView
    let onScanTapped: () -> Void

    @EnvironmentObject private var history: ScanHistoryModel

    @StateObject private var reopener = RecordReopener()

    private static let recentCount = 3

    private var recentScans: [ScanRecord] {
        history.recent(Self.recentCount)
    }

    var body: some View {
        screen
            .debugVerdictMenu()
    }

    private var screen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                greeting
                scanCard

                if !recentScans.isEmpty {
                    recentScansSection
                    statsSection
                }
            }
            .padding(.horizontal, Theme.sideMargin)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.paper.ignoresSafeArea())
        .task { await history.loadIfNeeded() }
        .scanResultSheet($reopener.result)
    }

    // MARK: - greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.timeOfDayGreeting)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Theme.ink)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var subtitle: String {
        recentScans.isEmpty
            ? "Nothing scanned yet. Start with your first barcode."
            : "Scan a product to check your active avoidances."
    }

    private static var timeOfDayGreeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - scan card

    private var scanCard: some View {
        Button(action: onScanTapped) {
            VStack(spacing: 20) {
                ZStack {
                    Circle().fill(Theme.inkWell)

                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 36, weight: .regular))
                        .foregroundStyle(Theme.surface)
                }
                .frame(width: 80, height: 80)

                VStack(spacing: 4) {
                    Text("Tap to Scan Barcode")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(Theme.surface)

                    Text("Detect allergens instantly")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.surface.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(Theme.ink)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - recent scans

    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent scans")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.ink)

            VStack(spacing: 10) {
                ForEach(recentScans) { record in
                    recentRow(record)
                }
            }
        }
    }

    private func recentRow(_ record: ScanRecord) -> some View {
        Button {
            reopener.open(record)
        } label: {
            HStack(spacing: 12) {
                thumbnail(record)

                VStack(alignment: .leading, spacing: 2) {
                    Text(record.displayName)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)

                    Text(record.brands ?? record.barcode)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if reopener.isOpening(record) {
                    ProgressView().tint(Theme.muted)
                } else {
                    VerdictChip(verdict: record.verdict)
                }
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(reopener.isOpening)
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

    // MARK: - stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.ink)

            HStack(spacing: 16) {
                statCard(history.scansThisWeek, "Scans this week")
                statCard(history.itemsFlaggedThisWeek, "Items flagged")
            }
        }
    }

    private func statCard(_ value: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Theme.ink)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

#Preview {
    TodayView(onScanTapped: {})
        .environmentObject(ScanHistoryModel())
}
