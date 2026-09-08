//
//  ProfileView.swift
//  Trace
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        Text("Profile")
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.paper.ignoresSafeArea())
    }
}

#Preview {
    ProfileView()
}
