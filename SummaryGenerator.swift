//
//  SummaryGenerator.swift
//  Intelligente Notizen App - Erweiterte Zusammenfassungs-Generation
//

import Foundation
import NaturalLanguage
import Combine
import SwiftUI

// MARK: - Main Summary Generator
class SummaryGenerator: ObservableObject {
    @Published var isGenerating: Bool = false
    @Published var generationProgress: Double = 0.0
    @Published var currentGenerationStep: String = ""
    @Published var currentSummary: GeneratedSummary?
    
    private let contentAnalyzer: ContentAnalyzer
    private let languageDetector = LanguageDetector()
    private let extractiveSummarizer = ExtractiveSummarizer()
    private let abstractiveSummarizer = AbstractiveSummarizer()
    private let bulletPointGenerator = BulletPointGenerator()
    private let keyPhraseExtractor = KeyPhraseExtractor()
    private let confidenceScorer = SummaryConfidenceScorer()
    private let lengthController = SummaryLengthController()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(contentAnalyzer: ContentAnalyzer) {
        self.contentAnalyzer = contentAnalyzer
    }
    
    // MARK: - Main Generation Methods
    func generateSummary(
        from text: String,
        format: SummaryFormat,
        contentType: ContentType? = nil,
        options: SummaryOptions = SummaryOptions(),
        completion: @escaping (GeneratedSummary) -> Void
    ) {
        DispatchQueue.main.async {
            self.isGenerating = true
            self.generationProgress = 0.0
        }
        
        let totalSteps = self.calculateSteps(for: format)
        var currentStep = 0.0
        
        // Step 1: Content Analysis
        currentGenerationStep = "Content wird analysiert..."
        contentAnalyzer.analyzeContent(text) { [weak self] analysis in
            currentStep += 1
            self?.updateProgress(currentStep, totalSteps)
            
            let detectedContentType = contentType ?? analysis.contentType
            let detectedLanguage = analysis.language
            
            // Step 2: Language-Specific Processing
            self?.currentGenerationStep = "Sprachspezifische Verarbeitung..."
            self?.processForLanguage(text: text, language: detectedLanguage, analysis: analysis) { processedText in
                currentStep += 1
                self?.updateProgress(currentStep, totalSteps)
                
                // Step 3: Extractive Summarization
                self?.currentGenerationStep = "Extrakte werden extrahiert..."
                self?.extractiveSummarizer.extract(
                    text: processedText,
                    analysis: analysis,
                    format: format,
                    options: options
                ) { extractiveResult in
                    currentStep += 1
                    self?.updateProgress(currentStep, totalSteps)
                    
                    // Step 4: Abstractive Summarization
                    self?.currentGenerationStep = "Abstrakte Zusammenfassung wird erstellt..."
                    self?.abstractiveSummarizer.generate(
                        text: processedText,
                        extractiveBasis: extractiveResult,
                        analysis: analysis,
                        format: format,
                        options: options
                    ) { abstractiveResult in
                        currentStep += 1
                        self?.updateProgress(currentStep, totalSteps)
                        
                        // Step 5: Content-Type Specific Processing
                        self?.currentGenerationStep = "Content-typ-spezifische Verarbeitung..."
                        self?.processForContentType(
                            text: processedText,
                            contentType: detectedContentType,
                            analysis: analysis,
                            format: format,
                            extractiveResult: extractiveResult,
                            abstractiveResult: abstractiveResult
                        ) { typedResult in
                            currentStep += 1
                            self?.updateProgress(currentStep, totalSteps)
                            
                            // Step 6: Bullet Point Generation
                            self?.currentGenerationStep = "Bullet Points werden generiert..."
                            self?.bulletPointGenerator.generate(
                                from: typedResult,
                                contentType: detectedContentType,
                                analysis: analysis,
                                format: format,
                                options: options
                            ) { bulletPoints in
                                currentStep += 1
                                self?.updateProgress(currentStep, totalSteps)
                                
                                // Step 7: Key Phrase Extraction
                                self?.currentGenerationStep = "Schlüsselphrasen werden extrahiert..."
                                self?.keyPhraseExtractor.extract(
                                    from: typedResult,
                                    analysis: analysis,
                                    language: detectedLanguage
                                ) { keyPhrases in
                                    currentStep += 1
                                    self?.updateProgress(currentStep, totalSteps)
                                    
                                    // Step 8: Confidence Scoring
                                    self?.currentGenerationStep = "Qualität wird bewertet..."
                                    self?.confidenceScorer.score(
                                        originalText: text,
                                        summary: typedResult,
                                        analysis: analysis,
                                        keyPhrases: keyPhrases,
                                        format: format
                                    ) { confidence in
                                        currentStep += 1
                                        self?.updateProgress(currentStep, totalSteps)
                                        
                                        // Step 9: Length Control
                                        self?.currentGenerationStep = "Länge wird angepasst..."
                                        self?.lengthController.adjust(
                                            summary: typedResult,
                                            targetLength: format.defaultLength,
                                            language: detectedLanguage,
                                            format: format
                                        ) { adjustedSummary in
                                            currentStep += 1
                                            self?.updateProgress(currentStep, totalSteps)
                                            
                                            // Final Summary Assembly
                                            let finalSummary = GeneratedSummary(
                                                originalText: text,
                                                contentType: detectedContentType,
                                                format: format,
                                                language: detectedLanguage,
                                                extractiveSummary: extractiveResult.summary,
                                                abstractiveSummary: abstractiveResult.summary,
                                                combinedSummary: adjustedSummary,
                                                bulletPoints: bulletPoints,
                                                keyPhrases: keyPhrases,
                                                highlights: self?.generateHighlights(from: keyPhrases, analysis: analysis) ?? [],
                                                confidence: confidence,
                                                metadata: self?.generateMetadata(analysis: analysis, format: format) ?? [:],
                                                processingTime: Date().timeIntervalSince(Date()),
                                                wordCount: self?.countWords(in: adjustedSummary) ?? 0,
                                                readingTime: self?.calculateReadingTime(for: adjustedSummary, language: detectedLanguage) ?? 0
                                            )
                                            
                                            DispatchQueue.main.async {
                                                self?.isGenerating = false
                                                self?.generationProgress = 1.0
                                                self?.currentSummary = finalSummary
                                            }
                                            
                                            completion(finalSummary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Content-Type Specific Processing
    private func processForContentType(
        text: String,
        contentType: ContentType,
        analysis: ExtendedAnalysisResult,
        format: SummaryFormat,
        extractiveResult: ExtractiveSummaryResult,
        abstractiveResult: AbstractiveSummaryResult,
        completion: @escaping (String) -> Void
    ) {
        switch contentType {
        case .email:
            processEmailSummary(text: text, analysis: analysis, format: format, completion: completion)
        case .meeting:
            processMeetingSummary(text: text, analysis: analysis, format: format, completion: completion)
        case .article:
            processArticleSummary(text: text, analysis: analysis, format: format, completion: completion)
        default:
            // Generic processing for other content types
            completion(abstractiveResult.summary)
        }
    }
    
    private func processEmailSummary(
        text: String,
        analysis: ExtendedAnalysisResult,
        format: SummaryFormat,
        completion: @escaping (String) -> Void
    ) {
        let senderInfo = extractSenderInfo(from: text)
        let actionItems = extractActionItems(from: text, analysis: analysis)
        let keyPoints = extractKeyPoints(from: text, analysis: analysis, maxPoints: format.bulletPointCount)
        
        let emailSummary: String
        switch format {
        case .short:
            emailSummary = """
            \(keyPoints.first ?? "Keine Hauptpunkte gefunden")
            
            Von: \(senderInfo)
            \(actionItems.isEmpty ? "" : "\nAktionen: \(actionItems.joined(separator: ", "))")
            """
        case .medium:
            emailSummary = """
            \(keyPoints.joined(separator: "\n• "))
            
            Absender: \(senderInfo)
            \(actionItems.isEmpty ? "" : "Aktionen:\n\(actionItems.map { "• \($0)" }.joined(separator: "\n"))")
            """
        case .detailed:
            let detailedPoints = extractDetailedEmailPoints(from: text, analysis: analysis)
            emailSummary = """
            \(detailedPoints.joined(separator: "\n\n"))
            
            Metadaten:
            • Absender: \(senderInfo)
            • Sentiment: \(analysis.sentiment.polarity.rawValue)
            • Dringlichkeit: \(analysis.urgency.level)
            \(actionItems.isEmpty ? "" : "\nAktionen:\n\(actionItems.map { "• \($0)" }.joined(separator: "\n"))")
            """
        }
        
        completion(emailSummary)
    }
    
    private func processMeetingSummary(
        text: String,
        analysis: ExtendedAnalysisResult,
        format: SummaryFormat,
        completion: @escaping (String) -> Void
    ) {
        let decisions = extractDecisions(from: text, analysis: analysis)
        let actionItems = extractMeetingActionItems(from: text, analysis: analysis)
        let nextSteps = extractNextSteps(from: text, analysis: analysis)
        let participants = extractParticipants(from: text, analysis: analysis)
        
        let meetingSummary: String
        switch format {
        case .short:
            meetingSummary = """
            \(decisions.first ?? "Keine Entscheidungen gefunden")
            \(actionItems.isEmpty ? "" : "\nAktionen: \(actionItems.joined(separator: ", "))")
            """
        case .medium:
            meetingSummary = """
            Entscheidungen:
            \(decisions.map { "• \($0)" }.joined(separator: "\n"))
            
            \(nextSteps.isEmpty ? "" : "Nächste Schritte:\n\(nextSteps.map { "• \($0)" }.joined(separator: "\n"))")
            
            Teilnehmer: \(participants.joined(separator: ", "))
            """
        case .detailed:
            let detailedMeetingPoints = extractDetailedMeetingPoints(from: text, analysis: analysis)
            meetingSummary = """
            \(detailedMeetingPoints.joined(separator: "\n\n"))
            
            Zusammenfassung:
            • Entscheidungen: \(decisions.joined(separator: "; "))
            \(nextSteps.isEmpty ? "" : "• Nächste Schritte: \(nextSteps.joined(separator: "; "))")
            \(actionItems.isEmpty ? "" : "• Aktionen: \(actionItems.joined(separator: "; "))")
            • Teilnehmer: \(participants.joined(separator: ", "))
            """
        }
        
        completion(meetingSummary)
    }
    
    private func processArticleSummary(
        text: String,
        analysis: ExtendedAnalysisResult,
        format: SummaryFormat,
        completion: @escaping (String) -> Void
    ) {
        let mainTopics = extractMainTopics(from: text, analysis: analysis, maxTopics: format.topicCount)
        let keyInsights = extractKeyInsights(from: text, analysis: analysis)
        let relatedThemes = extractRelatedThemes(from: text, analysis: analysis)
        
        let articleSummary: String
        switch format {
        case .short:
            articleSummary = """
            \(mainTopics.first ?? "Keine Hauptthemen gefunden")
            \(keyInsights.isEmpty ? "" : "\nEinsicht: \(keyInsights.first ?? "")")
            """
        case .medium:
            articleSummary = """
            \(mainTopics.joined(separator: " • "))
            
            \(keyInsights.joined(separator: "\n• "))
            """
        case .detailed:
            let detailedArticlePoints = extractDetailedArticlePoints(from: text, analysis: analysis)
            articleSummary = """
            \(detailedArticlePoints.joined(separator: "\n\n"))
            
            \(mainTopics.joined(separator: "\n• Hauptthema: "))
            
            \(relatedThemes.isEmpty ? "" : "Verwandte Themen:\n\(relatedThemes.map { "• \($0)" }.joined(separator: "\n"))")
            """
        }
        
        completion(articleSummary)
    }
    
    // MARK: - Language-Specific Processing
    private func processForLanguage(
        text: String,
        language: DetectedLanguage,
        analysis: ExtendedAnalysisResult,
        completion: @escaping (String) -> Void
    ) {
        // Apply language-specific processing rules
        var processedText = text
        
        if language.isGerman {
            // German-specific processing
            processedText = processedText.replacingOccurrences(of: "\\b(\\w+)\\s+und\\s+(\\w+)\\b", with: "$1 sowie $2", options: .regularExpression)
        } else if language.isEnglish {
            // English-specific processing
            processedText = processedText.replacingOccurrences(of: "\\band\\b", with: "and", options: .caseInsensitive)
        }
        
        completion(processedText)
    }
    
    // MARK: - Helper Methods
    private func calculateSteps(for format: SummaryFormat) -> Double {
        return 9.0 // Fixed number of processing steps
    }
    
    private func updateProgress(_ current: Double, _ total: Double) {
        DispatchQueue.main.async {
            self.generationProgress = current / total
        }
    }
    
    private func extractSenderInfo(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.hasPrefix("von:") || trimmed.hasPrefix("from:") {
                return String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            }
        }
        return "Unbekannt"
    }
    
    private func extractActionItems(from text: String, analysis: ExtendedAnalysisResult) -> [String] {
        var actionItems: [String] = []
        
        // Extract action items based on keywords and analysis
        let actionKeywords = ["erforderlich", "muss", "soll", "bitte", "action", "task", "erledigen"]
        let sentences = text.components(separatedBy: .punctuationCharacters)
        
        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if actionKeywords.contains(where: { trimmedSentence.lowercased().contains($0) }) {
                actionItems.append(trimmedSentence)
            }
        }
        
        return Array(actionItems.prefix(5)) // Limit to 5 action items
    }
    
    private func extractKeyPoints(from text: String, analysis: ExtendedAnalysisResult, maxPoints: Int) -> [String] {
        return analysis.keywords.prefix(maxPoints).map { $0.term }
    }
    
    private func extractDetailedEmailPoints(from text: String, analysis: ExtendedAnalysisResult) -> [String] {
        return [
            "Hauptinhalt: \(extractMainContent(from: text))",
            "Tonalität: \(analysis.sentiment.polarity.rawValue)",
            "Komplexität: \(analysis.overallQualityScore > 0.7 ? "Hoch" : "Niedrig")"
        ]
    }
    
    private func extractDecisions(from text: String, analysis: ExtendedAnalysisResult) -> [String] {
        let decisionKeywords = ["entschieden", "beschlossen", "entscheidung", "decision", "approved", "vereinbart"]
        let sentences = text.components(separatedBy: .punctuationCharacters)
        
        return sentences.compactMap { sentence in
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            return decisionKeywords.contains(where: { trimmed.lowercased().contains($0) }) ? trimmed : nil
        }
    }
    
    private func extractMeetingActionItems(from text: String, analysis: ExtendedAnalysisResult) -> [String] {
        return extractActionItems(from: text, analysis: analysis)
    }
    
    private func extractNextSteps(from text: String, analysis: ExtendedAnalysisResult) -> [String] {
        let nextStepKeywords = ["nächste schritte", "next steps", "follow-up", "weitere aktionen"]
        let sentences = text.components(separatedBy: .punctuationCharacters)
        
        return sentences.compactMap { sentence in
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            return nextStepKeywords.contains(where: { trimmed.lowercased().contains($0) }) ? trimmed : nil
        }
    }
    
    private func extractParticipants(from text: String, analysis: ExtendedAnalysisResult) -> [String] {
        return analysis.keywords
            .filter { $0.category == .person }
            .map { $0.term }
            .prefix(10)
            .map { $0 }
    }
    
    private func extractDetailedMeetingPoints(from text: String, analysis: ExtendedAnalysisResult) -> [String] {
        return [
            "Zusammenfassung: \(extractMainContent(from: text))",
            "Struktur: \(analysis.structure.hasHeaders ? "Strukturiert" : "Fließtext")",
            "Qualität: \(Int(analysis.overallQualityScore * 100))%"
        ]
    }
    
    private func extractMainTopics(from text: String, analysis: ExtendedAnalysisResult, maxTopics: Int) -> [String] {
        return analysis.topics.prefix(maxTopics).map { $0.name }
    }
    
    private func extractKeyInsights(from text: String, analysis: ExtendedAnalysisResult) -> [String] {
        // Extract insights based on high-confidence keywords and sentiment
        return analysis.keywords
            .filter { $0.relevance > 0.7 }
            .map { "Einsicht: \($0.term)" }
            .prefix(5)
            .map { $0 }
    }
    
    private func extractRelatedThemes(from text: String, analysis: ExtendedAnalysisResult) -> [String] {
        return analysis.topics
            .filter { $0.confidence > 0.5 }
            .map { $0.name }
            .suffix(5)
            .map { $0 }
    }
    
    private func extractDetailedArticlePoints(from text: String, analysis: ExtendedAnalysisResult) -> [String] {
        return [
            "Hauptthese: \(extractMainContent(from: text))",
            "Quellen: \(analysis.keywords.filter { $0.category == .organization }.count)",
            "Technische Begriffe: \(analysis.keywords.filter { $0.category == .technical }.count)"
        ]
    }
    
    private func extractMainContent(from text: String) -> String {
        // Simple extraction of first meaningful sentence
        let sentences = text.components(separatedBy: .punctuationCharacters)
        return sentences.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Inhalt nicht verfügbar"
    }
    
    private func generateHighlights(from keyPhrases: [KeyPhrase], analysis: ExtendedAnalysisResult) -> [SummaryHighlight] {
        return keyPhrases.prefix(10).map { phrase in
            SummaryHighlight(
                text: phrase.phrase,
                confidence: phrase.confidence,
                category: phrase.category,
                relevance: phrase.relevance
            )
        }
    }
    
    private func generateMetadata(analysis: ExtendedAnalysisResult, format: SummaryFormat) -> [String: AnyCodable] {
        return [
            "analysis_confidence": AnyCodable(analysis.confidence),
            "sentiment_polarity": AnyCodable(analysis.sentiment.polarity.rawValue),
            "urgency_level": AnyCodable(analysis.urgency.level.rawValue),
            "format_type": AnyCodable(format.rawValue),
            "quality_score": AnyCodable(analysis.overallQualityScore),
            "topics_count": AnyCodable(analysis.topics.count),
            "keywords_count": AnyCodable(analysis.keywords.count)
        ]
    }
    
    private func countWords(in text: String) -> Int {
        return text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    private func calculateReadingTime(for text: String, language: DetectedLanguage) -> TimeInterval {
        let wordCount = Double(countWords(in: text))
        let wordsPerMinute: Double = language.isGerman ? 180.0 : 200.0 // Germans read slightly slower
        return (wordCount / wordsPerMinute) * 60 // Return seconds
    }
    
    // MARK: - Batch Generation
    func generateBatchSummaries(
        texts: [(text: String, contentType: ContentType?)],
        format: SummaryFormat,
        options: SummaryOptions = SummaryOptions(),
        completion: @escaping ([GeneratedSummary]) -> Void
    ) {
        var results: [GeneratedSummary] = []
        let dispatchGroup = DispatchGroup()
        
        texts.forEach { textData in
            dispatchGroup.enter()
            generateSummary(
                from: textData.text,
                format: format,
                contentType: textData.contentType,
                options: options
            ) { summary in
                results.append(summary)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(results)
        }
    }
    
    // MARK: - Real-time Generation
    func generateRealtimeSummary(
        text: String,
        publisher: PassthroughSubject<String, Never>
    ) {
        publisher
            .debounce(for: .milliseconds(1000), scheduler: DispatchQueue.main)
            .sink { [weak self] updatedText in
                if updatedText.count > 50 { // Minimum text length for summary
                    self?.generateSummary(
                        from: updatedText,
                        format: .short,
                        options: SummaryOptions()
                    ) { summary in
                        NotificationCenter.default.post(
                            name: .realtimeSummaryUpdate,
                            object: summary
                        )
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Data Types
enum SummaryFormat: String, CaseIterable {
    case short = "Kurz"
    case medium = "Mittel"
    case detailed = "Ausführlich"
    
    var description: String {
        switch self {
        case .short: return "Kurze Zusammenfassung (1-2 Sätze)"
        case .medium: return "Mittlere Zusammenfassung (3-5 Punkte)"
        case .detailed: return "Ausführliche Zusammenfassung (komplette Übersicht)"
        }
    }
    
    var defaultLength: SummaryLength {
        switch self {
        case .short: return SummaryLength(wordCount: 25...50)
        case .medium: return SummaryLength(wordCount: 75...150)
        case .detailed: return SummaryLength(wordCount: 200...400)
        }
    }
    
    var bulletPointCount: Int {
        switch self {
        case .short: return 3
        case .medium: return 5
        case .detailed: return 10
        }
    }
    
    var topicCount: Int {
        switch self {
        case .short: return 2
        case .medium: return 4
        case .detailed: return 8
        }
    }
}

struct SummaryOptions {
    var includeHighlights: Bool = true
    var includeMetadata: Bool = true
    var includeConfidence: Bool = true
    var prioritizeActionItems: Bool = false
    var includeRelatedThemes: Bool = true
    var languageSpecific: Bool = true
    var maxHighlights: Int = 10
    var customWordLimit: Int?
}

struct SummaryLength {
    let wordCount: ClosedRange<Int>
    let paragraphCount: Int
    let bulletPointCount: Int?
    
    init(wordCount: ClosedRange<Int>, paragraphCount: Int = 1, bulletPointCount: Int? = nil) {
        self.wordCount = wordCount
        self.paragraphCount = paragraphCount
        self.bulletPointCount = bulletPointCount
    }
}

// MARK: - Generated Summary Result
struct GeneratedSummary {
    let originalText: String
    let contentType: ContentType
    let format: SummaryFormat
    let language: DetectedLanguage
    let extractiveSummary: String
    let abstractiveSummary: String
    let combinedSummary: String
    let bulletPoints: [BulletPoint]
    let keyPhrases: [KeyPhrase]
    let highlights: [SummaryHighlight]
    let confidence: SummaryConfidence
    let metadata: [String: AnyCodable]
    let processingTime: TimeInterval
    let wordCount: Int
    let readingTime: TimeInterval
    
    // Computed properties
    var summaryText: String {
        return combinedSummary.isEmpty ? abstractiveSummary : combinedSummary
    }
    
    var isHighQuality: Bool {
        return confidence.overallScore > 0.7
    }
    
    var qualityLevel: String {
        let score = confidence.overallScore
        switch score {
        case 0.8...1.0: return "Exzellent"
        case 0.6..<0.8: return "Gut"
        case 0.4..<0.6: return "Befriedigend"
        case 0.2..<0.4: return "Verbesserungsbedürftig"
        default: return "Niedrig"
        }
    }
}

struct BulletPoint {
    let text: String
    let priority: Priority
    let category: String
    let confidence: Double
    let actionRequired: Bool
    
    enum Priority {
        case low, medium, high, critical
    }
}

struct KeyPhrase {
    let phrase: String
    let confidence: Double
    let relevance: Double
    let category: KeyPhraseCategory
    let positions: [Int]
    
    enum KeyPhraseCategory {
        case topic, action, entity, concept, technical, emotional
    }
}

struct SummaryHighlight {
    let text: String
    let confidence: Double
    let category: String
    let relevance: Double
}

struct SummaryConfidence {
    let overallScore: Double
    let coherenceScore: Double
    let completenessScore: Double
    let accuracyScore: Double
    let languageQualityScore: Double
    let improvements: [QualityImprovement]
}

struct QualityImprovement {
    let category: String
    let suggestion: String
    let impact: Double
}

// MARK: - Summarization Processors
class ExtractiveSummarizer {
    func extract(
        text: String,
        analysis: ExtendedAnalysisResult,
        format: SummaryFormat,
        options: SummaryOptions,
        completion: @escaping (ExtractiveSummaryResult) -> Void
    ) {
        // Implement extractive summarization logic
        let keySentences = extractKeySentences(from: text, analysis: analysis, format: format)
        let summary = keySentences.joined(separator: " ")
        
        completion(ExtractiveSummaryResult(
            summary: summary,
            keySentences: keySentences,
            extractedKeywords: analysis.keywords.map { $0.term },
            coverage: calculateCoverage(original: text, extracted: summary)
        ))
    }
    
    private func extractKeySentences(from text: String, analysis: ExtendedAnalysisResult, format: SummaryFormat) -> [String] {
        let sentences = text.components(separatedBy: .punctuationCharacters)
        let sentenceCount = getSentenceCount(for: format)
        
        return sentences
            .map { ($0.trimmingCharacters(in: .whitespacesAndNewlines), calculateSentenceScore($0, analysis)) }
            .sorted { $0.1 > $1.1 }
            .prefix(sentenceCount)
            .map { $0.0 }
    }
    
    private func getSentenceCount(for format: SummaryFormat) -> Int {
        switch format {
        case .short: return 2
        case .medium: return 4
        case .detailed: return 8
        }
    }
    
    private func calculateSentenceScore(_ sentence: String, _ analysis: ExtendedAnalysisResult) -> Double {
        var score = 0.0
        
        // Score based on keyword presence
        for keyword in analysis.keywords {
            if sentence.lowercased().contains(keyword.term.lowercased()) {
                score += keyword.relevance * 0.3
            }
        }
        
        // Score based on position (first and last sentences often important)
        let isFirst = sentence == analysis.originalText.components(separatedBy: .punctuationCharacters).first
        let isLast = sentence == analysis.originalText.components(separatedBy: .punctuationCharacters).last
        
        if isFirst || isLast {
            score += 0.2
        }
        
        // Score based on sentiment relevance
        if sentence.lowercased().contains("wichtig") || sentence.lowercased().contains("entscheidung") {
            score += 0.3
        }
        
        return score
    }
    
    private func calculateCoverage(original: String, extracted: String) -> Double {
        // Simple coverage calculation based on word overlap
        let originalWords = Set(original.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let extractedWords = Set(extracted.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let overlap = originalWords.intersection(extractedWords)
        
        return Double(overlap.count) / Double(originalWords.count)
    }
}

struct ExtractiveSummaryResult {
    let summary: String
    let keySentences: [String]
    let extractedKeywords: [String]
    let coverage: Double
}

class AbstractiveSummarizer {
    func generate(
        text: String,
        extractiveBasis: ExtractiveSummaryResult,
        analysis: ExtendedAnalysisResult,
        format: SummaryFormat,
        options: SummaryOptions,
        completion: @escaping (AbstractiveSummaryResult) -> Void
    ) {
        // Implement abstractive summarization logic using LLM or template-based approach
        let abstractiveText = generateAbstractiveText(
            text: text,
            extractiveBasis: extractiveBasis,
            analysis: analysis,
            format: format
        )
        
        completion(AbstractiveSummaryResult(
            summary: abstractiveText,
            style: determineStyle(analysis: analysis),
            coherence: calculateCoherence(text: abstractiveText)
        ))
    }
    
    private func generateAbstractiveText(
        text: String,
        extractiveBasis: ExtractiveSummaryResult,
        analysis: ExtendedAnalysisResult,
        format: SummaryFormat
    ) -> String {
        // Template-based approach for abstractive summarization
        switch format {
        case .short:
            return generateShortSummary(text: text, analysis: analysis)
        case .medium:
            return generateMediumSummary(text: text, analysis: analysis)
        case .detailed:
            return generateDetailedSummary(text: text, analysis: analysis)
        }
    }
    
    private func generateShortSummary(text: String, analysis: ExtendedAnalysisResult) -> String {
        let mainTopic = analysis.topics.first?.name ?? "Hauptthema"
        let sentiment = analysis.sentiment.polarity.rawValue
        return "Der Text behandelt hauptsächlich \(mainTopic) mit \(sentiment)em Ton."
    }
    
    private func generateMediumSummary(text: String, analysis: ExtendedAnalysisResult) -> String {
        let topics = analysis.topics.map { $0.name }.prefix(3).joined(separator: ", ")
        let keyPoints = analysis.keywords.prefix(3).map { $0.term }.joined(separator: ", ")
        return "Der Text umfasst folgende Themen: \(topics). Wichtige Begriffe: \(keyPoints)."
    }
    
    private func generateDetailedSummary(text: String, analysis: ExtendedAnalysisResult) -> String {
        let comprehensiveOverview = """
        Diese ausführliche Analyse behandelt \(analysis.topics.count) Hauptthemen mit \(analysis.keywords.count) relevanten Begriffen. 
        Die Tonalität ist \(analysis.sentiment.polarity.rawValue) mit einer Qualitätsbewertung von \(Int(analysis.overallQualityScore * 100))%. 
        Die Struktur zeigt \(analysis.structure.hasHeaders ? "klare Struktur" : "fließende Darstellung").
        """
        return comprehensiveOverview
    }
    
    private func determineStyle(analysis: ExtendedAnalysisResult) -> String {
        if analysis.sentiment.polarity == .veryPositive || analysis.sentiment.polarity == .positive {
            return "Optimistisch"
        } else if analysis.sentiment.polarity == .negative || analysis.sentiment.polarity == .veryNegative {
            return "Kritisch"
        }
        return "Neutral"
    }
    
    private func calculateCoherence(text: String) -> Double {
        // Simple coherence calculation based on sentence transitions
        let sentences = text.components(separatedBy: .punctuationCharacters)
        guard sentences.count > 1 else { return 1.0 }
        
        var coherenceScore = 0.0
        for i in 0..<(sentences.count - 1) {
            let currentWords = Set(sentences[i].lowercased().components(separatedBy: .whitespacesAndNewlines))
            let nextWords = Set(sentences[i + 1].lowercased().components(separatedBy: .whitespacesAndNewlines))
            let overlap = currentWords.intersection(nextWords)
            
            if !overlap.isEmpty {
                coherenceScore += 1.0
            }
        }
        
        return coherenceScore / Double(sentences.count - 1)
    }
}

struct AbstractiveSummaryResult {
    let summary: String
    let style: String
    let coherence: Double
}

class BulletPointGenerator {
    func generate(
        from summary: String,
        contentType: ContentType,
        analysis: ExtendedAnalysisResult,
        format: SummaryFormat,
        options: SummaryOptions,
        completion: @escaping ([BulletPoint]) -> Void
    ) {
        var bulletPoints: [BulletPoint] = []
        
        // Generate bullet points based on content type
        switch contentType {
        case .email:
            bulletPoints = generateEmailBulletPoints(summary: summary, analysis: analysis, format: format)
        case .meeting:
            bulletPoints = generateMeetingBulletPoints(summary: summary, analysis: analysis, format: format)
        case .article:
            bulletPoints = generateArticleBulletPoints(summary: summary, analysis: analysis, format: format)
        default:
            bulletPoints = generateGenericBulletPoints(summary: summary, analysis: analysis, format: format)
        }
        
        // Sort by priority and limit count
        let sortedPoints = bulletPoints
            .sorted { bulletPointPriority($0) > bulletPointPriority($1) }
            .prefix(format.bulletPointCount)
            .map { $0 }
        
        completion(Array(sortedPoints))
    }
    
    private func generateEmailBulletPoints(summary: String, analysis: ExtendedAnalysisResult, format: SummaryFormat) -> [BulletPoint] {
        var points: [BulletPoint] = []
        
        // Add key points
        if let mainPoint = analysis.keywords.first {
            points.append(BulletPoint(
                text: "Hauptpunkt: \(mainPoint.term)",
                priority: .high,
                category: "Inhalt",
                confidence: mainPoint.relevance,
                actionRequired: false
            ))
        }
        
        // Add action items
        let actionItems = extractActionItemsFromSummary(summary: summary)
        for item in actionItems.prefix(3) {
            points.append(BulletPoint(
                text: item,
                priority: .medium,
                category: "Aktion",
                confidence: 0.8,
                actionRequired: true
            ))
        }
        
        // Add urgency indicator
        if analysis.urgency.level == .high || analysis.urgency.level == .critical {
            points.append(BulletPoint(
                text: "Hoch priorisiert",
                priority: .critical,
                category: "Priorität",
                confidence: 0.9,
                actionRequired: true
            ))
        }
        
        return points
    }
    
    private func generateMeetingBulletPoints(summary: String, analysis: ExtendedAnalysisResult, format: SummaryFormat) -> [BulletPoint] {
        var points: [BulletPoint] = []
        
        // Add decisions
        points.append(BulletPoint(
            text: "Entscheidungen getroffen",
            priority: .high,
            category: "Ergebnis",
            confidence: 0.8,
            actionRequired: false
        ))
        
        // Add next steps
        points.append(BulletPoint(
            text: "Nächste Schritte definiert",
            priority: .medium,
            category: "Planung",
            confidence: 0.7,
            actionRequired: true
        ))
        
        // Add participant info
        let participantCount = analysis.keywords.filter { $0.category == .person }.count
        points.append(BulletPoint(
            text: "\(participantCount) Teilnehmer",
            priority: .low,
            category: "Information",
            confidence: 0.9,
            actionRequired: false
        ))
        
        return points
    }
    
    private func generateArticleBulletPoints(summary: String, analysis: ExtendedAnalysisResult, format: SummaryFormat) -> [BulletPoint] {
        var points: [BulletPoint] = []
        
        // Add main topics
        for topic in analysis.topics.prefix(3) {
            points.append(BulletPoint(
                text: "Thema: \(topic.name)",
                priority: topic.confidence > 0.7 ? .high : .medium,
                category: "Inhalt",
                confidence: topic.confidence,
                actionRequired: false
            ))
        }
        
        return points
    }
    
    private func generateGenericBulletPoints(summary: String, analysis: ExtendedAnalysisResult, format: SummaryFormat) -> [BulletPoint] {
        var points: [BulletPoint] = []
        
        // Add key insights
        for keyword in analysis.keywords.prefix(format.bulletPointCount) {
            points.append(BulletPoint(
                text: keyword.term,
                priority: .medium,
                category: "Schlüsselbegriff",
                confidence: keyword.relevance,
                actionRequired: false
            ))
        }
        
        return points
    }
    
    private func extractActionItemsFromSummary(summary: String) -> [String] {
        let actionPatterns = ["erforderlich", "muss", "sollte", "bitte", "action"]
        var actionItems: [String] = []
        
        let sentences = summary.components(separatedBy: .punctuationCharacters)
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if actionPatterns.contains(where: { trimmed.lowercased().contains($0) }) {
                actionItems.append(trimmed)
            }
        }
        
        return actionItems
    }
    
    private func bulletPointPriority(_ point: BulletPoint) -> Double {
        switch point.priority {
        case .critical: return 4.0
        case .high: return 3.0
        case .medium: return 2.0
        case .low: return 1.0
        }
    }
}

class KeyPhraseExtractor {
    func extract(
        from summary: String,
        analysis: ExtendedAnalysisResult,
        language: DetectedLanguage,
        completion: @escaping ([KeyPhrase]) -> Void
    ) {
        var keyPhrases: [KeyPhrase] = []
        
        // Extract phrases from keywords with contextual information
        for keyword in analysis.keywords {
            let phrase = KeyPhrase(
                phrase: keyword.term,
                confidence: keyword.relevance,
                relevance: keyword.relevance,
                category: mapKeywordCategory(keyword.category),
                positions: keyword.positions
            )
            keyPhrases.append(phrase)
        }
        
        // Extract phrases from topics
        for topic in analysis.topics {
            let phrase = KeyPhrase(
                phrase: topic.name,
                confidence: topic.confidence,
                relevance: topic.confidence,
                category: .topic,
                positions: []
            )
            keyPhrases.append(phrase)
        }
        
        // Sort by relevance and limit
        let sortedPhrases = keyPhrases
            .sorted { $0.relevance > $1.relevance }
            .prefix(15)
            .map { $0 }
        
        completion(Array(sortedPhrases))
    }
    
    private func mapKeywordCategory(_ keywordCategory: Keyword.KeywordCategory) -> KeyPhrase.KeyPhraseCategory {
        switch keywordCategory {
        case .technical:
            return .technical
        case .business:
            return .concept
        case .emotional:
            return .emotional
        case .action:
            return .action
        case .person:
            return .entity
        case .organization:
            return .entity
        default:
            return .concept
        }
    }
}

class SummaryConfidenceScorer {
    func score(
        originalText: String,
        summary: String,
        analysis: ExtendedAnalysisResult,
        keyPhrases: [KeyPhrase],
        format: SummaryFormat,
        completion: @escaping (SummaryConfidence) -> Void
    ) {
        let coherenceScore = calculateCoherenceScore(text: summary)
        let completenessScore = calculateCompletenessScore(original: originalText, summary: summary)
        let accuracyScore = calculateAccuracyScore(analysis: analysis, summary: summary)
        let languageQualityScore = calculateLanguageQualityScore(summary: summary, language: analysis.language)
        
        let overallScore = (coherenceScore + completenessScore + accuracyScore + languageQualityScore) / 4.0
        let improvements = generateImprovements(coherence: coherenceScore, completeness: completenessScore, accuracy: accuracyScore)
        
        completion(SummaryConfidence(
            overallScore: overallScore,
            coherenceScore: coherenceScore,
            completenessScore: completenessScore,
            accuracyScore: accuracyScore,
            languageQualityScore: languageQualityScore,
            improvements: improvements
        ))
    }
    
    private func calculateCoherenceScore(text: String) -> Double {
        let sentences = text.components(separatedBy: .punctuationCharacters).filter { !$0.isEmpty }
        guard sentences.count > 1 else { return 1.0 }
        
        var coherenceSum = 0.0
        var connections = 0
        
        for i in 0..<(sentences.count - 1) {
            let words1 = Set(sentences[i].lowercased().components(separatedBy: .whitespacesAndNewlines))
            let words2 = Set(sentences[i + 1].lowercased().components(separatedBy: .whitespacesAndNewlines))
            let overlap = words1.intersection(words2)
            
            if !overlap.isEmpty {
                coherenceSum += 1.0
            }
            connections += 1
        }
        
        return connections > 0 ? coherenceSum / Double(connections) : 1.0
    }
    
    private func calculateCompletenessScore(original: String, summary: String) -> Double {
        let originalWords = Set(original.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let summaryWords = Set(summary.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let coverage = Double(originalWords.intersection(summaryWords).count) / Double(originalWords.count)
        let density = Double(summaryWords.count) / Double(originalWords.count)
        
        // Balance between coverage and density
        return min(1.0, (coverage * 0.6) + (density * 0.4))
    }
    
    private func calculateAccuracyScore(analysis: ExtendedAnalysisResult, summary: String) -> Double {
        var accuracy = 0.0
        
        // Check if summary maintains key information
        let highConfidenceKeywords = analysis.keywords.filter { $0.relevance > 0.7 }
        var matchedKeywords = 0
        
        for keyword in highConfidenceKeywords {
            if summary.lowercased().contains(keyword.term.lowercased()) {
                matchedKeywords += 1
            }
        }
        
        accuracy = highConfidenceKeywords.isEmpty ? 0.8 : Double(matchedKeywords) / Double(highConfidenceKeywords.count)
        
        // Adjust based on overall analysis confidence
        accuracy *= analysis.confidence
        
        return accuracy
    }
    
    private func calculateLanguageQualityScore(summary: String, language: DetectedLanguage) -> Double {
        let words = summary.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let sentences = summary.components(separatedBy: .punctuationCharacters).filter { !$0.isEmpty }
        
        // Basic language quality indicators
        let avgWordsPerSentence = words.count > 0 ? Double(words.count) / Double(sentences.count) : 0
        
        // Penalize overly long or short sentences
        var qualityScore = 1.0
        if avgWordsPerSentence > 25 {
            qualityScore -= 0.2 // Too long
        } else if avgWordsPerSentence < 5 {
            qualityScore -= 0.3 // Too short
        }
        
        // Language-specific adjustments
        if language.isGerman {
            // Germans prefer precise, well-structured sentences
            if sentences.count <= 3 {
                qualityScore -= 0.1
            }
        }
        
        return max(0.0, min(1.0, qualityScore))
    }
    
    private func generateImprovements(coherence: Double, completeness: Double, accuracy: Double) -> [QualityImprovement] {
        var improvements: [QualityImprovement] = []
        
        if coherence < 0.6 {
            improvements.append(QualityImprovement(
                category: "Kohärenz",
                suggestion: "Verbesserung der logischen Verbindung zwischen Sätzen",
                impact: 1.0 - coherence
            ))
        }
        
        if completeness < 0.7 {
            improvements.append(QualityImprovement(
                category: "Vollständigkeit",
                suggestion: "Hinzufügung wichtiger Details aus dem Originaltext",
                impact: 1.0 - completeness
            ))
        }
        
        if accuracy < 0.8 {
            improvements.append(QualityImprovement(
                category: "Genauigkeit",
                suggestion: "Präzisierung wichtiger Begriffe und Fakten",
                impact: 1.0 - accuracy
            ))
        }
        
        return improvements
    }
}

class SummaryLengthController {
    func adjust(
        summary: String,
        targetLength: SummaryLength,
        language: DetectedLanguage,
        format: SummaryFormat,
        completion: @escaping (String) -> Void
    ) {
        let currentWordCount = summary.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        var adjustedSummary = summary
        
        if currentWordCount > targetLength.wordCount.upperBound {
            // Trim the summary
            adjustedSummary = trimToTarget(summary: summary, targetWordCount: targetLength.wordCount.upperBound)
        } else if currentWordCount < targetLength.wordCount.lowerBound {
            // Expand the summary
            adjustedSummary = expandToTarget(summary: summary, targetWordCount: targetLength.wordCount.lowerBound)
        }
        
        completion(adjustedSummary)
    }
    
    private func trimToTarget(summary: String, targetWordCount: Int) -> String {
        let words = summary.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let trimmedWords = Array(words.prefix(targetWordCount))
        return trimmedWords.joined(separator: " ")
    }
    
    private func expandToTarget(summary: String, targetWordCount: Int) -> String {
        // Simple expansion by adding contextual information
        let currentWordCount = summary.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let wordsNeeded = targetWordCount - currentWordCount
        
        guard wordsNeeded > 0 else { return summary }
        
        var expandedSummary = summary
        let expansionPhrases = [
            "Weitere Details zeigen, dass",
            "Zusätzlich ist wichtig zu erwähnen,",
            "Es ist bemerkenswert, dass",
            "Die Analyse verdeutlicht,"
        ]
        
        var wordsAdded = 0
        for phrase in expansionPhrases where wordsAdded < wordsNeeded {
            expandedSummary += " " + phrase
            wordsAdded += phrase.components(separatedBy: .whitespacesAndNewlines).count
        }
        
        return expandedSummary
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let realtimeSummaryUpdate = Notification.Name("RealtimeSummaryUpdate")
}