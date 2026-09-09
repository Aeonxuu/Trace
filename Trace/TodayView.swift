//
//  TodayView.swift
//  Trace
//
//  Laid out from the Figma frame trace-today.
//

import SwiftUI

struct TodayView: View {

    /// Switches the shell to the Scan tab. Owned by RootView, since the tab
    /// selection is not this screen's to keep.
    let onScanTapped: () -> Void

    @EnvironmentObject private var history: ScanHistoryModel

    @State private var reopened: ScanResult?
    @State private var isReopening = false

    private let service = ProductService()

    var body: some View {
        screen
            .debugVerdictMenu()
    }

    private var screen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                greeting
                scanCard

                if let last = history.lastScan {
                    lastScanSection(last)
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
        .sheet(item: $reopened) { scan in
            ResultView(
                verdict: scan.verdict,
                product: scan.product,
                barcode: scan.barcode
            ) {
                reopened = nil
            }
            .presentationDetents([.large])
            .sheetCornerRadius(Theme.sheetRadius)
        }
    }

    // MARK: - Greeting

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
        history.lastScan == nil
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

    // MARK: - Scan card

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

    // MARK: - Last scan

    private func lastScanSection(_ record: ScanRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last scan")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.ink)

            Button {
                reopen(record)
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

                    if isReopening {
                        ProgressView().tint(Theme.muted)
                    } else {
                        verdictChip(record.verdict)
                    }
                }
                .padding(16)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isReopening)
        }
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

    /// The one place on this screen a verdict color is allowed.
    private func verdictChip(_ verdict: Verdict) -> some View {
        Text(verdict.chipLabel)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(verdict.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(verdict.color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    /// The record keeps only what the row draws, so the product is fetched
    /// again to fill the sheet. The verdict shown is the one from the scan,
    /// not a fresh reading.
    private func reopen(_ record: ScanRecord) {
        guard !isReopening else { return }
        isReopening = true

        Task {
            defer { isReopening = false }

            var product: Product?
            if case .found(let fetched)? = try? await service.fetchProduct(barcode: record.barcode) {
                product = fetched
            }

            reopened = ScanResult(
                verdict: record.verdict,
                product: product,
                barcode: record.barcode
            )
        }
    }

    // MARK: - Stats

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
