import Foundation
import CoreData

// MARK: - Core Data 模型程序化定义

extension PersistenceController {
    /// 程序化构建托管对象模型
    static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: ExperienceEntity
        let experienceEntity = NSEntityDescription()
        experienceEntity.name = "ExperienceEntity"
        experienceEntity.managedObjectClassName = "成长心图.ExperienceEntity"

        let expAttributes: [(String, NSAttributeType, Any?)] = [
            ("id", .UUIDAttributeType, nil),
            ("title", .stringAttributeType, ""),
            ("detailText", .stringAttributeType, ""),
            ("date", .dateAttributeType, nil),
            ("category", .stringAttributeType, "其他"),
            ("emotionTags", .transformableAttributeType, nil),
            ("impactLevel", .integer16AttributeType, 3),
            ("lifeLessons", .stringAttributeType, ""),
            ("createdAt", .dateAttributeType, nil),
            ("updatedAt", .dateAttributeType, nil),
        ]

        var expProperties: [NSPropertyDescription] = []
        for (name, type, defaultValue) in expAttributes {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.defaultValue = defaultValue
            attr.isOptional = (name != "id" && name != "title" && name != "date")
            expProperties.append(attr)
        }
        experienceEntity.properties = expProperties
        experienceEntity.uniquenessConstraints = [["id"]]

        // MARK: DiaryEntryEntity
        let diaryEntity = NSEntityDescription()
        diaryEntity.name = "DiaryEntryEntity"
        diaryEntity.managedObjectClassName = "成长心图.DiaryEntryEntity"

        let diaryAttributes: [(String, NSAttributeType, Any?)] = [
            ("id", .UUIDAttributeType, nil),
            ("title", .stringAttributeType, ""),
            ("content", .stringAttributeType, ""),
            ("date", .dateAttributeType, nil),
            ("mood", .integer16AttributeType, 3),
            ("tags", .transformableAttributeType, nil),
            ("weatherIcon", .stringAttributeType, "cloud.fill"),
            ("createdAt", .dateAttributeType, nil),
        ]

        var diaryProperties: [NSPropertyDescription] = []
        for (name, type, defaultValue) in diaryAttributes {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.defaultValue = defaultValue
            attr.isOptional = (name != "id" && name != "title" && name != "date")
            diaryProperties.append(attr)
        }
        diaryEntity.properties = diaryProperties
        diaryEntity.uniquenessConstraints = [["id"]]

        // MARK: TraitAnalysisEntity
        let analysisEntity = NSEntityDescription()
        analysisEntity.name = "TraitAnalysisEntity"
        analysisEntity.managedObjectClassName = "成长心图.TraitAnalysisEntity"

        let analysisAttributes: [(String, NSAttributeType, Any?)] = [
            ("id", .UUIDAttributeType, nil),
            ("analysisDate", .dateAttributeType, nil),
            ("topTraits", .transformableAttributeType, nil),
            ("traitScores", .transformableAttributeType, nil),
            ("inferredMission", .stringAttributeType, ""),
            ("strengthAreas", .transformableAttributeType, nil),
            ("growthAreas", .transformableAttributeType, nil),
            ("summary", .stringAttributeType, ""),
            ("dataStartDate", .dateAttributeType, nil),
            ("dataEndDate", .dateAttributeType, nil),
        ]

        var analysisProperties: [NSPropertyDescription] = []
        for (name, type, defaultValue) in analysisAttributes {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.defaultValue = defaultValue
            attr.isOptional = (name != "id" && name != "analysisDate")
            analysisProperties.append(attr)
        }
        analysisEntity.properties = analysisProperties
        analysisEntity.uniquenessConstraints = [["id"]]

        // MARK: SuggestionEntity
        let suggestionEntity = NSEntityDescription()
        suggestionEntity.name = "SuggestionEntity"
        suggestionEntity.managedObjectClassName = "成长心图.SuggestionEntity"

        let suggestionAttributes: [(String, NSAttributeType, Any?)] = [
            ("id", .UUIDAttributeType, nil),
            ("title", .stringAttributeType, ""),
            ("descriptionText", .stringAttributeType, ""),
            ("category", .stringAttributeType, "个人成长"),
            ("priority", .integer16AttributeType, 2),
            ("relatedTrait", .stringAttributeType, ""),
            ("isCompleted", .booleanAttributeType, false),
            ("deadline", .dateAttributeType, nil),
            ("createdAt", .dateAttributeType, nil),
        ]

        var suggestionProperties: [NSPropertyDescription] = []
        for (name, type, defaultValue) in suggestionAttributes {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.defaultValue = defaultValue
            attr.isOptional = (name != "id" && name != "title")
            suggestionProperties.append(attr)
        }
        suggestionEntity.properties = suggestionProperties
        suggestionEntity.uniquenessConstraints = [["id"]]

        model.entities = [experienceEntity, diaryEntity, analysisEntity, suggestionEntity]
        return model
    }
}
