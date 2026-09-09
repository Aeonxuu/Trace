//
//  RecordReopening.swift
//  Trace
//
//  Reopening a recorded scan, shared by Today's last-scan card and the
//  History rows so the two behave identically.
//

import Combine
import SwiftUI

/// A record keeps only what its row draws, so the product is fetched again by
/// barcode. The verdict shown is the one from the scan rather than a fresh
/// reading: the point is to see the answer as it was given at the time.
@MainActor
final class RecordReopener: ObservableObject {

    @Published var result: ScanResult?

    /// Which record is being fetched, so a list of rows can spin only the one
    /// that was tapped.
    @Published private(set) var openingID: ScanRecord.ID?

    var isOpening: Bool { openingID != nil }

    func isOpening(_ record: ScanRecord) -> Bool { openingID == record.id }

    private let service = ProductService()

    func open(_ record: ScanRecord) {
        guard !isOpening else { return }
        openingID = record.id

        Task {
            defer { openingID = nil }

            var product: Product?
            if case .found(let fetched)? = try? await service.fetchProduct(barcode: record.barcode) {
                product = fetched
            }

            // A failed refetch still opens: the verdict and the barcode are
            // the parts that were recorded, and both survive.
            result = ScanResult(
                verdict: record.verdict,
                product: product,
                barcode: record.barcode
            )
        }
    }
}

extension View {

    /// Presents a reopened record in the same sheet a live scan uses.
    func scanResultSheet(_ result: Binding<ScanResult?>) -> some View {
        sheet(item: result) { scan in
            ResultView(
                verdict: scan.verdict,
                product: scan.product,
                barcode: scan.barcode
            ) {
                result.wrappedValue = nil
            }
            .presentationDetents([.large])
            .sheetCornerRadius(Theme.sheetRadius)
        }
    }
}
