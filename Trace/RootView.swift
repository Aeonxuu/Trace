//
//  RootView.swift
//  Trace
//
//  The app's navigation shell.
//

import SwiftUI
import UIKit

struct RootView: View {

    private enum Tab: Hashable {
        case today, scan, history, profile
    }

    @State private var selection = Tab.today

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
        TabView(selection: $selection) {
            TodayView(onScanTapped: { selection = .scan })
                .tabItem { Label("Today", systemImage: "calendar") }
                .tag(Tab.today)

            ScanView()
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }
                .tag(Tab.scan)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(Tab.profile)
        }
        .tint(Theme.ink)
    }
}

#Preview {
    RootView()
        .environmentObject(RestrictionsModel())
        .environmentObject(ScanHistoryModel())
}
