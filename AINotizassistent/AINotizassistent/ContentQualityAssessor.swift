//
//  ContentQualityAssessor.swift
//  Content Quality Assessment
//

import Foundation
import NaturalLanguage

// MARK: - Content Quality Assessor
class ContentQualityAssessor {
    private let nlModel = NLTagger(tagSchemes: [.lexicalClass, .sentimentScore])
    
    // Grammatik- und Stilbewertung
    private let grammarRules: [GrammarRule] = [
        // Deutsche Grammatik-Regeln
        GrammarRule(
            pattern: "\\b(?:der|die|das|dem|den)\\s+\\b",
            type: .articleUsage,
            weight: 1.0,
            description: "Artikel-Verwendung prüfen"
        ),
        GrammarRule(
            pattern: "\\b\\w+\\s+(?:hat|ist|war)\\s+\\w+\\s+(?:worden|geworden|gewesen)\\b",
            type: .passiveVoice,
            weight: 0.7,
            description: "Passiv-Konstruktionen erkennen"
        ),
        GrammarRule(
            pattern: "\\b[A-Z][a-z]+\\s+\\b[A-Z][a-z]+\\b",
            type: .properNoun,
            weight: 0.8,
            description: "Eigennamen richtig geschrieben"
        ),
        
        // Satzstruktur-Regeln
        GrammarRule(
            pattern: "\\b[a-z]+\\s*,\\s*[a-z]+\\s*und\\s*[a-z]+\\b",
            type: .coordinateConjunction,
            weight: 0.6,
            description: "Satzzeichen bei Aufzählungen"
        )
    ]
    
    private let readabilityMetrics: ReadabilityMetric[] = [
        .averageSentenceLength,
        .averageWordsPerSentence,
        .complexWordsRatio,
        .monosyllabicWordsRatio,
        .fleschKincaid,
        .gunningFog
    ]
    
    private let completenessChecks: [CompletenessCheck] = [
        CompletenessCheck(
            name: "Subject-Verb-Object",
            description: "Vollständige Sätze",
            check: { text in checkSentenceCompleteness(text: text) }
        ),
        CompletenessCheck(
            name: "Context Provision",
            description: "Ausreichend Kontext",
            check: { text in checkContextProvision(text: text) }
        ),
        CompletenessCheck(
            name: "Information Density",
            description: "Informationsdichte",
            check: { text in checkInformationDensity(text: text) }
        ),
        CompletenessCheck(
            name: "Logical Flow",
            description: "Logischer Aufbau",
            check: { text in checkLogicalFlow(text: text) }
        )
    ]
    
    private let engagementMetrics: [EngagementMetric] = [
        EngagementMetric(
            name: "Active Voice Ratio",
            description: "Verhältnis aktive/passive Stimme",
            calculate: { text in calculateActiveVoiceRatio(text: text) }
        ),
        EngagementMetric(
            name: "Personal Pronouns",
            description: "Persönliche Pronomen",
            calculate: { text in countPersonalPronouns(text: text) }
        ),
        EngagementMetric(
            name: "Emotional Words",
            description: "Emotionale Wörter",
            calculate: { text in countEmotionalWords(text: text) }
        ),
        EngagementMetric(
            name: "Questions",
            description: "Fragen zur Lesereinbindung",
            calculate: { text in countQuestions(text: text) }
        ),
        EngagementMetric(
            name: "Varied Sentence Length",
            description: "Satzlängen-Variabilität",
            calculate: { text in calculateSentenceVariety(text: text) }
        )
    ]
    
    private let styleGuides: [String: StyleGuide] = [
        "de": StyleGuide(
            maxSentenceLength: 20,
            preferredSentenceLength: 15,
            avoidWords: ["überaus", "letztendlich", "im Grunde", "gewissermaßen"],
            preferredWords: ["klar", "direkt", "einfach", "deutlich"]
        ),
        "en": StyleGuide(
            maxSentenceLength: 25,
            preferredSentenceLength: 17,
            avoidWords: ["very", "really", "quite", "rather"],
            preferredWords: ["clear", "direct", "simple", "precise"]
        )
    ]
    
    init() {
        nlModel.string = ""
    }
    
    func assessQuality(text: String, language: DetectedLanguage, completion: @escaping (ContentQuality) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let quality = self.performQualityAssessment(text: text, language: language)
            DispatchQueue.main.async {
                completion(quality)
            }
        }
    }
    
    private func performQualityAssessment(text: String, language: DetectedLanguage) -> ContentQuality {
        // 1. Readability Score
        let readabilityScore = calculateReadabilityScore(text: text, language: language)
        
        // 2. Completeness Score
        let completenessScore = calculateCompletenessScore(text: text)
        
        // 3. Engagement Score
        let engagementScore = calculateEngagementScore(text: text, language: language)
        
        // 4. Grammar Score
        let grammarScore = calculateGrammarScore(text: text, language: language)
        
        // 5. Structure Score
        let structureScore = calculateStructureScore(text: text)
        
        // 6. Generate Suggestions
        let suggestions = generateQualitySuggestions(
            text: text,
            language: language,
            readabilityScore: readabilityScore,
            completenessScore: completenessScore,
            engagementScore: engagementScore,
            grammarScore: grammarScore,
            structureScore: structureScore
        )
        
        return ContentQuality(
            readabilityScore: readabilityScore,
            completenessScore: completenessScore,
            engagementScore: engagementScore,
            grammarScore: grammarScore,
            structureScore: structureScore,
            suggestions: suggestions
        )
    }
    
    private func calculateReadabilityScore(text: String, language: DetectedLanguage) -> Double {
        let sentences = splitIntoSentences(text)
        let words = tokenizeText(text, language: language)
        
        guard !sentences.isEmpty && !words.isEmpty else { return 0.0 }
        
        var score = 0.0
        
        // 1. Durchschnittliche Satzlänge (40%)
        let avgSentenceLength = Double(words.count) / Double(sentences.count)
        let lengthScore = calculateSentenceLengthScore(length: avgSentenceLength, language: language)
        score += lengthScore * 0.4
        
        // 2. Komplexitäts-Score (30%)
        let complexityScore = calculateComplexityScore(words: words, language: language)
        score += complexityScore * 0.3
        
        // 3. Flesch-Kincaid ähnlicher Score (30%)
        let fleschScore = calculateFleschLikeScore(text: text, language: language)
        score += fleschScore * 0.3
        
        return score
    }
    
    private func calculateCompletenessScore(text: String) -> Double {
        var totalScore = 0.0
        var checks = 0
        
        for check in completenessChecks {
            let checkResult = check.check(text)
            totalScore += checkResult
            checks += 1
        }
        
        return checks > 0 ? totalScore / Double(checks) : 0.0
    }
    
    private func calculateEngagementScore(text: String, language: DetectedLanguage) -> Double {
        var totalScore = 0.0
        
        for metric in engagementMetrics {
            let metricScore = metric.calculate(text)
            totalScore += metricScore
        }
        
        return totalScore / Double(engagementMetrics.count)
    }
    
    private func calculateGrammarScore(text: String, language: DetectedLanguage) -> Double {
        var totalScore = 1.0 // Start with perfect score
        var violations = 0
        
        for rule in grammarRules {
            let matches = findMatches(pattern: rule.pattern, text: text)
            if !matches.isEmpty {
                violations += matches.count
                totalScore -= rule.weight * Double(matches.count)
            }
        }
        
        // Additional grammar checks
        totalScore -= checkForCommonErrors(text: text, language: language)
        
        return max(totalScore, 0.0)
    }
    
    private func calculateStructureScore(text: String) -> Double {
        let structureAnalyzer = StructureAnalyzer()
        var structureScore = 0.0
        
        // Use existing structure analysis
        // This would be more integrated in a real implementation
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        
        // Paragraph distribution (25%)
        if paragraphs.count > 1 {
            structureScore += 0.25
        }
        
        // Sentence distribution (25%)
        let sentences = splitIntoSentences(text)
        if sentences.count > 1 {
            structureScore += 0.25
        }
        
        // Logical flow (50%)
        let flowScore = checkLogicalFlow(text: text)
        structureScore += flowScore * 0.5
        
        return structureScore
    }
    
    // MARK: - Helper Methods
    private func calculateSentenceLengthScore(length: Double, language: DetectedLanguage) -> Double {
        let styleGuide = styleGuides[language.code] ?? styleGuides["en"]!
        
        let idealLength = styleGuide.preferredSentenceLength
        let maxLength = styleGuide.maxSentenceLength
        
        // Optimal range around ideal length
        if length >= idealLength * 0.8 && length <= idealLength * 1.5 {
            return 1.0
        } else if length > idealLength && length <= maxLength {
            // Gradually decrease score for longer sentences
            return max(0.0, 1.0 - (length - idealLength) / (maxLength - idealLength) * 0.5)
        } else if length < idealLength {
            // Slight penalty for very short sentences
            return max(0.5, 1.0 - (idealLength - length) / idealLength * 0.3)
        } else {
            // Severe penalty for extremely long sentences
            return max(0.0, 0.3 - (length - maxLength) / maxLength)
        }
    }
    
    private func calculateComplexityScore(words: [String], language: DetectedLanguage) -> Double {
        let complexWords = words.filter { word in
            word.count > 6 || word.contains("-") || word.count > 8
        }
        
        let complexityRatio = Double(complexWords.count) / Double(words.count)
        
        // Sweet spot: 15-25% complex words
        if complexityRatio >= 0.15 && complexityRatio <= 0.25 {
            return 1.0
        } else if complexityRatio > 0.25 {
            return max(0.3, 1.0 - (complexityRatio - 0.25) * 2.0)
        } else {
            return max(0.5, complexityRatio / 0.15)
        }
    }
    
    private func calculateFleschLikeScore(text: String, language: DetectedLanguage) -> Double {
        let sentences = splitIntoSentences(text)
        let words = tokenizeText(text, language: language)
        let syllables = countSyllables(words: words)
        
        guard sentences.count > 0 && words.count > 0 else { return 0.0 }
        
        // Simplified Flesch formula
        let avgWordsPerSentence = Double(words.count) / Double(sentences.count)
        let avgSyllablesPerWord = Double(syllables) / Double(words.count)
        
        let fleschScore = 206.835 - 1.015 * avgWordsPerSentence - 84.6 * avgSyllablesPerWord
        
        // Normalize to 0-1 scale (Flesch scores range from 0-100 typically)
        return max(0.0, min(1.0, fleschScore / 100.0))
    }
    
    private func countSyllables(words: [String]) -> Int {
        // Simplified syllable counting - in reality this would be more sophisticated
        return words.reduce(0) { count, word in
            count + max(1, word.components(separatedBy: "aeiouAEIOU").count - 1)
        }
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        return text.components(separatedBy: .punctuationCharacters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func tokenizeText(_ text: String, language: DetectedLanguage) -> [String] {
        return text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && $0.count > 1 }
    }
    
    private func findMatches(pattern: String, text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
        
        return matches.compactMap { match in
            let range = Range(match.range, in: text)
            return range.map { String(text[$0]) }
        }
    }
    
    private func checkForCommonErrors(text: String, language: DetectedLanguage) -> Double {
        var errorPenalty = 0.0
        
        // Missing punctuation
        let sentences = splitIntoSentences(text)
        for sentence in sentences {
            if sentence.count > 50 && !sentence.hasSuffix(".") && !sentence.hasSuffix("!") && !sentence.hasSuffix("?") {
                errorPenalty += 0.1
            }
        }
        
        // Excessive repetition
        let words = tokenizeText(text, language: language)
        let wordFrequency = words.reduce(into: [String: Int]()) { dict, word in
            dict[word, default: 0] += 1
        }
        
        let maxFrequency = wordFrequency.values.max() ?? 1
        if maxFrequency > words.count / 10 {
            errorPenalty += 0.2
        }
        
        return min(errorPenalty, 1.0)
    }
    
    // MARK: - Specific Check Implementations
    private func checkSentenceCompleteness(text: String) -> Double {
        let sentences = splitIntoSentences(text)
        var completeSentences = 0
        
        for sentence in sentences {
            let words = sentence.components(separatedBy: .whitespaces)
            if words.count >= 3 && hasSubject(sentence) && hasVerb(sentence) {
                completeSentences += 1
            }
        }
        
        return sentences.isEmpty ? 0.0 : Double(completeSentences) / Double(sentences.count)
    }
    
    private func hasSubject(_ sentence: String) -> Bool {
        let pronouns = ["ich", "du", "er", "sie", "es", "wir", "ihr", "mich", "dich", "sich", "uns", "euch",
                       "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them"]
        return pronouns.contains { sentence.lowercased().contains($0) }
    }
    
    private func hasVerb(_ sentence: String) -> Bool {
        let verbs = ["ist", "hat", "war", "werden", "sein", "haben", "sein", "will", "can", "has", "was", "are", "is"]
        return verbs.contains { sentence.lowercased().contains($0) }
    }
    
    private func checkContextProvision(text: String) -> Double {
        // Check if content provides sufficient context
        let wordCount = text.components(separatedBy: .whitespaces).count
        
        if wordCount < 20 {
            return 0.3 // Too short to provide context
        } else if wordCount < 100 {
            return 0.7 // Adequate for basic context
        } else {
            return 1.0 // Sufficient context
        }
    }
    
    private func checkInformationDensity(text: String) -> Double {
        let sentences = splitIntoSentences(text)
        let words = tokenizeText(text, language: DetectedLanguage(code: "de", confidence: 1.0, isReliable: true, localizedName: "Deutsch"))
        
        let avgWordsPerSentence = Double(words.count) / Double(sentences.count)
        
        // Optimal range: 10-20 words per sentence
        if avgWordsPerSentence >= 10 && avgWordsPerSentence <= 20 {
            return 1.0
        } else {
            let deviation = abs(avgWordsPerSentence - 15) / 15
            return max(0.3, 1.0 - deviation)
        }
    }
    
    private func checkLogicalFlow(text: String) -> Double {
        let sentences = splitIntoSentences(text)
        
        // Simple coherence check based on word overlap between sentences
        var coherenceScore = 0.0
        
        for i in 0..<(sentences.count - 1) {
            let currentWords = Set(sentences[i].lowercased().components(separatedBy: .whitespaces))
            let nextWords = Set(sentences[i + 1].lowercased().components(separatedBy: .whitespaces))
            
            let overlap = currentWords.intersection(nextWords).count
            let union = currentWords.union(nextWords).count
            
            if union > 0 {
                coherenceScore += Double(overlap) / Double(union)
            }
        }
        
        return sentences.count > 1 ? coherenceScore / Double(sentences.count - 1) : 0.5
    }
    
    // MARK: - Engagement Metrics
    private func calculateActiveVoiceRatio(text: String) -> Double {
        let sentences = splitIntoSentences(text)
        var activeVoiceCount = 0
        
        for sentence in sentences {
            if isActiveVoice(sentence) {
                activeVoiceCount += 1
            }
        }
        
        return sentences.isEmpty ? 0.0 : Double(activeVoiceCount) / Double(sentences.count)
    }
    
    private func isActiveVoice(_ sentence: String) -> Bool {
        // Simplified active voice detection
        let passivePatterns = ["wurde", "ist worden", "worden", "ist gemacht", "ist getan"]
        return !passivePatterns.contains { sentence.lowercased().contains($0) }
    }
    
    private func countPersonalPronouns(text: String) -> Double {
        let germanPronouns = ["ich", "du", "er", "sie", "es", "wir", "ihr", "mich", "dich", "sich", "uns", "euch"]
        let englishPronouns = ["i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them"]
        
        let allPronouns = germanPronouns + englishPronouns
        let textLower = text.lowercased()
        
        let pronounCount = allPronouns.filter { textLower.contains($0) }.count
        let totalWords = text.components(separatedBy: .whitespaces).count
        
        return totalWords > 0 ? Double(pronounCount) / Double(totalWords) * 10 : 0.0
    }
    
    private func countEmotionalWords(text: String) -> Double {
        let emotionalWords = [
            "schön", "toll", "fantastisch", "traurig", "ärgerlich", "wunderbar",
            "beautiful", "amazing", "fantastic", "sad", "angry", "wonderful",
            "exciting", "disappointing", "thrilling", "frustrated", "delighted"
        ]
        
        let textLower = text.lowercased()
        let emotionalWordCount = emotionalWords.filter { textLower.contains($0) }.count
        let totalWords = text.components(separatedBy: .whitespaces).count
        
        return totalWords > 0 ? Double(emotionalWordCount) / Double(totalWords) * 10 : 0.0
    }
    
    private func countQuestions(text: String) -> Double {
        let questionMarks = text.components(separatedBy: "?").count - 1
        let totalSentences = splitIntoSentences(text).count
        
        return totalSentences > 0 ? Double(questionMarks) / Double(totalSentences) * 2 : 0.0
    }
    
    private func calculateSentenceVariety(text: String) -> Double {
        let sentences = splitIntoSentences(text)
        let sentenceLengths = sentences.map { $0.components(separatedBy: .whitespaces).count }
        
        guard sentenceLengths.count > 1 else { return 0.5 }
        
        let mean = sentenceLengths.reduce(0, +) / Double(sentenceLengths.count)
        let variance = sentenceLengths.reduce(0.0) { sum, length in
            sum + pow(Double(length) - mean, 2)
        } / Double(sentenceLengths.count)
        
        let standardDeviation = sqrt(variance)
        
        // Normalize standard deviation to 0-1 scale
        return min(1.0, standardDeviation / mean)
    }
    
    // MARK: - Suggestions Generation
    private func generateQualitySuggestions(
        text: String,
        language: DetectedLanguage,
        readabilityScore: Double,
        completenessScore: Double,
        engagementScore: Double,
        grammarScore: Double,
        structureScore: Double
    ) -> [ContentQuality.QualitySuggestion] {
        var suggestions: [ContentQuality.QualitySuggestion] = []
        
        // Readability suggestions
        if readabilityScore < 0.6 {
            suggestions.append(ContentQuality.QualitySuggestion(
                category: .readability,
                severity: .warning,
                message: "Text schwer zu lesen",
                suggestion: "Verwenden Sie kürzere Sätze und einfachere Wörter"
            ))
        }
        
        // Completeness suggestions
        if completenessScore < 0.7 {
            suggestions.append(ContentQuality.QualitySuggestion(
                category: .completeness,
                severity: .info,
                message: "Inhalt unvollständig",
                suggestion: "Fügen Sie mehr Details und Kontext hinzu"
            ))
        }
        
        // Engagement suggestions
        if engagementScore < 0.5 {
            suggestions.append(ContentQuality.QualitySuggestion(
                category: .engagement,
                severity: .info,
                message: "Inhalt wenig einbindend",
                suggestion: "Verwenden Sie Fragen und aktive Sprache"
            ))
        }
        
        // Grammar suggestions
        if grammarScore < 0.8 {
            suggestions.append(ContentQuality.QualitySuggestion(
                category: .grammar,
                severity: .warning,
                message: "Grammatikfehler erkannt",
                suggestion: "Überprüfen Sie Satzstruktur und Zeichensetzung"
            ))
        }
        
        // Structure suggestions
        if structureScore < 0.6 {
            suggestions.append(ContentQuality.QualitySuggestion(
                category: .structure,
                severity: .info,
                message: "Struktur verbesserungsfähig",
                suggestion: "Gliedern Sie den Text in Absätze"
            ))
        }
        
        return suggestions
    }
}

// MARK: - Supporting Data Types
struct GrammarRule {
    let pattern: String
    let type: GrammarRuleType
    let weight: Double
    let description: String
    
    enum GrammarRuleType {
        case articleUsage, passiveVoice, properNoun, coordinateConjunction, punctuation
    }
}

enum ReadabilityMetric {
    case averageSentenceLength
    case averageWordsPerSentence
    case complexWordsRatio
    case monosyllabicWordsRatio
    case fleschKincaid
    case gunningFog
}

struct CompletenessCheck {
    let name: String
    let description: String
    let check: (String) -> Double
}

struct EngagementMetric {
    let name: String
    let description: String
    let calculate: (String) -> Double
}

struct StyleGuide {
    let maxSentenceLength: Int
    let preferredSentenceLength: Int
    let avoidWords: [String]
    let preferredWords: [String]
}