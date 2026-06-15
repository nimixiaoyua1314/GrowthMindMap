import Foundation
import CoreData

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = PersistenceController.createManagedObjectModel()
        container = NSPersistentContainer(name: "成长心图", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data 加载失败: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Preview Helper
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // 插入示例数据用于预览
        let sampleExperience = ExperienceEntity(context: context)
        sampleExperience.id = UUID()
        sampleExperience.title = "大学毕业"
        sampleExperience.detailText = "完成了四年的计算机科学学业，获得了学士学位。这段经历让我学会了独立思考和解决问题的能力。"
        sampleExperience.date = Date().addingTimeInterval(-86400 * 90)
        sampleExperience.category = "教育"
        sampleExperience.emotionTags = ["喜悦", "感恩", "期待"]
        sampleExperience.impactLevel = 5
        sampleExperience.lifeLessons = "持续学习是成长的基石"
        sampleExperience.createdAt = Date()
        sampleExperience.updatedAt = Date()

        let sampleDiary = DiaryEntryEntity(context: context)
        sampleDiary.id = UUID()
        sampleDiary.title = "新的开始"
        sampleDiary.content = "今天开始思考人生的下一个阶段。回顾过去，发现自己对创造和帮助他人有着强烈的热情。这条路会通向何方呢？"
        sampleDiary.date = Date()
        sampleDiary.mood = 4
        sampleDiary.tags = ["思考", "未来", "成长"]
        sampleDiary.weatherIcon = "sun.max.fill"
        sampleDiary.createdAt = Date()

        try? context.save()
        return controller
    }()

    // MARK: - 保存上下文
    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            print("Core Data 保存失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 删除所有数据
    func deleteAll() {
        let context = container.viewContext
        let entities = container.managedObjectModel.entities

        for entity in entities {
            guard let entityName = entity.name else { continue }
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            _ = try? context.execute(deleteRequest)
        }

        save()
    }
}
