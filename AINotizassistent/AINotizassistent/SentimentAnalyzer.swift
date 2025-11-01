//
//  SentimentAnalyzer.swift
//  Sentiment Analysis mit Core ML
//

import Foundation
import NaturalLanguage
import CoreML

// MARK: - Sentiment Analyzer
class SentimentAnalyzer {
    private let nlModel: NLTagger
    private var sentimentModel: MLModel?
    
    // Sentiment Lexicons für verschiedene Sprachen
    private let germanPositiveWords: Set<String> = [
        "gut", "toll", "super", "großartig", "fantastisch", "ausgezeichnet",
        "perfekt", "schön", "freude", "glücklich", "zufrieden", "erfolgreich",
        "stark", "klar", "deutlich", "überzeugend", "positiv", "optimistisch",
        "interessant", "innovativ", "kreativ", "dynamisch", "flexibel",
        "sicher", "stabil", "kontinuierlich", "intelligent", "professionell"
    ]
    
    private let germanNegativeWords: Set<String> = [
        "schlecht", "furchtbar", "schrecklich", "schlimm", "negativ",
        "traurig", "frustriert", "enttäuscht", "ärgerlich", "wütend",
        "unsicher", "instabil", "kritisch", "problematisch", "kompliziert",
        "überfordernd", "stressig", "mühsam", "schwierig", "schwach",
        "fehlerhaft", "inkonsistent", "langsam", "veraltet", "ineffizient"
    ]
    
    private let englishPositiveWords: Set<String> = [
        "good", "great", "excellent", "amazing", "fantastic", "wonderful",
        "perfect", "beautiful", "happy", "joy", "satisfied", "successful",
        "strong", "clear", "convincing", "positive", "optimistic",
        "interesting", "innovative", "creative", "dynamic", "flexible",
        "secure", "stable", "intelligent", "professional"
    ]
    
    private let englishNegativeWords: Set<String> = [
        "bad", "terrible", "awful", "horrible", "negative", "sad",
        "frustrated", "disappointed", "angry", "mad", "unsafe",
        "unstable", "critical", "problematic", "complicated", "overwhelming",
        "stressful", "difficult", "weak", "buggy", "inconsistent",
        "slow", "outdated", "inefficient"
    ]
    
    private let emotionKeywords: [String: Emotion.EmotionType] = [
        "freude": .joy, "glück": .joy, "lachen": .joy, "fröhlich": .joy,
        "trauer": .sadness, "traurig": .sadness, "kummer": .sadness, "verlust": .sadness,
        "wut": .anger, "ärger": .anger, "frustriert": .anger, "verärgert": .anger,
        "angst": .fear, "furcht": .fear, "beängstigend": .fear, "sorge": .fear,
        "überraschung": .surprise, "erstaunlich": .surprise, "unerwartet": .surprise,
        "ekel": .disgust, "abstoßend": .disgust, "widerlich": .disgust,
        "vertrauen": .trust, "zuversichtlich": .trust, "glaubwürdig": .trust,
        "erwartung": .anticipation, "hoffnung": .anticipation, "spannend": .anticipation
    ]
    
    init() {
        self.nlModel = NLTagger(tagSchemes: [.sentimentScore, .lexicalClass])
        loadSentimentModel()
    }
    
    private func loadSentimentModel() {
        // Lade Core ML Model (falls verfügbar)
        // In einer produktiven App würde hier das echte Model geladen
        do {
            // Beispiel: sentimentClassifier = try SentimentClassifier(configuration: MLModelConfiguration())
            // self.sentimentModel = sentimentClassifier.model
        } catch {
            print("Failed to load sentiment model: \(error)")
        }
    }
    
    func analyzeSentiment(text: String, language: DetectedLanguage, completion: @escaping (SentimentAnalysis) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.performSentimentAnalysis(text: text, language: language)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func performSentimentAnalysis(text: String, language: DetectedLanguage) -> SentimentAnalysis {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let sentences = text.components(separatedBy: .punctuationCharacters)
        
        // Berechne Sentiment Score
        let sentimentScore = calculateSentimentScore(words: words, language: language)
        
        // Bestimme Polarity
        let polarity = determinePolarity(score: sentimentScore)
        
        // Berechne Intensität
        let intensity = calculateIntensity(words: words, language: language)
        
        // Extrahiere Emotionen
        let emotions = extractEmotions(words: words, text: text)
        
        return SentimentAnalysis(
            polarity: polarity,
            confidence: calculateConfidence(words: words, language: language),
            intensity: intensity,
            emotions: emotions
        )
    }
    
    private func calculateSentimentScore(words: [String], language: DetectedLanguage) -> Double {
        let positiveWords = language.isGerman ? germanPositiveWords : englishPositiveWords
        let negativeWords = language.isGerman ? germanNegativeWords : englishNegativeWords
        
        var positiveCount = 0
        var negativeCount = 0
        
        for word in words {
            let cleanedWord = word.trimmingCharacters(in: .punctuationCharacters)
            if positiveWords.contains(cleanedWord) {
                positiveCount += 1
            }
            if negativeWords.contains(cleanedWord) {
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
    
    private func calculateIntensity(words: [String], language: DetectedLanguage) -> Double {
        var intensityWords = 0
        let intensifiers = ["sehr", "wirklich", "extrem", "total", "absolut",
                           "very", "really", "extremely", "totally", "absolutely"]
        
        for word in words {
            if intensifiers.contains(word) {
                intensityWords += 1
            }
        }
        
        let intensityRatio = Double(intensityWords) / Double(words.count)
        return min(intensityRatio * 5.0, 1.0) // Cap at 1.0
    }
    
    private func extractEmotions(words: [String], text: String) -> [Emotion] {
        var emotions: [Emotion] = []
        
        for (keyword, emotionType) in emotionKeywords {
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
        
        // Normalize by text length and keyword frequency
        let baseConfidence = Double(keywordCount) / (textLength / 100.0)
        return min(baseConfidence, 1.0)
    }
    
    private func calculateConfidence(words: [String], language: DetectedLanguage) -> Double {
        // Confidence basierend auf Textlänge und eindeutigen Sentiment-Indikatoren
        let minWordsForConfidence = 10.0
        let lengthConfidence = min(Double(words.count) / minWordsForConfidence, 1.0)
        
        // Prüfe auf Eindeutigkeit der Sentiment-Indikatoren
        let positiveWords = language.isGerman ? germanPositiveWords : englishPositiveWords
        let negativeWords = language.isGerman ? germanNegativeWords : englishNegativeWords
        
        var sentimentIndicatorCount = 0
        for word in words {
            if positiveWords.contains(word) || negativeWords.contains(word) {
                sentimentIndicatorCount += 1
            }
        }
        
        let indicatorConfidence = Double(sentimentIndicatorCount) / Double(words.count)
        
        return (lengthConfidence + indicatorConfidence) / 2.0
    }
    
    // MARK: - Advanced Sentiment Analysis
    func analyzeEmotionalJourney(text: String, completion: @escaping ([EmotionalMoment]) -> Void) {
        let sentences = text.components(separatedBy: .punctuationCharacters)
        var emotionalJourney: [EmotionalMoment] = []
        
        sentences.enumerated().forEach { index, sentence in
            let words = sentence.lowercased().components(separatedBy: .whitespaces)
            let sentimentScore = calculateSentimentScore(words: words, language: DetectedLanguage(code: "de", confidence: 1.0, isReliable: true, localizedName: "Deutsch"))
            
            emotionalJourney.append(EmotionalMoment(
                position: index,
                text: sentence,
                sentiment: determinePolarity(score: sentimentScore),
                intensity: calculateIntensity(words: words, language: DetectedLanguage(code: "de", confidence: 1.0, isReliable: true, localizedName: "Deutsch")),
                emotions: extractEmotions(words: words, text: sentence)
            ))
        }
        
        completion(emotionalJourney)
    }
    
    func detectSarcasm(text: String, completion: @escaping (SarcasmAnalysis) -> Void) {
        let indicators = [
            "ironisch", "sarkastisch", "klar doch", "natürlich", "ach so",
            "ironic", "sarcastic", "of course", "oh really", "yeah right"
        ]
        
        let textLower = text.lowercased()
        let sarcasmScore = indicators.reduce(0.0) { score, indicator in
            textLower.contains(indicator) ? score + 0.2 : score
        }
        
        let hasSarcasm = sarcasmScore > 0.3
        let confidence = min(sarcasmScore, 1.0)
        
        completion(SarcasmAnalysis(
            hasSarcasm: hasSarcasm,
            confidence: confidence,
            indicators: indicators.filter { textLower.contains($0) }
        ))
    }
}

// MARK: - Supporting Data Types
struct EmotionalMoment {
    let position: Int
    let text: String
    let sentiment: SentimentAnalysis.SentimentPolarity
    let intensity: Double
    let emotions: [Emotion]
}

struct SarcasmAnalysis {
    let hasSarcasm: Bool
    let confidence: Double
    let indicators: [String]
}