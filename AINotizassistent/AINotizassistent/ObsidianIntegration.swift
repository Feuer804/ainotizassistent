import Foundation
import SwiftUI
import FileProvider
import YAMLWriter

// MARK: - Obsidian Vault Model
struct ObsidianVault: Codable, Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let createdDate: Date
    let lastModified: Date
    let isActive: Bool
    let settings: ObsidianSettings
    
    init(name: String, path: URL) {
        self.name = name
        self.path = path
        self.createdDate = Date()
        self.lastModified = Date()
        self.isActive = true
        self.settings = ObsidianSettings()
    }
}

// MARK: - Obsidian Settings
struct ObsidianSettings: Codable {
    var dailyNotesTemplate: String = """
    ---
    date: {{date:YYYY-MM-DD}}
    weekday: {{date:dddd}}
    tags: [daily-notes]
    ---
    
    # {{date:YYYY-MM-DD}}
    
    ## Wetter
    [Hier Wetter eintragen]
    
    ## Tagesordnung
    - [ ] Wichtige Aufgaben
    
    ## Tagesreflexion
    - Was gut lief:
    - Was verbessert werden kann:
    
    ## Memos
    [Weitere Notizen]
    """
    
    var projectTemplate: String = """
    ---
    project-name: {{project-name}}
    start-date: {{date:YYYY-MM-DD}}
    status: active
    priority: medium
    tags: [project]
    ---
    
    # {{project-name}}
    
    ## Projektbeschreibung
    [Projektbeschreibung hier]
    
    ## Ziele
    - [ ] Ziel 1
    - [ ] Ziel 2
    
    ## Aufgaben
    - [ ] Aufgabe 1
    - [ ] Aufgabe 2
    
    ## Fortschritt
    | Aufgabe | Status | Notizen |
    |---------|---------|---------|
    |        |         |         |
    
    ## Notizen
    [Projektnotizen]
    """
    
    var fileNamingConvention: FileNamingConvention = .kebabCase
    var autoCreateBacklinks: Bool = true
    var autoCreateTags: Bool = true
    var enableGitIntegration: Bool = false
    var syncService: SyncService = .none
}

// MARK: - File Naming Convention
enum FileNamingConvention: String, CaseIterable {
    case kebabCase = "kebab-case"
    case snakeCase = "snake_case"
    case camelCase = "camelCase"
    case dateBased = "YYYY-MM-DD"
    case custom = "custom"
}

// MARK: - Sync Service
enum SyncService: String, CaseIterable {
    case none = "none"
    case obsidianSync = "obsidian-sync"
    case icloud = "icloud"
    case dropbox = "dropbox"
    case onedrive = "onedrive"
}

// MARK: - Obsidian Note Model
struct ObsidianNote: Codable, Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let filePath: URL
    let createdDate: Date
    let lastModified: Date
    let tags: [String]
    let frontMatter: [String: Any]
    let backlinks: [URL]
    var wikilinks: [String] = []
    
    var displayName: String {
        title.isEmpty ? filePath.lastPathComponent : title
    }
}

// MARK: - Daily Note
struct DailyNote: ObsidianNote {
    let date: Date
    
    init(date: Date, vaultPath: URL) {
        let dateString = DateFormatter.iso8601.string(from: date)
        let filename = "Daily Notes/\(dateString).md"
        let filePath = vaultPath.appendingPathComponent(filename)
        
        super.init(
            title: "Tagesnotizen - \(dateString)",
            content: "",
            filePath: filePath,
            createdDate: Date(),
            lastModified: Date(),
            tags: ["daily-notes"],
            frontMatter: ["date": dateString],
            backlinks: []
        )
    }
}

// MARK: - Project
struct Project: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let status: ProjectStatus
    let startDate: Date
    var notes: [ObsidianNote] = []
    
    enum ProjectStatus: String, CaseIterable {
        case planning = "planning"
        case active = "active"
        case paused = "paused"
        case completed = "completed"
        case archived = "archived"
    }
}

// MARK: - Conflict Resolution
enum ConflictResolution {
    case keepLocal
    case keepRemote
    case merge
    case manual
}

struct FileConflict {
    let localPath: URL
    let remotePath: URL
    let conflictType: ConflictType
    let modifiedDates: (local: Date, remote: Date)
    
    enum ConflictType {
        case timestamp
        case content
        case metadata
    }
}

// MARK: - Main Obsidian Integration
@MainActor
class ObsidianIntegration: ObservableObject {
    @Published var vaults: [ObsidianVault] = []
    @Published var activeVault: ObsidianVault?
    @Published var isScanning: Bool = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var conflicts: [FileConflict] = []
    
    private let fileManager = FileManager.default
    private var syncTimer: Timer?
    
    // MARK: - Initialization
    init() {
        loadVaults()
        startSyncMonitoring()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Vault Management
    func createVault(name: String, at path: URL) throws -> ObsidianVault {
        let vault = ObsidianVault(name: name, path: path)
        try createVaultStructure(vault: vault)
        try createTemplateFiles(vault: vault)
        
        vaults.append(vault)
        activeVault = vault
        saveVaults()
        
        return vault
    }
    
    func detectVaults(at basePath: URL) async throws -> [URL] {
        var vaults: [URL] = []
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: basePath,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return vaults }
        
        for content in contents {
            if content.pathExtension == "md" || content.lastPathComponent == ".obsidian" {
                let vaultPath = content.deletingLastPathComponent()
                if !vaults.contains(vaultPath) {
                    vaults.append(vaultPath)
                }
            }
        }
        
        return vaults
    }
    
    func setActiveVault(_ vault: ObsidianVault) {
        activeVault = vault
        objectWillChange.send()
    }
    
    // MARK: - Folder Structure Creation
    private func createVaultStructure(vault: ObsidianVault) throws {
        let folderStructure = [
            "Daily Notes",
            "Projects",
            "Templates",
            "Attachments",
            "Archive",
            "Reference",
            "Meeting Notes",
            "Ideas",
            "Books",
            "Research"
        ]
        
        for folder in folderStructure {
            let folderPath = vault.path.appendingPathComponent(folder)
            try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true)
            
            // Create README.md für jeden Ordner
            if folder != "Attachments" {
                let readmePath = folderPath.appendingPathComponent("README.md")
                let readmeContent = """
                # \(folder)
                
                Dieses Verzeichnis enthält \(folder.lowercased()) für das Obsidian Vault.
                """
                try readmeContent.write(to: readmePath, atomically: true, encoding: .utf8)
            }
        }
        
        // Erstelle Hauptverzeichnisstruktur
        try createHiddenObsidianFolder(vault: vault)
    }
    
    private func createHiddenObsidianFolder(vault: ObsidianVault) throws {
        let obsidianPath = vault.path.appendingPathComponent(".obsidian")
        try fileManager.createDirectory(at: obsidianPath, withIntermediateDirectories: true)
        
        // Erstelle Workspace.json
        let workspaceData = [
            "main": true,
            "sidebar": true,
            "active": "Daily Notes"
        ]
        
        let workspacePath = obsidianPath.appendingPathComponent("workspace.json")
        try JSONSerialization.data(withJSONObject: workspaceData).write(to: workspacePath)
        
        // Erstelle app.json
        let appData = [
            "openInApp": true,
            "appSettings": vault.settings
        ] as [String: Any]
        
        let appPath = obsidianPath.appendingPathComponent("app.json")
        try JSONSerialization.data(withJSONObject: appData).write(to: appPath)
    }
    
    // MARK: - Template Files
    private func createTemplateFiles(vault: ObsidianVault) throws {
        let templatesPath = vault.path.appendingPathComponent("Templates")
        
        // Daily Notes Template
        let dailyTemplatePath = templatesPath.appendingPathComponent("daily-note.md")
        try vault.settings.dailyNotesTemplate.write(to: dailyTemplatePath, atomically: true, encoding: .utf8)
        
        // Project Template
        let projectTemplatePath = templatesPath.appendingPathComponent("project.md")
        try vault.settings.projectTemplate.write(to: projectTemplatePath, atomically: true, encoding: .utf8)
        
        // Meeting Template
        let meetingTemplate = """
        ---
        meeting-date: {{date:YYYY-MM-DD}}
        attendees: []
        tags: [meeting]
        ---
        
        # Meeting - {{date:YYYY-MM-DD}}
        
        ## Teilnehmer
        - [ ]
        
        ## Agenda
        1. 
        
        ## Diskussionen
        - 
        
        ## Entscheidungen
        - 
        
        ## Action Items
        - [ ] 
        """
        
        let meetingTemplatePath = templatesPath.appendingPathComponent("meeting.md")
        try meetingTemplate.write(to: meetingTemplatePath, atomically: true, encoding: .utf8)
        
        // Book Notes Template
        let bookTemplate = """
        ---
        book-title: {{book-title}}
        author: {{author}}
        read-date: {{date:YYYY-MM-DD}}
        rating: 
        tags: [books]
        ---
        
        # {{book-title}}
        
        ## Bewertung
        ⭐⭐⭐⭐⭐ ( /5 )
        
        ## Zusammenfassung
        [Hier Zusammenfassung eintragen]
        
        ## Zitate
        > "Zitat 1"
        
        ## Hauptthemen
        - Thema 1
        - Thema 2
        
        ## Reflexionen
        [Persönliche Gedanken]
        """
        
        let bookTemplatePath = templatesPath.appendingPathComponent("book-notes.md")
        try bookTemplate.write(to: bookTemplatePath, atomically: true, encoding: .utf8)
    }
    
    // MARK: - File Management
    func createNote(title: String, content: String = "", in folder: String = "") throws -> ObsidianNote {
        guard let vault = activeVault else {
            throw ObsidianError.noActiveVault
        }
        
        let folderPath = vault.path.appendingPathComponent(folder)
        let filename = generateFilename(for: title)
        let filePath = folderPath.appendingPathComponent("\(filename).md")
        
        let note = ObsidianNote(
            title: title,
            content: content,
            filePath: filePath,
            createdDate: Date(),
            lastModified: Date(),
            tags: [],
            frontMatter: [:],
            backlinks: []
        )
        
        try saveNote(note)
        return note
    }
    
    func createDailyNote(for date: Date = Date()) throws -> DailyNote {
        guard let vault = activeVault else {
            throw ObsidianError.noActiveVault
        }
        
        let dailyNote = DailyNote(date: date, vaultPath: vault.path)
        try saveNote(dailyNote)
        return dailyNote
    }
    
    func createProject(name: String, description: String = "") throws -> Project {
        guard let vault = activeVault else {
            throw ObsidianError.noActiveVault
        }
        
        let projectPath = vault.path.appendingPathComponent("Projects/\(name)")
        try fileManager.createDirectory(at: projectPath, withIntermediateDirectories: true)
        
        let projectFilePath = projectPath.appendingPathComponent("README.md")
        var content = "# \(name)\n\n"
        if !description.isEmpty {
            content += "\(description)\n\n"
        }
        
        // Füge Front Matter hinzu
        let frontMatter = generateFrontMatter(for: "project", additionalFields: [
            "project-name": name,
            "start-date": DateFormatter.iso8601.string(from: Date()),
            "status": "active",
            "priority": "medium"
        ])
        content = frontMatter + "\n\n" + content
        
        try content.write(to: projectFilePath, atomically: true, encoding: .utf8)
        
        return Project(
            name: name,
            path: projectPath,
            status: .active,
            startDate: Date()
        )
    }
    
    func saveNote(_ note: ObsidianNote) throws {
        var content = note.content
        
        // Füge Front Matter hinzu, wenn vorhanden
        if !note.frontMatter.isEmpty {
            let frontMatter = generateFrontMatter(for: "note", additionalFields: note.frontMatter)
            content = frontMatter + "\n\n" + content
        }
        
        // Füge Tags hinzu
        if !note.tags.isEmpty {
            content += "\n\n## Tags\n"
            for tag in note.tags {
                content += "#\(tag) "
            }
        }
        
        try content.write(to: note.filePath, atomically: true, encoding: .utf8)
    }
    
    func loadNote(from path: URL) throws -> ObsidianNote {
        let content = try String(contentsOf: path, encoding: .utf8)
        let (frontMatter, bodyContent) = parseMarkdownContent(content)
        
        let title = extractTitle(from: bodyContent) ?? path.deletingPathExtension().lastPathComponent
        let tags = extractTags(from: bodyContent)
        
        return ObsidianNote(
            title: title,
            content: bodyContent,
            filePath: path,
            createdDate: getFileCreationDate(path),
            lastModified: getFileModificationDate(path),
            tags: tags,
            frontMatter: frontMatter,
            backlinks: []
        )
    }
    
    func loadAllNotes() async throws -> [ObsidianNote] {
        guard let vault = activeVault else { return [] }
        
        var notes: [ObsidianNote] = []
        let exclusionPaths = [".obsidian", "Templates", "Archive"]
        
        try await scanDirectory(vault.path, excluding: exclusionPaths, collecting: &notes)
        return notes
    }
    
    // MARK: - Wiki Links and Backlinks
    func generateWikiLinks(from content: String) -> [String] {
        let wikiLinkPattern = #"\[\[([^\]]+)\]\]"#
        let regex = try! NSRegularExpression(pattern: wikiLinkPattern)
        let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
        
        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let range = match.range(at: 1)
            let start = content.index(content.startIndex, offsetBy: range.location)
            let end = content.index(start, offsetBy: range.length)
            return String(content[start..<end])
        }
    }
    
    func updateBacklinks(for note: ObsidianNote, allNotes: [ObsidianNote]) {
        var backlinks: [URL] = []
        
        for otherNote in allNotes where otherNote.id != note.id {
            if otherNote.content.contains("[[\(note.title)]]") || 
               otherNote.content.contains("[[\(note.displayName)]]") {
                backlinks.append(otherNote.filePath)
            }
        }
        
        // Speichere Backlinks in Front Matter
        try? saveBacklinks(note: note, backlinks: backlinks)
    }
    
    private func saveBacklinks(note: ObsidianNote, backlinks: [URL]) throws {
        // Hier würde die Logik implementiert werden, um Backlinks in das Front Matter zu speichern
        // Das erfordert das erneute Parsen und Speichern der Datei
    }
    
    // MARK: - File Naming
    private func generateFilename(for title: String) -> String {
        let convention = activeVault?.settings.fileNamingConvention ?? .kebabCase
        
        switch convention {
        case .kebabCase:
            return title.lowercased().replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "_", with: "-")
                .replacingOccurrences(of: "[^a-zA-Z0-9-]", with: "", options: .regularExpression)
        case .snakeCase:
            return title.lowercased().replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "-", with: "_")
                .replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "", options: .regularExpression)
        case .camelCase:
            let components = title.components(separatedBy: " ")
            return components.enumerated().map { index, component in
                index == 0 ? component.lowercased() : component.capitalized
            }.joined()
        case .dateBased:
            return DateFormatter.iso8601.string(from: Date())
        case .custom:
            return title // Implementierung für benutzerdefinierte Konventionen
        }
    }
    
    // MARK: - Front Matter Support
    private func generateFrontMatter(for type: String, additionalFields: [String: Any]) -> String {
        var frontMatterDict: [String: Any] = [
            "type": type,
            "created": DateFormatter.iso8601.string(from: Date())
        ]
        
        frontMatterDict.merge(additionalFields) { _, new in new }
        
        let yamlString = generateYAML(from: frontMatterDict)
        return "---\n\(yamlString)\n---"
    }
    
    private func parseMarkdownContent(_ content: String) -> ([String: String], String) {
        let components = content.components(separatedBy: "---")
        guard components.count >= 3 else { return ([:], content) }
        
        let frontMatterString = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyContent = components[2...].joined(separator: "---").trimmingCharacters(in: .whitespacesAndNewlines)
        
        let frontMatter = parseYAML(frontMatterString)
        return (frontMatter, bodyContent)
    }
    
    private func parseYAML(_ yaml: String) -> [String: String] {
        // Vereinfachte YAML-Parsing-Implementierung
        var result: [String: String] = [:]
        let lines = yaml.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains(":"), !trimmed.hasPrefix("#") {
                let parts = trimmed.components(separatedBy: ":", maxSplits: 1)
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1].trimmingCharacters(in: .whitespaces)
                    result[key] = value
                }
            }
        }
        
        return result
    }
    
    private func generateYAML(from dict: [String: Any]) -> String {
        return dict.compactMap { key, value in
            let stringValue: String
            if let date = value as? Date {
                stringValue = DateFormatter.iso8601.string(from: date)
            } else {
                stringValue = "\(value)"
            }
            return "\(key): \(stringValue)"
        }.joined(separator: "\n")
    }
    
    // MARK: - Content Parsing Helpers
    private func extractTitle(from content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                return String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    private func extractTags(from content: String) -> [String] {
        let tagPattern = #"(?<![\w])#([\w-]+)(?![\w])"#
        let regex = try! NSRegularExpression(pattern: tagPattern)
        let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
        
        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let range = match.range(at: 1)
            let start = content.index(content.startIndex, offsetBy: range.location)
            let end = content.index(start, offsetBy: range.length)
            return String(content[start..<end])
        }
    }
    
    // MARK: - File System Helpers
    private func getFileCreationDate(_ url: URL) -> Date {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.creationDate] as? Date ?? Date()
        } catch {
            return Date()
        }
    }
    
    private func getFileModificationDate(_ url: URL) -> Date {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.modificationDate] as? Date ?? Date()
        } catch {
            return Date()
        }
    }
    
    private func scanDirectory(_ url: URL, excluding exclusionPaths: [String], collecting notes: inout [ObsidianNote]) async throws {
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        
        for content in contents {
            if content.pathExtension == "md" && !exclusionPaths.contains(content.lastPathComponent) {
                let note = try loadNote(from: content)
                notes.append(note)
            } else if content.hasDirectoryPath && !exclusionPaths.contains(content.lastPathComponent) {
                try await scanDirectory(content, excluding: exclusionPaths, collecting: &notes)
            }
        }
    }
    
    // MARK: - Sync and Conflict Resolution
    enum SyncStatus {
        case idle
        case scanning
        case syncing
        case resolvingConflicts
        case completed
        case error(String)
    }
    
    func startSync() async {
        guard let vault = activeVault else { return }
        
        syncStatus = .scanning
        do {
            syncStatus = .syncing
            try await detectChanges(vault: vault)
            syncStatus = .completed
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }
    
    private func detectChanges(vault: ObsidianVault) async throws {
        let lastSyncFile = vault.path.appendingPathComponent(".obsidian/last-sync.json")
        let lastSyncDate = getFileModificationDate(lastSyncFile)
        
        // Implementierung der Änderungsdetektion
        // Hier würde die Logik implementiert werden, um Änderungen zwischen lokaler Datei und Sync-Service zu erkennen
    }
    
    private func startSyncMonitoring() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.checkForChanges()
            }
        }
    }
    
    private func checkForChanges() async {
        guard let vault = activeVault, syncStatus == .idle else { return }
        await startSync()
    }
    
    func resolveConflict(_ conflict: FileConflict, resolution: ConflictResolution) {
        conflicts.removeAll { $0 == conflict }
        
        switch resolution {
        case .keepLocal:
            // Behalte lokale Version
            break
        case .keepRemote:
            // Verwende Remote-Version
            break
        case .merge:
            // Führe Merge durch
            break
        case .manual:
            // Öffne Manuelle Konfliktlösung
            break
        }
    }
    
    // MARK: - Git Integration
    func initializeGitRepository() throws {
        guard let vault = activeVault else { return }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.currentDirectoryURL = vault.path
        process.arguments = ["init"]
        
        try process.run()
        process.waitUntilExit()
        
        // Erstelle .gitignore
        let gitignore = """
        .obsidian/workspace.json
        .obsidian/app.json
        .obsidian/workspace-mobile.json
        .obsidian/cache/
        .obsidian/workspace-ts-stage/
        """
        
        let gitignorePath = vault.path.appendingPathComponent(".gitignore")
        try gitignore.write(to: gitignorePath, atomically: true, encoding: .utf8)
        
        // Initiales Commit
        let addProcess = Process()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        addProcess.currentDirectoryURL = vault.path
        addProcess.arguments = ["add", "."]
        
        try addProcess.run()
        addProcess.waitUntilExit()
        
        let commitProcess = Process()
        commitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitProcess.currentDirectoryURL = vault.path
        commitProcess.arguments = ["commit", "-m", "Initial commit - Obsidian vault"]
        
        try commitProcess.run()
        commitProcess.waitUntilExit()
    }
    
    func commitChanges(message: String) throws {
        guard let vault = activeVault else { return }
        
        let addProcess = Process()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        addProcess.currentDirectoryURL = vault.path
        addProcess.arguments = ["add", "."]
        
        try addProcess.run()
        addProcess.waitUntilExit()
        
        let commitProcess = Process()
        commitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitProcess.currentDirectoryURL = vault.path
        addProcess.arguments = ["commit", "-m", message]
        
        try commitProcess.run()
        commitProcess.waitUntilExit()
    }
    
    // MARK: - Persistence
    private func loadVaults() {
        let vaultsURL = getDocumentsDirectory().appendingPathComponent("obsidian-vaults.json")
        guard let data = try? Data(contentsOf: vaultsURL) else { return }
        
        do {
            vaults = try JSONDecoder().decode([ObsidianVault].self, from: data)
            activeVault = vaults.first { $0.isActive }
        } catch {
            print("Fehler beim Laden der Vaults: \(error)")
        }
    }
    
    private func saveVaults() {
        let vaultsURL = getDocumentsDirectory().appendingPathComponent("obsidian-vaults.json")
        do {
            let data = try JSONEncoder().encode(vaults)
            try data.write(to: vaultsURL)
        } catch {
            print("Fehler beim Speichern der Vaults: \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

// MARK: - Errors
enum ObsidianError: Error, LocalizedError {
    case noActiveVault
    case vaultNotFound
    case fileNotFound
    case invalidPath
    case permissionDenied
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noActiveVault:
            return "Kein aktives Vault ausgewählt"
        case .vaultNotFound:
            return "Vault nicht gefunden"
        case .fileNotFound:
            return "Datei nicht gefunden"
        case .invalidPath:
            return "Ungültiger Pfad"
        case .permissionDenied:
            return "Zugriff verweigert"
        case .syncFailed(let message):
            return "Sync fehlgeschlagen: \(message)"
        }
    }
}