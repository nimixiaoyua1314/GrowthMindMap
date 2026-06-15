import Foundation
import NaturalLanguage

/// 中文关键词提取器
final class KeywordExtractor {

    /// 从文本中提取关键词
    func extractKeywords(from text: String, maxCount: Int = 20) -> [String] {
        guard !text.isEmpty else { return [] }

        var keywords: [String: Int] = [:]

        // 使用 NaturalLanguage 分词
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(.simplifiedChinese)

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range])
            // 过滤单字和标点
            if word.count >= 2 && !isStopWord(word) {
                keywords[word, default: 0] += 1
            }
            return true
        }

        // 按频率排序
        return keywords
            .sorted { $0.value > $1.value }
            .prefix(maxCount)
            .map { $0.key }
    }

    /// 提取情绪倾向 (积极/消极比例)
    func extractEmotionTendency(emotionTags: [[String]], moods: [Int16]) -> EmotionTendency {
        let positiveTags: Set<String> = ["喜悦", "兴奋", "感恩", "期待", "满足", "平静"]
        let negativeTags: Set<String> = ["悲伤", "焦虑", "愤怒", "压力"]

        var positiveCount = 0
        var negativeCount = 0

        for tags in emotionTags {
            for tag in tags {
                if positiveTags.contains(tag) { positiveCount += 1 }
                if negativeTags.contains(tag) { negativeCount += 1 }
            }
        }

        let totalMood = moods.reduce(0) { Int($0) + Int($1) }
        let avgMood = moods.isEmpty ? 3.0 : Double(totalMood) / Double(moods.count)

        return EmotionTendency(
            positiveRatio: positiveCount + negativeCount > 0
                ? Double(positiveCount) / Double(positiveCount + negativeCount)
                : 0.5,
            averageMood: avgMood
        )
    }

    /// 提取类别分布
    func extractCategoryDistribution(categories: [String]) -> [String: Int] {
        Dictionary(grouping: categories, by: { $0 }).mapValues { $0.count }
    }

    private func isStopWord(_ word: String) -> Bool {
        let stopWords: Set<String> = [
            "的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一",
            "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", "着",
            "没有", "看", "好", "自己", "这", "他", "她", "它", "们", "那", "些",
            "所以", "因为", "但是", "然后", "可以", "这个", "那个", "什么", "怎么",
            "觉得", "知道", "可能", "应该", "已经", "还是", "只是", "的话", "而已",
        ]
        return stopWords.contains(word)
    }
}

/// 情绪倾向分析结果
struct EmotionTendency {
    let positiveRatio: Double // 0-1，越高越积极
    let averageMood: Double   // 1-5 平均心情
}
