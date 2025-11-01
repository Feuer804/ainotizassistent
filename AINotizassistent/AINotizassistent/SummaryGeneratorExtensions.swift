//
//  SummaryGeneratorExtensions.swift
//  Intelligente Notizen App - Extensions und Utilities
//

import Foundation
import SwiftUI
import Combine

// MARK: - SummaryGenerator+Extensions
extension SummaryGenerator {
    
    // MARK: - Convenience Methods für verschiedene Content-Typen
    func generateEmailSummary(
        from emailText: String,
        format: SummaryFormat = .medium,
        completion: @escaping (GeneratedSummary) -> Void
    ) {
        generateSummary(
            from: emailText,
            format: format,
            contentType: .email,
            options: SummaryOptions(
                includeHighlights: true,
                includeMetadata: true,
                includeConfidence: true,
                prioritizeActionItems: true,
                includeRelatedThemes: false
            ),
            completion: completion
        )
    }
    
    func generateMeetingSummary(
        from meetingText: String,
        format: SummaryFormat = .detailed,
        completion: @escaping (GeneratedSummary) -> Void
    ) {
        generateSummary(
            from: meetingText,
            format: format,
            contentType: .meeting,
            options: SummaryOptions(
                includeHighlights: true,
                includeMetadata: true,
                includeConfidence: true,
                prioritizeActionItems: true,
                includeRelatedThemes: true
            ),
            completion: completion
        )
    }
    
    func generateArticleSummary(
        from articleText: String,
        format: SummaryFormat = .medium,
        completion: @escaping (GeneratedSummary) -> Void
    ) {
        generateSummary(
            from: articleText,
            format: format,
            contentType: .article,
            options: SummaryOptions(
                includeHighlights: true,
                includeMetadata: true,
                includeConfidence: true,
                prioritizeActionItems: false,
                includeRelatedThemes: true
            ),
            completion: completion
        )
    }
    
    // MARK: - Quick Summary Methods
    func generateQuickSummary(
        from text: String,
        maxWords: Int = 50,
        completion: @escaping (String) -> Void
    ) {
        generateSummary(
            from: text,
            format: .short,
            options: SummaryOptions(customWordLimit: maxWords)
        ) { summary in
            completion(summary.summaryText)
        }
    }
    
    func generateBulletPointSummary(
        from text: String,
        maxPoints: Int = 5,
        completion: @escaping ([BulletPoint]) -> Void
    ) {
        generateSummary(
            from: text,
            format: .medium,
            options: SummaryOptions(customWordLimit: maxPoints * 15)
        ) { summary in
            completion(summary.bulletPoints.prefix(maxPoints).map { $0 })
        }
    }
    
    // MARK: - Batch Processing für verschiedene Formate
    func generateMultipleFormats(
        from text: String,
        contentType: ContentType? = nil,
        completion: @escaping ([SummaryFormat: GeneratedSummary]) -> Void
    ) {
        var results: [SummaryFormat: GeneratedSummary] = [:]
        let dispatchGroup = DispatchGroup()
        
        SummaryFormat.allCases.forEach { format in
            dispatchGroup.enter()
            generateSummary(
                from: text,
                format: format,
                contentType: contentType
            ) { summary in
                results[format] = summary
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(results)
        }
    }
    
    // MARK: - Smart Summary mit AI-Enhancement
    func generateSmartSummary(
        from text: String,
        preferences: UserSummaryPreferences = UserSummaryPreferences(),
        completion: @escaping (GeneratedSummary) -> Void
    ) {
        // Erste Analyse ohne spezifischen Content-Type
        contentAnalyzer.analyzeContent(text) { analysis in
            let detectedContentType = analysis.contentType
            
            // Anpassung der Optionen basierend auf Benutzerpräferenzen
            let smartOptions = SummaryOptions(
                includeHighlights: preferences.includeHighlights,
                includeMetadata: preferences.includeMetadata,
                includeConfidence: preferences.includeConfidence,
                prioritizeActionItems: preferences.prioritizeActions,
                includeRelatedThemes: preferences.includeRelatedThemes,
                languageSpecific: preferences.useLanguageSpecific,
                maxHighlights: preferences.maxHighlights,
                customWordLimit: preferences.customWordLimit
            )
            
            // Intelligente Format-Auswahl basierend auf Text-Länge und -Komplexität
            let intelligentFormat = self.selectOptimalFormat(
                for: text,
                analysis: analysis,
                userPreference: preferences.preferredFormat
            )
            
            generateSummary(
                from: text,
                format: intelligentFormat,
                contentType: detectedContentType,
                options: smartOptions,
                completion: completion
            )
        }
    }
    
    private func selectOptimalFormat(
        for text: String,
        analysis: ExtendedAnalysisResult,
        userPreference: SummaryFormat?
    ) -> SummaryFormat {
        // Wenn Benutzer eine Präferenz hat, diese respektieren
        if let userPref = userPreference {
            return userPref
        }
        
        // Intelligente Auswahl basierend auf Text-Charakteristika
        let wordCount = analysis.structure.wordCount
        let complexity = analysis.overallQualityScore
        
        switch (wordCount, complexity) {
        case (0..<100, _):
            return .short
        case (100..<500, 0.8...1.0):
            return .detailed
        case (100..<500, _):
            return .medium
        case (500..., _):
            return .detailed
        default:
            return .medium
        }
    }
}

// MARK: - User Summary Preferences
struct UserSummaryPreferences {
    var preferredFormat: SummaryFormat?
    var includeHighlights: Bool = true
    var includeMetadata: Bool = true
    var includeConfidence: Bool = true
    var prioritizeActions: Bool = false
    var includeRelatedThemes: Bool = true
    var useLanguageSpecific: Bool = true
    var maxHighlights: Int = 10
    var customWordLimit: Int?
    var autoAdjustLength: Bool = true
    var preferBulletPoints: Bool = false
    var includeReadingTime: Bool = true
    
    //Preset-Konfigurationen
    static let business = UserSummaryPreferences(
        preferredFormat: .medium,
        prioritizeActions: true,
        includeRelatedThemes: false,
        preferBulletPoints: true
    )
    
    static let academic = UserSummaryPreferences(
        preferredFormat: .detailed,
        includeHighlights: true,
        includeMetadata: true,
        includeRelatedThemes: true,
        maxHighlights: 15
    )
    
    static let quick = UserSummaryPreferences(
        preferredFormat: .short,
        includeHighlights: false,
        includeMetadata: false,
        maxHighlights: 5
    )
}

// MARK: - Summary Analysis & Comparison
extension SummaryGenerator {
    
    // MARK: - Summary Comparison
    func compareSummaries(
        _ summary1: GeneratedSummary,
        _ summary2: GeneratedSummary,
        completion: @escaping (SummaryComparison) -> Void
    ) {
        let comparison = SummaryComparison(
            summary1: summary1,
            summary2: summary2,
            qualityComparison: compareQuality(summary1.confidence, summary2.confidence),
            coverageComparison: compareCoverage(summary1, summary2),
            readabilityComparison: compareReadability(summary1, summary2),
            recommendations: generateRecommendations(summary1, summary2)
        )
        
        completion(comparison)
    }
    
    private func compareQuality(_ quality1: SummaryConfidence, _ quality2: SummaryConfidence) -> QualityComparison {
        return QualityComparison(
            overallWinner: quality1.overallScore > quality2.overallScore ? .first : .second,
            coherenceComparison: compareMetric(quality1.coherenceScore, quality2.coherenceScore),
            completenessComparison: compareMetric(quality1.completenessScore, quality2.completenessScore),
            accuracyComparison: compareMetric(quality1.accuracyScore, quality2.accuracyScore)
        )
    }
    
    private func compareMetric(_ metric1: Double, _ metric2: Double) -> String {
        let diff = abs(metric1 - metric2)
        switch diff {
        case 0..<0.1:
            return "Gleichwertig"
        case 0.1..<0.3:
            return metric1 > metric2 ? "Besser" : "Schlechter"
        default:
            return metric1 > metric2 ? "Deutlich besser" : "Deutlich schlechter"
        }
    }
    
    private func compareCoverage(_ summary1: GeneratedSummary, _ summary2: GeneratedSummary) -> CoverageComparison {
        // Simple word overlap analysis
        let words1 = Set(summary1.summaryText.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(summary2.summaryText.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let overlap = words1.intersection(words2)
        let totalWords = words1.union(words2)
        
        let overlapPercentage = Double(overlap.count) / Double(totalWords.count)
        
        return CoverageComparison(
            overlapPercentage: overlapPercentage,
            uniqueContent1: words1.subtracting(words2),
            uniqueContent2: words2.subtracting(words1),
            recommendation: overlapPercentage > 0.7 ? "Hohe Ähnlichkeit" : "Verschiedene Perspektiven"
        )
    }
    
    private func compareReadability(_ summary1: GeneratedSummary, _ summary2: GeneratedSummary) -> ReadabilityComparison {
        // Simplified readability comparison
        return ReadabilityComparison(
            wordCountComparison: summary1.wordCount > summary2.wordCount ? "Länger" : "Kürzer",
            sentenceComplexity1: calculateSentenceComplexity(summary1.summaryText),
            sentenceComplexity2: calculateSentenceComplexity(summary2.summaryText),
            betterForQuickReading: summary1.readingTime < summary2.readingTime ? .first : .second
        )
    }
    
    private func calculateSentenceComplexity(_ text: String) -> Double {
        let sentences = text.components(separatedBy: .punctuationCharacters).filter { !$0.isEmpty }
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        guard !sentences.isEmpty && !words.isEmpty else { return 0 }
        
        let avgWordsPerSentence = Double(words.count) / Double(sentences.count)
        
        // Lower score = more complex (longer sentences)
        return max(0, 1.0 - (avgWordsPerSentence / 20.0))
    }
    
    private func generateRecommendations(_ summary1: GeneratedSummary, _ summary2: GeneratedSummary) -> [String] {
        var recommendations: [String] = []
        
        // Quality-based recommendations
        if summary1.confidence.overallScore > summary2.confidence.overallScore + 0.2 {
            recommendations.append("Die erste Zusammenfassung zeigt deutlich höhere Qualität")
        }
        
        // Length-based recommendations
        if abs(summary1.wordCount - summary2.wordCount) > 100 {
            let longer = summary1.wordCount > summary2.wordCount ? summary1 : summary2
            recommendations.append("Die längere Zusammenfassung (\(longer.format.rawValue)) bietet mehr Details")
        }
        
        // Format-based recommendations
        if summary1.format != summary2.format {
            recommendations.append("Verschiedene Formate eignen sich für unterschiedliche Verwendungszwecke")
        }
        
        return recommendations
    }
}

// MARK: - Comparison Result Structures
struct SummaryComparison {
    let summary1: GeneratedSummary
    let summary2: GeneratedSummary
    let qualityComparison: QualityComparison
    let coverageComparison: CoverageComparison
    let readabilityComparison: ReadabilityComparison
    let recommendations: [String]
}

struct QualityComparison {
    enum Winner { case first, second }
    
    let overallWinner: Winner
    let coherenceComparison: String
    let completenessComparison: String
    let accuracyComparison: String
}

struct CoverageComparison {
    let overlapPercentage: Double
    let uniqueContent1: Set<String>
    let uniqueContent2: Set<String>
    let recommendation: String
}

struct ReadabilityComparison {
    enum BetterForReading { case first, second }
    
    let wordCountComparison: String
    let sentenceComplexity1: Double
    let sentenceComplexity2: Double
    let betterForQuickReading: BetterForReading
}

// MARK: - Export & Sharing Extensions
extension GeneratedSummary {
    
    // MARK: - Export to different formats
    var markdownExport: String {
        var markdown = """
        # Zusammenfassung (\(format.rawValue))
        
        **Content-Typ:** \(contentType.rawValue)
        **Sprache:** \(language.displayName)
        **Qualität:** \(qualityLevel)
        
        """
        
        markdown += "## Zusammenfassung\n\n\(summaryText)\n\n"
        
        if !bulletPoints.isEmpty {
            markdown += "## Wichtige Punkte\n\n"
            for point in bulletPoints {
                markdown += "- **\(point.priority.rawValue):** \(point.text)\n"
            }
            markdown += "\n"
        }
        
        if !keyPhrases.isEmpty {
            markdown += "## Schlüsselphrasen\n\n"
            for phrase in keyPhrases {
                markdown += "- \(phrase.phrase) (\(Int(phrase.confidence * 100))%)\n"
            }
            markdown += "\n"
        }
        
        if !highlights.isEmpty {
            markdown += "## Highlights\n\n"
            for highlight in highlights {
                markdown += "- \(highlight.text)\n"
            }
            markdown += "\n"
        }
        
        markdown += """
        ## Metadaten
        
        - **Wortanzahl:** \(wordCount)
        - **Lesezeit:** \(Int(readingTime / 60)) Minuten
        - **Verarbeitungszeit:** \(String(format: "%.2f", processingTime)) Sekunden
        - **Qualitätsscore:** \(Int(confidence.overallScore * 100))%
        
        """
        
        return markdown
    }
    
    var plainTextExport: String {
        var text = """
        Zusammenfassung (\(format.rawValue))
        Content-Typ: \(contentType.rawValue)
        Qualität: \(qualityLevel)
        
        \(summaryText)
        
        """
        
        if !bulletPoints.isEmpty {
            text += "\nWichtige Punkte:\n"
            for point in bulletPoints {
                text += "• [\(point.priority.rawValue)] \(point.text)\n"
            }
        }
        
        if !keyPhrases.isEmpty {
            text += "\nSchlüsselphrasen:\n"
            for phrase in keyPhrases {
                text += "• \(phrase.phrase) (\(Int(phrase.confidence * 100))%)\n"
            }
        }
        
        text += "\nStatistiken:\n"
        text += "• Wortanzahl: \(wordCount)\n"
        text += "• Lesezeit: \(Int(readingTime / 60)) Minuten\n"
        text += "• Qualitätsscore: \(Int(confidence.overallScore * 100))%"
        
        return text
    }
    
    var jsonExport: [String: Any] {
        return [
            "summary": summaryText,
            "contentType": contentType.rawValue,
            "format": format.rawValue,
            "language": language.displayName,
            "qualityLevel": qualityLevel,
            "wordCount": wordCount,
            "readingTime": readingTime,
            "processingTime": processingTime,
            "confidence": confidence.overallScore,
            "bulletPoints": bulletPoints.map { [
                "text": $0.text,
                "priority": $0.priority.rawValue,
                "category": $0.category,
                "confidence": $0.confidence,
                "actionRequired": $0.actionRequired
            ]},
            "keyPhrases": keyPhrases.map { [
                "phrase": $0.phrase,
                "confidence": $0.confidence,
                "relevance": $0.relevance,
                "category": $0.category.rawValue
            ]},
            "highlights": highlights.map { [
                "text": $0.text,
                "confidence": $0.confidence,
                "category": $0.category,
                "relevance": $0.relevance
            ]}
        ]
    }
}

// MARK: - Summary Statistics & Analytics
extension GeneratedSummary {
    
    var summaryStatistics: SummaryStatistics {
        return SummaryStatistics(
            complexityScore: calculateComplexityScore(),
            informationDensity: calculateInformationDensity(),
            keywordCoverage: calculateKeywordCoverage(),
            readabilityLevel: determineReadabilityLevel(),
            suitabilityForAI: calculateAISuitability()
        )
    }
    
    private func calculateComplexityScore() -> Double {
        let sentences = summaryText.components(separatedBy: .punctuationCharacters).filter { !$0.isEmpty }
        let words = summaryText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        guard !sentences.isEmpty && !words.isEmpty else { return 0 }
        
        let avgWordsPerSentence = Double(words.count) / Double(sentences.count)
        let uniqueWordRatio = Double(Set(words.map { $0.lowercased() }).count) / Double(words.count)
        
        // Combine sentence length and vocabulary diversity
        let complexity = (avgWordsPerSentence / 20.0) + (1.0 - uniqueWordRatio)
        return min(1.0, complexity / 2.0)
    }
    
    private func calculateInformationDensity() -> Double {
        let sentences = summaryText.components(separatedBy: .punctuationCharacters).filter { !$0.isEmpty }
        let words = summaryText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        guard !sentences.isEmpty else { return 0 }
        
        // Information density = key information / total length
        let keyInfoCount = keyPhrases.count + bulletPoints.count
        let totalLength = words.count
        
        return min(1.0, Double(keyInfoCount) / Double(totalLength) * 100)
    }
    
    private func calculateKeywordCoverage() -> Double {
        // How well does the summary cover the original keywords
        guard !originalText.isEmpty else { return 0 }
        
        let originalKeywords = Set(originalText.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let summaryWords = Set(summaryText.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let coverage = originalKeywords.intersection(summaryWords)
        return Double(coverage.count) / Double(originalKeywords.count)
    }
    
    private func determineReadabilityLevel() -> String {
        let sentences = summaryText.components(separatedBy: .punctuationCharacters).filter { !$0.isEmpty }
        let words = summaryText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        guard !sentences.isEmpty && !words.isEmpty else { return "Unbekannt" }
        
        let avgWordsPerSentence = Double(words.count) / Double(sentences.count)
        let avgSyllables = estimateSyllables(from: summaryText) / Double(words.count)
        
        // Simplified readability scoring (similar to Flesch Reading Ease)
        let score = 206.835 - (1.015 * avgWordsPerSentence) - (84.6 * avgSyllables)
        
        if score >= 90 {
            return "Sehr einfach"
        } else if score >= 80 {
            return "Einfach"
        } else if score >= 70 {
            return "Leicht verständlich"
        } else if score >= 60 {
            return "Verständlich"
        } else if score >= 50 {
            return "Mäßig verständlich"
        } else if score >= 30 {
            return "Schwer verständlich"
        } else {
            return "Sehr schwer"
        }
    }
    
    private func estimateSyllables(from text: String) -> Int {
        // Simplified syllable estimation
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.reduce(0) { total, word in
            let vowels = word.lowercased().filter { "aeiou".contains($0) }.count
            return total + max(1, vowels)
        }
    }
    
    private func calculateAISuitability() -> Double {
        // How well suited is this summary for AI processing
        var score = 0.0
        
        // Structured content (bullet points) improves AI suitability
        score += Double(bulletPoints.count) * 0.1
        
        // Clear key phrases help
        score += Double(keyPhrases.filter { $0.confidence > 0.7 }.count) * 0.05
        
        // Balanced length is good for AI processing
        if wordCount.between(50, 200) {
            score += 0.3
        } else if wordCount.between(25, 400) {
            score += 0.2
        }
        
        // High confidence improves suitability
        score += confidence.overallScore * 0.3
        
        return min(1.0, score)
    }
}

struct SummaryStatistics {
    let complexityScore: Double
    let informationDensity: Double
    let keywordCoverage: Double
    let readabilityLevel: String
    let suitabilityForAI: Double
    
    var overallScore: Double {
        return (complexityScore + informationDensity + keywordCoverage + suitabilityForAI) / 4.0
    }
}

// MARK: - Utility Extensions
extension Int {
    func between(_ lower: Int, _ upper: Int) -> Bool {
        return self >= lower && self <= upper
    }
}