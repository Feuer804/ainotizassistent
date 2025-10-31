//
//  PromptManager.swift
//  Intelligente Notizen App - Erweiterte Prompt-Engineering
//

import Foundation
import Combine

// MARK: - Prompt Manager Protocol
protocol PromptManager: AnyObject {
    func generatePrompt(for contentType: ContentType, with context: PromptContext) async throws -> PromptResult
    func getPromptTemplate(for contentType: ContentType, language: PromptLanguage) -> PromptTemplate
    func optimizePrompt(_ prompt: String, basedOn context: PromptContext) async throws -> String
    func cachePrompt(_ prompt: String, for contentType: ContentType, contextHash: String) async
    func getCachedPrompt(for contentType: ContentType, contextHash: String) async -> String?
    func trackPromptUsage(_ promptId: String, success: Bool, responseTime: TimeInterval) async
    func getPromptAnalytics() async -> PromptAnalytics
    func createCustomPrompt(template: CustomPromptTemplate) async throws -> String
    func getABTestPrompts(for contentType: ContentType) async -> [ABTestPrompt]
    func getContextWindowManager() -> ContextWindowManager
    func getMultiLanguagePrompts(for contentType: ContentType) -> [PromptLanguage: String]
}

// MARK: - Prompt Data Types
struct PromptResult {
    let prompt: String
    let templateId: String
    let language: PromptLanguage
    let contentType: ContentType
    let contextHash: String
    let version: String
    let estimatedTokens: Int
    let generatedAt: Date
}

struct PromptContext {
    let content: String
    let language: DetectedLanguage
    let sentiment: SentimentAnalysis
    let urgency: UrgencyLevel
    let quality: ContentQuality
    let topics: [Topic]
    let keywords: [Keyword]
    let metadata: [String: AnyCodable]
    let userPreferences: UserPromptPreferences
    let contentLength: Int
    let structure: ContentStructure
}

struct PromptTemplate {
    let id: String
    let name: String
    let description: String
    let contentType: ContentType
    let language: PromptLanguage
    let basePrompt: String
    let parameters: [PromptParameter]
    let version: String
    let metadata: PromptTemplateMetadata
}

struct PromptParameter {
    let name: String
    let type: PromptParameterType
    let required: Bool
    let description: String
    let defaultValue: String?
    
    enum PromptParameterType {
        case string, integer, float, boolean, array, object
    }
}

struct PromptTemplateMetadata {
    let createdAt: Date
    let lastModified: Date
    let usageCount: Int
    let averageTokens: Double
    let successRate: Double
    let tags: [String]
}

enum PromptLanguage: String, CaseIterable, Codable {
    case german = "de"
    case english = "en"
    case multilingual = "multi"
    
    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        case .multilingual: return "Mehrsprachig"
        }
    }
    
    var nativeName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        case .multilingual: return "Multilingual"
        }
    }
}

// MARK: - Content-Type-specific Prompt Templates
struct ContentTypePromptTemplates {
    private static let templates: [ContentType: [PromptLanguage: String]] = [
        .email: [
            .german: """
            Du bist ein KI-Assistent für E-Mail-Analyse und -Verarbeitung.

            Analysiere die folgende E-Mail und erstelle eine strukturierte Zusammenfassung:
            
            E-Mail-Inhalt:
            {content}
            
            Analysiere:
            1. **Zusammenfassung**: Kompakte Zusammenfassung in 2-3 Sätzen
            2. **Action Items**: Liste aller Aufgaben und Fristen
            3. **Prioritäten**: Wichtigkeit und Dringlichkeit bewerten
            4. **Sentiment**: Grundstimmung der E-Mail
            5. **Nächste Schritte**: Konkrete Handlungsempfehlungen

            Antworte in diesem Format:
            ## Zusammenfassung
            [2-3 Sätze Zusammenfassung]
            
            ## Action Items
            - [Aufgabe 1] (Priorität: Hoch/Mittel/Niedrig) - Fällig: [Datum]
            - [Aufgabe 2] (Priorität: Hoch/Mittel/Niedrig) - Fällig: [Datum]
            
            ## Prioritäten
            - **Wichtig**: [Grund]
            - **Dringend**: [Grund]
            
            ## Sentiment
            [Positiv/Neutral/Negativ] - [Begründung]
            
            ## Nächste Schritte
            1. [Schritt 1]
            2. [Schritt 2]
            """,
            
            .english: """
            You are an AI assistant for email analysis and processing.

            Analyze the following email and create a structured summary:
            
            Email content:
            {content}
            
            Analyze:
            1. **Summary**: Compact summary in 2-3 sentences
            2. **Action Items**: List of all tasks and deadlines
            3. **Priorities**: Evaluate importance and urgency
            4. **Sentiment**: Overall mood of the email
            5. **Next Steps**: Concrete action recommendations

            Respond in this format:
            ## Summary
            [2-3 sentence summary]
            
            ## Action Items
            - [Task 1] (Priority: High/Medium/Low) - Due: [Date]
            - [Task 2] (Priority: High/Medium/Low) - Due: [Date]
            
            ## Priorities
            - **Important**: [Reason]
            - **Urgent**: [Reason]
            
            ## Sentiment
            [Positive/Neutral/Negative] - [Explanation]
            
            ## Next Steps
            1. [Step 1]
            2. [Step 2]
            """
        ],
        
        .meeting: [
            .german: """
            Du bist ein KI-Assistent für Meeting-Protokoll-Analyse.

            Analysiere das folgende Meeting-Protokoll und strukturiere die Informationen:
            
            Meeting-Inhalt:
            {content}
            
            Analysiere:
            1. **Agenda**: Themen und zeitliche Planung
            2. **Teilnehmer**: Identifizierte Personen
            3. **Beschlüsse**: Getroffene Entscheidungen
            4. **Action Items**: Aufgaben mit Verantwortlichen und Fristen
            5. **Nächste Schritte**: Folgeaktivitäten
            6. **Wichtige Punkte**: Kernaussagen und Diskussionspunkte

            Antworte in diesem Format:
            ## Meeting-Informationen
            - **Datum**: [aus Inhalt extrahiert oder heute]
            - **Typ**: [Projekt-Meeting/Team-Meeting/etc.]
            - **Dauer**: [geschätzt oder extrahiert]
            
            ## Agenda
            1. [Thema 1] - [Dauer]
            2. [Thema 2] - [Dauer]
            
            ## Teilnehmer
            - [Person 1] - [Rolle]
            - [Person 2] - [Rolle]
            
            ## Beschlüsse
            1. [Entscheidung 1] - [Begründung]
            2. [Entscheidung 2] - [Begründung]
            
            ## Action Items
            - [Aufgabe] → [Verantwortliche Person] → Fällig: [Datum]
            
            ## Nächste Schritte
            1. [Nächster Schritt 1]
            2. [Nächster Schritt 2]
            
            ## Wichtige Punkte
            - [Wichtiger Punkt 1]
            - [Wichtiger Punkt 2]
            """,
            
            .english: """
            You are an AI assistant for meeting minutes analysis.

            Analyze the following meeting minutes and structure the information:
            
            Meeting content:
            {content}
            
            Analyze:
            1. **Agenda**: Topics and timing
            2. **Participants**: Identified persons
            3. **Decisions**: Decisions made
            4. **Action Items**: Tasks with assignees and deadlines
            5. **Next Steps**: Follow-up activities
            6. **Key Points**: Core statements and discussion points

            Respond in this format:
            ## Meeting Information
            - **Date**: [extracted from content or today]
            - **Type**: [Project meeting/Team meeting/etc.]
            - **Duration**: [estimated or extracted]
            
            ## Agenda
            1. [Topic 1] - [Duration]
            2. [Topic 2] - [Duration]
            
            ## Participants
            - [Person 1] - [Role]
            - [Person 2] - [Role]
            
            ## Decisions
            1. [Decision 1] - [Reason]
            2. [Decision 2] - [Reason]
            
            ## Action Items
            - [Task] → [Responsible person] → Due: [Date]
            
            ## Next Steps
            1. [Next step 1]
            2. [Next step 2]
            
            ## Key Points
            - [Key point 1]
            - [Key point 2]
            """
        ],
        
        .article: [
            .german: """
            Du bist ein KI-Assistent für Artikel-Analyse und -Zusammenfassung.

            Analysiere den folgenden Artikel und erstelle eine strukturierte Übersicht:
            
            Artikel-Inhalt:
            {content}
            
            Analysiere:
            1. **Zusammenfassung**: Hauptpunkte in 3-4 Sätzen
            2. **Hauptthemen**: Identifizierte Kernthemen
            3. **Wichtige Erkenntnisse**: Schlüsselaussagen und Findings
            4. **Relevante Themen**: Verwandte oder ähnliche Themen
            5. **Quellen**: Erwähnte Quellen oder Referenzen
            6. **Kategorien**: Thematische Einordnung

            Antworte in diesem Format:
            ## Artikel-Übersicht
            - **Titel**: [Extrahiert oder basierend auf Inhalt]
            - **Typ**: [Nachrichten/Informativ/Lifestyle/etc.]
            - **Lesezeit**: [Geschätzt: X Minuten]
            - **Schwierigkeitsgrad**: [Leicht/Mittel/Schwer]
            
            ## Zusammenfassung
            [3-4 Sätze, die die Hauptpunkte zusammenfassen]
            
            ## Hauptthemen
            1. [Thema 1] - [Bedeutung]
            2. [Thema 2] - [Bedeutung]
            3. [Thema 3] - [Bedeutung]
            
            ## Wichtige Erkenntnisse
            - [Erkenntnis 1] mit [Beleg/Quelle]
            - [Erkenntnis 2] mit [Beleg/Quelle]
            - [Erkenntnis 3] mit [Beleg/Quelle]
            
            ## Relevante Themen
            - [Verwandtes Thema 1]
            - [Verwandtes Thema 2]
            - [Verwandtes Thema 3]
            
            ## Kategorien
            - [Kategorie 1]
            - [Kategorie 2]
            """,
            
            .english: """
            You are an AI assistant for article analysis and summarization.

            Analyze the following article and create a structured overview:
            
            Article content:
            {content}
            
            Analyze:
            1. **Summary**: Main points in 3-4 sentences
            2. **Main Topics**: Identified core topics
            3. **Key Insights**: Key statements and findings
            4. **Related Topics**: Related or similar topics
            5. **Sources**: Mentioned sources or references
            6. **Categories**: Thematic classification

            Respond in this format:
            ## Article Overview
            - **Title**: [Extracted or based on content]
            - **Type**: [News/Informational/Lifestyle/etc.]
            - **Reading Time**: [Estimated: X minutes]
            - **Difficulty Level**: [Easy/Medium/Hard]
            
            ## Summary
            [3-4 sentences summarizing the main points]
            
            ## Main Topics
            1. [Topic 1] - [Significance]
            2. [Topic 2] - [Significance]
            3. [Topic 3] - [Significance]
            
            ## Key Insights
            - [Insight 1] with [evidence/source]
            - [Insight 2] with [evidence/source]
            - [Insight 3] with [evidence/source]
            
            ## Related Topics
            - [Related topic 1]
            - [Related topic 2]
            - [Related topic 3]
            
            ## Categories
            - [Category 1]
            - [Category 2]
            """
        ],
        
        .code: [
            .german: """
            Du bist ein KI-Assistent für Code-Review und -Dokumentation.

            Analysiere den folgenden Code und erstelle eine umfassende Bewertung:
            
            Code:
            {content}
            
            Analysiere:
            1. **Funktionalität**: Was der Code tut
            2. **Code-Qualität**: Bewertung der Implementierung
            3. **Dokumentation**: Dokumentationsstand
            4. **Verbesserungsvorschläge**: Refactoring-Suggestionen
            5. **Bekannte Probleme**: Identifizierte Issues
            6. **Best Practices**: Empfehlungen

            Antworte in diesem Format:
            ## Code-Übersicht
            - **Programmiersprache**: [Identifiziert]
            - **Komplexität**: [Niedrig/Mittel/Hoch]
            - **Zeilen**: [Anzahl]
            - **Zweck**: [Hauptfunktion]
            
            ## Funktionalität
            [Beschreibung was der Code macht]
            
            ## Code-Qualität
            - **Lesbarkeit**: [Bewertung 1-10]
            - **Wartbarkeit**: [Bewertung 1-10]
            - **Performance**: [Bewertung 1-10]
            - **Sicherheit**: [Bewertung 1-10]
            
            ## Dokumentation
            - **Kommentare**: [Vorhanden/Fehlend]
            - **Funktions-Docs**: [Vorhanden/Fehlend]
            - **Beispiele**: [Vorhanden/Fehlend]
            
            ## Verbesserungsvorschläge
            1. [Verbesserung 1] - [Grund]
            2. [Verbesserung 2] - [Grund]
            3. [Verbesserung 3] - [Grund]
            
            ## Bekannte Probleme
            - [Problem 1] - [Lösungsvorschlag]
            - [Problem 2] - [Lösungsvorschlag]
            
            ## Best Practices
            - [Empfehlung 1]
            - [Empfehlung 2]
            """,
            
            .english: """
            You are an AI assistant for code review and documentation.

            Analyze the following code and create a comprehensive evaluation:
            
            Code:
            {content}
            
            Analyze:
            1. **Functionality**: What the code does
            2. **Code Quality**: Implementation evaluation
            3. **Documentation**: Documentation status
            4. **Improvement Suggestions**: Refactoring recommendations
            5. **Known Issues**: Identified issues
            6. **Best Practices**: Recommendations

            Respond in this format:
            ## Code Overview
            - **Programming Language**: [Identified]
            - **Complexity**: [Low/Medium/High]
            - **Lines**: [Count]
            - **Purpose**: [Main function]
            
            ## Functionality
            [Description of what the code does]
            
            ## Code Quality
            - **Readability**: [Rating 1-10]
            - **Maintainability**: [Rating 1-10]
            - **Performance**: [Rating 1-10]
            - **Security**: [Rating 1-10]
            
            ## Documentation
            - **Comments**: [Present/Missing]
            - **Function Docs**: [Present/Missing]
            - **Examples**: [Present/Missing]
            
            ## Improvement Suggestions
            1. [Improvement 1] - [Reason]
            2. [Improvement 2] - [Reason]
            3. [Improvement 3] - [Reason]
            
            ## Known Issues
            - [Issue 1] - [Solution suggestion]
            - [Issue 2] - [Solution suggestion]
            
            ## Best Practices
            - [Recommendation 1]
            - [Recommendation 2]
            """
        ]
    ]
    
    static func getTemplate(for contentType: ContentType, language: PromptLanguage) -> String {
        return templates[contentType]?[language] ?? templates[.article]?[language] ?? ""
    }
}

// MARK: - Prompt Manager Implementation
final class AIEnhancedPromptManager: ObservableObject, PromptManager {
    
    // MARK: - Properties
    private let promptCache = PromptCache()
    private let analyticsTracker = PromptAnalyticsTracker()
    private let contextWindowManager = ContextWindowManager()
    private let abTestManager = ABTestPromptManager()
    
    @Published var isGenerating: Bool = false
    @Published var lastGeneratedPrompt: PromptResult?
    @Published var promptUsageStats: PromptUsageStats = PromptUsageStats()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupRealTimeAnalytics()
        startPromptOptimization()
    }
    
    // MARK: - Prompt Generation
    func generatePrompt(for contentType: ContentType, with context: PromptContext) async throws -> PromptResult {
        await MainActor.run {
            isGenerating = true
        }
        
        defer {
            Task { @MainActor in
                isGenerating = false
            }
        }
        
        do {
            // 1. Generate context hash
            let contextHash = generateContextHash(from: context)
            
            // 2. Check cache first
            if let cachedPrompt = await getCachedPrompt(for: contentType, contextHash: contextHash) {
                await trackPromptUsage("cached", success: true, responseTime: 0.0)
                return createResult(from: cachedPrompt, contentType: context, contextHash: contextHash)
            }
            
            // 3. Get base template
            let baseTemplate = getPromptTemplate(for: contentType, language: .german) // Could be dynamic based on context
            
            // 4. Apply dynamic optimization
            let optimizedPrompt = try await optimizePrompt(baseTemplate, basedOn: context)
            
            // 5. Manage context window
            let windowManagedPrompt = await contextWindowManager.optimizePrompt(optimizedPrompt, forContentLength: context.contentLength)
            
            // 6. Handle A/B testing
            let finalPrompt = await applyABTesting(to: windowManagedPrompt, contentType: contentType)
            
            // 7. Cache the result
            await cachePrompt(finalPrompt, for: contentType, contextHash: contextHash)
            
            // 8. Track usage
            await trackPromptUsage(finalPrompt.hash.description, success: true, responseTime: 0.0)
            
            // 9. Update UI
            await MainActor.run {
                lastGeneratedPrompt = createResult(from: finalPrompt, contentType: contentType, contextHash: contextHash)
            }
            
            return createResult(from: finalPrompt, contentType: contentType, contextHash: contextHash)
            
        } catch {
            await trackPromptUsage("error", success: false, responseTime: 0.0)
            throw PromptError.generationFailed(underlying: error)
        }
    }
    
    func getPromptTemplate(for contentType: ContentType, language: PromptLanguage) -> PromptTemplate {
        let basePrompt = ContentTypePromptTemplates.getTemplate(for: contentType, language: language)
        
        return PromptTemplate(
            id: "\(contentType.rawValue)_\(language.rawValue)",
            name: "\(contentType.displayName) - \(language.displayName)",
            description: "Template für \(contentType.displayName) in \(language.displayName)",
            contentType: contentType,
            language: language,
            basePrompt: basePrompt,
            parameters: getParameters(for: contentType),
            version: "1.0",
            metadata: PromptTemplateMetadata(
                createdAt: Date(),
                lastModified: Date(),
                usageCount: 0,
                averageTokens: estimateTokens(for: basePrompt),
                successRate: 0.95,
                tags: [contentType.rawValue, language.rawValue]
            )
        )
    }
    
    func optimizePrompt(_ prompt: String, basedOn context: PromptContext) async throws -> String {
        var optimizedPrompt = prompt
        
        // 1. Content-based optimization
        if context.contentLength > 2000 {
            optimizedPrompt = addChunkingInstructions(to: optimizedPrompt)
        }
        
        // 2. Language-specific optimizations
        if context.language.isGerman {
            optimizedPrompt = optimizeForGerman(optimizedPrompt)
        } else if context.language.isEnglish {
            optimizedPrompt = optimizeForEnglish(optimizedPrompt)
        }
        
        // 3. Quality-based optimization
        if context.quality.readabilityScore < 0.5 {
            optimizedPrompt = addReadabilityEnhancement(to: optimizedPrompt)
        }
        
        // 4. Urgency-based optimization
        if context.urgency.score > 0.7 {
            optimizedPrompt = addUrgencyOptimization(to: optimizedPrompt)
        }
        
        // 5. Topic-based optimization
        if !context.topics.isEmpty {
            optimizedPrompt = addTopicContext(to: optimizedPrompt, topics: context.topics)
        }
        
        return optimizedPrompt
    }
    
    // MARK: - Caching
    func cachePrompt(_ prompt: String, for contentType: ContentType, contextHash: String) async {
        await promptCache.cache(prompt, key: "\(contentType.rawValue)_\(contextHash)")
    }
    
    func getCachedPrompt(for contentType: ContentType, contextHash: String) async -> String? {
        return await promptCache.getCachedPrompt(for: "\(contentType.rawValue)_\(contextHash)")
    }
    
    // MARK: - Analytics and Tracking
    func trackPromptUsage(_ promptId: String, success: Bool, responseTime: TimeInterval) async {
        await analyticsTracker.trackUsage(promptId: promptId, success: success, responseTime: responseTime)
        await updateUsageStats()
    }
    
    func getPromptAnalytics() async -> PromptAnalytics {
        return await analyticsTracker.getAnalytics()
    }
    
    // MARK: - Custom Prompts
    func createCustomPrompt(template: CustomPromptTemplate) async throws -> String {
        // Implementation for user-defined prompt templates
        var prompt = template.basePrompt
        
        for (key, value) in template.parameters {
            prompt = prompt.replacingOccurrences(of: "{\(key)}", with: value)
        }
        
        return prompt
    }
    
    // MARK: - A/B Testing
    func getABTestPrompts(for contentType: ContentType) async -> [ABTestPrompt] {
        return await abTestManager.getPrompts(for: contentType)
    }
    
    // MARK: - Context Window Management
    func getContextWindowManager() -> ContextWindowManager {
        return contextWindowManager
    }
    
    func getMultiLanguagePrompts(for contentType: ContentType) -> [PromptLanguage: String] {
        var prompts: [PromptLanguage: String] = [:]
        
        for language in PromptLanguage.allCases {
            let template = ContentTypePromptTemplates.getTemplate(for: contentType, language: language)
            prompts[language] = template
        }
        
        return prompts
    }
    
    // MARK: - Private Methods
    private func generateContextHash(from context: PromptContext) -> String {
        let contentHash = context.content.sha256()
        let sentimentHash = "\(context.sentiment.polarity.hashValue)"
        let topicsHash = context.topics.map { $0.name }.sorted().joined(separator: ",")
        let urgencyHash = "\(context.urgency.score.rounded())"
        
        return "\(contentHash.prefix(8))_\(sentimentHash)_\(topicsHash.prefix(8))_\(urgencyHash)"
    }
    
    private func createResult(from prompt: String, contentType: ContentType, contextHash: String) -> PromptResult {
        return PromptResult(
            prompt: prompt,
            templateId: "\(contentType.rawValue)_de_v1.0",
            language: .german,
            contentType: contentType,
            contextHash: contextHash,
            version: "1.0",
            estimatedTokens: estimateTokens(for: prompt),
            generatedAt: Date()
        )
    }
    
    private func estimateTokens(for text: String) -> Int {
        // Rough estimation: 1 token ≈ 4 characters for German/English
        return Int(Double(text.count) / 4.0)
    }
    
    private func getParameters(for contentType: ContentType) -> [PromptParameter] {
        switch contentType {
        case .email:
            return [
                PromptParameter(name: "content", type: .string, required: true, description: "E-Mail-Inhalt", defaultValue: nil)
            ]
        case .meeting:
            return [
                PromptParameter(name: "content", type: .string, required: true, description: "Meeting-Protokoll", defaultValue: nil)
            ]
        case .article:
            return [
                PromptParameter(name: "content", type: .string, required: true, description: "Artikel-Inhalt", defaultValue: nil)
            ]
        case .code:
            return [
                PromptParameter(name: "content", type: .string, required: true, description: "Code-Inhalt", defaultValue: nil)
            ]
        default:
            return [
                PromptParameter(name: "content", type: .string, required: true, description: "Content-Inhalt", defaultValue: nil)
            ]
        }
    }
    
    private func applyABTesting(to prompt: String, contentType: ContentType) async -> String {
        // Check if A/B testing is enabled for this content type
        let testPrompts = await abTestManager.getPrompts(for: contentType)
        guard !testPrompts.isEmpty else { return prompt }
        
        // Select variant based on test configuration
        let selectedVariant = await abTestManager.selectVariant(for: contentType)
        
        return testPrompts.first(where: { $0.id == selectedVariant })?.prompt ?? prompt
    }
    
    // Optimization methods
    private func addChunkingInstructions(to prompt: String) -> String {
        let chunkingInstruction = """

        **Wichtiger Hinweis**: Der Inhalt ist sehr umfangreich. Bitte arbeite schrittweise und strukturiere deine Antwort übersichtlich.
        """
        return prompt + chunkingInstruction
    }
    
    private func optimizeForGerman(_ prompt: String) -> String {
        return prompt // German prompts are already optimized
    }
    
    private func optimizeForEnglish(_ prompt: String) -> String {
        return prompt // English prompts are already optimized
    }
    
    private func addReadabilityEnhancement(to prompt: String) -> String {
        let enhancement = """

        **Qualitäts-Hinweis**: Bitte verwende klare, verständliche Formulierungen und strukturiere deine Antwort gut lesbar.
        """
        return prompt + enhancement
    }
    
    private func addUrgencyOptimization(to prompt: String) -> String {
        let urgency = """

        **Prioritäts-Hinweis**: Dieser Inhalt ist zeitkritisch. Fokussiere dich besonders auf Action Items und konkrete nächste Schritte.
        """
        return prompt + urgency
    }
    
    private func addTopicContext(to prompt: String, topics: [Topic]) -> String {
        let topicNames = topics.map { $0.name }.joined(separator: ", ")
        let context = """

        **Thematischer Kontext**: Der Inhalt behandelt folgende Themen: \(topicNames). Berücksichtige dies bei deiner Analyse.
        """
        return prompt + context
    }
    
    private func setupRealTimeAnalytics() {
        NotificationCenter.default.publisher(for: .realTimeAnalysisUpdate)
            .sink { [weak self] notification in
                // Handle real-time analytics updates
            }
            .store(in: &cancellables)
    }
    
    private func startPromptOptimization() {
        Task {
            await optimizePromptsPeriodically()
        }
    }
    
    private func optimizePromptsPeriodically() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            
            // Run optimization algorithms
            await analyticsTracker.optimizePrompts()
        }
    }
    
    private func updateUsageStats() async {
        let stats = await analyticsTracker.getCurrentStats()
        await MainActor.run {
            self.promptUsageStats = stats
        }
    }
}

// MARK: - Supporting Types
struct PromptAnalytics {
    let totalPromptsGenerated: Int
    let averageResponseTime: TimeInterval
    let successRate: Double
    let mostUsedTemplates: [PromptTemplate]
    let optimizationSuggestions: [OptimizationSuggestion]
}

struct PromptUsageStats {
    let totalPrompts: Int = 0
    let todayPrompts: Int = 0
    let averageTokens: Double = 0.0
    let cacheHitRate: Double = 0.0
}

struct OptimizationSuggestion {
    let type: OptimizationType
    let description: String
    let impact: Double
    let implementation: String
    
    enum OptimizationType {
        case template, context, caching, language, structure
    }
}

enum PromptError: Error {
    case generationFailed(underlying: Error)
    case templateNotFound(ContentType)
    case optimizationFailed(underlying: Error)
    case cachingFailed(underlying: Error)
}

// MARK: - String Extension for SHA256
extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

#if canImport(CommonCrypto)
import CommonCrypto

private extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
#endif