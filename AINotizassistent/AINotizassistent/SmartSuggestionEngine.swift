//
//  SmartSuggestionEngine.swift
//  Smart Suggestions für Content Improvements
//

import Foundation
import NaturalLanguage

// MARK: - Smart Suggestion Engine
class SmartSuggestionEngine {
    private let nlModel = NLTagger(tagSchemes: [.lexicalClass, .nameType])
    
    // Suggestion Templates für verschiedene Content-Typen
    private let suggestionTemplates: [ContentType: [SuggestionTemplate]] = [
        .email: [
            SuggestionTemplate(
                category: "structure",
                priority: .high,
                trigger: { analysis in analysis.structure.hasHeaders == false },
                message: "Betreff-Format fehlt",
                suggestion: "Verwenden Sie einen klaren Betreff wie '[Eilmeldung] [Thema]'",
                action: "addSubject",
                example: "Betreff: Status-Update Projekt X"
            ),
            SuggestionTemplate(
                category: "format",
                priority: .medium,
                trigger: { analysis in analysis.sentiment.polarity == .negative },
                message: "Höfliche Formulierung empfohlen",
                suggestion: "Verwenden Sie 'könnten Sie bitte' anstelle von direkten Aufforderungen",
                action: "improveTone",
                example: "Könnten Sie mir bitte bis morgen das Dokument zusenden?"
            )
        ],
        .meeting: [
            SuggestionTemplate(
                category: "structure",
                priority: .high,
                trigger: { analysis in !analysis.structure.hasLists },
                message: "Agenda fehlt",
                suggestion: "Erstellen Sie eine Agenda mit Aufzählungspunkten",
                action: "addAgenda",
                example: "1. Projekt-Status\n2. Probleme\n3. Nächste Schritte"
            ),
            SuggestionTemplate(
                category: "structure",
                priority: .medium,
                trigger: { analysis in analysis.structure.headerHierarchy.isEmpty },
                message: "Überschriften fehlen",
                suggestion: "Gliedern Sie das Protokoll mit Überschriften",
                action: "addHeaders",
                example: "## Teilnehmer\n## Beschlüsse\n## Nächste Schritte"
            )
        ],
        .article: [
            SuggestionTemplate(
                category: "structure",
                priority: .high,
                trigger: { analysis in analysis.structure.headerHierarchy.count < 2 },
                message: "Mehr Überschriften nötig",
                suggestion: "Verwenden Sie Zwischenüberschriften zur besseren Lesbarkeit",
                action: "addSubheadings",
                example: "## Hintergrund\n## Aktuelle Situation\n## Fazit"
            ),
            SuggestionTemplate(
                category: "content",
                priority: .medium,
                trigger: { analysis in analysis.sentiment.emotions.isEmpty },
                message: "Fehlende emotionale Bindung",
                suggestion: "Fügen Sie persönliche Erfahrungen oder Beispiele hinzu",
                action: "addExamples",
                example: "Ein konkretes Beispiel aus der Praxis..."
            )
        ],
        .task: [
            SuggestionTemplate(
                category: "action",
                priority: .high,
                trigger: { analysis in !analysis.originalText.lowercased().contains("bis") && !analysis.originalText.lowercased().contains("deadline") },
                message: "Deadline fehlt",
                suggestion: "Fügen Sie ein konkretes Fälligkeitsdatum hinzu",
                action: "addDeadline",
                example: "Bis: Freitag, 15.11.2024"
            ),
            SuggestionTemplate(
                category: "structure",
                priority: .medium,
                trigger: { analysis in analysis.structure.hasLists == false },
                message: "Aufgabenliste fehlt",
                suggestion: "Verwenden Sie eine Checkliste für bessere Übersicht",
                action: "addChecklist",
                example: "- [ ] Dokument erstellen\n- [ ] Review durchführen\n- [ ] Freigabe einholen"
            )
        ]
    ]
    
    // Intelligence-basierte Suggestion-Regeln
    private let intelligenceRules: [IntelligenceRule] = [
        IntelligenceRule(
            name: "Language Complexity",
            description: "Anpassung der Sprachkomplexität",
            condition: { analysis in analysis.quality.readabilityScore < 0.5 },
            action: { analysis in
                return [
                    SmartSuggestion(
                        type: .improvement,
                        priority: .medium,
                        title: "Sprache vereinfachen",
                        description: "Der Text könnte einfacher formuliert werden",
                        action: "simplifyLanguage",
                        category: "Stil"
                    )
                ]
            }
        ),
        IntelligenceRule(
            name: "Urgency Mismatch",
            description: "Diskrepanz zwischen Inhalt und Dringlichkeit",
            condition: { analysis in analysis.urgency.score > 0.7 && analysis.quality.completenessScore < 0.4 },
            action: { analysis in
                return [
                    SmartSuggestion(
                        type: .action,
                        priority: .high,
                        title: "Dringliche Inhalte vervollständigen",
                        description: "Da der Inhalt als dringend eingestuft wurde, sollten wichtige Details ergänzt werden",
                        action: "completeUrgentContent",
                        category: "Vollständigkeit"
                    )
                ]
            }
        ),
        IntelligenceRule(
            name: "Engagement Optimization",
            description: "Optimierung für höhere Leserbindung",
            condition: { analysis in analysis.quality.engagementScore < 0.4 },
            action: { analysis in
                return [
                    SmartSuggestion(
                        type: .content,
                        priority: .medium,
                        title: "Leserbindung erhöhen",
                        description: "Fügen Sie Fragen oder interaktive Elemente hinzu",
                        action: "addEngagement",
                        category: "Engagement"
                    )
                ]
            }
        )
    ]
    
    // Pattern-basierte Verbesserungsvorschläge
    private let improvementPatterns: [String: ImprovementPattern] = [
        "too_long_sentences": ImprovementPattern(
            pattern: #"[^.!?]+[,;][^.!?]+[,;][^.!?]+[,;][^.!?]+"#,
            problem: "Sehr lange Sätze mit mehreren Kommas",
            solution: "Teilen Sie den Satz auf oder verwenden Sie kürzere Phrasen",
            example: "Bevor: 'Das Unternehmen, das bereits seit Jahren erfolgreich am Markt tätig ist, expandiert nun, weil es neue Chancen sieht und mehr Umsatz generieren möchte.'\nNach: 'Das expandierende Unternehmen sieht neue Chancen für mehr Umsatz.'"
        ),
        "passive_voice": ImprovementPattern(
            pattern: #"\b(?:ist|war|werden|wurde)\s+(?:gemacht|getan|erstellt|geplant)\b"#,
            problem: "Zu viel Passiv-Stimme",
            solution: "Verwenden Sie aktive Formulierungen",
            example: "Bevor: 'Das Projekt wurde erfolgreich abgeschlossen.'\nNach: 'Wir haben das Projekt erfolgreich abgeschlossen.'"
        ),
        "word_repetition": ImprovementPattern(
            pattern: #"\b(\w+)\s+\1\s+"#,
            problem: "Wortwiederholungen",
            solution: "Verwenden Sie Synonyme für Abwechslung",
            example: "Bevor: 'Das Unternehmen hat gute Ergebnisse erzielt. Das Unternehmen plant Expansion.'\nNach: 'Das Unternehmen hat gute Ergebnisse erzielt. Die Firma plant Expansion.'"
        )
    ]
    
    init() {
        nlModel.string = ""
    }
    
    func generateSuggestions(
        text: String,
        contentType: ContentType,
        sentiment: SentimentAnalysis,
        urgency: UrgencyLevel,
        quality: ContentQuality,
        topics: [Topic],
        language: DetectedLanguage,
        completion: @escaping ([SmartSuggestion]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let analysis = self.createAnalysisContext(
                text: text,
                contentType: contentType,
                sentiment: sentiment,
                urgency: urgency,
                quality: quality,
                topics: topics,
                language: language
            )
            
            let suggestions = self.performSuggestionGeneration(analysis: analysis)
            
            DispatchQueue.main.async {
                completion(suggestions)
            }
        }
    }
    
    private func createAnalysisContext(
        text: String,
        contentType: ContentType,
        sentiment: SentimentAnalysis,
        urgency: UrgencyLevel,
        quality: ContentQuality,
        topics: [Topic],
        language: DetectedLanguage
    ) -> AnalysisContext {
        return AnalysisContext(
            originalText: text,
            contentType: contentType,
            sentiment: sentiment,
            urgency: urgency,
            quality: quality,
            topics: topics,
            language: language,
            structure: ContentStructure(
                hasHeaders: text.contains("#") || text.contains("##"),
                hasLists: text.contains("-") || text.contains("•"),
                hasLinks: text.contains("http"),
                hasImages: text.contains("!["),
                hasCode: text.contains("```"),
                headerHierarchy: [],
                listTypes: [],
                paragraphCount: text.components(separatedBy: "\n\n").count,
                sentenceCount: text.components(separatedBy: .punctuationCharacters).count,
                wordCount: text.components(separatedBy: .whitespaces).count
            )
        )
    }
    
    private func performSuggestionGeneration(analysis: AnalysisContext) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // 1. Template-basierte Suggestions
        let templateSuggestions = generateTemplateSuggestions(analysis: analysis)
        suggestions.append(contentsOf: templateSuggestions)
        
        // 2. Intelligence-basierte Suggestions
        let intelligenceSuggestions = generateIntelligenceSuggestions(analysis: analysis)
        suggestions.append(contentsOf: intelligenceSuggestions)
        
        // 3. Pattern-basierte Suggestions
        let patternSuggestions = generatePatternSuggestions(text: analysis.originalText)
        suggestions.append(contentsOf: patternSuggestions)
        
        // 4. Context-sensitive Suggestions
        let contextSuggestions = generateContextSuggestions(analysis: analysis)
        suggestions.append(contentsOf: contextSuggestions)
        
        // 5. Priorisierung und Filterung
        let prioritizedSuggestions = prioritizeSuggestions(suggestions: suggestions)
        
        // 6. Duplikat-Entfernung
        let uniqueSuggestions = removeDuplicates(suggestions: prioritizedSuggestions)
        
        return uniqueSuggestions
    }
    
    private func generateTemplateSuggestions(analysis: AnalysisContext) -> [SmartSuggestion] {
        guard let templates = suggestionTemplates[analysis.contentType] else { return [] }
        
        var suggestions: [SmartSuggestion] = []
        
        for template in templates {
            if template.trigger(analysis) {
                suggestions.append(SmartSuggestion(
                    type: convertSuggestionType(template.category),
                    priority: template.priority,
                    title: template.message,
                    description: template.suggestion,
                    action: template.action,
                    category: template.category.capitalized
                ))
            }
        }
        
        return suggestions
    }
    
    private func generateIntelligenceSuggestions(analysis: AnalysisContext) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        for rule in intelligenceRules {
            if rule.condition(analysis) {
                let ruleSuggestions = rule.action(analysis)
                suggestions.append(contentsOf: ruleSuggestions)
            }
        }
        
        return suggestions
    }
    
    private func generatePatternSuggestions(text: String) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        for (patternKey, pattern) in improvementPatterns {
            if let matches = findMatches(pattern: pattern.pattern, text: text), !matches.isEmpty {
                suggestions.append(SmartSuggestion(
                    type: .improvement,
                    priority: .medium,
                    title: pattern.problem,
                    description: pattern.solution,
                    action: "fix_\(patternKey)",
                    category: "Muster"
                ))
            }
        }
        
        return suggestions
    }
    
    private func generateContextSuggestions(analysis: AnalysisContext) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Language-specific suggestions
        if analysis.language.isGerman {
            suggestions.append(contentsOf: generateGermanSuggestions(analysis: analysis))
        } else if analysis.language.isEnglish {
            suggestions.append(contentsOf: generateEnglishSuggestions(analysis: analysis))
        }
        
        // Sentiment-based suggestions
        suggestions.append(contentsOf: generateSentimentSuggestions(analysis: analysis))
        
        // Topic-based suggestions
        suggestions.append(contentsOf: generateTopicSuggestions(analysis: analysis))
        
        return suggestions
    }
    
    private func generateGermanSuggestions(analysis: AnalysisContext) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Formal/Informal language detection
        if analysis.originalText.lowercased().contains("du") && analysis.contentType == .email {
            suggestions.append(SmartSuggestion(
                type: .format,
                priority: .low,
                title: "Förmlichkeitsprüfung",
                description: "Prüfen Sie, ob die Anredeform für den Empfänger geeignet ist",
                action: "checkFormality",
                category: "Ton"
            ))
        }
        
        // German-specific improvements
        if analysis.quality.readabilityScore < 0.6 {
            suggestions.append(SmartSuggestion(
                type: .improvement,
                priority: .medium,
                title: "Deutsche Rechtschreibung",
                description: "Nutzen Sie die Rechtschreibprüfung für optimale Qualität",
                action: "checkSpelling",
                category: "Grammatik"
            ))
        }
        
        return suggestions
    }
    
    private func generateEnglishSuggestions(analysis: AnalysisContext) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // English-specific improvements
        if analysis.quality.readabilityScore < 0.6 {
            suggestions.append(SmartSuggestion(
                type: .improvement,
                priority: .medium,
                title: "Clarity Enhancement",
                description: "Consider using more direct language for better clarity",
                action: "improveClarity",
                category: "Stil"
            ))
        }
        
        return suggestions
    }
    
    private func generateSentimentSuggestions(analysis: AnalysisContext) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        switch analysis.sentiment.polarity {
        case .veryNegative, .negative:
            suggestions.append(SmartSuggestion(
                type: .format,
                priority: .medium,
                title: "Positivere Formulierung",
                description: "Betrachten Sie eine ausgewogenere Darstellung",
                action: "balanceTone",
                category: "Ton"
            ))
        case .veryPositive:
            suggestions.append(SmartSuggestion(
                type: .format,
                priority: .low,
                title: "Ausgewogenheit prüfen",
                description: "Stellen Sie sicher, dass die Begeisterung angemessen ist",
                action: "checkBalance",
                category: "Ton"
            ))
        default:
            break
        }
        
        return suggestions
    }
    
    private func generateTopicSuggestions(analysis: AnalysisContext) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        if analysis.topics.count == 0 {
            suggestions.append(SmartSuggestion(
                type: .content,
                priority: .low,
                title: "Hauptthema definieren",
                description: "Klären Sie das Hauptthema für bessere Struktur",
                action: "defineTopic",
                category: "Struktur"
            ))
        } else if analysis.topics.count > 5 {
            suggestions.append(SmartSuggestion(
                type: .content,
                priority: .medium,
                title: "Fokus verbessern",
                description: "Konzentrieren Sie sich auf die wichtigsten Themen",
                action: "focusTopics",
                category: "Struktur"
            ))
        }
        
        return suggestions
    }
    
    private func prioritizeSuggestions(suggestions: [SmartSuggestion]) -> [SmartSuggestion] {
        return suggestions.sorted { suggestion1, suggestion2 in
            let priorityOrder: [SmartSuggestion.Priority: Int] = [
                .critical: 4,
                .high: 3,
                .medium: 2,
                .low: 1
            ]
            
            let priority1 = priorityOrder[suggestion1.priority] ?? 0
            let priority2 = priorityOrder[suggestion2.priority] ?? 0
            
            if priority1 != priority2 {
                return priority1 > priority2
            }
            
            // Secondary sort by category
            return suggestion1.category < suggestion2.category
        }
    }
    
    private func removeDuplicates(suggestions: [SmartSuggestion]) -> [SmartSuggestion] {
        var uniqueSuggestions: [SmartSuggestion] = []
        var seenActions: Set<String> = []
        
        for suggestion in suggestions {
            if !seenActions.contains(suggestion.action ?? "") {
                uniqueSuggestions.append(suggestion)
                seenActions.insert(suggestion.action ?? "")
            }
        }
        
        return uniqueSuggestions
    }
    
    private func findMatches(pattern: String, text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
        
        return matches.compactMap { match in
            let range = Range(match.range, in: text)
            return range.map { String(text[$0]) }
        }
    }
    
    private func convertSuggestionType(_ category: String) -> SmartSuggestion.SuggestionType {
        switch category.lowercased() {
        case "structure": return .structure
        case "content": return .content
        case "format": return .format
        case "action": return .action
        default: return .improvement
        }
    }
    
    // MARK: - Adaptive Learning
    func learnFromUserAction(_ action: UserAction, completion: @escaping (LearningResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Anpassung der Suggestion-Gewichtung basierend auf User-Feedback
            let learningResult = self.adjustSuggestionWeights(action: action)
            
            DispatchQueue.main.async {
                completion(learningResult)
            }
        }
    }
    
    private func adjustSuggestionWeights(action: UserAction) -> LearningResult {
        var feedbackScore = 0.0
        
        switch action.feedback {
        case .accepted:
            feedbackScore = 1.0
        case .modified:
            feedbackScore = 0.7
        case .rejected:
            feedbackScore = 0.0
        case .ignored:
            feedbackScore = 0.3
        }
        
        // Anpassung der Template-Gewichtung
        if let template = action.template {
            adjustTemplateWeight(template: template, feedback: feedbackScore)
        }
        
        return LearningResult(
            adjustedWeight: feedbackScore,
            suggestionsUpdated: true,
            learningMetrics: LearningMetrics(
                acceptanceRate: calculateAcceptanceRate(),
                modificationRate: calculateModificationRate(),
                rejectionRate: calculateRejectionRate()
            )
        )
    }
    
    private func adjustTemplateWeight(template: SuggestionTemplate, feedback: Double) {
        // Placeholder für Gewichtungsanpassung
        // In einer echten Implementierung würde dies in einer Datenbank gespeichert
    }
    
    private func calculateAcceptanceRate() -> Double {
        // Berechne Accept-Rate basierend auf historischen Daten
        return 0.7 // Placeholder
    }
    
    private func calculateModificationRate() -> Double {
        return 0.2 // Placeholder
    }
    
    private func calculateRejectionRate() -> Double {
        return 0.1 // Placeholder
    }
}

// MARK: - Supporting Data Types
struct AnalysisContext {
    let originalText: String
    let contentType: ContentType
    let sentiment: SentimentAnalysis
    let urgency: UrgencyLevel
    let quality: ContentQuality
    let topics: [Topic]
    let language: DetectedLanguage
    let structure: ContentStructure
}

struct SuggestionTemplate {
    let category: String
    let priority: SmartSuggestion.Priority
    let trigger: (AnalysisContext) -> Bool
    let message: String
    let suggestion: String
    let action: String
    let example: String
}

struct IntelligenceRule {
    let name: String
    let description: String
    let condition: (AnalysisContext) -> Bool
    let action: (AnalysisContext) -> [SmartSuggestion]
}

struct ImprovementPattern {
    let pattern: String
    let problem: String
    let solution: String
    let example: String
}

struct UserAction {
    let suggestion: SmartSuggestion
    let template: SuggestionTemplate?
    let feedback: UserFeedback
    let timestamp: Date
    
    enum UserFeedback {
        case accepted, modified, rejected, ignored
    }
}

struct LearningResult {
    let adjustedWeight: Double
    let suggestionsUpdated: Bool
    let learningMetrics: LearningMetrics
}

struct LearningMetrics {
    let acceptanceRate: Double
    let modificationRate: Double
    let rejectionRate: Double
}