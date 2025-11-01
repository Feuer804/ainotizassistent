//
//  StructureAnalyzer.swift
//  Content Structure Analysis (headers, lists, etc.)
//

import Foundation
import NaturalLanguage

// MARK: - Structure Analyzer
class StructureAnalyzer {
    private let nlModel = NLTagger(tagSchemes: [.lexicalClass, .nameType])
    
    // Header Patterns für verschiedene Formate
    private let headerPatterns: [HeaderLevel.HeaderLevelType: [String]] = [
        .markdown: ["# ", "## ", "### ", "#### ", "##### ", "###### "],
        .html: ["<h1>", "<h2>", "<h3>", "<h4>", "<h5>", "<h6>"],
        .numbered: ["1. ", "1.1 ", "1.1.1 "],
        .bulleted: ["• ", "- ", "* "],
        .underline: ["=== ", "--- "]
    ]
    
    private let listPatterns = [
        "• ", "- ", "* ", "◦ ", "▪ ", "▫ ",
        "1. ", "2. ", "3. ", "4. ", "5. ",
        "a) ", "b) ", "c) ", "d) ", "e) ",
        "A) ", "B) ", "C) ", "D) ", "E) "
    ]
    
    private let codeBlockPatterns = [
        "```", "```swift", "```javascript", "```python", "```java", "```cpp",
        "    ", "\t", "indent"
    ]
    
    private let linkPatterns = [
        "[",
        "http://", "https://", "www.",
        "mailto:", "tel:", "file:"
    ]
    
    init() {
        nlModel.string = ""
    }
    
    func analyzeStructure(text: String, completion: @escaping (ContentStructure) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let structure = self.performStructureAnalysis(text: text)
            DispatchQueue.main.async {
                completion(structure)
            }
        }
    }
    
    private func performStructureAnalysis(text: String) -> ContentStructure {
        let lines = text.components(separatedBy: .newlines)
        
        // Analysiere verschiedene Strukturkomponenten
        let hasHeaders = self.detectHeaders(in: lines)
        let hasLists = self.detectLists(in: lines)
        let hasLinks = self.detectLinks(in: text)
        let hasImages = self.detectImages(in: text)
        let hasCode = self.detectCodeBlocks(in: lines)
        
        let headerHierarchy = self.extractHeaderHierarchy(lines: lines)
        let listTypes = self.analyzeListTypes(in: lines)
        
        let paragraphCount = self.countParagraphs(in: text)
        let sentenceCount = self.countSentences(in: text)
        let wordCount = self.countWords(in: text)
        
        return ContentStructure(
            hasHeaders: hasHeaders,
            hasLists: hasLists,
            hasLinks: hasLinks,
            hasImages: hasImages,
            hasCode: hasCode,
            headerHierarchy: headerHierarchy,
            listTypes: listTypes,
            paragraphCount: paragraphCount,
            sentenceCount: sentenceCount,
            wordCount: wordCount
        )
    }
    
    private func detectHeaders(in lines: [String]) -> Bool {
        return lines.contains { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            return headerPatterns.values.flatMap { $0 }.contains { pattern in
                trimmedLine.hasPrefix(pattern)
            } || isHeaderByFormat(line: trimmedLine)
        }
    }
    
    private func detectLists(in lines: [String]) -> Bool {
        return lines.contains { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            return listPatterns.contains { pattern in
                trimmedLine.hasPrefix(pattern)
            }
        }
    }
    
    private func detectLinks(in text: String) -> Bool {
        let linkPatterns = ["[", "http://", "https://", "www.", "mailto:"]
        return linkPatterns.contains { pattern in
            text.contains(pattern)
        }
    }
    
    private func detectImages(in text: String) -> Bool {
        let imagePatterns = ["![", ".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"]
        return imagePatterns.contains { pattern in
            text.contains(pattern)
        }
    }
    
    private func detectCodeBlocks(in lines: [String]) -> Bool {
        return lines.contains { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            return codeBlockPatterns.contains { pattern in
                trimmedLine.hasPrefix(pattern) || trimmedLine.contains(pattern)
            } || isCodeByIndentation(line: trimmedLine)
        }
    }
    
    private func extractHeaderHierarchy(lines: [String]) -> [ContentStructure.HeaderLevel] {
        var headers: [ContentStructure.HeaderLevel] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Markdown Headers
            if let headerLevel = detectMarkdownHeader(line: trimmedLine) {
                headers.append(ContentStructure.HeaderLevel(
                    level: headerLevel,
                    text: String(trimmedLine.dropFirst(headerLevel + 1)),
                    position: index
                ))
            }
            
            // HTML Headers
            if let headerLevel = detectHTMLHeader(line: trimmedLine) {
                let headerText = extractTextFromHTMLHeader(line: trimmedLine)
                headers.append(ContentStructure.HeaderLevel(
                    level: headerLevel,
                    text: headerText,
                    position: index
                ))
            }
            
            // Numbered Headers
            if let (level, text) = detectNumberedHeader(line: trimmedLine) {
                headers.append(ContentStructure.HeaderLevel(
                    level: level,
                    text: text,
                    position: index
                ))
            }
        }
        
        return headers
    }
    
    private func detectMarkdownHeader(line: String) -> Int? {
        for (index, pattern) in headerPatterns[.markdown]!.enumerated() {
            if line.hasPrefix(pattern) {
                return index + 1
            }
        }
        return nil
    }
    
    private func detectHTMLHeader(line: String) -> Int? {
        let htmlPatterns = headerPatterns[.html]!
        for (index, pattern) in htmlPatterns.enumerated() {
            if line.lowercased().hasPrefix(pattern.lowercased()) {
                return index + 1
            }
        }
        return nil
    }
    
    private func extractTextFromHTMLHeader(line: String) -> String {
        // Entferne HTML-Tags und extrahiere Text
        let cleanLine = line.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return cleanLine.trimmingCharacters(in: .whitespaces)
    }
    
    private func detectNumberedHeader(line: String) -> (Int, String)? {
        let pattern = #"^(\d+(?:\.\d+)*)\s+(.+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: line.count))
            if let match = matches.first {
                let levelRange = Range(match.range(at: 1), in: line)!
                let textRange = Range(match.range(at: 2), in: line)!
                
                let levelString = String(line[levelRange])
                let level = levelString.components(separatedBy: ".").count
                let text = String(line[textRange])
                
                return (level, text)
            }
        }
        return nil
    }
    
    private func analyzeListTypes(in lines: [String]) -> [ContentStructure.ListType] {
        var listTypes: [ContentStructure.ListType] = []
        
        var inCodeBlock = false
        var codeBlockStartPatterns = ["```", "```swift", "```javascript"]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for code block boundaries
            if codeBlockStartPatterns.contains(trimmedLine) {
                inCodeBlock = !inCodeBlock
                continue
            }
            
            if inCodeBlock {
                continue
            }
            
            // Detect different list types
            if trimmedLine.hasPrefix("1. ") || trimmedLine.hasPrefix("2. ") || 
               trimmedLine.hasPrefix("3. ") || trimmedLine.hasPrefix("a) ") {
                if !listTypes.contains(.numbered) {
                    listTypes.append(.numbered)
                }
            } else if trimmedLine.hasPrefix("• ") || trimmedLine.hasPrefix("- ") || 
                      trimmedLine.hasPrefix("* ") || trimmedLine.hasPrefix("◦ ") {
                if !listTypes.contains(.bullet) {
                    listTypes.append(.bullet)
                }
            } else if trimmedLine.contains("[ ]") || trimmedLine.contains("[x]") {
                if !listTypes.contains(.checkboxes) {
                    listTypes.append(.checkboxes)
                }
            }
        }
        
        return listTypes.isEmpty ? [.none] : listTypes
    }
    
    private func countParagraphs(in text: String) -> Int {
        let paragraphs = text.components(separatedBy: "\n\n")
        return paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private func countSentences(in text: String) -> Int {
        let sentences = text.components(separatedBy: .punctuationCharacters)
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.trimmingCharacters(in: .punctuationCharacters).isEmpty }.count
    }
    
    private func isHeaderByFormat(line: String) -> Bool {
        // Heuristik für Überschriften ohne explizite Marker
        let words = line.components(separatedBy: .whitespaces)
        
        // Kurz und keine Endpunktzeichen
        if words.count <= 8 && !line.contains(".") && !line.contains("!") && !line.contains("?") {
            // Erster Buchstabe großgeschrieben
            if let firstChar = line.first, firstChar.isUppercase {
                // Nächste Zeile ist leer oder Strich (Unterstreichung)
                return true
            }
        }
        
        return false
    }
    
    private func isCodeByIndentation(line: String) -> Bool {
        // Prüfe auf Einrückung als Code-Indikator
        let leadingSpaces = line.prefix { $0 == " " }.count
        return leadingSpaces >= 4 || line.hasPrefix("\t")
    }
    
    // MARK: - Advanced Structure Analysis
    func analyzeDocumentStructure(text: String, completion: @escaping (DocumentStructureAnalysis) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let lines = text.components(separatedBy: .newlines)
            let structure = self.performStructureAnalysis(text: text)
            
            // Analysiere Dokument-Layout
            let layoutAnalysis = self.analyzeDocumentLayout(lines: lines)
            
            // Analysiere Content Flow
            let flowAnalysis = self.analyzeContentFlow(text: text)
            
            // Erkenne Dokument-Typ
            let documentType = self.detectDocumentType(structure: structure, text: text)
            
            // Bewerte Struktur-Qualität
            let qualityScore = self.assessStructureQuality(structure: structure)
            
            let analysis = DocumentStructureAnalysis(
                basicStructure: structure,
                documentType: documentType,
                layoutAnalysis: layoutAnalysis,
                contentFlow: flowAnalysis,
                qualityScore: qualityScore,
                structureRecommendations: self.generateStructureRecommendations(structure: structure)
            )
            
            DispatchQueue.main.async {
                completion(analysis)
            }
        }
    }
    
    private func analyzeDocumentLayout(lines: [String]) -> LayoutAnalysis {
        let totalLines = Double(lines.count)
        
        // Analysiere Textverteilung
        let textLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let emptyLines = lines.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let textLineRatio = Double(textLines.count) / totalLines
        let emptyLineRatio = Double(emptyLines.count) / totalLines
        
        // Analysiere Textbreite (Zeichen pro Zeile)
        let lineWidths = textLines.map { Double($0.count) }
        let avgLineWidth = lineWidths.reduce(0, +) / Double(lineWidths.count)
        let maxLineWidth = lineWidths.max() ?? 0
        
        // Erkennungen
        let hasConsistentIndentation = self.hasConsistentIndentation(in: lines)
        let hasVisualHierarchy = self.hasVisualHierarchy(in: lines)
        let hasProperSpacing = emptyLineRatio > 0.1 && emptyLineRatio < 0.3
        
        return LayoutAnalysis(
            textLineRatio: textLineRatio,
            emptyLineRatio: emptyLineRatio,
            averageLineWidth: avgLineWidth,
            maximumLineWidth: maxLineWidth,
            hasConsistentIndentation: hasConsistentIndentation,
            hasVisualHierarchy: hasVisualHierarchy,
            hasProperSpacing: hasProperSpacing
        )
    }
    
    private func analyzeContentFlow(text: String) -> ContentFlowAnalysis {
        let sentences = text.components(separatedBy: .punctuationCharacters)
        let sentencesWithContent = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Analysiere Satzlängen-Variabilität
        let sentenceLengths = sentencesWithContent.map { sentence in
            sentence.components(separatedBy: .whitespaces).count
        }
        
        let avgSentenceLength = sentenceLengths.reduce(0, +) / Double(sentenceLengths.count)
        let sentenceLengthVariance = calculateVariance(values: sentenceLengths)
        
        // Analysiere Paragraph-Übergänge
        let paragraphTransitions = self.analyzeParagraphTransitions(text: text)
        
        return ContentFlowAnalysis(
            averageSentenceLength: avgSentenceLength,
            sentenceLengthVariance: sentenceLengthVariance,
            paragraphTransitions: paragraphTransitions,
            coherenceScore: self.calculateCoherenceScore(sentences: sentencesWithContent)
        )
    }
    
    private func detectDocumentType(structure: ContentStructure, text: String) -> DocumentType {
        // Kombiniere verschiedene Indikatoren für Dokumenttyp-Erkennung
        let textLower = text.lowercased()
        
        // E-Mail Indikatoren
        if textLower.contains("von:") || textLower.contains("an:") || textLower.contains("betreff:") ||
           structure.hasHeaders && structure.headerHierarchy.isEmpty && text.count < 2000 {
            return .email
        }
        
        // Meeting Protokoll Indikatoren
        if textLower.contains("meeting") || textLower.contains("besprechung") || 
           textLower.contains("teilnehmer") || textLower.contains("protokoll") ||
           structure.hasHeaders && structure.headerHierarchy.contains(where: { $0.level <= 2 }) {
            return .meeting
        }
        
        // Artikel/Nachricht Indikatoren
        if structure.hasHeaders && structure.hasLinks && structure.wordCount > 500 {
            return .article
        }
        
        // Code-Dokumentation
        if structure.hasCode && (textLower.contains("function") || textLower.contains("class") || 
                                 textLower.contains("def ") || textLower.contains("func ")) {
            return .code
        }
        
        // Tutorial/How-to
        if structure.hasLists && structure.listTypes.contains(.numbered) && 
           (textLower.contains("schritt") || textLower.contains("step") || textLower.contains("wie")) {
            return .tutorial
        }
        
        // Forschungsbericht
        if structure.hasHeaders && structure.headerHierarchy.contains(where: { $0.level <= 3 }) &&
           (textLower.contains("studie") || textLower.contains("analyse") || textLower.contains("ergebnis")) {
            return .research
        }
        
        return .general
    }
    
    private func assessStructureQuality(structure: ContentStructure) -> Double {
        var score = 0.0
        
        // Header-Struktur (25%)
        if structure.hasHeaders {
            score += 0.25
            if structure.headerHierarchy.count > 2 {
                score += 0.1 // Bonus für mehrere Header-Ebenen
            }
        }
        
        // Listen-Struktur (20%)
        if structure.hasLists {
            score += 0.2
            if structure.listTypes.count > 1 {
                score += 0.05 // Bonus für Vielfalt
            }
        }
        
        // Konsistente Formatierung (20%)
        let formattingScore = calculateFormattingConsistency(structure: structure)
        score += formattingScore * 0.2
        
        // Text-Organisation (15%)
        if structure.paragraphCount > 1 {
            score += 0.15
        }
        
        // Satzlängen-Variabilität (10%)
        if structure.sentenceCount > 0 {
            score += 0.1
        }
        
        // Code-Struktur (10%)
        if structure.hasCode {
            score += 0.1
        }
        
        return min(score, 1.0)
    }
    
    private func generateStructureRecommendations(structure: ContentStructure) -> [StructureRecommendation] {
        var recommendations: [StructureRecommendation] = []
        
        // Header-Empfehlungen
        if !structure.hasHeaders && structure.wordCount > 200 {
            recommendations.append(StructureRecommendation(
                type: .addHeaders,
                priority: .medium,
                message: "Überschriften hinzufügen für bessere Struktur",
                suggestion: "Verwenden Sie Überschriften zur Gliederung des Inhalts"
            ))
        }
        
        // Listen-Empfehlungen
        if structure.hasHeaders && structure.wordCount > 300 && !structure.hasLists {
            recommendations.append(StructureRecommendation(
                type: .addLists,
                priority: .low,
                message: "Listen verwenden für Punktelisten",
                suggestion: "Nummerierte oder Aufzählungslisten können Informationen besser strukturieren"
            ))
        }
        
        // Paragraph-Empfehlungen
        if structure.paragraphCount == 1 && structure.wordCount > 150 {
            recommendations.append(StructureRecommendation(
                type: .splitParagraphs,
                priority: .medium,
                message: "Text in Absätze aufteilen",
                suggestion: "Längere Texte sollten in mehrere Absätze unterteilt werden"
            ))
        }
        
        // Code-Formatierung
        if structure.hasCode && !structure.hasHeaders {
            recommendations.append(StructureRecommendation(
                type: .formatCode,
                priority: .high,
                message: "Code-Blöcke formatieren",
                suggestion: "Verwenden Sie Markdown-Syntax für Code-Blöcke (```code```)"
            ))
        }
        
        return recommendations
    }
    
    private func hasConsistentIndentation(in lines: [String]) -> Bool {
        let indentations = lines.compactMap { line -> Int? in
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { return nil }
            return line.prefix { $0 == " " }.count
        }
        
        guard !indentations.isEmpty else { return false }
        
        let avgIndentation = indentations.reduce(0, +) / Double(indentations.count)
        let variance = calculateVariance(values: indentations)
        
        // Niedrige Varianz bedeutet konsistente Einrückung
        return variance < 4.0
    }
    
    private func hasVisualHierarchy(in lines: [String]) -> Bool {
        return structureHasHierarchicalHeaders(lines: lines)
    }
    
    private func structureHasHierarchicalHeaders(lines: [String]) -> Bool {
        var headerLevels: [Int] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if let level = detectMarkdownHeader(line: trimmedLine) {
                headerLevels.append(level)
            } else if let level = detectHTMLHeader(line: trimmedLine) {
                headerLevels.append(level)
            }
        }
        
        // Prüfe auf logische Hierarchie
        return headerLevels.count > 1 && headerLevels.sorted() == headerLevels
    }
    
    private func calculateFormattingConsistency(structure: ContentStructure) -> Double {
        var consistencyScore = 0.0
        var checks = 0
        
        // Check 1: Header Consistency
        if structure.hasHeaders {
            checks += 1
            if structure.headerHierarchy.count > 0 {
                let maxLevel = structure.headerHierarchy.map { $0.level }.max() ?? 0
                if maxLevel <= 4 { // Reasonable header depth
                    consistencyScore += 1.0
                }
            }
        }
        
        // Check 2: List Consistency
        if structure.hasLists {
            checks += 1
            if !structure.listTypes.contains(.none) {
                consistencyScore += 1.0
            }
        }
        
        // Check 3: Code Formatting
        if structure.hasCode {
            checks += 1
            // Code should have consistent indentation
            consistencyScore += 1.0
        }
        
        return checks > 0 ? consistencyScore / Double(checks) : 0.0
    }
    
    private func calculateVariance(values: [Int]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let squaredDiffs = values.map { pow(Double($0) - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
    
    private func analyzeParagraphTransitions(text: String) -> [ParagraphTransition] {
        let paragraphs = text.components(separatedBy: "\n\n")
        var transitions: [ParagraphTransition] = []
        
        for (index, paragraph) in paragraphs.enumerated() {
            guard index < paragraphs.count - 1 else { break }
            
            let currentParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            let nextParagraph = paragraphs[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !currentParagraph.isEmpty && !nextParagraph.isEmpty {
                let transitionType = determineTransitionType(
                    current: currentParagraph,
                    next: nextParagraph
                )
                
                transitions.append(ParagraphTransition(
                    fromIndex: index,
                    toIndex: index + 1,
                    transitionType: transitionType,
                    currentParagraph: currentParagraph,
                    nextParagraph: nextParagraph
                ))
            }
        }
        
        return transitions
    }
    
    private func determineTransitionType(current: String, next: String) -> ParagraphTransition.TransitionType {
        // Heuristiken für Übergangstypen
        let currentLower = current.lowercased()
        let nextLower = next.lowercased()
        
        // Kontrast
        if currentLower.contains("aber") || currentLower.contains("however") || currentLower.contains("dennoch") {
            return .contrast
        }
        
        // Fortsetzung
        if currentLower.contains("zusätzlich") || currentLower.contains("weiterhin") || 
           currentLower.contains("furthermore") || currentLower.contains("additionally") {
            return .continuation
        }
        
        // Zusammenfassung
        if currentLower.contains("schließlich") || currentLower.contains("finally") || currentLower.contains("zusammenfassend") {
            return .summary
        }
        
        // Neue Idee
        if currentLower.contains("desweiteren") || currentLower.contains("auf der anderen seite") {
            return .newIdea
        }
        
        return .smooth
    }
    
    private func calculateCoherenceScore(sentences: [String]) -> Double {
        guard sentences.count > 1 else { return 1.0 }
        
        // Vereinfachte Kohärenz-Bewertung basierend auf Wortwiederholungen
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
        
        return coherenceScore / Double(sentences.count - 1)
    }
}

// MARK: - Supporting Data Types
struct DocumentStructureAnalysis {
    let basicStructure: ContentStructure
    let documentType: DocumentType
    let layoutAnalysis: LayoutAnalysis
    let contentFlow: ContentFlowAnalysis
    let qualityScore: Double
    let structureRecommendations: [StructureRecommendation]
}

enum DocumentType {
    case email, article, meeting, code, tutorial, research, general
}

struct LayoutAnalysis {
    let textLineRatio: Double
    let emptyLineRatio: Double
    let averageLineWidth: Double
    let maximumLineWidth: Double
    let hasConsistentIndentation: Bool
    let hasVisualHierarchy: Bool
    let hasProperSpacing: Bool
}

struct ContentFlowAnalysis {
    let averageSentenceLength: Double
    let sentenceLengthVariance: Double
    let paragraphTransitions: [ParagraphTransition]
    let coherenceScore: Double
}

struct ParagraphTransition {
    let fromIndex: Int
    let toIndex: Int
    let transitionType: TransitionType
    let currentParagraph: String
    let nextParagraph: String
    
    enum TransitionType {
        case smooth, contrast, continuation, summary, newIdea
    }
}

struct StructureRecommendation {
    let type: RecommendationType
    let priority: RecommendationPriority
    let message: String
    let suggestion: String
    
    enum RecommendationType {
        case addHeaders, addLists, splitParagraphs, formatCode, improveFormatting, other
    }
    
    enum RecommendationPriority {
        case low, medium, high, critical
    }
}