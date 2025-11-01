//
//  ContentType.swift
//  Intelligente Notizen App
//

import Foundation

// MARK: - Content Type Detection
enum ContentType: String, CaseIterable, Codable {
    case email = "E-Mail"
    case meeting = "Meeting"
    case article = "Artikel"
    case note = "Notiz"
    case task = "Aufgabe"
    case idea = "Idee"
    case code = "Code"
    case question = "Frage"
    case research = "Recherche"
    case personal = "Persönlich"
    
    var icon: String {
        switch self {
        case .email:
            return "📧"
        case .meeting:
            return "📅"
        case .article:
            return "📰"
        case .note:
            return "📝"
        case .task:
            return "✅"
        case .idea:
            return "💡"
        case .code:
            return "💻"
        case .question:
            return "❓"
        case .research:
            return "🔬"
        case .personal:
            return "👤"
        }
    }
    
    var color: String {
        switch self {
        case .email:
            return "#007AFF"
        case .meeting:
            return "#FF9500"
        case .article:
            return "#5856D6"
        case .note:
            return "#34C759"
        case .task:
            return "#FF3B30"
        case .idea:
            return "#AF52DE"
        case .code:
            return "#FF9500"
        case .question:
            return "#007AFF"
        case .research:
            return "#30D158"
        case .personal:
            return "#FF9F0A"
        }
    }
    
    var defaultTags: [String] {
        switch self {
        case .email:
            return ["kommunikation", "business"]
        case .meeting:
            return ["termin", "besprechung"]
        case .article:
            return ["news", "information"]
        case .note:
            return ["notiz", "allgemein"]
        case .task:
            return ["aufgabe", "todo"]
        case .idea:
            return ["idee", "kreativ"]
        case .code:
            return ["entwicklung", "programmierung"]
        case .question:
            return ["frage", "unknown"]
        case .research:
            return ["recherche", "analyse"]
        case .personal:
            return ["persönlich", "privat"]
        }
    }
}

// MARK: - Content Type Detector
final class ContentTypeDetector {
    
    // MARK: - Detection Patterns
    private struct DetectionPatterns {
        // E-Mail Patterns
        static let emailPatterns = [
            "von:", "an:", "betreff:", "gesendet:", "cc:", "bcc:",
            "@", "deine e-mail", "ihre e-mail", "antwort",
            "forward", "weiterleitung", "greeting", "gruss"
        ]
        
        // Meeting Patterns
        static let meetingPatterns = [
            "meeting", "termin", "besprechung", "konferenz",
            "zoom", "teams", "call", "anruf", "treffen",
            "datum:", "zeit:", "ort:", "agenda", "teilnehmer",
            "protokoll", "notizen", "beschluss", "entscheidung"
        ]
        
        // Article Patterns
        static let articlePatterns = [
            "artikel", "news", "nachricht", "bericht",
            "veröffentlicht", "quellen:", "autor:", "quelle:",
            "studie", "forschung", "analyse", "trend",
            "update", "aktualisierung", "erschienen"
        ]
        
        // Task Patterns
        static let taskPatterns = [
            "todo", "aufgabe", "erledigen", "nächster schritt",
            "deadline", "frist", "erforderlich", "muss",
            "erledigt", "complete", "abgeschlossen", "pending",
            "warten auf", "abhängig", "priorität"
        ]
        
        // Code Patterns
        static let codePatterns = [
            "```", "code:", "funktion", "methode", "class",
            "import", "var ", "let ", "func ", "def ",
            "javascript", "swift", "python", "java", "php",
            "bug", "fix", "feature", "commit", "repository"
        ]
        
        // Question Patterns
        static let questionPatterns = [
            "?", "wie", "was", "warum", "wo", "wann",
            "frage", "unknown", "weiss nicht", "hilfe",
            "unterstützung", "anleitung", "tutorial"
        ]
        
        // Research Patterns
        static let researchPatterns = [
            "studie", "forschung", "analyse", "untersuchung",
            "ergebnis", "daten", "methode", "hypothese",
            "konklusion", "theorie", "wissenschaft", "paper"
        ]
    }
    
    // MARK: - Content Analysis
    static func detectContentType(from text: String) -> ContentType {
        let normalizedText = text.lowercased()
        let scoreMap = createScoreMap(for: normalizedText)
        
        // Find content type with highest score
        let detectedType = scoreMap.max { $0.value < $1.value }
        
        // If no clear winner, return generic note
        guard let detectedType = detectedType, detectedType.value > 0 else {
            return .note
        }
        
        return detectedType.key
    }
    
    static func detectContentTypeConfidence(from text: String) -> (type: ContentType, confidence: Double) {
        let normalizedText = text.lowercased()
        let scoreMap = createScoreMap(for: normalizedText)
        
        // Find content type with highest score
        let detectedType = scoreMap.max { $0.value < $1.value }
        
        guard let detectedType = detectedType else {
            return (.note, 0.0)
        }
        
        // Calculate confidence based on highest score vs total score
        let totalScore = scoreMap.values.reduce(0, +)
        let confidence = totalScore > 0 ? Double(detectedType.value) / Double(totalScore) : 0.0
        
        return (detectedType.key, confidence)
    }
    
    private static func createScoreMap(for text: String) -> [ContentType: Int] {
        var scores = ContentType.allCases.reduce(into: [ContentType: Int]()) { $0[$1] = 0 }
        
        // Score each content type based on pattern matches
        ContentType.allCases.forEach { type in
            let patterns = getPatternsForType(type)
            patterns.forEach { pattern in
                let matches = countMatches(for: pattern, in: text)
                scores[type, default: 0] += matches
            }
        }
        
        return scores
    }
    
    private static func getPatternsForType(_ type: ContentType) -> [String] {
        switch type {
        case .email:
            return DetectionPatterns.emailPatterns
        case .meeting:
            return DetectionPatterns.meetingPatterns
        case .article:
            return DetectionPatterns.articlePatterns
        case .task:
            return DetectionPatterns.taskPatterns
        case .code:
            return DetectionPatterns.codePatterns
        case .question:
            return DetectionPatterns.questionPatterns
        case .research:
            return DetectionPatterns.researchPatterns
        case .note, .idea, .personal:
            return [] // These don't have specific patterns
        }
    }
    
    private static func countMatches(for pattern: String, in text: String) -> Int {
        return text.components(separatedBy: pattern).count - 1
    }
    
    // MARK: - Content Analysis Features
    static func extractMetadata(from text: String, type: ContentType) -> [String: AnyCodable] {
        var metadata: [String: AnyCodable] = [:]
        
        switch type {
        case .email:
            metadata.merge(extractEmailMetadata(from: text)) { current, _ in current }
            
        case .meeting:
            metadata.merge(extractMeetingMetadata(from: text)) { current, _ in current }
            
        case .article:
            metadata.merge(extractArticleMetadata(from: text)) { current, _ in current }
            
        case .task:
            metadata.merge(extractTaskMetadata(from: text)) { current, _ in current }
            
        case .code:
            metadata.merge(extractCodeMetadata(from: text)) { current, _ in current }
            
        default:
            break
        }
        
        return metadata
    }
    
    // MARK: - Specific Metadata Extractors
    private static func extractEmailMetadata(from text: String) -> [String: AnyCodable] {
        var metadata: [String: AnyCodable] = [:]
        let lines = text.components(separatedBy: .newlines)
        
        lines.forEach { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            if trimmedLine.hasPrefix("von:") {
                let sender = String(trimmedLine.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                metadata["sender"] = AnyCodable(sender)
            } else if trimmedLine.hasPrefix("an:") {
                let recipient = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                metadata["recipient"] = AnyCodable(recipient)
            } else if trimmedLine.hasPrefix("betreff:") {
                let subject = String(trimmedLine.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                metadata["subject"] = AnyCodable(subject)
            }
        }
        
        return metadata
    }
    
    private static func extractMeetingMetadata(from text: String) -> [String: AnyCodable] {
        var metadata: [String: AnyCodable] = [:]
        let lines = text.components(separatedBy: .newlines)
        
        lines.forEach { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            if trimmedLine.hasPrefix("datum:") || trimmedLine.hasPrefix("date:") {
                let dateString = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                metadata["meeting_date"] = AnyCodable(dateString)
            } else if trimmedLine.hasPrefix("zeit:") || trimmedLine.hasPrefix("time:") {
                let timeString = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                metadata["meeting_time"] = AnyCodable(timeString)
            } else if trimmedLine.hasPrefix("ort:") || trimmedLine.hasPrefix("location:") {
                let location = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                metadata["location"] = AnyCodable(location)
            }
        }
        
        return metadata
    }
    
    private static func extractArticleMetadata(from text: String) -> [String: AnyCodable] {
        var metadata: [String: AnyCodable] = [:]
        let lines = text.components(separatedBy: .newlines)
        
        lines.forEach { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            if trimmedLine.hasPrefix("autor:") || trimmedLine.hasPrefix("author:") {
                let author = String(trimmedLine.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                metadata["author"] = AnyCodable(author)
            } else if trimmedLine.hasPrefix("quelle:") || trimmedLine.hasPrefix("source:") {
                let source = String(trimmedLine.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                metadata["source"] = AnyCodable(source)
            } else if trimmedLine.hasPrefix("veröffentlicht:") || trimmedLine.hasPrefix("published:") {
                let publishedDate = String(trimmedLine.dropFirst(15)).trimmingCharacters(in: .whitespaces)
                metadata["published_date"] = AnyCodable(publishedDate)
            }
        }
        
        return metadata
    }
    
    private static func extractTaskMetadata(from text: String) -> [String: AnyCodable] {
        var metadata: [String: AnyCodable] = [:]
        
        // Detect priority indicators
        if text.lowercased().contains("hoch") || text.lowercased().contains("urgent") || text.lowercased().contains("wichtig") {
            metadata["priority_level"] = AnyCodable("high")
        } else if text.lowercased().contains("niedrig") || text.lowercased().contains("low") {
            metadata["priority_level"] = AnyCodable("low")
        }
        
        // Detect deadline patterns
        if text.lowercased().contains("deadline") || text.lowercased().contains("frist") {
            metadata["has_deadline"] = AnyCodable(true)
        }
        
        // Detect completion status
        if text.lowercased().contains("erledigt") || text.lowercased().contains("complete") || text.lowercased().contains("abgeschlossen") {
            metadata["completion_status"] = AnyCodable("completed")
        }
        
        return metadata
    }
    
    private static func extractCodeMetadata(from text: String) -> [String: AnyCodable] {
        var metadata: [String: AnyCodable] = [:]
        
        // Detect programming language
        let languages = ["swift", "javascript", "python", "java", "php", "kotlin", "typescript"]
        for language in languages {
            if text.lowercased().contains(language) {
                metadata["language"] = AnyCodable(language)
                break
            }
        }
        
        // Detect code blocks
        if text.contains("```") {
            metadata["has_code_block"] = AnyCodable(true)
        }
        
        // Detect functions/methods
        if text.lowercased().contains("func ") || text.lowercased().contains("function ") {
            metadata["has_functions"] = AnyCodable(true)
        }
        
        return metadata
    }
}

// MARK: - Content Analysis Results
struct ContentAnalysisResult {
    let detectedType: ContentType
    let confidence: Double
    let metadata: [String: AnyCodable]
    let suggestions: [String]
    
    static func analyze(_ text: String) -> ContentAnalysisResult {
        let (type, confidence) = ContentTypeDetector.detectContentTypeConfidence(from: text)
        let metadata = ContentTypeDetector.extractMetadata(from: text, type: type)
        let suggestions = generateSuggestions(for: type, with: text)
        
        return ContentAnalysisResult(
            detectedType: type,
            confidence: confidence,
            metadata: metadata,
            suggestions: suggestions
        )
    }
    
    private static func generateSuggestions(for type: ContentType, with text: String) -> [String] {
        var suggestions: [String] = []
        
        switch type {
        case .email:
            suggestions.append(contentsOf: [
                "E-Mail-Format verwenden",
                "Betreff hinzufügen",
                "Kontakte verlinken"
            ])
            
        case .meeting:
            suggestions.append(contentsOf: [
                "Datum und Uhrzeit hinzufügen",
                "Agenda erstellen",
                "Teilnehmer notieren"
            ])
            
        case .task:
            suggestions.append(contentsOf: [
                "Priorität setzen",
                "Deadline definieren",
                "Status verfolgen"
            ])
            
        case .article:
            suggestions.append(contentsOf: [
                "Quellenangabe hinzufügen",
                "Zusammenfassung erstellen",
                "Tags für Kategorisierung"
            ])
            
        default:
            break
        }
        
        return suggestions
    }
}