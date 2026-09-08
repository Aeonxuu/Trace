//
//  ManualBarcodeView.swift
//  Trace
//
//  Types a barcode by hand and runs it through ProductService. Results go to
//  the console for now.
//

import SwiftUI

struct ManualBarcodeView: View {

    private let service = ProductService()

    @State private var barcode = ""
    @State private var isSubmitting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Enter barcode manually")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            TextField("4800361410816", text: $barcode)
                .keyboardType(.numberPad)
                .font(.body.monospacedDigit())
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Theme.surface)
                .clipShape(
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                )
                .onChange(of: barcode) { newValue in
                    let digits = newValue.filter(\.isNumber)
                    if digits != newValue { barcode = digits }
                }

            Button(action: { Task { await submit() } }) {
                ZStack {
                    Text("Look up")
                        .font(.body.weight(.semibold))
                        .opacity(isSubmitting ? 0 : 1)

                    if isSubmitting {
                        ProgressView().tint(Theme.paper)
                    }
                }
                .foregroundStyle(Theme.paper)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.ink)
                .clipShape(
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                )
            }
            .disabled(barcode.isEmpty || isSubmitting)
            .opacity(barcode.isEmpty ? 0.4 : 1)

            Text("The result prints to the Xcode console.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)

            Spacer()
        }
        .padding(.horizontal, Theme.sideMargin)
        .padding(.top, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.paper.ignoresSafeArea())
    }

    private func submit() async {
        let code = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            switch try await service.fetchProduct(barcode: code) {
            case .found(let product):
                print(summary(of: product, barcode: code))

            case .notFound:
                print("Trace: not found \(code)")

            case .failed(let error):
                print("Trace: lookup failed \(code) — \(error)")
            }
        } catch {
            print("Trace: lookup rejected \(code) — \(error)")
        }
    }

    private func summary(of product: Product, barcode: String) -> String {
        let nutriments = product.nutriments

        var lines = ["Trace: found \(barcode)"]
        lines.append("  product_name: " + (product.productName ?? "missing"))
        lines.append("  brands: " + (product.brands ?? "missing"))
        lines.append("  image_url: " + (product.imageURL ?? "missing"))
        lines.append("  energy: " + kcal(product.energyKcalPer100g))
        lines.append("  raw energy: " + rawEnergy(nutriments))
        lines.append("  sugars: " + grams(nutriments?.sugars100g))
        lines.append("  fat: " + grams(nutriments?.fat100g))
        lines.append("  saturated fat: " + grams(nutriments?.saturatedFat100g))
        lines.append("  salt: " + grams(nutriments?.salt100g))
        lines.append("  protein: " + grams(nutriments?.proteins100g))
        lines.append("  ingredient text: " + (product.ingredientText ?? "missing"))
        lines.append("  allergens_tags: \(product.allergensTags ?? [])")
        lines.append("  traces_tags: \(product.tracesTags ?? [])")
        lines.append("  traces_from_ingredients: " + (product.tracesFromIngredients ?? "missing"))
        lines.append("  ingredients_tags: \(product.ingredientsTags ?? [])")
        lines.append("  ingredients_analysis_tags: \(product.ingredientsAnalysisTags ?? [])")
        lines.append("  additives_tags: \(product.additivesTags ?? [])")
        return lines.joined(separator: "\n")
    }

    private func kcal(_ value: Double?) -> String {
        guard let value else { return "missing" }
        return String(format: "%.0f kcal/100 g", value)
    }

    private func grams(_ value: Double?) -> String {
        guard let value else { return "missing" }
        return String(format: "%.1f g", value)
    }

    /// Shows what the fallback path had to work with.
    private func rawEnergy(_ nutriments: Nutriments?) -> String {
        guard let energy = nutriments?.energy else { return "missing" }
        return "\(energy) \(nutriments?.energyUnit ?? "no unit")"
    }
}

#Preview {
    ManualBarcodeView()
}
