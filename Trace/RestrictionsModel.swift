// profile state, the only thing that talks to RestrictionStore

import Combine
import Foundation

@MainActor
final class RestrictionsModel: ObservableObject {

    @Published private(set) var restrictions: [Restriction] = []

    // whether "may contain" counts as a match, writing it saves
    @Published var countsMayContain = false {
        didSet {
            guard isLoaded, oldValue != countsMayContain else { return }
            persist()
        }
    }

    private let store: RestrictionStore

    // keeps the didSet above from writing back what it just read
    private var isLoaded = false

    // default built in here, a default argument evaluates outside the actor
    init(store: RestrictionStore? = nil) {
        self.store = store ?? UserDefaultsRestrictionStore()
    }

    var selectedTagIDs: Set<String> {
        Set(restrictions.map(\.tagID))
    }

    func loadIfNeeded() async {
        guard !isLoaded else { return }

        let settings = await store.load()
        restrictions = settings.restrictions
        countsMayContain = settings.countsMayContain
        isLoaded = true
    }

    // replaces the saved set, keeping severities that survived
    func apply(selection: Set<String>) {
        let existing = Dictionary(
            restrictions.map { ($0.tagID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        restrictions = AllergenCatalog.all
            .filter { selection.contains($0.id) }
            .map { allergen in
                existing[allergen.id]
                    ?? Restriction(tagID: allergen.id, name: allergen.name, severity: .avoid)
            }

        persist()
    }

    func remove(_ restriction: Restriction) {
        restrictions.removeAll { $0.tagID == restriction.tagID }
        persist()
    }

    func setSeverity(_ severity: Severity, for restriction: Restriction) {
        guard let index = restrictions.firstIndex(where: { $0.tagID == restriction.tagID }),
              restrictions[index].severity != severity else {
            return
        }

        restrictions[index].severity = severity
        persist()
    }

    private func persist() {
        let settings = RestrictionSettings(
            restrictions: restrictions,
            countsMayContain: countsMayContain
        )
        Task { await store.save(settings) }
    }
}
