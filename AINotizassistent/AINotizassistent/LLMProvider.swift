//
//  LLMProvider.swift
//  Intelligente Notizen App
//
//  Unified LLM Provider Interface
//  - Abstraction layer between different LLM providers
//  - Provider selection and routing
//  - Cost and performance optimization
//  - Unified API for all LLM operations
//

import Foundation
import Network

// MARK: - Provider Types
enum ProviderType: String, CaseIterable {
    case openai = "OpenAI"
    case openrouter = "OpenRouter"
    case anthropic = "Anthropic"
    case huggingface = "Hugging Face"
    case cohere = "Cohere"
    
    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .openrouter: return "OpenRouter"
        case .anthropic: return "Anthropic"
        case .huggingface: return "Hugging Face"
        case .cohere: return "Cohere"
        }
    }
}

// MARK: - Model Information
struct ModelInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let provider: ProviderType
    let contextLength: Int
    let supportsStreaming: Bool
    let supportsFunctionCalling: Bool
    let costPer1kTokens: CostInfo
    let capabilities: [ModelCapability]
    let performanceScore: Double
    
    var displayName: String {
        return "\(provider.displayName) \(name)"
    }
    
    var isAvailable: Bool {
        return !id.isEmpty && contextLength > 0
    }
}

struct CostInfo {
    let prompt: Double
    let completion: Double
    
    var totalFor1kTokens: Double {
        return prompt + completion
    }
    
    func calculateCost(for usage: Usage) -> Double {
        return (Double(usage.promptTokens) / 1000.0) * prompt +
               (Double(usage.completionTokens) / 1000.0) * completion
    }
}

struct Usage {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let cost: Double
    let timestamp: Date
}

enum ModelCapability: String, CaseIterable {
    case textGeneration = "Text Generation"
    case codeGeneration = "Code Generation"
    case reasoning = "Reasoning"
    case creativeWriting = "Creative Writing"
    case analysis = "Analysis"
    case translation = "Translation"
    case summarization = "Summarization"
    case questionAnswering = "Question Answering"
    case multimodal = "Multimodal"
}

// MARK: - LLM Request and Response
struct LLMRequest {
    let prompt: String
    let systemPrompt: String?
    let maxTokens: Int
    let temperature: Double
    let topP: Double
    let frequencyPenalty: Double
    let presencePenalty: Double
    let model: ModelInfo
    let capabilities: [ModelCapability]
    let metadata: [String: String]?
    
    init(
        prompt: String,
        systemPrompt: String? = nil,
        maxTokens: Int = 1000,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        frequencyPenalty: Double = 0.0,
        presencePenalty: Double = 0.0,
        model: ModelInfo,
        capabilities: [ModelCapability] = [],
        metadata: [String: String]? = nil
    ) {
        self.prompt = prompt
        self.systemPrompt = systemPrompt
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.model = model
        self.capabilities = capabilities
        self.metadata = metadata
    }
}

struct LLMResponse {
    let content: String
    let model: ModelInfo
    let usage: Usage
    let responseTime: TimeInterval
    let qualityScore: Double
    let tokensPerSecond: Double
    let success: Bool
    let error: Error?
    
    var costEfficiency: Double {
        return usage.cost > 0 ? qualityScore / usage.cost : 0
    }
}

// MARK: - Provider Manager
final class ProviderManager: ObservableObject {
    @Published var availableProviders: [ProviderType] = []
    @Published var selectedProvider: ProviderType = .openrouter
    @Published var availableModels: [ModelInfo] = []
    @Published var selectedModel: ModelInfo?
    @Published var isLoading = false
    @Published var lastError: Error?
    
    // Configuration
    private var providerConfigs: [ProviderType: ProviderConfig] = [:]
    
    // OpenRouter client reference
    private var openRouterClient: OpenRouterClient?
    
    init() {
        setupProviders()
        Task {
            await initializeProviders()
        }
    }
    
    private func setupProviders() {
        // Setup provider configurations
        providerConfigs[.openai] = ProviderConfig(
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "",
            baseURL: "https://api.openai.com/v1",
            models: ["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo"]
        )
        
        providerConfigs[.openrouter] = ProviderConfig(
            apiKey: ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? "",
            baseURL: "https://openrouter.ai/api/v1",
            models: [] // Will be loaded dynamically
        )
        
        providerConfigs[.anthropic] = ProviderConfig(
            apiKey: ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? "",
            baseURL: "https://api.anthropic.com/v1",
            models: ["claude-3-haiku", "claude-3-sonnet", "claude-3-opus"]
        )
    }
    
    private func initializeProviders() async {
        await MainActor.run {
            isLoading = true
        }
        
        await loadOpenRouterModels()
        
        await MainActor.run {
            isLoading = false
            refreshAvailableProviders()
        }
    }
    
    private func loadOpenRouterModels() async {
        do {
            let client = OpenRouterClient.shared
            await client.$availableModels.first()
            
            // Wait for models to load
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            let models = await client.availableModels
            
            await MainActor.run {
                let modelInfos = models.map { model in
                    ModelInfo(
                        id: model.id,
                        name: model.name,
                        provider: .openrouter,
                        contextLength: model.contextLength,
                        supportsStreaming: true,
                        supportsFunctionCalling: true,
                        costPer1kTokens: CostInfo(
                            prompt: model.pricing.prompt,
                            completion: model.pricing.completion
                        ),
                        capabilities: getCapabilities(for: model),
                        performanceScore: 0.8 // Default score, will be updated
                    )
                }
                
                self.availableModels.append(contentsOf: modelInfos)
                
                // Set default model
                if let preferredModel = modelInfos.first(where: { $0.id.contains("gpt-3.5-turbo") || $0.name.contains("3.5") }) {
                    self.selectedModel = preferredModel
                } else {
                    self.selectedModel = modelInfos.first
                }
            }
        } catch {
            await MainActor.run {
                self.lastError = error
            }
        }
    }
    
    private func getCapabilities(for model: OpenRouterModel) -> [ModelCapability] {
        var capabilities: [ModelCapability] = [.textGeneration]
        
        if model.id.contains("gpt-4") {
            capabilities.append(contentsOf: [.reasoning, .analysis, .codeGeneration])
        }
        
        if model.id.contains("code") || model.name.lowercased().contains("code") {
            capabilities.append(.codeGeneration)
        }
        
        if model.modality?.contains("image") == true {
            capabilities.append(.multimodal)
        }
        
        if model.id.contains("claude") {
            capabilities.append(contentsOf: [.reasoning, .creativeWriting, .analysis])
        }
        
        return capabilities
    }
    
    private func refreshAvailableProviders() {
        availableProviders = ProviderType.allCases.filter { provider in
            switch provider {
            case .openai:
                return !(providerConfigs[.openai]?.apiKey.isEmpty ?? true)
            case .openrouter:
                return !(providerConfigs[.openrouter]?.apiKey.isEmpty ?? true)
            case .anthropic:
                return !(providerConfigs[.anthropic]?.apiKey.isEmpty ?? true)
            default:
                return false // Not implemented yet
            }
        }
        
        if !availableProviders.contains(selectedProvider) {
            selectedProvider = availableProviders.first ?? .openrouter
        }
    }
}

// MARK: - Provider Configuration
struct ProviderConfig {
    let apiKey: String
    let baseURL: String
    let models: [String]
    
    var isConfigured: Bool {
        return !apiKey.isEmpty
    }
}

// MARK: - Unified LLM Provider
final class UnifiedLLMProvider: ObservableObject {
    static let shared = UnifiedLLMProvider()
    
    @Published var isProcessing = false
    @Published var lastResponse: LLMResponse?
    @Published var totalUsage: [ProviderType: Usage] = [:]
    
    private let providerManager: ProviderManager
    
    init() {
        self.providerManager = ProviderManager()
    }
    
    // MARK: - Chat Completion
    func generateResponse(for request: LLMRequest) async throws -> LLMResponse {
        await MainActor.run {
            isProcessing = true
        }
        
        let startTime = Date()
        
        do {
            let response: LLMResponse
            
            switch request.model.provider {
            case .openrouter:
                response = try await sendToOpenRouter(request: request)
            case .openai:
                response = try await sendToOpenAI(request: request)
            case .anthropic:
                response = try await sendToAnthropic(request: request)
            default:
                throw LLMError.providerNotSupported(request.model.provider)
            }
            
            await MainActor.run {
                self.lastResponse = response
                self.updateTotalUsage(for: request.model.provider, usage: response.usage)
                isProcessing = false
            }
            
            return response
            
        } catch {
            await MainActor.run {
                isProcessing = false
            }
            throw error
        }
    }
    
    // MARK: - Provider-Specific Implementations
    private func sendToOpenRouter(request: LLMRequest) async throws -> LLMResponse {
        let startTime = Date()
        let messages: [[String: String]]
        
        if let systemPrompt = request.systemPrompt {
            messages = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": request.prompt]
            ]
        } else {
            messages = [["role": "user", "content": request.prompt]]
        }
        
        let modelConfig = ModelConfig.from(
            OpenRouterModel(
                id: request.model.id,
                name: request.model.name,
                description: nil,
                contextLength: request.model.contextLength,
                pricing: OpenRouterPricing(
                    prompt: request.model.costPer1kTokens.prompt,
                    completion: request.model.costPer1kTokens.completion,
                    image: nil
                ),
                topProvider: OpenRouterProvider(contextLength: request.model.contextLength, maxContinuationTokens: nil),
                perRequestLimits: OpenRouterRequestLimits(tier: nil, maxTokens: request.maxTokens),
                architecture: ModelArchitecture(modality: "text", tokenizer: "cl100k_base", instructType: nil),
                modality: "text",
                instructType: "text"
            )
        )
        
        let openRouterResponse = try await OpenRouterClient.shared.sendChatMessage(
            messages: messages,
            model: modelConfig,
            temperature: request.temperature,
            maxTokens: request.maxTokens,
            topP: request.topP,
            frequencyPenalty: request.frequencyPenalty,
            presencePenalty: request.presencePenalty
        )
        
        let endTime = Date()
        let responseTime = endTime.timeIntervalSince(startTime)
        
        let usage = Usage(
            promptTokens: openRouterResponse.usage?.promptTokens ?? 0,
            completionTokens: openRouterResponse.usage?.completionTokens ?? 0,
            totalTokens: openRouterResponse.usage?.totalTokens ?? 0,
            cost: openRouterResponse.usage?.cost ?? 0,
            timestamp: startTime
        )
        
        let qualityScore = calculateQualityScore(responseTime: responseTime, usage: usage, content: openRouterResponse.choices.first?.message.content ?? "")
        let tokensPerSecond = responseTime > 0 ? Double(usage.totalTokens) / responseTime : 0
        
        return LLMResponse(
            content: openRouterResponse.choices.first?.message.content ?? "",
            model: request.model,
            usage: usage,
            responseTime: responseTime,
            qualityScore: qualityScore,
            tokensPerSecond: tokensPerSecond,
            success: true,
            error: nil
        )
    }
    
    private func sendToOpenAI(request: LLMRequest) async throws -> LLMResponse {
        // Implementation for OpenAI
        // This would use the existing OpenAI provider from KIProvider.swift
        throw LLMError.notImplemented("OpenAI integration not fully implemented")
    }
    
    private func sendToAnthropic(request: LLMRequest) async throws -> LLMResponse {
        // Implementation for Anthropic
        throw LLMError.notImplemented("Anthropic integration not implemented")
    }
    
    // MARK: - Batch Processing
    func processBatch(requests: [LLMRequest]) async throws -> [LLMResponse] {
        var responses: [LLMResponse] = []
        
        // Process requests concurrently with rate limiting
        let semaphore = DispatchSemaphore(value: 3) // Max 3 concurrent requests
        
        await withTaskGroup(of: LLMResponse?.self) { group in
            for request in requests {
                group.addTask {
                    defer { semaphore.signal() }
                    semaphore.wait()
                    
                    do {
                        return try await self.generateResponse(for: request)
                    } catch {
                        print("Batch request failed: \(error)")
                        return nil
                    }
                }
            }
            
            for await response in group {
                if let response = response {
                    responses.append(response)
                }
            }
        }
        
        return responses
    }
    
    // MARK: - Smart Model Selection
    func selectOptimalModel(for task: LLMTask, preferredProvider: ProviderType? = nil) -> ModelInfo? {
        let models = providerManager.availableModels.filter { $0.isAvailable }
        var suitableModels = models
        
        // Filter by capabilities
        if !task.requiredCapabilities.isEmpty {
            suitableModels = suitableModels.filter { model in
                task.requiredCapabilities.allSatisfy { capability in
                    model.capabilities.contains(capability)
                }
            }
        }
        
        // Filter by provider preference
        if let preferredProvider = preferredProvider {
            suitableModels = suitableModels.filter { $0.provider == preferredProvider }
        }
        
        // Select based on optimization strategy
        switch task.optimizationStrategy {
        case .cost:
            return suitableModels.min { $0.costPer1kTokens.totalFor1kTokens < $1.costPer1kTokens.totalFor1kTokens }
            
        case .performance:
            return suitableModels.max { $0.performanceScore > $1.performanceScore }
            
        case .balanced:
            return suitableModels.min { model in
                let costScore = 1.0 - (model.costPer1kTokens.totalFor1kTokens / 0.01) // Normalize cost
                let performanceScore = model.performanceScore
                return (costScore + performanceScore) / 2.0
            }
        }
    }
    
    // MARK: - Analytics and Optimization
    func getUsageAnalytics(provider: ProviderType? = nil) -> [ModelInfo: (totalCost: Double, totalTokens: Int, avgResponseTime: Double, successRate: Double)] {
        // Implementation would aggregate data from all providers
        return [:]
    }
    
    func optimizeCosts(threshold: Double = 0.001) -> [ModelInfo] {
        return providerManager.availableModels.filter { model in
            model.costPer1kTokens.totalFor1kTokens <= threshold
        }
    }
    
    func getTopPerformingModels(limit: Int = 5) -> [ModelInfo] {
        return providerManager.availableModels
            .sorted { $0.performanceScore > $1.performanceScore }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Private Methods
    private func calculateQualityScore(responseTime: TimeInterval, usage: Usage, content: String) -> Double {
        let responseTimeScore = max(0, 1 - (responseTime / 5.0)) // Penalize slow responses
        let contentScore = min(1.0, Double(content.count) / 100.0) // Basic content length score
        let efficiencyScore = usage.totalTokens > 0 ? 1.0 : 0.5
        
        return (responseTimeScore + contentScore + efficiencyScore) / 3.0
    }
    
    private func updateTotalUsage(for provider: ProviderType, usage: Usage) {
        var existingUsage = totalUsage[provider] ?? Usage(promptTokens: 0, completionTokens: 0, totalTokens: 0, cost: 0, timestamp: Date())
        
        existingUsage = Usage(
            promptTokens: existingUsage.promptTokens + usage.promptTokens,
            completionTokens: existingUsage.completionTokens + usage.completionTokens,
            totalTokens: existingUsage.totalTokens + usage.totalTokens,
            cost: existingUsage.cost + usage.cost,
            timestamp: Date()
        )
        
        totalUsage[provider] = existingUsage
    }
}

// MARK: - Task Definition
struct LLMTask {
    let type: TaskType
    let description: String
    let requiredCapabilities: [ModelCapability]
    let optimizationStrategy: OptimizationStrategy
    let maxCostThreshold: Double?
    let maxResponseTime: TimeInterval?
    
    enum TaskType {
        case textGeneration
        case codeGeneration
        case analysis
        case summarization
        case translation
        case creativeWriting
        case questionAnswering
    }
    
    enum OptimizationStrategy {
        case cost
        case performance
        case balanced
    }
    
    static let textGeneration = LLMTask(
        type: .textGeneration,
        description: "Generate text content",
        requiredCapabilities: [.textGeneration],
        optimizationStrategy: .balanced,
        maxCostThreshold: 0.001,
        maxResponseTime: 3.0
    )
    
    static let codeGeneration = LLMTask(
        type: .codeGeneration,
        description: "Generate and debug code",
        requiredCapabilities: [.codeGeneration],
        optimizationStrategy: .performance,
        maxCostThreshold: 0.002,
        maxResponseTime: 5.0
    )
    
    static let analysis = LLMTask(
        type: .analysis,
        description: "Analyze and interpret data",
        requiredCapabilities: [.analysis, .reasoning],
        optimizationStrategy: .performance,
        maxCostThreshold: 0.002,
        maxResponseTime: 4.0
    )
}

// MARK: - Supporting Types (Compatibility with OpenRouter)
struct OpenRouterModel: Codable {
    let id: String
    let name: String
    let description: String?
    let context_length: Int
    let pricing: OpenRouterPricing
    let top_provider: OpenRouterProvider
    let per_request_limits: OpenRouterRequestLimits?
    let architecture: ModelArchitecture
    let modality: String?
    let instruct_type: String?
}

struct OpenRouterPricing: Codable {
    let prompt: Double
    let completion: Double
    let image: Double?
}

struct OpenRouterProvider: Codable {
    let context_length: Int
    let max_completion_tokens: Int?
}

struct OpenRouterRequestLimits: Codable {
    let tier: String?
    let max_tokens: Int?
}

struct ModelArchitecture: Codable {
    let modality: String
    let tokenizer: String
    let instruct_type: String?
}

// MARK: - Error Handling
enum LLMError: Error, LocalizedError {
    case providerNotSupported(ProviderType)
    case modelNotFound(String)
    case invalidAPIKey(ProviderType)
    case rateLimitExceeded(ProviderType)
    case notImplemented(String)
    case insufficientCredits
    
    var errorDescription: String? {
        switch self {
        case .providerNotSupported(let provider):
            return "Provider \(provider.displayName) wird nicht unterstützt"
        case .modelNotFound(let modelId):
            return "Modell nicht gefunden: \(modelId)"
        case .invalidAPIKey(let provider):
            return "Ungültiger API-Schlüssel für \(provider.displayName)"
        case .rateLimitExceeded(let provider):
            return "Rate Limit überschritten für \(provider.displayName)"
        case .notImplemented(let message):
            return "Funktion noch nicht implementiert: \(message)"
        case .insufficientCredits:
            return "Unzureichende Credits für diese Operation"
        }
    }
}

// MARK: - Provider Factory
final class LLMProviderFactory {
    static func createProvider(for type: ProviderType, config: ProviderConfig) -> LLMProviderProtocol {
        switch type {
        case .openai:
            return OpenAIProviderImpl(config: config)
        case .openrouter:
            return OpenRouterProviderImpl()
        case .anthropic:
            return AnthropicProviderImpl(config: config)
        default:
            fatalError("Provider \(type.displayName) not implemented")
        }
    }
}

protocol LLMProviderProtocol {
    func generateResponse(request: LLMRequest) async throws -> LLMResponse
    func getAvailableModels() async -> [ModelInfo]
    func validateConfiguration() async throws -> Bool
}

struct OpenAIProviderImpl: LLMProviderProtocol {
    let config: ProviderConfig
    
    func generateResponse(request: LLMRequest) async throws -> LLMResponse {
        throw LLMError.notImplemented("OpenAI provider not fully implemented")
    }
    
    func getAvailableModels() async -> [ModelInfo] {
        return config.models.map { modelId in
            ModelInfo(
                id: modelId,
                name: modelId,
                provider: .openai,
                contextLength: 4096,
                supportsStreaming: true,
                supportsFunctionCalling: true,
                costPer1kTokens: CostInfo(prompt: 0.0005, completion: 0.0015),
                capabilities: [.textGeneration, .analysis, .reasoning],
                performanceScore: 0.9
            )
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        return config.isConfigured
    }
}

struct OpenRouterProviderImpl: LLMProviderProtocol {
    func generateResponse(request: LLMRequest) async throws -> LLMResponse {
        return try await UnifiedLLMProvider.shared.generateResponse(for: request)
    }
    
    func getAvailableModels() async -> [ModelInfo] {
        return UnifiedLLMProvider.shared.providerManager.availableModels.filter { $0.provider == .openrouter }
    }
    
    func validateConfiguration() async throws -> Bool {
        let config = ProviderManager().providerConfigs[.openrouter]
        return config?.isConfigured ?? false
    }
}

struct AnthropicProviderImpl: LLMProviderProtocol {
    let config: ProviderConfig
    
    func generateResponse(request: LLMRequest) async throws -> LLMResponse {
        throw LLMError.notImplemented("Anthropic provider not implemented")
    }
    
    func getAvailableModels() async -> [ModelInfo] {
        return config.models.map { modelId in
            ModelInfo(
                id: modelId,
                name: modelId,
                provider: .anthropic,
                contextLength: 200000,
                supportsStreaming: true,
                supportsFunctionCalling: false,
                costPer1kTokens: CostInfo(prompt: 0.00025, completion: 0.00125),
                capabilities: [.textGeneration, .analysis, .reasoning, .creativeWriting],
                performanceScore: 0.95
            )
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        return config.isConfigured
    }
}