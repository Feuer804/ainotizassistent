import Foundation
import SwiftUI
import Combine

class TextInputCoordinator: ObservableObject {
    @Published var text: String = ""
    @Published var isSaving = false
    @Published var lastSaved: Date?
    @Published var hasNewPasteContent = false
    
    // Properties für das Binding mit der Hauptansicht
    private var textBinding: Binding<String>?
    
    // Auto-save
    private var saveTimer: Timer?
    private let autoSaveInterval: TimeInterval = 3.0
    
    // Word count und reading time
    private var wordCount: Int = 0
    private var readingTime: Int = 0
    
    // Paste Detection
    private let pasteManager = PasteDetectionManager()
    private var pasteCancellable: AnyCancellable?
    
    // Formatted content
    private var isBold = false
    private var isItalic = false
    
    init() {
        setupPasteDetection()
        setupAutoSave()
    }
    
    func setup(text: Binding<String>) {
        textBinding = text
        if let binding = textBinding {
            text = binding.wrappedValue
        }
    }
    
    private func setupPasteDetection() {
        pasteCancellable = pasteManager.$hasNewContent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasNew in
                guard let self = self, hasNew else { return }
                
                self.handleNewPasteContent()
            }
    }
    
    private func setupAutoSave() {
        startAutoSaveTimer()
    }
    
    private func startAutoSaveTimer() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            self?.performAutoSave()
        }
    }
    
    private func performAutoSave() {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isSaving = true
        
        // Simuliert Speichervorgang
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Hier würde die eigentliche Speicherlogik stehen
            Thread.sleep(forTimeInterval: 0.5)
            
            DispatchQueue.main.async {
                self?.isSaving = false
                self?.lastSaved = Date()
            }
        }
    }
    
    private func handleNewPasteContent() {
        let sanitizedContent = pasteManager.sanitizePastedContent(pasteManager.detectedContent)
        
        // Check if content should be auto-formatted
        if pasteManager.shouldAutoFormatContent(sanitizedContent) {
            let formattedContent = autoFormatContent(sanitizedContent)
            insertText(formattedContent)
        } else {
            insertText(sanitizedContent)
        }
        
        hasNewPasteContent = true
        
        // Analysiere eingefügten Inhalt
        analyzePastedContent(sanitizedContent)
    }
    
    private func autoFormatContent(_ content: String) -> String {
        var formatted = content
        
        // Automatische Formatierung basierend auf Inhalt
        formatted = addMarkdownHeaders(formatted)
        formatted = formatLists(formatted)
        formatted = addLineBreaks(formatted)
        
        return formatted
    }
    
    private func addMarkdownHeaders(_ content: String) -> String {
        var lines = content.components(separatedBy: .newlines)
        
        for i in 0..<lines.count {
            let line = lines[i]
            
            // Erkennt Überschriften (Länge und Großbuchstaben)
            if line.count < 50 && 
               line.rangeOfCharacter(from: .lowercaseLetters) == nil &&
               line.rangeOfCharacter(from: .uppercaseLetters) != nil {
                lines[i] = "# " + line
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func formatLists(_ content: String) -> String {
        var formatted = content
        
        // Erkennt nummerierte Listen
        let numberedListPattern = #"^\d+\.\s+(.+)$"#
        formatted = formatted.replacingOccurrences(
            of: numberedListPattern,
            with: "- $1",
            options: .regularExpression
        )
        
        return formatted
    }
    
    private func addLineBreaks(_ content: String) -> String {
        // Fügt Absätze hinzu wo nötig
        return content.replacingOccurrences(
            of: "\\.([A-Z])",
            with: ".\n\n$1",
            options: .regularExpression
        )
    }
    
    private func analyzePastedContent(_ content: String) {
        // Extrahiert strukturierte Daten
        let extractedData = pasteManager.extractStructuredData(content)
        
        // Logik für die Verarbeitung strukturierter Daten
        if extractedData["type"] == "url" {
            // Automatische Link-Formatierung
            insertLink()
        } else if extractedData["type"] == "csv" {
            // CSV zu Tabelle konvertieren
            convertCSVToTable(content)
        }
    }
    
    private func convertCSVToTable(_ csvContent: String) {
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else { return }
        
        var markdownTable = "|"
        let headerCells = lines[0].components(separatedBy: ",")
        for cell in headerCells {
            markdownTable += " \(cell.trimmingCharacters(in: .whitespaces)) |"
        }
        
        markdownTable += "\n|"
        for _ in headerCells {
            markdownTable += " --- |"
        }
        
        for i in 1..<min(lines.count, 10) { // Max 10 Zeilen für Übersicht
            let rowCells = lines[i].components(separatedBy: ",")
            markdownTable += "\n|"
            for cell in rowCells {
                markdownTable += " \(cell.trimmingCharacters(in: .whitespaces)) |"
            }
        }
        
        insertText(markdownTable)
    }
    
    // Text Manipulation Functions
    func insertText(_ newText: String) {
        textBinding?.wrappedValue = newText
    }
    
    func toggleBold() {
        isBold.toggle()
        applyFormatting(.bold)
    }
    
    func toggleItalic() {
        isItalic.toggle()
        applyFormatting(.italic)
    }
    
    func insertList() {
        let listItem = "- "
        insertText(listItem)
    }
    
    func insertLink() {
        let linkText = "[Link Text](\(extractSelectedText() ?? "URL"))"
        insertText(linkText)
    }
    
    func applyFormatting(_ format: TextFormat) {
        switch format {
        case .bold:
            if isBold {
                insertText("**\(extractSelectedText() ?? "Fett")**")
            }
        case .italic:
            if isItalic {
                insertText("*\($0 ?? "Kursiv")*")
            }
        }
    }
    
    private func extractSelectedText() -> String? {
        // Hier würde die Logik zur Extraktion des ausgewählten Texts stehen
        // Für macOS würde dies über NSRange und NSTextView erfolgen
        return nil
    }
    
    enum TextFormat {
        case bold
        case italic
        case underline
        case strikethrough
    }
    
    // Drag & Drop Handling
    func handleDrop(items: [String]) {
        guard let firstItem = items.first else { return }
        
        // Überprüfe ob es sich um Text-Dateien handelt
        if firstItem.hasSuffix(".txt") || firstItem.hasSuffix(".md") {
            readFileContent(firstItem)
        } else {
            insertText(firstItem)
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: String.self) { [weak self] string, _ in
                DispatchQueue.main.async {
                    self?.insertText(string ?? "")
                }
            }
        }
    }
    
    private func readFileContent(_ filePath: String) {
        do {
            let content = try String(contentsOfFile: filePath)
            insertText(content)
        } catch {
            print("Fehler beim Lesen der Datei: \(error)")
        }
    }
    
    // Text Change Handler
    func handleTextChange(_ newValue: String) {
        text = newValue
        
        // Sofortige Wortanzahl-Aktualisierung
        calculateWordCount()
        
        // Restart auto-save timer
        startAutoSaveTimer()
    }
    
    private func calculateWordCount() {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        wordCount = words.count
        
        // Berechne Lesedauer (ca. 200 Wörter pro Minute)
        readingTime = max(1, wordCount / 200)
    }
    
    func calculateStats(_ text: String) -> TextStats {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let wordCount = words.count
        let charCount = text.count
        let lineCount = text.components(separatedBy: .newlines).count
        
        // Lesedauer berechnen (200 WPM)
        let readingTime = max(1, wordCount / 200)
        
        return TextStats(
            wordCount: wordCount,
            charCount: charCount,
            lineCount: lineCount,
            readingTime: readingTime
        )
    }
    
    var timeSinceLastSaved: String {
        guard let lastSaved = lastSaved else { return "" }
        let interval = Date().timeIntervalSince(lastSaved)
        
        if interval < 60 {
            return "gerade eben"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "vor \(minutes) Min."
        } else {
            let hours = Int(interval / 3600)
            return "vor \(hours) Std."
        }
    }
    
    // Export Functions
    func exportAsMarkdown() -> String {
        return text
    }
    
    func exportAsPlainText() -> String {
        // Entfernt Markdown-Formatierungen
        var plainText = text
        plainText = plainText.replacingOccurrences(of: "\\*\\*(.*?)\\*\\*", with: "$1", options: .regularExpression)
        plainText = plainText.replacingOccurrences(of: "\\*(.*?)\\*", with: "$1", options: .regularExpression)
        plainText = plainText.replacingOccurrences(of: "#[ ]?", with: "", options: .regularExpression)
        return plainText
    }
}

// MARK: - Supporting Types

struct TextStats {
    let wordCount: Int
    let charCount: Int
    let lineCount: Int
    let readingTime: Int
}