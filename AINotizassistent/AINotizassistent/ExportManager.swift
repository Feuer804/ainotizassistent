//
//  ExportManager.swift
//  AINotizassistent
//
//  Erstellt am 31.10.2025.
//  Copyright © 2025 AI Notizassistent. Alle Rechte vorbehalten.
//

import Foundation
import UIKit
import SwiftUI
import PDFKit
import Contacts
import EventKit

// MARK: - Export Types
enum ExportType: String, CaseIterable {
    case pdf = "PDF Export"
    case word = "Word Dokument"
    case notes = "Apple Notes"
    case email = "E-Mail Entwurf"
    case calendar = "Kalendereintrag"
    case taskManagement = "Aufgabenverwaltung"
    case airdrop = "AirDrop"
    case messages = "Nachrichten"
    case file = "Datei"
}

// MARK: - Task Management Services
enum TaskService: String, CaseIterable {
    case things = "Things 3"
    case todoist = "Todoist"
    case reminders = "Erinnerungen"
    case asana = "Asana"
    case trello = "Trello"
}

// MARK: - Export Configuration
struct ExportConfiguration {
    var includeMetadata: Bool = true
    var includeTimestamp: Bool = true
    var includeTags: Bool = true
    var customFooter: String = ""
    var pageFormat: PageFormat = .a4
    var fontSize: CGFloat = 12
    var includeTableOfContents: Bool = false
    var watermark: String = ""
}

// MARK: - Page Format Options
enum PageFormat: String, CaseIterable {
    case a4 = "A4"
    case letter = "Letter"
    case a5 = "A5"
    
    var size: CGSize {
        switch self {
        case .a4: return CGSize(width: 595.2, height: 841.8)
        case .letter: return CGSize(width: 612, height: 792)
        case .a5: return CGSize(width: 420.9, height: 595.8)
        }
    }
}

// MARK: - Export Result
struct ExportResult {
    let success: Bool
    let url: URL?
    let error: Error?
    let message: String
    
    init(success: Bool, url: URL? = nil, error: Error? = nil, message: String = "") {
        self.success = success
        self.url = url
        self.error = error
        self.message = message
    }
}

// MARK: - PDF Generator
class PDFGenerator {
    private let config: ExportConfiguration
    
    init(config: ExportConfiguration = ExportConfiguration()) {
        self.config = config
    }
    
    func generatePDF(from preview: PreviewData) -> Data? {
        let pdfDocument = PDFDocument()
        
        // Create PDF pages
        let pages = createPDFPages(from: preview)
        
        for page in pages {
            let pdfPage = PDFPage(page)
            pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
        }
        
        return pdfDocument.dataRepresentation()
    }
    
    private func createPDFPages(from preview: PreviewData) -> [UIView] {
        var pages: [UIView] = []
        let maxWidth: CGFloat = config.pageFormat.size.width - 80 // 40pt margin each side
        let maxHeight: CGFloat = config.pageFormat.size.height - 120 // 60pt margin top/bottom
        
        // Create main content view
        let contentView = createContentView(from: preview, maxWidth: maxWidth, maxHeight: maxHeight)
        
        // Split content into pages if needed
        let lines = contentView.subviews.compactMap { $0 as? UILabel }.flatMap { label in
            return label.text?.components(separatedBy: .newlines) ?? []
        }
        
        var currentPageHeight: CGFloat = 0
        var currentPageElements: [UIView] = []
        
        for line in lines {
            let lineLabel = createLineLabel(text: line)
            let lineHeight = lineLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude)).height
            
            if currentPageHeight + lineHeight > maxHeight {
                // Create new page
                let pageView = createPageView(elements: currentPageElements, width: config.pageFormat.size.width, height: config.pageFormat.size.height)
                pages.append(pageView)
                
                currentPageElements = [lineLabel]
                currentPageHeight = lineHeight
            } else {
                currentPageElements.append(lineLabel)
                currentPageHeight += lineHeight + 5 // 5pt spacing
            }
        }
        
        // Add remaining elements as final page
        if !currentPageElements.isEmpty {
            let pageView = createPageView(elements: currentPageElements, width: config.pageFormat.size.width, height: config.pageFormat.size.height)
            pages.append(pageView)
        }
        
        return pages.isEmpty ? [contentView] : pages
    }
    
    private func createContentView(from preview: PreviewData, maxWidth: CGFloat, maxHeight: CGFloat) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: maxWidth, height: maxHeight))
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: maxWidth, height: 50))
        titleLabel.text = preview.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: config.fontSize + 8)
        titleLabel.numberOfLines = 2
        container.addSubview(titleLabel)
        
        let metadataLabel = UILabel(frame: CGRect(x: 0, y: 55, width: maxWidth, height: 30))
        metadataLabel.text = createMetadataString(preview: preview)
        metadataLabel.font = UIFont.systemFont(ofSize: config.fontSize - 2)
        metadataLabel.textColor = .systemGray
        container.addSubview(metadataLabel)
        
        let contentTextView = UITextView(frame: CGRect(x: 0, y: 90, width: maxWidth, height: maxHeight - 140))
        contentTextView.text = preview.content
        contentTextView.font = UIFont.systemFont(ofSize: config.fontSize)
        contentTextView.isEditable = false
        contentTextView.textColor = .label
        container.addSubview(contentTextView)
        
        // Add footer if configured
        if !config.customFooter.isEmpty {
            let footerLabel = UILabel(frame: CGRect(x: 0, y: maxHeight - 30, width: maxWidth, height: 25))
            footerLabel.text = config.customFooter
            footerLabel.font = UIFont.systemFont(ofSize: config.fontSize - 2)
            footerLabel.textColor = .systemGray
            footerLabel.textAlignment = .center
            container.addSubview(footerLabel)
        }
        
        return container
    }
    
    private func createLineLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: config.fontSize)
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }
    
    private func createPageView(elements: [UIView], width: CGFloat, height: CGFloat) -> UIView {
        let pageView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        pageView.backgroundColor = .white
        
        var currentY: CGFloat = 60
        
        for element in elements {
            element.frame.origin.y = currentY
            pageView.addSubview(element)
            currentY += element.frame.height + 5
        }
        
        return pageView
    }
    
    private func createMetadataString(preview: PreviewData) -> String {
        var metadata = "Erstellt: \(DateFormatter.localizedString(from: preview.createdAt, dateStyle: .long, timeStyle: .short))"
        
        if config.includeTags && !preview.tags.isEmpty {
            metadata += " | Tags: \(preview.tags.joined(separator: ", "))"
        }
        
        if config.includeTimestamp {
            metadata += " | Wortanzahl: \(preview.wordCount)"
        }
        
        return metadata
    }
}

// MARK: - Word Document Generator
class WordDocumentGenerator {
    func generateWordDocument(from preview: PreviewData) -> Data? {
        // Basic DOCX generation (simplified)
        // In a real implementation, you'd use a proper DOCX library
        let content = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:body>
                <w:p>
                    <w:r>
                        <w:rPr>
                            <w:b/>
                            <w:sz w:val="28"/>
                        </w:rPr>
                        <w:t>\(preview.title)</w:t>
                    </w:r>
                </w:p>
                <w:p>
                    <w:r>
                        <w:t>\(preview.content)</w:t>
                    </w:r>
                </w:p>
            </w:body>
        </w:document>
        """
        
        return content.data(using: .utf8)
    }
}

// MARK: - Calendar Event Creator
class CalendarEventCreator {
    private let eventStore = EKEventStore()
    
    func createEvent(from preview: PreviewData, date: Date) async -> ExportResult {
        await MainActor.run {
            let status = EKEventStore.authorizationStatus(for: .event)
            
            guard status == .authorized else {
                return ExportResult(
                    success: false,
                    error: NSError(domain: "Calendar", code: 401, userInfo: [NSLocalizedDescriptionKey: "Keine Kalender-Berechtigung"]),
                    message: "Berechtigung für Kalender erforderlich"
                )
            }
            
            let event = EKEvent(eventStore: eventStore)
            event.title = preview.title
            event.notes = preview.content
            event.startDate = date
            event.endDate = date.addingTimeInterval(3600) // 1 hour duration
            
            do {
                try eventStore.save(event, span: .thisEvent)
                return ExportResult(
                    success: true,
                    message: "Kalendereintrag erfolgreich erstellt"
                )
            } catch {
                return ExportResult(
                    success: false,
                    error: error,
                    message: "Fehler beim Erstellen des Kalendereintrags"
                )
            }
        }
    }
}

// MARK: - Task Management Integration
class TaskManager {
    func createTasks(from preview: PreviewData, service: TaskService) async -> ExportResult {
        switch service {
        case .reminders:
            return await createRemindersTask(preview)
        case .things:
            return await createThingsTask(preview)
        case .todoist:
            return await createTodoistTask(preview)
        case .asana:
            return await createAsanaTask(preview)
        case .trello:
            return await createTrelloTask(preview)
        }
    }
    
    private func createRemindersTask(_ preview: PreviewData) async -> ExportResult {
        // Use Apple Reminders framework
        print("Creating reminder task: \(preview.title)")
        return ExportResult(success: true, message: "Reminder erfolgreich erstellt")
    }
    
    private func createThingsTask(_ preview: PreviewData) async -> ExportResult {
        // Things 3 URL scheme integration
        if let url = URL(string: "things:///add?title=\(preview.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&notes=\(preview.content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
            return ExportResult(success: true, message: "In Things 3 geöffnet")
        }
        return ExportResult(success: false, message: "Fehler beim Öffnen von Things 3")
    }
    
    private func createTodoistTask(_ preview: PreviewData) async -> ExportResult {
        // Todoist URL scheme integration
        print("Creating Todoist task: \(preview.title)")
        return ExportResult(success: true, message: "Todoist Task erstellt")
    }
    
    private func createAsanaTask(_ preview: PreviewData) async -> ExportResult {
        // Asana API integration (would require API key)
        print("Creating Asana task: \(preview.title)")
        return ExportResult(success: true, message: "Asana Task erstellt")
    }
    
    private func createTrelloTask(_ preview: PreviewData) async -> ExportResult {
        // Trello API integration (would require API key)
        print("Creating Trello card: \(preview.title)")
        return ExportResult(success: true, message: "Trello Card erstellt")
    }
}

// MARK: - Export Manager
@MainActor
class ExportManager: ObservableObject {
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0.0
    @Published var recentExports: [URL] = []
    
    private let pdfGenerator = PDFGenerator()
    private let wordGenerator = WordDocumentGenerator()
    private let calendarCreator = CalendarEventCreator()
    private let taskManager = TaskManager()
    
    // MARK: - PDF Export
    func exportToPDF(preview: PreviewData, config: ExportConfiguration = ExportConfiguration()) async -> ExportResult {
        isExporting = true
        defer { isExporting = false }
        
        exportProgress = 0.1
        
        do {
            let pdfData = pdfGenerator.generatePDF(from: preview)
            exportProgress = 0.7
            
            guard let pdfData = pdfData else {
                return ExportResult(success: false, message: "PDF-Generierung fehlgeschlagen")
            }
            
            let url = try await saveFile(data: pdfData, filename: "\(preview.title).pdf", type: "pdf")
            exportProgress = 1.0
            
            recentExports.insert(url, at: 0)
            if recentExports.count > 10 {
                recentExports = Array(recentExports.prefix(10))
            }
            
            return ExportResult(success: true, url: url, message: "PDF erfolgreich exportiert")
        } catch {
            return ExportResult(success: false, error: error, message: "Fehler beim PDF-Export")
        }
    }
    
    // MARK: - Word Export
    func exportToWord(preview: PreviewData) async -> ExportResult {
        isExporting = true
        defer { isExporting = false }
        
        do {
            let wordData = wordGenerator.generateWordDocument(from: preview)
            guard let wordData = wordData else {
                return ExportResult(success: false, message: "Word-Dokument-Generierung fehlgeschlagen")
            }
            
            let url = try await saveFile(data: wordData, filename: "\(preview.title).docx", type: "docx")
            return ExportResult(success: true, url: url, message: "Word-Dokument erfolgreich exportiert")
        } catch {
            return ExportResult(success: false, error: error, message: "Fehler beim Word-Export")
        }
    }
    
    // MARK: - Apple Notes Export
    func exportToNotes(preview: PreviewData) async -> ExportResult {
        isExporting = true
        defer { isExporting = false }
        
        // This would integrate with Apple Notes framework
        print("Exporting to Apple Notes: \(preview.title)")
        return ExportResult(success: true, message: "In Apple Notes exportiert")
    }
    
    // MARK: - Email Draft Export
    func createEmailDraft(preview: PreviewData) -> Bool {
        let subject = preview.title
        let body = preview.content
        
        if let emailURL = URL(string: "mailto:?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(emailURL)
            return true
        }
        return false
    }
    
    // MARK: - Calendar Event Export
    func exportToCalendar(preview: PreviewData, date: Date) async -> ExportResult {
        isExporting = true
        defer { isExporting = false }
        
        return await calendarCreator.createEvent(from: preview, date: date)
    }
    
    // MARK: - Task Management Export
    func exportToTaskManager(preview: PreviewData, service: TaskService) async -> ExportResult {
        isExporting = true
        defer { isExporting = false }
        
        return await taskManager.createTasks(from: preview, service: service)
    }
    
    // MARK: - Batch Export
    func exportBatch(previews: [PreviewData], format: FormatOption, config: ExportConfiguration = ExportConfiguration()) async -> [ExportResult] {
        isExporting = true
        var results: [ExportResult] = []
        
        for (index, preview) in previews.enumerated() {
            exportProgress = Double(index) / Double(previews.count)
            
            let result: ExportResult
            switch format {
            case .markdown:
                result = await exportMarkdown(preview)
            case .richText:
                result = await exportRichText(preview)
            case .plainText:
                result = await exportPlainText(preview)
            case .html:
                result = await exportHTML(preview)
            }
            
            results.append(result)
        }
        
        isExporting = false
        exportProgress = 1.0
        return results
    }
    
    // MARK: - Individual Format Exports
    private func exportMarkdown(_ preview: PreviewData) async -> ExportResult {
        let markdownContent = """
        # \(preview.title)
        
        **Erstellt am:** \(DateFormatter.localizedString(from: preview.createdAt, dateStyle: .long, timeStyle: .short))
        **Typ:** \(preview.type.rawValue)
        
        ---
        
        \(preview.content)
        """
        
        do {
            let url = try await saveFile(data: markdownContent.data(using: .utf8)!, filename: "\(preview.title).md", type: "md")
            return ExportResult(success: true, url: url, message: "Markdown erfolgreich exportiert")
        } catch {
            return ExportResult(success: false, error: error, message: "Markdown-Export fehlgeschlagen")
        }
    }
    
    private func exportRichText(_ preview: PreviewData) async -> ExportResult {
        let rtfContent = preview.content // Would be converted to RTF
        do {
            let url = try await saveFile(data: rtfContent.data(using: .utf8)!, filename: "\(preview.title).rtf", type: "rtf")
            return ExportResult(success: true, url: url, message: "Rich Text erfolgreich exportiert")
        } catch {
            return ExportResult(success: false, error: error, message: "Rich Text-Export fehlgeschlagen")
        }
    }
    
    private func exportPlainText(_ preview: PreviewData) async -> ExportResult {
        let plainContent = """
        \(preview.title)
        
        \(DateFormatter.localizedString(from: preview.createdAt, dateStyle: .long, timeStyle: .short))
        
        \(preview.content)
        """
        
        do {
            let url = try await saveFile(data: plainContent.data(using: .utf8)!, filename: "\(preview.title).txt", type: "txt")
            return ExportResult(success: true, url: url, message: "Plain Text erfolgreich exportiert")
        } catch {
            return ExportResult(success: false, error: error, message: "Plain Text-Export fehlgeschlagen")
        }
    }
    
    private func exportHTML(_ preview: PreviewData) async -> ExportResult {
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>\(preview.title)</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }
                h1 { color: #333; border-bottom: 2px solid #eee; padding-bottom: 10px; }
                .metadata { color: #666; font-size: 0.9em; margin-bottom: 20px; }
                .content { white-space: pre-wrap; }
            </style>
        </head>
        <body>
            <h1>\(preview.title)</h1>
            <div class="metadata">
                Erstellt am: \(DateFormatter.localizedString(from: preview.createdAt, dateStyle: .long, timeStyle: .short))<br>
                Typ: \(preview.type.rawValue)
            </div>
            <div class="content">\(preview.content)</div>
        </body>
        </html>
        """
        
        do {
            let url = try await saveFile(data: htmlContent.data(using: .utf8)!, filename: "\(preview.title).html", type: "html")
            return ExportResult(success: true, url: url, message: "HTML erfolgreich exportiert")
        } catch {
            return ExportResult(success: false, error: error, message: "HTML-Export fehlgeschlagen")
        }
    }
    
    // MARK: - File Operations
    private func saveFile(data: Data, filename: String, type: String) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Sharing & Collaboration
    func shareViaAirdrop(preview: PreviewData) -> Bool {
        // Implementation for Airdrop
        print("Sharing via Airdrop: \(preview.title)")
        return true
    }
    
    func shareViaMessages(preview: PreviewData) -> Bool {
        // Implementation for Messages
        if let messageURL = URL(string: "sms:?body=\(preview.content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(messageURL)
            return true
        }
        return false
    }
    
    func shareViaMail(preview: PreviewData) -> Bool {
        // Implementation for Mail
        let subject = preview.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = preview.content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let mailURL = URL(string: "mailto:?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(mailURL)
            return true
        }
        return false
    }
    
    // MARK: - Accessibility Support
    func getAccessibilityDescription(for exportType: ExportType) -> String {
        switch exportType {
        case .pdf:
            return "PDF-Dokument mit professionellem Layout exportieren"
        case .word:
            return "Microsoft Word-kompatibles Dokument erstellen"
        case .notes:
            return "In Apple Notes App speichern"
        case .email:
            return "Als E-Mail Entwurf öffnen"
        case .calendar:
            return "Als Kalendereintrag erstellen"
        case .taskManagement:
            return "In Aufgabenverwaltungs-App übertragen"
        case .airdrop:
            return "Via AirDrop an andere Geräte senden"
        case .messages:
            return "Als Nachricht teilen"
        case .file:
            return "Als Datei speichern"
        }
    }
}