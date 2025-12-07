# iOS 应用设置指南

本指南将帮助您将 Daily Wisdom 应用设置为可在 iPhone/iPad 上运行的 iOS 应用。

## 前置要求

1. **macOS** - iOS 开发只能在 macOS 上进行
2. **Xcode** (最新版本，推荐 15.0+) - 从 App Store 安装
3. **Node.js** (v18+) - 从 [nodejs.org](https://nodejs.org/) 安装
4. **CocoaPods** - iOS 依赖管理工具
   ```bash
   sudo gem install cocoapods
   ```
5. **React Native CLI** (可选，但推荐)
   ```bash
   npm install -g react-native-cli
   ```

## 项目结构说明

本项目已转换为 React Native，包含以下主要变更：

- ✅ 所有组件已转换为 React Native 组件
- ✅ `localStorage` 已替换为 `AsyncStorage`
- ✅ Web 样式已转换为 React Native StyleSheet
- ✅ 图标库使用 `lucide-react-native`
- ✅ 使用 `react-native-safe-area-context` 处理安全区域

## 安装步骤

### 1. 安装依赖

```bash
# 安装 npm 依赖
npm install

# 安装 iOS CocoaPods 依赖
cd ios
pod install
cd ..
```

### 2. 配置 API Key

您需要设置 Google Gemini API Key。有几种方式：

#### 方式 A: 使用环境变量（推荐用于开发）

创建 `.env` 文件（在项目根目录）：

```bash
GEMINI_API_KEY=your_api_key_here
```

然后安装 `react-native-config`：

```bash
npm install react-native-config
cd ios
pod install
cd ..
```

在 `App.tsx` 中导入：

```typescript
import Config from 'react-native-config';
const GEMINI_API_KEY = Config.GEMINI_API_KEY;
```

#### 方式 B: 直接在代码中设置（仅用于测试）

在 `App.tsx` 中直接设置（不推荐用于生产环境）：

```typescript
const GEMINI_API_KEY = 'your_api_key_here';
```

#### 方式 C: 使用 Xcode 的 Build Settings

1. 在 Xcode 中打开项目
2. 选择项目 → Build Settings
3. 添加 `GEMINI_API_KEY` 到 User-Defined Settings
4. 在 Info.plist 中引用

### 3. 创建 Xcode 项目

如果 `ios` 目录下还没有完整的 Xcode 项目，您需要初始化：

```bash
# 使用 React Native CLI 初始化（如果还没有项目）
npx react-native init DailyWisdom --template react-native-template-typescript

# 或者手动创建项目结构
```

**注意**: 由于 React Native 项目需要完整的 Xcode 项目结构，建议使用以下方法之一：

#### 方法 1: 使用 React Native CLI（推荐）

```bash
# 在项目根目录外创建新项目
cd ..
npx react-native init DailyWisdomApp --template react-native-template-typescript

# 然后将我们的代码复制过去
cp -r daily_quotes-main/* DailyWisdomApp/
cd DailyWisdomApp
npm install
cd ios && pod install && cd ..
```

#### 方法 2: 手动创建 Xcode 项目

1. 打开 Xcode
2. File → New → Project
3. 选择 "App"
4. 填写项目信息：
   - Product Name: `DailyWisdom`
   - Team: 选择您的开发团队
   - Organization Identifier: `com.yourcompany`
   - Language: Objective-C
   - Interface: Storyboard
5. 保存到 `ios` 目录

然后需要手动配置 React Native 集成（较复杂，不推荐）。

## 运行应用

### 在模拟器上运行

```bash
# 启动 Metro bundler
npm start

# 在另一个终端运行 iOS 应用
npm run ios

# 或指定模拟器
npm run ios -- --simulator="iPhone 15 Pro"
```

### 在真机上运行

1. 用 USB 连接您的 iPhone/iPad
2. 在 Xcode 中选择您的设备作为运行目标
3. 确保设备已信任您的开发者证书
4. 运行：

```bash
npm run ios -- --device
```

或在 Xcode 中直接点击运行按钮。

## 构建应用

### 开发构建

```bash
npm run ios
```

### 发布构建（生成 IPA）

1. 在 Xcode 中打开 `ios/DailyWisdom.xcworkspace`
2. 选择 Product → Scheme → Edit Scheme
3. 将 Build Configuration 设置为 "Release"
4. Product → Archive
5. 等待归档完成后，选择 "Distribute App"
6. 选择分发方式（App Store、Ad Hoc、Enterprise 等）

### 使用命令行构建

```bash
cd ios
xcodebuild -workspace DailyWisdom.xcworkspace \
           -scheme DailyWisdom \
           -configuration Release \
           -archivePath build/DailyWisdom.xcarchive \
           archive

# 导出 IPA
xcodebuild -exportArchive \
           -archivePath build/DailyWisdom.xcarchive \
           -exportPath build \
           -exportOptionsPlist ExportOptions.plist
```

## 常见问题

### 1. Pod 安装失败

```bash
# 清理并重新安装
cd ios
rm -rf Pods Podfile.lock
pod deintegrate
pod install
cd ..
```

### 2. Metro bundler 端口被占用

```bash
# 杀死占用 8081 端口的进程
lsof -ti:8081 | xargs kill -9

# 或使用其他端口
npm start -- --port 8082
```

### 3. 构建错误：找不到模块

```bash
# 清理构建缓存
cd ios
rm -rf build
xcodebuild clean
cd ..
npm start -- --reset-cache
```

### 4. API Key 未设置错误

确保您已经按照上面的步骤设置了 `GEMINI_API_KEY`。检查：

- `.env` 文件是否存在且包含正确的 key
- `react-native-config` 是否正确安装和配置
- 重新构建应用（环境变量更改需要重新构建）

### 5. 图标显示问题

确保 `lucide-react-native` 已正确安装：

```bash
npm install lucide-react-native
cd ios && pod install && cd ..
```

## 项目结构

```
daily_quotes-main/
├── App.tsx                 # 主应用组件
├── index.js                # React Native 入口
├── components/             # UI 组件
│   ├── Feed.tsx
│   ├── QuoteSlide.tsx
│   ├── FavoritesList.tsx
│   └── TabBar.tsx
├── services/               # 服务层
│   └── gemini.ts
├── config/                 # 配置文件
│   └── env.ts
├── types.ts               # TypeScript 类型定义
├── ios/                   # iOS 原生项目
│   ├── Podfile
│   ├── Info.plist
│   └── DailyWisdom/      # Xcode 项目文件
└── package.json
```

## 下一步

- ✅ 应用已成功转换为 React Native
- ✅ 所有组件已适配 iOS
- ✅ 样式遵循 iOS 设计规范
- 🔄 测试应用功能
- 🔄 优化性能和用户体验
- 🔄 准备 App Store 发布

## 技术支持

如果遇到问题，请检查：

1. React Native 文档: https://reactnative.dev/docs/getting-started
2. Xcode 文档: https://developer.apple.com/xcode/
3. CocoaPods 文档: https://cocoapods.org/

祝您开发顺利！🎉

