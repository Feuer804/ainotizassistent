//
//  UrgencyDetector.swift
//  Urgency Level Detection
//

import Foundation
import NaturalLanguage

// MARK: - Urgency Detector
class UrgencyDetector {
    private let nlModel = NLTagger(tagSchemes: [.lexicalClass])
    
    // Urgency Keywords für verschiedene Sprachen
    private let urgencyKeywords: [String: [String]] = [
        "de": [
            // Hoch urgent
            "sofort", "dringend", "notfall", "kritisch", "sofortig", "unverzüglich",
            "sofortig", "augenblicklich", "sofort", "eilig", "dringend", "wichtig",
            "priorität", "hoch", "kritisch", "essentiell", "unumgänglich",
            
            // Medium urgent
            "bald", "schnell", "demnächst", "möglichst bald", "dringend",
            "alsbald", "ehestens", "umgehend", "rasch", "zügig",
            
            // Niedrig urgent
            "später", "irgendwann", "wenn möglich", "bei gelegenheit", "nach bedarf"
        ],
        "en": [
            // High urgent
            "immediate", "urgent", "critical", "emergency", "asap", "immediately",
            "instant", "prompt", "critical", "essential", "crucial", "vital",
            "priority", "high", "pressing", "serious",
            
            // Medium urgent
            "soon", "quickly", "promptly", "swiftly", "rapidly", "speedily",
            "expeditiously", "efficiently", "fast",
            
            // Low urgent
            "later", "eventually", "when possible", "when convenient", "at your leisure"
        ]
    ]
    
    private let deadlinePatterns: [String: [String]] = [
        "de": [
            "bis zum", "bis spätestens", "deadline", "frist", "termin",
            "letzter termin", "截止日期", "spätestens", "vor dem",
            "bis", "unterfrist", "zeitlimit", "verfallsdatum"
        ],
        "en": [
            "deadline", "due date", "by", "before", "until", "by the end of",
            "due", "final date", "cutoff", "limit", "time limit", "target date"
        ]
    ]
    
    private let emotionalUrgencyIndicators: [String: [String]] = [
        "de": [
            "nervös", "besorgt", "aufgeregt", "frustriert", "gestresst", "panik",
            "panic", "verzweifelt", "entmutigt", "beunruhigt", "unruhig",
            "mich drückt", "mache mir sorgen", "schlaflos"
        ],
        "en": [
            "nervous", "worried", "excited", "frustrated", "stressed", "panic",
            "desperate", "discouraged", "concerned", "restless", "troubled",
            "pressured", "overwhelmed", "anxious"
        ]
    ]
    
    private let contextUrgencyMarkers: [String: [String]] = [
        "de": [
            "verpasst", "versäumt", "spät", "verschoben", "erinnerung",
            "überfällig", "überfällig", "nicht erledigt", "ausstehend", "offen",
            "wichtig", "entscheidend", "wichtig", "vorrangig"
        ],
        "en": [
            "missed", "late", "delayed", "overdue", "reminder",
            "past due", "unfinished", "pending", "outstanding", "open",
            "important", "crucial", "priority", "urgent"
        ]
    ]
    
    private let senderUrgencyWeights: [String: Double] = [
        // Höhere Gewichtung für bestimmte Absender
        "chef": 0.8, "boss": 0.8, "manager": 0.7,
        "notfall": 1.0, "emergency": 1.0,
        "support": 0.6, "help": 0.6,
        "automatisch": 0.3, "automated": 0.3,
        "noreply": 0.2, "no-reply": 0.2
    ]
    
    init() {
        nlModel.string = ""
    }
    
    func detectUrgency(text: String, contentType: ContentType, completion: @escaping (UrgencyLevel) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let urgency = self.performUrgencyDetection(text: text, contentType: contentType)
            DispatchQueue.main.async {
                completion(urgency)
            }
        }
    }
    
    private func performUrgencyDetection(text: String, contentType: ContentType) -> UrgencyLevel {
        let language = detectLanguageFromText(text: text)
        
        // Extrahiere verschiedene Urgency-Indikatoren
        let urgencyIndicators = self.extractUrgencyIndicators(text: text, language: language, contentType: contentType)
        
        // Berechne overall Urgency Score
        let overallScore = calculateOverallUrgencyScore(indicators: urgencyIndicators, contentType: contentType)
        
        // Bestimme Urgency Level
        let urgencyLevel = determineUrgencyLevel(score: overallScore)
        
        // Schätze Bearbeitungszeit
        let estimatedTime = estimateProcessingTime(urgencyLevel: urgencyLevel, text: text)
        
        return UrgencyLevel(
            level: urgencyLevel,
            score: overallScore,
            indicators: urgencyIndicators,
            estimatedTimeToComplete: estimatedTime
        )
    }
    
    private func extractUrgencyIndicators(text: String, language: String, contentType: ContentType) -> [UrgencyLevel.UrgencyIndicator] {
        var indicators: [UrgencyLevel.UrgencyIndicator] = []
        let textLower = text.lowercased()
        
        // 1. Keyword-basierte Indikatoren
        if let urgencyWords = urgencyKeywords[language] {
            for word in urgencyWords {
                if textLower.contains(word) {
                    let confidence = calculateKeywordConfidence(word: word, text: text)
                    indicators.append(UrgencyLevel.UrgencyIndicator(
                        type: .keywords,
                        confidence: confidence,
                        description: "Urgency keyword detected: \(word)"
                    ))
                }
            }
        }
        
        // 2. Deadline-Indikatoren
        if let deadlineWords = deadlinePatterns[language] {
            for pattern in deadlineWords {
                if textLower.contains(pattern) {
                    let confidence = calculatePatternConfidence(pattern: pattern, text: text)
                    indicators.append(UrgencyLevel.UrgencyIndicator(
                        type: .deadline,
                        confidence: confidence,
                        description: "Deadline pattern detected: \(pattern)"
                    ))
                }
            }
        }
        
        // 3. Emotionale Indikatoren
        if let emotionWords = emotionalUrgencyIndicators[language] {
            for word in emotionWords {
                if textLower.contains(word) {
                    let confidence = calculateEmotionalConfidence(word: word, text: text)
                    indicators.append(UrgencyLevel.UrgencyIndicator(
                        type: .emotion,
                        confidence: confidence,
                        description: "Emotional urgency detected: \(word)"
                    ))
                }
            }
        }
        
        // 4. Context-basierte Indikatoren
        for (pattern, _) in contextUrgencyMarkers[language, default: []] {
            if textLower.contains(pattern) {
                let confidence = calculateContextConfidence(pattern: pattern, text: text)
                indicators.append(UrgencyLevel.UrgencyIndicator(
                    type: .context,
                    confidence: confidence,
                    description: "Context urgency detected: \(pattern)"
                ))
            }
        }
        
        // 5. Sender-basierte Indikatoren (für E-Mails und Meetings)
        if contentType == .email || contentType == .meeting {
            let senderIndicators = extractSenderUrgency(text: text, language: language)
            indicators.append(contentsOf: senderIndicators)
        }
        
        // 6. Subject-basierte Indikatoren
        let subjectIndicators = extractSubjectUrgency(text: text, language: language)
        indicators.append(contentsOf: subjectIndicators)
        
        return indicators
    }
    
    private func calculateOverallUrgencyScore(indicators: [UrgencyLevel.UrgencyIndicator], contentType: ContentType) -> Double {
        guard !indicators.isEmpty else { return 0.0 }
        
        var weightedScore = 0.0
        var totalWeight = 0.0
        
        for indicator in indicators {
            let weight = getIndicatorWeight(indicator: indicator, contentType: contentType)
            weightedScore += indicator.confidence * weight
            totalWeight += weight
        }
        
        let baseScore = totalWeight > 0 ? weightedScore / totalWeight : 0.0
        
        // Content-Type adjustments
        let typeAdjustment = getContentTypeAdjustment(contentType: contentType)
        
        return min(baseScore + typeAdjustment, 1.0)
    }
    
    private func getIndicatorWeight(indicator: UrgencyLevel.UrgencyIndicator, contentType: ContentType) -> Double {
        switch indicator.type {
        case .deadline:
            return 1.0 // Höchstes Gewicht für Deadlines
        case .keywords:
            return 0.8
        case .emotion:
            return 0.7
        case .context:
            return 0.6
        case .sender:
            return 0.9
        case .subject:
            return 0.5
        }
    }
    
    private func getContentTypeAdjustment(contentType: ContentType) -> Double {
        switch contentType {
        case .email:
            return 0.05 // Emails sind oft dringend
        case .meeting:
            return 0.1  // Meetings haben oft feste Termine
        case .task:
            return 0.08 // Tasks können Dringlichkeit haben
        case .question:
            return 0.03 // Fragen können variieren
        default:
            return 0.0
        }
    }
    
    private func determineUrgencyLevel(score: Double) -> UrgencyLevel.UrgencyLevelType {
        if score >= 0.8 {
            return .critical
        } else if score >= 0.6 {
            return .high
        } else if score >= 0.3 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func estimateProcessingTime(urgencyLevel: UrgencyLevel.UrgencyLevelType, text: String) -> TimeInterval {
        let wordCount = text.components(separatedBy: .whitespaces).count
        
        // Basis-Zeit: 30 Sekunden pro 100 Wörter
        var baseTime = Double(wordCount) * 0.3
        
        // Urgency adjustment
        switch urgencyLevel {
        case .critical:
            baseTime *= 2.0 // Dringende Nachrichten werden schneller bearbeitet
        case .high:
            baseTime *= 1.5
        case .medium:
            baseTime *= 1.0
        case .low:
            baseTime *= 0.8 // Niedrige Urgency kann warten
        }
        
        // Minimum und Maximum Limits
        baseTime = max(baseTime, 60.0)      // Mindestens 1 Minute
        baseTime = min(baseTime, 3600.0)    // Maximal 1 Stunde
        
        return baseTime // Seconds
    }
    
    // MARK: - Helper Methods
    private func detectLanguageFromText(text: String) -> String {
        let germanIndicators = urgencyKeywords.keys.first ?? "de"
        let englishIndicators = urgencyKeywords.keys.last ?? "en"
        
        let textLower = text.lowercased()
        
        let germanMatches = urgencyKeywords[germanIndicators]?.prefix(5).filter { textLower.contains($0) }.count ?? 0
        let englishMatches = urgencyKeywords[englishIndicators]?.prefix(5).filter { textLower.contains($0) }.count ?? 0
        
        return germanMatches > englishMatches ? germanIndicators : englishIndicators
    }
    
    private func calculateKeywordConfidence(word: String, text: String) -> Double {
        let textLower = text.lowercased()
        let wordCount = textLower.components(separatedBy: word).count - 1
        let textLength = Double(text.count)
        
        // Normalized by text length
        let baseConfidence = Double(wordCount) / (textLength / 100.0)
        return min(baseConfidence, 1.0)
    }
    
    private func calculatePatternConfidence(pattern: String, text: String) -> Double {
        // Patterns are generally more reliable than single words
        return 0.8
    }
    
    private func calculateEmotionalConfidence(word: String, text: String) -> Double {
        // Emotions can be strong indicators but may be less reliable
        return 0.6
    }
    
    private func calculateContextConfidence(pattern: String, text: String) -> Double {
        // Context patterns can be reliable
        return 0.7
    }
    
    private func extractSenderUrgency(text: String, language: String) -> [UrgencyLevel.UrgencyIndicator] {
        var indicators: [UrgencyLevel.UrgencyIndicator] = []
        
        // Suche nach Absender-Indikatoren
        let senderPatterns = ["von:", "from:", "von", "from"]
        
        for pattern in senderPatterns {
            if text.lowercased().contains(pattern) {
                // Extrahiere Kontext um den Absender
                if let range = text.lowercased().range(of: pattern) {
                    let context = text[range.lowerBound..<text.endIndex]
                    let nextWords = context.components(separatedBy: .whitespaces).prefix(3).joined(separator: " ")
                    
                    // Bewerte Absender Urgency
                    let urgencyWeight = calculateSenderUrgencyWeight(senderText: nextWords)
                    
                    if urgencyWeight > 0.3 {
                        indicators.append(UrgencyLevel.UrgencyIndicator(
                            type: .sender,
                            confidence: urgencyWeight,
                            description: "High-priority sender detected: \(nextWords)"
                        ))
                    }
                }
            }
        }
        
        return indicators
    }
    
    private func calculateSenderUrgencyWeight(senderText: String) -> Double {
        let senderLower = senderText.lowercased()
        
        for (pattern, weight) in senderUrgencyWeights {
            if senderLower.contains(pattern) {
                return weight
            }
        }
        
        return 0.0
    }
    
    private func extractSubjectUrgency(text: String, language: String) -> [UrgencyLevel.UrgencyIndicator] {
        var indicators: [UrgencyLevel.UrgencyIndicator] = []
        
        let subjectPatterns = ["betreff:", "subject:", "betreff", "subject"]
        
        for pattern in subjectPatterns {
            if text.lowercased().contains(pattern) {
                if let range = text.lowercased().range(of: pattern) {
                    let subjectLine = text[range.lowerBound..<text.endIndex]
                    let subjectText = subjectLine.components(separatedBy: .newlines).first ?? ""
                    
                    // Analysiere Subject auf Urgency-Keywords
                    let subjectIndicators = extractUrgencyIndicators(text: subjectText, language: language, contentType: .email)
                    
                    for indicator in subjectIndicators {
                        if indicator.confidence > 0.5 {
                            indicators.append(UrgencyLevel.UrgencyIndicator(
                                type: .subject,
                                confidence: indicator.confidence * 1.2, // Subject ist wichtiger
                                description: "Subject urgency: \(indicator.description)"
                            ))
                        }
                    }
                }
            }
        }
        
        return indicators
    }
    
    // MARK: - Advanced Urgency Analysis
    func analyzeTemporalUrgency(text: String, completion: @escaping (TemporalUrgencyAnalysis) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let language = self.detectLanguageFromText(text: text)
            
            // Extrahiere Zeitangaben
            let timeExpressions = self.extractTimeExpressions(text: text, language: language)
            
            // Analysiere relative Zeitbegriffe
            let relativeTimeAnalysis = self.analyzeRelativeTime(text: text, language: language)
            
            // Berechne zeitliche Urgency
            let temporalScore = self.calculateTemporalUrgencyScore(
                timeExpressions: timeExpressions,
                relativeAnalysis: relativeTimeAnalysis
            )
            
            let analysis = TemporalUrgencyAnalysis(
                timeExpressions: timeExpressions,
                relativeTimeAnalysis: relativeTimeAnalysis,
                temporalUrgencyScore: temporalScore,
                recommendedActionTime: self.calculateRecommendedActionTime(
                    timeExpressions: timeExpressions,
                    urgencyScore: temporalScore
                )
            )
            
            DispatchQueue.main.async {
                completion(analysis)
            }
        }
    }
    
    private func extractTimeExpressions(text: String, language: String) -> [TimeExpression] {
        var expressions: [TimeExpression] = []
        let textLower = text.lowercased()
        
        // German time expressions
        if language == "de" {
            let patterns = [
                #"(\d{1,2})\.(\d{1,2})\.(\d{2,4})"#: .absoluteDate,
                #"(\d{1,2})\.(\d{1,2})"#: .ambiguousDate,
                #"(\d{1,2}):(\d{2})"#: .time,
                #"morgen"#: .relativeDay,
                #"übermorgen"#: .relativeDay,
                #"heute"#: .relativeDay,
                #"gestern"#: .relativeDay,
                #"nächste (woche|monat|jahr)"#: .relativeWeek,
                #"in (\d+) (tag|tagen|stunde|stunden|minute|minuten)"#: .relativeDuration
            ]
            
            for (pattern, type) in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let matches = regex.matches(in: textLower, range: NSRange(location: 0, length: textLower.count))
                    
                    for match in matches {
                        let matchRange = Range(match.range, in: textLower)!
                        let matchedText = String(textLower[matchRange])
                        
                        expressions.append(TimeExpression(
                            text: matchedText,
                            type: type,
                            position: match.range.location,
                            confidence: 0.8
                        ))
                    }
                }
            }
        }
        
        // English time expressions
        if language == "en" {
            let patterns = [
                #"(\d{1,2})\/(\d{1,2})\/(\d{2,4})"#: .absoluteDate,
                #"(\d{1,2})\/(\d{1,2})"#: .ambiguousDate,
                #"(\d{1,2}):(\d{2})"#: .time,
                #"tomorrow"#: .relativeDay,
                #"day after tomorrow"#: .relativeDay,
                #"today"#: .relativeDay,
                #"yesterday"#: .relativeDay,
                #"next (week|month|year)"#: .relativeWeek,
                #"in (\d+) (day|days|hour|hours|minute|minutes)"#: .relativeDuration
            ]
            
            for (pattern, type) in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let matches = regex.matches(in: textLower, range: NSRange(location: 0, length: textLower.count))
                    
                    for match in matches {
                        let matchRange = Range(match.range, in: textLower)!
                        let matchedText = String(textLower[matchRange])
                        
                        expressions.append(TimeExpression(
                            text: matchedText,
                            type: type,
                            position: match.range.location,
                            confidence: 0.8
                        ))
                    }
                }
            }
        }
        
        return expressions
    }
    
    private func analyzeRelativeTime(text: String, language: String) -> RelativeTimeAnalysis {
        let textLower = text.lowercased()
        
        var urgencyWords: [String] = []
        var delayWords: [String] = []
        
        if language == "de" {
            urgencyWords = ["sofort", "dringend", "unverzüglich", "eilig", "asap"]
            delayWords = ["später", "irgendwann", "bei gelegenheit"]
        } else {
            urgencyWords = ["immediate", "urgent", "asap", "promptly", "quickly"]
            delayWords = ["later", "eventually", "when convenient"]
        }
        
        let urgencyMatches = urgencyWords.filter { textLower.contains($0) }.count
        let delayMatches = delayWords.filter { textLower.contains($0) }.count
        
        let urgencyBias = urgencyMatches > delayMatches ? 1.0 : delayMatches > urgencyMatches ? -1.0 : 0.0
        
        return RelativeTimeAnalysis(
            urgencyBias: urgencyBias,
            urgencyWordCount: urgencyMatches,
            delayWordCount: delayMatches
        )
    }
    
    private func calculateTemporalUrgencyScore(timeExpressions: [TimeExpression], relativeAnalysis: RelativeTimeAnalysis) -> Double {
        var score = 0.0
        
        // Score basierend auf Zeit-Ausdrücken
        for expression in timeExpressions {
            switch expression.type {
            case .absoluteDate:
                // Prüfe, ob Datum in der Zukunft liegt
                if isDateInNearFuture(expression.text) {
                    score += 0.6
                }
            case .relativeDay:
                score += expression.text.contains("morgen") || expression.text.contains("today") ? 0.8 : 0.4
            case .relativeDuration:
                if expression.text.contains("minute") || expression.text.contains("stunde") {
                    score += 0.9
                } else if expression.text.contains("tag") || expression.text.contains("day") {
                    score += 0.6
                }
            default:
                break
            }
        }
        
        // Relative Zeit Bias
        if relativeAnalysis.urgencyBias > 0 {
            score += relativeAnalysis.urgencyBias * 0.3
        }
        
        return min(score, 1.0)
    }
    
    private func isDateInNearFuture(_ dateString: String) -> Bool {
        // Vereinfachte Implementierung - in einer echten App würde man NSDateFormatter verwenden
        return dateString.contains("morgen") || dateString.contains("tomorrow") || dateString.contains("heute")
    }
    
    private func calculateRecommendedActionTime(timeExpressions: [TimeExpression], urgencyScore: Double) -> TimeInterval {
        // Finde früheste Zeitangabe
        let earliestExpression = timeExpressions.min { $0.position < $1.position }
        
        if let expression = earliestExpression {
            switch expression.type {
            case .relativeDuration:
                // Parse duration from expression
                if let duration = parseDuration(expression.text) {
                    return duration * 3600 // Convert to seconds
                }
            case .relativeDay:
                return urgencyScore > 0.7 ? 3600 * 2 : 3600 * 8 // 2 or 8 hours
            case .absoluteDate:
                return 3600 * 4 // 4 hours for absolute dates
            default:
                break
            }
        }
        
        // Default based on urgency score
        switch urgencyScore {
        case 0.8...1.0:
            return 3600 * 1 // 1 hour
        case 0.6..<0.8:
            return 3600 * 4 // 4 hours
        case 0.3..<0.6:
            return 3600 * 24 // 1 day
        default:
            return 3600 * 72 // 3 days
        }
    }
    
    private func parseDuration(_ durationString: String) -> Double? {
        let components = durationString.components(separatedBy: .whitespaces)
        
        if components.count >= 2, let number = Double(components[1]) {
            if durationString.contains("minute") || durationString.contains("minuten") {
                return number * 60
            } else if durationString.contains("stunde") || durationString.contains("hour") {
                return number * 3600
            } else if durationString.contains("tag") || durationString.contains("day") {
                return number * 86400
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Data Types
struct TemporalUrgencyAnalysis {
    let timeExpressions: [TimeExpression]
    let relativeTimeAnalysis: RelativeTimeAnalysis
    let temporalUrgencyScore: Double
    let recommendedActionTime: TimeInterval
}

struct TimeExpression {
    let text: String
    let type: TimeExpressionType
    let position: Int
    let confidence: Double
    
    enum TimeExpressionType {
        case absoluteDate, ambiguousDate, time, relativeDay, relativeWeek, relativeDuration
    }
}

struct RelativeTimeAnalysis {
    let urgencyBias: Double
    let urgencyWordCount: Int
    let delayWordCount: Int
}