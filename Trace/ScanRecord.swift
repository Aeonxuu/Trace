//
//  ScanRecord.swift
//  Trace
//
//  One completed scan, kept so Today and History have something to read.
//

import Foundation

/// Deliberately not a whole `Product`: this is what the summary rows need to
/// draw, and nothing more. Reopening a record refetches the product by
/// barcode rather than trusting a copy that may be months stale.
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

    /// What the summary row shows when Open Food Facts had no name for it.
    var displayName: String {
        productName ?? "Unknown product"
    }
}
