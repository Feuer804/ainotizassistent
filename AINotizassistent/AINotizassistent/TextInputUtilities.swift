import Foundation
import SwiftUI

// MARK: - Text Utilities Extension

extension String {
    /// Analysiert den Text und gibt Statistiken zurück
    func analyze() -> TextAnalysis {
        let words = components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let sentences = components(separatedBy: .punctuationCharacters)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        let paragraphs = components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        let charCount = count
        let wordCount = words.count
        let sentenceCount = sentences.count
        let paragraphCount = paragraphs.count
        let avgWordsPerSentence = sentenceCount > 0 ? Double(wordCount) / Double(sentenceCount) : 0
        
        return TextAnalysis(
            charCount: charCount,
            wordCount: wordCount,
            sentenceCount: sentenceCount,
            paragraphCount: paragraphCount,
            avgWordsPerSentence: avgWordsPerSentence,
            estimatedReadingTime: max(1, wordCount / 200)
        )
    }
    
    /// Konvertiert zu Markdown mit Auto-Formatierung
    func toFormattedMarkdown() -> String {
        var formatted = self
        
        // Füge Überschriften hinzu wo passend
        formatted = addHeaders(formatted)
        
        // Formatiere Listen
        formatted = formatMarkdownLists(formatted)
        
        // Füge Links zu URLs hinzu
        formatted = autoLinkURLs(formatted)
        
        // Formatiere Code-Blöcke
        formatted = formatCodeBlocks(formatted)
        
        return formatted
    }
    
    private func addHeaders(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Überschriften erkennen
            if trimmed.count < 50 && 
               trimmed.rangeOfCharacter(from: .lowercaseLetters) == nil &&
               trimmed.rangeOfCharacter(from: .uppercaseLetters) != nil {
                result.append("# \(trimmed)")
            } else {
                result.append(line)
            }
        }
        
        return result.joined(separator: "\n")
    }
    
    private func formatMarkdownLists(_ text: String) -> String {
        var formatted = text
        
        // Nummerierte Listen zu Markdown
        formatted = formatted.replacingOccurrences(
            of: #"^\d+\.\s+(.+)$"#,
            with: "- $1",
            options: .regularExpression
        )
        
        // Bullet Points formatieren
        formatted = formatted.replacingOccurrences(
            of: "^[•·]\s+(.+)$",
            with: "- $1",
            options: .regularExpression
        )
        
        return formatted
    }
    
    private func autoLinkURLs(_ text: String) -> String {
        let urlPattern = #"((https?://)?([-\w.])+[:0-9]*(/[-/_\w .\(\)]*)?(\?\S*)?)"#
        
        return text.replacingOccurrences(
            of: urlPattern,
            with: "[$1]($1)",
            options: .regularExpression
        )
    }
    
    private func formatCodeBlocks(_ text: String) -> String {
        var formatted = text
        
        // Erkennt Code-Zeilen (beginnend mit Tab oder 4 Leerzeichen)
        formatted = formatted.replacingOccurrences(
            of: #"^\s{4}(.+)$"#,
            with: "    $1",
            options: .regularExpression
        )
        
        return formatted
    }
}

// MARK: - Text Analysis Struct

struct TextAnalysis {
    let charCount: Int
    let wordCount: Int
    let sentenceCount: Int
    let paragraphCount: Int
    let avgWordsPerSentence: Double
    let estimatedReadingTime: Int
    
    var complexity: TextComplexity {
        switch avgWordsPerSentence {
        case 0..<10:
            return .simple
        case 10..<20:
            return .moderate
        case 20..<30:
            return .complex
        default:
            return .veryComplex
        }
    }
    
    var readabilityScore: Double {
        // Vereinfachte Berechnung der Lesbarkeit
        let avgSentenceLength = avgWordsPerSentence
        let avgSyllablesPerWord = estimateAvgSyllablesPerWord()
        
        // Flesch Reading Ease Score (vereinfacht)
        return 206.835 - (1.015 * avgSentenceLength) - (84.6 * avgSyllablesPerWord)
    }
    
    private func estimateAvgSyllablesPerWord() -> Double {
        // Schätzung: durchschnittlich 1.5 Silben pro Wort
        return 1.5
    }
}

enum TextComplexity {
    case simple
    case moderate
    case complex
    case veryComplex
    
    var description: String {
        switch self {
        case .simple:
            return "Einfach"
        case .moderate:
            return "Mittel"
        case .complex:
            return "Komplex"
        case .veryComplex:
            return "Sehr komplex"
        }
    }
}

// MARK: - Text Formatting Tools

struct TextFormatter {
    /// Formatiert Text mit verschiedenen Stilen
    static func applyStyle(_ text: String, style: TextStyle) -> String {
        switch style {
        case .bold:
            return "**\(text)**"
        case .italic:
            return "*\(text)*"
        case .underline:
            return "<u>\(text)</u>"
        case .strikethrough:
            return "~~\(text)~~"
        case .code:
            return "`\(text)`"
        case .codeBlock:
            return "```\n\(text)\n```"
        case .quote:
            return "> \(text)"
        case .heading(let level):
            return String(repeating: "#", count: level) + " \(text)"
        }
    }
    
    static func removeStyle(_ text: String) -> String {
        var unformatted = text
        
        // Entfernt Markdown-Formatierungen
        unformatted = unformatted.replacingOccurrences(of: "\\*\\*(.*?)\\*\\*", with: "$1", options: .regularExpression)
        unformatted = unformatted.replacingOccurrences(of: "\\*(.*?)\\*", with: "$1", options: .regularExpression)
        unformatted = unformatted.replacingOccurrences(of: "~~(.*?)~~", with: "$1", options: .regularExpression)
        unformatted = unformatted.replacingOccurrences(of: "`(.*?)`", with: "$1", options: .regularExpression)
        unformatted = unformatted.replacingOccurrences(of: "```[\\s\\S]*?```", with: "", options: .regularExpression)
        
        return unformatted
    }
}

enum TextStyle {
    case bold
    case italic
    case underline
    case strikethrough
    case code
    case codeBlock
    case quote
    case heading(Int)
}

// MARK: - Spell Check Integration

class SpellCheckManager: ObservableObject {
    @Published var hasSpellingErrors = false
    @Published var errorCount = 0
    
    private let spellChecker = NSSpellChecker.shared
    
    func checkSpelling(in text: String) -> [SpellingError] {
        let range = NSRange(location: 0, length: text.utf16.count)
        let mistakes = spellChecker.checkSpelling(in: text, startingAt: 0)
        
        var errors: [SpellingError] = []
        
        // Simulierte Fehlererkennung
        // In der echten Implementierung würde hier NSSpellChecker verwendet
        if text.contains("teh ") {
            errors.append(SpellingError(
                text: "teh",
                replacement: "the",
                range: NSRange(location: text.range(of: "teh ")?.lowerBound?.utf16Offset(in: text) ?? 0, length: 3)
            ))
        }
        
        DispatchQueue.main.async {
            self.hasSpellingErrors = !errors.isEmpty
            self.errorCount = errors.count
        }
        
        return errors
    }
    
    func correctWord(_ word: String) -> String {
        return spellChecker.correction(forWordType: .init(), language: "de", word: word) ?? word
    }
}

struct SpellingError {
    let text: String
    let replacement: String
    let range: NSRange
}

// MARK: - Auto-save Manager

class AutoSaveManager: ObservableObject {
    @Published var isEnabled = true
    @Published var lastSaved: Date?
    @Published var saveStatus: SaveStatus = .idle
    
    private var saveTimer: Timer?
    private let saveInterval: TimeInterval = 5.0
    
    enum SaveStatus {
        case idle
        case saving
        case saved
        case failed
    }
    
    func startAutoSave(for text: String, completion: @escaping (Bool) -> Void) {
        guard isEnabled else {
            completion(false)
            return
        }
        
        saveTimer?.invalidate()
        saveStatus = .saving
        
        // Simuliert Speichervorgang
        DispatchQueue.global(qos: .userInitiated).async {
            // Hier würde der eigentliche Speichervorgang stattfinden
            Thread.sleep(forTimeInterval: 0.3)
            
            DispatchQueue.main.async {
                self.saveStatus = .saved
                self.lastSaved = Date()
                completion(true)
                
                // Reset zu idle nach kurzer Zeit
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.saveStatus = .idle
                }
            }
        }
        
        // Plan nächsten Auto-save
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: false) { [weak self] _ in
            self?.startAutoSave(for: text, completion: completion)
        }
    }
    
    func stopAutoSave() {
        saveTimer?.invalidate()
        saveTimer = nil
    }
}