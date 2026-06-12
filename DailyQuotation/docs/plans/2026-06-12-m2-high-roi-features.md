# M2 — High-ROI Features Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: superpowers:executing-plans

**Goal:** Ship the two most user-visible features (share-card export + history calendar) plus a tiny Settings sheet that consolidates the existing Customer Center entry.

**Architecture:**
- Pure SwiftUI; no new third-party deps.
- Share cards rendered via `ImageRenderer` (iOS 16+) to a 1080×1920 `UIImage`, surfaced through `ShareLink`.
- History reuses `FeedViewModel(referenceDate:)` — already supports arbitrary dates from M1 Task 7.
- Settings is a single SwiftUI sheet (not a full screen) keeping the modal feel; M3 may promote it later.

**Tech Stack:** SwiftUI · ImageRenderer · RevenueCatUI.CustomerCenterView

**Parent Design:** `docs/plans/2026-06-02-quoteary-optimization-v1-design.md` §4

---

## Pre-flight Checklist

- [ ] M1 fully verified (compile + run + RC paywall working end-to-end)
- [ ] Working tree clean before starting (`git status` should be empty)
- [ ] On `main` branch

If any of the above is false, stop and resolve before continuing.

---

## Task 1: Share Card (Export Poster)

### Files
- Create: `DailyQuotation/Views/Share/ShareCardView.swift`
- Create: `DailyQuotation/Views/Share/ShareCardSheet.swift`
- Modify: `DailyQuotation/Views/QuoteSlideView.swift` (add share button between ❤️ and Aa)

### Step 1: Create `ShareCardView.swift`

This is the pure SwiftUI view that will be passed to `ImageRenderer`. It must NOT depend on `@EnvironmentObject` / `@Environment(\.dismiss)` etc., because `ImageRenderer` renders it offscreen without a view hierarchy context.

Design (matches existing brand language):
- Aspect ratio: 9:16 (1080×1920)
- Background: same `GradientColors.gradient(for: index)` as the source quote
- Centered: "" Quote text "" + thin divider + author
- Bottom-right or bottom-center watermark: "Quoteary" (only if `includeWatermark` is true)
- Subtle decorative blur circles (reuse logic from QuoteSlideView)

```swift
import SwiftUI

struct ShareCardView: View {
  let quote: Quote
  let gradientIndex: Int
  let includeWatermark: Bool

  var body: some View {
    ZStack {
      GradientColors.gradient(for: gradientIndex)

      backgroundDecorations

      VStack(spacing: 24) {
        Spacer()

        Text("\u{201C}\(quote.text)\u{201D}")
          .font(.system(size: 44, weight: .regular, design: .serif))
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .lineSpacing(10)
          .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 6)
          .padding(.horizontal, 60)

        Rectangle()
          .fill(Color.white.opacity(0.3))
          .frame(width: 64, height: 2)

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
    HStack(spacing: 8) {
      Image(systemName: "quote.opening")
        .font(.system(size: 22, weight: .semibold))
      Text("Quoteary")
        .font(.system(size: 26, weight: .bold, design: .rounded))
        .tracking(1)
    }
    .foregroundColor(.white.opacity(0.85))
  }
}
```

### Step 2: Create `ShareCardSheet.swift`

This is the user-facing sheet. It:
1. Shows a scaled-down preview of the card.
2. If user is premium, shows a `Toggle("Watermark")` (default ON).
3. Renders the card to `UIImage` via `ImageRenderer`.
4. Uses `ShareLink(item: Image(uiImage:))` for the system share sheet.

```swift
import SwiftUI

struct ShareCardSheet: View {
  let quote: Quote
  let gradientIndex: Int
  let isPremium: Bool

  @State private var includeWatermark: Bool = true
  @State private var renderedImage: UIImage?
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          previewCard
            .aspectRatio(9.0/16.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
            .padding(.horizontal, 32)

          if isPremium {
            Toggle("Show watermark", isOn: $includeWatermark)
              .tint(.blue)
              .padding(.horizontal, 32)
          } else {
            Label("Watermark required for free users", systemImage: "info.circle")
              .font(.caption)
              .foregroundStyle(.secondary)
              .padding(.horizontal, 32)
          }

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
              .padding(.vertical, 14)
          }
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
      .task(id: actualIncludeWatermark) {
        await renderImage()
      }
    }
  }

  private var previewCard: ShareCardView {
    ShareCardView(
      quote: quote,
      gradientIndex: gradientIndex,
      includeWatermark: actualIncludeWatermark
    )
  }

  /// Free users cannot drop the watermark, regardless of the toggle state.
  private var actualIncludeWatermark: Bool {
    isPremium ? includeWatermark : true
  }

  @MainActor
  private func renderImage() async {
    let renderer = ImageRenderer(content: previewCard)
    renderer.scale = 1
    renderer.proposedSize = ProposedViewSize(width: 1080, height: 1920)
    renderedImage = renderer.uiImage
  }
}
```

### Step 3: Wire share button into `QuoteSlideView`

Add a third action button between the ❤️ and the Aa textformat button. It opens `ShareCardSheet` as a `.sheet`.

```swift
// Add to QuoteSlideView:
@State private var showShareSheet = false

// In actionButtons HStack, INSERT this between Save and Style:
VStack(spacing: 8) {
  Button {
    HapticManager.light()
    showShareSheet = true
  } label: {
    Image(systemName: "square.and.arrow.up")
      .font(.system(size: 24))
      .foregroundColor(.white)
      .opacity(0.9)
      .frame(width: 56, height: 56)
      .background(
        Circle()
          .fill(frostedCircleGradient(isActive: false))
          .overlay(
            Circle()
              .stroke(Color.white.opacity(0.15), lineWidth: 1)
          )
          .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
      )
  }
}

// Bottom of view body, alongside existing .overlay etc:
.sheet(isPresented: $showShareSheet) {
  ShareCardSheet(
    quote: quote,
    gradientIndex: index,
    isPremium: isPremium
  )
}
```

### Step 4: Verify and commit

Manual verification (no unit tests for UI):
- [ ] Compile ⌘B succeeds
- [ ] Run ⌘R, tap share on any quote → sheet appears, preview renders
- [ ] Free user: watermark always visible, toggle absent
- [ ] Premium user: toggle visible, switching off removes watermark from preview
- [ ] Share button opens system share sheet with image attached
- [ ] Save image to Photos → image is sharp, not blurry, correct gradient

```bash
git add DailyQuotation/DailyQuotation/Views/Share/ DailyQuotation/DailyQuotation/Views/QuoteSlideView.swift
git commit -m "feat(m2): add share-card export with watermark gating"
```

---

## Task 2: History Calendar (💎 Premium)

### Files
- Create: `DailyQuotation/Views/History/HistoryCalendarView.swift`
- Create: `DailyQuotation/Views/History/HistoryFeedView.swift`

(`FeedViewModel.init(isPremium:referenceDate:quotes:)` already accepts a custom `referenceDate` — no change needed there. ✅)

### Step 1: Create `HistoryCalendarView.swift`

```swift
import SwiftUI

struct HistoryCalendarView: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @Environment(\.dismiss) private var dismiss

  @State private var selectedDate: Date = Date()
  @State private var navigateToHistoryFeed: Bool = false

  // App's content "start date" — matches FeedViewModel.todayOrder
  private let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!

  private var dateRange: ClosedRange<Date> {
    startDate ... Date()
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Text("Browse quotes from any day since January 2025.")
          .font(.subheadline)
          .foregroundStyle(.white.opacity(0.65))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
          .padding(.top, 20)

        DatePicker(
          "Select date",
          selection: $selectedDate,
          in: dateRange,
          displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .tint(.white)
        .colorScheme(.dark)
        .padding(.horizontal, 16)

        Spacer()

        Button {
          navigateToHistoryFeed = true
        } label: {
          Label("View this day", systemImage: "arrow.right.circle.fill")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
      }
      .background(Color.black.ignoresSafeArea())
      .navigationTitle("History")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarColorScheme(.dark, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close") { dismiss() }
            .foregroundStyle(.white)
        }
      }
      .navigationDestination(isPresented: $navigateToHistoryFeed) {
        HistoryFeedView(referenceDate: selectedDate)
          .environmentObject(subscriptionManager)
      }
    }
  }
}
```

### Step 2: Create `HistoryFeedView.swift`

This is a stripped-down read-only Feed for a given date. Uses `FeedViewModel(isPremium: true, referenceDate:)` (premium=true because user just paid to be here; we don't gate within history) so the user sees the full 20-quote order for that day.

Reuse `QuoteSlideView` for rendering (favorites still work via `FavoritesManager`).

```swift
import SwiftUI

struct HistoryFeedView: View {
  let referenceDate: Date

  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @StateObject private var viewModel: FeedViewModel
  @ObservedObject private var favoritesManager = FavoritesManager.shared
  @StateObject private var appearanceManager = AppearanceManager.shared

  @State private var dragOffset: CGFloat = 0
  @State private var isDragging: Bool = false

  init(referenceDate: Date) {
    self.referenceDate = referenceDate
    // Premium-only entry point, so always run as premium here.
    self._viewModel = StateObject(
      wrappedValue: FeedViewModel(isPremium: true, referenceDate: referenceDate)
    )
  }

  private var appearanceBinding: Binding<AppearanceSettings> {
    Binding(
      get: { appearanceManager.settings },
      set: { appearanceManager.updateSettings($0) }
    )
  }

  var body: some View {
    GeometryReader { geometry in
      let screenHeight = geometry.size.height
      let totalPositions = viewModel.totalPositions
      let currentPosition = viewModel.currentPosition

      let prevPos = currentPosition > 0 ? currentPosition - 1 : nil
      let nextPos = currentPosition + 1 < totalPositions ? currentPosition + 1 : nil

      ZStack {
        Color.black.ignoresSafeArea()

        ZStack {
          if let prevPos {
            card(at: prevPos, offset: -screenHeight + max(0, dragOffset), screenHeight: screenHeight)
              .opacity(isDragging && dragOffset > 0 ? min(1, dragOffset / screenHeight) : 0)
          }
          card(at: currentPosition, offset: dragOffset, screenHeight: screenHeight)
          if let nextPos {
            card(at: nextPos, offset: screenHeight - max(0, -dragOffset), screenHeight: screenHeight)
              .opacity(isDragging && dragOffset < 0 ? min(1, -dragOffset / screenHeight) : 0)
          }
        }
        .gesture(swipeGesture(screenHeight: screenHeight))
      }
    }
    .ignoresSafeArea()
    .navigationTitle(referenceDate.formatted(date: .abbreviated, time: .omitted))
    .navigationBarTitleDisplayMode(.inline)
    .toolbarColorScheme(.dark, for: .navigationBar)
  }

  @ViewBuilder
  private func card(at position: Int, offset: CGFloat, screenHeight: CGFloat) -> some View {
    if let quote = viewModel.quote(at: position),
       let rawIndex = viewModel.quoteIndex(at: position) {
      QuoteSlideView(
        quote: quote,
        index: rawIndex,
        isToday: false,
        isPremium: subscriptionManager.isPremiumUser,
        onRequirePaywall: {},
        onToggleFavorite: {
          favoritesManager.toggleFavorite(quote)
        },
        appearance: appearanceBinding
      )
      .offset(y: offset)
      .scaleEffect(1.0 - abs(offset) / (screenHeight * 2))
      .opacity(1.0 - abs(offset) / (screenHeight * 1.5))
    }
  }

  private func swipeGesture(screenHeight: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 20)
      .onChanged { value in
        if abs(value.translation.height) > abs(value.translation.width) {
          isDragging = true
          dragOffset = value.translation.height
        }
      }
      .onEnded { value in
        let threshold = screenHeight * 0.25
        if value.translation.height < -threshold, viewModel.canMoveForward(from: viewModel.currentPosition) {
          withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            viewModel.currentPosition += 1
            dragOffset = 0
          }
          HapticManager.medium()
        } else if value.translation.height > threshold, viewModel.currentPosition > 0 {
          withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            viewModel.currentPosition -= 1
            dragOffset = 0
          }
          HapticManager.medium()
        } else {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = 0
          }
        }
        isDragging = false
      }
  }
}
```

### Step 3: Manual verification + commit

- [ ] Compile passes
- [ ] (After Task 3 wires the entry) Tap "History" in Settings → calendar shows
- [ ] Select a past date → "View this day" enabled
- [ ] Tap button → HistoryFeedView shows quotes from that date
- [ ] Vertical swipe navigates the 20 quotes of that day
- [ ] ❤️ button works, favorites sync back to Favorites tab
- [ ] Cannot select future dates (date range enforced)

```bash
git add DailyQuotation/DailyQuotation/Views/History/
git commit -m "feat(m2): add history calendar with read-only daily feed"
```

---

## Task 3: Favorites Settings Gear + SettingsSheet

### Files
- Create: `DailyQuotation/Views/Settings/SettingsSheet.swift`
- Modify: `DailyQuotation/Views/FavoritesListView.swift`
  - Change `person.crop.circle` button → `gear` icon
  - Wire it to present `SettingsSheet` instead of `CustomerCenterView` directly
  - Gate `History` row by `isPremiumUser`; tap when not premium → present paywall

### Step 1: Create `SettingsSheet.swift`

```swift
import RevenueCatUI
import SwiftUI

struct SettingsSheet: View {
  @EnvironmentObject private var subscriptionManager: RevenueCatManager
  @Environment(\.dismiss) private var dismiss

  @State private var showingCustomerCenter = false
  @State private var showingHistory = false
  @State private var showingPaywall = false

  private var appVersion: String {
    let dict = Bundle.main.infoDictionary
    let version = dict?["CFBundleShortVersionString"] as? String ?? "—"
    let build = dict?["CFBundleVersion"] as? String ?? "—"
    return "\(version) (\(build))"
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          Button {
            if subscriptionManager.isPremiumUser {
              showingHistory = true
            } else {
              dismiss()
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showingPaywall = true
              }
            }
          } label: {
            row(
              title: "History Calendar",
              subtitle: subscriptionManager.isPremiumUser
                ? "Browse past quotes by date"
                : "Premium — browse quotes from any day",
              systemImage: "calendar",
              showLock: !subscriptionManager.isPremiumUser
            )
          }
        }

        Section {
          Button {
            showingCustomerCenter = true
          } label: {
            row(
              title: "Manage Subscription",
              subtitle: subscriptionManager.isPremiumUser ? "Premium active" : "Not subscribed",
              systemImage: "person.crop.circle"
            )
          }
        }

        Section {
          HStack {
            Label("Version", systemImage: "info.circle")
            Spacer()
            Text(appVersion)
              .foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
      .sheet(isPresented: $showingCustomerCenter) {
        CustomerCenterView()
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

  private func row(title: String, subtitle: String, systemImage: String, showLock: Bool = false) -> some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .frame(width: 24)
        .foregroundStyle(.primary)
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(title)
            .foregroundStyle(.primary)
          if showLock {
            Image(systemName: "lock.fill")
              .font(.caption2)
              .foregroundStyle(.yellow)
          }
        }
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
    }
    .contentShape(Rectangle())
  }
}
```

### Step 2: Update `FavoritesListView.swift`

Replace the `person.crop.circle` button with a `gear` button that presents `SettingsSheet`. Remove the inline `CustomerCenterView` sheet (now lives in `SettingsSheet`).

Changes (in `FavoritesListView`):
- `@State private var showingCustomerCenter` → `@State private var showingSettings`
- Drop `import RevenueCatUI` (no longer needed here)
- Button label: `Image(systemName: "gearshape")` (more semantically correct than person)
- `.sheet(isPresented: $showingSettings) { SettingsSheet().environmentObject(subscriptionManager) }`

Note: `FavoritesListView` doesn't currently inject `subscriptionManager`. It needs to either:
- Read it from `@EnvironmentObject` (added in this task), OR
- Have it forwarded through the SettingsSheet via parent's environment.

Use `@EnvironmentObject` — `ContentView` already propagates it.

### Step 3: Manual verification + commit

- [ ] Tap gear in Favorites top-right → SettingsSheet appears
- [ ] **Free user**: tap "History Calendar" → Settings dismisses then paywall appears
- [ ] **Premium user**: tap "History Calendar" → HistoryCalendarView appears
- [ ] Tap "Manage Subscription" → CustomerCenterView appears (system-style modal)
- [ ] Version row shows correct version + build number
- [ ] Done button closes the sheet

```bash
git add DailyQuotation/DailyQuotation/Views/Settings/ DailyQuotation/DailyQuotation/Views/FavoritesListView.swift
git commit -m "feat(m2): replace inline Customer Center with SettingsSheet hub"
```

---

## Task 4: Manual end-to-end verification

- [ ] Free user flow:
  1. Open app → Feed
  2. Swipe to 2nd quote → paywall (RC) appears
  3. Close paywall
  4. Go to Favorites → tap gear → SettingsSheet shows
  5. Tap History Calendar → paywall appears
  6. Tap Manage Subscription → Customer Center shows
- [ ] Premium user flow (use sandbox / StoreKit testing):
  1. Subscribe via paywall
  2. Feed: swipe through 20 quotes + end card
  3. Open any quote → tap share → share sheet appears
  4. Toggle watermark off → preview updates → share works without watermark
  5. Favorites → gear → History Calendar → pick a past date → swipe through that day's quotes
  6. Favorite from history → see it in Favorites tab
- [ ] Regression: nothing in M1 is broken

```bash
git tag -a v0.7 -m "M2 complete: share cards, history calendar, settings sheet"
```

---

## Out of Scope (explicitly NOT in M2)

- ❌ Custom watermark text/logo design polish (use built-in icon + brand name)
- ❌ Multiple share-card templates (single template covers MVP)
- ❌ Custom calendar UI (DatePicker.graphical is good enough)
- ❌ Saving partial favorites state in history (favorites are global)
- ❌ Push notifications (M3)
- ❌ Settings extras like font preferences, theme packs (M3 or later)

## Risk & Rollback

- Each task is one commit. Any single task can be reverted independently.
- ImageRenderer is iOS 16+ stable but if it produces unexpected results on a specific device, the share button can be disabled by hiding it (one-line change in QuoteSlideView).
- HistoryFeedView duplicates some gesture/card code from FeedView. This is intentional for now (small surface, different lifecycle); if it grows, extract a shared FeedRenderer in a future refactor.
