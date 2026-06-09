import RevenueCat
import RevenueCatUI
import SwiftUI

/// Thin wrapper around `RevenueCatUI.PaywallView` that:
/// - Shows the paywall designed in the RevenueCat dashboard (no local UI).
/// - Falls back to a plain "subscription unavailable" view if the offering
///   can't be loaded (network failure or dashboard not yet configured).
/// - Auto-dismisses on successful purchase / restore via the parent sheet
///   binding plus `.onChange` of premium status.
/// - Displays a legal footer with functional links to the Terms of Use (EULA)
///   and Privacy Policy. These are REQUIRED by App Store Review Guideline 3.1.2
///   for any app offering auto-renewable subscriptions, and must be present in
///   the app binary (not only in App Store Connect metadata).
struct PaywallView: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Group {
      if let offering = subscriptionManager.currentOffering {
        RevenueCatUI.PaywallView(offering: offering, displayCloseButton: true)
      } else if subscriptionManager.isLoadingOfferings {
        loadingView
      } else {
        fallbackView
      }
    }
    // 把法律链接钉在订阅页面底部安全区内，确保审核员能在 binary 中看到并点击。
    .safeAreaInset(edge: .bottom, spacing: 0) {
      legalFooter
    }
    .onChange(of: subscriptionManager.isPremiumUser) { _, isPremium in
      if isPremium { dismiss() }
    }
    .task {
      if subscriptionManager.currentOffering == nil {
        await subscriptionManager.loadOfferings()
      }
    }
  }

  /// Footer 必须包含可点击的 Terms of Use (EULA) 与 Privacy Policy。
  /// 使用 SwiftUI `Link` 让系统直接在浏览器中打开真实 URL，满足 Apple "functional link" 的要求。
  private var legalFooter: some View {
    HStack(spacing: 16) {
      Link("Terms of Use (EULA)", destination: DailyQuoteConfig.eulaURL)
      Text("·")
        .foregroundStyle(.white.opacity(0.4))
      Link("Privacy Policy", destination: DailyQuoteConfig.privacyPolicyURL)
    }
    .font(.footnote)
    .foregroundStyle(.white.opacity(0.75))
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity)
    .background(Color.black.opacity(0.6))
  }

  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
      Text("Loading subscription options…")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.ignoresSafeArea())
  }

  private var fallbackView: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 36))
        .foregroundStyle(.yellow)
      Text("Subscription unavailable")
        .font(.headline)
        .foregroundStyle(.white)
      Text("We couldn't load the subscription options.\nPlease check your connection and try again.")
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .foregroundStyle(.white.opacity(0.7))
      Button("Try Again") {
        Task { await subscriptionManager.loadOfferings() }
      }
      .buttonStyle(.borderedProminent)
      .padding(.top, 8)

      Button("Close") { dismiss() }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.6))
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.ignoresSafeArea())
  }
}
