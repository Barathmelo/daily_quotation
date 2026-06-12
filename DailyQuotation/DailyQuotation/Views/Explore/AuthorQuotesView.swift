import SwiftUI

/// List of all quotes attributed to a single author. Quotes are passed
/// in pre-filtered so this view stays trivial.
struct AuthorQuotesView: View {
  let authorName: String
  let quotes: [Quote]

  @EnvironmentObject private var subscriptionManager: RevenueCatManager

  var body: some View {
    List {
      ForEach(quotes) { q in
        NavigationLink(value: NavTarget.quote(q)) {
          QuoteListRow(quote: q)
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.black.ignoresSafeArea())
    .navigationTitle(authorName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbarColorScheme(.dark, for: .navigationBar)
  }
}

/// Compact list row reused by both Category and Author drilldowns.
struct QuoteListRow: View {
  let quote: Quote

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("\u{201C}\(quote.text)\u{201D}")
        .font(.system(size: 14, weight: .medium, design: .serif))
        .foregroundStyle(.white)
        .lineLimit(3)
        .multilineTextAlignment(.leading)
      Text(quote.author.uppercased())
        .font(.system(size: 10, weight: .semibold))
        .tracking(1)
        .foregroundStyle(.white.opacity(0.5))
    }
    .padding(.vertical, 6)
    .listRowBackground(Color.white.opacity(0.04))
    .listRowSeparatorTint(Color.white.opacity(0.08))
  }
}
