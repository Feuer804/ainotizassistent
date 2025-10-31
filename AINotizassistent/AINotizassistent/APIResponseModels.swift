//
//  APIResponseModels.swift
//  AINotizassistent
//
//  Gemeinsame API Response Models für alle Provider
//

import Foundation

// MARK: - OpenAI Response Models

struct OpenAIChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIMessage
    let finishReason: String
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}

struct OpenAIImageResponse: Codable {
    let created: Int
    let data: [OpenAIImageData]
}

struct OpenAIImageData: Codable {
    let url: String?
    let revised_prompt: String?
    let b64_json: String?
}

struct OpenAIModelsResponse: Codable {
    let object: String
    let data: [OpenAIModelData]
}

struct OpenAIModelData: Codable {
    let id: String
    let object: String
    let created: Int
    let owned_by: String
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIErrorMessage
}

struct OpenAIErrorMessage: Codable {
    let message: String
    let type: String?
    let code: String?
}

struct TranscriptionResponse: Codable {
    let text: String
}

// MARK: - OpenRouter Response Models

struct OpenRouterChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenRouterChoice]
    let usage: OpenRouterUsage?
}

struct OpenRouterChoice: Codable {
    let index: Int
    let message: OpenRouterMessage
    let finishReason: String
}

struct OpenRouterMessage: Codable {
    let role: String
    let content: String
}

struct OpenRouterUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}

struct OpenRouterModelsResponse: Codable {
    let object: String
    let data: [OpenRouterModelInfo]
}

struct OpenRouterModelInfo: Codable {
    let id: String
    let name: String
    let pricing: ModelPricing
    let contextLength: Int
    let architecture: OpenRouterArchitecture
    let topProvider: OpenRouterTopProvider
}

struct OpenRouterArchitecture: Codable {
    let modality: String
    let tokenizer: String
    let instructType: String?
}

struct OpenRouterTopProvider: Codable {
    let modality: String
}

struct OpenRouterErrorResponse: Codable {
    let error: OpenRouterErrorMessage
}

struct OpenRouterErrorMessage: Codable {
    let message: String
    let type: String?
    let code: String?
}

struct CreditsResponse: Codable {
    let data: CreditsInfo
}

// MARK: - Notion Response Models

struct NotionSearchResponse: Codable {
    let object: String
    let results: [NotionSearchResult]
    let next_cursor: String?
    let has_more: Bool
}

struct NotionDatabaseQueryResponse: Codable {
    let object: String
    let results: [NotionPage]
    let next_cursor: String?
    let has_more: Bool
}

struct NotionUser: Codable {
    let object: String
    let id: String
    let type: String
    let name: String
    let avatar_url: String?
    let person: NotionPerson?
    let bot: NotionBot?
}

struct NotionPerson: Codable {
    let email: String
}

struct NotionBot: Codable {
    let owner: NotionOwner?
}

struct NotionOwner: Codable {
    let type: String
    let workspace: Bool
}

struct NotionDatabase: Codable {
    let object: String
    let id: String
    let created_time: String
    let last_edited_time: String
    let title: [NotionRichText]
    let description: [NotionRichText]?
    let properties: [String: NotionProperty]
    let parent: [String: String]
}

struct NotionPage: Codable {
    let object: String
    let id: String
    let created_time: String
    let last_edited_time: String
    let properties: [String: NotionProperty]
    let parent: [String: String]
    let url: String
}

struct NotionRichText: Codable {
    let type: String
    let text: NotionText
}

struct NotionText: Codable {
    let content: String
    let link: String?
}

struct NotionProperty: Codable {
    let id: String
    let type: String
    let title: [NotionRichText]?
    let rich_text: [NotionRichText]?
    let number: Int?
    let select: NotionSelect?
    let multi_select: [NotionSelect]?
    let date: NotionDate?
    let people: [NotionUser]?
    let files: [NotionFile]?
    let checkbox: Bool?
    let url: String?
    let email: String?
    let phone_number: String?
}

struct NotionSelect: Codable {
    let id: String?
    let name: String
    let color: String
}

struct NotionDate: Codable {
    let start: String
    let end: String?
    let time_zone: String?
}

struct NotionFile: Codable {
    let name: String
    let files: [NotionFileObject]?
}

struct NotionFileObject: Codable {
    let type: String
    let file: NotionFileDetails?
    let external: NotionExternalFile?
}

struct NotionFileDetails: Codable {
    let url: String
    let expiry_time: String
}

struct NotionExternalFile: Codable {
    let url: String
}

// MARK: - Whisper Response Models

struct WhisperTranscription: Codable, Identifiable {
    let id = UUID()
    let text: String
    let language: String?
    let duration: Double?
    let segments: [WhisperSegment]?
    let created_at: Date
    var isTranslation: Bool = false
    
    var wordCount: Int {
        return text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    var readingTime: TimeInterval {
        return Double(wordCount) / 200 * 60 // Assuming 200 words per minute
    }
}

struct WhisperSegment: Codable {
    let id: Int
    let seek: Int
    let start: Double
    let end: Double
    let text: String
    let tokens: [Int]
    let temperature: Double
    let avg_logprob: Double
    let compression_ratio: Double
    let no_speech_prob: Double
}

// MARK: - Common Models

enum SearchResult {
    case page(NotionPage)
    case database(NotionDatabase)
}

struct CreditsInfo: Codable {
    let credits: Double
    let currency: String
    let totalCreditsUsed: Double
    let totalCreditsPurchased: Double
    let nextReset: Date?
}

struct ModelPricing: Codable {
    let prompt: String
    let completion: String
    let image: String?
}

// MARK: - Utility Extensions

extension OpenAIChatResponse {
    var firstMessage: String? {
        return choices.first?.message.content
    }
    
    var totalTokens: Int {
        return usage?.totalTokens ?? 0
    }
    
    var cost: Double {
        // Simplified cost calculation
        guard let usage = usage else { return 0.0 }
        
        // Example pricing (should be updated with actual values)
        let inputCost = Double(usage.promptTokens) * 0.0005 / 1000
        let outputCost = Double(usage.completionTokens) * 0.0015 / 1000
        
        return inputCost + outputCost
    }
}

extension OpenRouterChatResponse {
    var firstMessage: String? {
        return choices.first?.message.content
    }
    
    var totalTokens: Int {
        return usage?.totalTokens ?? 0
    }
    
    var cost: Double {
        // Would need model-specific pricing
        guard let usage = usage else { return 0.0 }
        return Double(usage.totalTokens) * 0.0001 // Placeholder
    }
}

extension WhisperTranscription {
    var confidence: Double {
        guard let segments = segments, !segments.isEmpty else { return 0.0 }
        
        let totalConfidence = segments.reduce(0.0) { $0 + (1.0 - $1.no_speech_prob) }
        return totalConfidence / Double(segments.count)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "Unbekannt" }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else {
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
    
    var readabilityScore: Int {
        // Simple readability calculation based on sentence count and word length
        let sentences = text.components(separatedBy: .punctuationCharacters).filter { !$0.isEmpty }
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        guard !sentences.isEmpty && !words.isEmpty else { return 0 }
        
        let avgWordsPerSentence = Double(words.count) / Double(sentences.count)
        let avgWordLength = Double(words.joined().count) / Double(words.count)
        
        // Simple scoring (0-100)
        let score = Int((100 - (avgWordsPerSentence * 5)) - (avgWordLength * 5))
        return max(0, min(100, score))
    }
}

// MARK: - Validation Helpers

extension String {
    var isValidOpenAIKey: Bool {
        return hasPrefix("sk-") && count >= 50
    }
    
    var isValidOpenRouterKey: Bool {
        return hasPrefix("sk-or-") && count >= 50
    }
    
    var isValidNotionKey: Bool {
        return !isEmpty && count >= 20
    }
    
    var isValidWhisperKey: Bool {
        return hasPrefix("sk-") && count >= 50
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        return formatter
    }()
    
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}