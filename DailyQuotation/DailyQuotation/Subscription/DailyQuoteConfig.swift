import Foundation

/// One-stop home for build-time configuration values.
///
/// Keeping these in code (rather than `Info.plist`) avoids leaking
/// placeholder secrets through the bundled plist while staying easy to
/// grep. When the project later adopts xcconfig-driven secrets, move the
/// constants below to `Bundle.main.infoDictionary` reads and inject them
/// through `.xcconfig` files (e.g. `Debug.xcconfig` / `Release.xcconfig`).
enum DailyQuoteConfig {
  /// RevenueCat public iOS API key (Apple App Store).
  ///
  /// Pulled from RevenueCat dashboard → Project Settings → API Keys.
  /// The same key is used for both sandbox and production; RevenueCat
  /// distinguishes environments server-side based on the receipt.
  static let revenueCatAPIKey = "appl_nRdUDgmPLauGUJsBgSTDBGWolzu"
}
