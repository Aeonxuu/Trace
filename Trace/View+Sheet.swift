// sheet helpers

import SwiftUI

extension View {

    // presentationCornerRadius is ios 16.4, the target is 16.0
    @ViewBuilder
    func sheetCornerRadius(_ radius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            presentationCornerRadius(radius)
        } else {
            self
        }
    }
}
