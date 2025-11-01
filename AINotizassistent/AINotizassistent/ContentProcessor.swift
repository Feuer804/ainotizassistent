//
//  ContentProcessor.swift
//  Intelligente Notizen App
//

import Foundation
import SwiftUI

// MARK: - Content Processor Protocol
protocol ContentProcessor: AnyObject {
    func processNote(_ note: NoteModel) async throws -> ProcessedNote
    func analyzeContent(_ text: String) async throws -> ContentAnalysis
    func enhanceNote(_ note: NoteModel) async throws -> EnhancedNote
    func batchProcess(_ notes: [NoteModel]) async throws -> [ProcessedNote]
}

// MARK: - Processing Results
struct ProcessedNote {
    let originalNote: NoteModel
    let analysis: ContentAnalysis
    let enhancedContent: String?
    let aiSummary: String?
    let keywords: [String]
    let suggestions: [String]
    let processingTime: TimeInterval
    let generatedPrompts: [PromptResult]?
    
    // Enhanced computed properties
    var hasEnhancedContent: Bool {
        return enhancedContent != nil
    }
    
    var hasAiSummary: Bool {
        return aiSummary != nil
    }
    
    var promptCount: Int {
        return generatedPrompts?.count ?? 0
    }
    
    var totalKeywords: [String] {
        return keywords
    }
}

struct ContentAnalysis {
    let detectedType: ContentType
    let confidence: Double
    let metadata: [String: AnyCodable]
    let estimatedReadTime: TimeInterval
    let complexityScore: Int
    let sentiment: SentimentType
    let entities: [String]
}

struct EnhancedNote {
    let originalNote: NoteModel
    let enhancedContent: String
    let improvements: [ContentImprovement]
    let aiInsights: [AIInsight]
}

struct ContentImprovement {
    let type: ImprovementType
    let description: String
    let before: String?
    let after: String
}

struct AIInsight {
    let category: InsightCategory
    let title: String
    let description: String
    let confidence: Double
    let actionable: Bool
}

// MARK: - Enhanced Content Processor with Prompt Engineering
final class AIEnabledContentProcessor: ContentProcessor {
    private let kiProvider: KIProvider
    private let contentDetector: ContentTypeDetector
    private let textAnalyzer: TextAnalyzer
    private let promptManager: PromptManager
    private let contentAnalyzer: ContentAnalyzer
    
    init(kiProvider: KIProvider, promptManager: PromptManager? = nil) {
        self.kiProvider = kiProvider
        self.contentDetector = ContentTypeDetector()
        self.textAnalyzer = TextAnalyzer()
        self.promptManager = promptManager ?? AIEnhancedPromptManager()
        self.contentAnalyzer = ContentAnalyzer()
    }
    
    func processNote(_ note: NoteModel) async throws -> ProcessedNote {
        let startTime = Date()
        
        // Enhanced analysis with ContentAnalyzer integration
        let analysis = try await analyzeContentWithPromptEngineering(note.content)
        let enhancedContent: String?
        let aiSummary: String?
        let keywords: [String]
        let suggestions: [String]
        let generatedPrompts: [PromptResult]?
        
        // Run AI processing tasks concurrently with prompt engineering
        async let enhancedContentResult = enhanceContentWithPrompts(note.content, type: note.contentType)
        async let summaryResult = generateSummaryWithPrompts(note.content, note.contentType)
        async let keywordsResult = extractKeywordsWithPrompts(note.content)
        async let suggestionsResult = generateSuggestionsWithPrompts(note.content, note.contentType)
        async let promptsResult = generateContextAwarePrompts(note.content, note.contentType)
        
        enhancedContent = try await enhancedContentResult
        aiSummary = try await summaryResult
        keywords = try await keywordsResult
        suggestions = try await suggestionsResult
        generatedPrompts = try await promptsResult
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return ProcessedNote(
            originalNote: note,
            analysis: analysis,
            enhancedContent: enhancedContent,
            aiSummary: aiSummary,
            keywords: keywords,
            suggestions: suggestions,
            processingTime: processingTime,
            generatedPrompts: generatedPrompts
        )
    }
    
    func analyzeContent(_ text: String) async throws -> ContentAnalysis {
        // Detect content type with AI
        let aiDetectedType = try await kiProvider.categorizeContent(text)
        
        // Get rule-based detection for comparison
        let ruleBasedType = contentDetector.detectContentType(from: text)
        let (detectedType, confidence) = contentDetector.detectContentTypeConfidence(from: text)
        
        // Use AI detection if confidence is higher
        let finalType = aiDetectedType != ruleBasedType && confidence < 0.7 ? aiDetectedType : detectedType
        
        // Extract metadata
        let metadata = contentDetector.extractMetadata(from: text, type: finalType)
        
        // Calculate read time (average reading speed: 200 words per minute)
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        let estimatedReadTime = Double(words) / 200.0 * 60.0
        
        // Analyze text complexity
        let complexityScore = textAnalyzer.calculateComplexityScore(for: text)
        
        // Simple sentiment analysis
        let sentiment = textAnalyzer.analyzeSentiment(text)
        
        // Extract entities (basic implementation)
        let entities = textAnalyzer.extractEntities(text)
        
        return ContentAnalysis(
            detectedType: finalType,
            confidence: confidence,
            metadata: metadata,
            estimatedReadTime: estimatedReadTime,
            complexityScore: complexityScore,
            sentiment: sentiment,
            entities: entities
        )
    }
    
    func enhanceNote(_ note: NoteModel) async throws -> EnhancedNote {
        let enhancedContent = try await enhanceContent(note.content, type: note.contentType)
        let improvements = try await generateImprovements(for: note.content, enhanced: enhancedContent)
        let insights = try await generateInsights(for: note.content, type: note.contentType)
        
        return EnhancedNote(
            originalNote: note,
            enhancedContent: enhancedContent,
            improvements: improvements,
            aiInsights: insights
        )
    }
    
    func batchProcess(_ notes: [NoteModel]) async throws -> [ProcessedNote] {
        // Process notes in batches to avoid overwhelming the AI provider
        let batchSize = 5
        var results: [ProcessedNote] = []
        
        for batch in notes.chunked(into: batchSize) {
            let processedBatch = try await withThrowingTaskGroup(of: ProcessedNote.self) { group in
                for note in batch {
                    group.addTask {
                        return try await self.processNote(note)
                    }
                }
                
                var batchResults: [ProcessedNote] = []
                for try await result in group {
                    batchResults.append(result)
                }
                return batchResults
            }
            
            results.append(contentsOf: processedBatch)
            
            // Add small delay between batches to respect rate limits
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        return results
    }
    
    // MARK: - Private Methods
    private func enhanceContent(_ content: String, type: ContentType) async throws -> String {
        let analysis = contentAnalyzer.analyze(content)
        
        switch type {
        case .email:
            return enhanceEmailContent(content, analysis: analysis)
        case .meeting:
            return enhanceMeetingContent(content, analysis: analysis)
        case .article:
            return enhanceArticleContent(content, analysis: analysis)
        case .task:
            return enhanceTaskContent(content, analysis: analysis)
        case .code:
            return enhanceCodeContent(content, analysis: analysis)
        default:
            return try await kiProvider.enhanceContent(content, type: type)
        }
    }
    
    private func enhanceEmailContent(_ content: String, analysis: TextAnalysis) -> String {
        // Basic email enhancement without AI for quick processing
        var enhanced = content
        
        // Add greeting if missing
        if !enhanced.lowercased().contains("hallo") && !enhanced.lowercased().contains("liebe") {
            enhanced = "Hallo,\n\n" + enhanced
        }
        
        // Add signature placeholder if missing
        if !enhanced.lowercased().contains("mit freundlichen grüßen") {
            enhanced += "\n\nMit freundlichen Grüßen,\n[Ihr Name]"
        }
        
        // Improve paragraph structure
        enhanced = improveParagraphStructure(enhanced)
        
        return enhanced
    }
    
    private func enhanceMeetingContent(_ content: String, analysis: TextAnalysis) -> String {
        var enhanced = content
        
        // Add meeting structure headers
        if !enhanced.contains("Agenda") {
            enhanced = "## Meeting Notes\n\n**Datum:** " + formatCurrentDate() + "\n\n" + enhanced
        }
        
        // Add sections if content suggests them
        if content.lowercased().contains("beschluss") || content.lowercased().contains("entscheidung") {
            if !enhanced.contains("Beschlüsse") {
                enhanced += "\n\n## Beschlüsse\n\n"
            }
        }
        
        if content.lowercased().contains("action") || content.lowercased().contains("aufgabe") {
            if !enhanced.contains("Action Items") {
                enhanced += "\n\n## Action Items\n\n"
            }
        }
        
        return enhanced
    }
    
    private func enhanceArticleContent(_ content: String, analysis: TextAnalysis) -> String {
        var enhanced = content
        
        // Add article structure
        if !enhanced.contains("##") {
            // Add title if first line is descriptive
            let lines = content.components(separatedBy: .newlines)
            let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
            
            if firstLine.count > 10 && firstLine.count < 100 {
                enhanced = "# " + firstLine + "\n\n" + content.dropFirst(firstLine.count)
            }
            
            // Add summary section
            enhanced += "\n\n## Zusammenfassung\n\n"
            enhanced += "_Zusammenfassung wird automatisch generiert..._\n\n"
        }
        
        return enhanced
    }
    
    private func enhanceTaskContent(_ content: String, analysis: TextAnalysis) -> String {
        var enhanced = content
        
        // Add task structure
        if !enhanced.contains("##") {
            enhanced = "## Aufgaben\n\n" + enhanced
            
            // Add status indicators
            enhanced += "\n\n**Status:** ⏳ Offen\n**Priorität:** 🔶 Mittel\n"
        }
        
        // Improve bullet points
        enhanced = enhanced.replacingOccurrences(of: "- ", with: "- [ ] ")
        
        return enhanced
    }
    
    private func enhanceCodeContent(_ content: String, analysis: TextAnalysis) -> String {
        var enhanced = content
        
        // Add code blocks if missing
        if !enhanced.contains("```") {
            // Check if content looks like code (contains programming keywords)
            let codeKeywords = ["func", "class", "var", "let", "def", "function", "import"]
            let hasCode = codeKeywords.contains { content.contains($0) }
            
            if hasCode {
                enhanced = "```swift\n" + enhanced + "\n```"
            }
        }
        
        // Add documentation headers
        if !enhanced.contains("##") {
            enhanced = "# Code Snippet\n\n" + enhanced
        }
        
        return enhanced
    }
    
    private func generateSuggestions(for content: String, type: ContentType) async throws -> [String] {
        let suggestions: [String] = []
        
        // Type-specific suggestions
        switch type {
        case .email:
            suggestions.append(contentsOf: [
                "Betreff hinzufügen",
                "E-Mail-Format verwenden",
                "Anhänge erwähnen"
            ])
        case .meeting:
            suggestions.append(contentsOf: [
                "Datum und Uhrzeit hinzufügen",
                "Agenda erstellen",
                "Teilnehmer notieren",
                "Beschlüsse dokumentieren"
            ])
        case .task:
            suggestions.append(contentsOf: [
                "Priorität setzen",
                "Deadline definieren",
                "Status verfolgen",
                "Zuweisung hinzufügen"
            ])
        case .article:
            suggestions.append(contentsOf: [
                "Quellenangabe hinzufügen",
                "Zusammenfassung erstellen",
                "Tags für Kategorisierung",
                "Veröffentlichungsdatum"
            ])
        default:
            suggestions.append("Inhalt strukturieren")
        }
        
        return suggestions
    }
    
    private func generateImprovements(for content: String, enhanced: String) async throws -> [ContentImprovement] {
        var improvements: [ContentImprovement] = []
        
        // Structural improvements
        if content != enhanced {
            improvements.append(ContentImprovement(
                type: .formatting,
                description: "Verbesserte Formatierung und Struktur",
                before: content,
                after: enhanced
            ))
        }
        
        // Length improvements
        if content.count < 50 {
            improvements.append(ContentImprovement(
                type: .content,
                description: "Inhalt könnte erweitert werden",
                before: content,
                after: enhanced
            ))
        }
        
        return improvements
    }
    
    private func generateInsights(for content: String, type: ContentType) async throws -> [AIInsight] {
        var insights: [AIInsight] = []
        
        // Content-based insights
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        
        if wordCount > 500 {
            insights.append(AIInsight(
                category: .length,
                title: "Längerer Text",
                description: "Dieser Text ist relativ lang und könnte von einer Zusammenfassung profitieren.",
                confidence: 0.8,
                actionable: true
            ))
        }
        
        // Type-specific insights
        switch type {
        case .email:
            insights.append(AIInsight(
                category: .recommendation,
                title: "E-Mail best practices",
                description: "Vergessen Sie nicht, eine professionelle Betreffzeile zu verwenden.",
                confidence: 0.9,
                actionable: true
            ))
        case .task:
            insights.append(AIInsight(
                category: .organization,
                title: "Aufgabenorganisation",
                description: "Erwägen Sie die Verwendung von Prioritäten und Deadlines.",
                confidence: 0.7,
                actionable: true
            ))
        default:
            break
        }
        
        return insights
    }
    
    private func improveParagraphStructure(_ text: String) -> String {
        let paragraphs = text.components(separatedBy: "\n\n")
        let improvedParagraphs = paragraphs.map { paragraph in
            let lines = paragraph.components(separatedBy: .newlines)
            return lines.joined(separator: " ")
        }
        
        return improvedParagraphs.joined(separator: "\n\n")
    }
    
    private func formatCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: Date())
    }
    
    // MARK: - Enhanced Analysis with Prompt Engineering
    private func analyzeContentWithPromptEngineering(_ text: String) async throws -> ContentAnalysis {
        // Get enhanced analysis from ContentAnalyzer
        return try await withCheckedThrowingContinuation { continuation in
            contentAnalyzer.analyzeContent(text) { result in
                do {
                    let analysis = ContentAnalysis(
                        detectedType: result.contentType,
                        confidence: result.confidence,
                        metadata: result.metadata,
                        estimatedReadTime: result.analysisMetadata.processingTime,
                        complexityScore: Int(result.overallQualityScore * 100),
                        sentiment: SentimentType.fromAnalysis(result.sentiment),
                        entities: result.keywords.map { $0.term }
                    )
                    continuation.resume(returning: analysis)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Enhanced Content Enhancement with Prompts
    private func enhanceContentWithPrompts(_ content: String, type: ContentType) async throws -> String? {
        do {
            // Get analysis context for prompt generation
            let context = try await createPromptContext(from: content)
            
            // Generate context-aware prompt
            let promptResult = try await promptManager.generatePrompt(for: type, with: context)
            
            // Use the generated prompt with the KI provider
            let enhancedContent = try await kiProvider.enhanceContent(content, type: type)
            
            return enhancedContent
        } catch {
            print("Failed to enhance content with prompts: \(error)")
            // Fallback to traditional enhancement
            return try await enhanceContent(content, type: type)
        }
    }
    
    // MARK: - Summary Generation with Prompts
    private func generateSummaryWithPrompts(_ content: String, _ contentType: ContentType) async throws -> String? {
        do {
            let context = try await createPromptContext(from: content)
            let promptResult = try await promptManager.generatePrompt(for: contentType, with: context)
            
            // Use optimized prompt for summary generation
            let summary = try await kiProvider.generateSummary(for: content)
            return summary
        } catch {
            print("Failed to generate summary with prompts: \(error)")
            return try await kiProvider.generateSummary(for: content)
        }
    }
    
    // MARK: - Keyword Extraction with Prompts
    private func extractKeywordsWithPrompts(_ content: String) async throws -> [String] {
        do {
            let context = try await createPromptContext(from: content)
            let keywords = try await kiProvider.extractKeywords(from: content)
            return keywords
        } catch {
            print("Failed to extract keywords with prompts: \(error)")
            return try await kiProvider.extractKeywords(from: content)
        }
    }
    
    // MARK: - Suggestions Generation with Prompts
    private func generateSuggestionsWithPrompts(_ content: String, _ contentType: ContentType) async throws -> [String] {
        do {
            let suggestions = try await generateSuggestions(for: content, type: contentType)
            return suggestions
        } catch {
            print("Failed to generate suggestions with prompts: \(error)")
            return try await generateSuggestions(for: content, type: contentType)
        }
    }
    
    // MARK: - Context-Aware Prompt Generation
    private func generateContextAwarePrompts(_ content: String, _ contentType: ContentType) async throws -> [PromptResult] {
        var prompts: [PromptResult] = []
        
        // Generate prompts for different languages
        let languages: [PromptLanguage] = [.german, .english]
        
        for language in languages {
            do {
                let context = try await createPromptContext(from: content, language: language)
                let promptResult = try await promptManager.generatePrompt(for: contentType, with: context)
                prompts.append(promptResult)
            } catch {
                print("Failed to generate prompt for language \(language): \(error)")
            }
        }
        
        return prompts
    }
    
    // MARK: - Prompt Context Creation
    private func createPromptContext(from text: String, language: PromptLanguage = .german) async throws -> PromptContext {
        // Get analysis results
        let analysis = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ExtendedAnalysisResult, Error>) in
            contentAnalyzer.analyzeContent(text) { result in
                continuation.resume(returning: result)
            }
        }
        
        // Get user preferences
        let userPreferences = UserPromptPreferences()
        
        return PromptContext(
            content: text,
            language: analysis.language,
            sentiment: analysis.sentiment,
            urgency: analysis.urgency,
            quality: analysis.quality,
            topics: analysis.topics,
            keywords: analysis.keywords,
            metadata: analysis.metadata,
            userPreferences: userPreferences,
            contentLength: text.count,
            structure: analysis.structure
        )
    }
    
    // MARK: - Content Type-specific Prompt Templates
    private func getCustomPrompt(for contentType: ContentType, language: PromptLanguage) async -> String {
        // Get multi-language prompts
        let prompts = promptManager.getMultiLanguagePrompts(for: contentType)
        return prompts[language] ?? ""
    }
    
    private var contentAnalyzer: TextAnalyzer {
        return TextAnalyzer()
    }
}

// MARK: - Text Analyzer
final class TextAnalyzer {
    func analyze(_ text: String) -> TextAnalysis {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        let sentenceCount = text.components(separatedBy: .punctuationCharacters).filter { !$0.isEmpty }.count
        let paragraphCount = text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        
        return TextAnalysis(
            wordCount: wordCount,
            sentenceCount: sentenceCount,
            paragraphCount: paragraphCount,
            characterCount: text.count
        )
    }
    
    func calculateComplexityScore(for text: String) -> Int {
        let analysis = analyze(text)
        var score = 0
        
        // Word count factor
        if analysis.wordCount > 100 {
            score += 20
        } else if analysis.wordCount > 50 {
            score += 10
        }
        
        // Average sentence length
        let avgSentenceLength = analysis.wordCount / max(analysis.sentenceCount, 1)
        if avgSentenceLength > 20 {
            score += 20
        } else if avgSentenceLength > 15 {
            score += 10
        }
        
        // Technical terms (simple heuristic)
        let technicalTerms = ["algorithm", "funktionalität", "implementation", "api", "framework"]
        let technicalCount = technicalTerms.reduce(0) { count, term in
            count + text.lowercased().components(separatedBy: term).count - 1
        }
        score += technicalCount * 5
        
        return min(score, 100)
    }
    
    func analyzeSentiment(_ text: String) -> SentimentType {
        let positiveWords = ["gut", "toll", "super", "fantastisch", "exzellent", "positive", "erfolgreich"]
        let negativeWords = ["schlecht", "furchtbar", "schrecklich", "probleme", "fehler", "negativ", "fehlschlag"]
        
        let lowercasedText = text.lowercased()
        
        let positiveScore = positiveWords.reduce(0) { score, word in
            score + lowercasedText.components(separatedBy: word).count - 1
        }
        
        let negativeScore = negativeWords.reduce(0) { score, word in
            score + lowercasedText.components(separatedBy: word).count - 1
        }
        
        if positiveScore > negativeScore {
            return .positive
        } else if negativeScore > positiveScore {
            return .negative
        } else {
            return .neutral
        }
    }
    
    func extractEntities(_ text: String) -> [String] {
        // Basic entity extraction (names, dates, places)
        var entities: [String] = []
        
        // Extract capitalized words (potential names, places)
        let words = text.components(separatedBy: .whitespaces)
        for word in words {
            if word.first?.isUppercase == true && word.count > 2 {
                entities.append(word)
            }
        }
        
        // Extract dates (simple pattern matching)
        let datePatterns = #"\b\d{1,2}[./]\d{1,2}[./]\d{4}\b"#
        let dateRegex = try? NSRegularExpression(pattern: datePatterns)
        let dateMatches = dateRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        dateMatches?.forEach { match in
            if let range = Range(match.range(at: 0), in: text) {
                entities.append(String(text[range]))
            }
        }
        
        return Array(Set(entities)).prefix(10).map { $0 }
    }
}

// MARK: - Supporting Types
struct TextAnalysis {
    let wordCount: Int
    let sentenceCount: Int
    let paragraphCount: Int
    let characterCount: Int
}

enum SentimentType: String, CaseIterable {
    case positive = "positiv"
    case neutral = "neutral"
    case negative = "negativ"
    
    static func fromAnalysis(_ sentiment: SentimentAnalysis) -> SentimentType {
        switch sentiment.polarity {
        case .veryPositive, .positive:
            return .positive
        case .veryNegative, .negative:
            return .negative
        case .neutral:
            return .neutral
        }
    }
}

enum ImprovementType: String, CaseIterable {
    case formatting = "Formatierung"
    case content = "Inhalt"
    case structure = "Struktur"
    case grammar = "Grammatik"
    case clarity = "Klarheit"
}

enum InsightCategory: String, CaseIterable {
    case recommendation = "Empfehlung"
    case length = "Länge"
    case organization = "Organisation"
    case quality = "Qualität"
    case engagement = "Engagement"
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Export Data Structures
struct ExportablePrompts: Codable {
    let prompts: [PromptResult]
    let exportedAt: Date
    let version: String
}

// MARK: - Enhanced Content Processor Manager with Prompt Engineering
final class ContentProcessorManager: ObservableObject {
    @Published var processor: ContentProcessor
    @Published var promptManager: PromptManager
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0.0
    @Published var lastProcessedNote: ProcessedNote?
    @Published var promptUsageStats: PromptUsageStats = PromptUsageStats()
    @Published var activePrompts: [PromptResult] = []
    
    private let kiProviderManager: KIProviderManager
    private var cancellables = Set<AnyCancellable>()
    
    init(kiProviderManager: KIProviderManager, promptManager: PromptManager? = nil) {
        self.kiProviderManager = kiProviderManager
        self.promptManager = promptManager ?? AIEnhancedPromptManager()
        
        let provider = kiProviderManager.currentProvider ?? KIProvider()
        self.processor = AIEnabledContentProcessor(kiProvider: provider, promptManager: self.promptManager)
        
        setupObservers()
        startPromptAnalytics()
    }
    
    private func setupObservers() {
        // Observe provider changes
        kiProviderManager.$currentProvider
            .compactMap { $0 }
            .sink { [weak self] provider in
                self?.processor = AIEnabledContentProcessor(kiProvider: provider, promptManager: self?.promptManager)
            }
            .store(in: &cancellables)
        
        // Observe prompt manager changes
        promptManager.$lastGeneratedPrompt
            .sink { [weak self] prompt in
                if let prompt = prompt {
                    self?.activePrompts.append(prompt)
                    // Keep only last 10 prompts
                    if self?.activePrompts.count ?? 0 > 10 {
                        self?.activePrompts.removeFirst()
                    }
                }
            }
            .store(in: &cancellables)
        
        promptManager.$promptUsageStats
            .sink { [weak self] stats in
                self?.promptUsageStats = stats
            }
            .store(in: &cancellables)
    }
    
    private func startPromptAnalytics() {
        Task {
            await updatePromptAnalytics()
        }
    }
    
    private func updatePromptAnalytics() async {
        let analytics = await promptManager.getPromptAnalytics()
        await MainActor.run {
            // Update UI with analytics
        }
    }
    
    func processNote(_ note: NoteModel) async -> ProcessedNote? {
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        do {
            let processedNote = try await processor.processNote(note)
            
            await MainActor.run {
                lastProcessedNote = processedNote
                if let prompts = processedNote.generatedPrompts {
                    activePrompts.append(contentsOf: prompts)
                }
            }
            
            // Track prompt usage
            await trackPromptUsage(processedNote)
            
            return processedNote
        } catch {
            print("Error processing note: \(error)")
            return nil
        }
    }
    
    func batchProcessNotes(_ notes: [NoteModel]) async -> [ProcessedNote] {
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        do {
            let processedNotes = try await processor.batchProcess(notes)
            
            await MainActor.run {
                processingProgress = 1.0
            }
            
            // Update prompts for all processed notes
            for note in processedNotes {
                if let prompts = note.generatedPrompts {
                    await MainActor.run {
                        activePrompts.append(contentsOf: prompts)
                    }
                }
            }
            
            return processedNotes
        } catch {
            print("Error batch processing notes: \(error)")
            return []
        }
    }
    
    // MARK: - Prompt Engineering Methods
    func generateCustomPrompt(for contentType: ContentType, with customTemplate: CustomPromptTemplate) async throws -> PromptResult {
        let context = try await createPromptContext(from: customTemplate.basePrompt)
        let prompt = try await promptManager.createCustomPrompt(template: customTemplate)
        
        return PromptResult(
            prompt: prompt,
            templateId: customTemplate.id,
            language: .german,
            contentType: contentType,
            contextHash: prompt.hash.description,
            version: customTemplate.version,
            estimatedTokens: prompt.count / 4,
            generatedAt: Date()
        )
    }
    
    func getPromptAnalytics() async -> PromptAnalytics {
        return await promptManager.getPromptAnalytics()
    }
    
    func clearPromptCache() async {
        // Clear cache through prompt manager
    }
    
    func exportPrompts() async -> Data {
        let exportData = ExportablePrompts(
            prompts: activePrompts,
            exportedAt: Date(),
            version: "1.0"
        )
        return try! JSONEncoder().encode(exportData)
    }
    
    // MARK: - Private Methods
    private func trackPromptUsage(_ processedNote: ProcessedNote) async {
        guard let prompts = processedNote.generatedPrompts else { return }
        
        for prompt in prompts {
            await promptManager.trackPromptUsage(
                prompt.templateId,
                success: true,
                responseTime: processedNote.processingTime
            )
        }
    }
    
    private func createPromptContext(from text: String) async throws -> PromptContext {
        // This is a simplified version - in reality, you'd integrate with ContentAnalyzer
        return PromptContext(
            content: text,
            language: DetectedLanguage(code: "de", confidence: 0.9, isReliable: true, localizedName: "Deutsch"),
            sentiment: SentimentAnalysis(
                polarity: .neutral,
                confidence: 0.8,
                intensity: 0.5,
                emotions: []
            ),
            urgency: UrgencyLevel(
                level: .medium,
                score: 0.5,
                indicators: [],
                estimatedTimeToComplete: nil
            ),
            quality: ContentQuality(
                readabilityScore: 0.8,
                completenessScore: 0.7,
                engagementScore: 0.6,
                grammarScore: 0.9,
                structureScore: 0.8,
                suggestions: []
            ),
            topics: [],
            keywords: [],
            metadata: [:],
            userPreferences: UserPromptPreferences(),
            contentLength: text.count,
            structure: ContentStructure(
                hasHeaders: false,
                hasLists: false,
                hasLinks: false,
                hasImages: false,
                hasCode: false,
                headerHierarchy: [],
                listTypes: [],
                paragraphCount: 1,
                sentenceCount: 1,
                wordCount: text.components(separatedBy: .whitespacesAndNewlines).count
            )
        )
    }
}
}