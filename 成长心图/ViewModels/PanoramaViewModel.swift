import Foundation
import CoreData
import SwiftUI

/// 环层数据
struct RingData: Identifiable {
    let id = UUID()
    let title: String
    let items: [RingItemData]
    let color: Color
}

struct RingItemData: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
}

@MainActor
final class PanoramaViewModel: ObservableObject {
    @Published var rings: [RingData] = []           // 圆1: 我 — 经历/情绪/个性/领域
    @Published var timelineRings: [RingData] = []   // 圆2: 时空 — 历史/当下/未来
    @Published var centerText: String = "我"
    @Published var centerSub: String = ""
    @Published var timelineCenter: String = "时空"
    @Published var hasData: Bool = false

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func loadPanoramaData() {
        let experiences = ExperienceEntity.fetchAll(in: context)
        let diaries = DiaryEntryEntity.fetchAll(in: context)
        let analysis = TraitAnalysisEntity.fetchLatest(in: context)
        let suggestions = SuggestionEntity.fetchActive(in: context)

        hasData = !experiences.isEmpty || !diaries.isEmpty

        // 中心
        if let a = analysis, !a.topTraits.isEmpty {
            centerText = a.topTraits.first ?? "我"
            centerSub = a.topTraits.count > 1 ? a.topTraits[1] : ""
        } else if !experiences.isEmpty {
            centerText = "我"
            centerSub = "\(experiences.count)段经历"
        } else {
            centerText = "我"
            centerSub = "开始记录"
        }

        // === 环1: 经历 ===
        var expItems: [RingItemData] = []
        let recent = experiences.prefix(8)
        for e in recent {
            expItems.append(RingItemData(
                label: String(e.title.prefix(6)),
                color: categoryColor(e.category)
            ))
        }
        if expItems.isEmpty {
            expItems = [RingItemData(label: "记录你的第一段经历", color: ZenColor.gold)]
        }

        // === 环2: 情绪点 ===
        var emotionItems: [RingItemData] = []
        let recentDiaries = diaries.prefix(10)
        for d in recentDiaries {
            let moodEmoji = ["", "😔", "😕", "😐", "🙂", "😊"]
            let idx = min(max(Int(d.mood), 1), 5)
            emotionItems.append(RingItemData(label: "\(moodEmoji[idx]) \(String(d.content.prefix(6)))", color: moodColor(d.mood)))
        }
        // 补充情绪关键词
        let emotionKeywords = extractEmotionKeywords(from: experiences.map { $0.detailText } + diaries.map { $0.content })
        for kw in emotionKeywords.prefix(6) {
            if !emotionItems.contains(where: { $0.label.contains(kw) }) {
                emotionItems.append(RingItemData(label: kw, color: ZenColor.vermilionLight))
            }
        }
        if emotionItems.isEmpty {
            emotionItems = [RingItemData(label: "写下心情", color: ZenColor.jade)]
        }

        // === 环3: 个性总结 ===
        var traitItems: [RingItemData] = []
        if let a = analysis, !a.topTraits.isEmpty {
            for trait in a.topTraits.prefix(6) {
                traitItems.append(RingItemData(label: trait, color: traitColor(trait)))
            }
        }
        // 补充: 从经历分类推断
        let topCat = mostFrequentCategory(experiences)
        if !traitItems.contains(where: { $0.label == topCat }) && !topCat.isEmpty {
            traitItems.append(RingItemData(label: "关注\(topCat)", color: categoryColor(topCat)))
        }
        // 从日记推断活跃度
        if diaries.count > 5 {
            traitItems.append(RingItemData(label: "持续记录者", color: ZenColor.jade))
        }
        if traitItems.isEmpty {
            traitItems = [
                RingItemData(label: "等待发现", color: ZenColor.gold),
                RingItemData(label: "记录越多越清晰", color: ZenColor.inkLight),
            ]
        }

        // === 环4: 关注领域 & 社会议题 ===
        var domainItems: [RingItemData] = []
        // 从经历分类提取领域
        let catCounts = Dictionary(grouping: experiences, by: { $0.category }).mapValues { $0.count }
        let sortedCats = catCounts.sorted { $0.value > $1.value }
        for (cat, count) in sortedCats.prefix(3) {
            domainItems.append(RingItemData(label: "\(cat)(\(count))", color: categoryColor(cat)))
        }
        // 从建议提取方向
        for s in suggestions.prefix(2) {
            domainItems.append(RingItemData(label: String(s.title.prefix(8)), color: ZenColor.vermilion))
        }
        // 默认社会议题推测
        let keywords = extractKeywords(from: experiences.map { $0.detailText } + diaries.map { $0.content })
        let issueKeywords = ["社会", "环境", "教育", "科技", "公益", "社区", "平等", "健康", "文化", "创新"]
        for kw in issueKeywords {
            if keywords.contains(kw) && !domainItems.contains(where: { $0.label.contains(kw) }) {
                domainItems.append(RingItemData(label: kw, color: ZenColor.gold))
            }
        }
        if domainItems.isEmpty {
            domainItems = [
                RingItemData(label: "教育", color: ZenColor.jade),
                RingItemData(label: "科技", color: ZenColor.gold),
                RingItemData(label: "社会", color: ZenColor.vermilionLight),
            ]
        }

        // === Wiki 词条数据 ===
        let wiki = WikiTermsService.shared.load()

        // === 环5: 曾经历史 ===
        var historyItems: [RingItemData] = []
        for t in wiki.history.prefix(8) {
            historyItems.append(RingItemData(label: t.term, color: ZenColor.inkLight))
        }
        // 补充：过去的经历
        let oldExperiences = experiences.filter { $0.date < Date().addingTimeInterval(-86400 * 180) }
        for e in oldExperiences.prefix(3) {
            historyItems.append(RingItemData(label: String(e.title.prefix(8)), color: categoryColor(e.category)))
        }
        if historyItems.isEmpty {
            historyItems = [RingItemData(label: "时间会沉淀智慧", color: ZenColor.inkPale)]
        }

        // === 环6: 当下热点 ===
        var hotspotItems: [RingItemData] = []
        for t in wiki.present.prefix(10) {
            hotspotItems.append(RingItemData(label: t.term, color: ZenColor.vermilion))
        }
        if hotspotItems.isEmpty {
            hotspotItems = [RingItemData(label: "记录当下", color: ZenColor.vermilionLight)]
        }

        // === 环7: 潜在未来 ===
        var futureItems: [RingItemData] = []
        for t in wiki.future.prefix(10) {
            futureItems.append(RingItemData(label: t.term, color: Color.themeInfo))
        }
        // 补充：分析引擎的成长领域
        if let a = analysis {
            for area in a.growthAreas.prefix(2) {
                futureItems.append(RingItemData(label: "发展\(area)", color: ZenColor.jade))
            }
        }
        if futureItems.isEmpty {
            futureItems = [RingItemData(label: "无限可能", color: ZenColor.gold)]
        }

        rings = [
            RingData(title: "经历", items: expItems, color: ZenColor.gold),
            RingData(title: "情绪", items: emotionItems, color: ZenColor.vermilionLight),
            RingData(title: "个性", items: traitItems, color: ZenColor.jade),
            RingData(title: "领域", items: domainItems, color: Color.themeInfo),
        ]

        timelineRings = [
            RingData(title: "历史", items: historyItems, color: ZenColor.inkLight),
            RingData(title: "当下", items: hotspotItems, color: ZenColor.vermilion),
            RingData(title: "未来", items: futureItems, color: Color.themeInfo),
        ]

        let userName = UserDefaults.standard.string(forKey: "user_name") ?? "我"
        centerText = userName
        centerSub = hasData ? "\(experiences.count)经历 · \(diaries.count)日记 · \(traitItems.count)特质" : "开始记录你的成长"
    }

    // MARK: - 辅助
    private func categoryColor(_ cat: String) -> Color {
        ExperienceCategory.allCases.first(where: { $0.rawValue == cat }).map { Color(hex: $0.color) } ?? ZenColor.gold
    }

    private func moodColor(_ mood: Int16) -> Color {
        switch mood {
        case 5: return .moodExcellent
        case 4: return .moodGood
        case 3: return .moodNeutral
        case 2: return .moodBad
        default: return .moodTerrible
        }
    }

    private func traitColor(_ t: String) -> Color {
        let map: [String: Color] = [
            "创造力": Color(hex: "C9A96E"), "坚韧": Color(hex: "B8705A"),
            "同理心": Color(hex: "6B8F71"), "领导力": Color(hex: "8A7BA0"),
            "好奇心": Color(hex: "DDC896"), "自律": Color(hex: "6B8F71"),
            "乐观": Color(hex: "E8C860"), "分析力": Color(hex: "8A7BA0"),
            "社交力": Color(hex: "CC9080"), "冒险精神": Color(hex: "B8705A"),
            "耐心": Color(hex: "6B8F71"), "感恩": Color(hex: "DDC896"),
            "独立性": Color(hex: "8A7BA0"), "适应性": Color(hex: "B8705A"),
        ]
        return map[t] ?? ZenColor.gold
    }

    private func mostFrequentCategory(_ exps: [ExperienceEntity]) -> String {
        let counts = Dictionary(grouping: exps, by: { $0.category }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? ""
    }

    private func extractEmotionKeywords(from texts: [String]) -> [String] {
        let emotionWords = ["喜悦", "平静", "焦虑", "兴奋", "感恩", "满足", "期待", "释然", "思念", "坚定"]
        var found: [String] = []
        for text in texts {
            for w in emotionWords {
                if text.contains(w) && !found.contains(w) {
                    found.append(w)
                }
            }
        }
        return found
    }

    private func extractKeywords(from texts: [String]) -> [String] {
        let all = texts.joined(separator: " ")
        let keywords = ["教育", "科技", "社会", "健康", "文化", "创新", "公益", "社区", "平等", "环境"]
        return keywords.filter { all.contains($0) }
    }
}
