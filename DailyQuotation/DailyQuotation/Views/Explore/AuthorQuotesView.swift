import SwiftUI

/// List of all quotes attributed to a single author. Quotes are passed
/// in pre-filtered so this view stays trivial.
struct AuthorQuotesView: View {
  let authorName: String
  let quotes: [Quote]

  @EnvironmentObject private var subscriptionManager: RevenueCatManager

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(quotes) { q in
          NavigationLink(value: NavTarget.quote(q)) {
            QuoteListRow(quote: q)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(16)
    }
    .background(Color.black.ignoresSafeArea())
    .navigationTitle(authorName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbarColorScheme(.dark, for: .navigationBar)
  }
}

/// Compact card row reused by both Category and Author drilldowns.
/// Self-contained styling (no listRow* dependencies) so it works in
/// any container — List, ScrollView, or LazyVStack.
struct QuoteListRow: View {
  let quote: Quote

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("\u{201C}\(quote.text)\u{201D}")
        .font(.system(size: 15, weight: .medium, design: .serif))
        .foregroundStyle(.white)
        .lineLimit(3)
        .multilineTextAlignment(.leading)
      HStack {
        Text(quote.author.uppercased())
          .font(.system(size: 11, weight: .semibold))
          .tracking(1)
          .foregroundStyle(.white.opacity(0.5))
        if let category = quote.category, !category.isEmpty {
          Text("• \(category.capitalized)")
            .font(.system(size: 11))
            .foregroundStyle(.white.opacity(0.35))
        }
        Spacer()
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(Color.white.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    )
  }
}
