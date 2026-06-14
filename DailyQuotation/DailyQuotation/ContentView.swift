import SwiftUI

struct ContentView: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @StateObject private var appearanceManager = AppearanceManager.shared
  @State private var currentView: AppView = .feed
  @State private var transitionDirection: TabTransitionDirection = .forward
  @State private var translation: CGFloat = 0
  @State private var isInteracting = false
  @State private var feedCurrentIndex: Int = 0
  @State private var showPaywall = false
  @State private var isTabBarHidden = false
  /// `true` while a descendant horizontal ScrollView is actively being
  /// dragged. While set, our own tab-switch gesture stays out of the way.
  @State private var isChildClaimingHorizontalDrag = false
  /// Locked once at the start of a drag so a midway twitch never flips
  /// the tab between horizontal-swipe and vertical-scroll behavior.
  @State private var lockedDragDirection: DragDirection? = nil

  init() {
    DailyQuoteSync.syncTodayIfNeeded()
    // Stamp the install date the very first time the app launches so
    // the History Calendar can later forbid picking days before the
    // user actually started using the app.
    FirstLaunchTracker.recordIfNeeded()
  }

  private let tabSwitchAnimation = Animation.easeInOut(duration: 0.28)
  private let translationSpring = Animation.interactiveSpring(
    response: 0.32,
    dampingFraction: 0.82,
    blendDuration: 0.1)

  private var appearance: Binding<AppearanceSettings> {
    Binding(
      get: { appearanceManager.settings },
      set: { appearanceManager.updateSettings($0) }
    )
  }

  var body: some View {
    ZStack {
      contentLayer

      if !isTabBarHidden {
        VStack {
          Spacer()
          TabBarView(
            currentView: currentView,
            onSelect: handleTabSelection
          )
          .padding(.bottom, 32)
        }
        .padding(.horizontal, 0)
        .ignoresSafeArea(edges: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .background(Color.black.ignoresSafeArea())
    .onAppear(perform: syncDailyQuoteAndIndex)
    .onPreferenceChange(TabBarHiddenPreferenceKey.self) { hidden in
      withAnimation(.easeInOut(duration: 0.22)) {
        isTabBarHidden = hidden
      }
    }
    .onPreferenceChange(HorizontalDragClaimedPreferenceKey.self) { claimed in
      isChildClaimingHorizontalDrag = claimed
    }
    .sheet(isPresented: $showPaywall) {
      PaywallView()
        .environmentObject(subscriptionManager)
    }
  }

  // MARK: - Content Layer with Gesture
  private var contentLayer: some View {
    tabContentLayer
      .offset(x: translation)
      .animation(translationSpring, value: translation)
      .simultaneousGesture(dragGesture)
      .ignoresSafeArea()
  }

  // MARK: - Tab Content
  @ViewBuilder
  private var tabContentLayer: some View {
    ZStack {
      if currentView == .feed {
        pageView(for: .feed)
          .transition(pageTransition)
          .zIndex(currentView == .feed ? 1 : 0)
      }

      if currentView == .explore {
        pageView(for: .explore)
          .transition(pageTransition)
          .zIndex(currentView == .explore ? 1 : 0)
      }

      if currentView == .favorites {
        pageView(for: .favorites)
          .transition(pageTransition)
          .zIndex(currentView == .favorites ? 1 : 0)
      }
    }
  }

  private var pageTransition: AnyTransition {
    // Pure horizontal slide, no opacity fade. The combined .opacity
    // version had each tab cross-fade through half-transparency mid-
    // transition, briefly revealing the black background behind both
    // views and reading as a "flash" / flicker.
    .asymmetric(
      insertion: .move(edge: transitionDirection == .forward ? .trailing : .leading),
      removal: .move(edge: transitionDirection == .forward ? .leading : .trailing)
    )
  }

  // MARK: - Pages
  @ViewBuilder
  private func pageView(for view: AppView) -> some View {
    switch view {
    case .feed:
      FeedView(
        appearance: appearance,
        persistedIndex: $feedCurrentIndex,
        isPremium: subscriptionManager.isPremiumUser,
        onRequirePaywall: { showPaywall = true }
      )
      .id(subscriptionManager.isPremiumUser)
      .environmentObject(subscriptionManager)
    case .explore:
      ExploreView(feedCurrentIndex: $feedCurrentIndex)
        .environmentObject(subscriptionManager)
    case .favorites:
      FavoritesListView(appearance: appearance)
        .environmentObject(subscriptionManager)
    }
  }

  // MARK: - Gestures
  ///
  /// Active on every tab. We use `.simultaneousGesture` upstream so
  /// child gestures (FeedView's vertical drag, scroll views, etc.)
  /// still get their events. The relatively large `minimumDistance`
  /// (45pt) gives horizontal ScrollViews (category / author pills on
  /// Explore) the first ~45pt of slop before this gesture even wakes
  /// up — by then the ScrollView has already claimed the drag.
  ///
  /// We also lock the direction on the first onChanged call: if the
  /// first decisive movement is vertical, this gesture goes dormant
  /// for the rest of the drag, so users scrolling the Explore page
  /// with a slight horizontal jitter don't see the whole tab slide
  /// sideways.
  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 20)
      .onChanged { value in
        // A descendant horizontal ScrollView (Explore pills) is
        // already handling this drag — don't fight it.
        if isChildClaimingHorizontalDrag {
          lockedDragDirection = .vertical
          return
        }

        if lockedDragDirection == nil {
          let absW = abs(value.translation.width)
          let absH = abs(value.translation.height)

          // Hard-block: any meaningful vertical movement disqualifies
          // horizontal — vertical wins ties and near-ties, since
          // misfiring the tab gesture during a vertical list scroll
          // is much more annoying than missing a borderline swipe.
          if absH > 15 {
            lockedDragDirection = .vertical
          } else if absW > 35 && absW > absH * 3 {
            // Horizontal needs a deliberate, mostly-pure horizontal
            // gesture: at least 35pt of horizontal travel AND ≥3x
            // the vertical component. Anything less is treated as
            // "still observing" and the gesture stays dormant until
            // intent becomes clearer.
            lockedDragDirection = .horizontal
          } else {
            return
          }
        }

        guard lockedDragDirection == .horizontal else { return }

        // Mid-drag direction reversal: user started horizontal but now
        // dragged more vertically (an "L" gesture). Treat that as a
        // change of intent — release the horizontal claim, snap the
        // page back to center, and let the rest of the drag flow into
        // the underlying ScrollView.
        let absW = abs(value.translation.width)
        let absH = abs(value.translation.height)
        if absH > absW {
          lockedDragDirection = .vertical
          withAnimation(translationSpring) {
            translation = 0
            isInteracting = false
          }
          return
        }

        isInteracting = true
        // Skip horizontal feedback entirely when the user is dragging
        // past the first or last tab — there's no target tab to switch
        // to, and any rubber-band offset combines with the simultaneous
        // vertical ScrollView scroll inside Favorites/Explore to read
        // as the whole page drifting diagonally. We keep `isInteracting`
        // set so taps on the tab bar still get suppressed mid-drag, but
        // `translation` stays at 0 so the page doesn't move.
        let raw = value.translation.width
        let isOverscroll =
          (raw < 0 && currentView.next() == nil) ||
          (raw > 0 && currentView.previous() == nil)
        guard !isOverscroll else { return }
        translation = raw
      }
      .onEnded { value in
        defer { lockedDragDirection = nil }

        // Only commit a tab switch if the drag was locked horizontal
        // *or* the released gesture is unambiguously horizontal
        // (avoids missing fast, decisive swipes that flew past the
        // 35pt observation window without setting the lock).
        let absW = abs(value.translation.width)
        let absH = abs(value.translation.height)
        let releasedHorizontal = lockedDragDirection == .horizontal
          || (absW > 60 && absW > absH * 3)

        if releasedHorizontal {
          let threshold: CGFloat = 60
          let dragWidth = value.translation.width
          if dragWidth < -threshold {
            onSwipeToNextTab()
          } else if dragWidth > threshold {
            onSwipeToPreviousTab()
          }
        }

        withAnimation(translationSpring) {
          translation = 0
          isInteracting = false
        }
      }
  }

  // MARK: - Tab Actions
  private func handleTabSelection(_ target: AppView) {
    guard target != currentView else { return }
    guard !isInteracting else { return }
    performTransition(to: target)
  }

  private func onSwipeToNextTab() {
    guard let next = currentView.next() else { return }
    performTransition(to: next)
  }

  private func onSwipeToPreviousTab() {
    guard let previous = currentView.previous() else { return }
    performTransition(to: previous)
  }

  private func performTransition(to target: AppView) {
    let direction: TabTransitionDirection =
      target.order > currentView.order ? .forward : .backward

    transitionDirection = direction

    withAnimation(tabSwitchAnimation) {
      currentView = target
    }

    withAnimation(translationSpring) {
      translation = 0
      isInteracting = false
    }
  }

  // MARK: - Daily Quote Sync
  private func syncDailyQuoteAndIndex() {
    DailyQuoteSync.syncTodayIfNeeded()
    feedCurrentIndex = 0
  }
}

private enum DragDirection {
  case horizontal
  case vertical
}

/// Forward → 新页面从右过来  / 当前页面往左
/// Backward → 新页面从左过来 / 当前页面往右
private enum TabTransitionDirection {
  case forward
  case backward
}

#Preview {
  ContentView()
}
