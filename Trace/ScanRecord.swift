// one completed scan, kept for today and history

import Foundation

// only what the summary rows draw, reopening refetches by barcode
struct ScanRecord: Identifiable, Codable, Hashable {

    let id: UUID
    let barcode: String
    let productName: String?
    let brands: String?
    let imageURL: String?
    let verdict: Verdict
    let scannedAt: Date

    init(
        id: UUID = UUID(),
        barcode: String,
        productName: String?,
        brands: String?,
        imageURL: String?,
        verdict: Verdict,
        scannedAt: Date = Date()
    ) {
        self.id = id
        self.barcode = barcode
        self.productName = productName
        self.brands = brands
        self.imageURL = imageURL
        self.verdict = verdict
        self.scannedAt = scannedAt
    }

    // shown when open food facts had no name
    var displayName: String {
        productName ?? "Unknown product"
    }
}
