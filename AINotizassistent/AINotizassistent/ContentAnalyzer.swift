//
//  ContentAnalyzer.swift
//  Intelligente Notizen App - Erweiterte Content-Analyse
//

import Foundation
import NaturalLanguage
import CoreML
import Combine

// MARK: - Content Analysis Engine
class ContentAnalyzer: ObservableObject {
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Double = 0.0
    @Published var currentAnalysisStep: String = ""
    
    private let nlProcessor = NLModelProcessor()
    private let sentimentAnalyzer = SentimentAnalyzer()
    private let languageDetector = LanguageDetector()
    private let topicExtractor = TopicExtractor()
    private let structureAnalyzer = StructureAnalyzer()
    private let urgencyDetector = UrgencyDetector()
    private let qualityAssessor = ContentQualityAssessor()
    private let suggestionEngine = SmartSuggestionEngine()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Sample Content for Settings Preview
    var sampleContent: String {
        return """
        Meeting with John tomorrow at 2 PM to discuss project status
        
        Agenda:
        1. Review current progress
        2. Discuss upcoming deadlines
        3. Plan next sprint
        4. Address any blockers
        
        Participants: John Doe, Jane Smith, Mike Johnson
        
        Meeting link: https://zoom.us/j/123456789
        """
    }
    
    // MARK: - Main Analysis Method
    func analyzeContent(_ text: String, completion: @escaping (ExtendedAnalysisResult) -> Void) {
        DispatchQueue.main.async {
            self.isAnalyzing = true
            self.analysisProgress = 0.0
        }
        
        let totalSteps = 9.0
        var currentStep = 0.0
        
        // Step 1: Language Detection
        currentAnalysisStep = "Sprache wird erkannt..."
        languageDetector.detectLanguage(from: text) { [weak self] language in
            currentStep += 1
            self?.updateProgress(currentStep, totalSteps)
            
            // Step 2: Sentiment Analysis
            self?.currentAnalysisStep = "Sentiment wird analysiert..."
            self?.sentimentAnalyzer.analyzeSentiment(text: text, language: language) { sentiment in
                currentStep += 1
                self?.updateProgress(currentStep, totalSteps)
                
                // Step 3: Topic Extraction
                self?.currentAnalysisStep = "Themen werden extrahiert..."
                self?.topicExtractor.extractTopics(text: text, language: language) { topics in
                    currentStep += 1
                    self?.updateProgress(currentStep, totalSteps)
                    
                    // Step 4: Structure Analysis
                    self?.currentAnalysisStep = "Struktur wird analysiert..."
                    self?.structureAnalyzer.analyzeStructure(text: text) { structure in
                        currentStep += 1
                        self?.updateProgress(currentStep, totalSteps)
                        
                        // Step 5: Content Type Classification
                        self?.currentAnalysisStep = "Content-Typ wird klassifiziert..."
                        let contentType = ContentTypeDetector.detectContentTypeConfidence(from: text)
                        currentStep += 1
                        self?.updateProgress(currentStep, totalSteps)
                        
                        // Step 6: Urgency Detection
                        self?.currentAnalysisStep = "Dringlichkeit wird bewertet..."
                        self?.urgencyDetector.detectUrgency(text: text, contentType: contentType.type) { urgency in
                            currentStep += 1
                            self?.updateProgress(currentStep, totalSteps)
                            
                            // Step 7: Quality Assessment
                            self?.currentAnalysisStep = "Qualität wird bewertet..."
                            self?.qualityAssessor.assessQuality(text: text, language: language) { quality in
                                currentStep += 1
                                self?.updateProgress(currentStep, totalSteps)
                                
                                // Step 8: Keyword Identification
                                self?.currentAnalysisStep = "Schlüsselwörter werden identifiziert..."
                                let keywords = self?.extractKeywords(text: text, language: language) ?? []
                                currentStep += 1
                                self?.updateProgress(currentStep, totalSteps)
                                
                                // Step 9: Smart Suggestions
                                self?.currentAnalysisStep = "Vorschläge werden generiert..."
                                self?.suggestionEngine.generateSuggestions(
                                    text: text,
                                    contentType: contentType.type,
                                    sentiment: sentiment,
                                    urgency: urgency,
                                    quality: quality,
                                    topics: topics,
                                    language: language
                                ) { suggestions in
                                    currentStep += 1
                                    self?.updateProgress(currentStep, totalSteps)
                                    
                                    // Final Result
                                    let result = ExtendedAnalysisResult(
                                        originalText: text,
                                        contentType: contentType.type,
                                        confidence: contentType.confidence,
                                        language: language,
                                        sentiment: sentiment,
                                        topics: topics,
                                        keywords: keywords,
                                        structure: structure,
                                        urgency: urgency,
                                        quality: quality,
                                        suggestions: suggestions,
                                        metadata: ContentTypeDetector.extractMetadata(from: text, type: contentType.type),
                                        timestamp: Date(),
                                        analysisMetadata: AnalysisMetadata(
                                            processingTime: self?.calculateProcessingTime() ?? 0.0,
                                            modelVersions: self?.getModelVersions() ?? [:]
                                        )
                                    )
                                    
                                    DispatchQueue.main.async {
                                        self?.isAnalyzing = false
                                        self?.analysisProgress = 1.0
                                    }
                                    
                                    completion(result)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateProgress(_ current: Double, _ total: Double) {
        DispatchQueue.main.async {
            self.analysisProgress = current / total
        }
    }
    
    private func extractKeywords(text: String, language: DetectedLanguage) -> [Keyword] {
        let nlModel = NLModel()
        return nlModel.extractKeywords(from: text, language: language)
    }
    
    private func calculateProcessingTime() -> Double {
        // Implementierung zur Berechnung der Verarbeitungszeit
        return 0.0
    }
    
    private func getModelVersions() -> [String: String] {
        return [
            "sentiment": "1.0",
            "language": "1.0",
            "topics": "1.0",
            "urgency": "1.0",
            "quality": "1.0"
        ]
    }
    
    // MARK: - Batch Analysis
    func analyzeBatch(_ texts: [String], completion: @escaping ([ExtendedAnalysisResult]) -> Void) {
        var results: [ExtendedAnalysisResult] = []
        let dispatchGroup = DispatchGroup()
        
        texts.forEach { text in
            dispatchGroup.enter()
            analyzeContent(text) { result in
                results.append(result)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(results)
        }
    }
    
    // MARK: - Real-time Analysis
    func analyzeInRealTime(_ text: String, publisher: PassthroughSubject<String, Never>) {
        publisher
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] updatedText in
                if updatedText.count > 10 { // Minimum text length for analysis
                    self?.analyzeContent(updatedText) { result in
                        // Send real-time updates
                        NotificationCenter.default.post(
                            name: .realTimeAnalysisUpdate,
                            object: result
                        )
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Extended Analysis Result
struct ExtendedAnalysisResult {
    let originalText: String
    let contentType: ContentType
    let confidence: Double
    let language: DetectedLanguage
    let sentiment: SentimentAnalysis
    let topics: [Topic]
    let keywords: [Keyword]
    let structure: ContentStructure
    let urgency: UrgencyLevel
    let quality: ContentQuality
    let suggestions: [SmartSuggestion]
    let metadata: [String: AnyCodable]
    let timestamp: Date
    let analysisMetadata: AnalysisMetadata
    
    // Convenience computed properties
    var readabilityScore: Double {
        return quality.readabilityScore
    }
    
    var completenessScore: Double {
        return quality.completenessScore
    }
    
    var engagementScore: Double {
        return quality.engagementScore
    }
    
    var overallQualityScore: Double {
        return (readabilityScore + completenessScore + engagementScore) / 3.0
    }
}

// MARK: - Supporting Data Types
struct DetectedLanguage {
    let code: String
    let confidence: Double
    let isReliable: Bool
    let localizedName: String
    
    var displayName: String {
        return localizedName
    }
    
    var isEnglish: Bool {
        return code.lowercased().hasPrefix("en")
    }
    
    var isGerman: Bool {
        return code.lowercased().hasPrefix("de")
    }
    
    var isMultilingual: Bool {
        return confidence < 0.7
    }
}

struct SentimentAnalysis {
    let polarity: SentimentPolarity
    let confidence: Double
    let intensity: Double
    let emotions: [Emotion]
    
    enum SentimentPolarity {
        case veryNegative, negative, neutral, positive, veryPositive
        
        var score: Double {
            switch self {
            case .veryNegative: return -1.0
            case .negative: return -0.5
            case .neutral: return 0.0
            case .positive: return 0.5
            case .veryPositive: return 1.0
            }
        }
    }
}

struct Emotion {
    let type: EmotionType
    let confidence: Double
    let intensity: Double
    
    enum EmotionType {
        case joy, sadness, anger, fear, surprise, disgust, trust, anticipation
    }
}

struct Topic {
    let name: String
    let confidence: Double
    let keywords: [String]
    let category: TopicCategory
    
    enum TopicCategory {
        case business, technology, health, education, entertainment, sports, politics, science, other
    }
}

struct Keyword {
    let term: String
    let relevance: Double
    let frequency: Int
    let positions: [Int]
    let category: KeywordCategory
    
    enum KeywordCategory {
        case technical, business, emotional, action, location, person, organization, other
    }
}

struct ContentStructure {
    let hasHeaders: Bool
    let hasLists: Bool
    let hasLinks: Bool
    let hasImages: Bool
    let hasCode: Bool
    let headerHierarchy: [HeaderLevel]
    let listTypes: [ListType]
    let paragraphCount: Int
    let sentenceCount: Int
    let wordCount: Int
    
    struct HeaderLevel {
        let level: Int
        let text: String
        let position: Int
    }
    
    enum ListType {
        case bullet, numbered, checkboxes, none
    }
}

struct UrgencyLevel {
    let level: UrgencyLevelType
    let score: Double
    let indicators: [UrgencyIndicator]
    let estimatedTimeToComplete: TimeInterval?
    
    enum UrgencyLevelType {
        case low, medium, high, critical
    }
    
    struct UrgencyIndicator {
        let type: IndicatorType
        let confidence: Double
        let description: String
        
        enum IndicatorType {
            case deadline, keywords, emotion, context, sender, subject
        }
    }
}

struct ContentQuality {
    let readabilityScore: Double
    let completenessScore: Double
    let engagementScore: Double
    let grammarScore: Double
    let structureScore: Double
    let suggestions: [QualitySuggestion]
    
    struct QualitySuggestion {
        let category: Category
        let severity: Severity
        let message: String
        let suggestion: String
        
        enum Category {
            case grammar, style, structure, completeness, engagement
        }
        
        enum Severity {
            case info, warning, error
        }
    }
}

struct SmartSuggestion {
    let type: SuggestionType
    let priority: Priority
    let title: String
    let description: String
    let action: String?
    let category: String
    
    enum SuggestionType {
        case improvement, action, format, content, structure
    }
    
    enum Priority {
        case low, medium, high, critical
    }
}

struct AnalysisMetadata {
    let processingTime: Double
    let modelVersions: [String: String]
    let timestamp: Date
}

// MARK: - Content Analysis Extensions
extension ContentAnalyzer {
    func analyzeEmail(_ text: String, completion: @escaping (EmailAnalysis) -> Void) {
        analyzeContent(text) { result in
            let emailAnalysis = EmailAnalysis(
                standardAnalysis: result,
                hasAttachments: text.contains("[Anhang]") || text.contains("[Attachment]"),
                hasRecipients: text.contains("an:") || text.contains("to:"),
                isReply: text.lowercased().contains("re:") || text.lowercased().contains("aw:"),
                isForward: text.lowercased().contains("fw:") || text.lowercased().contains("wg:"),
                replyUrgency: self.calculateReplyUrgency(from: result)
            )
            completion(emailAnalysis)
        }
    }
    
    func analyzeMeeting(_ text: String, completion: @escaping (MeetingAnalysis) -> Void) {
        analyzeContent(text) { result in
            let meetingAnalysis = MeetingAnalysis(
                standardAnalysis: result,
                meetingType: self.detectMeetingType(from: result),
                hasAgenda: result.structure.hasHeaders,
                participantCount: self.estimateParticipants(from: result),
                duration: self.estimateDuration(from: result),
                isRecurring: self.detectRecurringPattern(from: result)
            )
            completion(meetingAnalysis)
        }
    }
    
    func analyzeArticle(_ text: String, completion: @escaping (ArticleAnalysis) -> Void) {
        analyzeContent(text) { result in
            let articleAnalysis = ArticleAnalysis(
                standardAnalysis: result,
                articleType: self.detectArticleType(from: result),
                hasSource: result.keywords.contains { $0.category == .organization },
                wordCount: result.structure.wordCount,
                readingTime: self.calculateReadingTime(from: result),
                difficultyLevel: self.calculateDifficultyLevel(from: result)
            )
            completion(articleAnalysis)
        }
    }
    
    private func calculateReplyUrgency(from result: ExtendedAnalysisResult) -> Double {
        var urgencyScore = 0.0
        
        // Check for urgent keywords
        if result.keywords.contains(where: { $0.term.lowercased().contains("urgent") || $0.term.lowercased().contains("wichtig") }) {
            urgencyScore += 0.3
        }
        
        // Check sentiment for urgency
        if result.sentiment.polarity == .negative || result.sentiment.polarity == .veryNegative {
            urgencyScore += 0.2
        }
        
        // Check for question patterns
        if result.keywords.contains(where: { $0.term.contains("?") || $0.term.lowercased().contains("frage") }) {
            urgencyScore += 0.2
        }
        
        return min(urgencyScore, 1.0)
    }
    
    private func detectMeetingType(from result: ExtendedAnalysisResult) -> String {
        if result.topics.contains(where: { $0.name.lowercased().contains("projekt") }) {
            return "Projekt-Besprechung"
        } else if result.topics.contains(where: { $0.name.lowercased().contains("review") }) {
            return "Review-Meeting"
        } else if result.topics.contains(where: { $0.name.lowercased().contains("brainstorm") }) {
            return "Brainstorming"
        }
        return "Allgemeines Meeting"
    }
    
    private func estimateParticipants(from result: ExtendedAnalysisResult) -> Int {
        // Estimate based on pronouns and names
        let nameCount = result.keywords.filter { $0.category == .person }.count
        return max(nameCount + 1, 2) // At least 2 participants
    }
    
    private func estimateDuration(from result: ExtendedAnalysisResult) -> TimeInterval {
        // Estimate based on content length and complexity
        let wordCount = Double(result.structure.wordCount)
        let complexityFactor = result.overallQualityScore
        
        // Simple estimation: 100-150 words per minute
        let minutes = (wordCount / 125.0) * (1.0 / complexityFactor)
        return minutes * 60 // Convert to seconds
    }
    
    private func detectRecurringPattern(from result: ExtendedAnalysisResult) -> Bool {
        let text = result.originalText.lowercased()
        return text.contains("jeden") || text.contains("wöchentlich") || 
               text.contains("monthly") || text.contains("wöchentlich") ||
               text.contains("regelmäßig") || text.contains("recurring")
    }
    
    private func detectArticleType(from result: ExtendedAnalysisResult) -> String {
        if result.topics.contains(where: { $0.category == .news }) {
            return "Nachrichten-Artikel"
        } else if result.quality.grammarScore > 0.8 && result.structure.hasHeaders {
            return "Informational"
        } else if result.sentiment.emotions.contains(where: { $0.type == .joy }) {
            return "Lifestyle"
        }
        return "Allgemeiner Artikel"
    }
    
    private func calculateReadingTime(from result: ExtendedAnalysisResult) -> TimeInterval {
        let wordsPerMinute = 200.0 // Average reading speed
        let wordCount = Double(result.structure.wordCount)
        return (wordCount / wordsPerMinute) * 60 // Convert to seconds
    }
    
    private func calculateDifficultyLevel(from result: ExtendedAnalysisResult) -> Double {
        // Combine readability score with technical keyword density
        let readability = result.quality.readabilityScore
        let technicalDensity = Double(result.keywords.filter { $0.category == .technical }.count) / Double(result.keywords.count)
        
        // Lower score means more difficult
        return max(0.0, readability - (technicalDensity * 0.3))
    }
}

// MARK: - Specialized Analysis Types
struct EmailAnalysis {
    let standardAnalysis: ExtendedAnalysisResult
    let hasAttachments: Bool
    let hasRecipients: Bool
    let isReply: Bool
    let isForward: Bool
    let replyUrgency: Double
}

struct MeetingAnalysis {
    let standardAnalysis: ExtendedAnalysisResult
    let meetingType: String
    let hasAgenda: Bool
    let participantCount: Int
    let duration: TimeInterval
    let isRecurring: Bool
}

struct ArticleAnalysis {
    let standardAnalysis: ExtendedAnalysisResult
    let articleType: String
    let hasSource: Bool
    let wordCount: Int
    let readingTime: TimeInterval
    let difficultyLevel: Double
}

// MARK: - Notification Names
extension Notification.Name {
    static let realTimeAnalysisUpdate = Notification.Name("RealTimeAnalysisUpdate")
}

// MARK: - Natural Language Model Processor
class NLModelProcessor {
    func processText(_ text: String) -> NLModelResult {
        let recognizer = NLTagger(tagSchemes: [.nameType, .lexicalClass, .sentimentScore])
        recognizer.string = text
        
        return NLModelResult()
    }
}

struct NLModelResult {
    // Implement NL processing results
}