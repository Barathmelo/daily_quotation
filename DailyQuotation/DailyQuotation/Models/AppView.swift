import Foundation

enum AppView: String, CaseIterable {
    case feed = "FEED"
    case favorites = "FAVORITES"

    var order: Int {
        switch self {
        case .feed:
            return 0
        case .favorites:
            return 1
        }
    }

    private static var orderedCases: [AppView] {
        Self.allCases.sorted { $0.order < $1.order }
    }

    func next() -> AppView? {
        let cases = Self.orderedCases
        guard let index = cases.firstIndex(of: self),
              index + 1 < cases.count else {
            return nil
        }
        return cases[index + 1]
    }

    func previous() -> AppView? {
        let cases = Self.orderedCases
        guard let index = cases.firstIndex(of: self),
              index - 1 >= 0 else {
            return nil
        }
        return cases[index - 1]
    }
}


