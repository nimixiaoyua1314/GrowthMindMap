import Foundation
import CoreData
import SwiftUI

@MainActor
final class DiaryViewModel: ObservableObject {
    @Published var diaries: [DiaryEntryEntity] = []
    @Published var searchText: String = ""
    @Published var selectedDate: Date?
    @Published var isShowingEditor = false
    @Published var editingDiary: DiaryEntryEntity?

    private let context: NSManagedObjectContext

    var filteredDiaries: [DiaryEntryEntity] {
        var result = diaries

        if let date = selectedDate {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            result = result.filter { $0.date >= startOfDay && $0.date < endOfDay }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var moodStats: MoodStats {
        let total = diaries.count
        let avgMood = diaries.isEmpty ? 0 : Double(diaries.reduce(0) { $0 + Int($1.mood) }) / Double(total)
        let totalDays = diaries.isEmpty ? 0 : Set(diaries.compactMap { Calendar.current.startOfDay(for: $0.date) }).count

        // 连续写作天数
        let sortedDates = diaries.map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        var streak = 0
        var maxStreak = 0
        var prevDate: Date?
        for date in sortedDates {
            if let prev = prevDate {
                if Calendar.current.date(byAdding: .day, value: 1, to: prev) == date {
                    streak += 1
                } else {
                    streak = 1
                }
            } else {
                streak = 1
            }
            maxStreak = max(maxStreak, streak)
            prevDate = date
        }
        if sortedDates.isEmpty { maxStreak = 0 }

        return MoodStats(
            averageMood: avgMood,
            totalEntries: total,
            totalDays: totalDays,
            maxStreak: maxStreak
        )
    }

    var diaryDates: Set<Date> {
        Set(diaries.map { Calendar.current.startOfDay(for: $0.date) })
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchDiaries()
    }

    func fetchDiaries() {
        diaries = DiaryEntryEntity.fetchAll(in: context)
    }

    func createDiary(title: String, content: String, date: Date, mood: Int16, tags: [String], weatherIcon: String) {
        let entity = DiaryEntryEntity(context: context)
        entity.id = UUID()
        entity.title = title
        entity.content = content
        entity.date = date
        entity.mood = mood
        entity.tags = tags
        entity.weatherIcon = weatherIcon
        entity.createdAt = Date()

        save()
        fetchDiaries()
    }

    func updateDiary(_ entity: DiaryEntryEntity, title: String, content: String, date: Date, mood: Int16, tags: [String], weatherIcon: String) {
        entity.title = title
        entity.content = content
        entity.date = date
        entity.mood = mood
        entity.tags = tags
        entity.weatherIcon = weatherIcon

        save()
        fetchDiaries()
    }

    func deleteDiary(_ entity: DiaryEntryEntity) {
        DiaryEntryEntity.delete(entity, in: context)
        fetchDiaries()
    }

    private func save() {
        try? context.save()
    }
}

struct MoodStats {
    let averageMood: Double
    let totalEntries: Int
    let totalDays: Int
    let maxStreak: Int
}
