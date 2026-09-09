//
//  ScanHistoryStore.swift
//  Trace
//
//  Scan history persistence, behind a protocol so the UserDefaults
//  implementation can be swapped for Firestore later.
//

import Foundation

/// Async on both sides even though UserDefaults is not, so that swapping in a
/// Firestore implementation changes this file and nothing above it. Same shape
/// as RestrictionStore.
protocol ScanHistory {
    func load() async -> [ScanRecord]
    func save(_ records: [ScanRecord]) async
}

struct UserDefaultsScanHistory: ScanHistory {

    /// Versioned: a later shape change can migrate instead of guessing.
    private static let key = "trace.scanHistory.v1"

    /// UserDefaults is loaded into memory whole, so the log is capped rather
    /// than left to grow for the life of the install.
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
