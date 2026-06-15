import Foundation
import CoreData

@objc(SuggestionEntity)
public class SuggestionEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var descriptionText: String
    @NSManaged public var category: String
    @NSManaged public var priority: Int16
    @NSManaged public var relatedTrait: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var deadline: Date?
    @NSManaged public var createdAt: Date
}

extension SuggestionEntity {
    static func fetchAll(in context: NSManagedObjectContext) -> [SuggestionEntity] {
        let request: NSFetchRequest<SuggestionEntity> = fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SuggestionEntity.priority, ascending: true),
            NSSortDescriptor(keyPath: \SuggestionEntity.createdAt, ascending: false),
        ]
        return (try? context.fetch(request)) ?? []
    }

    static func fetchActive(in context: NSManagedObjectContext) -> [SuggestionEntity] {
        let request: NSFetchRequest<SuggestionEntity> = fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SuggestionEntity.priority, ascending: true),
            NSSortDescriptor(keyPath: \SuggestionEntity.createdAt, ascending: false),
        ]
        return (try? context.fetch(request)) ?? []
    }

    static func delete(_ entity: SuggestionEntity, in context: NSManagedObjectContext) {
        context.delete(entity)
        try? context.save()
    }
}

extension SuggestionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SuggestionEntity> {
        return NSFetchRequest<SuggestionEntity>(entityName: "SuggestionEntity")
    }
}
