import SwiftUI

struct ContentView: View {
  @StateObject private var appearanceManager = AppearanceManager.shared
  @State private var currentView: AppView = .feed
  @State private var transitionDirection: TabTransitionDirection = .forward
  @State private var translation: CGFloat = 0
  @State private var isInteracting = false

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

      VStack {
        Spacer()
        TabBarView(
          currentView: currentView,
          onSelect: handleTabSelection
        )
        .padding(.bottom, 16)
      }
      .padding(.horizontal, 0)
      .ignoresSafeArea(edges: .bottom)
    }
    .background(Color.black.ignoresSafeArea())
  }

  // MARK: - Content Layer with Gesture
  private var contentLayer: some View {
    tabContentLayer
      .offset(x: translation)
      .animation(translationSpring, value: translation)
      .gesture(dragGesture)
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
      FeedView(appearance: appearance)
    case .favorites:
      FavoritesListView(appearance: appearance)
    }
  }

  // MARK: - Gestures
  private var dragGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        guard abs(value.translation.width) > abs(value.translation.height) else { return }
        isInteracting = true
        translation = value.translation.width
      }
      .onEnded { value in
        let threshold = UIScreen.main.bounds.width * 0.25
        let dragWidth = value.translation.width

        if dragWidth < -threshold {
          onSwipeToNextTab()
        } else if dragWidth > threshold {
          onSwipeToPreviousTab()
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
