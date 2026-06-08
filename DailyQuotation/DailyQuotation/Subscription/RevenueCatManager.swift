import Combine
import Foundation
import RevenueCat

/// Centralised wrapper around the RevenueCat SDK.
///
/// Responsibilities:
/// - Hold the most recent `CustomerInfo` and the current `Offering`.
/// - Expose `isPremiumUser` derived from the `DailyQuote Pro` entitlement.
/// - Listen to `Purchases.shared.customerInfoStream` so the UI updates
///   automatically after purchase/restore/cross-device sync, with no need
///   for manual `refresh()` calls on `scenePhase` transitions.
///
/// `Purchases.configure(withAPIKey:)` must be called once at app launch
/// (see `DailyQuotationApp.init`) before any instance method here runs.
@MainActor
final class RevenueCatManager: ObservableObject {
  static let shared = RevenueCatManager()

  /// Identifier of the entitlement that unlocks premium features.
  /// Must match exactly what's configured in the RevenueCat dashboard.
  static let premiumEntitlementID = "DailyQuote Pro"

  @Published private(set) var customerInfo: CustomerInfo?
  @Published private(set) var currentOffering: Offering?
  @Published private(set) var isPremiumUser: Bool = false
  @Published private(set) var isLoadingOfferings: Bool = false

  private var customerInfoTask: Task<Void, Never>?

  private init() {}

  // MARK: - Lifecycle

  /// Start observing `customerInfoStream` and prefetch the current offering.
  /// Safe to call multiple times; the listener task is replaced on each call.
  func start() {
    customerInfoTask?.cancel()
    customerInfoTask = Task { [weak self] in
      guard let self else { return }
      for await info in Purchases.shared.customerInfoStream {
        self.apply(customerInfo: info)
      }
    }

    Task { await loadOfferings() }
  }

  // MARK: - Public API

  func loadOfferings() async {
    isLoadingOfferings = true
    defer { isLoadingOfferings = false }
    do {
      let offerings = try await Purchases.shared.offerings()
      currentOffering = offerings.current
    } catch {
      #if DEBUG
      print("⚠️ RevenueCatManager.loadOfferings failed: \(error)")
      #endif
    }
  }

  @discardableResult
  func purchase(_ package: Package) async throws -> CustomerInfo {
    let result = try await Purchases.shared.purchase(package: package)
    apply(customerInfo: result.customerInfo)
    return result.customerInfo
  }

  @discardableResult
  func restorePurchases() async throws -> CustomerInfo {
    let info = try await Purchases.shared.restorePurchases()
    apply(customerInfo: info)
    return info
  }

  // MARK: - Helpers

  private func apply(customerInfo info: CustomerInfo) {
    customerInfo = info
    isPremiumUser = info.entitlements[Self.premiumEntitlementID]?.isActive == true
  }
}
