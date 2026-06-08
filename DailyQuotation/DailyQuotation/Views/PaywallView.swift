import RevenueCat
import RevenueCatUI
import SwiftUI

/// Thin wrapper around `RevenueCatUI.PaywallView` that:
/// - Shows the paywall designed in the RevenueCat dashboard (no local UI).
/// - Falls back to a plain "subscription unavailable" view if the offering
///   can't be loaded (network failure or dashboard not yet configured).
/// - Auto-dismisses on successful purchase / restore via the parent sheet
///   binding plus `.onChange` of premium status.
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
    .onChange(of: subscriptionManager.isPremiumUser) { _, isPremium in
      if isPremium { dismiss() }
    }
    .task {
      if subscriptionManager.currentOffering == nil {
        await subscriptionManager.loadOfferings()
      }
    }
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
