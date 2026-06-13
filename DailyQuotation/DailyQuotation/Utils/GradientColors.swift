import SwiftUI

/// Thin shim that delegates to the active `QuoteTheme`. Kept as a
/// compatibility layer so call sites that don't yet thread an explicit
/// theme through their environment can still ask for "the gradient at
/// this index" and get the user-selected theme automatically.
///
/// Prefer `theme.gradient(for: index)` directly when you already have
/// the theme in scope (e.g. inside `QuoteSlideView` via `appearance`).
struct GradientColors {
  /// Mirrors the `colors` array of the currently-active theme. Read
  /// from `AppearanceManager.shared` so any caller that doesn't have
  /// the binding still picks up theme switches on next render.
  static var gradients: [[Color]] {
    AppearanceManager.shared.settings.theme.colors
  }

  static func gradient(for index: Int) -> LinearGradient {
    AppearanceManager.shared.settings.theme.gradient(for: index)
  }
}
