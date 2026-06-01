# Quoteary 优化与功能迭代设计 v1

**日期**: 2026-06-02
**状态**: Approved · 实施中
**前置背景**: 项目尚未上线，无需考虑老用户兼容

## 1. 目标

在 5-6.5 个工作日内完成 3 个 milestone 的工作：
1. 修复 3 个 bug 级问题、清理架构债（M1）
2. 加入两个高 ROI 用户感知功能（M2）
3. 加入探索/搜索 + 每日推送（M3）

每个 milestone 独立可发版，独立可 commit，独立可回滚。

## 2. 整体架构

- **目标 iOS**: 18+（保持）
- **架构**: SwiftUI + 轻量 `@MainActor ObservableObject` ViewModel
- **数据存储**: 全部统一到 App Group (`group.BiBoBiBo.DailyQuotation`)
- **依赖**: 不引入新的第三方库
- **i18n**: 本轮不做，但新字符串走 `String(localized:)` 为下版铺路
- **测试**: 对纯逻辑工具类写 XCTest 单元测试，View 不写 UI 测试

TabBar 最终形态（M3 之后）：

```
┌──────────┬──────────┬───────────┐
│   Feed   │  Explore │ Favorites │
│ (现有)   │ (M3 新增)│ (现有+齿轮)│
└──────────┴──────────┴───────────┘
                                 ↓
                          SettingsView
                          (M2 简版 → M3 完整版)
```

## 3. M1 — 稳基础（1-1.5 天）

### 3.1 Quote ID 稳定化

**问题**: `Quote.id` 用 `UUID()` 生成，每次启动重新读 `quotes.json` 时 id 都变。`FavoritesManager.isFavorite` 按 id 比较，会导致收藏判定不稳。

**方案**:
- 新增 `Quote.stableID(text:author:) -> String`：用 SHA256(text + "|" + author) 前 16 hex
- `Quote.init` 不传 id 时默认走 `stableID`
- `LocalQuotes` 解析 `quotes.json` 时改用稳定 id
- **不写迁移代码**（无老用户）

**成功标准**:
1. 同样的 text+author 调用多次 `stableID(...)` 返回同一字符串
2. 删除 app → 重装 → 收藏不消失（原本就 OK，回归测试）
3. 同一 quote 在 Feed 和 Favorites 之间，`isFavorite` 判定一致

### 3.2 SharedDefaults Fallback

**问题**: App Group 不可用时 `fatalError` 闪退。

**方案**:
```swift
static var store: UserDefaults {
  UserDefaults(suiteName: appGroupIdentifier) ?? .standard
}
```

**成功标准**: 故意删除 entitlements 后能启动（fallback 到 standard），且 print 警告。

### 3.3 FavoritesManager 迁 App Group

**问题**: 与 `AppearanceManager` 不一致，且 Widget/Intent 拿不到收藏。

**方案**: `storageKey` 改为 `SharedDefaults.store` 引用。仅一行修改。

**成功标准**: 收藏数据写入 App Group 后能在 Widget 读到（写一个临时测试函数验证）。

### 3.4 统一 Model（去重）

**问题**: `Quote`/`AppearanceSettings`/`FontFamily`/`TextSize` 在主 App 和 Widget 各定义一份。

**方案**:
- 在 Xcode 中把 `DailyQuotation/Models/Quote.swift` 和 `AppearanceSettings.swift` 的 **Target Membership** 勾上 Widget
- 把 Widget 端 `WidgetSharedModels.swift` 的 `Quote.placeholder` 和 `AppearanceSettings.quoteFont` 扩展挪到主 Model 文件
- 删除 Widget 端的重复定义，只保留 `WidgetSharedDefaults`

**成功标准**: 主 app + Widget 都能编译通过；Widget Preview 正常。

### 3.5 拆 FeedViewModel

**问题**: `FeedView` 270 行，逻辑全揉在一起，无法单元测试。

**方案**:
- 新增 `Views/Feed/FeedViewModel.swift`（`@MainActor ObservableObject`），承担：
  - `todayOrder` 计算（含 quotesPerDay、startIndex）
  - `currentPosition` / `furthestPosition` 状态
  - 订阅 gating（`canScrollNext`、`shouldShowPaywall`、`endCardAllowance`）
- `FeedView` 只保留渲染、手势、动画
- 预期 `FeedView` 从 270 → ~150 行

**成功标准**:
1. 行为完全一致：免费 1 条、付费 20 条 + end card 都正常
2. `FeedViewModel` 可在测试里独立实例化并断言

### 3.6 删 GeminiService + Info.plist 清理

**方案**:
- 删 `Services/GeminiService.swift` 整个文件
- 删 `Services/` 目录（如果空了）
- `Info.plist` 删 `GEMINI_API_KEY` 键
- `Info.plist` 删 `NSAppTransportSecurity` 整段
- `Info.plist` 删 `UIRequiredDeviceCapabilities` 里的 `armv7`

**成功标准**: 编译通过，无 Gemini 相关 dead code。

### 3.7 替换 UIScreen.main

**方案**: `FeedView`、`ContentView` 中所有 `UIScreen.main.bounds.{width,height}` 改用 `GeometryReader` 拿到的尺寸（通过 `@State` 缓存即可，性能 OK）。

**成功标准**: 编译无 deprecation warning，多设备尺寸表现正常。

### 3.8 M1 验证 Checklist（手动）

- [ ] 删 app 重装 → 收藏点过的 quote 在 Feed 上心形依然 fill
- [ ] 改 bundle id（临时）→ App Group 不可用 → app 不闪退
- [ ] 切付费 → 能看 20 条 + end card
- [ ] 切免费 → 只能看 1 条 + 第 2 条触发 paywall
- [ ] Widget 在 small/medium/large 都正常显示
- [ ] 跨天打开 → quote 内容变化
- [ ] 所有 ViewModel/Util 单元测试通过

## 4. M2 — 高 ROI 新功能（1.5-2 天）

### 4.1 分享卡片（导出海报）

**入口**: `QuoteSlideView` 加第三个 action button（位置：心形和 textformat 之间或右边）。

**实现**:
- `Views/Share/ShareCardView.swift`：纯 SwiftUI，1080×1920 渲染目标，复用当前 quote 的 `GradientColors` 渐变 + Quote 文字 + 作者 + 底部水印
- `Views/Share/ShareCardSheet.swift`：预览 + `ShareLink`
- 用 `ImageRenderer` 渲染 → `UIImage` → 通过 `ShareLink(item: Image(uiImage:))` 分享

**水印策略**:
- 免费用户：水印强制显示
- 付费用户：在卡片底部加一个 toggle "Show watermark"，默认显示，可关

**成功标准**:
1. 任意 quote 都能导出图片
2. 免费用户无法去除水印
3. 付费用户可去除
4. 导出图片在相册显示无模糊

### 4.2 历史日历回看（💎 完全付费）

**入口（M2 临时）**: `FavoritesListView` 顶部加按钮区 → "History"
**入口（M3 最终）**: 移到 Explore tab

**实现**:
- `Views/History/HistoryCalendarView.swift`：`DatePicker(.graphical)` 限制 dateRange 为 (2025-01-01 ... 今天)
- 选某一天 → push `HistoryFeedView`，用 `FeedViewModel` 接受 `date` 参数反推那天的 20 条 quote
- 免费用户进入 `HistoryCalendarView` 立即触发 paywall（不让看日历本身）

**成功标准**:
1. 选 2025-06-01 看到的 quotes 与那天打开 app 时一致
2. 历史页里收藏 ❤️ 同步到 Favorites
3. 免费用户点入口立即弹 paywall

### 4.3 Favorites 右上角齿轮 + 简版 SettingsView

**FavoritesListView 顶部**:
- 左：History 按钮（`calendar` 图标）
- 右：Settings 按钮（`gear` 图标）

**SettingsView 内容（M2 简版）**:
- "Manage Subscription"（`AppStore.showManageSubscriptions(in:)`）
- "Restore Purchases"
- "Privacy Policy"（占位 URL）
- "About"（版本号 from Bundle）

**成功标准**: 各按钮均能跳转/触发，无空操作。

### 4.4 M2 验证 Checklist

- [ ] 分享按钮在 QuoteSlide 上显示且可点
- [ ] 海报渲染清晰
- [ ] 免费用户水印不可隐藏
- [ ] 付费用户可隐藏水印
- [ ] 历史日历可选过去任意一天
- [ ] 历史页 quote 与算法一致
- [ ] 免费用户进历史弹 paywall
- [ ] Favorites 顶部按钮正常工作
- [ ] Settings 各项跳转/触发正常

## 5. M3 — 探索 + 推送（2.5-3 天）

### 5.1 Explore Tab（新增）

**TabBar 改动**:
- `AppView` enum 加 `case explore`，order 1
- icon: 未选 `magnifyingglass` / 选中 `magnifyingglass.circle.fill`
- `TabBarView` 中 accentColor 给 Explore 一个独立色（建议蓝）

**ExploreView 结构**:
```
┌──────────────────────┐
│ [Search bar]         │
│                      │
│ Today's Pick         │
│ [横滚 quote 卡]      │
│                      │
│ Browse by Category   │
│ [Inspiration][Life]  │  ← 标签云
│ [Success][Love]...   │
│                      │
│ Top Authors          │
│ [Einstein][Twain]... │  ← 横滚
│                      │
│ History Calendar 💎  │  ← M2 入口移到这
└──────────────────────┘
```

**搜索实现**:
- 简单实现：内存全量过滤 `text.localizedCaseInsensitiveContains(query) || author.localizedCaseInsensitiveContains(query)`
- 10000 条数据 < 100ms，不引入索引库
- 输入加 300ms debounce

**分类/作者实现**:
- `Utils/QuoteIndex.swift`：启动时一次性按 `category` 和 `author` 分组（`Dictionary(grouping:by:)`），缓存
- 点 category → push `CategoryQuotesView`（纯 List）
- 点 author → push `AuthorQuotesView`（同样的 List）

**成功标准**:
1. 输入关键词能在 300ms 内显示结果
2. 点 category 进入子列表，内容正确
3. 历史日历从 Favorites 移到 Explore 后入口仍能用

### 5.2 每日推送提醒

**权限申请时机**: 用户**首次进设置打开开关**时申请，不在启动时打扰。

**SettingsView 新增**:
- Toggle: "Daily Reminder"
- 时间选择器：`DatePicker(...hourAndMinute)`，默认 09:00
- 副本说明："We'll send you a quote every day at the time you choose."

**实现**:
- `Utils/NotificationManager.swift`：
  - `requestAuthorizationIfNeeded() async -> Bool`
  - `scheduleDailyReminder(hour:minute:) async`：取消旧 → 用 `UNCalendarNotificationTrigger(dateMatching:..., repeats: true)` 注册
  - 通知内容：当天的 `DailyQuoteSync.todayIndex` 对应 quote 的 text 截前 80 字
- App 启动时 `DailyQuoteSync.syncTodayIfNeeded` 之后，若推送已启用且日期变化，重新调度（确保明天看到新 quote）

**iOS 局限**:
- 本地通知不能动态计算"明天的 quote"，只能预先调度
- 解决：app 启动时检测日期变化 → 重排
- 用户改系统时间会导致时机错乱（接受）
- 64 个 pending 通知限制：我们只 1 个，无关

**成功标准**:
1. 关闭推送 → 系统通知中心无 pending
2. 开启 → 系统通知中心能看到调度
3. 改时间 → 旧调度被覆盖
4. 模拟器手动触发通知能预览内容

### 5.3 SettingsView 扩展（完整版）

承载：
- 推送相关（5.2）
- 已有的订阅管理、Restore、Privacy、About
- (可选) 分类偏好：选哪些 category 进 Feed → 若实现，需修改 `FeedViewModel.todayOrder` 加 filter

**默认不做"分类偏好"**：保持 YAGNI，等用户反馈再说。

### 5.4 M3 验证 Checklist

- [ ] TabBar 显示 3 个 tab
- [ ] Explore tab 内搜索可用
- [ ] 分类标签云正常显示
- [ ] 作者横滚正常显示
- [ ] 历史日历入口在 Explore 内可用
- [ ] 开启 Daily Reminder 触发权限申请
- [ ] 选择时间 + 开关后通知正确调度
- [ ] 关闭 Daily Reminder 通知被取消
- [ ] App 跨天启动后通知内容刷新

## 6. 测试策略

只对纯逻辑工具类写 XCTest。View 不写 UI 测试（ROI 太低）。

| 测试目标 | 文件 | Cases |
|---|---|---|
| `Quote.stableID` | `QuoteTests.swift` | 同 text+author → 同 id；不同 → 不同；空字符串边界 |
| `DailyQuoteSync` | `DailyQuoteSyncTests.swift` | 同一天多次幂等；跨天换 quote；syncTodayIfNeeded 写入数据可读出 |
| `FeedViewModel.todayOrder` | `FeedViewModelTests.swift` | 免费 1 条；付费 20 条；跨天位移；订阅状态切换 |
| `NotificationManager` | `NotificationManagerTests.swift` | 调度参数正确（注入 UNUserNotificationCenter mock） |
| `QuoteIndex` | `QuoteIndexTests.swift` | 按 category 分组正确；按 author 分组正确；空 category 不爆 |
| 搜索过滤 | `ExploreSearchTests.swift` | 大小写不敏感；多关键词；空 query 返回原集 |

新建 `DailyQuotationTests` target（如果尚未存在）。

## 7. 风险与兜底

| 风险 | 影响 | 兜底 |
|---|---|---|
| stableID 算法将来需改 | 收藏 id 不再匹配 | 一次定型；future 通过版本化 migration 处理 |
| FeedViewModel 拆分引入回归 | Feed 行为变化 | M1.8 手动 checklist 全跑一遍 |
| 推送权限被拒 | UI 显示开关但通知不响 | Toggle 状态 = 系统权限 ∩ 用户偏好；被拒时按钮置灰并提示"请到系统设置开启" |
| iOS 18 `.glassEffect` 模拟器异常 | TabBar 显示错位 | 提供 fallback：`.ultraThinMaterial` |
| 10000 条全量搜索卡顿 | Explore 慢 | 加 debounce；真卡再上 Task |
| ImageRenderer 在低端机渲染慢 | 分享体验差 | 渲染时显示 progress；失败时降级到 1080×1080 |

## 8. 显式 YAGNI（本三轮 milestone **不**做）

- 国际化（i18n）— 下版
- 浅色模式 / 主题色定制
- Lock Screen Widget / StandBy / Live Activity
- 主题包 / 专题包
- iCloud 同步收藏
- AI 生成名言（GeminiService 删除）
- Onboarding（首次启动引导）
- 笔记/感想功能
- 分类偏好（除非 M3 时间充裕）

## 9. 不在本设计内但已记录的代码味道

- `TabBarView.label(for:)` 是死代码（顺手在 M1 删）
- `Info.plist` 里 `UIRequiredDeviceCapabilities = ["armv7"]` 是 iOS 7 时代写法（M1 删）
- `UserInterfaceState.xcuserstate` 被 git 跟踪（M1 完成后用 `git rm --cached` + .gitignore 处理）

## 10. 提交策略

- 每个 sub-task 独立 commit（M1.1/M1.2/...），便于回滚和 review
- commit message 格式：`feat/fix/refactor/chore(scope): description`
- M1/M2/M3 完成后各打一个 git tag（v0.6 / v0.7 / v0.8）
- 直接 commit 到 main（用户已确认不需要 PR 流程）
