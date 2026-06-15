import Foundation
import CoreData

@objc(DiaryEntryEntity)
public class DiaryEntryEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var content: String
    @NSManaged public var date: Date
    @NSManaged public var mood: Int16
    @NSManaged public var tags: [String]
    @NSManaged public var weatherIcon: String
    @NSManaged public var createdAt: Date
}

extension DiaryEntryEntity {
    static func fetchAll(in context: NSManagedObjectContext) -> [DiaryEntryEntity] {
        let request: NSFetchRequest<DiaryEntryEntity> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntryEntity.date, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    static func fetch(from startDate: Date, to endDate: Date, in context: NSManagedObjectContext) -> [DiaryEntryEntity] {
        let request: NSFetchRequest<DiaryEntryEntity> = fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntryEntity.date, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    static func fetchByDate(_ date: Date, in context: NSManagedObjectContext) -> [DiaryEntryEntity] {
        let request: NSFetchRequest<DiaryEntryEntity> = fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        return (try? context.fetch(request)) ?? []
    }

    static func delete(_ entity: DiaryEntryEntity, in context: NSManagedObjectContext) {
        context.delete(entity)
        try? context.save()
    }
}

extension DiaryEntryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DiaryEntryEntity> {
        return NSFetchRequest<DiaryEntryEntity>(entityName: "DiaryEntryEntity")
    }
}
