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
    HStack(spacing: 0) {
      ForEach(AppView.allCases, id: \.self) { view in
        tabButton(for: view)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 8)
//    .background(GlassBarBackground())
    .padding(.horizontal, 26)
    .animation(tabSpring, value: currentView)
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
        Image(systemName: iconName(for: view, isSelected: isSelected))
          .font(.system(size: 26, weight: .medium))
          .foregroundColor(isSelected ? accentColor : Color(white: 0.6))
          .frame(width: 36, height: 36)
          .scaleEffect(isSelected ? 1.12 : 1.0)

//        Text(label(for: view))
//          .font(.system(size: 13, weight: .semibold))
//          .tracking(1)
//          .foregroundColor(isSelected ? accentColor : Color(white: 0.6))
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 4)
      .padding(.top, 2)
      .padding(.bottom, 10)
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

// MARK: - Glass Background

private struct GlassBarBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  private var tintOpacity: Double {
    colorScheme == .dark ? 0.18 : 0.08
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 32, style: .continuous)
      .fill(.ultraThinMaterial)
      .background(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .fill(Color.white.opacity(tintOpacity))
          .blur(radius: 20)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .stroke(Color.white.opacity(colorScheme == .dark ? 0.25 : 0.3), lineWidth: 1)
          .blendMode(.overlay)
      )
      .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
      .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1)
  }
}
