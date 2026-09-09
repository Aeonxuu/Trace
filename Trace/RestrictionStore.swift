//
//  RestrictionStore.swift
//  Trace
//
//  Persistence for the Profile screen, behind a protocol so the UserDefaults
//  implementation can be swapped for Firestore later.
//

import Foundation

/// Async on both sides even though UserDefaults is not, so that swapping in a
/// Firestore implementation changes this file and nothing above it.
protocol RestrictionStore {
    func load() async -> RestrictionSettings
    func save(_ settings: RestrictionSettings) async
}

struct UserDefaultsRestrictionStore: RestrictionStore {

    /// Versioned: a later shape change can migrate instead of guessing.
    private static let key = "trace.restrictionSettings.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() async -> RestrictionSettings {
        guard let data = defaults.data(forKey: Self.key),
              let settings = try? JSONDecoder().decode(RestrictionSettings.self, from: data) else {
            return RestrictionSettings()
        }
        return settings
    }

    func save(_ settings: RestrictionSettings) async {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
