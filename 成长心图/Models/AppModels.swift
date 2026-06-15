import Foundation

// MARK: - 经历分类
enum ExperienceCategory: String, CaseIterable, Identifiable {
    case 教育 = "教育"
    case 职业 = "职业"
    case 关系 = "关系"
    case 健康 = "健康"
    case 旅行 = "旅行"
    case 其他 = "其他"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .教育: return "book.fill"
        case .职业: return "briefcase.fill"
        case .关系: return "heart.fill"
        case .健康: return "heart.text.square.fill"
        case .旅行: return "airplane"
        case .其他: return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .教育: return "4D96FF"
        case .职业: return "6B5B9A"
        case .关系: return "E76F51"
        case .健康: return "6BCB77"
        case .旅行: return "4CAF50"
        case .其他: return "9B9B9B"
        }
    }
}

// MARK: - 情绪标签
enum EmotionTag: String, CaseIterable, Identifiable {
    case 喜悦 = "喜悦"
    case 悲伤 = "悲伤"
    case 焦虑 = "焦虑"
    case 平静 = "平静"
    case 兴奋 = "兴奋"
    case 感恩 = "感恩"
    case 愤怒 = "愤怒"
    case 期待 = "期待"
    case 满足 = "满足"
    case 压力 = "压力"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .喜悦: return "😊"
        case .悲伤: return "😢"
        case .焦虑: return "😰"
        case .平静: return "😌"
        case .兴奋: return "🤩"
        case .感恩: return "🙏"
        case .愤怒: return "😤"
        case .期待: return "✨"
        case .满足: return "😌"
        case .压力: return "😫"
        }
    }
}

// MARK: - 心情等级
enum MoodLevel: Int, CaseIterable, Identifiable {
    case terrible = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case excellent = 5

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .terrible: return "很差"
        case .bad: return "不好"
        case .neutral: return "一般"
        case .good: return "不错"
        case .excellent: return "很好"
        }
    }

    var iconName: String {
        switch self {
        case .terrible: return "face.dashed"
        case .bad: return "face.smiling"
        case .neutral: return "face.neutral"
        case .good: return "face.smiling.fill"
        case .excellent: return "face.dashed.fill"
        }
    }
}

// MARK: - 天气图标
enum WeatherIcon: String, CaseIterable, Identifiable {
    case sunny = "sun.max.fill"
    case cloudy = "cloud.fill"
    case rainy = "cloud.rain.fill"
    case snowy = "cloud.snow.fill"
    case windy = "wind"
    case rainbow = "rainbow"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunny: return "晴"
        case .cloudy: return "多云"
        case .rainy: return "雨"
        case .snowy: return "雪"
        case .windy: return "风"
        case .rainbow: return "彩虹"
        }
    }
}

// MARK: - 特质定义
struct TraitDefinition: Identifiable {
    let id = UUID()
    let name: String
    let keywords: [String]
    let description: String
}

/// 预定义特质库
enum TraitLibrary {
    static let allTraits: [TraitDefinition] = [
        TraitDefinition(name: "创造力", keywords: ["创新", "设计", "写作", "艺术", "想象", "灵感", "创作", "构想"],
                        description: "你拥有丰富的想象力和创造欲望，善于生成新想法并将其实现"),
        TraitDefinition(name: "坚韧", keywords: ["克服", "坚持", "困难", "挑战", "不放弃", "逆境", "毅力", "突破"],
                        description: "面对困难时你展现出非凡的韧性，能够坚持不懈直到目标达成"),
        TraitDefinition(name: "同理心", keywords: ["理解", "感受", "帮助", "关心", "倾听", "共情", "体谅", "支持"],
                        description: "你能够深刻理解他人的感受，这使你成为天然的倾听者和支持者"),
        TraitDefinition(name: "领导力", keywords: ["带领", "组织", "决策", "负责", "团队", "引导", "协调", "统筹"],
                        description: "你具有组织和引领他人的天赋，能在关键时刻做出果断决策"),
        TraitDefinition(name: "好奇心", keywords: ["探索", "学习", "新知", "尝试", "发现", "研究", "钻研", "求索"],
                        description: "你对世界充满好奇，不断探索未知领域，学习是你内在的驱动力"),
        TraitDefinition(name: "自律", keywords: ["坚持", "习惯", "规律", "克制", "计划", "执行", "专注", "纪律"],
                        description: "你拥有强大的自我管理能力，能够按照计划稳步前进"),
        TraitDefinition(name: "乐观", keywords: ["希望", "积极", "机会", "美好", "未来", "信心", "光明", "向上"],
                        description: "你总是能在困难中看到希望，积极的视角让你充满能量"),
        TraitDefinition(name: "分析力", keywords: ["思考", "逻辑", "分析", "推理", "问题", "解决", "判断", "洞察"],
                        description: "你擅长深入思考和分析问题，能洞察事物的本质和规律"),
        TraitDefinition(name: "社交力", keywords: ["朋友", "交流", "聚会", "关系", "沟通", "连接", "分享", "互动"],
                        description: "你在人际互动中游刃有余，善于建立和维护深厚的关系"),
        TraitDefinition(name: "冒险精神", keywords: ["冒险", "挑战", "未知", "旅行", "尝试", "勇气", "突破", "探索"],
                        description: "你不畏惧未知，愿意走出舒适区去体验新事物"),
        TraitDefinition(name: "耐心", keywords: ["等待", "沉淀", "慢慢", "耐心", "积累", "持久", "深耕", "沉淀"],
                        description: "你明白成长需要时间，愿意静待花开，不急不躁"),
        TraitDefinition(name: "感恩", keywords: ["感谢", "珍惜", "感恩", "幸运", "回馈", "知足", "珍视", "感激"],
                        description: "你心怀感恩，珍惜生活中的每一份恩赐和遇见"),
        TraitDefinition(name: "独立性", keywords: ["独立", "自主", "独自", "自我", "自由", "自主性", "独当一面", "独立人格"],
                        description: "你拥有强烈的独立意识，能够自主决策并为自己的选择负责"),
        TraitDefinition(name: "适应性", keywords: ["适应", "调整", "灵活", "变化", "变通", "应变", "融入", "转换"],
                        description: "你能快速适应环境变化，在各种情况下都能找到自己的位置"),
    ]
}

// MARK: - 建议分类
enum SuggestionCategory: String, CaseIterable, Identifiable {
    case 即时行动 = "即时行动"
    case 短期目标 = "短期目标"
    case 长期方向 = "长期方向"
    case 个人成长 = "个人成长"
    case 人际关系 = "人际关系"
    case 职业发展 = "职业发展"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .即时行动: return "bolt.fill"
        case .短期目标: return "target"
        case .长期方向: return "compass.drawing"
        case .个人成长: return "person.fill.viewfinder"
        case .人际关系: return "person.2.fill"
        case .职业发展: return "chart.line.uptrend.xyaxis"
        }
    }
}
