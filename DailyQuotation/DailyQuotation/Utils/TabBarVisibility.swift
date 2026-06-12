import SwiftUI

// MARK: - Tab bar visibility

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

// MARK: - Horizontal drag ownership

/// Preference key that lets a horizontal ScrollView (or any other
/// region that wants to own horizontal drags) tell `ContentView` "I'm
/// handling this — don't fire the tab-switch gesture". `.simultaneous`
/// gestures otherwise fire in parallel, so without this signal a drag
/// inside the Explore category pills would also slide the whole tab.
struct HorizontalDragClaimedPreferenceKey: PreferenceKey {
  static var defaultValue: Bool = false

  static func reduce(value: inout Bool, nextValue: () -> Bool) {
    value = value || nextValue()
  }
}

extension View {
  /// Apply to a horizontal `ScrollView` to suppress ContentView's
  /// swipe-to-switch-tab gesture while the user is actively dragging
  /// inside this view. Uses a tiny `minimumDistance: 2` drag observer
  /// so we only claim ownership once the user really starts dragging
  /// horizontally — taps and small jitters don't trigger it.
  func claimsHorizontalDrag() -> some View {
    modifier(HorizontalDragClaimModifier())
  }
}

private struct HorizontalDragClaimModifier: ViewModifier {
  @State private var isDragging: Bool = false

  func body(content: Content) -> some View {
    content
      .simultaneousGesture(
        DragGesture(minimumDistance: 2)
          .onChanged { value in
            // Only claim once we know this is a horizontal drag.
            if abs(value.translation.width) > abs(value.translation.height) {
              if !isDragging { isDragging = true }
            }
          }
          .onEnded { _ in
            isDragging = false
          }
      )
      .preference(key: HorizontalDragClaimedPreferenceKey.self, value: isDragging)
  }
}
