//
//  TopicExtractor.swift
//  Topic Extraction und Keyword-Identification
//

import Foundation
import NaturalLanguage

// MARK: - Topic Extractor
class TopicExtractor {
    private let nlModel = NLTagger(tagSchemes: [.lexicalClass, .nameType])
    
    // Topic-spezifische Keywords
    private let topicKeywords: [Topic.TopicCategory: [String]] = [
        .business: [
            "business", "unternehmen", "firma", "profit", "umsatz", "kunde", "client",
            "verkauf", "marketing", "strategie", "management", "leadership", "team",
            "meeting", "besprechung", "präsentation", "projekt", "budget", "kosten",
            "revenue", "sales", "customer", "client", "stakeholder", "board"
        ],
        .technology: [
            "technologie", "software", "hardware", "entwicklung", "programmierung",
            "code", "api", "database", "server", "cloud", "ai", "machine learning",
            "development", "programming", "coding", "framework", "library", "sdk",
            "algorithm", "data", "automation", "testing", "deployment"
        ],
        .health: [
            "gesundheit", "medizin", "medizinisch", "krankenhaus", "arzt", "patient",
            "therapie", "behandlung", "medikament", "diagnose", "symptom", "prävention",
            "health", "medical", "hospital", "doctor", "patient", "treatment",
            "medicine", "diagnosis", "symptom", "prevention", "wellness"
        ],
        .education: [
            "bildung", "schule", "universität", "lernen", "lehren", "student", "schüler",
            "kurs", "seminar", "vorlesung", "ausbildung", "studium",
            "education", "school", "university", "learning", "teaching", "student",
            "course", "training", "lesson", "curriculum", "academic"
        ],
        .entertainment: [
            "unterhaltung", "film", "musik", "fernsehen", "kino", "theater", "comedy",
            "show", "serie", "spiel", "spaß", "veranstaltung",
            "entertainment", "movie", "music", "tv", "cinema", "theatre",
            "comedy", "show", "series", "game", "fun", "event"
        ],
        .sports: [
            "sport", "fußball", "tennis", "basketball", "schwimmen", "lauf", "fitness",
            "training", "wettkampf", "verein", "tournament", "championship",
            "sports", "football", "soccer", "tennis", "basketball", "swimming",
            "running", "fitness", "training", "competition", "club", "match"
        ],
        .politics: [
            "politik", "regierung", "partei", "wahl", "abgeordnete", "minister",
            "gesetze", "entscheidung", "stimme", "demokratie",
            "politics", "government", "party", "election", "representative", "minister",
            "law", "decision", "vote", "democracy", "policy"
        ],
        .science: [
            "wissenschaft", "forschung", "studie", "experiment", "theorie", "analyse",
            "methode", "ergebnis", "daten", "publikation",
            "science", "research", "study", "experiment", "theory", "analysis",
            "method", "result", "data", "publication", "discovery"
        ]
    ]
    
    private let tfidfCalculator = TFIDFCalculator()
    private let keywordExtractor = KeywordExtractor()
    
    init() {
        // NLTagger initialisieren
        nlModel.string = ""
    }
    
    func extractTopics(text: String, language: DetectedLanguage, completion: @escaping ([Topic]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let topics = self.performTopicExtraction(text: text, language: language)
            DispatchQueue.main.async {
                completion(topics)
            }
        }
    }
    
    private func performTopicExtraction(text: String, language: DetectedLanguage) -> [Topic] {
        let tokens = tokenizeText(text, language: language)
        let sentences = splitIntoSentences(text)
        
        // Extrahiere Kandidaten-Themen
        let candidateTopics = extractCandidateTopics(tokens: tokens, sentences: sentences, language: language)
        
        // Bewerte und filtere Themen
        let scoredTopics = candidateTopics.map { topic in
            let score = calculateTopicScore(topic: topic, tokens: tokens, sentences: sentences)
            return (topic, score)
        }
        
        // Sortiere nach Score und nimm die besten
        let sortedTopics = scoredTopics
            .sorted { $0.1 > $1.1 }
            .prefix(while: { $0.1 > 0.1 }) // Threshold für relevante Themen
            .map { Topic(name: $0.0, confidence: $0.1, keywords: $0.0, category: self.categorizeTopic($0.0)) }
        
        return Array(sortedTopics)
    }
    
    private func extractCandidateTopics(tokens: [String], sentences: [String], language: DetectedLanguage) -> [String] {
        var candidates: Set<String> = []
        
        // 1. Noun Phrase Extraction mit NLTagger
        let nounPhrases = extractNounPhrases(text: sentences.joined(separator: " "))
        candidates.formUnion(nounPhrases)
        
        // 2. Frequent Term Extraction
        let frequentTerms = extractFrequentTerms(tokens: tokens, minFrequency: 2)
        candidates.formUnion(frequentTerms)
        
        // 3. Named Entity Recognition
        let namedEntities = extractNamedEntities(text: sentences.joined(separator: " "), language: language)
        candidates.formUnion(namedEntities)
        
        // 4. Collocation Detection
        let collocations = detectCollocations(tokens: tokens)
        candidates.formUnion(collocations)
        
        return Array(candidates)
    }
    
    private func extractNounPhrases(text: String) -> [String] {
        nlModel.string = text
        var nounPhrases: [String] = []
        
        nlModel.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, tokenRange in
            if tag == .personalNamePlaceName || tag == .organizationName || tag == .numeric {
                let phrase = String(text[tokenRange])
                nounPhrases.append(phrase)
            }
            return true
        }
        
        return nounPhrases
    }
    
    private func extractFrequentTerms(tokens: [String], minFrequency: Int) -> [String] {
        let frequencyMap = tokens.reduce(into: [String: Int]()) { dict, token in
            dict[token, default: 0] += 1
        }
        
        return frequencyMap
            .filter { $0.value >= minFrequency }
            .sorted { $0.value > $1.value }
            .prefix(20) // Top 20 frequent terms
            .map { $0.key }
    }
    
    private func extractNamedEntities(text: String, language: DetectedLanguage) -> [String] {
        // Vereinfachte Named Entity Recognition
        let words = text.components(separatedBy: .whitespaces)
        var entities: [String] = []
        
        // Pattern für E-Mail-Adressen
        let emailPattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        if let regex = try? NSRegularExpression(pattern: emailPattern) {
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
            for match in matches {
                let emailRange = Range(match.range, in: text)!
                entities.append(String(text[emailRange]))
            }
        }
        
        // Pattern für URLs
        let urlPattern = "https?://[^\\s]+"
        if let regex = try? NSRegularExpression(pattern: urlPattern) {
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
            for match in matches {
                let urlRange = Range(match.range, in: text)!
                entities.append(String(text[urlRange]))
            }
        }
        
        return entities
    }
    
    private func detectCollocations(tokens: [String]) -> [String] {
        var collocations: [String] = []
        
        // Bigram Collocations
        for i in 0..<(tokens.count - 1) {
            let bigram = "\(tokens[i]) \(tokens[i + 1])"
            collocations.append(bigram)
        }
        
        // Trigram Collocations
        for i in 0..<(tokens.count - 2) {
            let trigram = "\(tokens[i]) \(tokens[i + 1]) \(tokens[i + 2])"
            collocations.append(trigram)
        }
        
        return collocations
    }
    
    private func calculateTopicScore(topic: String, tokens: [String], sentences: [String]) -> Double {
        var score = 0.0
        
        // Term Frequency Score
        let tokenCount = tokens.filter { topic.lowercased().contains($0.lowercased()) }.count
        let tfScore = Double(tokenCount) / Double(tokens.count)
        score += tfScore * 2.0
        
        // Position Score (earlier mentions are more important)
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
        
        // Coherence Score (how well the topic fits with other terms)
        let coherenceScore = calculateCoherence(topic: topic, tokens: tokens)
        score += coherenceScore
        
        // Length penalty (prefer shorter, more focused topics)
        let lengthPenalty = topic.components(separatedBy: .whitespaces).count <= 4 ? 1.0 : 0.8
        score *= lengthPenalty
        
        return min(score, 1.0)
    }
    
    private func calculateCoherence(topic: String, tokens: [String]) -> Double {
        let topicWords = topic.lowercased().components(separatedBy: .whitespaces)
        var coherence = 0.0
        var pairs = 0
        
        for i in 0..<topicWords.count {
            for j in (i + 1)..<topicWords.count {
                let word1 = topicWords[i]
                let word2 = topicWords[j]
                
                // Count co-occurrences
                let coOccurrences = countCoOccurrences(word1: word1, word2: word2, tokens: tokens)
                if coOccurrences > 0 {
                    coherence += 1.0
                }
                pairs += 1
            }
        }
        
        return pairs > 0 ? coherence / Double(pairs) : 0.0
    }
    
    private func countCoOccurrences(word1: String, word2: String, tokens: [String]) -> Int {
        var count = 0
        var windowSize = 5 // Count words within a window of 5
        
        for i in 0..<(tokens.count - windowSize) {
            let window = tokens[i..<(i + windowSize)]
            if window.contains(where: { $0.lowercased() == word1 }) &&
               window.contains(where: { $0.lowercased() == word2 }) {
                count += 1
            }
        }
        
        return count
    }
    
    private func categorizeTopic(_ topic: String) -> Topic.TopicCategory {
        let topicLower = topic.lowercased()
        
        for (category, keywords) in topicKeywords {
            if keywords.contains(where: { topicLower.contains($0.lowercased()) }) {
                return category
            }
        }
        
        return .other
    }
    
    private func tokenizeText(_ text: String, language: DetectedLanguage) -> [String] {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && $0.count > 2 } // Filter out very short words
        
        return words
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        return text.components(separatedBy: .punctuationCharacters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Advanced Topic Extraction
    func extractTopicHierarchy(text: String, language: DetectedLanguage, completion: @escaping (TopicHierarchy) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let topics = self.performTopicExtraction(text: text, language: language)
            
            // Erstelle Hierarchie basierend auf Kategorien
            let hierarchy = TopicHierarchy(
                primaryTopics: topics.filter { $0.confidence > 0.7 },
                secondaryTopics: topics.filter { $0.confidence > 0.3 && $0.confidence <= 0.7 },
                emergingTopics: topics.filter { $0.confidence <= 0.3 },
                topicRelationships: self.calculateTopicRelationships(topics: topics)
            )
            
            DispatchQueue.main.async {
                completion(hierarchy)
            }
        }
    }
    
    private func calculateTopicRelationships(topics: [Topic]) -> [TopicRelationship] {
        var relationships: [TopicRelationship] = []
        
        for i in 0..<topics.count {
            for j in (i + 1)..<topics.count {
                let topic1 = topics[i]
                let topic2 = topics[j]
                
                // Berechne Ähnlichkeit zwischen Themen
                let similarity = calculateTopicSimilarity(topic1: topic1, topic2: topic2)
                
                if similarity > 0.3 {
                    relationships.append(TopicRelationship(
                        topic1: topic1,
                        topic2: topic2,
                        similarity: similarity,
                        relationshipType: .related
                    ))
                }
            }
        }
        
        return relationships
    }
    
    private func calculateTopicSimilarity(topic1: Topic, topic2: Topic) -> Double {
        let keywords1 = Set(topic1.keywords.map { $0.lowercased() })
        let keywords2 = Set(topic2.keywords.map { $0.lowercased() })
        
        let intersection = keywords1.intersection(keywords2)
        let union = keywords1.union(keywords2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    func trackTopicEvolution(texts: [String], language: DetectedLanguage, completion: @escaping (TopicEvolution) -> Void) {
        var evolutionStages: [TopicEvolutionStage] = []
        
        for (index, text) in texts.enumerated() {
            let topics = performTopicExtraction(text: text, language: language)
            
            evolutionStages.append(TopicEvolutionStage(
                stageIndex: index,
                text: text,
                topics: topics,
                dominantTopic: topics.first,
                topicDistribution: calculateTopicDistribution(topics: topics)
            ))
        }
        
        let evolution = TopicEvolution(stages: evolutionStages)
        completion(evolution)
    }
    
    private func calculateTopicDistribution(topics: [Topic]) -> [String: Double] {
        let totalConfidence = topics.map { $0.confidence }.reduce(0, +)
        var distribution: [String: Double] = [:]
        
        for topic in topics {
            distribution[topic.name] = topic.confidence / totalConfidence
        }
        
        return distribution
    }
}

// MARK: - Supporting Components
class TFIDFCalculator {
    func calculateTFIDF(documents: [[String]]) -> [[String: Double]] {
        let vocabulary = Set(documents.flatMap { $0 })
        var tfidfResults: [[String: Double]] = []
        
        for document in documents {
            let termFrequencies = calculateTermFrequencies(terms: document)
            let idfScores = calculateIDFScores(documents: documents, vocabulary: vocabulary)
            let tfidfScores = calculateTFIDFScores(tf: termFrequencies, idf: idfScores)
            tfidfResults.append(tfidfScores)
        }
        
        return tfidfResults
    }
    
    private func calculateTermFrequencies(terms: [String]) -> [String: Double] {
        let totalTerms = Double(terms.count)
        var frequencies: [String: Double] = [:]
        
        for term in terms {
            frequencies[term, default: 0] += 1.0
        }
        
        for term in frequencies.keys {
            frequencies[term] = frequencies[term]! / totalTerms
        }
        
        return frequencies
    }
    
    private func calculateIDFScores(documents: [[String]], vocabulary: Set<String>) -> [String: Double] {
        var idfScores: [String: Double] = [:]
        let totalDocuments = Double(documents.count)
        
        for term in vocabulary {
            let documentFrequency = Double(documents.filter { $0.contains(term) }.count)
            idfScores[term] = log(totalDocuments / (1.0 + documentFrequency))
        }
        
        return idfScores
    }
    
    private func calculateTFIDFScores(tf: [String: Double], idf: [String: Double]) -> [String: Double] {
        var tfidfScores: [String: Double] = [:]
        
        for term in tf.keys {
            tfidfScores[term] = tf[term]! * (idf[term] ?? 0.0)
        }
        
        return tfidfScores
    }
}

class KeywordExtractor {
    func extractKeywords(text: String, language: DetectedLanguage, maxKeywords: Int = 10) -> [Keyword] {
        let tokens = tokenizeText(text, language: language)
        let positions = getWordPositions(text: text)
        
        let keywordCandidates = identifyKeywordCandidates(tokens: tokens)
        let scoredKeywords = keywordCandidates.map { candidate in
            let score = calculateKeywordScore(candidate: candidate, tokens: tokens, positions: positions)
            let category = categorizeKeyword(candidate.term)
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
            .prefix(maxKeywords)
            .map { $0 }
    }
    
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
        // TF-IDF Score (vereinfacht)
        let tf = Double(candidate.frequency) / Double(tokens.count)
        
        // Position Score (earlier positions are more important)
        let avgPosition = Double(candidate.positions.reduce(0, +)) / Double(candidate.positions.count)
        let positionScore = 1.0 - (avgPosition / Double(tokens.count))
        
        // Length Score (prefer medium-length terms)
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
    
    private func categorizeKeyword(_ term: String) -> Keyword.KeywordCategory {
        let termLower = term.lowercased()
        
        // Technical terms
        let technicalTerms = ["api", "code", "software", "entwicklung", "programmierung", "technology", "tech"]
        if technicalTerms.contains(termLower) {
            return .technical
        }
        
        // Business terms
        let businessTerms = ["business", "profit", "umsatz", "kunde", "sales", "marketing"]
        if businessTerms.contains(termLower) {
            return .business
        }
        
        // Action words
        let actionTerms = ["machen", "tun", "implementieren", "entwickeln", "create", "build", "implement"]
        if actionTerms.contains(termLower) {
            return .action
        }
        
        // Emotions
        let emotionTerms = ["gut", "schlecht", "glücklich", "traurig", "good", "bad", "happy", "sad"]
        if emotionTerms.contains(termLower) {
            return .emotional
        }
        
        // Organizations (simplified)
        if term.contains(" GmbH") || term.contains(" AG") || term.contains(" Inc") || term.contains(" Corp") {
            return .organization
        }
        
        // Person names (simplified)
        if term.first?.isUppercase == true && term.count > 3 {
            return .person
        }
        
        // Locations (simplified)
        let locationTerms = ["Berlin", "München", "Hamburg", "Köln", "Frankfurt", "New York", "London", "Paris"]
        if locationTerms.contains(term) {
            return .location
        }
        
        return .other
    }
    
    private func tokenizeText(_ text: String, language: DetectedLanguage) -> [String] {
        return text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && $0.count > 2 }
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
}

// MARK: - Supporting Data Types
struct KeywordCandidate {
    let term: String
    var frequency: Int
    var positions: [Int]
}

struct TopicHierarchy {
    let primaryTopics: [Topic]
    let secondaryTopics: [Topic]
    let emergingTopics: [Topic]
    let topicRelationships: [TopicRelationship]
}

struct TopicRelationship {
    let topic1: Topic
    let topic2: Topic
    let similarity: Double
    let relationshipType: RelationshipType
    
    enum RelationshipType {
        case similar, related, opposing, hierarchical
    }
}

struct TopicEvolution {
    let stages: [TopicEvolutionStage]
}

struct TopicEvolutionStage {
    let stageIndex: Int
    let text: String
    let topics: [Topic]
    let dominantTopic: Topic?
    let topicDistribution: [String: Double]
}