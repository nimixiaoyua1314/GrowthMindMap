import Foundation

/// 分析结果
struct AnalysisResult {
    let topTraits: [String]         // Top 5 核心特质
    let traitScores: [String: Double] // 所有特质得分
    let mission: String            // 人生使命推断
    let strengthAreas: [String]    // 优势领域
    let growthAreas: [String]      // 成长领域
    let summary: String            // 文字摘要
}

/// 本地特质分析引擎
final class AnalysisEngine {
    private let extractor = KeywordExtractor()

    /// 执行完整分析
    func analyze(experiences: [ExperienceEntity], diaries: [DiaryEntryEntity]) -> AnalysisResult {
        // 1. 关键词提取
        let experienceText = experiences.map { "\($0.title) \($0.detailText) \($0.lifeLessons)" }.joined(separator: " ")
        let diaryText = diaries.map { "\($0.title) \($0.content)" }.joined(separator: " ")
        let allText = experienceText + " " + diaryText

        let allKeywords = extractor.extractKeywords(from: allText)

        // 2. 情绪分析
        let emotionTags = experiences.map { $0.emotionTags }
        let moods = diaries.map { $0.mood }
        let emotionTendency = extractor.extractEmotionTendency(emotionTags: emotionTags, moods: moods)

        // 3. 类别分析
        let categories = experiences.map { $0.category }
        let categoryDistribution = extractor.extractCategoryDistribution(categories: categories)

        // 4. 特质打分
        let traitScores = scoreTraits(
            keywords: allKeywords,
            emotionTendency: emotionTendency,
            categories: categoryDistribution,
            experiences: experiences,
            diaries: diaries
        )

        // 5. 排序取 Top 5
        let sortedTraits = traitScores.sorted { $0.value > $1.value }
        let topTraits = Array(sortedTraits.prefix(5).map { $0.key })

        // 6. 优势与成长领域
        let strengthAreas = Array(sortedTraits.prefix(3).map { $0.key })
        let growthAreas = Array(sortedTraits.suffix(3).filter { $0.value < 30 }.map { $0.key })

        // 7. 使命推断
        let mission = inferMission(topTraits: topTraits, categoryDistribution: categoryDistribution, experiences: experiences)

        // 8. 摘要生成
        let summary = generateSummary(topTraits: topTraits, mission: mission, strengthAreas: strengthAreas, growthAreas: growthAreas, emotionTendency: emotionTendency)

        return AnalysisResult(
            topTraits: topTraits,
            traitScores: traitScores,
            mission: mission,
            strengthAreas: strengthAreas,
            growthAreas: growthAreas,
            summary: summary
        )
    }

    // MARK: - 特质评分

    private func scoreTraits(
        keywords: [String],
        emotionTendency: EmotionTendency,
        categories: [String: Int],
        experiences: [ExperienceEntity],
        diaries: [DiaryEntryEntity]
    ) -> [String: Double] {
        var scores: [String: Double] = [:]

        for trait in TraitLibrary.allTraits {
            var score: Double = 0

            // 维度1：关键词匹配 (权重 50%)
            let keywordMatches = trait.keywords.filter { kw in
                keywords.contains { $0.contains(kw) || kw.contains($0) }
            }.count
            score += Double(keywordMatches) / Double(max(trait.keywords.count, 1)) * 50

            // 维度2：情绪倾向 (权重 20%)
            if emotionTendency.positiveRatio > 0.6 {
                let positiveTraits = ["乐观", "感恩", "社交力"]
                if positiveTraits.contains(trait.name) {
                    score += 20 * emotionTendency.positiveRatio
                }
            }
            if emotionTendency.averageMood >= 3.5 {
                let resilientTraits = ["坚韧", "适应性", "乐观"]
                if resilientTraits.contains(trait.name) {
                    score += 15
                }
            }

            // 维度3：经历影响度 (权重 20%)
            let avgImpact = experiences.isEmpty ? 0 : Double(experiences.reduce(0) { $0 + Int($1.impactLevel) }) / Double(experiences.count)
            let highImpactTraits = ["坚韧", "领导力", "独立性"]
            if highImpactTraits.contains(trait.name) && avgImpact >= 3.0 {
                score += 20 * (avgImpact / 5.0)
            }

            // 维度4：日记持续性 (权重 10%)
            let diaryCount = diaries.count
            let consistentTraits = ["自律", "耐心", "好奇心"]
            if consistentTraits.contains(trait.name) && diaryCount > 5 {
                let diaryBonus = min(Double(diaryCount) / 30.0, 1.0) * 10
                score += diaryBonus
            }

            // 维度5：类别关联 (附加分)
            if let edu = categories["教育"], ["好奇心", "分析力", "自律"].contains(trait.name) {
                score += min(Double(edu), 10)
            }
            if let career = categories["职业"], ["领导力", "社交力", "坚韧"].contains(trait.name) {
                score += min(Double(career), 10)
            }
            if let relation = categories["关系"], ["同理心", "感恩", "社交力"].contains(trait.name) {
                score += min(Double(relation), 10)
            }

            scores[trait.name] = min(score, 100)
        }

        return scores
    }

    // MARK: - 使命推断

    private func inferMission(
        topTraits: [String],
        categoryDistribution: [String: Int],
        experiences: [ExperienceEntity]
    ) -> String {
        let primaryTrait = topTraits.first ?? "成长"
        let secondaryTrait = topTraits.count > 1 ? topTraits[1] : "探索"

        // 分析最频繁的经历类别
        let topCategory = categoryDistribution.max(by: { $0.value < $1.value })?.key ?? "生活"

        // 提取高频 lifeLessons 主题
        let lessons = experiences.map { $0.lifeLessons }.filter { !$0.isEmpty }
        let lessonKeywords = extractor.extractKeywords(from: lessons.joined(separator: " "))
        let lessonTheme = lessonKeywords.first ?? "成长"

        // 使命模板库
        let templates: [String] = [
            "用你的\(primaryTrait)在\(topCategory)领域持续深耕，以\(secondaryTrait)连接更多人，共同\(lessonTheme)",
            "你天生具备\(primaryTrait)和\(secondaryTrait)，这让你在\(topCategory)方面有独特优势，你的使命是推动\(lessonTheme)",
            "将你的\(primaryTrait)转化为力量，在\(topCategory)的道路上，以\(secondaryTrait)影响身边的人，实现\(lessonTheme)",
            "你是一个\(primaryTrait)的人，通过\(topCategory)实践\(secondaryTrait)，最终达成\(lessonTheme)的更高目标",
            "发挥你的\(primaryTrait)天赋，以\(secondaryTrait)为桥梁，在\(topCategory)领域创造属于你的\(lessonTheme)故事",
        ]

        return templates.randomElement() ?? templates[0]
    }

    // MARK: - 摘要生成

    private func generateSummary(
        topTraits: [String],
        mission: String,
        strengthAreas: [String],
        growthAreas: [String],
        emotionTendency: EmotionTendency
    ) -> String {
        let traitStr = topTraits.prefix(3).joined(separator: "、")
        let strengthStr = strengthAreas.joined(separator: "、")
        let growthStr = growthAreas.isEmpty ? "各方面均衡发展" : growthAreas.joined(separator: "、")

        let emotionNote: String
        if emotionTendency.positiveRatio > 0.7 {
            emotionNote = "你的情绪状态整体积极向上"
        } else if emotionTendency.positiveRatio > 0.5 {
            emotionNote = "你的情绪状态较为平衡"
        } else {
            emotionNote = "你近期可能经历了一些挑战，但这正是成长的契机"
        }

        return """
        \(emotionNote)。通过分析你的经历和日记，我们发现你最突出的核心特质是【\(traitStr)】。

        你的优势领域集中在：\(strengthStr)。建议在：\(growthStr)方面多加关注。

        \(mission)
        """
    }
}
