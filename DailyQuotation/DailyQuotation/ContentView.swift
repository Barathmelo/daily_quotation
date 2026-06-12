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
  /// Locked once at the start of a drag so a midway twitch never flips
  /// the tab between horizontal-swipe and vertical-scroll behavior.
  @State private var lockedDragDirection: DragDirection? = nil

  init() {
    DailyQuoteSync.syncTodayIfNeeded()
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
    .asymmetric(
      insertion: .move(edge: transitionDirection == .forward ? .trailing : .leading)
        .combined(with: .opacity),
      removal: .move(edge: transitionDirection == .forward ? .leading : .trailing)
        .combined(with: .opacity)
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
      ExploreView()
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
    DragGesture(minimumDistance: 45)
      .onChanged { value in
        if lockedDragDirection == nil {
          let absW = abs(value.translation.width)
          let absH = abs(value.translation.height)
          // Require clear horizontal intent (≥1.5x vertical) to claim
          // the drag for tab switching; otherwise treat as vertical
          // and stay out of the way.
          lockedDragDirection = absW > absH * 1.5 ? .horizontal : .vertical
        }

        guard lockedDragDirection == .horizontal else { return }
        isInteracting = true
        translation = value.translation.width
      }
      .onEnded { value in
        defer { lockedDragDirection = nil }

        if lockedDragDirection == .horizontal {
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
