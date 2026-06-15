import Foundation
import CoreData

@objc(TraitAnalysisEntity)
public class TraitAnalysisEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var analysisDate: Date
    @NSManaged public var topTraits: [String]
    @NSManaged public var traitScores: [String: Double]
    @NSManaged public var inferredMission: String
    @NSManaged public var strengthAreas: [String]
    @NSManaged public var growthAreas: [String]
    @NSManaged public var summary: String
    @NSManaged public var dataStartDate: Date
    @NSManaged public var dataEndDate: Date
}

extension TraitAnalysisEntity {
    static func fetchAll(in context: NSManagedObjectContext) -> [TraitAnalysisEntity] {
        let request: NSFetchRequest<TraitAnalysisEntity> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TraitAnalysisEntity.analysisDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    static func fetchLatest(in context: NSManagedObjectContext) -> TraitAnalysisEntity? {
        let request: NSFetchRequest<TraitAnalysisEntity> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TraitAnalysisEntity.analysisDate, ascending: false)]
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    static func delete(_ entity: TraitAnalysisEntity, in context: NSManagedObjectContext) {
        context.delete(entity)
        try? context.save()
    }
}

extension TraitAnalysisEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TraitAnalysisEntity> {
        return NSFetchRequest<TraitAnalysisEntity>(entityName: "TraitAnalysisEntity")
    }
}
