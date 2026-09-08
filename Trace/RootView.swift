//
//  RootView.swift
//  Trace
//
//  The app's navigation shell.
//

import SwiftUI
import UIKit

struct RootView: View {

    init() {
        // `.tint` below colors the selected item; this colors the unselected
        // icons and labels. Deliberately not a UITabBarAppearance: configuring
        // one also restyles the bar's background material.
        UITabBar.appearance().unselectedItemTintColor = UIColor(Theme.muted)
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "calendar") }

            ScanView()
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .tint(Theme.ink)
    }
}

#Preview {
    RootView()
}
