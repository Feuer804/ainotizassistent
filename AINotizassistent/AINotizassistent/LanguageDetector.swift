//
//  LanguageDetector.swift
//  Language Detection mit Natural Language
//

import Foundation
import NaturalLanguage

// MARK: - Language Detector
class LanguageDetector {
    private let nlpRecognizer = NLLanguageRecognizer()
    
    // Sprachspezifische Charakteristiken
    private let languageCharacteristics: [String: LanguageCharacteristics] = [
        "de": LanguageCharacteristics(
            commonWords: ["der", "die", "das", "und", "ist", "zu", "mit", "auf", "für", "von", "in", "an", "als", "auch", "es"],
            specialChars: ["ä", "ö", "ü", "ß"],
            sentenceStructure: .svo, // Subject-Verb-Object
            punctuation: ["§", "%", "°"]
        ),
        "en": LanguageCharacteristics(
            commonWords: ["the", "and", "to", "of", "a", "in", "for", "is", "on", "that", "by", "this", "with", "i", "it"],
            specialChars: [],
            sentenceStructure: .svo,
            punctuation: []
        ),
        "fr": LanguageCharacteristics(
            commonWords: ["le", "de", "et", "à", "un", "il", "être", "et", "en", "avoir", "que", "pour", "dans", "ce", "son"],
            specialChars: ["é", "è", "ê", "ë", "à", "â", "ù", "ô", "î", "ï", "ç"],
            sentenceStructure: .svo,
            punctuation: []
        ),
        "es": LanguageCharacteristics(
            commonWords: ["el", "de", "que", "y", "a", "en", "un", "es", "se", "no", "te", "lo", "le", "da", "su"],
            specialChars: ["ñ", "á", "é", "í", "ó", "ú", "ü"],
            sentenceStructure: .svo,
            punctuation: []
        ),
        "it": LanguageCharacteristics(
            commonWords: ["il", "che", "di", "e", "la", "per", "una", "in", "con", "del", "da", "un", "è", "non", "mi"],
            specialChars: ["à", "è", "é", "ì", "í", "ò", "ó", "ù", "ú"],
            sentenceStructure: .svo,
            punctuation: []
        ),
        "pt": LanguageCharacteristics(
            commonWords: ["o", "de", "a", "e", "do", "da", "em", "um", "para", "é", "com", "não", "uma", "os", "no"],
            specialChars: ["á", "à", "ã", "â", "é", "ê", "í", "ó", "ô", "õ", "ú", "ç"],
            sentenceStructure: .svo,
            punctuation: []
        )
    ]
    
    private let stopWords: [String: Set<String>] = [
        "de": ["der", "die", "das", "und", "ist", "zu", "mit", "auf", "für", "von", "in", "an", "als", "auch", "es", "ich", "du", "er", "sie", "wir", "ihr", "den", "dem", "des"],
        "en": ["the", "and", "to", "of", "a", "in", "for", "is", "on", "that", "by", "this", "with", "i", "it", "you", "he", "she", "we", "they", "be", "have", "do", "will"],
        "fr": ["le", "de", "et", "à", "un", "il", "être", "en", "avoir", "que", "pour", "dans", "ce", "son", "une", "sur", "avec", "ne", "se", "pas", "tout", "plus"],
        "es": ["el", "de", "que", "y", "a", "en", "un", "es", "se", "no", "te", "lo", "le", "da", "su", "por", "son", "con", "para", "como", "las", "del"],
        "it": ["il", "che", "di", "e", "la", "per", "una", "in", "con", "del", "da", "un", "è", "non", "mi", "ma", "se", "più", "lei", "lei", "questo"],
        "pt": ["o", "de", "a", "e", "do", "da", "em", "um", "para", "é", "com", "não", "uma", "os", "no", "se", "na", "por", "mais", "as", "dos"]
    ]
    
    init() {
        // NLLanguageRecognizer initialisieren
        nlpRecognizer.processString("")
    }
    
    func detectLanguage(from text: String, completion: @escaping (DetectedLanguage) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let detectedLanguage = self.performLanguageDetection(text: text)
            DispatchQueue.main.async {
                completion(detectedLanguage)
            }
        }
    }
    
    private func performLanguageDetection(text: String) -> DetectedLanguage {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return DetectedLanguage(code: "en", confidence: 0.5, isReliable: false, localizedName: "English")
        }
        
        // Nutze Apple's Natural Language Framework für erste Erkennung
        let nlpResult = detectWithNLPFramework(text: normalizedText)
        
        // Verbessere mit statistischer Analyse
        let statisticalResult = detectWithStatisticalAnalysis(text: normalizedText)
        
        // Kombiniere Ergebnisse
        let finalResult = combineResults(nlpResult: nlpResult, statisticalResult: statisticalResult)
        
        return finalResult
    }
    
    private func detectWithNLPFramework(text: String) -> LanguageDetectionResult {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        let hypotheses = recognizer.languageHypotheses(withMaximum: 5)
        
        guard let dominantLanguage = hypotheses.first?.key else {
            return LanguageDetectionResult(languageCode: "en", confidence: 0.5)
        }
        
        let confidence = hypotheses.first?.value ?? 0.0
        
        return LanguageDetectionResult(
            languageCode: dominantLanguage.rawValue,
            confidence: Double(confidence),
            nlpBased: true
        )
    }
    
    private func detectWithStatisticalAnalysis(text: String) -> LanguageDetectionResult {
        let words = tokenizeText(text)
        let characterNGrams = extractCharacterNGrams(text: text)
        
        var languageScores: [String: Double] = [:]
        
        for (languageCode, characteristics) in languageCharacteristics {
            var score = 0.0
            
            // Bewerte häufige Wörter
            let commonWordMatches = countCommonWordMatches(words: words, commonWords: characteristics.commonWords)
            score += commonWordMatches * 2.0
            
            // Bewerte Special Characters
            let specialCharMatches = countSpecialCharMatches(text: text, specialChars: characteristics.specialChars)
            score += specialCharMatches * 3.0
            
            // Bewerte N-Gramme
            let ngramScore = calculateNGramScore(characterNGrams: characterNGrams, language: languageCode)
            score += ngramScore
            
            // Bewerte Stop-Wörter
            if let stopWordSet = stopWords[languageCode] {
                let stopWordMatches = countStopWordMatches(words: words, stopWords: stopWordSet)
                score += stopWordMatches * 1.5
            }
            
            // Normalisiere Score basierend auf Textlänge
            let normalizedScore = score / Double(max(words.count, 1))
            languageScores[languageCode] = normalizedScore
        }
        
        // Finde Sprache mit höchstem Score
        let bestLanguage = languageScores.max { $0.value < $1.value }
        
        guard let (languageCode, score) = bestLanguage else {
            return LanguageDetectionResult(languageCode: "en", confidence: 0.5)
        }
        
        // Normalisiere Confidence
        let maxScore = languageScores.values.max() ?? 1.0
        let confidence = min(score / maxScore, 1.0)
        
        return LanguageDetectionResult(
            languageCode: languageCode,
            confidence: confidence,
            statisticalBased: true
        )
    }
    
    private func combineResults(nlpResult: LanguageDetectionResult, statisticalResult: LanguageDetectionResult) -> DetectedLanguage {
        // Gewichtete Kombination der Ergebnisse
        let nlpWeight = 0.6
        let statisticalWeight = 0.4
        
        let combinedConfidence = (nlpResult.confidence * nlpWeight) + (statisticalResult.confidence * statisticalWeight)
        
        // Bestimme finale Sprache
        let finalLanguage = nlpResult.confidence > statisticalResult.confidence ? 
                           nlpResult.languageCode : 
                           statisticalResult.languageCode
        
        let localizedName = getLocalizedLanguageName(finalLanguage)
        let isReliable = combinedConfidence > 0.7
        
        return DetectedLanguage(
            code: finalLanguage,
            confidence: combinedConfidence,
            isReliable: isReliable,
            localizedName: localizedName
        )
    }
    
    private func tokenizeText(_ text: String) -> [String] {
        return text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
    }
    
    private func extractCharacterNGrams(text: String, size: Int = 3) -> [String: Int] {
        let cleanText = text.lowercased().replacingOccurrences(of: "[^a-zäöüßáéíóúàèìòùñç]", with: " ", options: .regularExpression)
        var ngrams: [String: Int] = [:]
        
        let characters = Array(cleanText)
        for i in 0...(characters.count - size) {
            let ngram = String(characters[i..<i+size])
            ngrams[ngram, default: 0] += 1
        }
        
        return ngrams
    }
    
    private func countCommonWordMatches(words: [String], commonWords: [String]) -> Int {
        let commonWordSet = Set(commonWords)
        return words.filter { commonWordSet.contains($0) }.count
    }
    
    private func countSpecialCharMatches(text: String, specialChars: [Character]) -> Int {
        return text.filter { specialChars.contains($0) }.count
    }
    
    private func calculateNGramScore(characterNGrams: [String: Int], language: String) -> Double {
        // Vereinfachte N-Gram Bewertung
        // In einer vollständigen Implementierung würden wir eine N-Gram-Datenbank verwenden
        return Double(characterNGrams.count) * 0.1
    }
    
    private func countStopWordMatches(words: [String], stopWords: Set<String>) -> Int {
        return words.filter { stopWords.contains($0) }.count
    }
    
    private func getLocalizedLanguageName(_ languageCode: String) -> String {
        let languageNames: [String: String] = [
            "de": "Deutsch",
            "en": "English",
            "fr": "Français",
            "es": "Español",
            "it": "Italiano",
            "pt": "Português",
            "nl": "Nederlands",
            "sv": "Svenska",
            "da": "Dansk",
            "no": "Norsk",
            "fi": "Suomi",
            "pl": "Polski",
            "cs": "Čeština",
            "hu": "Magyar",
            "ro": "Română",
            "bg": "Български",
            "hr": "Hrvatski",
            "sk": "Slovenčina",
            "sl": "Slovenščina",
            "et": "Eesti",
            "lv": "Latviešu",
            "lt": "Lietuvių",
            "ru": "Русский",
            "uk": "Українська",
            "be": "Беларуская",
            "zh": "中文",
            "ja": "日本語",
            "ko": "한국어",
            "ar": "العربية",
            "he": "עברית",
            "hi": "हिन्दी",
            "th": "ไทย",
            "vi": "Tiếng Việt",
            "id": "Bahasa Indonesia",
            "ms": "Bahasa Melayu",
            "tr": "Türkçe"
        ]
        
        return languageNames[languageCode] ?? languageCode.uppercased()
    }
    
    // MARK: - Advanced Language Detection
    func detectLanguageChange(text: String, completion: @escaping ([LanguageSegment]) -> Void) {
        let sentences = text.components(separatedBy: .punctuationCharacters)
        var segments: [LanguageSegment] = []
        
        sentences.enumerated().forEach { index, sentence in
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespaces)
            guard !trimmedSentence.isEmpty else { return }
            
            let language = performLanguageDetection(text: trimmedSentence)
            segments.append(LanguageSegment(
                position: index,
                text: trimmedSentence,
                language: language,
                confidence: language.confidence
            ))
        }
        
        completion(segments)
    }
    
    func analyzeLanguageMixing(text: String, completion: @escaping (LanguageMixingAnalysis) -> Void) {
        detectLanguageChange(text: text) { segments in
            let languageCount = segments.reduce(into: [String: Int]()) { dict, segment in
                dict[segment.language.code, default: 0] += 1
            }
            
            let dominantLanguage = languageCount.max { $0.value < $1.value }
            let mixingScore = self.calculateMixingScore(languageCount: languageCount, totalSegments: segments.count)
            let isMixedLanguage = mixingScore > 0.3
            
            completion(LanguageMixingAnalysis(
                isMixedLanguage: isMixedLanguage,
                mixingScore: mixingScore,
                languageDistribution: languageCount,
                dominantLanguage: dominantLanguage?.key ?? "unknown",
                segments: segments
            ))
        }
    }
    
    private func calculateMixingScore(languageCount: [String: Int], totalSegments: Int) -> Double {
        guard totalSegments > 0 else { return 0.0 }
        
        let languageVariety = Double(languageCount.count)
        let maxVariety = 5.0 // Max considered languages for mixing
        
        return min(languageVariety / maxVariety, 1.0)
    }
}

// MARK: - Supporting Data Types
struct LanguageCharacteristics {
    let commonWords: [String]
    let specialChars: [Character]
    let sentenceStructure: SentenceStructure
    let punctuation: [Character]
    
    enum SentenceStructure {
        case svo, sov, vso, osv, vos, v2
    }
}

struct LanguageDetectionResult {
    let languageCode: String
    let confidence: Double
    let nlpBased: Bool = false
    let statisticalBased: Bool = false
}

struct LanguageSegment {
    let position: Int
    let text: String
    let language: DetectedLanguage
    let confidence: Double
}

struct LanguageMixingAnalysis {
    let isMixedLanguage: Bool
    let mixingScore: Double
    let languageDistribution: [String: Int]
    let dominantLanguage: String
    let segments: [LanguageSegment]
}