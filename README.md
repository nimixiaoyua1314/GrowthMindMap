# 成长心图 (Growth Mind Map)

一个基于 iOS 的个人成长记录与分析应用。

## 核心功能

- **📖 记录人生经历** — 记录重要的生活事件，标注情绪、影响度和感悟
- **✍️ 撰写日记** — 每日日记，记录心情、天气和思考
- **🔍 特质分析** — 基于经历和日记分析核心人格特质，展示雷达图
- **🎯 人生使命** — 推断个性化的人生使命方向
- **💡 行动建议** — 生成即时行动、短期目标和长期方向的建议
- **🧠 AI 深度分析** — 可选接入 Claude API 进行更深度的分析

## 技术栈

| 层面 | 技术 |
|------|------|
| UI | SwiftUI |
| 架构 | MVVM |
| 持久化 | Core Data (程序化模型) |
| 最低版本 | iOS 16.0 |
| 语言 | Swift 5.9 |

## 项目结构

```
成长心图/
├── project.yml                    # XcodeGen 项目配置
├── README.md
└── 成长心图/
    ├── App/
    │   └── 成长心图App.swift       # 应用入口
    ├── Models/
    │   └── AppModels.swift         # 枚举和类型定义
    ├── CoreData/
    │   ├── PersistenceController.swift
    │   ├── CoreDataModel.swift     # 程序化数据模型
    │   └── Extensions/            # NSManagedObject 子类
    ├── ViewModels/
    │   ├── ExperienceViewModel.swift
    │   ├── DiaryViewModel.swift
    │   ├── AnalysisViewModel.swift
    │   └── SuggestionViewModel.swift
    ├── Views/
    │   ├── MainTabView.swift
    │   ├── Experience/            # 经历模块
    │   ├── Diary/                 # 日记模块
    │   ├── Analysis/              # 分析模块
    │   ├── Suggestions/           # 建议模块
    │   └── Profile/               # 个人中心
    ├── Services/
    │   ├── AnalysisEngine.swift   # 本地分析引擎
    │   ├── SuggestionEngine.swift # 建议引擎
    │   ├── KeywordExtractor.swift # 中文关键词提取
    │   └── LLMService.swift      # AI 深度分析服务
    ├── Extensions/
    │   ├── Color+Theme.swift      # 主题色
    │   ├── Date+Extensions.swift
    │   └── View+Extensions.swift
    └── Resources/
        ├── Info.plist
        └── Assets.xcassets/
```

## 快速开始

### 方法一：使用 XcodeGen（推荐）

1. 安装 XcodeGen:
```bash
brew install xcodegen
```

2. 在项目根目录生成 Xcode 项目:
```bash
cd /Volumes/拓展空间/成长心图
xcodegen generate
```

3. 打开生成的 `成长心图.xcodeproj`，选择模拟器运行。

### 方法二：手动创建 Xcode 项目

1. 打开 Xcode → New Project → iOS App
2. 项目名设为「成长心图」，选择 SwiftUI
3. 将 `成长心图/` 目录下的所有 Swift 文件拖入项目
4. 确保 Info.plist 引用正确
5. 运行

## 分析引擎说明

### 本地分析（默认可用）
- 使用 NaturalLanguage 框架进行中文分词
- 基于关键词匹配、情绪模式、行为模式进行特质评分
- 14 种预定义特质词典，每种特质有对应的关键词映射
- 分析维度：情感模式(30%)、行为模式(25%)、价值观(25%)、成长轨迹(20%)

### AI 深度分析（可选）
- 在「我的」→「AI 配置」中设置 API Key
- 支持 Claude API（默认）和其他兼容接口
- 分析数据会脱敏处理

## 色彩方案

- 主色：`#6B5B9A` 深紫（智慧）
- 辅色：`#F4A261` 暖橙（活力）
- 背景：`#FAF7F2` 米白
- 暗黑模式完整支持

## License

MIT
