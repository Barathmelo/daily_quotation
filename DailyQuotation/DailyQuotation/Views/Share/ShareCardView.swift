import SwiftUI

/// The image source for share-card export.
///
/// Rendered into a `UIImage` offscreen via `ImageRenderer`, so it MUST
/// NOT rely on `@EnvironmentObject`, `@Environment(\.dismiss)`, or any
/// other view-hierarchy state — `ImageRenderer` evaluates it without a
/// surrounding scene.
struct ShareCardView: View {
  let quote: Quote
  let gradientIndex: Int
  let includeWatermark: Bool

  var body: some View {
    ZStack {
      GradientColors.gradient(for: gradientIndex)

      backgroundDecorations

      VStack(spacing: 28) {
        Spacer()

        Text("\u{201C}\(quote.text)\u{201D}")
          .font(.system(size: 44, weight: .regular, design: .serif))
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .lineSpacing(10)
          .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 6)
          .padding(.horizontal, 60)

        Rectangle()
          .fill(Color.white.opacity(0.35))
          .frame(width: 80, height: 2)
          .cornerRadius(1)

        Text(quote.author.uppercased())
          .font(.system(size: 22, weight: .medium, design: .rounded))
          .tracking(2.5)
          .foregroundColor(.white.opacity(0.9))

        Spacer()

        if includeWatermark {
          watermark
            .padding(.bottom, 60)
        }
      }
      .padding(.horizontal, 40)
    }
    .frame(width: 1080, height: 1920)
  }

  private var backgroundDecorations: some View {
    ZStack {
      Circle()
        .fill(Color.white.opacity(0.18))
        .frame(width: 700, height: 700)
        .blur(radius: 200)
        .offset(x: -250, y: -400)

      Circle()
        .fill(Color.white.opacity(0.18))
        .frame(width: 700, height: 700)
        .blur(radius: 200)
        .offset(x: 250, y: 400)
    }
  }

  private var watermark: some View {
    HStack(spacing: 10) {
      Image(systemName: "quote.opening")
        .font(.system(size: 22, weight: .semibold))
      Text("Quoteary")
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .tracking(1)
    }
    .foregroundColor(.white.opacity(0.85))
  }
}
