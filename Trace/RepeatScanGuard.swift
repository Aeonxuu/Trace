//
//  RepeatScanGuard.swift
//  Trace
//
//  Suppresses the re-detection of a barcode that is still in frame when its
//  result sheet closes.
//

import Foundation

/// Pure decision logic, kept out of the view so it can be tested without a
/// camera. Declining a detection must never stop the scanner — see the
/// coordinator in BarcodeScannerView for why that once cost the whole session.
nonisolated struct RepeatScanGuard {

    static let window: TimeInterval = 3

    private var recentBarcode: String?
    private var ignoreUntil = Date.distantPast

    /// Whether this detection should be taken. A barcode that differs from
    /// the last one taken always goes through, which is what clears the guard
    /// early rather than waiting out the window.
    func allows(_ barcode: String, now: Date = Date()) -> Bool {
        barcode != recentBarcode || now >= ignoreUntil
    }

    mutating func took(_ barcode: String) {
        recentBarcode = barcode
    }

    /// Opens the window. Called when the result sheet closes rather than when
    /// the scan completed: the label is still in frame at that moment, and the
    /// sheet may have been up far longer than the window is wide.
    mutating func resultDismissed(now: Date = Date()) {
        ignoreUntil = now.addingTimeInterval(Self.window)
    }
}
