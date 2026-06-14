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

// MARK: - Quote text shadow

extension View {
  /// Two-layer drop shadow used on quote text everywhere it sits on
  /// top of a gradient or photo background. The inner tight shadow
  /// gives white glyphs a crisp edge; the outer soft shadow casts a
  /// dark halo so the text still pops against bright regions (Desert,
  /// Holo, the brighter half of Mountain etc.).
  func quoteTextShadow() -> some View {
    self
      .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
      .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 6)
  }
}

// MARK: - Readable content width

extension View {
  /// Cap a view's width to a comfortable reading width on iPad while
  /// still letting it fill the available space on iPhone. 680pt is the
  /// rough "ideal line length" recommended by typography resources
  /// (~70 chars at 16pt body). Wrapping outside in another
  /// `.frame(maxWidth: .infinity)` keeps the capped content horizontally
  /// centered on iPad.
  func readableWidth(_ maxWidth: CGFloat = 680) -> some View {
    self
      .frame(maxWidth: maxWidth)
      .frame(maxWidth: .infinity)
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

// MARK: - Horizontal tab swipe in flight (parent → child)

/// Environment flag set by `ContentView` while the user is mid-way
/// through a horizontal tab-switch drag. Vertical `ScrollView`s on the
/// destination pages read this and bind it to `.scrollDisabled` so the
/// page can't simultaneously rubber-band downward while it's already
/// being translated sideways.
///
/// Crucially this stays `true` from the moment the parent gesture locks
/// horizontal until the finger actually lifts — including after a mid-
/// drag disqualification that snaps `translation` back to 0. Without
/// that, the user could "release" the horizontal commit by adding
/// vertical motion and then have the ScrollView take over the still-
/// active touch, producing the offset-plus-bounce artifact.
private struct HorizontalTabSwipeActiveKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

extension EnvironmentValues {
  var isHorizontalTabSwipeActive: Bool {
    get { self[HorizontalTabSwipeActiveKey.self] }
    set { self[HorizontalTabSwipeActiveKey.self] = newValue }
  }
}
