//
//  NLModel.swift
//  Natural Language Model Processing
//

import Foundation
import NaturalLanguage

// MARK: - Natural Language Model
class NLModel: ObservableObject {
    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .sentimentScore, .language])
    
    // Tokenization Patterns
    private let sentencePatterns = [
        "[.!?]+",      // Standard sentence endings
        "\\.\\s+",     // Abbreviation patterns
        "\\n\\n+",     // Paragraph breaks
        "\\r\\n\\r\\n+", // Windows paragraph breaks
    ]
    
    private let wordPatterns = [
        "\\b\\w+\\b",                    // General words
        "\\b[A-Z][a-z]+\\b",            // Proper nouns
        "\\b[A-Z]{2,}\\b",              // Acronyms
        "\\b\\d+(?:\\.\\d+)?\\b",       // Numbers
        "\\b\\w+@\\w+\\.\\w+\\b",       // Email addresses
        "\\bhttps?://[^\\s]+\\b"        // URLs
    ]
    
    // Sentiment Lexicons (German & English)
    private let positiveWords = Set([
        // German
        "gut", "toll", "super", "großartig", "fantastisch", "ausgezeichnet",
        "perfekt", "schön", "freude", "glücklich", "zufrieden", "erfolgreich",
        // English
        "good", "great", "excellent", "amazing", "fantastic", "wonderful",
        "perfect", "beautiful", "happy", "joy", "satisfied", "successful"
    ])
    
    private let negativeWords = Set([
        // German
        "schlecht", "furchtbar", "schrecklich", "schlimm", "negativ",
        "traurig", "frustriert", "enttäuscht", "ärgerlich", "wütend",
        // English
        "bad", "terrible", "awful", "horrible", "negative", "sad",
        "frustrated", "disappointed", "angry", "mad"
    ])
    
    // Named Entity Patterns
    private let personPatterns = [
        "\\b[A-Z][a-z]+ [A-Z][a-z]+\\b", // First Last
        "\\b[A-Z][a-z]+\\s+von\\s+[A-Z][a-z]+\\b" // First von Last (German)
    ]
    
    private let organizationPatterns = [
        "\\b[A-Z][A-Z]+\\b(?: GmbH| AG| Inc\\.| Corp\\.| Ltd\\.| S\\.A\\.| S\\.A\\.S\\.)?",
        "\\bUniversität\\s+[A-Z][a-z]+\\b",
        "\\b[A-Z][a-z]+\\s+Universität\\b"
    ]
    
    private let locationPatterns = [
        "\\b[A-Z][a-z]+,\\s*[A-Z][a-z]+\\b", // City, Country
        "\\b[A-Z][a-z]+\\s+[A-Z][a-z]+\\s+(Straße|Str\\.|Platz|Av\\.|Road|St\\.)\\b" // Street addresses
    ]
    
    init() {
        // Initialize with empty string
        tagger.string = ""
    }
    
    // MARK: - Main Processing Methods
    func extractKeywords(from text: String, language: DetectedLanguage) -> [Keyword] {
        let tokens = tokenizeText(text)
        let positions = getWordPositions(text: text)
        
        // Extract candidate keywords
        let candidates = identifyKeywordCandidates(tokens: tokens)
        
        // Score and filter keywords
        let scoredKeywords = candidates.map { candidate in
            let score = calculateKeywordScore(candidate: candidate, tokens: tokens, positions: positions)
            let category = categorizeKeyword(candidate.term, language: language)
            
            return Keyword(
                term: candidate.term,
                relevance: score,
                frequency: candidate.frequency,
                positions: candidate.positions,
                category: category
            )
        }
        
        return scoredKeywords
            .sorted { $0.relevance > $1.relevance }
            .prefix(20) // Return top 20 keywords
            .map { $0 }
    }
    
    func analyzeSentiment(text: String) -> SentimentAnalysis {
        let words = tokenizeText(text)
        let sentimentScore = calculateSentimentScore(words: words)
        let intensity = calculateIntensity(words: words)
        let emotions = extractEmotions(words: words, text: text)
        
        let polarity = determinePolarity(score: sentimentScore)
        let confidence = calculateConfidence(words: words)
        
        return SentimentAnalysis(
            polarity: polarity,
            confidence: confidence,
            intensity: intensity,
            emotions: emotions
        )
    }
    
    func detectEntities(text: String) -> NamedEntities {
        let persons = extractPersons(text: text)
        let organizations = extractOrganizations(text: text)
        let locations = extractLocations(text: text)
        let dates = extractDates(text: text)
        
        return NamedEntities(
            persons: persons,
            organizations: organizations,
            locations: locations,
            dates: dates
        )
    }
    
    func analyzeLanguage(text: String) -> LanguageDetection {
        // Use Apple's NLTagger for language detection
        tagger.string = text
        
        let hypotheses = tagger.languageHypotheses(withMaximum: 1)
        let dominantLanguage = hypotheses.first?.key ?? NLLanguage.undetermined
        let confidence = Double(hypotheses.first?.value ?? 0.0)
        
        // Validate with statistical analysis
        let statisticalResult = detectLanguageStatistically(text: text)
        
        let finalConfidence = max(confidence, statisticalResult.confidence)
        let isReliable = finalConfidence > 0.7
        
        return LanguageDetection(
            language: dominantLanguage.rawValue,
            confidence: finalConfidence,
            isReliable: isReliable,
            alternatives: extractLanguageAlternatives(hypotheses: hypotheses)
        )
    }
    
    func extractTopics(text: String) -> [Topic] {
        let tokens = tokenizeText(text)
        let sentences = splitIntoSentences(text)
        
        // Extract candidate topics using multiple methods
        let nounPhrases = extractNounPhrases(text: text)
        let frequentTerms = extractFrequentTerms(tokens: tokens)
        let namedEntities = extractNamedEntities(text: text)
        
        var allCandidates = Set<String>()
        allCandidates.formUnion(nounPhrases)
        allCandidates.formUnion(frequentTerms)
        allCandidates.formUnion(namedEntities)
        
        // Score and categorize topics
        let topics = Array(allCandidates).map { candidate in
            let score = calculateTopicScore(topic: candidate, tokens: tokens, sentences: sentences)
            let category = categorizeTopic(candidate)
            let keywords = extractKeywordsForTopic(topic: candidate, tokens: tokens)
            
            return Topic(
                name: candidate,
                confidence: score,
                keywords: keywords,
                category: category
            )
        }
        
        return topics
            .filter { $0.confidence > 0.1 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(10) // Return top 10 topics
            .map { $0 }
    }
    
    // MARK: - Tokenization
    private func tokenizeText(_ text: String) -> [String] {
        let cleanedText = text.lowercased()
            .replacingOccurrences(of: "[^\\w\\s@\\.-]", with: " ", options: .regularExpression)
        
        return cleanedText
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && $0.count > 2 }
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        let sentenceEndings = "[.!?]+\\s+"
        let sentences = text.components(separatedBy: .punctuationCharacters)
        
        return sentences.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Keyword Processing
    private func identifyKeywordCandidates(tokens: [String]) -> [KeywordCandidate] {
        var candidateMap: [String: KeywordCandidate] = [:]
        
        for (index, token) in tokens.enumerated() {
            if candidateMap[token] == nil {
                candidateMap[token] = KeywordCandidate(term: token, frequency: 0, positions: [])
            }
            candidateMap[token]!.frequency += 1
            candidateMap[token]!.positions.append(index)
        }
        
        return Array(candidateMap.values)
    }
    
    private func calculateKeywordScore(candidate: KeywordCandidate, tokens: [String], positions: [String: [Int]]) -> Double {
        let tf = Double(candidate.frequency) / Double(tokens.count)
        
        // Position score (earlier positions are more important)
        let avgPosition = Double(candidate.positions.reduce(0, +)) / Double(candidate.positions.count)
        let positionScore = 1.0 - (avgPosition / Double(tokens.count))
        
        // Length score (prefer medium-length terms)
        let lengthScore = calculateLengthScore(term: candidate.term)
        
        return (tf * 0.5) + (positionScore * 0.3) + (lengthScore * 0.2)
    }
    
    private func calculateLengthScore(term: String) -> Double {
        let wordCount = term.components(separatedBy: .whitespaces).count
        
        switch wordCount {
        case 1: return 0.6
        case 2: return 1.0
        case 3: return 0.8
        default: return 0.4
        }
    }
    
    private func categorizeKeyword(_ term: String, language: DetectedLanguage) -> Keyword.KeywordCategory {
        let termLower = term.lowercased()
        
        // Technical terms
        let technicalTerms = [
            "api", "code", "software", "entwicklung", "programmierung", "technology", "tech",
            "function", "class", "method", "variable", "development"
        ]
        if technicalTerms.contains(termLower) {
            return .technical
        }
        
        // Business terms
        let businessTerms = [
            "business", "profit", "umsatz", "kunde", "sales", "marketing", "client",
            "revenue", "customer", "stakeholder", "strategy"
        ]
        if businessTerms.contains(termLower) {
            return .business
        }
        
        // Action words
        let actionTerms = [
            "machen", "tun", "implementieren", "entwickeln", "create", "build", "implement",
            "erstellen", "durchführen", "realisieren"
        ]
        if actionTerms.contains(termLower) {
            return .action
        }
        
        // Emotions
        let emotionTerms = [
            "gut", "schlecht", "glücklich", "traurig", "good", "bad", "happy", "sad",
            "toll", "fantastisch", "wunderbar", "schrecklich"
        ]
        if emotionTerms.contains(termLower) {
            return .emotional
        }
        
        // Organizations
        if term.contains("GmbH") || term.contains("AG") || term.contains("Inc") || 
           term.contains("Corp") || term.contains("University") || term.contains("Universität") {
            return .organization
        }
        
        // Person names (simplified)
        if term.first?.isUppercase == true && term.count > 3 && !term.contains(" ") {
            let commonWords = ["und", "oder", "aber", "denn", "sondern", "von", "zu", "in"]
            if !commonWords.contains(termLower) {
                return .person
            }
        }
        
        // Locations
        let locationTerms = [
            "Berlin", "München", "Hamburg", "Köln", "Frankfurt", "Stuttgart", "Düsseldorf",
            "New York", "London", "Paris", "Rom", "Madrid", "Wien"
        ]
        if locationTerms.contains(term) {
            return .location
        }
        
        return .other
    }
    
    private func getWordPositions(text: String) -> [String: [Int]] {
        let words = text.components(separatedBy: .whitespaces)
        var positions: [String: [Int]] = [:]
        
        for (index, word) in words.enumerated() {
            let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            positions[cleanWord, default: []].append(index)
        }
        
        return positions
    }
    
    // MARK: - Sentiment Analysis
    private func calculateSentimentScore(words: [String]) -> Double {
        var positiveCount = 0
        var negativeCount = 0
        
        for word in words {
            if positiveWords.contains(word) {
                positiveCount += 1
            }
            if negativeWords.contains(word) {
                negativeCount += 1
            }
        }
        
        let totalWords = Double(words.count)
        let positiveRatio = Double(positiveCount) / totalWords
        let negativeRatio = Double(negativeCount) / totalWords
        
        return positiveRatio - negativeRatio
    }
    
    private func determinePolarity(score: Double) -> SentimentAnalysis.SentimentPolarity {
        if score > 0.3 {
            return .veryPositive
        } else if score > 0.1 {
            return .positive
        } else if score < -0.3 {
            return .veryNegative
        } else if score < -0.1 {
            return .negative
        } else {
            return .neutral
        }
    }
    
    private func calculateIntensity(words: [String]) -> Double {
        var intensityWords = 0
        let intensifiers = [
            "sehr", "wirklich", "extrem", "total", "absolut", "überaus",
            "very", "really", "extremely", "totally", "absolutely", "quite"
        ]
        
        for word in words {
            if intensifiers.contains(word) {
                intensityWords += 1
            }
        }
        
        let intensityRatio = Double(intensityWords) / Double(words.count)
        return min(intensityRatio * 5.0, 1.0)
    }
    
    private func extractEmotions(words: [String], text: String) -> [Emotion] {
        var emotions: [Emotion] = []
        
        let emotionMapping: [String: Emotion.EmotionType] = [
            "freude": .joy, "glück": .joy, "lachen": .joy, "fröhlich": .joy,
            "trauer": .sadness, "traurig": .sadness, "kummer": .sadness, "verlust": .sadness,
            "wut": .anger, "ärger": .anger, "frustriert": .anger, "verärgert": .anger,
            "angst": .fear, "furcht": .fear, "beängstigend": .fear, "sorge": .fear,
            "überraschung": .surprise, "erstaunlich": .surprise, "unerwartet": .surprise,
            "ekel": .disgust, "abstoßend": .disgust, "widerlich": .disgust,
            "vertrauen": .trust, "zuversichtlich": .trust, "glaubwürdig": .trust,
            "erwartung": .anticipation, "hoffnung": .anticipation, "spannend": .anticipation
        ]
        
        for (keyword, emotionType) in emotionMapping {
            if text.lowercased().contains(keyword) {
                let confidence = calculateEmotionConfidence(keyword: keyword, text: text)
                emotions.append(Emotion(
                    type: emotionType,
                    confidence: confidence,
                    intensity: confidence
                ))
            }
        }
        
        return emotions
    }
    
    private func calculateEmotionConfidence(keyword: String, text: String) -> Double {
        let textLower = text.lowercased()
        let keywordCount = textLower.components(separatedBy: keyword).count - 1
        let textLength = Double(text.count)
        
        let baseConfidence = Double(keywordCount) / (textLength / 100.0)
        return min(baseConfidence, 1.0)
    }
    
    private func calculateConfidence(words: [String]) -> Double {
        let minWordsForConfidence = 10.0
        let lengthConfidence = min(Double(words.count) / minWordsForConfidence, 1.0)
        
        let totalWords = Double(words.count)
        let sentimentIndicatorCount = words.filter { positiveWords.contains($0) || negativeWords.contains($0) }.count
        let indicatorConfidence = Double(sentimentIndicatorCount) / totalWords
        
        return (lengthConfidence + indicatorConfidence) / 2.0
    }
    
    // MARK: - Named Entity Recognition
    private func extractPersons(text: String) -> [String] {
        return extractEntities(text: text, patterns: personPatterns)
    }
    
    private func extractOrganizations(text: String) -> [String] {
        return extractEntities(text: text, patterns: organizationPatterns)
    }
    
    private func extractLocations(text: String) -> [String] {
        return extractEntities(text: text, patterns: locationPatterns)
    }
    
    private func extractDates(text: String) -> [String] {
        let datePatterns = [
            "\\b\\d{1,2}\\.\\d{1,2}\\.\\d{2,4}\\b",  // DD.MM.YYYY
            "\\b\\d{1,2}\\/\\d{1,2}\\/\\d{2,4}\\b", // DD/MM/YYYY
            "\\b\\d{4}-\\d{2}-\\d{2}\\b",          // YYYY-MM-DD
            "\\b\\d{1,2}\\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{4}\\b"
        ]
        
        return extractEntities(text: text, patterns: datePatterns)
    }
    
    private func extractEntities(text: String, patterns: [String]) -> [String] {
        var entities: [String] = []
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
                
                for match in matches {
                    let range = Range(match.range, in: text)
                    if let range = range {
                        let entity = String(text[range])
                        entities.append(entity)
                    }
                }
            }
        }
        
        return Array(Set(entities)) // Remove duplicates
    }
    
    private func extractNamedEntities(text: String) -> [String] {
        let allPatterns = personPatterns + organizationPatterns + locationPatterns
        return extractEntities(text: text, patterns: allPatterns)
    }
    
    // MARK: - Language Detection
    private func detectLanguageStatistically(text: String) -> LanguageDetection {
        let words = tokenizeText(text)
        
        // Simple statistical language detection based on common words
        let germanIndicators = ["der", "die", "das", "und", "ist", "zu", "mit", "auf", "für", "von"]
        let englishIndicators = ["the", "and", "to", "of", "a", "in", "for", "is", "on", "that"]
        
        var germanScore = 0.0
        var englishScore = 0.0
        
        for word in words {
            if germanIndicators.contains(word) {
                germanScore += 1.0
            }
            if englishIndicators.contains(word) {
                englishScore += 1.0
            }
        }
        
        let totalScore = germanScore + englishScore
        let confidence = totalScore > 0 ? max(germanScore, englishScore) / totalScore : 0.5
        
        let detectedLanguage = germanScore > englishScore ? "de" : "en"
        
        return LanguageDetection(
            language: detectedLanguage,
            confidence: confidence,
            isReliable: confidence > 0.7,
            alternatives: []
        )
    }
    
    private func extractLanguageAlternatives(hypotheses: [NLLanguage: Double]) -> [LanguageDetection.Alternative] {
        return hypotheses.compactMap { language, confidence in
            LanguageDetection.Alternative(
                language: language.rawValue,
                confidence: Double(confidence)
            )
        }.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Topic Processing
    private func extractNounPhrases(text: String) -> [String] {
        tagger.string = text
        var phrases: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, tokenRange in
            if tag == .personalNamePlaceName || tag == .organizationName || tag == .numeric {
                let phrase = String(text[tokenRange])
                phrases.append(phrase)
            }
            return true
        }
        
        return phrases
    }
    
    private func extractFrequentTerms(tokens: [String]) -> [String] {
        let frequencyMap = tokens.reduce(into: [String: Int]()) { dict, token in
            dict[token, default: 0] += 1
        }
        
        return frequencyMap
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(15)
            .map { $0.key }
    }
    
    private func calculateTopicScore(topic: String, tokens: [String], sentences: [String]) -> Double {
        var score = 0.0
        
        // Term frequency
        let tokenCount = tokens.filter { topic.lowercased().contains($0.lowercased()) }.count
        let tfScore = Double(tokenCount) / Double(tokens.count)
        score += tfScore * 2.0
        
        // Position score
        var minPosition = Int.max
        sentences.enumerated().forEach { index, sentence in
            if sentence.lowercased().contains(topic.lowercased()) {
                minPosition = min(minPosition, index)
            }
        }
        
        if minPosition != Int.max {
            let positionScore = 1.0 - (Double(minPosition) / Double(sentences.count))
            score += positionScore * 1.5
        }
        
        return min(score, 1.0)
    }
    
    private func categorizeTopic(_ topic: String) -> Topic.TopicCategory {
        let topicLower = topic.lowercased()
        
        let topicMappings: [Topic.TopicCategory: [String]] = [
            .business: ["business", "unternehmen", "firma", "profit", "umsatz", "kunde", "client"],
            .technology: ["technologie", "software", "hardware", "entwicklung", "programmierung", "code", "api"],
            .health: ["gesundheit", "medizin", "medizinisch", "krankenhaus", "arzt", "patient"],
            .education: ["bildung", "schule", "universität", "lernen", "lehren", "student", "schüler"],
            .entertainment: ["unterhaltung", "film", "musik", "fernsehen", "kino", "theater", "comedy"],
            .sports: ["sport", "fußball", "tennis", "basketball", "schwimmen", "lauf", "fitness"],
            .politics: ["politik", "regierung", "partei", "wahl", "abgeordnete", "minister"],
            .science: ["wissenschaft", "forschung", "studie", "experiment", "theorie", "analyse"]
        ]
        
        for (category, keywords) in topicMappings {
            if keywords.contains(where: { topicLower.contains($0.lowercased()) }) {
                return category
            }
        }
        
        return .other
    }
    
    private func extractKeywordsForTopic(topic: String, tokens: [String]) -> [String] {
        // Find related keywords for a topic
        let relatedWords = tokens.filter { word in
            !word.isEmpty && topic.lowercased().contains(word.lowercased()) ||
            word.count > 3 // Filter out very short words
        }
        
        return Array(Set(relatedWords)).prefix(5).map { $0 }
    }
}

// MARK: - Supporting Data Types
struct NamedEntities {
    let persons: [String]
    let organizations: [String]
    let locations: [String]
    let dates: [String]
    
    var allEntities: [String] {
        return persons + organizations + locations + dates
    }
    
    var entityCount: Int {
        return allEntities.count
    }
}

struct LanguageDetection {
    let language: String
    let confidence: Double
    let isReliable: Bool
    let alternatives: [Alternative]
    
    struct Alternative {
        let language: String
        let confidence: Double
    }
}