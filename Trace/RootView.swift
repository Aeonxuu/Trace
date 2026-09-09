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
        // An unconfigured tab bar uses a translucent material, so it darkens
        // as content scrolls under it. An opaque appearance on both the
        // standard and scroll-edge states holds it at surface either way.
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.surface)

        // configureWithOpaqueBackground resets item colors, so the tints have
        // to be set here rather than on UITabBar directly.
        for items in [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ] {
            items.normal.iconColor = UIColor(Theme.muted)
            items.normal.titleTextAttributes = [.foregroundColor: UIColor(Theme.muted)]
            items.selected.iconColor = UIColor(Theme.ink)
            items.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.ink)]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
        .environmentObject(RestrictionsModel())
}
