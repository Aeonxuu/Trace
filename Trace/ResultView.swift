// the verdict sheet, from the figma result frames

import SwiftUI

// one scan ready to show, product is nil when the lookup found nothing
struct ScanResult: Identifiable {
    let id = UUID()
    let verdict: Verdict
    let product: Product?
    let barcode: String
}

struct ResultView: View {

    let verdict: Verdict
    let product: Product?
    let barcode: String
    let onScanNext: () -> Void

    // stands in for a figure we cannot print, never a zero
    private static let missing = "—"

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

    // MARK: - verdict band

    private func verdictBand(height: CGFloat) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            Image(systemName: verdict.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(Theme.surface)

            VStack(spacing: 8) {
                Text(verdict.title)
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(Theme.surface)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)

                // with no product to name, the code identifies the scan
                if case .notFound = verdict {
                    Text(barcode)
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.surface.opacity(0.75))
                }
            }
        }
        .padding(.horizontal, Theme.sideMargin)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(verdict.color)
    }

    // MARK: - body

    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let product {
                productMeta(product)
            }

            whyCard

            if let product {
                ingredientsSection(product)
                nutritionCard

                if hasNoNutritionFigures {
                    Text("No nutrition data on file")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                }
            }

            Text("Always check the physical label")
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .center)

            scanNextButton
        }
        .padding(.horizontal, Theme.sideMargin)
        .padding(.vertical, 24)
    }

    private func productMeta(_ product: Product) -> some View {
        HStack(spacing: 16) {
            thumbnail(product)

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

    private func thumbnail(_ product: Product) -> some View {
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

            VStack(alignment: .leading, spacing: 6) {
                // keyed by position, two matches could share a display name
                ForEach(Array(verdict.reasonLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }

    private func ingredientsSection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.ink)

            if let text = product.ingredientText {
                highlighting(verdict.matchedItems, in: text)
                    .font(.system(size: 17))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No ingredient list on file")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.muted)
            }

            declaredAllergens(product)
        }
    }

    // declared allergens often never appear in the visible text, so they go here
    @ViewBuilder
    private func declaredAllergens(_ product: Product) -> some View {
        let names = (product.allergensTags ?? [])
            .map { AllergenCatalog.displayName(forTagID: $0).lowercased() }
            .filter { !$0.isEmpty }

        if !names.isEmpty {
            (
                Text("Declared allergens: ").foregroundColor(Theme.muted)
                    + highlighting(
                        verdict.matchedItems,
                        in: names.joined(separator: ", "),
                        base: Theme.muted
                    )
            )
            .font(.system(size: 15))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
    }

    // marks every whole-word occurrence of every matched item
    private func highlighting(
        _ terms: [String],
        in text: String,
        base: Color = Theme.ink
    ) -> Text {
        guard !terms.isEmpty else {
            return Text(text).foregroundColor(base)
        }

        // walked in document order, a range starting inside a drawn one is skipped
        let ranges = terms
            .flatMap { WordMatch.ranges(of: $0, in: text) }
            .sorted { $0.lowerBound < $1.lowerBound }

        var result = Text("")
        var cursor = text.startIndex

        for range in ranges where range.lowerBound >= cursor {
            result = result + Text(String(text[cursor..<range.lowerBound])).foregroundColor(base)
            result = result + Text(String(text[range])).bold().foregroundColor(Theme.contains)
            cursor = range.upperBound
        }

        return result + Text(String(text[cursor...])).foregroundColor(base)
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

    // MARK: - nutrition rows

    struct NutritionRow: Identifiable {
        // labels are unique down the table
        var id: String { label }
        let label: String
        let value: String
    }

    private var nutritionRows: [NutritionRow] {
        let nutriments = product?.nutriments

        return [
            NutritionRow(label: "Energy", value: kcal(product?.energyKcalPer100g)),
            NutritionRow(label: "Sugars", value: grams(nutriments?.sugars100g)),
            NutritionRow(label: "Fat", value: grams(nutriments?.fat100g)),
            NutritionRow(label: "Saturated fat", value: grams(nutriments?.saturatedFat100g)),
            NutritionRow(label: "Salt", value: grams(nutriments?.salt100g)),
            NutritionRow(label: "Protein", value: grams(nutriments?.proteins100g))
        ]
    }

    // true when no row came out with a figure behind it
    private var hasNoNutritionFigures: Bool {
        nutritionRows.allSatisfy { $0.value == Self.missing }
    }

    private func kcal(_ value: Double?) -> String {
        guard let value else { return Self.missing }
        return String(format: "%.0f kcal", value)
    }

    private func grams(_ value: Double?) -> String {
        guard let value else { return Self.missing }
        return String(format: "%.1f g", value)
    }
}

#if DEBUG
#Preview("Contains") {
    ResultView(
        verdict: .contains(matches: [VerdictMatch(name: "Milk", source: .allergens)]),
        product: DebugSample.containsMilk.product,
        barcode: DebugSample.containsMilk.barcode,
        onScanNext: {}
    )
}

#Preview("No match") {
    ResultView(
        verdict: .clear,
        product: DebugSample.noMatch.product,
        barcode: DebugSample.noMatch.barcode,
        onScanNext: {}
    )
}

#Preview("Not enough data") {
    ResultView(
        verdict: .unknown,
        product: DebugSample.notEnoughData.product,
        barcode: DebugSample.notEnoughData.barcode,
        onScanNext: {}
    )
}

#Preview("Not found") {
    ResultView(
        verdict: .notFound,
        product: nil,
        barcode: DebugSample.notFound.barcode,
        onScanNext: {}
    )
}
#endif
