//
//  TraceApp.swift
//  Trace
//
//  Created by LJ on 9/8/26.
//

import SwiftUI

@main
struct TraceApp: App {

    /// One model for the whole app: the Scan tab has to read the same saved
    /// restrictions the Profile tab edits, not its own copy of them.
    @StateObject private var restrictions = RestrictionsModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(restrictions)
                .task { await restrictions.loadIfNeeded() }
        }
    }
}
