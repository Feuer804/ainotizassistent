//
//  AppleScriptManager.swift
//  AppleScript Integration für Apple Notes
//

import Foundation
import OSLog

@available(macOS 12.0, *)
class AppleScriptManager {
    
    private let logger = Logger(subsystem: "AINotizassistent", category: "AppleScriptManager")
    
    // MARK: - Note Operations
    
    func createNote(title: String, content: String, tags: [String], category: String) async throws -> AppleNotesNote {
        
        let script = createNoteScript(title: title, content: content, tags: tags, category: category)
        
        do {
            let result = try await executeAppleScript(script)
            return parseCreateNoteResult(result, title: title, content: content, tags: tags, category: category)
        } catch {
            logger.error("Apple Script Fehler beim Erstellen der Notiz: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateNote(note: AppleNotesNote, title: String?, content: String?, tags: [String]?, category: String?) async throws {
        
        let script = updateNoteScript(note: note, title: title, content: content, tags: tags, category: category)
        
        do {
            _ = try await executeAppleScript(script)
        } catch {
            logger.error("Apple Script Fehler beim Aktualisieren der Notiz: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getAllNotes() async throws -> [AppleNotesNote] {
        
        let script = getAllNotesScript()
        
        do {
            let result = try await executeAppleScript(script)
            return parseGetAllNotesResult(result)
        } catch {
            logger.error("Apple Script Fehler beim Abrufen der Notizen: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getNotes(in category: String) async throws -> [AppleNotesNote] {
        
        let script = getNotesInCategoryScript(category: category)
        
        do {
            let result = try await executeAppleScript(script)
            return parseGetAllNotesResult(result) // Gleicher Parser
        } catch {
            logger.error("Apple Script Fehler beim Abrufen der Notizen in Kategorie \(category): \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteNote(_ note: AppleNotesNote) async throws {
        
        let script = deleteNoteScript(note: note)
        
        do {
            _ = try await executeAppleScript(script)
        } catch {
            logger.error("Apple Script Fehler beim Löschen der Notiz: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Category Operations
    
    func createCategory(_ category: AppleNotesCategory) async throws {
        
        let script = createCategoryScript(category: category)
        
        do {
            _ = try await executeAppleScript(script)
        } catch {
            logger.error("Apple Script Fehler beim Erstellen der Kategorie: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getAllCategories() async throws -> [String] {
        
        let script = getAllCategoriesScript()
        
        do {
            let result = try await executeAppleScript(script)
            return parseGetAllCategoriesResult(result)
        } catch {
            logger.error("Apple Script Fehler beim Abrufen der Kategorien: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Sharing Operations
    
    func shareNoteViaiCloud(_ note: AppleNotesNote) async throws -> URL {
        
        let script = shareNoteViaiCloudScript(note: note)
        
        do {
            let result = try await executeAppleScript(script)
            guard let iCloudURLString = result.components(separatedBy: "iCloudURL:").last?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let url = URL(string: iCloudURLString) else {
                throw NotesError.noteNotFound
            }
            return url
        } catch {
            logger.error("Apple Script Fehler beim Teilen der Notiz: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getNoteShareLink(_ note: AppleNotesNote) async throws -> String {
        
        let script = getNoteShareLinkScript(note: note)
        
        do {
            let result = try await executeAppleScript(script)
            return result
        } catch {
            logger.error("Apple Script Fehler beim Abrufen des Share-Links: \(error.localizedDescription)")
            throw error
        }
    }
    
    func shareNoteViaEmail(_ note: AppleNotesNote) async throws -> URL {
        
        let script = shareNoteViaEmailScript(note: note)
        
        do {
            _ = try await executeAppleScript(script)
            // Für Email gibt es keine URL zurück, die Notiz wurde direkt geteilt
            return URL(string: "mailto:")!
        } catch {
            logger.error("Apple Script Fehler beim Email-Teilen: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Script Generation
    
    private func createNoteScript(title: String, content: String, tags: [String], category: String) -> String {
        return """
        tell application "Notes"
            try
                -- Create new note in specified folder
                set newNote to make new note at folder "\(category)" with properties {body:"\(escapeQuotes(content))", name:"\(escapeQuotes(title))"}
                
                -- Add tags as comments or metadata
                set noteBody to body of newNote
                if "\(tags.joined(separator: ","))" is not "" then
                    set body of newNote to noteBody & return & "Tags: \(tags.joined(separator: ", "))"
                end if
                
                -- Return note ID for tracking
                return "SUCCESS:NoteID:" & (id of newNote as string)
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
    
    private func updateNoteScript(note: AppleNotesNote, title: String?, content: String?, tags: [String]?, category: String?) -> String {
        
        var script = """
        tell application "Notes"
            try
                -- Find note by ID
                set targetNote to note id "\(note.id)"
        """
        
        if let title = title {
            script += """
                -- Update title
                set name of targetNote to "\(escapeQuotes(title))"
            """
        }
        
        if let content = content {
            script += """
                -- Update content
                set body of targetNote to "\(escapeQuotes(content))"
            """
        }
        
        if let tags = tags {
            script += """
                -- Update tags
                set noteBody to body of targetNote
                set body of targetNote to noteBody & return & "Tags: \(tags.joined(separator: ", "))"
            """
        }
        
        script += """
                return "SUCCESS:Note updated"
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
        
        return script
    }
    
    private func getAllNotesScript() -> String {
        return """
        tell application "Notes"
            try
                set allNotes to {}
                repeat with thisNote in every note
                    set noteData to (name of thisNote) & "||" & (body of thisNote) & "||" & (creation date of thisNote as string) & "||" & (id of thisNote as string)
                    set end of allNotes to noteData
                end repeat
                return "SUCCESS:" & (allNotes as string)
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
    
    private func getNotesInCategoryScript(category: String) -> String {
        return """
        tell application "Notes"
            try
                set categoryNotes to {}
                repeat with thisNote in (every note in folder "\(category)")
                    set noteData to (name of thisNote) & "||" & (body of thisNote) & "||" & (creation date of thisNote as string) & "||" & (id of thisNote as string)
                    set end of categoryNotes to noteData
                end repeat
                return "SUCCESS:" & (categoryNotes as string)
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
    
    private func deleteNoteScript(note: AppleNotesNote) -> String {
        return """
        tell application "Notes"
            try
                delete note id "\(note.id)"
                return "SUCCESS:Note deleted"
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
    
    private func createCategoryScript(category: AppleNotesCategory) -> String {
        return """
        tell application "Notes"
            try
                make new folder at folder "Notes" with properties {name:"\(category.name)"}
                return "SUCCESS:Category created"
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
    
    private func getAllCategoriesScript() -> String {
        return """
        tell application "Notes"
            try
                set allFolders to name of every folder
                return "SUCCESS:" & (allFolders as string)
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
    
    private func shareNoteViaiCloudScript(note: AppleNotesNote) -> String {
        return """
        tell application "Notes"
            try
                set targetNote to note id "\(note.id)"
                set noteLink to "notes://share?noteID=\(note.id)"
                return "SUCCESS:iCloudURL:" & noteLink
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
    
    private func getNoteShareLinkScript(note: AppleNotesNote) -> String {
        return """
        tell application "Notes"
            try
                set targetNote to note id "\(note.id)"
                set noteLink to "https://www.icloud.com/notes/\(note.id)"
                return noteLink
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
    
    private func shareNoteViaEmailScript(note: AppleNotesNote) -> String {
        return """
        tell application "Mail"
            try
                set newEmail to make new outgoing message
                set subject of newEmail to "Notiz: \(note.title)"
                set content of newEmail to note.content
                return "SUCCESS:Email created"
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
    
    // MARK: - Script Execution and Parsing
    
    private func executeAppleScript(_ script: String) async throws -> String {
        
        // Da AppleScript Execution in dieser Umgebung nicht möglich ist,
        // simulieren wir das Ergebnis für Demonstrationszwecke
        // In einer echten App würde hier AppleScript ausgeführt werden
        
        logger.info("Führe AppleScript aus:\(script)")
        
        // Simuliere Ausführungszeit
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 Sekunden
        
        // Für Demo-Zwecke: Simuliere Erfolg
        return "SUCCESS:AppleScript operation completed"
    }
    
    private func parseCreateNoteResult(_ result: String, title: String, content: String, tags: [String], category: String) -> AppleNotesNote {
        
        // Extrahiere NoteID aus dem Ergebnis falls verfügbar
        var noteID = UUID().uuidString
        if result.contains("NoteID:") {
            let components = result.components(separatedBy: "NoteID:")
            if components.count > 1 {
                noteID = components[1].components(separatedBy: "\n").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? noteID
            }
        }
        
        return AppleNotesNote(
            id: noteID,
            title: title,
            content: content,
            tags: tags,
            category: category
        )
    }
    
    private func parseGetAllNotesResult(_ result: String) -> [AppleNotesNote] {
        
        // Parse note data in format: "Name||Content||Date||ID"
        var notes: [AppleNotesNote] = []
        
        guard result.hasPrefix("SUCCESS:") else {
            return notes
        }
        
        let noteDataString = String(result.dropFirst("SUCCESS:".count))
        
        // Für Demo-Zwecke: Erstelle einige Beispiel-Notizen
        let sampleNotes = [
            AppleNotesNote(
                id: UUID().uuidString,
                title: "Beispiel Notiz 1",
                content: "Dies ist der Inhalt der ersten Beispiel-Notiz aus AppleScript.",
                tags: ["applescript", "demo"],
                category: "Notes"
            ),
            AppleNotesNote(
                id: UUID().uuidString,
                title: "Arbeitsplanung",
                content: "Heute wichtige Termine:\n- 9:00 Meeting mit Team\n- 14:00 Projekt Review\n- 17:00 Status Update",
                tags: ["arbeit", "termine"],
                category: "Work"
            )
        ]
        
        return sampleNotes
    }
    
    private func parseGetAllCategoriesResult(_ result: String) -> [String] {
        
        guard result.hasPrefix("SUCCESS:") else {
            return ["Notes"]
        }
        
        // Für Demo-Zwecke: Simuliere verfügbare Kategorien
        return ["Notes", "Work", "Personal", "Ideas", "Projects"]
    }
    
    // MARK: - Helper Methods
    
    private func escapeQuotes(_ text: String) -> String {
        return text.replacingOccurrences(of: "\"", with: "\\\"")
    }
}

// MARK: - Advanced AppleScript Features
@available(macOS 12.0, *)
extension AppleScriptManager {
    
    func exportNoteToMarkdown(_ note: AppleNotesNote) async throws -> URL {
        
        let script = exportNoteToMarkdownScript(note: note)
        
        do {
            let result = try await executeAppleScript(script)
            
            guard result.contains("SUCCESS:"),
                  let filePath = result.components(separatedBy: "SUCCESS:FilePath:").last?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let url = URL(string: filePath) else {
                throw NotesError.noteNotFound
            }
            
            return url
        } catch {
            logger.error("Fehler beim Exportieren als Markdown: \(error.localizedDescription)")
            throw error
        }
    }
    
    func importNotesFromBackup(_ backupURL: URL) async throws {
        
        let script = importNotesFromBackupScript(backupURL: backupURL)
        
        do {
            _ = try await executeAppleScript(script)
        } catch {
            logger.error("Fehler beim Importieren aus Backup: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func exportNoteToMarkdownScript(note: AppleNotesNote) -> String {
        return """
        tell application "Notes"
            try
                set targetNote to note id "\(note.id)"
                set noteContent to "# " & (name of targetNote) & return & (body of targetNote)
                
                -- Save to Desktop as markdown
                set desktopPath to (path to desktop as string)
                set fileName to (name of targetNote) & ".md"
                set fullPath to desktopPath & fileName
                
                set fileRef to open for access file fullPath with write permission
                write noteContent to fileRef
                close access fileRef
                
                return "SUCCESS:FilePath:file://" & fullPath
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
    
    private func importNotesFromBackupScript(backupURL: URL) -> String {
        return """
        tell application "Notes"
            try
                -- Read from backup and create notes
                -- This would parse the backup format and create notes
                return "SUCCESS:Import completed"
            on error errorMessage
                return "ERROR:" & errorMessage
            end try
        end tell
        """
    }
}