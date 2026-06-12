# M3 — Explore Tab + Daily Notifications Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: superpowers:executing-plans

**Goal:** Make the 10000-quote corpus discoverable through search/categories/authors, give favorites a contextual home, and re-engage users with a daily local push notification.

**Architecture:**
- New Explore tab inserted between Feed and Favorites (`AppView.explore`, order 1).
- In-memory `QuoteIndex` built lazily once at app launch from `LocalQuotes.quotes`. No external search lib; 10k rows × O(n) filter is sub-100ms.
- Search results -> `QuoteDetailView` (single quote with favorite/share/copy actions). No deep nav stack of quote-flipping pages — that would duplicate FeedView and obscure the search-result origin.
- Local notifications via `UNUserNotificationCenter` with `UNCalendarNotificationTrigger(dateMatching:repeats:true)`. Single repeating slot; app launch syncs content to "today's quote".
- Settings expanded to host the reminder toggle + time picker. History Calendar entry moves OUT of Settings INTO Explore (single source of truth).

**Tech Stack:** SwiftUI · UNUserNotificationCenter · existing FeedViewModel / FavoritesManager / RevenueCatManager

**Parent Design:** `docs/plans/2026-06-02-quoteary-optimization-v1-design.md` §5

**Decisions captured 2026-06-12:**
- Q1 — History Calendar: ONLY in Explore (delete from SettingsSheet, no double entry)
- Q2 — Search results: tap → single-quote detail view (favorite/share/copy)
- Q3 — Notification content: today's actual quote text (with app-launch re-scheduling to refresh content on date rollover)

---

## Pre-flight

- [ ] M2 verified, v0.7 tag in place
- [ ] Working tree clean
- [ ] On `main`

---

## Task 1: QuoteIndex utility (foundation for Task 2 search/browse)

### Files
- Create: `DailyQuotation/Utils/QuoteIndex.swift`

### What it does

Singleton that, on first access, builds three views of `LocalQuotes.quotes`:
1. Grouped by canonical category (lowercased + trimmed)
2. Grouped by author (lowercased + trimmed for keys, original casing for display)
3. Sorted list of all unique categories (by quote count descending)
4. Sorted list of top-N authors (by quote count descending)

Plus a `search(query:limit:)` method that does the case-insensitive contains match across `text` and `author`.

### Implementation

```swift
import Foundation

/// Lazy-built, immutable view of LocalQuotes for the Explore tab.
@MainActor
final class QuoteIndex {
  static let shared = QuoteIndex()

  let allQuotes: [Quote]
  let byCategory: [String: [Quote]]
  let byAuthor: [String: [Quote]]
  let topCategories: [(name: String, count: Int)]
  let topAuthors: [(name: String, count: Int)]

  private init() {
    let quotes = LocalQuotes.quotes
    self.allQuotes = quotes

    var byCat: [String: [Quote]] = [:]
    var byAuth: [String: [Quote]] = [:]
    for q in quotes {
      if let c = q.category?.trimmingCharacters(in: .whitespacesAndNewlines), !c.isEmpty {
        byCat[c, default: []].append(q)
      }
      let author = q.author.trimmingCharacters(in: .whitespacesAndNewlines)
      if !author.isEmpty {
        byAuth[author, default: []].append(q)
      }
    }
    self.byCategory = byCat
    self.byAuthor = byAuth

    self.topCategories = byCat
      .map { (name: $0.key, count: $0.value.count) }
      .sorted { $0.count > $1.count }

    self.topAuthors = byAuth
      .map { (name: $0.key, count: $0.value.count) }
      .sorted { $0.count > $1.count }
  }

  /// Case-insensitive contains match against text and author.
  /// `limit` caps result size to keep List scroll perf stable.
  func search(_ query: String, limit: Int = 200) -> [Quote] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }

    var results: [Quote] = []
    results.reserveCapacity(min(limit, 64))
    for q in allQuotes {
      if q.text.localizedCaseInsensitiveContains(trimmed)
        || q.author.localizedCaseInsensitiveContains(trimmed) {
        results.append(q)
        if results.count >= limit { break }
      }
    }
    return results
  }
}
```

### Commit

```bash
git add DailyQuotation/DailyQuotation/Utils/QuoteIndex.swift
git commit -m "feat(m3): add QuoteIndex utility for category/author/search views"
```

---

## Task 2: QuoteDetailView (search-result tap target)

### Files
- Create: `DailyQuotation/Views/Detail/QuoteDetailView.swift`

### Behavior
- Visually similar to a single QuoteSlideView card but inside a NavigationStack (no full-screen / gesture hijacking).
- Actions: Favorite toggle (gated by AccessControl + paywall), Share (open ShareCardSheet), Copy text.

```swift
import SwiftUI

struct QuoteDetailView: View {
  let quote: Quote
  /// The gradient index is normally derived from a quote's position in
  /// the feed rotation; for detail-view from search/browse we have no
  /// natural position, so we derive a stable one from the stable id.
  let gradientIndex: Int

  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @ObservedObject private var favoritesManager = FavoritesManager.shared
  @State private var showShareSheet = false
  @State private var copied = false

  init(quote: Quote) {
    self.quote = quote
    // Convert the first 4 hex chars of stable id to an int and mod by gradient count.
    let head = quote.id.prefix(4)
    let value = UInt32(head, radix: 16) ?? 0
    self.gradientIndex = Int(value) % max(GradientColors.gradients.count, 1)
  }

  private var isFavorite: Bool {
    favoritesManager.isFavorite(quote)
  }

  var body: some View {
    ZStack {
      GradientColors.gradient(for: gradientIndex)
        .ignoresSafeArea()

      VStack(spacing: 24) {
        Spacer()

        Text("\u{201C}\(quote.text)\u{201D}")
          .font(.system(size: 26, weight: .regular, design: .serif))
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .lineSpacing(8)
          .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
          .padding(.horizontal, 28)

        Rectangle()
          .fill(Color.white.opacity(0.3))
          .frame(width: 48, height: 2)

        Text(quote.author)
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(.white.opacity(0.9))
          .tracking(1)

        if let category = quote.category {
          Text(category.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(2)
            .foregroundColor(.white.opacity(0.6))
        }

        Spacer()

        actionRow
          .padding(.bottom, 32)
      }
    }
    .navigationTitle("Quote")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarColorScheme(.dark, for: .navigationBar)
    .sheet(isPresented: $showShareSheet) {
      ShareCardSheet(
        quote: quote,
        gradientIndex: gradientIndex,
        isPremium: subscriptionManager.isPremiumUser
      )
    }
  }

  private var actionRow: some View {
    HStack(spacing: 28) {
      iconButton(
        systemName: isFavorite ? "heart.fill" : "heart",
        tint: isFavorite ? .red : .white,
        action: handleFavoriteTap
      )
      iconButton(systemName: "square.and.arrow.up", tint: .white) {
        HapticManager.light()
        showShareSheet = true
      }
      iconButton(
        systemName: copied ? "checkmark" : "doc.on.doc",
        tint: copied ? .green : .white,
        action: handleCopyTap
      )
    }
  }

  private func iconButton(systemName: String, tint: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 22))
        .foregroundColor(tint)
        .frame(width: 56, height: 56)
        .background(
          Circle()
            .fill(Color.white.opacity(0.12))
            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        )
    }
    .buttonStyle(.plain)
  }

  private func handleFavoriteTap() {
    HapticManager.light()
    let allowed = AccessControl.shared.canAddFavorite(
      currentCount: favoritesManager.favorites.count,
      isPremium: subscriptionManager.isPremiumUser
    )
    if allowed {
      favoritesManager.toggleFavorite(quote)
    }
  }

  private func handleCopyTap() {
    UIPasteboard.general.string = "\"\(quote.text)\" — \(quote.author)"
    HapticManager.success()
    withAnimation { copied = true }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation { copied = false }
    }
  }
}
```

### Commit

```bash
git add DailyQuotation/DailyQuotation/Views/Detail/
git commit -m "feat(m3): add QuoteDetailView for search/browse drilldowns"
```

---

## Task 3: Explore tab — new top-level tab with search, categories, authors

### Files
- Modify: `DailyQuotation/Models/AppView.swift` — add `case explore`
- Modify: `DailyQuotation/Views/TabBarView.swift` — add explore icon + accent color
- Modify: `DailyQuotation/ContentView.swift` — render ExploreView for `.explore`
- Create: `DailyQuotation/Views/Explore/ExploreView.swift`
- Create: `DailyQuotation/Views/Explore/CategoryQuotesView.swift`
- Create: `DailyQuotation/Views/Explore/AuthorQuotesView.swift`

### Step 1: Wire the tab into the model

```swift
// AppView.swift
enum AppView: String, CaseIterable {
    case feed = "FEED"
    case explore = "EXPLORE"
    case favorites = "FAVORITES"

    var order: Int {
        switch self {
        case .feed: return 0
        case .explore: return 1
        case .favorites: return 2
        }
    }
    // ... orderedCases / next / previous unchanged
}
```

```swift
// TabBarView.swift — extend iconName + accentColor
private func iconName(for view: AppView, isSelected: Bool) -> String {
  switch view {
  case .feed:
    return isSelected ? "square.stack.fill" : "square.stack"
  case .explore:
    return isSelected ? "magnifyingglass.circle.fill" : "magnifyingglass"
  case .favorites:
    return isSelected ? "heart.fill" : "heart"
  }
}

// In tabButton(for:), accentColor:
private func tabButton(for view: AppView) -> some View {
  let isSelected = currentView == view
  let accentColor: Color = {
    switch view {
    case .feed: return .white
    case .explore: return .cyan
    case .favorites: return .red
    }
  }()
  // ... rest unchanged
}
```

### Step 2: ExploreView

Sections from top to bottom:
1. Search bar (`.searchable`-bound)
2. Search results (only if query non-empty)
3. Today's Pick (`DailyQuoteSync.loadTodayQuote()`)
4. Browse by Category (horizontal scroll, all categories — they fit in flowing pills)
5. Top Authors (horizontal scroll, top 20)
6. History Calendar (premium-gated row — moved from SettingsSheet)

```swift
import SwiftUI

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

          Color.clear.frame(height: 100) // breathing room for tab bar
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
      }
      .background(Color.black.ignoresSafeArea())
      .navigationBarHidden(true)
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

  @ViewBuilder
  private var historyEntrySection: some View {
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

/// Navigation destinations for the Explore stack.
enum NavTarget: Hashable {
  case quote(Quote)
  case category(String, [Quote])
  case author(String, [Quote])
}
```

### Step 3: CategoryQuotesView + AuthorQuotesView

Both are simple List wrappers that take an array of pre-filtered quotes and let the user drill into `QuoteDetailView`.

```swift
// CategoryQuotesView.swift
import SwiftUI

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

// AuthorQuotesView.swift
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

/// Compact list row reused by both category and author drilldowns.
struct QuoteListRow: View {
  let quote: Quote

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("\u{201C}\(quote.text)\u{201D}")
        .font(.system(size: 14, weight: .medium, design: .serif))
        .foregroundStyle(.white)
        .lineLimit(3)
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
```

### Step 4: Wire the tab in ContentView

```swift
// ContentView.swift — add explore to pageView switch:
case .explore:
    ExploreView()
        .environmentObject(subscriptionManager)
```

And in `tabContentLayer`, add the explore branch:

```swift
if currentView == .explore {
    pageView(for: .explore)
        .transition(pageTransition)
        .zIndex(currentView == .explore ? 1 : 0)
}
```

### Step 5: Manual verification + commit

- [ ] TabBar shows three tabs in order: Feed, Explore, Favorites
- [ ] Explore renders search bar + Today's Pick + categories + authors + History entry
- [ ] Typing in search field debounces 250ms then shows results
- [ ] Tap a result -> QuoteDetailView
- [ ] Tap a category pill -> filtered list -> tap row -> detail
- [ ] Tap an author pill -> filtered list -> tap row -> detail
- [ ] Tap History (premium) -> calendar opens
- [ ] Tap History (free) -> paywall opens

```bash
git add DailyQuotation/DailyQuotation/{Models/AppView.swift,Views/TabBarView.swift,ContentView.swift,Views/Explore/}
git commit -m "feat(m3): add Explore tab with search, browse, and history entry"
```

---

## Task 4: Remove History Calendar entry from SettingsSheet

Per Q1 decision, History Calendar now lives only in Explore. SettingsSheet keeps Manage Subscription + Version, plus the new Daily Reminder controls (Task 5).

### Files
- Modify: `DailyQuotation/Views/Settings/SettingsSheet.swift`

Remove the entire "History Calendar" Section, the `showingHistory` state, the `HistoryCalendarView` sheet, and the `onRequirePaywall` parameter (no longer needed — there's nothing premium-gated left to trigger it). Also delete the FavoritesListView's chained paywall sheet plumbing.

### Commit

```bash
git add DailyQuotation/DailyQuotation/Views/Settings/SettingsSheet.swift DailyQuotation/DailyQuotation/Views/FavoritesListView.swift
git commit -m "refactor(m3): make Explore the single home for History Calendar"
```

---

## Task 5: Daily Reminder local notification

### Files
- Create: `DailyQuotation/Utils/NotificationManager.swift`
- Modify: `DailyQuotation/Views/Settings/SettingsSheet.swift` — add Reminder section
- Modify: `DailyQuotation/Utils/SharedDefaults.swift` — add ReminderPreferences storage
- Modify: `DailyQuotation/DailyQuotationApp.swift` — re-schedule on launch
- Modify: `DailyQuotation/Info.plist` — `NSUserNotificationUsageDescription` is optional for local notifications; iOS will still show the system prompt without it. Skip unless we hit a compliance issue.

### Step 1: ReminderPreferences storage

Add to `SharedDefaults.swift` (or a new small file) a struct holding `enabled: Bool`, `hour: Int`, `minute: Int`, with App Group-backed get/set helpers. Keep it tiny — no full Codable struct, three keys is fine:

```swift
enum ReminderPreferences {
  private static let store = SharedDefaults.store
  private static let enabledKey = "reminder.enabled"
  private static let hourKey = "reminder.hour"
  private static let minuteKey = "reminder.minute"

  static var isEnabled: Bool {
    get { store.bool(forKey: enabledKey) }
    set { store.set(newValue, forKey: enabledKey) }
  }

  static var hour: Int {
    get {
      let v = store.object(forKey: hourKey) as? Int
      return v ?? 9
    }
    set { store.set(newValue, forKey: hourKey) }
  }

  static var minute: Int {
    get {
      let v = store.object(forKey: minuteKey) as? Int
      return v ?? 0
    }
    set { store.set(newValue, forKey: minuteKey) }
  }
}
```

### Step 2: NotificationManager

```swift
import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
  static let shared = NotificationManager()

  private let center = UNUserNotificationCenter.current()
  private let identifier = "daily-quote-reminder"

  @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

  private init() {
    Task { await refreshStatus() }
  }

  func refreshStatus() async {
    let settings = await center.notificationSettings()
    authorizationStatus = settings.authorizationStatus
  }

  /// Request authorization if not yet decided. Returns `true` if granted.
  @discardableResult
  func requestAuthorizationIfNeeded() async -> Bool {
    await refreshStatus()
    switch authorizationStatus {
    case .notDetermined:
      do {
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        await refreshStatus()
        return granted
      } catch {
        return false
      }
    case .authorized, .provisional, .ephemeral:
      return true
    case .denied:
      return false
    @unknown default:
      return false
    }
  }

  /// Cancel any existing reminder and re-schedule using today's quote
  /// (or a generic placeholder if for some reason the index is empty).
  func scheduleDailyReminder(hour: Int, minute: Int) async {
    cancelDailyReminder()

    let content = UNMutableNotificationContent()
    content.title = "Quoteary"
    if let quote = DailyQuoteSync.loadTodayQuote() {
      // Trim to keep the lock-screen presentation readable.
      let trimmed = String(quote.text.prefix(120))
      content.body = "\u{201C}\(trimmed)\u{201D} — \(quote.author)"
    } else {
      content.body = "Your daily quote is ready."
    }
    content.sound = .default

    var dateComponents = DateComponents()
    dateComponents.hour = hour
    dateComponents.minute = minute

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    do {
      try await center.add(request)
    } catch {
      #if DEBUG
      print("⚠️ NotificationManager.schedule failed: \(error)")
      #endif
    }
  }

  func cancelDailyReminder() {
    center.removePendingNotificationRequests(withIdentifiers: [identifier])
  }
}
```

### Step 3: App launch re-scheduling

In `DailyQuotationApp.init` (or in the `.task` block where `RevenueCatManager.start()` runs), if reminder is enabled, re-schedule it. This refreshes the body text to "today's" quote on date rollover.

```swift
.task {
  subscriptionManager.start()
  if ReminderPreferences.isEnabled {
    await NotificationManager.shared.scheduleDailyReminder(
      hour: ReminderPreferences.hour,
      minute: ReminderPreferences.minute
    )
  }
}
```

### Step 4: SettingsSheet — Daily Reminder section

Add (above the Manage Subscription section):

```swift
@StateObject private var notificationManager = NotificationManager.shared
@State private var reminderEnabled = ReminderPreferences.isEnabled
@State private var reminderTime = Calendar.current.date(
  bySettingHour: ReminderPreferences.hour,
  minute: ReminderPreferences.minute,
  second: 0,
  of: Date()
) ?? Date()

Section {
  Toggle("Daily Reminder", isOn: $reminderEnabled)
    .onChange(of: reminderEnabled) { _, newValue in
      Task {
        if newValue {
          let granted = await notificationManager.requestAuthorizationIfNeeded()
          if granted {
            ReminderPreferences.isEnabled = true
            await reschedule()
          } else {
            reminderEnabled = false
            ReminderPreferences.isEnabled = false
          }
        } else {
          ReminderPreferences.isEnabled = false
          notificationManager.cancelDailyReminder()
        }
      }
    }

  if reminderEnabled {
    DatePicker(
      "Time",
      selection: $reminderTime,
      displayedComponents: .hourAndMinute
    )
    .onChange(of: reminderTime) { _, newValue in
      let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
      ReminderPreferences.hour = comps.hour ?? 9
      ReminderPreferences.minute = comps.minute ?? 0
      Task { await reschedule() }
    }
  }

  if notificationManager.authorizationStatus == .denied && reminderEnabled {
    Text("Notifications are disabled in System Settings. Tap Settings → Notifications → Quoteary to enable.")
      .font(.caption)
      .foregroundStyle(.orange)
  }
} header: {
  Text("Daily Reminder")
} footer: {
  Text("Receive one quote each day at the time you choose. Content refreshes when you open the app.")
}

// Helper:
private func reschedule() async {
  await notificationManager.scheduleDailyReminder(
    hour: ReminderPreferences.hour,
    minute: ReminderPreferences.minute
  )
}
```

### Step 5: Manual verification + commit

- [ ] Open Settings -> see "Daily Reminder" section
- [ ] Toggle ON for first time -> system permission prompt
- [ ] Allow -> toggle stays ON; time picker appears (default 09:00)
- [ ] Change time -> next `notificationSettings` shows updated trigger (use a delegate or Console)
- [ ] Toggle OFF -> pending notification gone (check via Xcode > Debug > Simulate Background Fetch or `unNotificationCenter.getPendingNotificationRequests`)
- [ ] Deny permission -> toggle flips back OFF, footer warning appears
- [ ] Set time to 1 minute from now, lock device, wait -> notification fires with today's quote in the body

```bash
git add DailyQuotation/DailyQuotation/Utils/{NotificationManager.swift,SharedDefaults.swift} DailyQuotation/DailyQuotation/Views/Settings/SettingsSheet.swift DailyQuotation/DailyQuotation/DailyQuotationApp.swift
git commit -m "feat(m3): daily local-notification reminder with time picker"
```

---

## Task 6: End-to-end verification + v0.8 tag

Manual checklist (M1+M2+M3 regression):

- [ ] App launches, 3 tabs visible, default tab Feed
- [ ] Feed: swipe up/down works; ❤️ / share / Aa buttons all functional
- [ ] Explore: search → 3+ chars produces results; tap → detail view
- [ ] Explore: category pill → list → detail
- [ ] Explore: author pill → list → detail
- [ ] Explore: History (premium) → calendar; (free) → paywall
- [ ] Favorites: gear → Settings has only Manage Sub + Reminder + Version (no History row anymore)
- [ ] Reminder: enable → permission → scheduled → triggers
- [ ] Customer Center via Manage Subscription works
- [ ] Quote favorited in Explore detail → shows in Favorites tab
- [ ] Widget still updates daily

```bash
git tag -a v0.8 -m "v0.8 — Explore tab + daily reminder notifications"
```

---

## Explicit YAGNI for M3

- No SwiftData/Core Data — search is in-memory, fast enough
- No tokenized full-text search — `localizedCaseInsensitiveContains` is fine for 10k rows
- No recently-viewed history
- No category filters in Feed itself (the original §5.3 "category preferences" idea is dropped — promote later only if users ask)
- No notification grouping / actions / images
- No widget reminder (the Daily Reminder is app-launched local, not via WidgetKit)

## Risk

- `UNCalendarNotificationTrigger(repeats:true)` content is frozen at schedule time. Re-scheduling on each app launch is the standard workaround; users who never open the app would see stale body text but the notification still fires.
- Free users land on `History Calendar` row in Explore and see it locked. That's intentional (discovery) but if it feels too in-your-face we can move it lower or behind a small "More" group.
