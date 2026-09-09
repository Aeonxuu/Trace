//
//  DebugSamples.swift
//  Trace
//
//  Temporary. Stand-in scans for checking the Result screen without a
//  barcode in front of the camera. Delete once the verdict engine can
//  produce all four states from real lookups.
//

import Foundation

#if DEBUG

/// One canned scan, named for the state it demonstrates.
struct DebugSample: Identifiable {

    var id: String { name }

    let name: String
    let verdict: Verdict
    let product: Product?
    let barcode: String

    var scan: ScanResult {
        ScanResult(verdict: verdict, product: product, barcode: barcode)
    }

    static let all = [containsMilk, containsTwo, noMatch, notEnoughData, notFound]

    // MARK: - The four states

    static let containsMilk = DebugSample(
        name: "Contains milk",
        verdict: .contains(matches: [VerdictMatch(name: "Milk", source: .allergens)]),
        product: decoded("""
        {
          "product_name": "Dark Chocolate Bar",
          "brands": "Maison Cacao",
          "ingredients_text_en": "Cocoa mass, sugar, cocoa butter, emulsifier \
        (soy lecithin), whole milk powder, natural vanilla flavoring.",
          "allergens_tags": ["en:milk"],
          "nutriments": {
            "energy-kcal_100g": 540, "sugars_100g": 42.5, "fat_100g": 34.1,
            "saturated-fat_100g": 20.4, "salt_100g": 0.1, "proteins_100g": 6.8
          }
        }
        """),
        barcode: "4800361410816"
    )

    /// Two matches at different tiers, for checking the title's list form and
    /// the one-line-per-match Why card.
    static let containsTwo = DebugSample(
        name: "Contains milk and peanuts",
        verdict: .contains(matches: [
            VerdictMatch(name: "Milk", source: .allergens),
            VerdictMatch(name: "Peanuts", source: .traces)
        ]),
        product: decoded("""
        {
          "product_name": "Peanut Butter Cups",
          "brands": "Choco Treats",
          "ingredients_text_en": "Milk chocolate (sugar, cocoa butter, milk), \
        peanuts, salt.",
          "allergens_tags": ["en:milk"],
          "traces_tags": ["en:peanuts"],
          "nutriments": {
            "energy-kcal_100g": 515, "sugars_100g": 48.0, "fat_100g": 29.0,
            "saturated-fat_100g": 11.0, "salt_100g": 0.4, "proteins_100g": 9.0
          }
        }
        """),
        barcode: "0034000002405"
    )

    /// Salt is a measured 0.0 here on purpose: a real zero must still read as
    /// a zero, which is the whole reason missing values get an em dash.
    static let noMatch = DebugSample(
        name: "No match found",
        verdict: .clear,
        product: decoded("""
        {
          "product_name": "Organic Rolled Oats",
          "brands": "Harvest Fields",
          "ingredients_text_en": "100% organic whole grain rolled oats.",
          "allergens_tags": [],
          "nutriments": {
            "energy-kcal_100g": 366, "sugars_100g": 1.1, "fat_100g": 6.9,
            "saturated-fat_100g": 1.2, "salt_100g": 0.0, "proteins_100g": 13.2
          }
        }
        """),
        barcode: "5010026503105"
    )

    /// No ingredient text, no allergen tags, no nutriments — the product Open
    /// Food Facts knows the name of and nothing else.
    static let notEnoughData = DebugSample(
        name: "Not enough data",
        verdict: .unknown,
        product: decoded("""
        {
          "product_name": "Sparkling Mineral Water",
          "brands": "Alpina Springs"
        }
        """),
        barcode: "8000060010027"
    )

    static let notFound = DebugSample(
        name: "No product found",
        verdict: .notFound,
        product: nil,
        barcode: "0123456789012"
    )

    private static func decoded(_ json: String) -> Product? {
        try? JSONDecoder().decode(Product.self, from: Data(json.utf8))
    }
}

#endif
