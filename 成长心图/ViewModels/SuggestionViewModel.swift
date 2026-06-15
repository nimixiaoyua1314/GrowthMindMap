import Foundation
import CoreData
import SwiftUI

@MainActor
final class SuggestionViewModel: ObservableObject {
    @Published var suggestions: [SuggestionEntity] = []
    @Published var isGenerating = false

    private let context: NSManagedObjectContext
    private let suggestionEngine = SuggestionEngine()

    var activeSuggestions: [SuggestionEntity] {
        suggestions.filter { !$0.isCompleted }
    }

    var completedSuggestions: [SuggestionEntity] {
        suggestions.filter { $0.isCompleted }
    }

    var highPriority: [SuggestionEntity] {
        activeSuggestions.filter { $0.priority == 1 }
    }

    var mediumPriority: [SuggestionEntity] {
        activeSuggestions.filter { $0.priority == 2 }
    }

    var lowPriority: [SuggestionEntity] {
        activeSuggestions.filter { $0.priority == 3 }
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchSuggestions()
    }

    func fetchSuggestions() {
        suggestions = SuggestionEntity.fetchAll(in: context)
    }

    /// 基于最新分析生成建议
    func generateSuggestions(from analysis: TraitAnalysisEntity?) async {
        isGenerating = true

        // 先清除旧的未完成建议
        let oldSuggestions = SuggestionEntity.fetchActive(in: context)
        for old in oldSuggestions {
            context.delete(old)
        }

        guard let analysis = analysis else {
            isGenerating = false
            return
        }

        let generated = suggestionEngine.generate(
            topTraits: analysis.topTraits,
            traitScores: analysis.traitScores,
            strengthAreas: analysis.strengthAreas,
            growthAreas: analysis.growthAreas,
            mission: analysis.inferredMission
        )

        for item in generated {
            let entity = SuggestionEntity(context: context)
            entity.id = UUID()
            entity.title = item.title
            entity.descriptionText = item.descriptionText
            entity.category = item.category
            entity.priority = item.priority
            entity.relatedTrait = item.relatedTrait
            entity.isCompleted = false
            entity.deadline = item.deadline
            entity.createdAt = Date()
        }

        save()
        fetchSuggestions()
        isGenerating = false
    }

    func toggleCompletion(_ entity: SuggestionEntity) {
        entity.isCompleted.toggle()
        save()
        fetchSuggestions()
    }

    func deleteSuggestion(_ entity: SuggestionEntity) {
        SuggestionEntity.delete(entity, in: context)
        fetchSuggestions()
    }

    private func save() {
        try? context.save()
    }
}
