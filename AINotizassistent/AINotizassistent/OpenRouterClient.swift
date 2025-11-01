//
//  OpenRouterClient.swift
//  Intelligente Notizen App
//
//  Comprehensive OpenRouter API Integration with advanced features
//  - Model selection and management
//  - Cost tracking per model
//  - Failover mechanisms
//  - Load balancing
//  - Performance monitoring
//  - Batch processing
//  - Usage analytics
//

import Foundation
import Network

// MARK: - OpenRouter Models
struct OpenRouterModel: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let contextLength: Int
    let pricing: Pricing
    let topProvider: Provider
    let perRequestLimits: RequestLimits?
    let architecture: ModelArchitecture
    let modality: String?
    let instructType: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case description = "description"
        case contextLength = "context_length"
        case pricing = "pricing"
        case topProvider = "top_provider"
        case perRequestLimits = "per_request_limits"
        case architecture = "architecture"
        case modality = "modality"
        case instructType = "instruct_type"
    }
}

struct Pricing: Codable {
    let prompt: Double
    let completion: Double
    let image: Double?
    
    enum CodingKeys: String, CodingKey {
        case prompt = "prompt"
        case completion = "completion"
        case image = "image"
    }
}

struct Provider: Codable {
    let contextLength: Int
    let maxContinuationTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case contextLength = "context_length"
        case maxContinuationTokens = "max_completion_tokens"
    }
}

struct RequestLimits: Codable {
    let tier: String?
    let maxTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case tier = "tier"
        case maxTokens = "max_tokens"
    }
}

struct ModelArchitecture: Codable {
    let modality: String
    let tokenizer: String
    let instructType: String?
}

// MARK: - OpenRouter Response Models
struct OpenRouterResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
    let systemFingerprint: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case model
        case choices
        case usage
        case systemFingerprint = "system_fingerprint"
    }
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let cost: Double?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case cost = "cost"
    }
}

// MARK: - Model Configuration
struct ModelConfig {
    let id: String
    let name: String
    let provider: String
    let contextLength: Int
    let maxTokens: Int
    let temperature: Double = 0.7
    let topP: Double = 0.9
    let frequencyPenalty: Double = 0.0
    let presencePenalty: Double = 0.0
    
    var displayName: String {
        return "\(provider)/\(name)"
    }
    
    static func from(_ model: OpenRouterModel) -> ModelConfig {
        return ModelConfig(
            id: model.id,
            name: model.name,
            provider: model.id.components(separatedBy: "/").first ?? "unknown",
            contextLength: model.contextLength,
            maxTokens: model.perRequestLimits?.maxTokens ?? 4096
        )
    }
}

// MARK: - Cost Tracking
struct ModelUsage: Codable, Identifiable {
    let id = UUID()
    let modelId: String
    let date: Date
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let cost: Double
    let requestCount: Int
    
    var costPer1kTokens: Double {
        return totalTokens > 0 ? (cost / Double(totalTokens)) * 1000 : 0
    }
    
    var costPerRequest: Double {
        return requestCount > 0 ? cost / Double(requestCount) : 0
    }
}

struct CostTracking {
    private var usageByModel: [String: [ModelUsage]] = [:]
    private let queue = DispatchQueue(label: "cost.tracking", qos: .userInitiated)
    
    mutating func recordUsage(modelId: String, usage: Usage, cost: Double) {
        queue.async {
            let today = Calendar.current.startOfDay(for: Date())
            let usageEntry = ModelUsage(
                modelId: modelId,
                date: today,
                promptTokens: usage.promptTokens,
                completionTokens: usage.completionTokens,
                totalTokens: usage.totalTokens,
                cost: cost,
                requestCount: 1
            )
            
            if var existingUsage = self.usageByModel[modelId] {
                if let todayIndex = existingUsage.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                    let existing = existingUsage[todayIndex]
                    existingUsage[todayIndex] = ModelUsage(
                        modelId: modelId,
                        date: today,
                        promptTokens: existing.promptTokens + usage.promptTokens,
                        completionTokens: existing.completionTokens + usage.completionTokens,
                        totalTokens: existing.totalTokens + usage.totalTokens,
                        cost: existing.cost + cost,
                        requestCount: existing.requestCount + 1
                    )
                } else {
                    existingUsage.append(usageEntry)
                }
            } else {
                self.usageByModel[modelId] = [usageEntry]
            }
        }
    }
    
    func getTotalCost(for modelId: String, period: DateInterval? = nil) -> Double {
        let usage = usageByModel[modelId] ?? []
        let filteredUsage = period != nil ? usage.filter { period!.contains($0.date) } : usage
        return filteredUsage.reduce(0) { $0 + $1.cost }
    }
    
    func getUsageStats(for modelId: String, period: DateInterval? = nil) -> (totalCost: Double, totalTokens: Int, totalRequests: Int) {
        let usage = usageByModel[modelId] ?? []
        let filteredUsage = period != nil ? usage.filter { period!.contains($0.date) } : usage
        return (
            totalCost: filteredUsage.reduce(0) { $0 + $1.cost },
            totalTokens: filteredUsage.reduce(0) { $0 + $1.totalTokens },
            totalRequests: filteredUsage.reduce(0) { $0 + $1.requestCount }
        )
    }
}

// MARK: - Performance Monitoring
struct ModelPerformance: Codable, Identifiable {
    let id = UUID()
    let modelId: String
    let timestamp: Date
    let responseTime: TimeInterval
    let tokensPerSecond: Double
    let success: Bool
    let errorMessage: String?
    
    var qualityScore: Double {
        // Simple quality metric based on response time and success rate
        let responseTimeScore = max(0, 1 - (responseTime / 10.0)) // Penalize slow responses
        let successScore = success ? 1.0 : 0.0
        return (responseTimeScore + successScore) / 2.0
    }
}

struct PerformanceMonitor {
    private var performanceByModel: [String: [ModelPerformance]] = [:]
    private let queue = DispatchQueue(label: "performance.monitor", qos: .userInitiated)
    
    mutating func recordPerformance(modelId: String, responseTime: TimeInterval, success: Bool, error: Error?) {
        queue.async {
            let tokensPerSecond = responseTime > 0 ? 1.0 / responseTime : 0
            let performance = ModelPerformance(
                modelId: modelId,
                timestamp: Date(),
                responseTime: responseTime,
                tokensPerSecond: tokensPerSecond,
                success: success,
                errorMessage: error?.localizedDescription
            )
            
            if self.performanceByModel[modelId] == nil {
                self.performanceByModel[modelId] = []
            }
            
            self.performanceByModel[modelId]?.append(performance)
            
            // Keep only last 1000 entries per model
            if let performances = self.performanceByModel[modelId], performances.count > 1000 {
                self.performanceByModel[modelId] = Array(performances.suffix(1000))
            }
        }
    }
    
    func getAveragePerformance(for modelId: String, lastNSamples: Int = 100) -> (avgResponseTime: TimeInterval, successRate: Double, avgTokensPerSecond: Double) {
        let performances = performanceByModel[modelId] ?? []
        let recentSamples = Array(performances.suffix(lastNSamples))
        
        guard !recentSamples.isEmpty else {
            return (0, 0, 0)
        }
        
        let avgResponseTime = recentSamples.reduce(0.0) { $0 + $1.responseTime } / Double(recentSamples.count)
        let successRate = recentSamples.filter { $0.success }.count > 0 ? Double(recentSamples.filter { $0.success }.count) / Double(recentSamples.count) : 0
        let avgTokensPerSecond = recentSamples.filter { $0.tokensPerSecond > 0 }.reduce(0.0) { $0 + $1.tokensPerSecond } / Double(recentSamples.filter { $0.tokensPerSecond > 0 }.count)
        
        return (avgResponseTime, successRate, avgTokensPerSecond)
    }
}

// MARK: - Failover Strategy
enum FailoverStrategy {
    case roundRobin
    case leastLatency
    case mostReliable
    case costOptimized
    case custom(([ModelConfig]) -> ModelConfig?)
}

struct FailoverManager {
    private var currentIndex = 0
    private let strategy: FailoverStrategy
    
    init(strategy: FailoverStrategy = .roundRobin) {
        self.strategy = strategy
    }
    
    func selectNextModel(from availableModels: [ModelConfig]) -> ModelConfig? {
        guard !availableModels.isEmpty else { return nil }
        
        switch strategy {
        case .roundRobin:
            let selected = availableModels[currentIndex]
            currentIndex = (currentIndex + 1) % availableModels.count
            return selected
            
        case .leastLatency:
            return availableModels.min { $0.id < $1.id } // Would need performance data
            
        case .mostReliable:
            return availableModels.first // Would need reliability data
            
        case .costOptimized:
            return availableModels.min { $0.provider < $1.provider } // Would need cost data
            
        case .custom(let selector):
            return selector(availableModels)
        }
    }
}

// MARK: - Load Balancer
struct LoadBalancer {
    private var requestCounts: [String: Int] = [:]
    
    func selectModel(from models: [ModelConfig]) -> ModelConfig? {
        guard !models.isEmpty else { return nil }
        
        // Simple round-robin with load consideration
        let model = models.min { 
            let count1 = requestCounts[$0.id] ?? 0
            let count2 = requestCounts[$1.id] ?? 0
            return count1 < count2
        }
        
        if let model = model {
            requestCounts[model.id, default: 0] += 1
        }
        
        return model
    }
    
    func resetLoad() {
        requestCounts.removeAll()
    }
}

// MARK: - Batch Request
struct BatchRequest {
    let id = UUID()
    let requests: [ChatMessage]
    let model: ModelConfig
    let temperature: Double
    let maxTokens: Int
    let batchSize: Int = 10
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
        
        init(role: String, content: String) {
            self.role = role
            self.content = content
        }
    }
}

struct BatchResponse {
    let id: UUID
    let responses: [String]
    let totalCost: Double
    let totalTokens: Int
    let processingTime: TimeInterval
}

// MARK: - OpenRouter Client
@MainActor
final class OpenRouterClient: ObservableObject {
    static let shared = OpenRouterClient()
    
    @Published var availableModels: [OpenRouterModel] = []
    @Published var selectedModel: ModelConfig?
    @Published var isLoadingModels = false
    @Published var lastError: Error?
    
    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1"
    private let session: URLSession
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    
    // Advanced Features
    private var costTracking = CostTracking()
    private var performanceMonitor = PerformanceMonitor()
    private var failoverManager = FailoverManager()
    private var loadBalancer = LoadBalancer()
    
    // Rate limiting
    private var requestTimestamps: [Date] = []
    private let maxRequestsPerMinute = 100
    
    private init() {
        self.apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? ""
        self.session = URLSession.shared
        
        jsonDecoder.dateDecodingStrategy = .iso8601
        jsonEncoder.dateEncodingStrategy = .iso8601
        
        Task {
            await loadModels()
        }
    }
    
    // MARK: - Model Management
    func loadModels() async {
        guard !apiKey.isEmpty else {
            print("OpenRouter API key not found")
            return
        }
        
        isLoadingModels = true
        
        do {
            let request = createRequest(endpoint: "/models", method: "GET")
            let (data, _) = try await session.data(for: request)
            
            let response = try JSONDecoder().decode(OpenRouterModelsResponse.self, from: data)
            await MainActor.run {
                self.availableModels = response.data
                if let firstModel = response.data.first {
                    self.selectedModel = ModelConfig.from(firstModel)
                }
            }
            
        } catch {
            await MainActor.run {
                self.lastError = error
            }
            print("Failed to load models: \(error)")
        }
        
        await MainActor.run {
            isLoadingModels = false
        }
    }
    
    func getModels(by provider: String? = nil) -> [OpenRouterModel] {
        if let provider = provider {
            return availableModels.filter { $0.id.hasPrefix(provider + "/") }
        }
        return availableModels
    }
    
    func getModels(byCapability capability: String) -> [OpenRouterModel] {
        return availableModels.filter { model in
            switch capability.lowercased() {
            case "coding":
                return model.architecture.modality.contains("text") && 
                       (model.id.contains("code") || model.name.lowercased().contains("code"))
            case "reasoning":
                return model.id.contains("gpt-4") || model.id.contains("claude-3")
            case "fast":
                return model.pricing.prompt < 0.001 && model.pricing.completion < 0.002
            case "multimodal":
                return model.modality?.contains("image") == true
            default:
                return true
            }
        }
    }
    
    // MARK: - Chat Completion
    func sendChatMessage(
        messages: [[String: String]],
        model: ModelConfig? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil,
        customHeaders: [String: String] = nil
    ) async throws -> ChatResponse {
        
        let startTime = Date()
        let selectedModel = model ?? selectedModel
        
        guard let selectedModel = selectedModel else {
            throw OpenRouterError.noModelSelected
        }
        
        try await validateRateLimit()
        
        let requestBody = ChatRequest(
            model: selectedModel.id,
            messages: messages.map { ChatMessage(role: $0["role"] ?? "", content: $0["content"] ?? "") },
            temperature: temperature ?? selectedModel.temperature,
            maxTokens: maxTokens ?? selectedModel.maxTokens,
            topP: topP ?? selectedModel.topP,
            frequencyPenalty: frequencyPenalty ?? selectedModel.frequencyPenalty,
            presencePenalty: presencePenalty ?? selectedModel.presencePenalty
        )
        
        let request = createRequest(
            endpoint: "/chat/completions",
            method: "POST",
            body: requestBody,
            customHeaders: customHeaders
        )
        
        let response: ChatResponse
        var success = false
        var error: Error?
        
        do {
            let (data, _) = try await session.data(for: request)
            response = try JSONDecoder().decode(ChatResponse.self, from: data)
            success = true
            
            // Track usage and cost
            if let usage = response.usage {
                let cost = calculateCost(for: selectedModel, usage: usage)
                costTracking.recordUsage(modelId: selectedModel.id, usage: usage, cost: cost)
            }
            
        } catch {
            error = error
            throw error
        }
        
        // Record performance
        let responseTime = Date().timeIntervalSince(startTime)
        performanceMonitor.recordPerformance(modelId: selectedModel.id, responseTime: responseTime, success: success, error: error)
        
        return response
    }
    
    // MARK: - Batch Processing
    func processBatchRequests(_ requests: [BatchRequest]) async throws -> [BatchResponse] {
        var results: [BatchResponse] = []
        
        for batchRequest in requests {
            let batchStartTime = Date()
            var responses: [String] = []
            var totalCost = 0.0
            var totalTokens = 0
            
            // Process requests in chunks
            let chunkedRequests = batchRequest.requests.chunked(into: batchRequest.batchSize)
            
            for chunk in chunkedRequests {
                let messages = chunk.map { ["role": $0.role, "content": $0.content] }
                
                do {
                    let response = try await sendChatMessage(
                        messages: messages,
                        model: batchRequest.model,
                        temperature: batchRequest.temperature,
                        maxTokens: batchRequest.maxTokens
                    )
                    
                    if let content = response.choices.first?.message.content {
                        responses.append(content)
                    }
                    
                    if let usage = response.usage {
                        totalCost += calculateCost(for: batchRequest.model, usage: usage)
                        totalTokens += usage.totalTokens
                    }
                    
                } catch {
                    print("Batch request failed: \(error)")
                    responses.append("Error: \(error.localizedDescription)")
                }
            }
            
            let processingTime = Date().timeIntervalSince(batchStartTime)
            results.append(BatchResponse(
                id: batchRequest.id,
                responses: responses,
                totalCost: totalCost,
                totalTokens: totalTokens,
                processingTime: processingTime
            ))
        }
        
        return results
    }
    
    // MARK: - Failover and Load Balancing
    func sendWithFailover(
        messages: [[String: String]],
        preferredModels: [ModelConfig]? = nil,
        customHeaders: [String: String] = nil
    ) async throws -> ChatResponse {
        
        let availableModels = preferredModels ?? getModelsForTask()
        var lastError: Error?
        
        // Try each available model in order
        for model in availableModels {
            do {
                let response = try await sendChatMessage(
                    messages: messages,
                    model: model,
                    customHeaders: customHeaders
                )
                return response
            } catch {
                lastError = error
                print("Model \(model.displayName) failed: \(error)")
                continue
            }
        }
        
        throw OpenRouterError.allModelsFailed(underlyingError: lastError)
    }
    
    private func getModelsForTask() -> [ModelConfig] {
        let models = availableModels.map { ModelConfig.from($0) }
        
        // Simple task-based model selection
        // In practice, this would be more sophisticated
        return models.sorted { model1, model2 in
            let performance1 = performanceMonitor.getAveragePerformance(for: model1.id)
            let performance2 = performanceMonitor.getAveragePerformance(for: model2.id)
            return performance1.avgResponseTime < performance2.avgResponseTime
        }
    }
    
    // MARK: - Cost and Usage Analytics
    func getUsageAnalytics(period: DateInterval? = nil) -> [String: (totalCost: Double, totalTokens: Int, totalRequests: Int, avgCostPer1kTokens: Double)] {
        var analytics: [String: (Double, Int, Int, Double)] = [:]
        
        let uniqueModelIds = Set(availableModels.map { $0.id })
        
        for modelId in uniqueModelIds {
            let stats = costTracking.getUsageStats(for: modelId, period: period)
            let costPer1kTokens = stats.totalTokens > 0 ? (stats.totalCost / Double(stats.totalTokens)) * 1000 : 0
            analytics[modelId] = (stats.totalCost, stats.totalTokens, stats.totalRequests, costPer1kTokens)
        }
        
        return analytics
    }
    
    func getCostOptimizedModels() -> [ModelConfig] {
        let models = availableModels.map { ModelConfig.from($0) }
        
        return models.sorted { model1, model2 in
            let stats1 = costTracking.getUsageStats(for: model1.id)
            let stats2 = costTracking.getUsageStats(for: model2.id)
            let costPer1k1 = stats1.totalTokens > 0 ? (stats1.totalCost / Double(stats1.totalTokens)) * 1000 : 0
            let costPer1k2 = stats2.totalTokens > 0 ? (stats2.totalCost / Double(stats2.totalTokens)) * 1000 : 0
            return costPer1k1 < costPer1k2
        }
    }
    
    // MARK: - Utility Methods
    private func calculateCost(for model: ModelConfig, usage: Usage) -> Double {
        // Get model pricing information
        if let openRouterModel = availableModels.first(where: { $0.id == model.id }) {
            let promptCost = (Double(usage.promptTokens) / 1000.0) * openRouterModel.pricing.prompt
            let completionCost = (Double(usage.completionTokens) / 1000.0) * openRouterModel.pricing.completion
            return promptCost + completionCost
        }
        
        // Fallback estimation if model not found
        return (Double(usage.totalTokens) / 1000.0) * 0.002
    }
    
    private func validateRateLimit() async throws {
        let now = Date()
        
        // Remove old timestamps
        requestTimestamps.removeAll { $0.timeIntervalSince(now) < -60 }
        
        if requestTimestamps.count >= maxRequestsPerMinute {
            throw OpenRouterError.rateLimitExceeded
        }
        
        requestTimestamps.append(now)
    }
    
    private func createRequest(
        endpoint: String,
        method: String,
        body: Encodable? = nil,
        customHeaders: [String: String]? = nil
    ) -> URLRequest {
        
        let url = URL(string: baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Standard headers
        var headers: [String: String] = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://intelligente-notizen-app.com",
            "X-Title": "Intelligente Notizen App",
            "User-Agent": "Intelligente-Notizen-App/1.0"
        ]
        
        // Add custom headers
        if let customHeaders = customHeaders {
            headers.merge(customHeaders) { _, new in new }
        }
        
        request.allHTTPHeaderFields = headers
        
        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }
        
        return request
    }
}

// MARK: - API Models
struct OpenRouterModelsResponse: Codable {
    let data: [OpenRouterModel]
    let object: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int
    let topP: Double
    let frequencyPenalty: Double
    let presencePenalty: Double
}

struct ChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Error Handling
enum OpenRouterError: Error, LocalizedError {
    case noModelSelected
    case rateLimitExceeded
    case allModelsFailed(underlyingError: Error?)
    
    var errorDescription: String? {
        switch self {
        case .noModelSelected:
            return "Kein Modell ausgewählt"
        case .rateLimitExceeded:
            return "Rate Limit überschritten. Bitte warten Sie einen Moment."
        case .allModelsFailed(let error):
            return "Alle Modelle sind fehlgeschlagen: \(error?.localizedDescription ?? "Unbekannter Fehler")"
        }
    }
}

// MARK: - Array Extensions
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}