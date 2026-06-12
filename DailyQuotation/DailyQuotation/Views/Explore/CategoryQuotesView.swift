import SwiftUI

/// List of all quotes belonging to a single category. Quotes are passed
/// in pre-filtered so this view stays trivial.
struct CategoryQuotesView: View {
  let categoryName: String
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
    .navigationTitle(categoryName.capitalized)
    .navigationBarTitleDisplayMode(.inline)
    .toolbarColorScheme(.dark, for: .navigationBar)
  }
}
