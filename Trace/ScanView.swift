//
//  ScanView.swift
//  Trace
//

import SwiftUI

struct ScanView: View {

    private let service = ProductService()

    @State private var availability = ScannerAvailability.current()
    @State private var isEnteringManually = false
    @State private var isLookingUp = false
    @State private var result: ScanResult?

    /// The camera runs only when nothing is in front of it.
    private var isScannerPaused: Bool {
        isLookingUp || result != nil || isEnteringManually
    }

    var body: some View {
        VStack(spacing: 16) {
            if let message = availability.message {
                unavailable(message)
            } else {
                scanner

                Text("Point at the barcode")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }

            Button("Enter barcode manually") {
                isEnteringManually = true
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, Theme.sideMargin)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper.ignoresSafeArea())
        .onAppear { availability = .current() }
        .sheet(isPresented: $isEnteringManually) {
            ManualBarcodeView()
                .presentationDetents([.medium])
                .sheetCornerRadius(Theme.sheetRadius)
        }
        .sheet(item: $result) { scan in
            ResultView(verdict: scan.verdict, product: scan.product) {
                result = nil
            }
            .presentationDetents([.large])
            .sheetCornerRadius(Theme.sheetRadius)
        }
    }

    private var scanner: some View {
        BarcodeScannerView(isPaused: isScannerPaused, onScan: handleScan)
            .clipShape(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            )
            .overlay {
                if isLookingUp {
                    ZStack {
                        Color.black.opacity(0.4)
                        ProgressView().tint(Theme.surface)
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    )
                }
            }
    }

    private func unavailable(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Theme.muted)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }

    private func handleScan(_ barcode: String) {
        guard !isLookingUp, result == nil else { return }

        print("Scanned barcode: \(barcode)")
        isLookingUp = true

        Task {
            defer { isLookingUp = false }

            do {
                switch try await service.fetchProduct(barcode: barcode) {
                case .found(let product):
                    // Hardcoded until the verdict engine lands.
                    result = ScanResult(verdict: .contains("milk"), product: product)

                case .notFound:
                    print("Trace: not found \(barcode)")

                case .failed(let error):
                    print("Trace: lookup failed \(barcode) — \(error)")
                }
            } catch {
                print("Trace: lookup rejected \(barcode) — \(error)")
            }
        }
    }
}

private extension View {

    /// `presentationCornerRadius` is iOS 16.4, the deployment target is 16.0.
    @ViewBuilder
    func sheetCornerRadius(_ radius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            presentationCornerRadius(radius)
        } else {
            self
        }
    }
}

#Preview {
    ScanView()
}
