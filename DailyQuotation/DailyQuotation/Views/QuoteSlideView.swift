import SwiftUI

struct QuoteSlideView: View {
  let quote: Quote
  let index: Int
  @ObservedObject var favoritesManager = FavoritesManager.shared
  let onToggleFavorite: () -> Void
  @Binding var appearance: AppearanceSettings

  @State private var showSettings = false
  @State private var isBouncing = false

  private var isFavorite: Bool {
    favoritesManager.isFavorite(quote)
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
    }
    .padding(.horizontal, 32)
    .frame(maxWidth: 600)
  }

  private var categoryBadge: some View {
    Text(index == 0 ? "Quote of the Day" : (quote.category ?? "Inspiration"))
      .font(.system(size: 10, weight: .bold))
      .tracking(2)
      .foregroundColor(.white.opacity(0.7))
      .padding(.horizontal, 16)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(Color.white.opacity(0.1))
          .background(
            Capsule()
              .fill(.ultraThinMaterial)
          )
          .overlay(
            Capsule()
              .stroke(Color.white.opacity(0.1), lineWidth: 1)
          )
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
          Image(systemName: isFavorite ? "heart.fill" : "heart")
            .font(.system(size: 24))
            .foregroundColor(isFavorite ? .red : .white)
            .frame(width: 56, height: 56)
            .background(
              Circle()
                .fill(isFavorite ? Color.white : Color.white.opacity(0.1))
                .background(
                  Circle()
                    .fill(.ultraThinMaterial)
                )
                .overlay(
                  Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            )
            .scaleEffect(isBouncing ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isBouncing)
            .shadow(color: isFavorite ? .red.opacity(0.3) : .clear, radius: 10)
        }
      }

      // Style button
      VStack(spacing: 8) {
        Button(action: {
          withAnimation(.spring()) {
            showSettings.toggle()
            if showSettings {
              HapticManager.selection()
            }
          }
        }) {
          Image(systemName: "textformat")
            .font(.system(size: 24))
            .foregroundColor(showSettings ? .black : .white)
            .frame(width: 56, height: 56)
            .background(
              Circle()
                .fill(showSettings ? Color.white : Color.white.opacity(0.1))
                .background(
                  Circle()
                    .fill(.ultraThinMaterial)
                )
                .overlay(
                  Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            )
        }
      }
    }
  }

  private func handleSaveClick() {
    HapticManager.light()

    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
      isBouncing = true
    }

    onToggleFavorite()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      withAnimation {
        isBouncing = false
      }
    }
  }

  private var settingsOverlay: some View {
    Group {
      if showSettings {
        Color.black.opacity(0.3)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation {
              showSettings = false
            }
          }

        VStack(spacing: 16) {
          // Font options
          VStack(alignment: .leading, spacing: 8) {
            Text("FONT")
              .font(.system(size: 10, weight: .bold))
              .tracking(2)
              .foregroundColor(.white.opacity(0.5))
              .padding(.leading, 4)

            HStack(spacing: 8) {
              ForEach(FontFamily.allCases, id: \.self) { font in
                Button(action: {
                  withAnimation {
                    appearance.font = font
                    HapticManager.selection()
                  }
                }) {
                  Text(font.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(appearance.font == font ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                      RoundedRectangle(cornerRadius: 8)
                        .fill(
                          appearance.font == font
                            ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    )
                }
              }
            }
          }

          // Size options
          VStack(alignment: .leading, spacing: 8) {
            Text("SIZE")
              .font(.system(size: 10, weight: .bold))
              .tracking(2)
              .foregroundColor(.white.opacity(0.5))
              .padding(.leading, 4)

            HStack(spacing: 8) {
              ForEach(TextSize.allCases, id: \.self) { size in
                Button(action: {
                  withAnimation {
                    appearance.size = size
                    HapticManager.selection()
                  }
                }) {
                  Text("A")
                    .font(
                      .system(
                        size: size == .small ? 12 : size == .medium ? 16 : 20, weight: .medium)
                    )
                    .foregroundColor(appearance.size == size ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                      RoundedRectangle(cornerRadius: 8)
                        .fill(
                          appearance.size == size
                            ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    )
                }
              }
            }
          }
        }
        .padding(16)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.6))
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        )
        .padding(.horizontal, 32)
        .padding(.bottom, 140)
        .transition(.scale.combined(with: .opacity))
      }
    }
  }
}
