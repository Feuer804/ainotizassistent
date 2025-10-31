//
//  NotesIntegration.swift
//  Apple Notes Integration für AINotizassistent
//

import Foundation
import SwiftUI
import Combine
import CoreData

// MARK: - Apple Notes Integration Manager
@available(iOS 15.0, macOS 12.0, *)
class NotesIntegration: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var lastSyncDate: Date?
    @Published var syncInProgress = false
    @Published var availableCategories: [AppleNotesCategory] = []
    @Published var permissionsGranted = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let shortcutsManager = ShortcutsManager()
    private let applescriptManager = AppleScriptManager()
    private let spotlightManager = SpotlightManager()
    private let richTextConverter = RichTextConverter()
    
    // MARK: - Initialization
    init() {
        checkPermissions()
        setupCategories()
    }
    
    // MARK: - Permissions and Setup
    func checkPermissions() {
        // Prüfe auf Notes App-Berechtigungen
        permissionsGranted = checkNotesPermissions()
        isConnected = permissionsGranted
    }
    
    private func checkNotesPermissions() -> Bool {
        // Hier würde die tatsächliche Berechtigungsprüfung stattfinden
        // Für jetzt returning true für Demonstration
        return true
    }
    
    private func setupCategories() {
        availableCategories = [
            AppleNotesCategory(name: "All Notes", id: "all", icon: "folder"),
            AppleNotesCategory(name: "Notes", id: "notes", icon: "note.text"),
            AppleNotesCategory(name: "Work", id: "work", icon: "briefcase"),
            AppleNotesCategory(name: "Personal", id: "personal", icon: "person"),
            AppleNotesCategory(name: "Ideas", id: "ideas", icon: "lightbulb"),
            AppleNotesCategory(name: "Projects", id: "projects", icon: "folder.badge.plus")
        ]
    }
    
    // MARK: - Note Creation
    func createNote(title: String, content: String, tags: [String] = [], category: String = "Notes") async throws -> AppleNotesNote {
        
        guard permissionsGranted else {
            throw NotesError.permissionDenied
        }
        
        let richTextContent = richTextConverter.markdownToAppleNotesFormat(content)
        
        // Versuche zuerst via Shortcuts
        do {
            if let shortcutResult = try await shortcutsManager.createNote(
                title: title,
                content: richTextContent,
                tags: tags,
                category: category
            ) {
                return shortcutResult
            }
        } catch {
            print("Shortcuts creation failed, falling back to AppleScript: \(error)")
        }
        
        // Fallback zu AppleScript
        return try await applescriptManager.createNote(
            title: title,
            content: richTextContent,
            tags: tags,
            category: category
        )
    }
    
    // MARK: - Note Update
    func updateNote(_ note: AppleNotesNote, title: String?, content: String?, tags: [String]?, category: String?) async throws {
        
        guard permissionsGranted else {
            throw NotesError.permissionDenied
        }
        
        let updatedContent = content.map { richTextConverter.markdownToAppleNotesFormat($0) }
        
        do {
            try await shortcutsManager.updateNote(
                note: note,
                title: title,
                content: updatedContent,
                tags: tags,
                category: category
            )
        } catch {
            print("Shortcuts update failed, falling back to AppleScript: \(error)")
            try await applescriptManager.updateNote(
                note: note,
                title: title,
                content: updatedContent,
                tags: tags,
                category: category
            )
        }
        
        // Update Spotlight für Suchintegration
        try await spotlightManager.updateNoteInSpotlight(note)
    }
    
    // MARK: - Note Retrieval
    func getAllNotes() async throws -> [AppleNotesNote] {
        guard permissionsGranted else {
            throw NotesError.permissionDenied
        }
        
        do {
            if let shortcutResult = try await shortcutsManager.getAllNotes() {
                return shortcutResult
            }
        } catch {
            print("Shortcuts retrieval failed, falling back to AppleScript: \(error)")
        }
        
        return try await applescriptManager.getAllNotes()
    }
    
    func getNotes(in category: String) async throws -> [AppleNotesNote] {
        guard permissionsGranted else {
            throw NotesError.permissionDenied
        }
        
        let allNotes = try await getAllNotes()
        return allNotes.filter { $0.category == category }
    }
    
    func searchNotes(query: String, spotlight: Bool = true) async throws -> [AppleNotesNote] {
        guard permissionsGranted else {
            throw NotesError.permissionDenied
        }
        
        if spotlight {
            // Spotlight Suche für bessere Performance
            return try await spotlightManager.searchNotes(query: query)
        } else {
            let allNotes = try await getAllNotes()
            return allNotes.filter { note in
                note.title.localizedCaseInsensitiveContains(query) ||
                note.content.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    // MARK: - Categories and Folders
    func getAllCategories() async throws -> [AppleNotesCategory] {
        guard permissionsGranted else {
            throw NotesError.permissionDenied
        }
        
        return availableCategories
    }
    
    func createCategory(_ category: AppleNotesCategory) async throws {
        guard permissionsGranted else {
            throw NotesError.permissionDenied
        }
        
        try await applescriptManager.createCategory(category)
        await MainActor.run {
            availableCategories.append(category)
        }
    }
    
    // MARK: - Sync Operations
    func syncWithAppleNotes(force: Bool = false) async throws -> SyncResult {
        
        guard permissionsGranted else {
            throw NotesError.permissionDenied
        }
        
        await MainActor.run {
            syncInProgress = true
        }
        
        defer {
            Task {
                await MainActor.run {
                    syncInProgress = false
                }
            }
        }
        
        let startTime = Date()
        
        do {
            let appleNotes = try await getAllNotes()
            let syncTime = Date()
            
            let result = SyncResult(
                notesCount: appleNotes.count,
                lastSync: syncTime,
                duration: syncTime.timeIntervalSince(startTime),
                success: true
            )
            
            await MainActor.run {
                lastSyncDate = syncTime
                isConnected = true
            }
            
            return result
            
        } catch {
            await MainActor.run {
                isConnected = false
            }
            
            throw NotesError.syncFailed(error)
        }
    }
    
    // MARK: - Image and Attachment Support
    func addImageToNote(_ note: AppleNotesNote, imageData: Data, filename: String) async throws {
        guard permissionsGranted else {
            throw NotesError.permissionDenied
        }
        
        // Konvertiere Bild zu kompatiblem Format für Notes
        let optimizedData = try await ImageProcessor.optimizeImageForNotes(imageData, filename: filename)
        
        try await shortcutsManager.addAttachmentToNote(note, data: optimizedData, filename: filename)
    }
    
    // MARK: - Sharing and Collaboration
    func shareNote(_ note: AppleNotesNote, method: ShareMethod) async throws -> URL {
        guard permissionsGranted else {
            throw NotesError.permissionDenied
        }
        
        switch method {
        case .icloudLink:
            return try await applescriptManager.shareNoteViaiCloud(note)
        case .copyLink:
            let link = try await applescriptManager.getNoteShareLink(note)
            UIPasteboard.general.string = link
            return URL(string: link)!
        case .email:
            return try await applescriptManager.shareNoteViaEmail(note)
        }
    }
    
    // MARK: - Offline Support
    func createLocalNote(_ note: NoteModel) -> LocalAppleNotesNote {
        return LocalAppleNotesNote(
            localID: UUID(),
            appleNotesID: nil,
            title: note.title,
            content: note.content,
            tags: note.tags,
            category: "Local Notes",
            createdAt: note.createdAt,
            updatedAt: note.updatedAt,
            isLocalOnly: true
        )
    }
    
    func syncLocalNotes() async throws {
        // Hier würde die Synchronisation lokaler Notizen mit Apple Notes stattfinden
        let localNotes = await getLocalNotes()
        
        for localNote in localNotes where localNote.isLocalOnly {
            let appleNote = try await createNote(
                title: localNote.title,
                content: localNote.content,
                tags: localNote.tags
            )
            
            // Update local note with Apple Notes ID
            await updateLocalNoteID(localNote.localID, appleNotesID: appleNote.id)
        }
    }
    
    private func getLocalNotes() async -> [LocalAppleNotesNote] {
        // Implementierung für lokale Notizen
        return []
    }
    
    private func updateLocalNoteID(_ localID: UUID, appleNotesID: String) async {
        // Implementierung für Update von localen Notiz-IDs
    }
}

// MARK: - Supporting Types

@available(iOS 15.0, macOS 12.0, *)
struct AppleNotesNote: Identifiable, Equatable {
    let id: String
    var title: String
    var content: String
    var tags: [String]
    var category: String
    var createdAt: Date
    var updatedAt: Date
    var attachments: [AppleNotesAttachment]
    
    init(id: String = UUID().uuidString, title: String, content: String, tags: [String] = [], category: String = "Notes") {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
        self.attachments = []
    }
}

@available(iOS 15.0, macOS 12.0, *)
struct AppleNotesCategory: Identifiable, Equatable {
    let id: String
    var name: String
    var icon: String
    
    init(name: String, id: String = UUID().uuidString, icon: String = "folder") {
        self.name = name
        self.id = id
        self.icon = icon
    }
}

struct AppleNotesAttachment: Identifiable {
    let id = UUID()
    let filename: String
    let data: Data
    let mimeType: String
}

struct LocalAppleNotesNote: Identifiable {
    let id = UUID()
    let localID: UUID
    var appleNotesID: String?
    var title: String
    var content: String
    var tags: [String]
    var category: String
    var createdAt: Date
    var updatedAt: Date
    var isLocalOnly: Bool
}

struct SyncResult {
    let notesCount: Int
    let lastSync: Date
    let duration: TimeInterval
    let success: Bool
    let error: Error?
}

// MARK: - Enums

enum ShareMethod {
    case icloudLink
    case copyLink
    case email
}

enum NotesError: Error, LocalizedError {
    case permissionDenied
    case syncFailed(Error)
    case categoriesNotFound
    case noteNotFound
    case invalidContent
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Zugriff auf Apple Notes wurde verweigert"
        case .syncFailed(let error):
            return "Synchronisation fehlgeschlagen: \(error.localizedDescription)"
        case .categoriesNotFound:
            return "Keine Kategorien gefunden"
        case .noteNotFound:
            return "Notiz nicht gefunden"
        case .invalidContent:
            return "Ungültiger Inhalt"
        }
    }
}