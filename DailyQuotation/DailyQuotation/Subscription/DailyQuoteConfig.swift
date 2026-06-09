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

  // MARK: - Legal links (required by App Store Guideline 3.1.2)
  //
  // 这两个 URL 必须在订阅页面（PaywallView）中以可点击链接的形式呈现，
  // 同时 App Store Connect 的 App Description 里也必须出现 EULA 链接。
  // 不要在这里使用本地文件 / about:blank 之类的占位，Apple 会真实点击验证。

  /// 标准 Apple EULA。如果你后续使用自定义 EULA，
  /// 在 App Store Connect → App Information → License Agreement 配置，
  /// 并把这里替换成自己的可访问 URL。
  static let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

  /// 自托管 Privacy Policy URL（推荐用 GitHub Pages）。
  static let privacyPolicyURL = URL(string: "https://barathmelo.github.io/privacy.html")!
}
