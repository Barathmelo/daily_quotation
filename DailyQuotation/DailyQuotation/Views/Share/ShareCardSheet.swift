import SwiftUI

/// User-facing sheet that previews the share card and offers a system
/// share menu via `ShareLink`. Renders the underlying `ShareCardView`
/// to a `UIImage` through `ImageRenderer`.
struct ShareCardSheet: View {
  let quote: Quote
  let gradientIndex: Int
  let isPremium: Bool

  @State private var includeWatermark: Bool = true
  @State private var renderedImage: UIImage?
  @Environment(\.dismiss) private var dismiss

  /// Free users cannot drop the watermark, regardless of the toggle.
  private var effectiveWatermark: Bool {
    isPremium ? includeWatermark : true
  }

  private var sourceCard: ShareCardView {
    ShareCardView(
      quote: quote,
      gradientIndex: gradientIndex,
      includeWatermark: effectiveWatermark
    )
  }

  /// Source canvas size that ShareCardView is designed at (also the
  /// exported image's pixel dimensions).
  private let sourceSize = CGSize(width: 1080, height: 1920)

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          scaledPreview
            .padding(.horizontal, 32)

          if isPremium {
            Toggle("Show watermark", isOn: $includeWatermark)
              .tint(.blue)
              .foregroundStyle(.white)
              .padding(.horizontal, 32)
          } else {
            Label("Watermark required for free users", systemImage: "info.circle")
              .font(.caption)
              .foregroundStyle(.white.opacity(0.65))
              .padding(.horizontal, 32)
          }

          shareButton
        }
        .padding(.top, 20)
        .padding(.bottom, 32)
      }
      .background(Color.black.ignoresSafeArea())
      .navigationTitle("Share Quote")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarColorScheme(.dark, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
            .foregroundStyle(.white)
        }
      }
      .task(id: effectiveWatermark) {
        await renderImage()
      }
    }
  }

  /// Scale the 1080×1920 source down to fit the available width while
  /// preserving aspect ratio. `scaleEffect` doesn't change layout
  /// participation, so we wrap it in an outer `.frame` matched to the
  /// geometry to reserve the correct space in the scroll view.
  private var scaledPreview: some View {
    GeometryReader { proxy in
      let scale = proxy.size.width / sourceSize.width
      sourceCard
        .frame(width: sourceSize.width, height: sourceSize.height)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: proxy.size.width, height: sourceSize.height * scale)
    }
    .aspectRatio(sourceSize.width / sourceSize.height, contentMode: .fit)
    .frame(maxWidth: .infinity)
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
  }

  @ViewBuilder
  private var shareButton: some View {
    if let image = renderedImage {
      ShareLink(
        item: Image(uiImage: image),
        preview: SharePreview("Quoteary", image: Image(uiImage: image))
      ) {
        Label("Share", systemImage: "square.and.arrow.up")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(Color.white)
          .foregroundStyle(.black)
          .clipShape(RoundedRectangle(cornerRadius: 16))
      }
      .padding(.horizontal, 32)
    } else {
      ProgressView()
        .tint(.white)
        .padding(.vertical, 18)
    }
  }

  @MainActor
  private func renderImage() async {
    let renderer = ImageRenderer(content: sourceCard)
    renderer.scale = 1
    renderer.proposedSize = ProposedViewSize(width: 1080, height: 1920)
    renderedImage = renderer.uiImage
  }
}
