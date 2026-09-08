//
//  ScanView.swift
//  Trace
//

import SwiftUI

struct ScanView: View {
    var body: some View {
        Text("Scan")
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.paper.ignoresSafeArea())
    }
}

#Preview {
    ScanView()
}
