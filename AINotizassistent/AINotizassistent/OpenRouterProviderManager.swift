//
//  OpenRouterProviderManager.swift
//  AINotizassistent
//
//  Spezialisierter Manager für OpenRouter API Integration
//

import Foundation
import Network

/// Spezialisierter Manager für OpenRouter API Integration
class OpenRouterProviderManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isInitialized = false
    @Published var availableModels: [OpenRouterModel] = []
    @Published var currentModel: OpenRouterModel = OpenRouterModel.openaiGpt35Turbo
    @Published var isGenerating = false
    @Published var lastRequest: OpenRouterRequest?
    @Published var rateLimitStatus: OpenRouterRateLimitStatus = .unknown
    @Published var creditsInfo: CreditsInfo?
    @Published var usageStats: OpenRouterUsageStats?
    
    // MARK: - OpenRouter Configuration
    
    struct OpenRouterConfig {
        static let baseURL = "https://openrouter.ai/api/v1"
        static let apiVersion = "2023-11-01"
        static let timeoutInterval: TimeInterval = 30
    }
    
    // MARK: - Rate Limiting
    
    struct OpenRouterRateLimitInfo {
        let remaining: Int
        let resetTime: Date
        let windowStart: Date
        
        var isLimited: Bool {
            return remaining <= 0
        }
        
        var timeUntilReset: TimeInterval {
            return resetTime.timeIntervalSinceNow
        }
    }
    
    enum OpenRouterRateLimitStatus {
        case unknown
        case normal
        case approaching
        case limited(interval: TimeInterval)
    }
    
    private var rateLimitInfo: OpenRouterRateLimitInfo?
    private let requestQueue = DispatchQueue(label: "openrouter.requests", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init() {
        setupModels()
        loadCachedUsage()
    }
    
    private func setupModels() {
        availableModels = [
            OpenRouterModel.openaiGpt35Turbo,
            OpenRouterModel.openaiGpt4,
            OpenRouterModel.openaiGpt4Turbo,
            OpenRouterModel.anthropicClaude3Sonnet,
            OpenRouterModel.anthropicClaude3Haiku,
            OpenRouterModel.mistralMixtral8x7B,
            OpenRouterModel.metaLlama2_70b,
            OpenRouterModel.googleGeminiPro,
            OpenRouterModel.cohereCommandR,
            OpenRouterModel.mistralSmall
        ]
    }
    
    // MARK: - API Key Management
    
    var isAPIKeyValid: Bool {
        guard let key = APIKeyManager.shared.getDecryptedKey(for: .openrouter) else { return false }
        return key.hasPrefix("sk-or-")
    }
    
    var currentAPIKey: String? {
        return APIKeyManager.shared.getDecryptedKey(for: .openrouter)
    }
    
    // MARK: - Model Management
    
    func setCurrentModel(_ model: OpenRouterModel) {
        currentModel = model
        saveUserDefaults()
    }
    
    func getModelInfo() -> [String: Any] {
        return [
            "id": currentModel.id,
            "name": currentModel.name,
            "provider": currentModel.provider,
            "contextLength": currentModel.contextLength,
            "inputCost": currentModel.inputCost,
            "outputCost": currentModel.outputCost,
            "description": currentModel.description
        ]
    }
    
    // MARK: - API Requests
    
    func generateText(prompt: String, parameters: OpenRouterParameters = OpenRouterParameters()) async throws -> OpenRouterResponse {
        guard isAPIKeyValid else {
            throw OpenRouterError.invalidAPIKey
        }
        
        guard !isGenerating else {
            throw OpenRouterError.requestInProgress
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                self.isGenerating = true
                
                var request = self.createTextRequest(prompt: prompt, parameters: parameters)
                self.lastRequest = .text(request)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    defer { self.isGenerating = false }
                    
                    if let error = error {
                        continuation.resume(throwing: OpenRouterError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: OpenRouterError.noData)
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        
                        let response = try decoder.decode(OpenRouterChatResponse.self, from: data)
                        
                        // Track usage
                        self.trackUsage(response: response)
                        
                        continuation.resume(returning: .chat(response))
                    } catch {
                        if let openRouterError = try? decoder.decode(OpenRouterErrorResponse.self, from: data) {
                            continuation.resume(throwing: OpenRouterError.apiError(openRouterError.error.message))
                        } else {
                            continuation.resume(throwing: OpenRouterError.decodingError(error.localizedDescription))
                        }
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func listModels() async throws -> [OpenRouterModelInfo] {
        guard isAPIKeyValid else {
            throw OpenRouterError.invalidAPIKey
        }
        
        let url = URL(string: "\(OpenRouterConfig.baseURL)/models")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(currentAPIKey!)", forHTTPHeaderField: "Authorization")
        request.setValue("HTTP-Referer https://example.com", forHTTPHeaderField: "Referer")
        request.setValue("AI Notizassistent", forHTTPHeaderField: "X-Title")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            self.updateRateLimit(from: httpResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let result = try decoder.decode(OpenRouterModelsResponse.self, from: data)
        
        return result.data
    }
    
    func getCurrentCredits() async throws -> CreditsInfo {
        guard isAPIKeyValid else {
            throw OpenRouterError.invalidAPIKey
        }
        
        let url = URL(string: "\(OpenRouterConfig.baseURL)/credits")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(currentAPIKey!)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let result = try decoder.decode(CreditsResponse.self, from: data)
        
        self.creditsInfo = result.data
        return result.data
    }
    
    // MARK: - Request Creation
    
    private func createTextRequest(prompt: String, parameters: OpenRouterParameters) -> URLRequest {
        let url = URL(string: "\(OpenRouterConfig.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(currentAPIKey!)", forHTTPHeaderField: "Authorization")
        request.setValue("HTTP-Referer https://example.com", forHTTPHeaderField: "Referer")
        request.setValue("AI Notizassistent", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = OpenRouterConfig.timeoutInterval
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        var body: [String: Any] = [
            "model": currentModel.id,
            "messages": messages
        ]
        
        if let maxTokens = parameters.maxTokens {
            body["max_tokens"] = maxTokens
        }
        
        if let temperature = parameters.temperature {
            body["temperature"] = temperature
        }
        
        if let topP = parameters.topP {
            body["top_p"] = topP
        }
        
        if let frequencyPenalty = parameters.frequencyPenalty {
            body["frequency_penalty"] = frequencyPenalty
        }
        
        if let presencePenalty = parameters.presencePenalty {
            body["presence_penalty"] = presencePenalty
        }
        
        if let stop = parameters.stop {
            body["stop"] = stop
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    // MARK: - Usage Tracking
    
    private func trackUsage(response: OpenRouterChatResponse) {
        guard let usage = response.usage else { return }
        
        let currentStats = usageStats ?? OpenRouterUsageStats()
        currentStats.totalTokens += usage.totalTokens
        currentStats.promptTokens += usage.promptTokens
        currentStats.completionTokens += usage.completionTokens
        currentStats.requests += 1
        currentStats.lastRequest = Date()
        
        // Calculate estimated cost
        let inputCost = Double(usage.promptTokens) * currentModel.inputCost
        let outputCost = Double(usage.completionTokens) * currentModel.outputCost
        currentStats.costEstimate += inputCost + outputCost
        
        usageStats = currentStats
        saveUsageStats()
        
        // Track in main API Key Manager
        APIKeyManager.shared.trackUsage(for: .openrouter, tokensUsed: usage.totalTokens, cost: inputCost + outputCost)
    }
    
    private func updateRateLimit(from response: HTTPURLResponse) {
        if let remaining = Int(response.value(forHTTPHeaderField: "x-ratelimit-remaining-requests") ?? "0"),
           let resetTimeString = response.value(forHTTPHeaderField: "x-ratelimit-reset-requests"),
           let resetTime = ISO8601DateFormatter().date(from: resetTimeString) {
            
            rateLimitInfo = OpenRouterRateLimitInfo(
                remaining: remaining,
                resetTime: resetTime,
                windowStart: Date()
            )
            
            updateRateLimitStatus()
        }
    }
    
    private func updateRateLimitStatus() {
        guard let info = rateLimitInfo else {
            rateLimitStatus = .unknown
            return
        }
        
        if info.isLimited {
            rateLimitStatus = .limited(interval: info.timeUntilReset)
        } else if info.remaining < 10 {
            rateLimitStatus = .approaching
        } else {
            rateLimitStatus = .normal
        }
    }
    
    // MARK: - UserDefaults
    
    private func saveUserDefaults() {
        UserDefaults.standard.set(currentModel.id, forKey: "openrouter_current_model")
    }
    
    private func loadUserDefaults() {
        if let modelId = UserDefaults.standard.string(forKey: "openrouter_current_model") {
            currentModel = availableModels.first { $0.id == modelId } ?? OpenRouterModel.openaiGpt35Turbo
        }
    }
    
    private func saveUsageStats() {
        if let data = try? JSONEncoder().encode(usageStats) {
            UserDefaults.standard.set(data, forKey: "openrouter_usage_stats")
        }
    }
    
    private func loadCachedUsage() {
        if let data = UserDefaults.standard.data(forKey: "openrouter_usage_stats"),
           let stats = try? JSONDecoder().decode(OpenRouterUsageStats.self, from: data) {
            usageStats = stats
        }
    }
    
    // MARK: - Model Information
    
    func getModelPrices() async throws -> [String: ModelPricing] {
        let models = try await listModels()
        return Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0.pricing) })
    }
    
    func getPopularModels() -> [OpenRouterModel] {
        return [
            OpenRouterModel.openaiGpt35Turbo,
            OpenRouterModel.openaiGpt4Turbo,
            OpenRouterModel.anthropicClaude3Sonnet,
            OpenRouterModel.mistralMixtral8x7B
        ]
    }
}

// MARK: - Supporting Types

struct OpenRouterModel: CaseIterable {
    let id: String
    let name: String
    let provider: String
    let contextLength: Int
    let inputCost: Double
    let outputCost: Double
    let description: String
    
    static let openaiGpt35Turbo = OpenRouterModel(
        id: "openai/gpt-3.5-turbo",
        name: "GPT-3.5 Turbo",
        provider: "OpenAI",
        contextLength: 4096,
        inputCost: 0.0005 / 1000,
        outputCost: 0.0015 / 1000,
        description: "Schnell und kostengünstig für die meisten Aufgaben"
    )
    
    static let openaiGpt4 = OpenRouterModel(
        id: "openai/gpt-4",
        name: "GPT-4",
        provider: "OpenAI",
        contextLength: 8192,
        inputCost: 0.03 / 1000,
        outputCost: 0.06 / 1000,
        description: "Höchste Qualität für komplexe Aufgaben"
    )
    
    static let openaiGpt4Turbo = OpenRouterModel(
        id: "openai/gpt-4-turbo",
        name: "GPT-4 Turbo",
        provider: "OpenAI",
        contextLength: 128000,
        inputCost: 0.01 / 1000,
        outputCost: 0.03 / 1000,
        description: "GPT-4 mit erweiterter Kontextlänge"
    )
    
    static let anthropicClaude3Sonnet = OpenRouterModel(
        id: "anthropic/claude-3-sonnet",
        name: "Claude 3 Sonnet",
        provider: "Anthropic",
        contextLength: 200000,
        inputCost: 0.003 / 1000,
        outputCost: 0.015 / 1000,
        description: "Ausgewogenes Claude 3 Modell"
    )
    
    static let anthropicClaude3Haiku = OpenRouterModel(
        id: "anthropic/claude-3-haiku",
        name: "Claude 3 Haiku",
        provider: "Anthropic",
        contextLength: 200000,
        inputCost: 0.00025 / 1000,
        outputCost: 0.00125 / 1000,
        description: "Schnelles und kostengünstiges Claude 3 Modell"
    )
    
    static let mistralMixtral8x7B = OpenRouterModel(
        id: "mistralai/mixtral-8x7b-instruct",
        name: "Mixtral 8x7B",
        provider: "Mistral AI",
        contextLength: 32768,
        inputCost: 0.00027 / 1000,
        outputCost: 0.00027 / 1000,
        description: "Effizientes Sparse Mixtrural Modell"
    )
    
    static let metaLlama2_70b = OpenRouterModel(
        id: "meta-llama/llama-2-70b-chat",
        name: "Llama 2 70B",
        provider: "Meta",
        contextLength: 4096,
        inputCost: 0.0007 / 1000,
        outputCost: 0.0009 / 1000,
        description: "Meta's Llama 2 70B Chat Modell"
    )
    
    static let googleGeminiPro = OpenRouterModel(
        id: "google/gemini-pro",
        name: "Gemini Pro",
        provider: "Google",
        contextLength: 32768,
        inputCost: 0.0005 / 1000,
        outputCost: 0.0015 / 1000,
        description: "Google's Gemini Pro Modell"
    )
    
    static let cohereCommandR = OpenRouterModel(
        id: "cohere/command-r",
        name: "Command R",
        provider: "Cohere",
        contextLength: 128000,
        inputCost: 0.00015 / 1000,
        outputCost: 0.0006 / 1000,
        description: "Cohere's Command R für RAG-Anwendungen"
    )
    
    static let mistralSmall = OpenRouterModel(
        id: "mistralai/mistral-7b-instruct",
        name: "Mistral 7B",
        provider: "Mistral AI",
        contextLength: 32768,
        inputCost: 0.0001 / 1000,
        outputCost: 0.0001 / 1000,
        description: "Schnelles 7B Modell für einfache Aufgaben"
    )
}

struct OpenRouterParameters {
    var maxTokens: Int?
    var temperature: Double?
    var topP: Double?
    var frequencyPenalty: Double?
    var presencePenalty: Double?
    var stop: [String]?
    
    static let `default` = OpenRouterParameters()
}

enum OpenRouterResponse {
    case chat(OpenRouterChatResponse)
}

enum OpenRouterError: Error, LocalizedError {
    case invalidAPIKey
    case requestInProgress
    case networkError(String)
    case decodingError(String)
    case noData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "OpenRouter API Key ist ungültig oder nicht konfiguriert"
        case .requestInProgress:
            return "Eine Anfrage wird bereits verarbeitet"
        case .networkError(let message):
            return "Netzwerkfehler: \(message)"
        case .decodingError(let message):
            return "Dekodierungsfehler: \(message)"
        case .noData:
            return "Keine Daten erhalten"
        case .apiError(let message):
            return "OpenRouter API Fehler: \(message)"
        }
    }
}

// MARK: - Response Models

struct OpenRouterUsageStats: Codable {
    var totalTokens: Int = 0
    var promptTokens: Int = 0
    var completionTokens: Int = 0
    var requests: Int = 0
    var costEstimate: Double = 0.0
    var lastRequest: Date?
    var dailyUsage: [String: Int] = [:]
    var monthlyUsage: Int = 0
}

enum OpenRouterRequest {
    case text(URLRequest)
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

// MARK: - API Response Models

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

struct OpenRouterTopProvider: Cododer {
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