//
//  View+Sheet.swift
//  Trace
//

import SwiftUI

extension View {

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
