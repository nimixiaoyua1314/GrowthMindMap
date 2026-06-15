import Foundation
import CoreData
import SwiftUI

/// 统一记录条目
enum RecordEntry: Identifiable {
    case experience(ExperienceEntity)
    case diary(DiaryEntryEntity)

    var id: UUID {
        switch self {
        case .experience(let e): return e.id
        case .diary(let d): return d.id
        }
    }
    var date: Date {
        switch self {
        case .experience(let e): return e.date
        case .diary(let d): return d.date
        }
    }
    var text: String {
        switch self {
        case .experience(let e): return e.title + " " + e.detailText
        case .diary(let d): return d.title + " " + d.content
        }
    }
    var title: String {
        switch self {
        case .experience(let e): return e.title
        case .diary(let d): return d.title
        }
    }
    var content: String {
        switch self {
        case .experience(let e): return e.detailText
        case .diary(let d): return d.content
        }
    }
    var category: String {
        switch self {
        case .experience(let e): return e.category
        case .diary: return "日记"
        }
    }
    var tags: [String] {
        switch self {
        case .experience(let e): return e.emotionTags
        case .diary(let d): return d.tags
        }
    }
    var typeIcon: String {
        switch self {
        case .experience: return "book.fill"
        case .diary: return "square.and.pencil.fill"
        }
    }
    var typeLabel: String {
        switch self {
        case .experience: return "经历"
        case .diary: return "日记"
        }
    }
    var typeColor: Color {
        switch self {
        case .experience: return Color.themeSecondary
        case .diary: return Color.themeInfo
        }
    }
}

// MARK: - ViewModel
@MainActor
final class RecordViewModel: ObservableObject {
    @Published var records: [RecordEntry] = []
    @Published var searchText: String = ""
    @Published var selectedType: String? = nil // "经历", "日记", nil=全部
    @Published var selectedTag: String? = nil

    // 编辑状态
    @Published var isShowingEditor = false
    @Published var editType: EditType = .experience
    @Published var editingExperience: ExperienceEntity?
    @Published var editingDiary: DiaryEntryEntity?

    private let context: NSManagedObjectContext
    private var experienceVM: ExperienceViewModel
    private var diaryVM: DiaryViewModel

    enum EditType { case experience, diary }

    var allTags: [String] {
        var tags = Set<String>()
        for r in records {
            for t in r.tags where !t.isEmpty {
                tags.insert(t)
            }
            // 同时从内容中提取 #tag
            for t in extractHashtags(from: r.content) where !t.isEmpty {
                tags.insert(t)
            }
        }
        return Array(tags).sorted()
    }

    var filteredRecords: [RecordEntry] {
        var result = records

        if let type = selectedType {
            switch type {
            case "经历":
                result = result.filter { if case .experience = $0 { return true }; return false }
            case "日记":
                result = result.filter { if case .diary = $0 { return true }; return false }
            default: break
            }
        }

        if let tag = selectedTag {
            result = result.filter { entry in
                let storedTags = entry.tags.map { $0.lowercased() }
                let contentTags = extractHashtags(from: entry.content).map { $0.lowercased() }
                return storedTags.contains(tag.lowercased()) || contentTags.contains(tag.lowercased())
            }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var stats: (total: Int, expCount: Int, diaryCount: Int) {
        let exp = records.filter { if case .experience = $0 { return true }; return false }.count
        let dia = records.filter { if case .diary = $0 { return true }; return false }.count
        return (records.count, exp, dia)
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        self.experienceVM = ExperienceViewModel(context: context)
        self.diaryVM = DiaryViewModel(context: context)
        fetchAll()
    }

    func fetchAll() {
        let exps = ExperienceEntity.fetchAll(in: context).map { RecordEntry.experience($0) }
        let dias = DiaryEntryEntity.fetchAll(in: context).map { RecordEntry.diary($0) }
        records = (exps + dias).sorted { $0.date > $1.date }
    }

    /// 打开新增经历编辑
    func addExperience() {
        editType = .experience
        editingExperience = nil
        editingDiary = nil
        isShowingEditor = true
    }

    /// 打开新增日记编辑
    func addDiary() {
        editType = .diary
        editingExperience = nil
        editingDiary = nil
        isShowingEditor = true
    }

    /// 打开编辑已有条目
    func editEntry(_ entry: RecordEntry) {
        switch entry {
        case .experience(let e):
            editType = .experience
            editingExperience = e
            editingDiary = nil
        case .diary(let d):
            editType = .diary
            editingExperience = nil
            editingDiary = d
        }
        isShowingEditor = true
    }

    /// 删除条目
    func deleteEntry(_ entry: RecordEntry) {
        switch entry {
        case .experience(let e):
            ExperienceEntity.delete(e, in: context)
        case .diary(let d):
            DiaryEntryEntity.delete(d, in: context)
        }
        fetchAll()
    }

    /// 保存经历（精简版）
    func saveExperience(title: String, detailText: String, date: Date, category: String, tags: [String]) {
        if let exp = editingExperience {
            experienceVM.updateExperience(exp, title: title, detailText: detailText, date: date, category: category, emotionTags: tags, impactLevel: 3, lifeLessons: "")
        } else {
            experienceVM.createExperience(title: title, detailText: detailText, date: date, category: category, emotionTags: tags, impactLevel: 3, lifeLessons: "")
        }
        fetchAll()
    }

    /// 保存日记（精简版）
    func saveDiary(title: String, content: String, date: Date, tags: [String]) {
        if let d = editingDiary {
            diaryVM.updateDiary(d, title: title, content: content, date: date, mood: 3, tags: tags, weatherIcon: "sun.max.fill")
        } else {
            diaryVM.createDiary(title: title, content: content, date: date, mood: 3, tags: tags, weatherIcon: "sun.max.fill")
        }
        fetchAll()
    }

    /// 从文本中提取 #标签
    func extractHashtags(from text: String) -> [String] {
        let pattern = "#([\\w\\u4e00-\\u9fff]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap {
            Range($0.range(at: 1), in: text).map { String(text[$0]) }
        }
    }
}
