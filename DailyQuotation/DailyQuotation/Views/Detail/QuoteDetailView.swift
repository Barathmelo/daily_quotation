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
  @ObservedObject private var appearanceManager = AppearanceManager.shared

  @State private var showShareSheet = false
  @State private var copied = false

  private var theme: QuoteTheme {
    appearanceManager.settings.theme
  }

  init(quote: Quote) {
    self.quote = quote
    // The Feed picks gradients by feed position; detail-view quotes
    // arrive without a position, so derive a stable bucket from the
    // first 4 hex chars of the stable id. This keeps the same quote
    // showing the same colors every visit. (We assume all themes
    // expose the same palette count — currently 5.)
    let head = quote.id.prefix(4)
    let value = UInt32(head, radix: 16) ?? 0
    self.gradientIndex = Int(value) % max(QuoteTheme.midnight.colors.count, 1)
  }

  private var isFavorite: Bool {
    favoritesManager.isFavorite(quote)
  }

  /// Mirrors the Feed card's length-based shrink so a 160-char quote doesn't
  /// crowd this single-card detail view either. Detail uses a fixed 26pt
  /// base because it has no per-screen typography controls.
  private var adaptiveQuoteFontSize: CGFloat {
    let base: CGFloat = 26
    let length = quote.text.count
    let scale: CGFloat
    switch length {
    case ..<60: scale = 1.0
    case ..<100: scale = 0.88
    case ..<140: scale = 0.77
    default: scale = 0.66
    }
    return base * scale
  }

  var body: some View {
    ZStack {
      theme.background(for: gradientIndex)
        .ignoresSafeArea()

      VStack(spacing: 22) {
        Spacer()

        Text("\u{201C}\(quote.text)\u{201D}")
          .font(.system(size: adaptiveQuoteFontSize, weight: .regular, design: .serif))
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .lineSpacing(max(4, adaptiveQuoteFontSize * 0.28))
          .minimumScaleFactor(0.7)
          .quoteTextShadow()
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
          .padding(.bottom, 48)
      }
      .readableWidth()
    }
    .navigationTitle("Quote")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarColorScheme(.dark, for: .navigationBar)
    .hidesFloatingTabBar()
    .sheet(isPresented: $showShareSheet) {
      ShareCardSheet(
        quote: quote,
        gradientIndex: gradientIndex,
        theme: theme,
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
