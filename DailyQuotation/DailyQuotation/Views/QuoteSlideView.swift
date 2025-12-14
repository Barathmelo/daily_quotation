import SwiftUI

struct QuoteSlideView: View {
  let quote: Quote
  let index: Int
  let isToday: Bool
  let isPremium: Bool
  let onRequirePaywall: () -> Void
  @ObservedObject var favoritesManager = FavoritesManager.shared
  let onToggleFavorite: () -> Void
  @Binding var appearance: AppearanceSettings

  @State private var showSettings = false
  @State private var favoriteVisualOverride: Bool? = nil

  private var isFavorite: Bool {
    favoritesManager.isFavorite(quote)
  }

  private var displayedFavoriteState: Bool {
    favoriteVisualOverride ?? isFavorite
  }

  var body: some View {
    ZStack {
      GradientColors.gradient(for: index)
        .ignoresSafeArea(.all)

      // Background decorative elements
      backgroundDecorations
        .ignoresSafeArea(.all)

      GeometryReader { geometry in
        VStack(spacing: 0) {
          Spacer()

          contentContainer

          Spacer()
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
      }
      .padding(.bottom, 120)
    }
    .ignoresSafeArea(.all)
    .overlay(
      settingsOverlay,
      alignment: .bottom
    )
    .onChange(of: isFavorite) { _ in
      favoriteVisualOverride = nil
    }
  }

  private var backgroundDecorations: some View {
    ZStack {
      Circle()
        .fill(Color.white.opacity(0.2))
        .frame(width: 400, height: 400)
        .blur(radius: 100)
        .offset(x: -150, y: -150)

      Circle()
        .fill(Color.white.opacity(0.2))
        .frame(width: 400, height: 400)
        .blur(radius: 100)
        .offset(x: 150, y: 150)
    }
    .opacity(0.2)
  }

  private var contentContainer: some View {
    VStack(spacing: 24) {
      // Category badge
      categoryBadge

      // Quote text
      Text("\"\(quote.text)\"")
        .font(fontForAppearance)
        .fontWeight(.regular)
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .lineSpacing(8)
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)

      // Divider
      Rectangle()
        .fill(Color.white.opacity(0.3))
        .frame(width: 48, height: 2)
        .cornerRadius(1)

      // Author
      Text(quote.author)
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(.white.opacity(0.9))
        .tracking(1)

      // Action buttons
      actionButtons
        .padding(.top, 16)
    }
    .padding(.horizontal, 32)
    .frame(maxWidth: 600)
  }

  private var categoryBadge: some View {
    let categoryText = isToday ? "Quote of the Day" : (quote.category ?? "Inspiration")

    return Text(categoryText.uppercased())
      .font(.system(size: 13, weight: .semibold, design: .rounded))
      .tracking(2)
      .foregroundColor(.white)
      .padding(.horizontal, 22)
      .padding(.vertical, 10)
      .background(
        Capsule()
          .fill(
            LinearGradient(
              colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay(
            Capsule()
              .stroke(Color.white.opacity(0.35), lineWidth: 1)
          )
          .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
      )
  }

  private var fontForAppearance: Font {
    switch appearance.font {
    case .serif:
      return .system(size: appearance.size.fontSize, design: .serif)
    case .sans:
      return .system(size: appearance.size.fontSize, design: .rounded)
    case .mono:
      return .system(size: appearance.size.fontSize, design: .monospaced)
    }
  }

  private var actionButtons: some View {
    HStack(spacing: 32) {
      // Save button
      VStack(spacing: 8) {
        Button(action: handleSaveClick) {
          Image(systemName: displayedFavoriteState ? "heart.fill" : "heart")
            .font(.system(size: 24))
            .foregroundColor(displayedFavoriteState ? .red : .white)
            .opacity(displayedFavoriteState ? 1 : 0.9)
            .frame(width: 56, height: 56)
            .background(
              Circle()
                .fill(frostedCircleGradient(isActive: displayedFavoriteState))
                .overlay(
                  Circle()
                    .stroke(
                      Color.white.opacity(displayedFavoriteState ? 0.15 : 0.15),
                      lineWidth: displayedFavoriteState ? 1.5 : 1
                    )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
            )
        }
      }

      // Style button
      VStack(spacing: 8) {
        Button(action: {
          let shouldShow = !showSettings
          withAnimation(settingsAnimation) {
            showSettings = shouldShow
          }
          if shouldShow {
            HapticManager.selection()
          }
        }) {
          Image(systemName: "textformat")
            .font(.system(size: 24))
            .foregroundColor(.white)
            .opacity(showSettings ? 1 : 0.9)
            .frame(width: 56, height: 56)
            .background(
              Circle()
                .fill(frostedCircleGradient(isActive: showSettings))
                .overlay(
                  Circle()
                    .stroke(
                      Color.white.opacity(showSettings ? 0.15 : 0.15),
                      lineWidth: showSettings ? 1.5 : 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
            )
        }
      }
    }
  }

  private func frostedCircleGradient(isActive: Bool) -> LinearGradient {
    LinearGradient(
      colors: [
        Color.white.opacity(isActive ? 0.15 : 0.15),
        Color.white.opacity(isActive ? 0.15 : 0.08),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private func handleSaveClick() {
    HapticManager.light()
    let nextState = !(favoriteVisualOverride ?? isFavorite)

    withAnimation(.easeOut(duration: 0.12)) {
      favoriteVisualOverride = nextState
    }

    onToggleFavorite()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      if favoriteVisualOverride == nextState {
        favoriteVisualOverride = nil
      }
    }
  }

  private var settingsOverlay: some View {
    Group {
      if showSettings {
        overlayContainer
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .animation(settingsAnimation, value: showSettings)
      }
    }
  }

  private var overlayContainer: some View {
    ZStack(alignment: .bottom) {
      overlayBackground
      appearancePanel
    }
  }

  private var overlayBackground: some View {
    Color.black.opacity(0.35)
      .ignoresSafeArea()
      .onTapGesture {
        closeSettings()
      }
  }

  private var appearancePanel: some View {
    VStack(alignment: .leading, spacing: 20) {
      appearanceHeader
      typefaceSection
      sizeSection
    }
    .padding(24)
    .frame(maxWidth: 520)
    .background(
      RoundedRectangle(cornerRadius: 32)
        .fill(Color.black.opacity(0.9))
        .overlay(
          RoundedRectangle(cornerRadius: 32)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    )
    .padding(.horizontal, 20)
    .padding(.bottom, 110)
  }

  private var appearanceHeader: some View {
    HStack(alignment: .center) {
      Text("Appearance")
        .font(.system(size: 24, weight: .bold, design: .rounded))
        .foregroundColor(.white)
      Spacer()
      Button(action: closeSettings) {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.white)
          .padding(10)
          .background(
            Circle()
              .fill(Color.white.opacity(0.08))
          )
      }
    }
  }

  private var typefaceSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionLabel("TYPEFACE")
      HStack(spacing: 12) {
        ForEach(FontFamily.allCases, id: \.self) { font in
          typefaceButton(for: font)
        }
      }
    }
  }

  private var sizeSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionLabel("SIZE")
      HStack(spacing: 12) {
        ForEach(TextSize.allCases, id: \.self) { size in
          sizeButton(for: size)
        }
      }
      .padding(6)
      .background(
        RoundedRectangle(cornerRadius: 26)
          .fill(Color.white.opacity(0.03))
      )
    }
  }

  private func sectionLabel(_ title: String) -> some View {
    Text(title)
      .font(.system(size: 14, weight: .semibold))
      .tracking(1)
      .foregroundColor(.white.opacity(0.5))
      .padding(.leading, 2)
  }

  private func typefaceButton(for font: FontFamily) -> some View {
    let isSelected = appearance.font == font

    return Button(action: {
      guard AccessControl.shared.canUseFont(font: font, isPremium: isPremium) else {
        onRequirePaywall()
        return
      }
      withAnimation(.easeOut(duration: 0.15)) {
        appearance.font = font
        HapticManager.selection()
      }
    }) {
      VStack(spacing: 6) {
        Text("Aa")
          .font(.system(size: 22, weight: .semibold, design: design(for: font)))
        Text(font.displayName)
          .font(.system(size: 13, weight: .medium))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .foregroundColor(isSelected ? .black : .white.opacity(0.8))
      .background(
        RoundedRectangle(cornerRadius: 22)
          .fill(isSelected ? Color.white : Color.white.opacity(0.06))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 22)
          .stroke(Color.white.opacity(isSelected ? 0.4 : 0.1), lineWidth: 1)
      )
    }
  }

  private func sizeButton(for size: TextSize) -> some View {
    let isSelected = appearance.size == size

    return Button(action: {
      withAnimation(.easeOut(duration: 0.15)) {
        appearance.size = size
        HapticManager.selection()
      }
    }) {
      Text("Aa")
        .font(.system(size: fontSize(for: size), weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .foregroundColor(isSelected ? .black : .white.opacity(0.8))
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(isSelected ? Color.white : Color.white.opacity(0.06))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white.opacity(isSelected ? 0.4 : 0.1), lineWidth: 1)
        )
    }
  }

  private func closeSettings() {
    withAnimation(settingsAnimation) {
      showSettings = false
    }
  }

  private var settingsAnimation: Animation {
    .spring(response: 0.25, dampingFraction: 0.85)
  }

  private func design(for font: FontFamily) -> Font.Design {
    switch font {
    case .serif:
      return .serif
    case .sans:
      return .rounded
    case .mono:
      return .monospaced
    }
  }

  private func fontSize(for size: TextSize) -> CGFloat {
    switch size {
    case .small:
      return 16
    case .medium:
      return 20
    case .large:
      return 24
    }
  }
}
