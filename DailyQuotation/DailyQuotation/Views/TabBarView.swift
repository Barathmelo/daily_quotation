import SwiftUI

struct TabBarView: View {
  let currentView: AppView
  let onSelect: (AppView) -> Void

  @Namespace private var tabAnimation
  private let tabSpring = Animation.spring(
    response: 0.15,
    dampingFraction: 0.82,
    blendDuration: 0.25)

  var body: some View {
    tabBarContent
      .padding(.horizontal, 80)
      .animation(tabSpring, value: currentView)
  }

  @ViewBuilder
  private var tabBarContent: some View {
    HStack(spacing: 8) {
      ForEach(AppView.allCases, id: \.self) { view in
        tabButton(for: view)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .glassEffect(.clear.interactive(), in: .capsule)
  }

  private func tabButton(for view: AppView) -> some View {
    let isSelected = currentView == view
    let accentColor: Color = view == .favorites ? .red : .white

    return Button {
      guard currentView != view else { return }
      HapticManager.light()
      onSelect(view)
    } label: {
      VStack(spacing: 6) {
        ZStack {
          if isSelected {
            Circle()
              .fill(accentColor.opacity(0.15))
              .frame(width: 44, height: 44)
              .matchedGeometryEffect(id: "tabSelection", in: tabAnimation)
          }

          Image(systemName: iconName(for: view, isSelected: isSelected))
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(isSelected ? accentColor : Color(white: 0.6))
            .symbolEffect(.bounce, value: isSelected)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 4)
      .padding(.vertical, 4)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func iconName(for view: AppView, isSelected: Bool) -> String {
    switch view {
    case .feed:
      return isSelected ? "square.stack.fill" : "square.stack"
    case .favorites:
      return isSelected ? "heart.fill" : "heart"
    }
  }

  private func label(for view: AppView) -> String {
    switch view {
    case .feed:
      return "Daily"
    case .favorites:
      return "Saved"
    }
  }
}
