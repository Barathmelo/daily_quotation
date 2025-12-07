# 快速启动指南

## 前提条件检查

在开始之前，请确保您已安装：

- ✅ macOS（iOS 开发必需）
- ✅ Xcode（从 App Store 安装）
- ✅ Node.js v18+ (`node --version`)
- ✅ CocoaPods (`pod --version`)

如果没有安装 CocoaPods：
```bash
sudo gem install cocoapods
```

## 5 分钟快速启动

### 步骤 1: 安装依赖

```bash
npm install
cd ios && pod install && cd ..
```

### 步骤 2: 设置 API Key

创建 `.env` 文件：

```bash
echo "GEMINI_API_KEY=your_api_key_here" > .env
```

**或者**直接在 `App.tsx` 中设置（仅用于测试）：

```typescript
const GEMINI_API_KEY = 'your_api_key_here';
```

### 步骤 3: 运行应用

```bash
# 终端 1: 启动 Metro bundler
npm start

# 终端 2: 运行 iOS 应用
npm run ios
```

## 如果遇到问题

### 问题: "Command not found: pod"

```bash
sudo gem install cocoapods
```

### 问题: Pod 安装失败

```bash
cd ios
rm -rf Pods Podfile.lock
pod deintegrate
pod install
cd ..
```

### 问题: Metro bundler 端口被占用

```bash
lsof -ti:8081 | xargs kill -9
npm start
```

### 问题: 需要完整的 Xcode 项目

如果您看到 "No Xcode project found" 错误，您需要初始化 React Native 项目：

```bash
# 方法 1: 使用 React Native CLI（推荐）
npx react-native init DailyWisdomApp --template react-native-template-typescript
# 然后复制我们的代码到新项目

# 方法 2: 手动创建（见 IOS_SETUP.md）
```

## 下一步

- 📖 阅读 [IOS_SETUP.md](./IOS_SETUP.md) 了解详细配置
- 🎨 自定义应用样式和功能
- 📱 在真机上测试
- 🚀 准备发布到 App Store

## 需要帮助？

查看详细文档：
- [IOS_SETUP.md](./IOS_SETUP.md) - 完整设置指南
- [README_IOS.md](./README_IOS.md) - 项目概述

