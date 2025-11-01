//
//  StorageService.swift
//  Intelligente Notizen App
//

import Foundation
import CoreData
import SwiftUI

// MARK: - Storage Service Protocol
protocol StorageService: AnyObject {
    func saveNote(_ note: NoteModel) async throws
    func loadNote(by id: UUID) async throws -> NoteModel?
    func loadAllNotes() async throws -> [NoteModel]
    func deleteNote(by id: UUID) async throws
    func searchNotes(query: String) async throws -> [NoteModel]
    func loadNotes(by contentType: ContentType) async throws -> [NoteModel]
    func loadBookmarkedNotes() async throws -> [NoteModel]
    func loadArchivedNotes() async throws -> [NoteModel]
    func exportNotes(to url: URL) async throws
    func importNotes(from url: URL) async throws -> [NoteModel]
}

// MARK: - Core Data Stack
final class CoreDataStack {
    static let shared = CoreDataStack()
    
    let persistentContainer: NSPersistentContainer
    
    private init() {
        let modelURL = Bundle.module.url(forResource: "NoteModel", withExtension: "momd")
        guard let model = modelURL.flatMap { NSManagedObjectModel(contentsOf: $0) } else {
            fatalError("Core Data model not found")
        }
        
        persistentContainer = NSPersistentContainer(name: "NoteModel", managedObjectModel: model)
        persistentContainer.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

// MARK: - Core Data Storage Service
final class CoreDataStorageService: StorageService {
    private let coreDataStack = CoreDataStack.shared
    private let backgroundContext: NSManagedObjectContext
    
    init() {
        backgroundContext = coreDataStack.persistentContainer.newBackgroundContext()
    }
    
    func saveNote(_ note: NoteModel) async throws {
        try await backgroundContext.perform {
            let noteEntity = try self.findOrCreateNoteEntity(id: note.id, in: self.backgroundContext)
            
            noteEntity.id = note.id
            noteEntity.title = note.title
            noteEntity.content = note.content
            noteEntity.contentTypeRawValue = note.contentType.rawValue
            noteEntity.createdAt = note.createdAt
            noteEntity.updatedAt = note.updatedAt
            noteEntity.tags = note.tags as NSObject
            noteEntity.priorityRawValue = note.priority.rawValue
            noteEntity.isBookmarked = note.isBookmarked
            noteEntity.isArchived = note.isArchived
            noteEntity.aiSummary = note.aiSummary
            noteEntity.aiKeywords = note.aiKeywords as NSObject?
            noteEntity.metadata = try JSONSerialization.data(withJSONObject: note.metadata.mapValues { $0.value })
            
            try self.backgroundContext.save()
        }
    }
    
    func loadNote(by id: UUID) async throws -> NoteModel? {
        return try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let entities = try self.backgroundContext.fetch(fetchRequest)
            return entities.first.flatMap { self.mapToNoteModel($0) }
        }
    }
    
    func loadAllNotes() async throws -> [NoteModel] {
        return try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try self.backgroundContext.fetch(fetchRequest)
            return entities.compactMap { self.mapToNoteModel($0) }
        }
    }
    
    func deleteNote(by id: UUID) async throws {
        try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let entities = try self.backgroundContext.fetch(fetchRequest)
            entities.forEach { self.backgroundContext.delete($0) }
            
            try self.backgroundContext.save()
        }
    }
    
    func searchNotes(query: String) async throws -> [NoteModel] {
        return try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
            
            let searchPredicate = NSPredicate(format: 
                "title CONTAINS[c] %@ OR content CONTAINS[c] %@",
                query, query
            )
            fetchRequest.predicate = searchPredicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try self.backgroundContext.fetch(fetchRequest)
            return entities.compactMap { self.mapToNoteModel($0) }
        }
    }
    
    func loadNotes(by contentType: ContentType) async throws -> [NoteModel] {
        return try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "contentTypeRawValue == %@", contentType.rawValue)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try self.backgroundContext.fetch(fetchRequest)
            return entities.compactMap { self.mapToNoteModel($0) }
        }
    }
    
    func loadBookmarkedNotes() async throws -> [NoteModel] {
        return try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isBookmarked == YES")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try self.backgroundContext.fetch(fetchRequest)
            return entities.compactMap { self.mapToNoteModel($0) }
        }
    }
    
    func loadArchivedNotes() async throws -> [NoteModel] {
        return try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isArchived == YES")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try self.backgroundContext.fetch(fetchRequest)
            return entities.compactMap { self.mapToNoteModel($0) }
        }
    }
    
    func exportNotes(to url: URL) async throws {
        let notes = try await loadAllNotes()
        let exportData = try JSONEncoder().encode(notes)
        try exportData.write(to: url)
    }
    
    func importNotes(from url: URL) async throws -> [NoteModel] {
        let data = try Data(contentsOf: url)
        let notes = try JSONDecoder().decode([NoteModel].self, from: data)
        
        // Save imported notes
        for note in notes {
            try await saveNote(note)
        }
        
        return notes
    }
    
    // MARK: - Helper Methods
    private func findOrCreateNoteEntity(id: UUID, in context: NSManagedObjectContext) throws -> NoteEntity {
        let fetchRequest: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        let existingEntities = try context.fetch(fetchRequest)
        return existingEntities.first ?? NoteEntity(context: context)
    }
    
    private func mapToNoteModel(_ entity: NoteEntity) -> NoteModel? {
        guard let id = entity.id,
              let title = entity.title,
              let content = entity.content,
              let contentTypeRawValue = entity.contentTypeRawValue,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt,
              let tags = entity.tags as? [String],
              let priorityRawValue = entity.priorityRawValue else {
            return nil
        }
        
        let contentType = ContentType(rawValue: contentTypeRawValue) ?? .note
        let priority = NotePriority(rawValue: priorityRawValue) ?? .medium
        
        var metadata: [String: AnyCodable] = [:]
        if let metadataData = entity.metadata as Data? {
            do {
                if let metadataDict = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any] {
                    metadata = metadataDict.mapValues { AnyCodable($0) }
                }
            } catch {
                print("Error decoding metadata: \(error)")
            }
        }
        
        let aiKeywords = entity.aiKeywords as? [String]
        
        return NoteModel(
            id: id,
            title: title,
            content: content,
            contentType: contentType,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            priority: priority,
            isBookmarked: entity.isBookmarked,
            isArchived: entity.isArchived,
            aiSummary: entity.aiSummary,
            aiKeywords: aiKeywords,
            metadata: metadata
        )
    }
}

// MARK: - File System Storage Service
final class FileSystemStorageService: StorageService {
    private let fileManager = FileManager.default
    private let notesDirectory: URL
    
    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        notesDirectory = documentsPath.appendingPathComponent("Notes")
        
        // Create notes directory if it doesn't exist
        if !fileManager.fileExists(atPath: notesDirectory.path) {
            try? fileManager.createDirectory(at: notesDirectory, withIntermediateDirectories: true)
        }
    }
    
    func saveNote(_ note: NoteModel) async throws {
        let noteURL = notesDirectory.appendingPathComponent("\(note.id.uuidString).json")
        let data = try JSONEncoder().encode(note)
        try data.write(to: noteURL)
    }
    
    func loadNote(by id: UUID) async throws -> NoteModel? {
        let noteURL = notesDirectory.appendingPathComponent("\(id.uuidString).json")
        
        guard fileManager.fileExists(atPath: noteURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: noteURL)
        return try JSONDecoder().decode(NoteModel.self, from: data)
    }
    
    func loadAllNotes() async throws -> [NoteModel] {
        let urls = try fileManager.contentsOfDirectory(at: notesDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        
        var notes: [NoteModel] = []
        
        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                let note = try JSONDecoder().decode(NoteModel.self, from: data)
                notes.append(note)
            } catch {
                print("Error loading note from \(url): \(error)")
            }
        }
        
        return notes.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func deleteNote(by id: UUID) async throws {
        let noteURL = notesDirectory.appendingPathComponent("\(id.uuidString).json")
        try fileManager.removeItem(at: noteURL)
    }
    
    func searchNotes(query: String) async throws -> [NoteModel] {
        let allNotes = try await loadAllNotes()
        
        return allNotes.filter { note in
            note.title.localizedCaseInsensitiveContains(query) ||
            note.content.localizedCaseInsensitiveContains(query) ||
            note.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func loadNotes(by contentType: ContentType) async throws -> [NoteModel] {
        let allNotes = try await loadAllNotes()
        return allNotes.filter { $0.contentType == contentType }
    }
    
    func loadBookmarkedNotes() async throws -> [NoteModel] {
        let allNotes = try await loadAllNotes()
        return allNotes.filter { $0.isBookmarked }
    }
    
    func loadArchivedNotes() async throws -> [NoteModel] {
        let allNotes = try await loadAllNotes()
        return allNotes.filter { $0.isArchived }
    }
    
    func exportNotes(to url: URL) async throws {
        let notes = try await loadAllNotes()
        let exportData = try JSONEncoder().encode(notes)
        try exportData.write(to: url)
    }
    
    func importNotes(from url: URL) async throws -> [NoteModel] {
        let data = try Data(contentsOf: url)
        let notes = try JSONDecoder().decode([NoteModel].self, from: data)
        
        // Save imported notes
        for note in notes {
            try await saveNote(note)
        }
        
        return notes
    }
}

// MARK: - CloudKit Storage Service (Placeholder)
final class CloudKitStorageService: StorageService {
    // Placeholder implementation for CloudKit integration
    // This would require proper CloudKit setup and permissions
    
    func saveNote(_ note: NoteModel) async throws {
        throw StorageError.notImplemented
    }
    
    func loadNote(by id: UUID) async throws -> NoteModel? {
        throw StorageError.notImplemented
    }
    
    func loadAllNotes() async throws -> [NoteModel] {
        throw StorageError.notImplemented
    }
    
    func deleteNote(by id: UUID) async throws {
        throw StorageError.notImplemented
    }
    
    func searchNotes(query: String) async throws -> [NoteModel] {
        throw StorageError.notImplemented
    }
    
    func loadNotes(by contentType: ContentType) async throws -> [NoteModel] {
        throw StorageError.notImplemented
    }
    
    func loadBookmarkedNotes() async throws -> [NoteModel] {
        throw StorageError.notImplemented
    }
    
    func loadArchivedNotes() async throws -> [NoteModel] {
        throw StorageError.notImplemented
    }
    
    func exportNotes(to url: URL) async throws {
        throw StorageError.notImplemented
    }
    
    func importNotes(from url: URL) async throws -> [NoteModel] {
        throw StorageError.notImplemented
    }
}

// MARK: - Storage Manager
final class StorageManager: ObservableObject {
    @Published var currentStorage: StorageService
    @Published var availableStorages: [StorageServiceType: StorageService] = [:]
    @Published var selectedStorageType: StorageServiceType = .coreData
    @Published var isLoading: Bool = false
    @Published var lastError: Error?
    
    init() {
        let coreDataService = CoreDataStorageService()
        let fileSystemService = FileSystemStorageService()
        let cloudKitService = CloudKitStorageService()
        
        availableStorages = [
            .coreData: coreDataService,
            .fileSystem: fileSystemService,
            .cloudKit: cloudKitService
        ]
        
        currentStorage = coreDataService
    }
    
    func setStorageType(_ type: StorageServiceType) {
        selectedStorageType = type
        currentStorage = availableStorages[type] ?? currentStorage
    }
    
    // MARK: - Convenience Methods
    func saveNote(_ note: NoteModel) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await currentStorage.saveNote(note)
            lastError = nil
        } catch {
            lastError = error
        }
    }
    
    func loadAllNotes() async -> [NoteModel] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let notes = try await currentStorage.loadAllNotes()
            lastError = nil
            return notes
        } catch {
            lastError = error
            return []
        }
    }
    
    func deleteNote(by id: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await currentStorage.deleteNote(by: id)
            lastError = nil
        } catch {
            lastError = error
        }
    }
    
    func searchNotes(query: String) async -> [NoteModel] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let notes = try await currentStorage.searchNotes(query: query)
            lastError = nil
            return notes
        } catch {
            lastError = error
            return []
        }
    }
    
    func exportNotes(to url: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await currentStorage.exportNotes(to: url)
            lastError = nil
        } catch {
            lastError = error
        }
    }
    
    func importNotes(from url: URL) async -> [NoteModel] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let notes = try await currentStorage.importNotes(from: url)
            lastError = nil
            return notes
        } catch {
            lastError = error
            return []
        }
    }
}

// MARK: - Supporting Types
enum StorageServiceType: String, CaseIterable {
    case coreData = "Core Data"
    case fileSystem = "File System"
    case cloudKit = "CloudKit"
}

enum StorageError: Error, LocalizedError {
    case notImplemented
    case invalidFile
    case decodingError(Error)
    case encodingError(Error)
    case fileSystemError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Funktion nicht implementiert"
        case .invalidFile:
            return "Ungültige Datei"
        case .decodingError(let error):
            return "Dekodierungsfehler: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Kodierungsfehler: \(error.localizedDescription)"
        case .fileSystemError(let error):
            return "Dateisystemfehler: \(error.localizedDescription)"
        }
    }
}

// MARK: - NoteEntity (Core Data)
@objc(NoteEntity)
class NoteEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var content: String
    @NSManaged var contentTypeRawValue: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var tags: [String]
    @NSManaged var priorityRawValue: String
    @NSManaged var isBookmarked: Bool
    @NSManaged var isArchived: Bool
    @NSManaged var aiSummary: String?
    @NSManaged var aiKeywords: [String]?
    @NSManaged var metadata: Data
}

// MARK: - NoteEntity Extension
extension NoteEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoteEntity> {
        return NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
    }
}

// MARK: - Bundle Module
import Foundation
import SwiftUI

class BundleTarget {
    static let module: Bundle = {
        // This would be properly configured in a real iOS app
        return Bundle.main
    }()
}