import SwiftUI

/// Main "Quote of the Day" surface. Single card, no swipe paging. Users
/// can refresh the visible quote via the top-right button: premium gets
/// `AccessControl.premiumDailyRefreshLimit` refreshes per day, free
/// gets `freeDailyRefreshLimit`. Exceeding the free limit raises the
/// paywall via `onRequirePaywall`.
struct FeedView: View {
  /// Always constructed with `isPremium: true` so `todayOrder` returns
  /// the full 20-quote rotation — the new model uses `AccessControl`
  /// (not viewmodel state) to gate access, but still relies on the
  /// viewmodel for the deterministic per-day index sequence.
  @StateObject private var viewModel: FeedViewModel
  @ObservedObject var favoritesManager = FavoritesManager.shared
  @Binding var appearance: AppearanceSettings
  @Binding var persistedIndex: Int
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  var onRequirePaywall: () -> Void = {}

  @State private var remainingRefreshes: Int = 0
  @State private var showingSettings = false

  init(
    appearance: Binding<AppearanceSettings>,
    persistedIndex: Binding<Int>,
    isPremium: Bool,
    onRequirePaywall: @escaping () -> Void
  ) {
    self._appearance = appearance
    self._persistedIndex = persistedIndex
    self.onRequirePaywall = onRequirePaywall
    // Force `isPremium: true` so the viewmodel exposes the full 20-quote
    // rotation regardless of subscription. The refresh quota itself is
    // enforced by AccessControl using the *real* `isPremium` flag.
    self._viewModel = StateObject(wrappedValue: FeedViewModel(isPremium: true))
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black.ignoresSafeArea(.all)

        if let quote = viewModel.quote(at: viewModel.currentPosition) {
          QuoteSlideView(
            quote: quote,
            // Hold the gradient index steady across refreshes so the
            // background doesn't jump between palettes every tap. The
            // per-day "Quote of the Day" pins the visual; refreshing
            // only changes the quote text/author, not the canvas.
            index: stableGradientIndex,
            // Always show the "Quote of the Day" badge — even after a
            // refresh — since the new model treats every Feed card as
            // the user's daily pick rather than a paged Feed slot.
            isToday: true,
            isPremium: subscriptionManager.isPremiumUser,
            onRequirePaywall: onRequirePaywall,
            onToggleFavorite: {
              let allowed = AccessControl.shared.canAddFavorite(
                currentCount: favoritesManager.favorites.count,
                isPremium: subscriptionManager.isPremiumUser)
              if allowed {
                favoritesManager.toggleFavorite(
                  quote,
                  appearance: appearance,
                  gradientIndex: stableGradientIndex
                )
              } else {
                onRequirePaywall()
              }
            },
            appearance: $appearance
          )
          // Cross-fade so refresh feels like the card content morphs
          // in place rather than abruptly switching.
          .id(viewModel.currentPosition)
          .transition(.opacity)
        }

        VStack {
          HStack {
            refreshButton
            Spacer()
            settingsButton
          }
          .padding(.horizontal, 16)
          .padding(.top, 60)
          Spacer()
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        // Match `QuoteSlideView`'s `.opacity` transition so the top
        // controls fade in alongside the card on tab switches instead
        // of inheriting the parent `pageTransition`'s horizontal slide
        // and visibly skating in from the side.
        .transition(.opacity)
      }
    }
    .ignoresSafeArea(.all)
    .sheet(isPresented: $showingSettings) {
      SettingsSheet()
        .environmentObject(subscriptionManager)
    }
    .onAppear(perform: handleAppear)
    .onChange(of: persistedIndex) { newValue in
      viewModel.currentPosition = clamp(newValue)
    }
    .onChange(of: viewModel.currentPosition) { newValue in
      persistedIndex = newValue
      // Mirror whatever the user is currently looking at to the widget
      // so the home-screen card matches Feed (including post-refresh).
      syncCurrentQuoteToWidget()
    }
    .onChange(of: currentDayOfYear) { _ in
      // New day → re-pin viewmodel to today (so `todayOrder` rebuilds
      // for the new date), restart on the fresh "Quote of the Day", and
      // replenish the refresh counter.
      viewModel.updateReferenceDate(Date())
      viewModel.currentPosition = 0
      persistedIndex = 0
      AccessControl.shared.resetIfNeeded()
      remainingRefreshes = AccessControl.shared
        .remainingRefreshes(isPremium: subscriptionManager.isPremiumUser)
    }
  }

  // MARK: - Top-right controls

  /// Companion to `refreshButton`. Sits to its left and opens the
  /// global Settings sheet. Lives on Feed (not Favorites) so the
  /// entry point is reachable from the app's primary surface, and
  /// styled as a circle to visually distinguish it from the refresh
  /// pill while sharing the same translucent material.
  private var settingsButton: some View {
    Button {
      HapticManager.light()
      showingSettings = true
    } label: {
      Image(systemName: "gearshape")
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(.white.opacity(0.95))
        .frame(width: 34, height: 34)
        .background(
          Circle()
            .fill(Color.white.opacity(0.12))
            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        )
    }
    .buttonStyle(.plain)
  }

  // MARK: - Refresh control

  /// Top-right pill: refresh icon + remaining-count badge. Tapping
  /// either spends a refresh or triggers the paywall depending on
  /// remaining quota and subscription tier.
  private var refreshButton: some View {
    let isPremium = subscriptionManager.isPremiumUser
    let isDepleted = remainingRefreshes <= 0
    let showPaywallOnTap = isDepleted && !isPremium

    return Button(action: handleRefreshTap) {
      HStack(spacing: 6) {
        Image(systemName: showPaywallOnTap ? "lock.fill" : "arrow.clockwise")
          .font(.system(size: 14, weight: .semibold))
        Text("\(remainingRefreshes)")
          .font(.system(size: 13, weight: .semibold))
          .monospacedDigit()
      }
      .foregroundColor(.white.opacity(isDepleted && isPremium ? 0.35 : 0.95))
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(
        Capsule()
          .fill(Color.white.opacity(0.12))
          .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
      )
    }
    .buttonStyle(.plain)
    // Premium user with 0 left → nothing useful to do, so disable the
    // button. Free user with 0 left still receives the tap → paywall.
    .disabled(isDepleted && isPremium)
  }

  private func handleRefreshTap() {
    let isPremium = subscriptionManager.isPremiumUser

    // Premium + depleted is unreachable here (button is disabled), so
    // we only branch between "spend a refresh" and "free user out of
    // quota → paywall".
    if AccessControl.shared.registerRefreshIfAllowed(isPremium: isPremium) {
      advanceToNextQuote()
      remainingRefreshes = AccessControl.shared.remainingRefreshes(isPremium: isPremium)
      HapticManager.medium()
    } else {
      HapticManager.warning()
      onRequirePaywall()
    }
  }

  private func advanceToNextQuote() {
    let next = clamp(viewModel.currentPosition + 1)
    withAnimation(.easeInOut(duration: 0.28)) {
      viewModel.currentPosition = next
    }
  }

  // MARK: - Lifecycle helpers

  private func handleAppear() {
    AccessControl.shared.resetIfNeeded()
    // Detect cross-midnight when the user returns to Feed from another
    // tab: re-pin the rotation to today and snap back to position 0.
    // `.onChange(of: currentDayOfYear)` doesn't fire while the Feed
    // isn't on screen, so this onAppear path is the second safety net.
    let now = Date()
    if !Calendar.current.isDate(viewModel.referenceDate, inSameDayAs: now) {
      viewModel.updateReferenceDate(now)
      viewModel.currentPosition = 0
      persistedIndex = 0
    } else {
      // `refreshesUsedToday` is the persisted source of truth for
      // "how far the user has advanced today" (every refresh tap
      // increments it by 1 in lock-step with `currentPosition`). The
      // in-memory `persistedIndex` resets across App kills, so always
      // rebase on the persisted counter to survive cold-starts;
      // otherwise Feed snaps back to "Quote of the Day" after a kill
      // even though Widget kept the post-refresh quote.
      let restored = AccessControl.shared.refreshesUsedToday
      viewModel.currentPosition = restored
      persistedIndex = restored
    }
    remainingRefreshes = AccessControl.shared
      .remainingRefreshes(isPremium: subscriptionManager.isPremiumUser)
    // First entry into Feed in this session — push the current quote
    // to the widget too. `onChange(of: currentPosition)` only fires on
    // *changes* so we wouldn't otherwise sync the initial position 0.
    syncCurrentQuoteToWidget()
  }

  /// Push the quote currently in focus to the shared payload backing
  /// the widget. The gradient index is `stableGradientIndex` (today's
  /// "Quote of the Day" position) rather than the rawIndex of the
  /// currently-visible quote, so the widget background matches the in-app
  /// canvas and doesn't drift when the user taps refresh.
  private func syncCurrentQuoteToWidget() {
    guard let quote = viewModel.quote(at: viewModel.currentPosition) else { return }
    DailyQuoteSync.update(quote: quote, gradientIndex: stableGradientIndex)
  }

  /// Always render the theme's first palette variation. Gradient
  /// themes ship 5 palettes each (index 0…4), but the theme picker's
  /// `previewSwatch` shows `palettes[0]`, so that's what the user
  /// effectively picked. Pinning every Feed/Widget/Favorite/Share
  /// surface to index 0 keeps the visual identical to the picker —
  /// the canvas only ever changes when the user explicitly picks a
  /// different theme in Settings.
  private var stableGradientIndex: Int { 0 }

  /// Snap `position` into today's reachable range. position 0 is the
  /// "Quote of the Day"; each subsequent refresh moves the ceiling up
  /// by one. The bound is `refreshesUsedToday` because every
  /// `advanceToNextQuote` is paired with `registerRefreshIfAllowed`,
  /// so `currentPosition == refreshesUsedToday` is an invariant.
  private func clamp(_ position: Int) -> Int {
    let used = AccessControl.shared.refreshesUsedToday
    return max(0, min(position, used))
  }

  private var currentDayOfYear: Int {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    return calendar.ordinality(of: .day, in: .year, for: startOfDay) ?? 0
  }
}
