// profile persistence behind a protocol, swappable for firestore later

import Foundation

// async on both sides, so a firestore swap changes this file and nothing above
protocol RestrictionStore {
    func load() async -> RestrictionSettings
    func save(_ settings: RestrictionSettings) async
}

struct UserDefaultsRestrictionStore: RestrictionStore {

    // versioned, so a later shape change can migrate
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
