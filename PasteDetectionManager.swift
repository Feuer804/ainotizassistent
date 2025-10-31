import Foundation
import AppKit
import Combine

class PasteDetectionManager: ObservableObject {
    @Published var hasNewContent = false
    @Published var detectedContent: String = ""
    @Published var pasteType: PasteType = .none
    
    private let pasteboard = NSPasteboard.general
    private var monitor: Any?
    private var lastChangeCount: Int = 0
    
    enum PasteType {
        case text
        case richText
        case url
        case image
        case none
    }
    
    struct DetectedPasteContent {
        let type: PasteType
        let content: String
        let timestamp: Date
        let isFormatted: Bool
    }
    
    init() {
        setupMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func setupMonitoring() {
        lastChangeCount = pasteboard.changeCount
        
        monitor = NSEvent.addGlobalMonitor(forEvents: [.keyDown]) { [weak self] event in
            guard let self = self else { return }
            
            // Erkennt Cmd+V (Paste)
            if event.modifierFlags.contains(.command) && event.keyCode == 9 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.detectPasteContent()
                }
            }
        }
    }
    
    func detectPasteContent() {
        guard let string = pasteboard.string(forType: .string) else {
            // Überprüfe andere Typen
            detectAlternativePasteTypes()
            return
        }
        
        let detectedContent = DetectedPasteContent(
            type: .text,
            content: string,
            timestamp: Date(),
            isFormatted: isFormattedText()
        )
        
        processDetectedContent(detectedContent)
    }
    
    private func detectAlternativePasteTypes() {
        // URL-Erkennung
        if let urlString = pasteboard.string(forType: .URL),
           let url = URL(string: urlString) {
            let detectedContent = DetectedPasteContent(
                type: .url,
                content: urlString,
                timestamp: Date(),
                isFormatted: false
            )
            processDetectedContent(detectedContent)
            return
        }
        
        // Bild-Erkennung
        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            let detectedContent = DetectedPasteContent(
                type: .image,
                content: "[Bild eingefügt]",
                timestamp: Date(),
                isFormatted: false
            )
            processDetectedContent(detectedContent)
            return
        }
        
        // RTF-Erkennung
        if let rtfData = pasteboard.data(forType: .rtf) {
            let detectedContent = DetectedPasteContent(
                type: .richText,
                content: "[Formatierter Text eingefügt]",
                timestamp: Date(),
                isFormatted: true
            )
            processDetectedContent(detectedContent)
        }
    }
    
    private func isFormattedText() -> Bool {
        // Überprüft, ob der eingefügte Text Formatierungen enthält
        return pasteboard.data(forType: .rtf) != nil || 
               pasteboard.data(forType: .html) != nil
    }
    
    private func processDetectedContent(_ content: DetectedPasteContent) {
        DispatchQueue.main.async {
            self.detectedContent = content.content
            self.pasteType = content.type
            self.hasNewContent = true
            
            // Automatisches Reset nach 3 Sekunden
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.hasNewContent = false
            }
        }
    }
    
    func startContinuousMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let currentChangeCount = self.pasteboard.changeCount
            if currentChangeCount != self.lastChangeCount {
                self.lastChangeCount = currentChangeCount
                self.detectPasteContent()
            }
        }
    }
    
    func stopMonitoring() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    // Erweiterte Funktionen für verschiedene Paste-Szenarien
    func handleLargePaste(_ content: String, completion: @escaping (Bool) -> Void) {
        // Handhabt große Text-Einfügungen mit Fortschrittsanzeige
        DispatchQueue.global(qos: .userInitiated).async {
            let isLarge = content.count > 10000
            
            DispatchQueue.main.async {
                completion(isLarge)
            }
        }
    }
    
    func sanitizePastedContent(_ content: String) -> String {
        // Entfernt unerwünschte Formatierungen beim Einfügen
        var sanitized = content
        
        // Entfernt übermäßige Leerzeichen
        sanitized = sanitized.replacingOccurrences(
            of: "\\s+\\n",
            with: "\n",
            options: .regularExpression
        )
        
        // Normalisiert Zeilenenden
        sanitized = sanitized.replacingOccurrences(
            of: "\\r\\n|\\r",
            with: "\n",
            options: .regularExpression
        )
        
        return sanitized
    }
    
    func extractStructuredData(_ content: String) -> [String: String] {
        // Extrahiert strukturierte Daten aus eingefügtem Inhalt
        var data: [String: String] = [:]
        
        // CSV-Erkennung
        if content.contains(",") && content.contains("\n") {
            let lines = content.components(separatedBy: .newlines)
            if lines.count > 1 {
                data["type"] = "csv"
                data["rows"] = "\(lines.count)"
                data["columns"] = "\(lines.first?.components(separatedBy: ",").count ?? 0)"
            }
        }
        
        // JSON-Erkennung
        if content.trimmingCharacters(in: .whitespaces).hasPrefix("{") {
            data["type"] = "json"
        }
        
        // URL-Erkennung
        if let url = URL(string: content.trimmingCharacters(in: .whitespaces)) {
            data["type"] = "url"
            data["domain"] = url.host ?? ""
        }
        
        return data
    }
    
    // Nutzer-Präferenzen für Paste-Verhalten
    func shouldAutoFormatContent(_ content: String) -> Bool {
        // Bestimmt, ob der Inhalt automatisch formatiert werden soll
        return content.count < 5000 && // Nicht zu groß
               !content.contains("http") && // Keine URLs
               !content.hasPrefix("#") // Keine Markdown-Header
    }
}