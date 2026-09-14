// the scan log, the only thing that talks to ScanHistory

import Combine
import Foundation

@MainActor
final class ScanHistoryModel: ObservableObject {

    // newest first
    @Published private(set) var records: [ScanRecord] = []

    private let store: ScanHistory
    private var isLoaded = false

    // default built in here, a default argument evaluates outside the actor
    init(store: ScanHistory? = nil) {
        self.store = store ?? UserDefaultsScanHistory()
    }

    func loadIfNeeded() async {
        guard !isLoaded else { return }

        records = await store.load()
        isLoaded = true
    }

    func record(_ record: ScanRecord) {
        records.insert(record, at: 0)
        records = Array(records.prefix(UserDefaultsScanHistory.limit))
        persist()
    }

    func remove(_ record: ScanRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    private func persist() {
        let snapshot = records
        Task { await store.save(snapshot) }
    }

    // the newest scans, however many there are
    func recent(_ count: Int) -> [ScanRecord] {
        Array(records.prefix(count))
    }

    var scansThisWeek: Int {
        thisWeek.count
    }

    // same seven days as the scan total
    var itemsFlaggedThisWeek: Int {
        thisWeek.filter(\.verdict.isContains).count
    }

    private var thisWeek: [ScanRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        return records.filter { $0.scannedAt >= cutoff }
    }
}
