//  Created by LJ on 9/8/26.
// app entry point

import SwiftUI

@main
struct TraceApp: App {

    // one model for the whole app, scan reads what profile edits
    @StateObject private var restrictions = RestrictionsModel()
    @StateObject private var history = ScanHistoryModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(restrictions)
                .environmentObject(history)
                .task {
                    await restrictions.loadIfNeeded()
                    await history.loadIfNeeded()
                }
        }
    }
}
