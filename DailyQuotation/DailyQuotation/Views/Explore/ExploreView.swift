import SwiftUI

/// Top-level Explore tab. Always-on search bar at the top; when the
/// query is non-empty the body switches to a results list. Otherwise we
/// surface curated entry points: today's quote, category pills, top
/// authors, and the (premium-gated) History Calendar entry.
struct ExploreView: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager

  @State private var searchText: String = ""
  @State private var debouncedQuery: String = ""
  @State private var debounceTask: Task<Void, Never>?
  @State private var showingHistory = false
  @State private var showingPaywall = false

  private let index = QuoteIndex.shared

  private var todaysQuote: Quote? {
    DailyQuoteSync.loadTodayQuote()
  }

  private var searchResults: [Quote] {
    index.search(debouncedQuery)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          searchField

          if !debouncedQuery.isEmpty {
            searchResultsSection
          } else {
            todaysPickSection
            categoriesSection
            authorsSection
            historyEntrySection
          }

          Color.clear.frame(height: 100)
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
      }
      .background(Color.black.ignoresSafeArea())
      .navigationBarHidden(true)
      .navigationDestination(for: NavTarget.self) { target in
        switch target {
        case .quote(let q):
          QuoteDetailView(quote: q)
            .environmentObject(subscriptionManager)
        case .category(let name, let quotes):
          CategoryQuotesView(categoryName: name, quotes: quotes)
            .environmentObject(subscriptionManager)
        case .author(let name, let quotes):
          AuthorQuotesView(authorName: name, quotes: quotes)
            .environmentObject(subscriptionManager)
        }
      }
      .sheet(isPresented: $showingHistory) {
        HistoryCalendarView()
          .environmentObject(subscriptionManager)
      }
      .sheet(isPresented: $showingPaywall) {
        PaywallView()
          .environmentObject(subscriptionManager)
      }
    }
    .onChange(of: searchText) { _, newValue in
      debounceTask?.cancel()
      debounceTask = Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }
        debouncedQuery = newValue
      }
    }
  }

  // MARK: - Sections

  private var searchField: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.white.opacity(0.6))
      TextField("Search quotes or authors", text: $searchText)
        .foregroundStyle(.white)
        .tint(.cyan)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
      if !searchText.isEmpty {
        Button {
          searchText = ""
          debouncedQuery = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.white.opacity(0.5))
        }
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(Color.white.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
    )
  }

  @ViewBuilder
  private var searchResultsSection: some View {
    if searchResults.isEmpty {
      VStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 32))
          .foregroundStyle(.white.opacity(0.4))
        Text("No matches")
          .foregroundStyle(.white.opacity(0.6))
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 40)
    } else {
      sectionHeader(title: "\(searchResults.count) results")
      LazyVStack(spacing: 12) {
        ForEach(searchResults) { quote in
          NavigationLink(value: NavTarget.quote(quote)) {
            quoteRow(quote)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  @ViewBuilder
  private var todaysPickSection: some View {
    if let q = todaysQuote {
      sectionHeader(title: "Today's Pick")
      NavigationLink(value: NavTarget.quote(q)) {
        quoteRow(q)
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private var categoriesSection: some View {
    sectionHeader(title: "Browse by Category")
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(index.topCategories.prefix(40), id: \.name) { item in
          NavigationLink(value: NavTarget.category(item.name, index.byCategory[item.name] ?? [])) {
            pill(text: item.name.capitalized, badge: "\(item.count)")
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  @ViewBuilder
  private var authorsSection: some View {
    sectionHeader(title: "Top Authors")
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(index.topAuthors.prefix(20), id: \.name) { item in
          NavigationLink(value: NavTarget.author(item.name, index.byAuthor[item.name] ?? [])) {
            pill(text: item.name, badge: "\(item.count)")
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private var historyEntrySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader(title: "Time Travel")
      Button {
        if subscriptionManager.isPremiumUser {
          showingHistory = true
        } else {
          showingPaywall = true
        }
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "calendar")
            .font(.system(size: 22))
            .foregroundStyle(.cyan)
            .frame(width: 36)
          VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
              Text("History Calendar")
                .foregroundStyle(.white)
                .font(.system(size: 16, weight: .semibold))
              if !subscriptionManager.isPremiumUser {
                Image(systemName: "lock.fill")
                  .font(.caption2)
                  .foregroundStyle(.yellow)
              }
            }
            Text(subscriptionManager.isPremiumUser
              ? "Browse past quotes by date"
              : "Premium — open any past day")
              .font(.caption)
              .foregroundStyle(.white.opacity(0.55))
          }
          Spacer()
          Image(systemName: "chevron.right")
            .foregroundStyle(.white.opacity(0.35))
        }
        .padding(16)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Reusable

  private func sectionHeader(title: String) -> some View {
    Text(title)
      .font(.system(size: 13, weight: .semibold))
      .tracking(1.5)
      .foregroundStyle(.white.opacity(0.55))
      .padding(.horizontal, 4)
  }

  private func pill(text: String, badge: String) -> some View {
    HStack(spacing: 6) {
      Text(text)
        .font(.system(size: 14, weight: .medium))
      Text(badge)
        .font(.system(size: 11, weight: .semibold))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.white.opacity(0.15)))
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(
      Capsule()
        .fill(Color.white.opacity(0.08))
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
    )
  }

  private func quoteRow(_ q: Quote) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("\u{201C}\(q.text)\u{201D}")
        .font(.system(size: 15, weight: .medium, design: .serif))
        .foregroundStyle(.white)
        .lineLimit(3)
        .multilineTextAlignment(.leading)
      HStack {
        Text(q.author.uppercased())
          .font(.system(size: 11, weight: .semibold))
          .tracking(1)
          .foregroundStyle(.white.opacity(0.5))
        if let category = q.category, !category.isEmpty {
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

/// Navigation destinations for the Explore stack. Defined here (not as
/// nested type) so CategoryQuotesView / AuthorQuotesView can use the
/// same enum for their own row → detail NavigationLinks.
enum NavTarget: Hashable {
  case quote(Quote)
  case category(String, [Quote])
  case author(String, [Quote])
}
