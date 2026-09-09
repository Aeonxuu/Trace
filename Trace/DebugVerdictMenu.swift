//
//  DebugVerdictMenu.swift
//  Trace
//
//  Temporary. Long-press the Today screen to open the Result screen in each
//  of its four states. Goes away once real scans can reach all four.
//

import SwiftUI

extension View {

    @ViewBuilder
    func debugVerdictMenu() -> some View {
        #if DEBUG
        modifier(DebugVerdictMenu())
        #else
        self
        #endif
    }
}

#if DEBUG

private struct DebugVerdictMenu: ViewModifier {

    @State private var isShowingMenu = false
    @State private var result: ScanResult?

    func body(content: Content) -> some View {
        content
            // The whole screen is the target, not just the text on it.
            .contentShape(Rectangle())
            .onLongPressGesture { isShowingMenu = true }
            .confirmationDialog(
                "Result screen",
                isPresented: $isShowingMenu,
                titleVisibility: .visible
            ) {
                ForEach(DebugSample.all) { sample in
                    Button(sample.name) { result = sample.scan }
                }
            }
            // Presented rather than pushed, so it is checked in the same
            // sheet it appears in after a real scan.
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
}

#endif
