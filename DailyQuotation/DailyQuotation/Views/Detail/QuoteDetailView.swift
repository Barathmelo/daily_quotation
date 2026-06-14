import SwiftUI

/// Single-quote landing view used as the destination from Explore search
/// results, category lists, author lists, and "Today's Pick". Visually
/// echoes a Feed card but stays inside a NavigationStack — no full-screen
/// hijacking and no swipe-to-next, so the back gesture cleanly returns
/// to the originating list.
struct QuoteDetailView: View {
  let quote: Quote
  let gradientIndex: Int
  /// Optional appearance snapshot passed in by the Favorites tab so a
  /// saved card is replayed with the font/size/theme the user had
  /// active when they tapped the heart. `nil` for all other entry
  /// points (Explore "Today's Pick", category lists, author lists),
  /// which fall back to the global `AppearanceManager` settings and
  /// the pre-existing serif rendering.
  let appearanceOverride: AppearanceSettings?

  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @ObservedObject private var favoritesManager = FavoritesManager.shared
  @ObservedObject private var appearanceManager = AppearanceManager.shared

  @State private var showShareSheet = false
  @State private var showingPaywall = false
  @State private var copied = false

  /// The appearance source the view should render against: snapshot
  /// when one was supplied, otherwise the live global settings.
  private var effectiveAppearance: AppearanceSettings {
    appearanceOverride ?? appearanceManager.settings
  }

  private var theme: QuoteTheme {
    effectiveAppearance.theme
  }

  init(quote: Quote) {
    self.quote = quote
    self.appearanceOverride = nil
    // The Feed picks gradients by feed position; detail-view quotes
    // arrive without a position, so derive a stable bucket from the
    // first 4 hex chars of the stable id. This keeps the same quote
    // showing the same colors every visit. (We assume all themes
    // expose the same palette count — currently 5.)
    let head = quote.id.prefix(4)
    let value = UInt32(head, radix: 16) ?? 0
    self.gradientIndex = Int(value) % max(QuoteTheme.midnight.colors.count, 1)
  }

  /// Snapshot entry point used by the Favorites tab. The caller
  /// supplies the exact appearance + gradient index that were active
  /// when the quote was saved, so the detail view re-creates that
  /// visual instead of using the user's current global settings.
  init(quote: Quote, appearance: AppearanceSettings, gradientIndex: Int) {
    self.quote = quote
    self.appearanceOverride = appearance
    self.gradientIndex = gradientIndex
  }

  private var isFavorite: Bool {
    favoritesManager.isFavorite(quote)
  }

  /// Mirrors the Feed card's length-based shrink so a 160-char quote doesn't
  /// crowd this single-card detail view either. When a snapshot is
  /// supplied we honor its `TextSize`; otherwise we keep the original
  /// 26pt detail-view default.
  private var adaptiveQuoteFontSize: CGFloat {
    let base: CGFloat = appearanceOverride?.size.fontSize ?? 26
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

  /// Font used to render the quote body. Snapshot mode uses the saved
  /// `FontFamily`; other entry points keep the legacy serif design.
  private var quoteFont: Font {
    if let override = appearanceOverride {
      return override.font.font(size: adaptiveQuoteFontSize)
    }
    return .system(size: adaptiveQuoteFontSize, weight: .regular, design: .serif)
  }

  var body: some View {
    ZStack {
      theme.background(for: gradientIndex)
        .ignoresSafeArea()

      VStack(spacing: 22) {
        Spacer()

        Text("\u{201C}\(quote.text)\u{201D}")
          .font(quoteFont)
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
        font: effectiveAppearance.font,
        isPremium: subscriptionManager.isPremiumUser,
        onRequirePaywall: {
          // Mirror QuoteSlideView: dismiss the share sheet first so its
          // exit animation completes, otherwise SwiftUI silently drops
          // the second sheet presentation in the same frame.
          showShareSheet = false
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showingPaywall = true
          }
        }
      )
    }
    .sheet(isPresented: $showingPaywall) {
      PaywallView()
        .environmentObject(subscriptionManager)
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
      // Use the effective appearance + active gradient index as the
      // snapshot. If we got here via Favorites tap (with an override),
      // re-toggling will restore the same visual; otherwise we capture
      // the user's current global settings.
      favoritesManager.toggleFavorite(
        quote,
        appearance: effectiveAppearance,
        gradientIndex: gradientIndex
      )
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
