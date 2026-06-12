import SwiftUI

/// Single-quote landing view used as the destination from Explore search
/// results, category lists, author lists, and "Today's Pick". Visually
/// echoes a Feed card but stays inside a NavigationStack — no full-screen
/// hijacking and no swipe-to-next, so the back gesture cleanly returns
/// to the originating list.
struct QuoteDetailView: View {
  let quote: Quote
  let gradientIndex: Int

  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @ObservedObject private var favoritesManager = FavoritesManager.shared

  @State private var showShareSheet = false
  @State private var copied = false

  init(quote: Quote) {
    self.quote = quote
    // The Feed picks gradients by feed position; detail-view quotes
    // arrive without a position, so derive a stable bucket from the
    // first 4 hex chars of the stable id. This keeps the same quote
    // showing the same colors every visit.
    let head = quote.id.prefix(4)
    let value = UInt32(head, radix: 16) ?? 0
    self.gradientIndex = Int(value) % max(GradientColors.gradients.count, 1)
  }

  private var isFavorite: Bool {
    favoritesManager.isFavorite(quote)
  }

  var body: some View {
    ZStack {
      GradientColors.gradient(for: gradientIndex)
        .ignoresSafeArea()

      VStack(spacing: 22) {
        Spacer()

        Text("\u{201C}\(quote.text)\u{201D}")
          .font(.system(size: 26, weight: .regular, design: .serif))
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .lineSpacing(8)
          .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
          .padding(.horizontal, 28)

        Rectangle()
          .fill(Color.white.opacity(0.3))
          .frame(width: 48, height: 2)

        Text(quote.author)
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(.white.opacity(0.9))
          .tracking(1)

        if let category = quote.category, !category.isEmpty {
          Text(category.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(2)
            .foregroundColor(.white.opacity(0.6))
        }

        Spacer()

        actionRow
          // ContentView keeps a floating TabBar overlay on top of all
          // pages (it's a hand-rolled bar, not SwiftUI's TabView), so a
          // pushed detail view still has to make room for it manually.
          .padding(.bottom, 130)
      }
    }
    .navigationTitle("Quote")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarColorScheme(.dark, for: .navigationBar)
    .sheet(isPresented: $showShareSheet) {
      ShareCardSheet(
        quote: quote,
        gradientIndex: gradientIndex,
        isPremium: subscriptionManager.isPremiumUser
      )
    }
  }

  private var actionRow: some View {
    HStack(spacing: 28) {
      iconButton(
        systemName: isFavorite ? "heart.fill" : "heart",
        tint: isFavorite ? .red : .white,
        action: handleFavoriteTap
      )
      iconButton(systemName: "square.and.arrow.up", tint: .white) {
        HapticManager.light()
        showShareSheet = true
      }
      iconButton(
        systemName: copied ? "checkmark" : "doc.on.doc",
        tint: copied ? .green : .white,
        action: handleCopyTap
      )
    }
  }

  private func iconButton(systemName: String, tint: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 22))
        .foregroundColor(tint)
        .frame(width: 56, height: 56)
        .background(
          Circle()
            .fill(Color.white.opacity(0.12))
            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        )
    }
    .buttonStyle(.plain)
  }

  private func handleFavoriteTap() {
    HapticManager.light()
    let allowed = AccessControl.shared.canAddFavorite(
      currentCount: favoritesManager.favorites.count,
      isPremium: subscriptionManager.isPremiumUser
    )
    if allowed {
      favoritesManager.toggleFavorite(quote)
    }
  }

  private func handleCopyTap() {
    UIPasteboard.general.string = "\u{201C}\(quote.text)\u{201D} — \(quote.author)"
    HapticManager.success()
    withAnimation { copied = true }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation { copied = false }
    }
  }
}
