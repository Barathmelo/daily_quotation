import SwiftUI

/// The image source for share-card export.
///
/// Rendered into a `UIImage` offscreen via `ImageRenderer`, so it MUST
/// NOT rely on `@EnvironmentObject`, `@Environment(\.dismiss)`, or any
/// other view-hierarchy state — `ImageRenderer` evaluates it without a
/// surrounding scene.
///
/// The canvas is designed at 1080×1920 (9:16 portrait). All sizes below
/// are absolute design points at that resolution; the preview renderer
/// scales the whole view down uniformly via `scaleEffect`.
struct ShareCardView: View {
  let quote: Quote
  let gradientIndex: Int
  let theme: QuoteTheme
  let includeWatermark: Bool

  // MARK: - Body

  var body: some View {
    ZStack {
      theme.background(for: gradientIndex)

      backgroundDecorations

      VStack(spacing: 0) {
        Spacer(minLength: 0)

        decorativeQuoteMark
          .padding(.bottom, 24)

        Text(quote.text)
          .font(.system(size: quoteFontSize, weight: .medium, design: .serif))
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .lineSpacing(quoteFontSize * 0.18)
          .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 8)
          .padding(.horizontal, 80)
          .minimumScaleFactor(0.7)
          .fixedSize(horizontal: false, vertical: true)

        divider
          .padding(.top, 56)
          .padding(.bottom, 36)

        Text(quote.author.uppercased())
          .font(.system(size: 36, weight: .medium, design: .rounded))
          .tracking(5)
          .foregroundColor(.white.opacity(0.92))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 80)
          .minimumScaleFactor(0.7)
          .lineLimit(2)

        Spacer(minLength: 0)

        if includeWatermark {
          watermark
            .padding(.bottom, 90)
        }
      }
      .padding(.vertical, 120)
    }
    .frame(width: 1080, height: 1920)
  }

  // MARK: - Pieces

  private var decorativeQuoteMark: some View {
    Text("\u{201C}")
      .font(.system(size: 280, weight: .bold, design: .serif))
      .foregroundColor(.white.opacity(0.22))
      .frame(height: 140, alignment: .center)
      .offset(y: 20)
  }

  private var divider: some View {
    Rectangle()
      .fill(Color.white.opacity(0.45))
      .frame(width: 96, height: 3)
      .cornerRadius(1.5)
  }

  private var watermark: some View {
    HStack(spacing: 12) {
      Image(systemName: "quote.opening")
        .font(.system(size: 26, weight: .semibold))
      Text("Quoteary")
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .tracking(1)
    }
    .foregroundColor(.white.opacity(0.78))
    .padding(.horizontal, 28)
    .padding(.vertical, 14)
    .background(
      Capsule()
        .fill(Color.white.opacity(0.08))
        .overlay(
          Capsule()
            .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    )
  }

  private var backgroundDecorations: some View {
    ZStack {
      Circle()
        .fill(Color.white.opacity(0.18))
        .frame(width: 760, height: 760)
        .blur(radius: 200)
        .offset(x: -260, y: -440)

      Circle()
        .fill(Color.white.opacity(0.18))
        .frame(width: 760, height: 760)
        .blur(radius: 200)
        .offset(x: 260, y: 440)
    }
  }

  // MARK: - Type scale

  /// Pick a quote font size that gives short quotes serious presence
  /// while keeping the longest ones legible without overflow.
  /// All measured at 1080-pt-wide design space.
  private var quoteFontSize: CGFloat {
    switch quote.text.count {
    case ..<60: return 92
    case 60..<110: return 78
    case 110..<160: return 66
    case 160..<220: return 56
    default: return 48
    }
  }
}
