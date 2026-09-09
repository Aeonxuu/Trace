//
//  Product.swift
//  Trace
//
//  Open Food Facts response models. Only the fields CLAUDE.md names are
//  modeled, and every one of them is optional.
//

import Foundation

/// The response envelope. `status` decides found vs. not found, not the
/// HTTP status code.
nonisolated struct ProductResponse: Decodable {
    let status: Int?
    let product: Product?
}

nonisolated struct Product: Decodable {

    let productName: String?
    let brands: String?
    let imageURL: String?
    let allergensTags: [String]?
    let tracesTags: [String]?
    let tracesFromIngredients: String?
    let ingredientsTags: [String]?
    let ingredientsAnalysisTags: [String]?
    let additivesTags: [String]?
    let ingredientsTextEn: String?
    let ingredientsText: String?
    let nutriments: Nutriments?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case imageURL = "image_url"
        case allergensTags = "allergens_tags"
        case tracesTags = "traces_tags"
        case tracesFromIngredients = "traces_from_ingredients"
        case ingredientsTags = "ingredients_tags"
        case ingredientsAnalysisTags = "ingredients_analysis_tags"
        case additivesTags = "additives_tags"
        case ingredientsTextEn = "ingredients_text_en"
        case ingredientsText = "ingredients_text"
        case nutriments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        productName = container.lenient(String.self, .productName)
        brands = container.lenient(String.self, .brands)
        imageURL = container.lenient(String.self, .imageURL)
        allergensTags = container.lenient([String].self, .allergensTags)
        tracesTags = container.lenient([String].self, .tracesTags)
        tracesFromIngredients = container.lenient(String.self, .tracesFromIngredients)
        ingredientsTags = container.lenient([String].self, .ingredientsTags)
        ingredientsAnalysisTags = container.lenient([String].self, .ingredientsAnalysisTags)
        additivesTags = container.lenient([String].self, .additivesTags)
        ingredientsTextEn = container.lenient(String.self, .ingredientsTextEn)
        ingredientsText = container.lenient(String.self, .ingredientsText)
        nutriments = container.lenient(Nutriments.self, .nutriments)
    }

    /// English first, then the default language, then missing. An empty
    /// string counts as missing: Open Food Facts sends "" for absent text.
    var ingredientText: String? {
        ingredientsTextEn?.nonEmpty ?? ingredientsText?.nonEmpty
    }

    /// Energy per 100 g in kilocalories.
    ///
    /// `energy-kcal_100g` is already in kcal. Falling back to the plain
    /// `energy` field means reading `energy_unit` first, since that value can
    /// be either unit. A missing unit is treated as kJ, which is what Open
    /// Food Facts sends by default.
    var energyKcalPer100g: Double? {
        if let kcal = nutriments?.energyKcal100g {
            return kcal
        }

        guard let energy = nutriments?.energy else { return nil }

        if nutriments?.energyUnit?.lowercased() == "kcal" {
            return energy
        }
        return energy / 4.184
    }
}

nonisolated struct Nutriments: Decodable {

    let energyKcal100g: Double?

    /// Paired with `energyUnit`. Read neither one without the other.
    let energy: Double?
    let energyUnit: String?

    let sugars100g: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let salt100g: Double?
    let proteins100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case energy
        case energyUnit = "energy_unit"
        case sugars100g = "sugars_100g"
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case salt100g = "salt_100g"
        case proteins100g = "proteins_100g"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        energyKcal100g = container.lenient(Double.self, .energyKcal100g)
        energy = container.lenient(Double.self, .energy)
        energyUnit = container.lenient(String.self, .energyUnit)
        sugars100g = container.lenient(Double.self, .sugars100g)
        fat100g = container.lenient(Double.self, .fat100g)
        saturatedFat100g = container.lenient(Double.self, .saturatedFat100g)
        salt100g = container.lenient(Double.self, .salt100g)
        proteins100g = container.lenient(Double.self, .proteins100g)
    }
}

private extension KeyedDecodingContainer {

    /// Decodes a key, yielding nil when it is absent, null, or the wrong
    /// type. Open Food Facts is crowd-sourced, so one malformed field must
    /// not cost us the whole product.
    nonisolated func lenient<T: Decodable>(_ type: T.Type, _ key: Key) -> T? {
        try? decodeIfPresent(type, forKey: key)
    }
}

private extension String {
    nonisolated var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
