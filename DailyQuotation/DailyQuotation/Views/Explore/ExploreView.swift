import SwiftUI

/// Top-level Explore tab. Surfaces curated entry points: today's quote
/// (matches the first card of Feed for the current subscription tier),
/// premium-gated category and author drilldowns, and the History
/// Calendar entry.
struct ExploreView: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  /// Mirrors `ContentView.feedCurrentIndex` so "Today's Pick" follows
  /// whichever quote the user is currently looking at on Feed (after
  /// any number of refresh taps), not just position 0.
  @Binding var feedCurrentIndex: Int

  @State private var navigationPath = NavigationPath()
  @State private var showingHistory = false
  @State private var showingPaywall = false
  /// Signaled by `ContentView` while a horizontal tab-switch drag is
  /// in flight. We mirror it onto the outer `ScrollView`'s
  /// `.scrollDisabled` so the page can't rubber-band vertically while
  /// it's already being translated sideways.
  @Environment(\.isHorizontalTabSwipeActive) private var isHorizontalTabSwipeActive

  private let index = QuoteIndex.shared

  /// "Today's Pick" mirrors the card the user is currently looking at
  /// on Feed. With the new refresh model, that may not be position 0
  /// anymore — if they've refreshed N times today they're on position N.
  private var todaysQuote: Quote? {
    // Always construct with isPremium=true so the viewmodel exposes the
    // full 20-quote rotation, matching FeedView. The actual visibility
    // gating happens in FeedView via AccessControl, not here.
    FeedViewModel(isPremium: true).quote(at: feedCurrentIndex)
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          todaysPickSection
          categoriesSection
          authorsSection
          historyEntrySection

          Color.clear.frame(height: 100)
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .readableWidth()
      }
      .scrollDisabled(isHorizontalTabSwipeActive)
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
  }

  // MARK: - Sections

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
    sectionHeader(title: "Browse by Category", showLock: !subscriptionManager.isPremiumUser)
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(index.topCategories.prefix(40), id: \.name) { item in
          Button {
            handleCategoryTap(name: item.name)
          } label: {
            pill(text: item.name.capitalized, badge: "\(item.count)")
          }
          .buttonStyle(.plain)
        }
      }
    }
    .claimsHorizontalDrag()
  }

  @ViewBuilder
  private var authorsSection: some View {
    sectionHeader(title: "Top Authors", showLock: !subscriptionManager.isPremiumUser)
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(index.topAuthors.prefix(20), id: \.name) { item in
          Button {
            handleAuthorTap(name: item.name)
          } label: {
            pill(text: item.name, badge: "\(item.count)")
          }
          .buttonStyle(.plain)
        }
      }
    }
    .claimsHorizontalDrag()
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

  // MARK: - Actions

  private func handleCategoryTap(name: String) {
    if subscriptionManager.isPremiumUser {
      let quotes = index.byCategory[name] ?? []
      navigationPath.append(NavTarget.category(name, quotes))
    } else {
      HapticManager.warning()
      showingPaywall = true
    }
  }

  private func handleAuthorTap(name: String) {
    if subscriptionManager.isPremiumUser {
      let quotes = index.byAuthor[name] ?? []
      navigationPath.append(NavTarget.author(name, quotes))
    } else {
      HapticManager.warning()
      showingPaywall = true
    }
  }

  // MARK: - Reusable

  private func sectionHeader(title: String, showLock: Bool = false) -> some View {
    HStack(spacing: 6) {
      Text(title)
        .font(.system(size: 13, weight: .semibold))
        .tracking(1.5)
        .foregroundStyle(.white.opacity(0.55))
      if showLock {
        Image(systemName: "lock.fill")
          .font(.system(size: 9))
          .foregroundStyle(.yellow.opacity(0.8))
      }
    }
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
        .font(.system(size: 17, weight: .medium, design: .serif))
        .foregroundStyle(.white)
        .lineLimit(3)
        .multilineTextAlignment(.leading)
      HStack {
        Text(q.author.uppercased())
          .font(.system(size: 12, weight: .semibold))
          .tracking(1)
          .foregroundStyle(.white.opacity(0.5))
        if let category = q.category, !category.isEmpty {
          Text("• \(category.capitalized)")
            .font(.system(size: 12))
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
