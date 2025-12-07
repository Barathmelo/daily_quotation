# Daily Wisdom - iOS 应用

这是一个每日名言应用，已从 Web 应用转换为 React Native iOS 应用。

## 快速开始

### 1. 安装依赖

```bash
npm install
cd ios && pod install && cd ..
```

### 2. 设置 API Key

创建 `.env` 文件：

```bash
GEMINI_API_KEY=your_gemini_api_key_here
```

或安装 `react-native-config` 来管理环境变量。

### 3. 运行应用

```bash
# 启动 Metro bundler
npm start

# 在另一个终端运行 iOS 应用
npm run ios
```

## 主要特性

- 📱 原生 iOS 体验
- 🎨 精美的渐变背景和动画
- 💾 本地收藏功能（使用 AsyncStorage）
- ⚙️ 可自定义字体和大小
- 🔄 下拉刷新获取新名言
- 📖 使用 Google Gemini API 生成名言

## 技术栈

- **React Native** - 跨平台移动应用框架
- **TypeScript** - 类型安全
- **AsyncStorage** - 本地数据存储
- **Google Gemini API** - AI 生成名言
- **Lucide React Native** - 图标库
- **React Native Safe Area Context** - 安全区域处理

## 项目结构

```
├── App.tsx                 # 主应用入口
├── components/             # UI 组件
│   ├── Feed.tsx          # 名言流
│   ├── QuoteSlide.tsx    # 单个名言卡片
│   ├── FavoritesList.tsx # 收藏列表
│   └── TabBar.tsx        # 底部导航栏
├── services/
│   └── gemini.ts         # Gemini API 服务
├── config/
│   └── env.ts            # 环境配置
└── types.ts              # TypeScript 类型
```

## 构建说明

详细说明请参阅 [IOS_SETUP.md](./IOS_SETUP.md)

## 许可证

MIT

