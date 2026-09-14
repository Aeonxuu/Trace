// reopening a recorded scan, shared by today and history

import Combine
import SwiftUI

// refetches the product by barcode, but shows the verdict as it was recorded
@MainActor
final class RecordReopener: ObservableObject {

    @Published var result: ScanResult?

    // which record is loading, so only the tapped row spins
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

            // a failed refetch still opens, verdict and barcode both survive
            result = ScanResult(
                verdict: record.verdict,
                product: product,
                barcode: record.barcode
            )
        }
    }
}

extension View {

    // same sheet a live scan uses
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
