import Foundation
import CoreData
import SwiftUI

@MainActor
final class AnalysisViewModel: ObservableObject {
    @Published var latestAnalysis: TraitAnalysisEntity?
    @Published var analysisHistory: [TraitAnalysisEntity] = []
    @Published var isAnalyzing = false
    @Published var analysisError: String?
    @Published var traitScores: [String: Double] = [:]
    @Published var topTraits: [String] = []
    @Published var inferredMission: String = ""
    @Published var strengthAreas: [String] = []
    @Published var growthAreas: [String] = []
    @Published var summary: String = ""

    private let context: NSManagedObjectContext
    private let analysisEngine = AnalysisEngine()
    private let llmService = LLMService()

    init(context: NSManagedObjectContext) {
        self.context = context
        loadLatestAnalysis()
    }

    func loadLatestAnalysis() {
        analysisHistory = TraitAnalysisEntity.fetchAll(in: context)
        latestAnalysis = TraitAnalysisEntity.fetchLatest(in: context)

        if let latest = latestAnalysis {
            self.traitScores = latest.traitScores
            self.topTraits = latest.topTraits
            self.inferredMission = latest.inferredMission
            self.strengthAreas = latest.strengthAreas
            self.growthAreas = latest.growthAreas
            self.summary = latest.summary
        }
    }

    /// 本地分析
    func runLocalAnalysis() async {
        isAnalyzing = true
        analysisError = nil

        let experiences = ExperienceEntity.fetchAll(in: context)
        let diaries = DiaryEntryEntity.fetchAll(in: context)

        guard !experiences.isEmpty || !diaries.isEmpty else {
            analysisError = "请先记录一些经历或日记，数据越多分析越准确"
            isAnalyzing = false
            return
        }

        // 过滤最近一年的数据
        let oneYearAgo = Date().addingTimeInterval(-86400 * 365)
        let recentExperiences = experiences.filter { $0.date >= oneYearAgo }
        let recentDiaries = diaries.filter { $0.date >= oneYearAgo }

        let result = analysisEngine.analyze(experiences: recentExperiences, diaries: recentDiaries)

        // 保存到 Core Data
        let analysis = TraitAnalysisEntity(context: context)
        analysis.id = UUID()
        analysis.analysisDate = Date()
        analysis.topTraits = result.topTraits
        analysis.traitScores = result.traitScores
        analysis.inferredMission = result.mission
        analysis.strengthAreas = result.strengthAreas
        analysis.growthAreas = result.growthAreas
        analysis.summary = result.summary
        analysis.dataStartDate = oneYearAgo
        analysis.dataEndDate = Date()

        save()

        self.traitScores = result.traitScores
        self.topTraits = result.topTraits
        self.inferredMission = result.mission
        self.strengthAreas = result.strengthAreas
        self.growthAreas = result.growthAreas
        self.summary = result.summary

        isAnalyzing = false
        loadLatestAnalysis()
    }

    /// AI 深度分析
    func runDeepAnalysis() async {
        guard !llmService.apiKey.isEmpty else {
            analysisError = "请先在「我的」页面配置 AI API Key"
            return
        }

        isAnalyzing = true
        analysisError = nil

        let experiences = ExperienceEntity.fetchAll(in: context)
        let diaries = DiaryEntryEntity.fetchAll(in: context)

        // 准备脱敏摘要
        let experienceSummary = experiences.prefix(20).map { exp in
            "经历：\(exp.title)（分类：\(exp.category)，情绪：\(exp.emotionTags.joined(separator: "、"))，感悟：\(exp.lifeLessons)）"
        }.joined(separator: "\n")

        let diarySummary = diaries.prefix(30).map { diary in
            "日记：\(diary.title)（心情：\(diary.mood)/5）— \(String(diary.content.prefix(100)))"
        }.joined(separator: "\n")

        do {
            let result = try await llmService.deepAnalyze(
                experienceSummary: experienceSummary,
                diarySummary: diarySummary
            )

            // 合并到最新的分析中
            if let latest = latestAnalysis {
                latest.inferredMission = result.mission
                latest.summary = result.summary
                latest.strengthAreas = result.strengthAreas
                latest.growthAreas = result.growthAreas
                save()
                loadLatestAnalysis()
            }
        } catch {
            analysisError = "AI 分析失败: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    private func save() {
        try? context.save()
    }
}
