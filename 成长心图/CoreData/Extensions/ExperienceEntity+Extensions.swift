import Foundation
import CoreData

@objc(ExperienceEntity)
public class ExperienceEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var detailText: String
    @NSManaged public var date: Date
    @NSManaged public var category: String
    @NSManaged public var emotionTags: [String]
    @NSManaged public var impactLevel: Int16
    @NSManaged public var lifeLessons: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

// MARK: - 获取经历
extension ExperienceEntity {
    static func fetchAll(in context: NSManagedObjectContext) -> [ExperienceEntity] {
        let request: NSFetchRequest<ExperienceEntity> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExperienceEntity.date, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    static func fetchByCategory(_ category: String, in context: NSManagedObjectContext) -> [ExperienceEntity] {
        let request: NSFetchRequest<ExperienceEntity> = fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExperienceEntity.date, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    static func fetch(from startDate: Date, to endDate: Date, in context: NSManagedObjectContext) -> [ExperienceEntity] {
        let request: NSFetchRequest<ExperienceEntity> = fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExperienceEntity.date, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    static func delete(_ entity: ExperienceEntity, in context: NSManagedObjectContext) {
        context.delete(entity)
        try? context.save()
    }
}

// MARK: - Fetch Request
extension ExperienceEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExperienceEntity> {
        return NSFetchRequest<ExperienceEntity>(entityName: "ExperienceEntity")
    }
}
