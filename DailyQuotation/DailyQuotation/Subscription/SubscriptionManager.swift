import Combine
import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
  static let shared = SubscriptionManager()

  @Published private(set) var products: [Product] = []
  @Published private(set) var isPremiumUser: Bool = false
  @Published private(set) var isLoading: Bool = false

  private let productIDs = [
    "premium_monthly",
    "premium_yearly"
  ]

  init() {
    Task {
      await loadProducts()
      await refreshSubscriptionStatus()
      listenForTransactions()
    }
  }

  // MARK: - Public API
  func loadProducts() async {
    isLoading = true
    defer { isLoading = false }
    do {
      let fetched = try await Product.products(for: productIDs)
      await MainActor.run {
        self.products = fetched.sorted { $0.id < $1.id }
      }
    } catch {
      print("❌ loadProducts error: \(error)")
    }
  }

  func purchase(_ product: Product) async {
    do {
      let result = try await product.purchase()
      switch result {
      case .success(let verification):
        if case .verified(let transaction) = verification {
          await transaction.finish()
          await refreshSubscriptionStatus()
        }
      case .userCancelled, .pending:
        break
      @unknown default:
        break
      }
    } catch {
      print("❌ purchase error: \(error)")
    }
  }

  func restorePurchases() async {
    do {
      try await AppStore.sync()
      await refreshSubscriptionStatus()
    } catch {
      print("❌ restore error: \(error)")
    }
  }

  func refreshSubscriptionStatus() async {
    var active = false
    for await result in Transaction.currentEntitlements {
      if case .verified(let transaction) = result,
         productIDs.contains(transaction.productID) {
        active = true
        break
      }
    }
    await MainActor.run {
      self.isPremiumUser = active
    }
  }

  // MARK: - Helpers
  var monthly: Product? { products.first { $0.id == "premium_monthly" } }
  var yearly: Product? { products.first { $0.id == "premium_yearly" } }

  private func listenForTransactions() {
    Task.detached { [weak self] in
      for await update in Transaction.updates {
        guard let self else { continue }
        if case .verified(let transaction) = update,
           self.productIDs.contains(transaction.productID) {
          await transaction.finish()
          await self.refreshSubscriptionStatus()
        }
      }
    }
  }
}

