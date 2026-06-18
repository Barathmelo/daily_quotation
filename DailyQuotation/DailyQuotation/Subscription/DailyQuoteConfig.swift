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

  // MARK: - Legal URLs (App Store Guideline 3.1.2)
  //
  // These URLs must also be configured in the RevenueCat dashboard
  // (Paywall → Footer Links) so that RevenueCatUI renders them on the
  // main paywall screen. The constants here are used as a fallback for
  // the paywall error state and for the in-app Settings legal section.

  /// Hosted Privacy Policy page.
  static let privacyPolicyURL = URL(string: "https://barathmelo.github.io/privacy.html")!

  /// Terms of Use — Apple Standard EULA.
  static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

  // MARK: - Support / Marketing URLs
  //
  // App Store rating / share URLs intentionally omitted pre-launch:
  // the numeric Apple ID is only available after the listing exists.
  // Re-introduce `appStoreURL` and `appStoreReviewURL` here, and wire the
  // Settings → Support section, once we have the real ID.
}
