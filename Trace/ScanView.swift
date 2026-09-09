//
//  ScanView.swift
//  Trace
//

import SwiftUI

struct ScanView: View {

    private let service = ProductService()

    @EnvironmentObject private var restrictions: RestrictionsModel
    @EnvironmentObject private var history: ScanHistoryModel

    @State private var availability = ScannerAvailability.current()
    @State private var isEnteringManually = false
    @State private var isLookingUp = false
    @State private var result: ScanResult?

    @State private var repeatGuard = RepeatScanGuard()

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
        .onChange(of: result?.id) { id in
            guard id == nil else { return }
            repeatGuard.resultDismissed()
        }
        .sheet(isPresented: $isEnteringManually) {
            ManualBarcodeView()
                .presentationDetents([.medium])
                .sheetCornerRadius(Theme.sheetRadius)
        }
        .sheet(item: $result) { scan in
            ResultView(
                verdict: scan.verdict,
                product: scan.product,
                barcode: scan.barcode
            ) {
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

    /// Returns whether the scan was taken. Declining one leaves the camera
    /// running, so the next barcode is still detected.
    private func handleScan(_ barcode: String) -> Bool {
        guard !isLookingUp, result == nil, repeatGuard.allows(barcode) else { return false }

        repeatGuard.took(barcode)
        isLookingUp = true

        Task {
            defer { isLookingUp = false }

            do {
                switch try await service.fetchProduct(barcode: barcode) {
                case .found(let product):
                    let verdict = VerdictEngine.evaluate(
                        product: product,
                        restrictions: restrictions.restrictions,
                        countTraces: restrictions.countsMayContain
                    )
                    result = ScanResult(verdict: verdict, product: product, barcode: barcode)
                    log(verdict, product: product, barcode: barcode)

                case .notFound:
                    result = nothingFound(barcode)

                case .failed(let error):
                    // A dead end either way for the person holding the phone,
                    // so it lands on the same screen. The error is kept in the
                    // log because the screen cannot carry it.
                    print("Trace: lookup failed \(barcode) — \(error)")
                    result = nothingFound(barcode)
                }
            } catch {
                print("Trace: lookup rejected \(barcode) — \(error)")
                result = nothingFound(barcode)
            }
        }

        return true
    }

    /// The lookup came back with no product to say anything about.
    private func nothingFound(_ barcode: String) -> ScanResult {
        log(.notFound, product: nil, barcode: barcode)
        return ScanResult(verdict: .notFound, product: nil, barcode: barcode)
    }

    /// Records the scan for Today and History. Keeps only what those rows
    /// draw; reopening one refetches the product by barcode.
    private func log(_ verdict: Verdict, product: Product?, barcode: String) {
        history.record(
            ScanRecord(
                barcode: barcode,
                productName: product?.productName,
                brands: product?.brands,
                imageURL: product?.imageURL,
                verdict: verdict
            )
        )
    }
}

#Preview {
    ScanView()
        .environmentObject(RestrictionsModel())
        .environmentObject(ScanHistoryModel())
}
