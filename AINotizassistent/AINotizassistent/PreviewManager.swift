//
//  PreviewManager.swift
//  AINotizassistent
//
//  Erstellt am 31.10.2025.
//  Copyright © 2025 AI Notizassistent. Alle Rechte vorbehalten.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Preview Types
enum PreviewType: String, CaseIterable {
    case summary = "Zusammenfassung"
    case todo = "Aufgabenliste"
    case meeting = "Meeting-Protokoll"
    case note = "Notiz"
}

// MARK: - Format Options
enum FormatOption: String, CaseIterable, Identifiable {
    case markdown = "Markdown"
    case richText = "Rich Text"
    case plainText = "Plain Text"
    case html = "HTML"
    
    var id: String { rawValue }
    
    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .richText: return "rtf"
        case .plainText: return "txt"
        case .html: return "html"
        }
    }
    
    var mimeType: String {
        switch self {
        case .markdown: return "text/markdown"
        case .richText: return "application/rtf"
        case .plainText: return "text/plain"
        case .html: return "text/html"
        }
    }
}

// MARK: - Preview Data Model
struct PreviewData: Identifiable {
    let id = UUID()
    let type: PreviewType
    var title: String
    var content: String
    var format: FormatOption
    let createdAt: Date
    var modifiedAt: Date
    var tags: [String]
    var metadata: [String: String]
    
    init(type: PreviewType, title: String, content: String, format: FormatOption = .markdown) {
        self.type = type
        self.title = title
        self.content = content
        self.format = format
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.tags = []
        self.metadata = [:]
    }
    
    var wordCount: Int {
        content.split { !$0.isLetter }.count
    }
    
    var readingTime: Int {
        // 200 WPM (Wörter pro Minute)
        return max(1, Int(ceil(Double(wordCount) / 200.0)))
    }
}

// MARK: - Preview Template
struct PreviewTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var type: PreviewType
    var format: FormatOption
    var template: String
    var variables: [String: String]
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, description: String, type: PreviewType, format: FormatOption = .markdown, template: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.format = format
        self.template = template
        self.variables = [:]
        self.isDefault = isDefault
    }
}

// MARK: - Version History Entry
struct VersionEntry: Identifiable, Codable {
    let id: UUID
    let version: Int
    let content: String
    let timestamp: Date
    let changeDescription: String
    
    init(version: Int, content: String, changeDescription: String = "") {
        self.id = UUID()
        self.version = version
        self.content = content
        self.timestamp = Date()
        self.changeDescription = changeDescription
    }
}

// MARK: - Preview Manager
@MainActor
class PreviewManager: ObservableObject {
    @Published var currentPreview: PreviewData?
    @Published var previewHistory: [PreviewData] = []
    @Published var templates: [PreviewTemplate] = []
    @Published var selectedTemplate: PreviewTemplate?
    @Published var isLivePreviewEnabled: Bool = true
    @Published var isEditing: Bool = false
    @Published var realTimeUpdates: [String: Any] = [:]
    
    // Version History
    @Published var versionHistory: [VersionEntry] = []
    private var currentVersion = 0
    
    // Active Editors
    private var activeEditors: Set<String> = []
    private var collaborators: [String: Date] = [:]
    
    // Private Properties
    private let userDefaults = UserDefaults.standard
    private let templatesKey = "previewTemplates"
    private let historyKey = "previewHistory"
    private let maxHistoryItems = 50
    private var cancellables = Set<AnyCancellable>()
    
    // Preview Configuration
    let previewUpdateDebounceInterval: TimeInterval = 0.5
    
    // MARK: - Initialization
    init() {
        loadTemplates()
        loadHistory()
        setupDefaultTemplates()
        setupRealTimeUpdates()
    }
    
    // MARK: - Template Management
    private func setupDefaultTemplates() {
        if templates.isEmpty {
            let defaultTemplates = [
                // Summary Template
                PreviewTemplate(
                    name: "Standard Zusammenfassung",
                    description: "Allgemeine Zusammenfassung mit Kernpunkten",
                    type: .summary,
                    template: """
                    # {{title}}
                    
                    **Erstellt am:** {{date}}
                    
                    ## Kernpunkte
                    {{points}}
                    
                    ## Wichtige Erkenntnisse
                    {{insights}}
                    
                    ## Nächste Schritte
                    {{nextSteps}}
                    """,
                    isDefault: true
                ),
                
                // Todo Template
                PreviewTemplate(
                    name: "Aufgabenliste mit Prioritäten",
                    description: "Strukturierte Aufgabenliste mit Prioritäten und Due Dates",
                    type: .todo,
                    template: """
                    # {{title}}
                    
                    **Erstellt am:** {{date}}
                    
                    ## 🔴 Hohe Priorität
                    {{highPriority}}
                    
                    ## 🟡 Mittlere Priorität
                    {{mediumPriority}}
                    
                    ## 🟢 Niedrige Priorität
                    {{lowPriority}}
                    
                    ## 📋 Generelle Aufgaben
                    {{generalTasks}}
                    """,
                    isDefault: true
                ),
                
                // Meeting Template
                PreviewTemplate(
                    name: "Meeting Protokoll",
                    description: "Strukturiertes Meeting-Protokoll mit Teilnehmern und Aktionspunkten",
                    type: .meeting,
                    template: """
                    # Meeting: {{title}}
                    
                    **Datum:** {{date}}
                    **Teilnehmer:** {{participants}}
                    **Dauer:** {{duration}}
                    
                    ## 📋 Tagesordnung
                    {{agenda}}
                    
                    ## 💬 Besprechungspunkte
                    {{discussion}}
                    
                    ## ✅ Beschlüsse
                    {{decisions}}
                    
                    ## 🎯 Aktionspunkte
                    {{actionItems}}
                    
                    ## 📅 Nächstes Meeting
                    {{nextMeeting}}
                    """,
                    isDefault: true
                )
            ]
            
            templates.append(contentsOf: defaultTemplates)
            saveTemplates()
        }
    }
    
    func loadTemplates() {
        if let data = userDefaults.data(forKey: templatesKey),
           let decodedTemplates = try? JSONDecoder().decode([PreviewTemplate].self, from: data) {
            templates = decodedTemplates
        }
    }
    
    func saveTemplates() {
        if let encodedTemplates = try? JSONEncoder().encode(templates) {
            userDefaults.set(encodedTemplates, forKey: templatesKey)
        }
    }
    
    func createTemplate(from preview: PreviewData) -> PreviewTemplate {
        return PreviewTemplate(
            name: "\(preview.title) Vorlage",
            description: "Automatisch generierte Vorlage",
            type: preview.type,
            format: preview.format,
            template: preview.content
        )
    }
    
    func applyTemplate(_ template: PreviewTemplate, with variables: [String: String] = [:]) -> PreviewData {
        let currentDate = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short)
        var processedContent = template.template
        
        // Replace variables
        variables.forEach { key, value in
            processedContent = processedContent.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        
        // Add default variables
        if !variables.keys.contains("date") {
            processedContent = processedContent.replacingOccurrences(of: "{{date}}", with: currentDate)
        }
        
        return PreviewData(
            type: template.type,
            title: "Neues Dokument von \(template.name)",
            content: processedContent,
            format: template.format
        )
    }
    
    // MARK: - Preview Creation & Management
    func createPreview(type: PreviewType, title: String, content: String = "", format: FormatOption = .markdown) -> PreviewData {
        let preview = PreviewData(type: type, title: title, content: content, format: format)
        currentPreview = preview
        addToHistory(preview)
        return preview
    }
    
    func updatePreview(_ preview: PreviewData) {
        var updatedPreview = preview
        updatedPreview.modifiedAt = Date()
        
        currentPreview = updatedPreview
        
        // Add to version history if content changed significantly
        if let lastVersion = versionHistory.last, lastVersion.content != updatedPreview.content {
            currentVersion += 1
            let versionEntry = VersionEntry(
                version: currentVersion,
                content: updatedPreview.content,
                changeDescription: "Automatische Speicherung"
            )
            versionHistory.append(versionEntry)
            
            // Keep only last 20 versions
            if versionHistory.count > 20 {
                versionHistory.removeFirst()
            }
        }
        
        addToHistory(updatedPreview)
        updateRealTimeUpdates(for: updatedPreview)
    }
    
    func duplicatePreview(_ preview: PreviewData) -> PreviewData {
        var duplicated = preview
        duplicated.id = UUID()
        duplicated.title = "\(preview.title) (Kopie)"
        duplicated.createdAt = Date()
        duplicated.modifiedAt = Date()
        
        return duplicated
    }
    
    func deletePreview(_ preview: PreviewData) {
        previewHistory.removeAll { $0.id == preview.id }
        if currentPreview?.id == preview.id {
            currentPreview = nil
        }
    }
    
    func searchPreviews(query: String) -> [PreviewData] {
        guard !query.isEmpty else { return previewHistory }
        
        return previewHistory.filter { preview in
            preview.title.localizedCaseInsensitiveContains(query) ||
            preview.content.localizedCaseInsensitiveContains(query) ||
            preview.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func filterPreviews(by type: PreviewType? = nil, by format: FormatOption? = nil) -> [PreviewData] {
        var filtered = previewHistory
        
        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }
        
        if let format = format {
            filtered = filtered.filter { $0.format == format }
        }
        
        return filtered.sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    // MARK: - History Management
    private func addToHistory(_ preview: PreviewData) {
        // Remove existing entry with same ID
        previewHistory.removeAll { $0.id == preview.id }
        
        // Add to front of history
        previewHistory.insert(preview, at: 0)
        
        // Limit history size
        if previewHistory.count > maxHistoryItems {
            previewHistory = Array(previewHistory.prefix(maxHistoryItems))
        }
        
        // Save to UserDefaults (compressed)
        saveHistory()
    }
    
    private func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let decodedHistory = try? JSONDecoder().decode([PreviewData].self, from: data) {
            previewHistory = decodedHistory
        }
    }
    
    private func saveHistory() {
        // Compress history for storage
        let limitedHistory = Array(previewHistory.prefix(20))
        if let encodedHistory = try? JSONEncoder().encode(limitedHistory) {
            userDefaults.set(encodedHistory, forKey: historyKey)
        }
    }
    
    // MARK: - Real-time Updates
    private func setupRealTimeUpdates() {
        // Set up real-time preview updates
        if isLivePreviewEnabled {
            $currentPreview
                .debounce(for: .seconds(previewUpdateDebounceInterval), scheduler: DispatchQueue.main)
                .sink { [weak self] preview in
                    self?.updateRealTimeUpdates(for: preview)
                }
                .store(in: &cancellables)
        }
    }
    
    private func updateRealTimeUpdates(for preview: PreviewData?) {
        guard let preview = preview else {
            realTimeUpdates.removeAll()
            return
        }
        
        realTimeUpdates["title"] = preview.title
        realTimeUpdates["content"] = preview.content
        realTimeUpdates["wordCount"] = preview.wordCount
        realTimeUpdates["readingTime"] = preview.readingTime
        realTimeUpdates["lastModified"] = preview.modifiedAt
        realTimeUpdates["type"] = preview.type.rawValue
        realTimeUpdates["format"] = preview.format.rawValue
    }
    
    func startEditing() {
        isEditing = true
        let userId = UUID().uuidString
        activeEditors.insert(userId)
    }
    
    func stopEditing() {
        isEditing = false
        let userId = UUID().uuidString
        activeEditors.remove(userId)
    }
    
    // MARK: - Collaboration Features
    func addCollaborator(_ userId: String) {
        collaborators[userId] = Date()
    }
    
    func removeCollaborator(_ userId: String) {
        collaborators.removeValue(forKey: userId)
    }
    
    func getActiveCollaborators() -> [String: Date] {
        // Remove inactive collaborators (no activity for 5 minutes)
        let cutoffTime = Date().addingTimeInterval(-300)
        return collaborators.filter { $0.value > cutoffTime }
    }
    
    func shareViaAirdrop(_ preview: PreviewData) -> Bool {
        // Implementation for Airdrop sharing
        // This would integrate with UIActivityViewController
        print("Airdrop sharing für: \(preview.title)")
        return true
    }
    
    func shareViaMessages(_ preview: PreviewData) -> Bool {
        // Implementation for Messages sharing
        print("Messages sharing für: \(preview.title)")
        return true
    }
    
    func shareViaMail(_ preview: PreviewData) -> Bool {
        // Implementation for Mail sharing
        print("Mail sharing für: \(preview.title)")
        return true
    }
    
    // MARK: - Export Preparation
    func prepareForExport(_ preview: PreviewData, format: FormatOption) -> Data? {
        switch format {
        case .markdown, .plainText, .html:
            return preview.content.data(using: .utf8)
        case .richText:
            // Convert to RTF format
            return convertToRTF(preview.content)
        }
    }
    
    private func convertToRTF(_ content: String) -> Data? {
        // Basic RTF conversion
        let rtfHeader = "{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Times New Roman;}}"
        let rtfContent = content.replacingOccurrences(of: "\n", with: "\\par ")
        let rtfFooter = "}"
        
        let rtfString = rtfHeader + rtfContent + rtfFooter
        return rtfString.data(using: .utf8)
    }
    
    // MARK: - Accessibility Support
    func getAccessibilityDescription(for preview: PreviewData) -> String {
        return """
        \(preview.type.rawValue) Dokument: \(preview.title)
        Erstellt am: \(DateFormatter.localizedString(from: preview.createdAt, dateStyle: .long, timeStyle: .short))
        Wörter: \(preview.wordCount)
        Lesezeit: \(preview.readingTime) Minuten
        Format: \(preview.format.rawValue)
        """
    }
}

// MARK: - Preview Formatter Extensions
extension PreviewManager {
    func formatContent(_ content: String, to format: FormatOption) -> String {
        switch format {
        case .markdown:
            return formatAsMarkdown(content)
        case .richText:
            return formatAsRichText(content)
        case .plainText:
            return formatAsPlainText(content)
        case .html:
            return formatAsHTML(content)
        }
    }
    
    private func formatAsMarkdown(_ content: String) -> String {
        // Auto-detect and format as Markdown
        var formatted = content
        
        // Convert headers (# ## ###)
        formatted = formatted.replacingOccurrences(
            of: "^(#{1,6})\\s*(.+)$",
            with: "$1 $2",
            options: .regularExpression
        )
        
        // Convert bold text
        formatted = formatted.replacingOccurrences(
            of: "\\*\\*(.*?)\\*\\*",
            with: "**$1**",
            options: .regularExpression
        )
        
        // Convert italic text
        formatted = formatted.replacingOccurrences(
            of: "\\*(.*?)\\*",
            with: "*$1*",
            options: .regularExpression
        )
        
        return formatted
    }
    
    private func formatAsRichText(_ content: String) -> String {
        // Return RTF formatted content
        let rtfContent = content
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "{", with: "\\{")
            .replacingOccurrences(of: "}", with: "\\}")
            .replacingOccurrences(of: "\n", with: "\\par ")
        
        return "{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Times New Roman;}}\\f0 " + rtfContent + "}"
    }
    
    private func formatAsPlainText(_ content: String) -> String {
        // Strip all formatting and return plain text
        return content
            .replacingOccurrences(of: "#+ ", with: "")
            .replacingOccurrences(of: "\\*\\*(.*?)\\*\\*", with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "\\*(.*?)\\*", with: "$1", options: .regularExpression)
    }
    
    private func formatAsHTML(_ content: String) -> String {
        // Convert to basic HTML
        var html = content
        
        // Convert headers
        html = html.replacingOccurrences(
            of: "^(#{1,6})\\s*(.+)$",
            with: "<h$1>$2</h$1>",
            options: .regularExpression
        )
        
        // Convert bold text
        html = html.replacingOccurrences(
            of: "\\*\\*(.*?)\\*\\*",
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        
        // Convert italic text
        html = html.replacingOccurrences(
            of: "\\*(.*?)\\*",
            with: "<em>$1</em>",
            options: .regularExpression
        )
        
        // Convert line breaks to paragraphs
        let paragraphs = html.split(whereSeparator: \.isNewline)
        html = paragraphs.joined(separator: "</p><p>")
        html = "<p>" + html + "</p>"
        
        return html
    }
}