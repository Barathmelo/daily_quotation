import SwiftUI

/// List of all quotes belonging to a single category. Quotes are passed
/// in pre-filtered so this view stays trivial.
struct CategoryQuotesView: View {
  let categoryName: String
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
      .readableWidth()
    }
    .background(Color.black.ignoresSafeArea())
    .navigationTitle(categoryName.capitalized)
    .navigationBarTitleDisplayMode(.inline)
    .toolbarColorScheme(.dark, for: .navigationBar)
    .hidesFloatingTabBar()
  }
}
