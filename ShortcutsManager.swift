//
//  ShortcutsManager.swift
//  Apple Notes Integration via Shortcuts App
//

import Foundation
import OSLog

@available(iOS 15.0, macOS 12.0, *)
class ShortcutsManager {
    
    private let logger = Logger(subsystem: "AINotizassistent", category: "ShortcutsManager")
    
    // MARK: - Note Operations via Shortcuts
    
    func createNote(title: String, content: String, tags: [String], category: String) async throws -> AppleNotesNote? {
        
        // Erweitere den Input für Shortcuts
        let input = """
        Title: \(title)
        Content: \(content)
        Tags: \(tags.joined(separator: ","))
        Category: \(category)
        """
        
        let shortcutName = "CreateNote" // Muss in Shortcuts App erstellt werden
        
        guard let shortcutURL = createShortcutURL(shortcutName: shortcutName, input: input) else {
            logger.warning("Konnte Shortcut URL nicht erstellen")
            return nil
        }
        
        do {
            // Führe Shortcut aus
            let result = try await executeShortcut(shortcutURL)
            return parseShortcutResult(result, title: title, content: content, tags: tags, category: category)
        } catch {
            logger.error("Fehler beim Ausführen des Shortcuts: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateNote(note: AppleNotesNote, title: String?, content: String?, tags: [String]?, category: String?) async throws {
        
        var updates: [String] = []
        if let title = title { updates.append("Title: \(title)") }
        if let content = content { updates.append("Content: \(content)") }
        if let tags = tags { updates.append("Tags: \(tags.joined(separator: ","))") }
        if let category = category { updates.append("Category: \(category)") }
        
        let input = """
        NoteID: \(note.id)
        \(updates.joined(separator: "\n"))
        """
        
        let shortcutName = "UpdateNote"
        
        guard let shortcutURL = createShortcutURL(shortcutName: shortcutName, input: input) else {
            throw NotesError.noteNotFound
        }
        
        _ = try await executeShortcut(shortcutURL)
    }
    
    func getAllNotes() async throws -> [AppleNotesNote]? {
        
        let shortcutName = "GetAllNotes"
        guard let shortcutURL = createShortcutURL(shortcutName: shortcutName, input: "") else {
            logger.warning("Konnte Shortcut URL nicht erstellen")
            return nil
        }
        
        let result = try await executeShortcut(shortcutURL)
        return parseNotesListResult(result)
    }
    
    func searchNotes(query: String) async throws -> [AppleNotesNote]? {
        
        let input = "SearchQuery: \(query)"
        let shortcutName = "SearchNotes"
        
        guard let shortcutURL = createShortcutURL(shortcutName: shortcutName, input: input) else {
            return nil
        }
        
        let result = try await executeShortcut(shortcutURL)
        return parseNotesListResult(result)
    }
    
    func addAttachmentToNote(_ note: AppleNotesNote, data: Data, filename: String) async throws {
        
        let attachmentData = data.base64EncodedString()
        let input = """
        NoteID: \(note.id)
        Attachment: \(attachmentData)
        Filename: \(filename)
        """
        
        let shortcutName = "AddAttachmentToNote"
        
        guard let shortcutURL = createShortcutURL(shortcutName: shortcutName, input: input) else {
            throw NotesError.noteNotFound
        }
        
        _ = try await executeShortcut(shortcutURL)
    }
    
    func getNoteCategories() async throws -> [String]? {
        
        let shortcutName = "GetNoteCategories"
        guard let shortcutURL = createShortcutURL(shortcutName: shortcutName, input: "") else {
            return nil
        }
        
        let result = try await executeShortcut(shortcutURL)
        return parseCategoriesResult(result)
    }
    
    // MARK: - Helper Methods
    
    private func createShortcutURL(shortcutName: String, input: String) -> URL? {
        
        guard let encodedShortcut = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedInput = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        let shortcutURL = "shortcuts://run-shortcut?name=\(encodedShortcut)&input=\(encodedInput)"
        return URL(string: shortcutURL)
    }
    
    private func executeShortcut(_ url: URL) async throws -> String {
        
        // Da wir keine direkte Shortcut-Ausführung haben,
        // simulieren wir hier das Ergebnis für Demonstrationszwecke
        // In einer echten Implementierung würde hier der URL geöffnet
        // und das Ergebnis geparst werden
        
        logger.info("Führe Shortcut aus: \(url.absoluteString)")
        
        // Simuliere eine kurze Verzögerung
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 Sekunden
        
        // Für Demo-Zwecke: Simuliere Erfolg
        return "SUCCESS: Operation completed successfully"
    }
    
    private func parseShortcutResult(_ result: String, title: String, content: String, tags: [String], category: String) -> AppleNotesNote? {
        
        guard result.contains("SUCCESS") else {
            logger.error("Shortcut gab Fehler zurück: \(result)")
            return nil
        }
        
        // Erstelle eine neue Notiz mit generierter ID
        return AppleNotesNote(
            title: title,
            content: content,
            tags: tags,
            category: category
        )
    }
    
    private func parseNotesListResult(_ result: String) -> [AppleNotesNote]? {
        
        guard result.contains("SUCCESS") else {
            return nil
        }
        
        // Für Demo-Zwecke: Simuliere einige Beispiel-Notizen
        return [
            AppleNotesNote(
                title: "Beispiel Notiz 1",
                content: "Dies ist der Inhalt der ersten Beispiel-Notiz.",
                tags: ["demo", "beispiel"],
                category: "Notes"
            ),
            AppleNotesNote(
                title: "Beispiel Notiz 2",
                content: "Dies ist der Inhalt der zweiten Beispiel-Notiz.",
                tags: ["wichtig"],
                category: "Work"
            )
        ]
    }
    
    private func parseCategoriesResult(_ result: String) -> [String]? {
        
        guard result.contains("SUCCESS") else {
            return nil
        }
        
        return ["Notes", "Work", "Personal", "Ideas", "Projects"]
    }
}

// MARK: - Shortcuts App Templates
extension ShortcutsManager {
    
    // Template für Shortcuts, die der Benutzer erstellen muss
    static func getShortcutTemplates() -> [String: String] {
        return [
            "CreateNote": """
            Get variable: Shortcut Input
            Extract Text from Input
            Get Details of Quick Look from Input
            Ask for Input (Title): Title
            Ask for Input (Content): Content  
            Ask for Input (Tags): Tags
            Ask for Input (Category): Category
            Set Variable: NoteData
            Run Apple Script:
            -- Create note in Notes app
            tell application "Notes"
                make new note at folder "Notes" with properties {body:Content, name:Title}
            end tell
            -- Return success
            Return "SUCCESS"
            """,
            
            "GetAllNotes": """
            Run Apple Script:
            -- Get all notes from Notes app
            tell application "Notes"
                set allNotes to name of every note
                return allNotes
            end tell
            Set Variable: NotesList
            Return "SUCCESS"
            """,
            
            "SearchNotes": """
            Get variable: Shortcut Input
            Extract Text from Input
            Get Details of Quick Look from Input
            Ask for Input: Search Query
            Run Apple Script:
            -- Search notes in Notes app
            tell application "Notes"
                set searchResults to every note whose body contains Search Query or name contains Search Query
                return name of searchResults
            end tell
            Return "SUCCESS"
            """
        ]
    }
    
    static func generateShortcutInstructions() -> String {
        return """
        ## Shortcuts App Setup für Apple Notes Integration
        
        Erstelle die folgenden Shortcuts in der Shortcuts App:
        
        ### 1. CreateNote Shortcut:
        1. Öffne die Shortcuts App
        2. Tippe auf "+" um einen neuen Shortcut zu erstellen
        3. Benenne ihn "CreateNote"
        4. Füge die Aktionen aus dem Template hinzu
        5. Speichere den Shortcut
        
        ### 2. GetAllNotes Shortcut:
        1. Erstelle einen neuen Shortcut namens "GetAllNotes"
        2. Füge die Apple Script Aktion hinzu
        3. Konfiguriere das Script um alle Notizen zu extrahieren
        
        ### 3. SearchNotes Shortcut:
        1. Erstelle einen neuen Shortcut namens "SearchNotes" 
        2. Füge Apple Script Aktion hinzu
        3. Konfiguriere das Script für Notizen-Suche
        
        ### Berechtigungen:
        - Notes App Zugriff in Systemeinstellungen erlauben
        - Apple Script Berechtigungen aktivieren
        """
    }
}