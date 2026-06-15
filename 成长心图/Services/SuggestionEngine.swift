import Foundation

/// 建议项
struct SuggestionItem {
    let title: String
    let descriptionText: String
    let category: String
    let priority: Int16
    let relatedTrait: String
    let deadline: Date?
}

/// 本地建议引擎
final class SuggestionEngine {

    /// 基于分析结果生成建议
    func generate(
        topTraits: [String],
        traitScores: [String: Double],
        strengthAreas: [String],
        growthAreas: [String],
        mission: String
    ) -> [SuggestionItem] {
        var suggestions: [SuggestionItem] = []

        // 1. 即时行动建议（基于最强特质）
        if let primaryTrait = topTraits.first {
            suggestions.append(contentsOf: generateImmediateActions(for: primaryTrait))
        }

        // 2. 短期目标建议（基于优势和成长领域）
        suggestions.append(contentsOf: generateShortTermGoals(strengths: strengthAreas, growth: growthAreas))

        // 3. 长期方向建议（基于使命）
        suggestions.append(contentsOf: generateLongTermDirections(mission: mission, topTraits: topTraits))

        return suggestions
    }

    // MARK: - 即时行动 (优先级 1, 1-7天)

    private func generateImmediateActions(for trait: String) -> [SuggestionItem] {
        let traitLibrary = TraitLibrary.allTraits
        guard traitLibrary.contains(where: { $0.name == trait }) else { return [] }

        let templates: [String: [SuggestionItem]] = [
            "创造力": [
                SuggestionItem(title: "创意日记：今天的新想法", descriptionText: "花15分钟写下今天冒出的任何新想法，不评判，只记录", category: "即时行动", priority: 1, relatedTrait: "创造力", deadline: Date().addingTimeInterval(86400 * 7)),
                SuggestionItem(title: "换个角度看世界", descriptionText: "选择一件日常事物，尝试用不同的方式去做或理解它", category: "即时行动", priority: 1, relatedTrait: "创造力", deadline: Date().addingTimeInterval(86400 * 7)),
            ],
            "坚韧": [
                SuggestionItem(title: "记录一次克服困难", descriptionText: "回忆并写下你最近克服的一个困难，标注你用了什么方法", category: "即时行动", priority: 1, relatedTrait: "坚韧", deadline: Date().addingTimeInterval(86400 * 7)),
                SuggestionItem(title: "微小坚持计划", descriptionText: "选择一个你想养成的小习惯，承诺每天至少做5分钟，坚持7天", category: "即时行动", priority: 1, relatedTrait: "坚韧", deadline: Date().addingTimeInterval(86400 * 7)),
            ],
            "同理心": [
                SuggestionItem(title: "深度倾听练习", descriptionText: "今天与一个人交谈时，专注倾听，不打断，不急于给出建议", category: "即时行动", priority: 1, relatedTrait: "同理心", deadline: Date().addingTimeInterval(86400 * 7)),
                SuggestionItem(title: "写一封感谢信", descriptionText: "给一个对你有影响的人写一封感谢信（不一定要寄出）", category: "即时行动", priority: 1, relatedTrait: "同理心", deadline: Date().addingTimeInterval(86400 * 7)),
            ],
            "好奇心": [
                SuggestionItem(title: "学习一个新概念", descriptionText: "选一个你一直好奇但不了解的话题，花30分钟学习它的基础内容", category: "即时行动", priority: 1, relatedTrait: "好奇心", deadline: Date().addingTimeInterval(86400 * 7)),
                SuggestionItem(title: "提出三个为什么", descriptionText: "选一件日常事物，连问三个「为什么」，探究其本质", category: "即时行动", priority: 1, relatedTrait: "好奇心", deadline: Date().addingTimeInterval(86400 * 7)),
            ],
            "自律": [
                SuggestionItem(title: "明日规划", descriptionText: "今晚睡前花5分钟规划明天的三件最重要的事", category: "即时行动", priority: 1, relatedTrait: "自律", deadline: Date().addingTimeInterval(86400 * 7)),
                SuggestionItem(title: "追踪你的时间", descriptionText: "用一天时间记录你的时间花在哪里，发现可优化的点", category: "即时行动", priority: 1, relatedTrait: "自律", deadline: Date().addingTimeInterval(86400 * 7)),
            ],
            "领导力": [
                SuggestionItem(title: "主动发起一个行动", descriptionText: "在团队或社群中主动发起一个小行动或讨论", category: "即时行动", priority: 1, relatedTrait: "领导力", deadline: Date().addingTimeInterval(86400 * 7)),
            ],
            "社交力": [
                SuggestionItem(title: "联系一个老朋友", descriptionText: "给一个很久没联系的朋友发一条消息，分享你的近况", category: "即时行动", priority: 1, relatedTrait: "社交力", deadline: Date().addingTimeInterval(86400 * 7)),
            ],
        ]

        return templates[trait] ?? [
            SuggestionItem(title: "发挥你的\(trait)", descriptionText: "今天找一个机会展现你的\(trait)特质", category: "即时行动", priority: 1, relatedTrait: trait, deadline: Date().addingTimeInterval(86400 * 7)),
        ]
    }

    // MARK: - 短期目标 (优先级 2, 1-3个月)

    private func generateShortTermGoals(strengths: [String], growth: [String]) -> [SuggestionItem] {
        var items: [SuggestionItem] = []

        if let strength = strengths.first {
            items.append(SuggestionItem(
                title: "深化你的\(strength)",
                descriptionText: "在接下来一个月中，每周安排至少2小时投入与\(strength)相关的活动，并记录你的进展",
                category: "短期目标",
                priority: 2,
                relatedTrait: strength,
                deadline: Date().addingTimeInterval(86400 * 30)
            ))
        }

        if let area = growth.first {
            items.append(SuggestionItem(
                title: "探索\(area)的可能",
                descriptionText: "选择一项能锻炼\(area)的活动（如课程、实践项目、社群），在三个月内完成",
                category: "短期目标",
                priority: 2,
                relatedTrait: area,
                deadline: Date().addingTimeInterval(86400 * 90)
            ))
        }

        items.append(SuggestionItem(
            title: "建立月度复盘习惯",
            descriptionText: "每月最后一天花20分钟回顾当月的成长和收获，调整下月计划",
            category: "短期目标",
            priority: 2,
            relatedTrait: "自律",
            deadline: Date().addingTimeInterval(86400 * 30)
        ))

        return items
    }

    // MARK: - 长期方向 (优先级 3)

    private func generateLongTermDirections(mission: String, topTraits: [String]) -> [SuggestionItem] {
        [
            SuggestionItem(
                title: "定义你的年度关键词",
                descriptionText: "基于你的使命「\(mission)」，为今年选一个关键词，让它成为你决策的北极星",
                category: "长期方向",
                priority: 3,
                relatedTrait: topTraits.first ?? "成长",
                deadline: Date().addingTimeInterval(86400 * 365)
            ),
            SuggestionItem(
                title: "寻找导师或伙伴",
                descriptionText: "找到在\(topTraits.first ?? "你感兴趣领域")方面有经验的人，建立长期的指导和陪伴关系",
                category: "长期方向",
                priority: 3,
                relatedTrait: topTraits.first ?? "成长",
                deadline: Date().addingTimeInterval(86400 * 180)
            ),
            SuggestionItem(
                title: "创建你的成长路线图",
                descriptionText: "画一条从现在的你到理想中的你的路径，标注关键的里程碑和时间节点",
                category: "长期方向",
                priority: 3,
                relatedTrait: topTraits.first ?? "成长",
                deadline: Date().addingTimeInterval(86400 * 365)
            ),
        ]
    }
}
