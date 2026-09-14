// scan history persistence behind a protocol, swappable for firestore later

import Foundation

// async on both sides, same shape as RestrictionStore
protocol ScanHistory {
    func load() async -> [ScanRecord]
    func save(_ records: [ScanRecord]) async
}

struct UserDefaultsScanHistory: ScanHistory {

    // v2: v1 records cannot decode into the multi-match shape
    private static let key = "trace.scanHistory.v2"

    // userdefaults loads whole, so the log is capped
    static let limit = 200

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() async -> [ScanRecord] {
        guard let data = defaults.data(forKey: Self.key),
              let records = try? JSONDecoder().decode([ScanRecord].self, from: data) else {
            return []
        }
        return records
    }

    func save(_ records: [ScanRecord]) async {
        guard let data = try? JSONEncoder().encode(Array(records.prefix(Self.limit))) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
