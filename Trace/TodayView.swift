//
//  TodayView.swift
//  Trace
//

import SwiftUI

struct TodayView: View {
    var body: some View {
        Text("Today")
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.paper.ignoresSafeArea())
            .debugVerdictMenu()
    }
}

#Preview {
    TodayView()
}
