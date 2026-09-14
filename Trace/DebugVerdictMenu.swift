// temporary: long-press today to open the result screen in each state

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
            // the whole screen is the target
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
            // presented, not pushed, so it is the same sheet a real scan uses
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
