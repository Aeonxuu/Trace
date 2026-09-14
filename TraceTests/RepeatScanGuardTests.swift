// repeat scan guard tests

import XCTest
@testable import Trace

final class RepeatScanGuardTests: XCTestCase {

    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func seconds(_ offset: TimeInterval) -> Date {
        start.addingTimeInterval(offset)
    }

    func testFirstScanIsTaken() {
        let guardState = RepeatScanGuard()

        XCTAssertTrue(guardState.allows("4800361410816", now: start))
    }

    // the duplicate the guard exists to drop
    func testSameBarcodeIsSuppressedInsideTheWindow() {
        var guardState = RepeatScanGuard()
        guardState.took("4800361410816")
        guardState.resultDismissed(now: start)

        XCTAssertFalse(guardState.allows("4800361410816", now: seconds(0.1)))
        XCTAssertFalse(guardState.allows("4800361410816", now: seconds(2.9)))
    }

    // the case that matters most: a suppressed detection must not cost the next
    func testDifferentBarcodeIsTakenImmediatelyAfterASuppressedOne() {
        var guardState = RepeatScanGuard()
        guardState.took("4800361410816")
        guardState.resultDismissed(now: start)

        XCTAssertFalse(guardState.allows("4800361410816", now: seconds(0.1)))
        XCTAssertTrue(guardState.allows("5010026503105", now: seconds(0.2)))
    }

    func testSameBarcodeIsTakenAgainOnceTheWindowHasPassed() {
        var guardState = RepeatScanGuard()
        guardState.took("4800361410816")
        guardState.resultDismissed(now: start)

        XCTAssertTrue(guardState.allows("4800361410816", now: seconds(3.1)))
    }

    // the window opens on dismissal, so a deliberate rescan is not blocked
    func testWindowOnlyOpensOnDismissal() {
        var guardState = RepeatScanGuard()
        guardState.took("4800361410816")

        XCTAssertTrue(guardState.allows("4800361410816", now: seconds(0.1)))
    }

    // a new barcode retires the old one
    func testTakingANewBarcodeReleasesThePreviousOne() {
        var guardState = RepeatScanGuard()
        guardState.took("4800361410816")
        guardState.resultDismissed(now: start)
        guardState.took("5010026503105")

        XCTAssertTrue(guardState.allows("4800361410816", now: seconds(0.2)))
    }
}
