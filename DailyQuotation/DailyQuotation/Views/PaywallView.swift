import StoreKit
import SwiftUI

struct PaywallView: View {
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @Environment(\.dismiss) private var dismiss
  @State private var purchasingProductID: String?
  @State private var purchaseError: String?

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color.black.opacity(0.96), Color.black],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 16) {
        header
        benefits
        plans
        restoreButton
      }
      .padding(.horizontal, 24)
      .padding(.top, 8)
      .frame(maxWidth: 500)
    }
    .foregroundStyle(.white)
    .onAppear {
      // 确保进入时不会遗留上次的“加载中”状态
      purchasingProductID = nil
    }
    .task {
      if subscriptionManager.products.isEmpty {
        Task { await subscriptionManager.loadProducts() }
      }
    }
    .onChange(of: subscriptionManager.isPremiumUser) { _, isPremium in
      if isPremium {
        dismiss()
      }
    }
    .alert(
      "Purchase Failed",
      isPresented: Binding(
        get: { purchaseError != nil },
        set: { newValue in if !newValue { purchaseError = nil } })
    ) {
      Button("OK", role: .cancel) { purchaseError = nil }
    } message: {
      Text(purchaseError ?? "")
    }
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Get Full Access")
          .font(.system(size: 28, weight: .bold))
        // Text("All features. Full AI power.")
        //   .font(.system(size: 16, weight: .semibold))
        //   .foregroundStyle(Color.green)
      }
      Spacer()
      Button(action: { dismiss() }) {
        Image(systemName: "xmark")
          .font(.system(size: 16, weight: .bold))
          .padding(8)
          .background(Color.white.opacity(0.08))
          .clipShape(Circle())
      }
    }
  }

  private var benefits: some View {
    VStack(alignment: .leading, spacing: 12) {
      benefitRow("Save unlimited favorites")
      benefitRow("View up to 20 quotes/day")
      benefitRow("Unlock all font styles")
    }
    .padding()
    .background(Color.white.opacity(0.06))
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  private func benefitRow(_ text: String) -> some View {
    HStack(spacing: 10) {
      Image(systemName: "crown.fill")
        .foregroundColor(.yellow)
      Text(text)
        .font(.system(size: 15, weight: .semibold))
      Spacer()
    }
  }

  private var plans: some View {
    VStack(spacing: 12) {
      planButton(
        product: subscriptionManager.yearly, title: "$11.99 / Year",
        subtitle: "Best Value · 50% Discount!")
      planButton(
        product: subscriptionManager.monthly, title: "$1.99 / Month", subtitle: nil)
    }
  }

  private func planButton(product: Product?, title: String, subtitle: String?) -> some View {
    Button {
      if let product {
        HapticManager.medium()  // 仅订阅按钮触发触感
        performPurchase(product)
      } else {
        Task { await subscriptionManager.loadProducts() }
      }
    } label: {
      HStack {
        VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 4) {
          Text(title)
            .font(.system(size: 17, weight: .bold))
          if let subtitle, !subtitle.isEmpty {
            Text(subtitle)
              .font(.system(size: 13, weight: .medium))
              .foregroundColor(.black.opacity(0.8))
          }
        }
        Spacer()
        if let productID = product?.id, purchasingProductID == productID {
          ProgressView()
            .tint(.black)
            .scaleEffect(0.9)
        } else if let offer = product?.subscription?.introductoryOffer {
          Text(offerDisplay(offer))
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.18))
            .clipShape(Capsule())
        } else {
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .bold))
        }
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(
        LinearGradient(
          colors: [Color.yellow, Color.green],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .contentShape(RoundedRectangle(cornerRadius: 16))
      .foregroundColor(.black)
    }
    .buttonStyle(.plain)
    .disabled(purchasingProductID != nil || product == nil)
  }

  private var restoreButton: some View {
    Button {
      Task { await subscriptionManager.restorePurchases() }
    } label: {
      Text("Restore Purchases")
        .font(.system(size: 15, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
  }

  private var footerNote: some View {
    Text(
      "Subscriptions auto-renew unless cancelled at least 24 hours before the end of the period. Free trial converts to a paid subscription. Manage or cancel anytime in Settings."
    )
    .font(.system(size: 12))
    .foregroundStyle(.white.opacity(0.7))
    .multilineTextAlignment(.leading)
  }

  private var primaryButton: some View {
    Button(action: { dismiss() }) {
      Text("Continue")
        .font(.system(size: 17, weight: .bold))
        .frame(maxWidth: .infinity)
        .padding()
        .background(
          LinearGradient(
            colors: [Color.yellow, Color.green],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .foregroundColor(.black)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .buttonStyle(.plain)
  }

  private func offerDisplay(_ offer: Product.SubscriptionOffer) -> String {
    if offer.paymentMode == .freeTrial {
      let period = offer.period
      if period.unit == .day, period.value == 7 {
        return "7-day free trial"
      }
    }
    return "Intro Offer"
  }

  private func performPurchase(_ product: Product) {
    let productID = product.id
    purchasingProductID = productID

    Task {
      await subscriptionManager.purchase(product)
      await MainActor.run {
        purchasingProductID = nil
      }
    }
  }
}
