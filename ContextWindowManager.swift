//
//  ContextWindowManager.swift
//  Intelligente Notizen App
//

import Foundation

// MARK: - Context Window Manager Protocol
protocol ContextWindowManaging: AnyObject {
    func optimizePrompt(_ prompt: String, forContentLength contentLength: Int) async -> String
    func getOptimalWindowSize(for contentType: ContentType, language: PromptLanguage) -> WindowSize
    func splitContentIntoChunks(_ content: String, maxChunkSize: Int) async -> [ContentChunk]
    func calculateTokenCount(for text: String) -> Int
    func getModelLimits() -> [String: ModelLimits]
    func prioritizeContent(_ content: String, prompt: String) async -> PrioritizedContent
}

// MARK: - Context Window Manager
final class ContextWindowManager: ContextWindowManaging {
    
    private let modelLimits: [String: ModelLimits] = [
        "gpt-4": ModelLimits(maxTokens: 8192, maxCharacters: 32000, recommended: 6000),
        "gpt-3.5-turbo": ModelLimits(maxTokens: 4096, maxCharacters: 16000, recommended: 3000),
        "claude-3": ModelLimits(maxTokens: 100000, maxCharacters: 400000, recommended: 80000),
        "gemini-pro": ModelLimits(maxTokens: 32000, maxCharacters: 128000, recommended: 24000),
        "default": ModelLimits(maxTokens: 4000, maxCharacters: 16000, recommended: 3000)
    ]
    
    private let tokenEstimator = TokenEstimator()
    private let contentPrioritizer = ContentPrioritizer()
    
    func optimizePrompt(_ prompt: String, forContentLength contentLength: Int) async -> String {
        let totalTokens = await calculateTokenCount(for: prompt)
        
        // Determine if we need optimization
        if totalTokens <= getOptimalWindowSize(for: .article, language: .german).recommended {
            return prompt
        }
        
        // Apply optimization strategies
        var optimizedPrompt = prompt
        
        // 1. Remove redundant whitespace and formatting
        optimizedPrompt = optimizeFormatting(optimizedPrompt)
        
        // 2. Compress examples and demonstrations
        optimizedPrompt = compressExamples(optimizedPrompt)
        
        // 3. Use placeholders for large content
        optimizedPrompt = replaceLargeContent(optimizedPrompt, contentLength: contentLength)
        
        // 4. Add chunking instructions if still too long
        if await calculateTokenCount(for: optimizedPrompt) > getOptimalWindowSize(for: .article, language: .german).recommended {
            optimizedPrompt = addChunkingInstructions(optimizedPrompt)
        }
        
        return optimizedPrompt
    }
    
    func getOptimalWindowSize(for contentType: ContentType, language: PromptLanguage) -> WindowSize {
        // Adjust limits based on content type and language
        let baseLimits = modelLimits["default"] ?? ModelLimits.default
        
        switch contentType {
        case .code:
            // Code requires more context for proper analysis
            return WindowSize(
                maxTokens: Int(Double(baseLimits.maxTokens) * 1.5),
                maxCharacters: Int(Double(baseLimits.maxCharacters) * 1.5),
                recommended: Int(Double(baseLimits.recommended) * 1.3)
            )
            
        case .article:
            // Articles need context for summary generation
            return WindowSize(
                maxTokens: Int(Double(baseLimits.maxTokens) * 1.2),
                maxCharacters: Int(Double(baseLimits.maxCharacters) * 1.2),
                recommended: baseLimits.recommended
            )
            
        case .email:
            // Emails are typically shorter
            return WindowSize(
                maxTokens: Int(Double(baseLimits.maxTokens) * 0.8),
                maxCharacters: Int(Double(baseLimits.maxCharacters) * 0.8),
                recommended: Int(Double(baseLimits.recommended) * 0.7)
            )
            
        case .meeting:
            // Meeting notes need moderate context
            return WindowSize(
                maxTokens: baseLimits.maxTokens,
                maxCharacters: baseLimits.maxCharacters,
                recommended: baseLimits.recommended
            )
            
        default:
            return baseLimits
        }
    }
    
    func splitContentIntoChunks(_ content: String, maxChunkSize: Int) async -> [ContentChunk] {
        let chunks: [ContentChunk] = []
        let estimatedChunks = await calculateOptimalChunkCount(content, maxChunkSize: maxChunkSize)
        
        if estimatedChunks.count <= 1 {
            return [ContentChunk(
                id: "chunk_1",
                content: content,
                tokenCount: await calculateTokenCount(for: content),
                priority: .high,
                chunkType: .complete
            )]
        }
        
        // Split content intelligently
        return await intelligentlySplitContent(content, targetChunkCount: estimatedChunks.count, maxChunkSize: maxChunkSize)
    }
    
    func calculateTokenCount(for text: String) -> Int {
        return tokenEstimator.estimateTokens(for: text)
    }
    
    func getModelLimits() -> [String: ModelLimits] {
        return modelLimits
    }
    
    func prioritizeContent(_ content: String, prompt: String) async -> PrioritizedContent {
        return await contentPrioritizer.prioritize(content, prompt: prompt)
    }
    
    // MARK: - Private Optimization Methods
    private func optimizeFormatting(_ prompt: String) -> String {
        var optimized = prompt
        
        // Remove excessive line breaks
        optimized = optimized.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )
        
        // Remove excessive spaces
        optimized = optimized.replacingOccurrences(
            of: " {2,}",
            with: " ",
            options: .regularExpression
        )
        
        // Preserve important formatting (headers, code blocks, lists)
        optimized = preserveImportantFormatting(optimized)
        
        return optimized
    }
    
    private func compressExamples(_ prompt: String) -> String {
        var compressed = prompt
        
        // Compress long examples
        let examplePattern = "Beispiel:?[\\s\\S]*?(?=\\n\\n|\\n##|\\n\\*\\*|$)"
        let regex = try? NSRegularExpression(pattern: examplePattern)
        
        if let matches = regex?.matches(in: prompt, range: NSRange(prompt.startIndex..., in: prompt)) {
            for match in matches.reversed() {
                if let range = Range(match.range, in: prompt) {
                    let example = String(prompt[range])
                    if example.count > 200 {
                        let compressedExample = compressExampleText(example)
                        compressed.replaceSubrange(range, with: compressedExample)
                    }
                }
            }
        }
        
        return compressed
    }
    
    private func replaceLargeContent(_ prompt: String, contentLength: Int) -> String {
        var modifiedPrompt = prompt
        
        if contentLength > 1000 {
            // Replace large content sections with placeholders
            modifiedPrompt = modifiedPrompt.replacingOccurrences(
                of: "{content}",
                with: "[Content: \(contentLength) Zeichen - werde in Chunks verarbeitet]"
            )
        }
        
        return modifiedPrompt
    }
    
    private func addChunkingInstructions(_ prompt: String) -> String {
        let chunkingInstructions = """

        **Verarbeitungshinweis**: Der Inhalt wird in Teilen verarbeitet. Bitte arbeite schrittweise und strukturiere deine Antwort übersichtlich.

        **Strukturierte Antwort**:
        - Verwende klare Abschnitte und Überschriften
        - Nummeriere wichtige Punkte
        - Fokussiere auf die Hauptinformationen
        """
        
        return prompt + chunkingInstructions
    }
    
    private func preserveImportantFormatting(_ text: String) -> String {
        // This would preserve markdown headers, code blocks, and list structures
        // Implementation would be more complex in a real scenario
        return text
    }
    
    private func compressExampleText(_ example: String) -> String {
        // Keep first and last sentence, compress middle
        let sentences = example.components(separatedBy: .punctuationCharacters)
        if sentences.count > 3 {
            let first = sentences[0]
            let last = sentences[sentences.count - 1]
            return "\(first)...[komprimiert]...\(last)"
        }
        return example.count > 200 ? String(example.prefix(100)) + "...[gekürzt]..." : example
    }
    
    private func calculateOptimalChunkCount(_ content: String, maxChunkSize: Int) async -> [ContentChunk] {
        let tokenCount = await calculateTokenCount(for: content)
        let maxTokensPerChunk = maxChunkSize / 4 // Rough token estimation
        
        let estimatedChunks = Int(ceil(Double(tokenCount) / Double(maxTokensPerChunk)))
        return Array(repeating: ContentChunk(id: "placeholder", content: "", tokenCount: 0, priority: .medium, chunkType: .partial), count: estimatedChunks)
    }
    
    private func intelligentlySplitContent(_ content: String, targetChunkCount: Int, maxChunkSize: Int) async -> [ContentChunk] {
        // Intelligent content splitting logic
        let paragraphs = content.components(separatedBy: "\n\n")
        var chunks: [ContentChunk] = []
        
        var currentChunk = ""
        var currentChunkTokens = 0
        
        for paragraph in paragraphs {
            let paragraphTokens = await calculateTokenCount(for: paragraph)
            
            if currentChunkTokens + paragraphTokens > maxChunkSize && !currentChunk.isEmpty {
                // Save current chunk
                chunks.append(createChunk(from: currentChunk, chunkIndex: chunks.count + 1))
                
                // Start new chunk
                currentChunk = paragraph
                currentChunkTokens = paragraphTokens
            } else {
                if !currentChunk.isEmpty {
                    currentChunk += "\n\n"
                }
                currentChunk += paragraph
                currentChunkTokens += paragraphTokens
            }
        }
        
        // Add final chunk
        if !currentChunk.isEmpty {
            chunks.append(createChunk(from: currentChunk, chunkIndex: chunks.count + 1))
        }
        
        return chunks
    }
    
    private func createChunk(from content: String, chunkIndex: Int) -> ContentChunk {
        return ContentChunk(
            id: "chunk_\(chunkIndex)",
            content: content,
            tokenCount: content.count / 4, // Rough estimation
            priority: chunkIndex == 1 ? .high : .medium,
            chunkType: .partial
        )
    }
}

// MARK: - Supporting Data Types
struct WindowSize {
    let maxTokens: Int
    let maxCharacters: Int
    let recommended: Int
    
    static let `default` = WindowSize(maxTokens: 4000, maxCharacters: 16000, recommended: 3000)
}

struct ModelLimits {
    let maxTokens: Int
    let maxCharacters: Int
    let recommended: Int
}

struct ContentChunk {
    let id: String
    let content: String
    let tokenCount: Int
    let priority: ChunkPriority
    let chunkType: ChunkType
    
    enum ChunkPriority {
        case high, medium, low
    }
    
    enum ChunkType {
        case complete, partial, summary
    }
}

struct PrioritizedContent {
    let primaryContent: String
    let secondaryContent: [String]
    let context: String
    let priority: Double
}

// MARK: - Token Estimator
class TokenEstimator {
    func estimateTokens(for text: String) -> Int {
        // Different languages have different token-to-character ratios
        let germanRatio = 3.8 // German is more token-dense
        let englishRatio = 4.0
        let multilingualRatio = 3.9
        
        // Simple heuristic based on character count
        return Int(Double(text.count) / multilingualRatio)
    }
    
    func estimateTokens(for prompt: String, language: PromptLanguage) -> Int {
        let baseTokens = estimateTokens(for: prompt)
        
        switch language {
        case .german:
            return Int(Double(baseTokens) * 1.1) // German text often needs more tokens
        case .english:
            return baseTokens
        case .multilingual:
            return Int(Double(baseTokens) * 1.05)
        }
    }
}

// MARK: - Content Prioritizer
class ContentPrioritizer {
    func prioritize(_ content: String, prompt: String) async -> PrioritizedContent {
        let sentences = content.components(separatedBy: .punctuationCharacters)
        var primarySentences: [String] = []
        var secondarySentences: [String] = []
        
        // Simple prioritization based on position and keywords
        for (index, sentence) in sentences.enumerated() {
            let priority = calculateSentencePriority(sentence, position: index, totalCount: sentences.count)
            
            if priority > 0.7 {
                primarySentences.append(sentence)
            } else {
                secondarySentences.append(sentence)
            }
        }
        
        // Build prioritized content
        let primaryContent = primarySentences.joined(separator: " ")
        let secondaryContent = secondarySentences.suffix(5) // Keep top 5 secondary items
        let context = "Content für Prompt-Optimierung"
        
        return PrioritizedContent(
            primaryContent: primaryContent,
            secondaryContent: Array(secondaryContent),
            context: context,
            priority: Double(primarySentences.count) / Double(sentences.count)
        )
    }
    
    private func calculateSentencePriority(_ sentence: String, position: Int, totalCount: Int) -> Double {
        var priority = 0.0
        
        // Position-based priority
        if position < totalCount / 4 {
            priority += 0.4 // First quarter gets higher priority
        }
        
        // Length-based priority
        let length = Double(sentence.count)
        if length > 50 && length < 200 {
            priority += 0.2 // Medium length sentences are often more informative
        }
        
        // Keyword-based priority
        let importantKeywords = ["wichtig", "entscheidend", "summary", "zusammenfassung", "erste", "letzte"]
        let lowercaseSentence = sentence.lowercased()
        
        for keyword in importantKeywords {
            if lowercaseSentence.contains(keyword) {
                priority += 0.3
                break
            }
        }
        
        return min(priority, 1.0)
    }
}