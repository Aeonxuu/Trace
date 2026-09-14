// verdict engine tests

import XCTest
@testable import Trace

// reaches into the verdict without a guard case at every call site
private extension Verdict {
    var matches: [VerdictMatch]? {
        if case .contains(let matches) = self { return matches }
        return nil
    }
}

final class VerdictEngineTests: XCTestCase {

    // MARK: - fixtures

    private let milk = Restriction(tagID: "en:milk", name: "Milk", severity: .avoid)
    private let severeMilk = Restriction(tagID: "en:milk", name: "Milk", severity: .severe)
    private let peanuts = Restriction(tagID: "en:peanuts", name: "Peanuts", severity: .avoid)

    // fixtures decode the way real products do, Product has no memberwise init
    private func product(_ json: String) throws -> Product {
        try JSONDecoder().decode(Product.self, from: Data(json.utf8))
    }

    // MARK: - tier 1: declared allergens

    func testDeclaredAllergenMatches() throws {
        let bar = try product("""
        {
          "product_name": "Dark Chocolate Bar",
          "ingredients_text_en": "Cocoa mass, sugar, whole milk powder.",
          "allergens_tags": ["en:milk"]
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: bar,
            restrictions: [milk],
            countTraces: false
        )

        XCTAssertEqual(verdict.matches?.map(\.name), ["Milk"])
        XCTAssertEqual(verdict.matches?.map(\.source), [.allergens])
    }

    // present in two tiers, listed once, attributed to the earlier
    func testRestrictionInTwoTiersIsReportedOnce() throws {
        let bar = try product("""
        {
          "allergens_tags": ["en:milk"],
          "ingredients_tags": ["en:milk", "en:sugar"]
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: bar,
            restrictions: [milk],
            countTraces: false
        )

        XCTAssertEqual(verdict.matches?.map(\.name), ["Milk"])
        XCTAssertEqual(verdict.matches?.map(\.source), [.allergens])
    }

    // MARK: - tier 2: traces

    // avoid-level plus toggle off means traces are ignored
    func testTraceIgnoredWhenCountTracesOffAndSeverityIsAvoid() throws {
        let oats = try product("""
        {
          "ingredients_text_en": "Whole grain oats.",
          "allergens_tags": [],
          "ingredients_tags": ["en:oats"],
          "traces_tags": ["en:milk"]
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: oats,
            restrictions: [milk],
            countTraces: false
        )

        guard case .clear = verdict else {
            return XCTFail("expected clear, got \(verdict)")
        }
    }

    // severity carries the trace on its own
    func testTraceMatchesOnSeverityWhenCountTracesOff() throws {
        let oats = try product("""
        {
          "ingredients_text_en": "Whole grain oats.",
          "ingredients_tags": ["en:oats"],
          "traces_tags": ["en:milk"]
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: oats,
            restrictions: [severeMilk],
            countTraces: false
        )

        XCTAssertEqual(verdict.matches?.map(\.name), ["Milk"])
        XCTAssertEqual(verdict.matches?.map(\.source), [.traces])
    }

    func testTraceMatchesWhenCountTracesOn() throws {
        let oats = try product("""
        {
          "ingredients_text_en": "Whole grain oats.",
          "ingredients_tags": ["en:oats"],
          "traces_tags": ["en:milk"]
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: oats,
            restrictions: [milk],
            countTraces: true
        )

        XCTAssertEqual(verdict.matches?.map(\.name), ["Milk"])
        XCTAssertEqual(verdict.matches?.map(\.source), [.traces])
    }

    // traces_from_ingredients is free text, read alongside traces_tags
    func testTraceFromIngredientsTextMatches() throws {
        let biscuits = try product("""
        {
          "ingredients_text_en": "Flour, sugar, butter.",
          "ingredients_tags": ["en:flour"],
          "traces_from_ingredients": "en:peanuts,en:sesame-seeds"
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: biscuits,
            restrictions: [peanuts],
            countTraces: true
        )

        XCTAssertEqual(verdict.matches?.map(\.name), ["Peanuts"])
        XCTAssertEqual(verdict.matches?.map(\.source), [.traces])
    }

    // MARK: - several matches

    // two restrictions caught at different tiers both belong on the verdict
    func testTwoMatchesAreBothReported() throws {
        let cups = try product("""
        {
          "product_name": "Peanut Butter Cups",
          "ingredients_text_en": "Milk chocolate, peanuts, salt.",
          "allergens_tags": ["en:milk"],
          "ingredients_tags": ["en:peanuts", "en:sugar"]
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: cups,
            restrictions: [milk, peanuts],
            countTraces: false
        )

        XCTAssertEqual(verdict.matches?.map(\.name), ["Milk", "Peanuts"])
        XCTAssertEqual(verdict.matches?.map(\.source), [.allergens, .ingredients])
    }

    // tier order, not saved order
    func testMatchesAreOrderedByTierNotBySavedOrder() throws {
        let cups = try product("""
        {
          "ingredients_text_en": "Milk chocolate, peanuts.",
          "allergens_tags": ["en:peanuts"],
          "ingredients_tags": ["en:milk"]
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: cups,
            restrictions: [milk, peanuts],
            countTraces: false
        )

        XCTAssertEqual(verdict.matches?.map(\.name), ["Peanuts", "Milk"])
        XCTAssertEqual(verdict.matches?.map(\.source), [.allergens, .ingredients])
    }

    // however many matched, the chip says the same thing
    func testChipLabelIsFlaggedForAnyNumberOfMatches() {
        let one = Verdict.contains(matches: [VerdictMatch(name: "Milk", source: .allergens)])
        let two = Verdict.contains(matches: [
            VerdictMatch(name: "Milk", source: .allergens),
            VerdictMatch(name: "Peanuts", source: .ingredients)
        ])

        XCTAssertEqual(one.chipLabel, "Flagged")
        XCTAssertEqual(two.chipLabel, "Flagged")
    }

    // MARK: - titles and reasons

    func testTitleListsMatches() {
        func title(_ names: [String]) -> String {
            Verdict.contains(
                matches: names.map { VerdictMatch(name: $0, source: .allergens) }
            ).title
        }

        XCTAssertEqual(title(["Milk"]), "Contains milk")
        XCTAssertEqual(title(["Milk", "Peanuts"]), "Contains milk and peanuts")
        XCTAssertEqual(title(["Milk", "Peanuts", "Soy"]), "Contains milk, peanuts and soy")
    }

    // one line per match, each naming its own source
    func testReasonLinesNameEachSource() {
        let verdict = Verdict.contains(matches: [
            VerdictMatch(name: "Milk", source: .allergens),
            VerdictMatch(name: "Peanuts", source: .traces)
        ])

        XCTAssertEqual(verdict.reasonLines, [
            "Milk is listed in this product's declared allergens.",
            "Peanuts is listed in this product's may-contain traces."
        ])
    }

    // MARK: - clear

    func testCleanProductIsClear() throws {
        let oats = try product("""
        {
          "product_name": "Organic Rolled Oats",
          "ingredients_text_en": "100% organic whole grain rolled oats.",
          "allergens_tags": [],
          "ingredients_tags": ["en:oats"]
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: oats,
            restrictions: [milk, peanuts],
            countTraces: true
        )

        guard case .clear = verdict else {
            return XCTFail("expected clear, got \(verdict)")
        }
    }

    // a near miss must not match
    func testSimilarTagDoesNotMatch() throws {
        let drink = try product("""
        {
          "ingredients_text_en": "Water, coconut extract.",
          "ingredients_tags": ["en:coconut-milk", "en:water"]
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: drink,
            restrictions: [milk],
            countTraces: true
        )

        guard case .clear = verdict else {
            return XCTFail("expected clear, got \(verdict)")
        }
    }

    // MARK: - unknown

    func testNoIngredientDataIsUnknown() throws {
        let water = try product("""
        {
          "product_name": "Sparkling Mineral Water",
          "brands": "Alpina Springs"
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: water,
            restrictions: [milk],
            countTraces: true
        )

        guard case .unknown = verdict else {
            return XCTFail("expected unknown, got \(verdict)")
        }
    }

    // empty fields are missing data, not evidence of absence
    func testEmptyFieldsAreUnknownRatherThanClear() throws {
        let water = try product("""
        {
          "product_name": "Sparkling Mineral Water",
          "ingredients_text_en": "",
          "ingredients_text": "",
          "allergens_tags": [],
          "ingredients_tags": []
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: water,
            restrictions: [milk],
            countTraces: true
        )

        guard case .unknown = verdict else {
            return XCTFail("expected unknown, got \(verdict)")
        }
    }

    // additives alone cannot lift a product out of unknown
    func testAdditivesAloneDoNotMakeAProductCheckable() throws {
        let soda = try product("""
        {
          "product_name": "Cola",
          "additives_tags": ["en:e150d"]
        }
        """)

        let verdict = VerdictEngine.evaluate(
            product: soda,
            restrictions: [milk],
            countTraces: true
        )

        guard case .unknown = verdict else {
            return XCTFail("expected unknown, got \(verdict)")
        }
    }
}
