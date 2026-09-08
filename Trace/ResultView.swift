//
//  ResultView.swift
//  Trace
//
//  The verdict sheet. Laid out from the Figma frame trace-contains-milk.
//

import SwiftUI

/// One scan, ready to show.
struct ScanResult: Identifiable {
    let id = UUID()
    let verdict: Verdict
    let product: Product
}

struct ResultView: View {

    let verdict: Verdict
    let product: Product
    let onScanNext: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    verdictBand(height: proxy.size.height * 0.30)
                    contentBody
                }
            }
            .background(Theme.paper)
        }
    }

    // MARK: - Verdict band

    private func verdictBand(height: CGFloat) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            Image(systemName: verdict.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(Theme.surface)

            Text(verdict.title)
                .font(.system(size: 44, weight: .heavy))
                .foregroundStyle(Theme.surface)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, Theme.sideMargin)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(verdict.color)
    }

    // MARK: - Body

    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 20) {
            productMeta
            whyCard
            ingredientsSection
            nutritionCard

            Text("Always check the physical label")
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .center)

            scanNextButton
        }
        .padding(.horizontal, Theme.sideMargin)
        .padding(.vertical, 24)
    }

    private var productMeta: some View {
        HStack(spacing: 16) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(product.productName ?? "Unknown product")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Theme.ink)

                if let brands = product.brands, !brands.isEmpty {
                    Text(brands)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var thumbnail: some View {
        AsyncImage(url: URL(string: product.imageURL ?? "")) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            ZStack {
                Theme.surface
                Image(systemName: "photo")
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    private var whyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.ink)

            Text(verdict.reason)
                .font(.system(size: 17))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.ink)

            if let text = product.ingredientText {
                highlighting(verdict.matchedItem, in: text)
                    .font(.system(size: 17))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No ingredient list available.")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.muted)
            }
        }
    }

    /// Marks each whole-word occurrence of the matched item.
    private func highlighting(_ term: String?, in text: String) -> Text {
        guard let term else {
            return Text(text).foregroundColor(Theme.ink)
        }

        var result = Text("")
        var cursor = text.startIndex

        for range in WordMatch.ranges(of: term, in: text) {
            result = result + Text(String(text[cursor..<range.lowerBound])).foregroundColor(Theme.ink)
            result = result + Text(String(text[range])).bold().foregroundColor(Theme.contains)
            cursor = range.upperBound
        }

        return result + Text(String(text[cursor...])).foregroundColor(Theme.ink)
    }

    private var nutritionCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nutrition")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Theme.ink)

                Spacer()

                Text("per 100 g")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.bottom, 8)

            ForEach(nutritionRows) { row in
                nutritionRow(row)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    private func nutritionRow(_ row: NutritionRow) -> some View {
        HStack {
            Text(row.label)
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink)

            Spacer()

            Text(row.value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
        }
    }

    private var scanNextButton: some View {
        Button(action: onScanNext) {
            Text("Scan next")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.surface)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        }
    }

    // MARK: - Nutrition rows

    struct NutritionRow: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    private var nutritionRows: [NutritionRow] {
        let nutriments = product.nutriments

        return [
            NutritionRow(label: "Energy", value: kcal(product.energyKcalPer100g)),
            NutritionRow(label: "Sugars", value: grams(nutriments?.sugars100g)),
            NutritionRow(label: "Fat", value: grams(nutriments?.fat100g)),
            NutritionRow(label: "Saturated fat", value: grams(nutriments?.saturatedFat100g)),
            NutritionRow(label: "Salt", value: grams(nutriments?.salt100g)),
            NutritionRow(label: "Protein", value: grams(nutriments?.proteins100g))
        ]
    }

    private func kcal(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.0f kcal", value)
    }

    private func grams(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f g", value)
    }
}

#if DEBUG
extension Product {

    /// Stands in for a lookup in previews.
    static var sample: Product? {
        let json = """
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
        """
        return try? JSONDecoder().decode(Product.self, from: Data(json.utf8))
    }
}
#endif

#Preview {
    if let product = Product.sample {
        ResultView(verdict: .contains("milk"), product: product, onScanNext: {})
    }
}
