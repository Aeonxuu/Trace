//
//  ScanHistoryModel.swift
//  Trace
//
//  The scan log. The only thing that talks to ScanHistory, so no view has to
//  know where any of this is kept.
//

import Combine
import Foundation

@MainActor
final class ScanHistoryModel: ObservableObject {

    /// Newest first, which is the order every screen wants to read it in.
    @Published private(set) var records: [ScanRecord] = []

    private let store: ScanHistory
    private var isLoaded = false

    /// The default is built in here rather than as a default argument: a
    /// default argument is evaluated outside the actor, which this type is
    /// isolated to.
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

    /// The newest scans, newest first, however many of them there are.
    func recent(_ count: Int) -> [ScanRecord] {
        Array(records.prefix(count))
    }

    var scansThisWeek: Int {
        thisWeek.count
    }

    /// Counted over the same seven days as the scan total, so the two numbers
    /// read against each other rather than over different spans.
    var itemsFlaggedThisWeek: Int {
        thisWeek.filter(\.verdict.isContains).count
    }

    private var thisWeek: [ScanRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        return records.filter { $0.scannedAt >= cutoff }
    }
}
