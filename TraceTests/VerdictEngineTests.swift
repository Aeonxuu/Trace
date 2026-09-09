//
//  VerdictEngineTests.swift
//  TraceTests
//

import XCTest
@testable import Trace

final class VerdictEngineTests: XCTestCase {

    // MARK: - Fixtures

    private let milk = Restriction(tagID: "en:milk", name: "Milk", severity: .avoid)
    private let severeMilk = Restriction(tagID: "en:milk", name: "Milk", severity: .severe)
    private let peanuts = Restriction(tagID: "en:peanuts", name: "Peanuts", severity: .avoid)

    /// Product has no memberwise initializer by design — every field is
    /// decoded — so fixtures come in the same way real products do.
    private func product(_ json: String) throws -> Product {
        try JSONDecoder().decode(Product.self, from: Data(json.utf8))
    }

    // MARK: - Tier 1: declared allergens

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

        guard case .contains(let matched, let source) = verdict else {
            return XCTFail("expected contains, got \(verdict)")
        }
        XCTAssertEqual(matched, "Milk")
        XCTAssertEqual(source, .allergens)
    }

    /// Tier 1 outranks tier 3, so the same item present in both is reported as
    /// the declared allergen it is.
    func testDeclaredAllergenOutranksIngredientTags() throws {
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

        guard case .contains(_, let source) = verdict else {
            return XCTFail("expected contains, got \(verdict)")
        }
        XCTAssertEqual(source, .allergens)
    }

    // MARK: - Tier 2: traces

    /// An avoid-level restriction does not want to hear about traces while the
    /// global toggle is off, so the product reads clear on the strength of its
    /// ingredient list.
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

    /// Severity carries the trace on its own: a severe restriction is matched
    /// even with the global toggle off.
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

        guard case .contains(let matched, let source) = verdict else {
            return XCTFail("expected contains, got \(verdict)")
        }
        XCTAssertEqual(matched, "Milk")
        XCTAssertEqual(source, .traces)
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

        guard case .contains(let matched, let source) = verdict else {
            return XCTFail("expected contains, got \(verdict)")
        }
        XCTAssertEqual(matched, "Milk")
        XCTAssertEqual(source, .traces)
    }

    /// `traces_from_ingredients` is free text rather than a tag list, and is
    /// read alongside `traces_tags`.
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

        guard case .contains(let matched, let source) = verdict else {
            return XCTFail("expected contains, got \(verdict)")
        }
        XCTAssertEqual(matched, "Peanuts")
        XCTAssertEqual(source, .traces)
    }

    // MARK: - Clear

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

    /// A near miss must not match: whole tag values are compared, so milk does
    /// not turn up inside coconut milk.
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

    // MARK: - Unknown

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

    /// Empty arrays and an empty ingredient string are missing data, not
    /// evidence of absence.
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

    /// Additives alone are not one of the three fields CLAUDE.md names, so
    /// they cannot lift a product out of unknown.
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
