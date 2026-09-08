//
//  HistoryView.swift
//  Trace
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        Text("History")
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.paper.ignoresSafeArea())
    }
}

#Preview {
    HistoryView()
}
