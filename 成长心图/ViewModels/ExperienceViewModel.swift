import Foundation
import CoreData
import SwiftUI

@MainActor
final class ExperienceViewModel: ObservableObject {
    @Published var experiences: [ExperienceEntity] = []
    @Published var selectedCategory: String?
    @Published var searchText: String = ""
    @Published var isShowingAddSheet = false
    @Published var editingExperience: ExperienceEntity?

    private let context: NSManagedObjectContext

    var filteredExperiences: [ExperienceEntity] {
        var result = experiences

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.detailText.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var categoryCounts: [String: Int] {
        Dictionary(grouping: experiences, by: { $0.category })
            .mapValues { $0.count }
    }

    var stats: ExperienceStats {
        let total = experiences.count
        let avgImpact = experiences.isEmpty ? 0 : Double(experiences.reduce(0) { $0 + Int($1.impactLevel) }) / Double(total)
        let topCategory = categoryCounts.max(by: { $0.value < $1.value })?.key ?? "无"
        let recent30Days = experiences.filter { $0.date >= Date().addingTimeInterval(-86400 * 30) }.count

        return ExperienceStats(
            total: total,
            averageImpact: avgImpact,
            topCategory: topCategory,
            recentCount: recent30Days
        )
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchExperiences()
    }

    func fetchExperiences() {
        experiences = ExperienceEntity.fetchAll(in: context)
    }

    func createExperience(
        title: String,
        detailText: String,
        date: Date,
        category: String,
        emotionTags: [String],
        impactLevel: Int16,
        lifeLessons: String
    ) {
        let entity = ExperienceEntity(context: context)
        entity.id = UUID()
        entity.title = title
        entity.detailText = detailText
        entity.date = date
        entity.category = category
        entity.emotionTags = emotionTags
        entity.impactLevel = impactLevel
        entity.lifeLessons = lifeLessons
        entity.createdAt = Date()
        entity.updatedAt = Date()

        save()
        fetchExperiences()
    }

    func updateExperience(
        _ entity: ExperienceEntity,
        title: String,
        detailText: String,
        date: Date,
        category: String,
        emotionTags: [String],
        impactLevel: Int16,
        lifeLessons: String
    ) {
        entity.title = title
        entity.detailText = detailText
        entity.date = date
        entity.category = category
        entity.emotionTags = emotionTags
        entity.impactLevel = impactLevel
        entity.lifeLessons = lifeLessons
        entity.updatedAt = Date()

        save()
        fetchExperiences()
    }

    func deleteExperience(_ entity: ExperienceEntity) {
        ExperienceEntity.delete(entity, in: context)
        fetchExperiences()
    }

    func deleteExperiences(at offsets: IndexSet) {
        // 需要在 filtered 列表上操作，但 Core Data 操作在完整列表上
        let filtered = filteredExperiences
        for index in offsets {
            let entity = filtered[index]
            ExperienceEntity.delete(entity, in: context)
        }
        fetchExperiences()
    }

    private func save() {
        try? context.save()
    }
}

// MARK: - 统计数据
struct ExperienceStats {
    let total: Int
    let averageImpact: Double
    let topCategory: String
    let recentCount: Int
}
