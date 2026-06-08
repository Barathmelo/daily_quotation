import Foundation

/// One-stop home for build-time configuration values.
///
/// Keeping these in code (rather than `Info.plist`) avoids leaking
/// placeholder secrets through the bundled plist while staying easy to
/// grep. When the project later adopts xcconfig-driven secrets, move the
/// constants below to `Bundle.main.infoDictionary` reads and inject them
/// through `.xcconfig` files (e.g. `Debug.xcconfig` / `Release.xcconfig`).
enum DailyQuoteConfig {
  /// RevenueCat public iOS API key.
  ///
  /// - Important: This is a sandbox/test key. Replace with the
  ///   `appl_` Apple App Store production key before App Store release.
  static let revenueCatAPIKey = "test_IWZshKbmWcsfoLszvzbqCdQvKvO"
}
