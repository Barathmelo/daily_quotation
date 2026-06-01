# M1 — Stabilize Foundation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复 3 个 bug 级问题、清理架构债，让代码库为后续 M2/M3 新功能做好基础。

**Architecture:** 统一数据存储到 App Group；Quote 用稳定 hash id；拆出 FeedViewModel 让逻辑可测试；删 dead code；统一 Model 在 App 和 Widget 之间去重。

**Tech Stack:** Swift 5+, SwiftUI, XCTest, App Group (`group.BiBoBiBo.DailyQuotation`), iOS 18+

**Parent Design:** `docs/plans/2026-06-02-quoteary-optimization-v1-design.md` §3

---

## Pre-flight: 项目当前状态确认

**前置检查（在写代码前确认）:**

- [ ] Xcode 项目可正常 build & run（用户确认）
- [ ] `DailyQuotationTests` test target 存在；若不存在，需在 Xcode 中新建（File → New → Target → Unit Testing Bundle）
- [ ] 当前在 main 分支，工作树干净（已通过 `chore: clean working tree before refactor` 完成）

**如果 test target 不存在**：先停下，请用户在 Xcode 中创建后再开始 Task 1。理由：所有需要测试的任务都要往里加文件。

---

## Task 1: 删除 GeminiService 死代码 + Info.plist 清理

> 最简单的任务，先做获得快速反馈。无单元测试需要（纯删除）。

**Files:**
- Delete: `DailyQuotation/Services/GeminiService.swift`
- Delete: `DailyQuotation/Services/` 目录（如果空了）
- Modify: `DailyQuotation/Info.plist`

**Step 1: 删除 GeminiService 文件**

```bash
rm "DailyQuotation/Services/GeminiService.swift"
rmdir "DailyQuotation/Services" 2>/dev/null || true
```

**Step 2: 修改 Info.plist 移除三段**

打开 `DailyQuotation/Info.plist`，删除三处：

1. `GEMINI_API_KEY` 键和它的 string 值
2. 整个 `NSAppTransportSecurity` 字典
3. `UIRequiredDeviceCapabilities` 数组里的 `armv7` string

最终 plist 不再有 Gemini 相关键和 ATS 段。

**Step 3: 同步更新 Xcode project**

GeminiService.swift 被删后，Xcode project.pbxproj 里还有对它的引用，会导致 build 报错。

操作：在 Xcode 项目导航器里找到 GeminiService.swift 的红色（missing）引用，右键 → Delete → Remove Reference。

**Step 4: 验证 build**

在 Xcode 里：Product → Build (⌘B)。预期：Build Succeeded，无 warning/error。

**Step 5: Commit**

```bash
cd "/Users/alex/Documents/IOS projects"
git add -A
git commit -m "chore(m1): remove unused GeminiService and AI-related Info.plist entries"
```

---

## Task 2: SharedDefaults 用 fallback 替代 fatalError

> 简单单点修改 + 单元测试。

**Files:**
- Modify: `DailyQuotation/Utils/SharedDefaults.swift`
- Create: `DailyQuotationTests/SharedDefaultsTests.swift`

**Step 1: 写失败的测试**

`DailyQuotationTests/SharedDefaultsTests.swift`：

```swift
import XCTest
@testable import DailyQuotation

final class SharedDefaultsTests: XCTestCase {
    func test_store_returnsUserDefaultsEvenWhenAppGroupUnavailable() {
        let store = SharedDefaults.store
        XCTAssertNotNil(store)
        store.set("ping", forKey: "shared_defaults_test_key")
        XCTAssertEqual(store.string(forKey: "shared_defaults_test_key"), "ping")
        store.removeObject(forKey: "shared_defaults_test_key")
    }
}
```

**Step 2: 运行测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:DailyQuotationTests/SharedDefaultsTests 2>&1 | tail -20
```

预期：如果 App Group 配置正常则 PASS；当前实现因 `fatalError` 会让测试也崩。

**Step 3: 修改 SharedDefaults**

修改 `DailyQuotation/Utils/SharedDefaults.swift`：

```swift
import Foundation
import WidgetKit

enum SharedDefaults {
  private static let appGroupIdentifier = "group.BiBoBiBo.DailyQuotation"

  static var store: UserDefaults {
    if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
      return defaults
    }
    #if DEBUG
    print("⚠️ SharedDefaults: App Group \(appGroupIdentifier) unavailable, falling back to .standard")
    #endif
    return .standard
  }
}

// ... 保留下面 DailyQuoteSync 整段不动
```

注意：只改 `store` 这个 computed property，下面的 `DailyQuoteSync` 整段不动。

**Step 4: 再次运行测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:DailyQuotationTests/SharedDefaultsTests 2>&1 | tail -10
```

预期：PASS

**Step 5: Commit**

```bash
git add -A
git commit -m "fix(m1): replace fatalError with .standard fallback in SharedDefaults"
```

---

## Task 3: 替换 UIScreen.main.bounds 为 GeometryReader

> 中等改动，FeedView 和 ContentView 都涉及。无单元测试（纯重构），用手动验证。

**Files:**
- Modify: `DailyQuotation/Views/FeedView.swift`
- Modify: `DailyQuotation/ContentView.swift`

**Step 1: 修改 FeedView**

`DailyQuotation/Views/FeedView.swift` 当前用 `UIScreen.main.bounds.height` 做 `screenHeight`。改为通过 `GeometryReader` 拿屏幕高度。

修改方案：
- 删除 `private let screenHeight = UIScreen.main.bounds.height`
- 在 `body` 最外层包一层 `GeometryReader`，把 `geometry.size.height` 传给子方法
- 把 `quoteCard(at:isFirstOfDay:offset:)` 等方法签名加上 `screenHeight: CGFloat` 参数
- 所有用到 `screenHeight` 的地方改用参数

完整修改后 body 顶部：

```swift
var body: some View {
    GeometryReader { geometry in
        let screenHeight = geometry.size.height
        let order = todayOrder
        // ... 其余逻辑不变，所有 screenHeight 引用都用这里的 local 变量
        ZStack {
            // ...
        }
    }
}
```

注意：原来用 `screenHeight` 计算 dragThreshold 等的地方都需要继续工作，只是 source 从 `UIScreen.main` 换成 `geometry`。

**Step 2: 修改 ContentView**

`DailyQuotation/ContentView.swift` 的 `dragGesture` 里用了 `UIScreen.main.bounds.width`：

```swift
let threshold = UIScreen.main.bounds.width * 0.15
```

改为通过 `GeometryReader` 包装 `contentLayer`，把 width 传下来。或者更简单：用 `@Environment(\.horizontalSizeClass)` 不合适（不是尺寸），改用：

```swift
.gesture(
    DragGesture()
        .onChanged { ... }
        .onEnded { value in
            // 用相对阈值：拖动距离 > 翻译值的 60 个 pt 即触发
            let threshold: CGFloat = 60
            // ... 其余不变
        }
)
```

或者用 GeometryReader 包 contentLayer。两种方案任选其一。**推荐用固定 60pt threshold**（更简洁），因为 tab 切换不依赖屏幕宽度。

**Step 3: 手动验证**

在 iPhone 15 模拟器跑：

- [ ] Feed 上下滑动正常切换 quote
- [ ] 左右滑动在 Feed 和 Favorites 之间切换
- [ ] 拖动一小段距离不切（threshold 生效）
- [ ] 拖动超过 threshold 切换
- [ ] 在 iPad mini 模拟器再跑一次（确认大屏 OK）

**Step 4: Commit**

```bash
git add -A
git commit -m "refactor(m1): replace UIScreen.main with GeometryReader/relative thresholds"
```

---

## Task 4: Quote.stableID — 稳定化 id 算法

> 核心 bug 修复。TDD 严格执行。

**Files:**
- Modify: `DailyQuotation/Models/Quote.swift`
- Modify: `DailyQuotation/Data/LocalQuotes.swift`
- Create: `DailyQuotationTests/QuoteTests.swift`

**Step 1: 写失败的测试**

`DailyQuotationTests/QuoteTests.swift`：

```swift
import XCTest
@testable import DailyQuotation

final class QuoteTests: XCTestCase {
    func test_stableID_isDeterministic() {
        let id1 = Quote.stableID(text: "Hello world", author: "Alex")
        let id2 = Quote.stableID(text: "Hello world", author: "Alex")
        XCTAssertEqual(id1, id2)
    }

    func test_stableID_differsForDifferentText() {
        let id1 = Quote.stableID(text: "Hello", author: "Alex")
        let id2 = Quote.stableID(text: "World", author: "Alex")
        XCTAssertNotEqual(id1, id2)
    }

    func test_stableID_differsForDifferentAuthor() {
        let id1 = Quote.stableID(text: "Hello", author: "Alex")
        let id2 = Quote.stableID(text: "Hello", author: "Bob")
        XCTAssertNotEqual(id1, id2)
    }

    func test_stableID_handlesEmptyStrings() {
        let id = Quote.stableID(text: "", author: "")
        XCTAssertEqual(id.count, 16)
    }

    func test_stableID_is16HexChars() {
        let id = Quote.stableID(text: "Be yourself", author: "Wilde")
        XCTAssertEqual(id.count, 16)
        XCTAssertTrue(id.allSatisfy { $0.isHexDigit })
    }

    func test_init_withoutId_usesStableID() {
        let q = Quote(text: "Be yourself", author: "Wilde")
        let expected = Quote.stableID(text: "Be yourself", author: "Wilde")
        XCTAssertEqual(q.id, expected)
    }
}
```

**Step 2: 运行测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:DailyQuotationTests/QuoteTests 2>&1 | tail -30
```

预期：FAIL（`stableID` 不存在；`init(text:author:)` 默认走 UUID）

**Step 3: 实现 stableID**

修改 `DailyQuotation/Models/Quote.swift`：

```swift
import CryptoKit
import Foundation

struct Quote: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let author: String
    let category: String?

    init(id: String? = nil, text: String, author: String, category: String? = nil) {
        self.id = id ?? Self.stableID(text: text, author: author)
        self.text = text
        self.author = author
        self.category = category
    }

    static func stableID(text: String, author: String) -> String {
        let input = "\(text)|\(author)"
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}

extension Quote {
    static let initial: Quote = Quote(
        id: "initial-1",
        text: "Every moment is a fresh beginning.",
        author: "T.S. Eliot",
        category: "Inspiration"
    )
}
```

**Step 4: 再次运行测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:DailyQuotationTests/QuoteTests 2>&1 | tail -15
```

预期：PASS（6/6）

**Step 5: 让 LocalQuotes 解析时也用 stableID**

`DailyQuotation/Data/LocalQuotes.swift` 的 `QuoteRecord.toQuote()` 当前显式传了 `id: UUID().uuidString`，删掉这个参数让默认值生效：

```swift
func toQuote() -> Quote? {
    let trimmedQuote = quote.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuote.isEmpty, !trimmedAuthor.isEmpty else { return nil }

    let categoryValue = LocalQuotes.normalizedCategory(from: self)
    return Quote(
        text: trimmedQuote,
        author: trimmedAuthor,
        category: categoryValue
    )
}
```

注意 fallbackQuotes 数组里的 `Quote(id: "local-N", ...)` 保持不变（显式传了 id，新 init 签名兼容）。

**Step 6: 手动验证**

- [ ] App build & run
- [ ] 在 Feed 点❤️收藏一条
- [ ] 滑到下一条/切到 Favorites tab，再回 Feed
- [ ] 那条卡片心形仍是 fill（红色）
- [ ] 杀掉 App 重启，那条仍然是 fill

**Step 7: Commit**

```bash
git add -A
git commit -m "fix(m1): use SHA256-based stable ID for Quote to prevent favorites desync"
```

---

## Task 5: FavoritesManager 迁到 App Group

> 一行核心修改 + 单元测试。

**Files:**
- Modify: `DailyQuotation/Utils/FavoritesManager.swift`
- Create: `DailyQuotationTests/FavoritesManagerTests.swift`

**Step 1: 写失败的测试**

`DailyQuotationTests/FavoritesManagerTests.swift`：

```swift
import XCTest
@testable import DailyQuotation

final class FavoritesManagerTests: XCTestCase {
    func test_storage_usesSharedDefaults() {
        // 写一条 favorite，验证能从 SharedDefaults 读出
        let manager = FavoritesManager.shared
        let testQuote = Quote(text: "Test quote for storage", author: "TestAuthor")

        let beforeCount = manager.favorites.count
        manager.toggleFavorite(testQuote)
        defer { manager.removeFavorite(testQuote) }

        XCTAssertEqual(manager.favorites.count, beforeCount + 1)

        // 直接读 SharedDefaults 验证持久化位置正确
        let storedData = SharedDefaults.store.data(forKey: "dailyWisdomFavorites")
        XCTAssertNotNil(storedData, "Expected favorites to be persisted in SharedDefaults (App Group)")
    }
}
```

**Step 2: 运行测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:DailyQuotationTests/FavoritesManagerTests 2>&1 | tail -15
```

预期：FAIL（当前实现写到 `.standard`，SharedDefaults 里读不到）

**Step 3: 修改 FavoritesManager**

`DailyQuotation/Utils/FavoritesManager.swift`：替换 `UserDefaults.standard` 为 `SharedDefaults.store`，仅两处：

```swift
func loadFavorites() {
    guard let data = SharedDefaults.store.data(forKey: storageKey),
          let decoded = try? JSONDecoder().decode([Quote].self, from: data)
    else {
        favorites = []
        return
    }
    favorites = decoded
}

func saveFavorites() {
    guard let data = try? JSONEncoder().encode(favorites) else { return }
    SharedDefaults.store.set(data, forKey: storageKey)
}
```

**Step 4: 再次运行测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:DailyQuotationTests/FavoritesManagerTests 2>&1 | tail -10
```

预期：PASS

**Step 5: Commit**

```bash
git add -A
git commit -m "refactor(m1): move favorites storage to App Group via SharedDefaults"
```

---

## Task 6: 统一 Quote/AppearanceSettings Model（去重）

> 需要 Xcode GUI 操作（修改 Target Membership），无单元测试，靠 build 验证。

**Files:**
- Modify (Xcode target membership):
  - `DailyQuotation/Models/Quote.swift`
  - `DailyQuotation/Models/AppearanceSettings.swift`
- Modify: `DailyQuotation/Models/Quote.swift`（加 placeholder）
- Modify: `DailyQuotation/Models/AppearanceSettings.swift`（加 quoteFont 扩展和 fontDesign）
- Modify: `DailyQuotationWidget/WidgetSharedModels.swift`（删除重复定义，只保留 WidgetSharedDefaults）

**Step 1: 把 Models 加到 Widget Target**

在 Xcode 中：

1. 选中 `DailyQuotation/Models/Quote.swift`
2. 右侧 File Inspector → Target Membership
3. 勾上 `DailyQuotationWidgetExtension`
4. 对 `AppearanceSettings.swift` 重复同样操作

**Step 2: 把 Widget 端的扩展移到主 Model**

修改 `DailyQuotation/Models/Quote.swift`，在文件末尾加 placeholder：

```swift
extension Quote {
    static let placeholder: Quote = Quote(
        id: "widget-placeholder",
        text: "Every moment is a fresh beginning.",
        author: "T.S. Eliot",
        category: "Inspiration"
    )
}
```

修改 `DailyQuotation/Models/AppearanceSettings.swift`，加 fontDesign 和 quoteFont：

```swift
import Foundation
import SwiftUI

enum FontFamily: String, Codable, CaseIterable {
    case serif = "serif"
    case sans = "sans"
    case mono = "mono"

    var displayName: String {
        switch self {
        case .serif: return "Classic"
        case .sans: return "Modern"
        case .mono: return "Type"
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .serif: return .serif
        case .sans: return .rounded
        case .mono: return .monospaced
        }
    }
}

enum TextSize: String, Codable, CaseIterable {
    case small = "sm"
    case medium = "md"
    case large = "lg"

    var fontSize: CGFloat {
        switch self {
        case .small: return 26
        case .medium: return 30
        case .large: return 40
        }
    }
}

struct AppearanceSettings: Codable, Hashable {
    var font: FontFamily
    var size: TextSize

    static let `default` = AppearanceSettings(font: .serif, size: .medium)
}

extension AppearanceSettings {
    var quoteFont: Font {
        .system(size: size.fontSize, design: font.fontDesign)
    }
}
```

注意：现在 `Quote` 加了 Hashable，`AppearanceSettings` 也加了 Hashable（Widget 端原本就有）。

**Step 3: 清理 Widget 端的重复定义**

修改 `DailyQuotationWidget/WidgetSharedModels.swift`，只保留 `WidgetSharedDefaults`：

```swift
import Foundation

enum WidgetSharedDefaults {
  private static let appGroupIdentifier = "group.BiBoBiBo.DailyQuotation"

  static var store: UserDefaults {
    UserDefaults(suiteName: appGroupIdentifier) ?? .standard
  }
}
```

注意：顺便把 `fatalError` 也换成 fallback（和 Task 2 保持一致）。

**Step 4: 验证 build**

在 Xcode：
- Product → Build (⌘B) 主 App scheme → 预期 Build Succeeded
- 切到 `DailyQuotationWidgetExtension` scheme → Build → 预期 Build Succeeded
- 运行 Widget Preview（在 `DailyQuotationWidget.swift` 文件里点 Resume）→ 预期正常显示

**Step 5: 跑所有测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" 2>&1 | tail -20
```

预期：之前的 Quote/SharedDefaults/Favorites 测试全部通过。

**Step 6: Commit**

```bash
git add -A
git commit -m "refactor(m1): unify Quote/AppearanceSettings models across App and Widget targets"
```

---

## Task 7: 拆 FeedViewModel

> M1 最大块改动。先写测试定行为，再做拆分。

**Files:**
- Create: `DailyQuotation/Views/Feed/FeedViewModel.swift`
- Modify: `DailyQuotation/Views/FeedView.swift`
- Create: `DailyQuotationTests/FeedViewModelTests.swift`

**Step 1: 写 FeedViewModel 失败的测试**

`DailyQuotationTests/FeedViewModelTests.swift`：

```swift
import XCTest
@testable import DailyQuotation

@MainActor
final class FeedViewModelTests: XCTestCase {

    func test_todayOrder_freeUser_returnsOneQuote() {
        let vm = FeedViewModel(isPremium: false)
        XCTAssertEqual(vm.todayOrder.count, 1)
    }

    func test_todayOrder_premiumUser_returnsMaxDaily() {
        let vm = FeedViewModel(isPremium: true)
        XCTAssertEqual(vm.todayOrder.count, 20)
    }

    func test_totalPositions_premiumWithFullOrder_includesEndCard() {
        let vm = FeedViewModel(isPremium: true)
        XCTAssertEqual(vm.totalPositions, 21) // 20 quotes + 1 end card
    }

    func test_totalPositions_freeUser_noEndCard() {
        let vm = FeedViewModel(isPremium: false)
        XCTAssertEqual(vm.totalPositions, 1) // only 1 quote, no end card
    }

    func test_isEndCard_atLastPositionForPremium() {
        let vm = FeedViewModel(isPremium: true)
        XCTAssertTrue(vm.isEndCard(at: 20))
        XCTAssertFalse(vm.isEndCard(at: 19))
    }

    func test_canMoveForward_freeUser_blockedAfterFirst() {
        let vm = FeedViewModel(isPremium: false)
        XCTAssertFalse(vm.canMoveForward(from: 0))
    }

    func test_canMoveForward_premiumUser_allowedWithinRange() {
        let vm = FeedViewModel(isPremium: true)
        XCTAssertTrue(vm.canMoveForward(from: 0))
        XCTAssertTrue(vm.canMoveForward(from: 19))
        XCTAssertFalse(vm.canMoveForward(from: 20)) // end card 已经是终点
    }

    func test_quoteIndex_returnsCorrectIndex() {
        let vm = FeedViewModel(isPremium: true)
        let order = vm.todayOrder
        XCTAssertEqual(vm.quoteIndex(at: 0), order[0])
        XCTAssertEqual(vm.quoteIndex(at: 19), order[19])
        XCTAssertNil(vm.quoteIndex(at: 20)) // end card 位置，无 quote
    }
}
```

**Step 2: 运行测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:DailyQuotationTests/FeedViewModelTests 2>&1 | tail -30
```

预期：FAIL（`FeedViewModel` 不存在）

**Step 3: 创建 FeedViewModel**

`DailyQuotation/Views/Feed/FeedViewModel.swift`（先 mkdir 这个 subfolder）：

```swift
import Foundation
import SwiftUI

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var currentPosition: Int = 0
    @Published var furthestPosition: Int = 0

    let isPremium: Bool
    let referenceDate: Date

    private let quotes: [Quote]
    private let maxDailyQuotes = 20
    private let freeScrollAllowance = 1

    init(
        isPremium: Bool,
        referenceDate: Date = Date(),
        quotes: [Quote] = LocalQuotes.quotes
    ) {
        self.isPremium = isPremium
        self.referenceDate = referenceDate
        self.quotes = quotes
    }

    var quotesPerDay: Int {
        isPremium ? maxDailyQuotes : freeScrollAllowance
    }

    var todayOrder: [Int] {
        guard !quotes.isEmpty else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: referenceDate)
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: startOfDay).day ?? 0
        let totalQuotes = quotes.count

        let startIndex = (daysSinceStart * quotesPerDay) % totalQuotes
        return (0..<quotesPerDay).map { (startIndex + $0) % totalQuotes }
    }

    var hasEndCard: Bool {
        isPremium && todayOrder.count >= maxDailyQuotes
    }

    var totalPositions: Int {
        todayOrder.count + (hasEndCard ? 1 : 0)
    }

    func isEndCard(at position: Int) -> Bool {
        hasEndCard && position == todayOrder.count
    }

    func canMoveForward(from position: Int) -> Bool {
        let nextPos = position + 1
        if !isPremium && nextPos >= freeScrollAllowance {
            return false
        }
        return nextPos < totalPositions
    }

    func quoteIndex(at position: Int) -> Int? {
        let order = todayOrder
        guard position >= 0, position < order.count else { return nil }
        return order[position]
    }

    func quote(at position: Int) -> Quote? {
        guard let idx = quoteIndex(at: position), !quotes.isEmpty else { return nil }
        let actual = ((idx % quotes.count) + quotes.count) % quotes.count
        return quotes[actual]
    }
}
```

**Step 4: 运行 FeedViewModel 测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:DailyQuotationTests/FeedViewModelTests 2>&1 | tail -20
```

预期：PASS（8/8）

**Step 5: 把 FeedViewModel 加到 Xcode 主 App target**

在 Xcode 中：
1. 右键 `Views` 文件夹 → New Group → 命名 `Feed`
2. 拖入 `FeedViewModel.swift`
3. 确认 Target Membership 包括 DailyQuotation 主 app

**Step 6: 改造 FeedView 使用 ViewModel**

修改 `DailyQuotation/Views/FeedView.swift`，替换所有原 `todayOrder` / `currentPosition` / `freeScrollAllowance` / `maxDailyQuotes` 引用为通过 `@StateObject viewModel` 访问。预期 FeedView 减少到 ~150 行。

完整改造：

```swift
import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @ObservedObject var favoritesManager = FavoritesManager.shared
    @Binding var appearance: AppearanceSettings
    @Binding var persistedIndex: Int
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    var onRequirePaywall: () -> Void = {}

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    init(
        appearance: Binding<AppearanceSettings>,
        persistedIndex: Binding<Int>,
        isPremium: Bool,
        onRequirePaywall: @escaping () -> Void
    ) {
        self._appearance = appearance
        self._persistedIndex = persistedIndex
        self.onRequirePaywall = onRequirePaywall
        self._viewModel = StateObject(wrappedValue: FeedViewModel(isPremium: isPremium))
    }

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            // ... 原有渲染逻辑，把 currentPosition 改为 viewModel.currentPosition
            //     把 todayOrder 改为 viewModel.todayOrder
            //     把 hasEndCard 改为 viewModel.hasEndCard
            //     把 totalPositions 改为 viewModel.totalPositions
            //     把 freeScrollAllowance/maxDailyQuotes 删除（ViewModel 内部用）
            //     gestures 中的判断改用 viewModel.canMoveForward / isEndCard / quoteIndex(at:)
        }
        .ignoresSafeArea(.all)
        .onAppear { /* ... */ }
        .onChange(of: persistedIndex) { /* ... */ }
        .onChange(of: viewModel.currentPosition) { newValue in
            persistedIndex = newValue
        }
        .onChange(of: currentDayOfYear) { _ in /* ... */ }
    }

    // 注意：因为 init 用了 isPremium 作为参数，每次订阅状态变化时
    // 需要外面 ContentView 重新 init FeedView（用 .id() 强制 rebuild），
    // 或在 ViewModel 内观察 subscriptionManager。
    // 简化方案：把 isPremium 改为 .onChange 监听，传给 viewModel 更新内部状态。
}
```

**关键决策**：FeedViewModel 的 `isPremium` 是 init 时传入的不可变值，但用户可能在 app 运行期间订阅。两种处理：
- **方案 A**（推荐）：ContentView 监听 `subscriptionManager.isPremiumUser`，用 `.id(isPremium)` 强制 rebuild FeedView
- **方案 B**：把 isPremium 改为 `@Published`，ViewModel 监听 SubscriptionManager

选**方案 A**（更简洁）。修改 ContentView：

```swift
case .feed:
    FeedView(
        appearance: appearance,
        persistedIndex: $feedCurrentIndex,
        isPremium: subscriptionManager.isPremiumUser,
        onRequirePaywall: { showPaywall = true }
    )
    .id(subscriptionManager.isPremiumUser) // 订阅状态变化时重建 ViewModel
    .environmentObject(subscriptionManager)
```

**Step 7: 跑所有测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" 2>&1 | tail -20
```

预期：所有测试 PASS。

**Step 8: 手动回归测试**

跑完整 M1 手动 checklist：

- [ ] 删 app 重装 → 收藏点过的 quote 在 Feed 上心形依然 fill
- [ ] 切付费（StoreKit testing） → 能看 20 条 + end card
- [ ] 切免费 → 只能看 1 条 + 第 2 条触发 paywall
- [ ] 收藏数 < 3 时点❤️有效；达到 3 时点❤️触发 paywall
- [ ] 用 Modern/Type 字体时（免费）触发 paywall
- [ ] Widget 在 small/medium/large 都正常显示
- [ ] 跨天打开 → quote 内容变化（用模拟器日历改时间测试）

**Step 9: Commit**

```bash
git add -A
git commit -m "refactor(m1): extract FeedViewModel from FeedView for testability"
```

---

## Task 8: 顺手清理 TabBarView 死代码

> M1 收尾。

**Files:**
- Modify: `DailyQuotation/Views/TabBarView.swift`

**Step 1: 删除未使用的 label(for:) 方法**

`DailyQuotation/Views/TabBarView.swift`：删除第 72-79 行的 `private func label(for view: AppView) -> String` 整段（没有任何地方调用）。

**Step 2: 验证 build**

Xcode → Product → Build (⌘B)。预期 OK。

**Step 3: Commit**

```bash
git add -A
git commit -m "chore(m1): remove dead label(for:) helper in TabBarView"
```

---

## Task 9: M1 总验证 + 打 tag

**Step 1: 跑全部单元测试**

```bash
xcodebuild test -project "DailyQuotation/DailyQuotation.xcodeproj" -scheme DailyQuotation -destination "platform=iOS Simulator,name=iPhone 15" 2>&1 | tail -10
```

预期：全部 PASS。

**Step 2: 跑完整手动 checklist**

参见设计文档 §3.8。

**Step 3: 打 tag**

```bash
cd "/Users/alex/Documents/IOS projects"
git tag -a v0.6 -m "M1 complete: stabilize foundation (id, App Group, ViewModel split, dead code removal)"
git log --oneline -10
```

**Step 4: 通知用户 M1 完成**

总结输出：
- 7 个 commit（GeminiService 删 / SharedDefaults / UIScreen / Quote.stableID / FavoritesManager / Models 去重 / FeedViewModel 拆 / TabBarView 死码）
- 4 个单元测试文件（SharedDefaults / Quote / FavoritesManager / FeedViewModel）
- v0.6 tag

---

## 不在 M1 范围内的事项

- ❌ 把 `xcuserstate` 从 git 中移除（需要 `git rm --cached`）— 留到 M2 启动前再做
- ❌ M2/M3 任务 — 各自有独立 plan

## 风险与回滚

如果任何任务出现意外问题：
- 每个任务独立 commit，可用 `git revert <sha>` 单独回滚
- M1 完成前不打 tag，所以不影响 v0.5 的稳定性
- 如果 Task 7（FeedViewModel 拆分）出现回归，可单独 revert 它，其余改动保留
