// suppresses re-detection of a barcode still in frame when its sheet closes

import Foundation

// pure decision logic, testable without a camera
nonisolated struct RepeatScanGuard {

    static let window: TimeInterval = 3

    private var recentBarcode: String?
    private var ignoreUntil = Date.distantPast

    // whether to take this detection, a different barcode always goes through
    func allows(_ barcode: String, now: Date = Date()) -> Bool {
        barcode != recentBarcode || now >= ignoreUntil
    }

    mutating func took(_ barcode: String) {
        recentBarcode = barcode
    }

    // opens the window on sheet dismissal, not on scan completion
    mutating func resultDismissed(now: Date = Date()) {
        ignoreUntil = now.addingTimeInterval(Self.window)
    }
}
