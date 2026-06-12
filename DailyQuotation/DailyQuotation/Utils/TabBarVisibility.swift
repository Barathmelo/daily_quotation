import SwiftUI

/// Preference key used by destination views to ask `ContentView` to
/// hide its floating tab-bar overlay while they're on screen.
///
/// We can't use SwiftUI's `.toolbar(.hidden, for: .tabBar)` because the
/// tab bar isn't a `TabView` — it's a custom overlay that ContentView
/// stacks on top of every page. Preference keys flow naturally up the
/// view tree and reset to `defaultValue` when the contributing view
/// disappears, which gives us the right "hide while pushed, show on
/// pop" behavior for free.
struct TabBarHiddenPreferenceKey: PreferenceKey {
  static var defaultValue: Bool = false

  static func reduce(value: inout Bool, nextValue: () -> Bool) {
    // OR-merge so any descendant requesting "hidden" wins over peers
    // that left it at default.
    value = value || nextValue()
  }
}

extension View {
  /// Hide ContentView's floating tab bar while this view is in the
  /// hierarchy. Apply to terminal/dead-end destinations
  /// (QuoteDetailView, CategoryQuotesView, …) so users back-button
  /// out instead of jumping to another tab mid-task.
  func hidesFloatingTabBar(_ hidden: Bool = true) -> some View {
    preference(key: TabBarHiddenPreferenceKey.self, value: hidden)
  }
}
