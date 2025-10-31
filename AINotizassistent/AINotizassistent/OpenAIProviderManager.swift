//
//  OpenAIProviderManager.swift
//  AINotizassistent
//
//  Spezialisierter Manager für OpenAI API Integration
//

import Foundation
import Network

/// Spezialisierter Manager für OpenAI API Integration
class OpenAIProviderManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isInitialized = false
    @Published var availableModels: [OpenAIModel] = []
    @Published var currentModel: OpenAIModel = .gpt3_5_turbo
    @Published var usageStats: OpenAIUsageStats?
    @Published var isGenerating = false
    @Published var lastRequest: OpenAIRequest?
    @Published var rateLimitStatus: RateLimitStatus = .unknown
    
    // MARK: - OpenAI Configuration
    
    struct OpenAIConfig {
        static let baseURL = "https://api.openai.com/v1"
        static let apiVersion = "2023-12-01-preview"
        static let maxTokens = 4096
        static let timeoutInterval: TimeInterval = 30
    }
    
    // MARK: - Rate Limiting
    
    struct RateLimitInfo {
        let limit: Int
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
    
    enum RateLimitStatus {
        case unknown
        case normal
        case approaching
        case limited(interval: TimeInterval)
    }
    
    private var rateLimitInfo: RateLimitInfo?
    private let requestQueue = DispatchQueue(label: "openai.requests", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init() {
        setupModels()
        loadCachedUsage()
    }
    
    private func setupModels() {
        availableModels = [
            .gpt3_5_turbo,
            .gpt3_5_turbo_16k,
            .gpt4,
            .gpt4_turbo,
            .gpt4_vision,
            .gpt4_32k,
            .dall_e_3,
            .dall_e_2,
            .whisper_1,
            .tts_1
        ]
    }
    
    // MARK: - API Key Management
    
    var isAPIKeyValid: Bool {
        guard let key = APIKeyManager.shared.getDecryptedKey(for: .openai) else { return false }
        return key.hasPrefix("sk-")
    }
    
    var currentAPIKey: String? {
        return APIKeyManager.shared.getDecryptedKey(for: .openai)
    }
    
    // MARK: - Model Management
    
    func setCurrentModel(_ model: OpenAIModel) {
        currentModel = model
        saveUserDefaults()
    }
    
    func getModelInfo() -> [String: Any] {
        return [
            "name": currentModel.rawValue,
            "maxTokens": currentModel.maxTokens,
            "supportsVision": currentModel.supportsVision,
            "costPerToken": currentModel.costPerToken,
            "description": currentModel.description
        ]
    }
    
    // MARK: - API Requests
    
    func generateText(prompt: String, parameters: OpenAIParameters = OpenAIParameters()) async throws -> OpenAIResponse {
        guard isAPIKeyValid else {
            throw OpenAIError.invalidAPIKey
        }
        
        guard !isGenerating else {
            throw OpenAIError.requestInProgress
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
                        continuation.resume(throwing: OpenAIError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: OpenAIError.noData)
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(OpenAIChatResponse.self, from: data)
                        
                        // Track usage
                        self.trackUsage(response: response)
                        
                        continuation.resume(returning: .chat(response))
                    } catch {
                        if let openAIError = try? decoder.decode(OpenAIErrorResponse.self, from: data) {
                            continuation.resume(throwing: OpenAIError.apiError(openAIError.error.message))
                        } else {
                            continuation.resume(throwing: OpenAIError.decodingError(error.localizedDescription))
                        }
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func generateImage(prompt: String, size: ImageSize = .size1024x1024) async throws -> OpenAIImageResponse {
        guard isAPIKeyValid else {
            throw OpenAIError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                var request = self.createImageRequest(prompt: prompt, size: size)
                self.lastRequest = .image(request)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: OpenAIError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: OpenAIError.noData)
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(OpenAIImageResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: OpenAIError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func transcribeAudio(audioData: Data, format: AudioFormat = .mp3) async throws -> String {
        guard isAPIKeyValid else {
            throw OpenAIError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                var request = self.createTranscriptionRequest(audioData: audioData, format: format)
                self.lastRequest = .transcription(request)
                
                let task = URLSession.shared.uploadTask(with: request, from: audioData) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: OpenAIError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: OpenAIError.noData)
                        return
                    }
                    
                    do {
                        let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
                        continuation.resume(returning: response.text)
                    } catch {
                        continuation.resume(throwing: OpenAIError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    // MARK: - Request Creation
    
    private func createTextRequest(prompt: String, parameters: OpenAIParameters) -> URLRequest {
        let url = URL(string: "\(OpenAIConfig.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(currentAPIKey!)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = OpenAIConfig.timeoutInterval
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        var body: [String: Any] = [
            "model": currentModel.rawValue,
            "messages": messages,
            "max_tokens": parameters.maxTokens ?? currentModel.maxTokens,
            "temperature": parameters.temperature ?? 0.7
        ]
        
        if let topP = parameters.topP {
            body["top_p"] = topP
        }
        
        if let frequencyPenalty = parameters.frequencyPenalty {
            body["frequency_penalty"] = frequencyPenalty
        }
        
        if let presencePenalty = parameters.presencePenalty {
            body["presence_penalty"] = presencePenalty
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    private func createImageRequest(prompt: String, size: ImageSize) -> URLRequest {
        let url = URL(string: "\(OpenAIConfig.baseURL)/images/generations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(currentAPIKey!)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "prompt": prompt,
            "n": 1,
            "size": size.rawValue,
            "quality": size.quality,
            "style": "vivid"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    private func createTranscriptionRequest(audioData: Data, format: AudioFormat) -> URLRequest {
        let url = URL(string: "\(OpenAIConfig.baseURL)/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(currentAPIKey!)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.\(format.rawValue)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(format.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        return request
    }
    
    // MARK: - Usage Tracking
    
    private func trackUsage(response: OpenAIChatResponse) {
        guard let usage = response.usage else { return }
        
        let currentStats = usageStats ?? OpenAIUsageStats()
        currentStats.totalTokens += usage.totalTokens
        currentStats.promptTokens += usage.promptTokens
        currentStats.completionTokens += usage.completionTokens
        currentStats.requests += 1
        currentStats.lastRequest = Date()
        
        usageStats = currentStats
        saveUsageStats()
        
        // Track in main API Key Manager
        APIKeyManager.shared.trackUsage(for: .openai, tokensUsed: usage.totalTokens)
    }
    
    private func updateRateLimit(from response: HTTPURLResponse) {
        if let limit = Int(response.value(forHTTPHeaderField: "x-ratelimit-limit-requests") ?? "0"),
           let remaining = Int(response.value(forHTTPHeaderField: "x-ratelimit-remaining-requests") ?? "0"),
           let resetTimeString = response.value(forHTTPHeaderField: "x-ratelimit-reset-requests"),
           let resetTime = ISO8601DateFormatter().date(from: resetTimeString) {
            
            rateLimitInfo = RateLimitInfo(
                limit: limit,
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
        } else if info.remaining < info.limit / 10 {
            rateLimitStatus = .approaching
        } else {
            rateLimitStatus = .normal
        }
    }
    
    // MARK: - UserDefaults
    
    private func saveUserDefaults() {
        UserDefaults.standard.set(currentModel.rawValue, forKey: "openai_current_model")
    }
    
    private func loadUserDefaults() {
        if let modelName = UserDefaults.standard.string(forKey: "openai_current_model"),
           let model = OpenAIModel(rawValue: modelName) {
            currentModel = model
        }
    }
    
    private func saveUsageStats() {
        if let data = try? JSONEncoder().encode(usageStats) {
            UserDefaults.standard.set(data, forKey: "openai_usage_stats")
        }
    }
    
    private func loadCachedUsage() {
        if let data = UserDefaults.standard.data(forKey: "openai_usage_stats"),
           let stats = try? JSONDecoder().decode(OpenAIUsageStats.self, from: data) {
            usageStats = stats
        }
    }
    
    // MARK: - Model Information
    
    func getAvailableModels() async throws -> [OpenAIModel] {
        guard isAPIKeyValid else {
            throw OpenAIError.invalidAPIKey
        }
        
        let url = URL(string: "\(OpenAIConfig.baseURL)/models")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(currentAPIKey!)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIModelsResponse.self, from: data)
        
        return response.data.compactMap { apiModel in
            OpenAIModel(rawValue: apiModel.id)
        }
    }
}

// MARK: - Supporting Types

enum OpenAIModel: String, CaseIterable {
    case gpt3_5_turbo = "gpt-3.5-turbo"
    case gpt3_5_turbo_16k = "gpt-3.5-turbo-16k"
    case gpt4 = "gpt-4"
    case gpt4_turbo = "gpt-4-turbo-preview"
    case gpt4_vision = "gpt-4-vision-preview"
    case gpt4_32k = "gpt-4-32k"
    case dall_e_2 = "dall-e-2"
    case dall_e_3 = "dall-e-3"
    case whisper_1 = "whisper-1"
    case tts_1 = "tts-1"
    case tts_1_hd = "tts-1-hd"
    
    var maxTokens: Int {
        switch self {
        case .gpt3_5_turbo: return 4096
        case .gpt3_5_turbo_16k: return 16384
        case .gpt4: return 8192
        case .gpt4_turbo: return 128000
        case .gpt4_vision: return 128000
        case .gpt4_32k: return 32768
        case .dall_e_2, .dall_e_3: return 0
        case .whisper_1, .tts_1, .tts_1_hd: return 0
        }
    }
    
    var supportsVision: Bool {
        return self == .gpt4_vision
    }
    
    var costPerToken: Double {
        switch self {
        case .gpt3_5_turbo: return 0.0005 / 1000
        case .gpt3_5_turbo_16k: return 0.003 / 1000
        case .gpt4: return 0.03 / 1000
        case .gpt4_turbo: return 0.01 / 1000
        case .gpt4_vision: return 0.01 / 1000
        case .gpt4_32k: return 0.06 / 1000
        case .dall_e_2: return 0.02
        case .dall_e_3: return 0.04
        case .whisper_1: return 0.006
        case .tts_1: return 0.015
        case .tts_1_hd: return 0.030
        }
    }
    
    var description: String {
        switch self {
        case .gpt3_5_turbo: return "Schnell und kostengünstig für die meisten Aufgaben"
        case .gpt3_5_turbo_16k: return "Erweiterte Kontextlänge für längere Texte"
        case .gpt4: return "Höchste Qualität für komplexe Aufgaben"
        case .gpt4_turbo: return "Aktuelles GPT-4 mit erweiterten Funktionen"
        case .gpt4_vision: return "GPT-4 mit Bildverständnis-Fähigkeiten"
        case .gpt4_32k: return "GPT-4 mit sehr großer Kontextlänge"
        case .dall_e_2: return "KI-Bildgenerierung (Legacy)"
        case .dall_e_3: return "Neueste KI-Bildgenerierung"
        case .whisper_1: return "Sprach-zu-Text Transkription"
        case .tts_1: return "Text-zu-Sprache Synthese"
        case .tts_1_hd: return "Hochqualitative Text-zu-Sprache Synthese"
        }
    }
}

enum ImageSize: String, CaseIterable {
    case size256x256 = "256x256"
    case size512x512 = "512x512"
    case size1024x1024 = "1024x1024"
    case size1792x1024 = "1792x1024"
    case size1024x1792 = "1024x1792"
    
    var quality: String {
        switch self {
        case .size256x256, .size512x512, .size1024x1024:
            return "standard"
        default:
            return "hd"
        }
    }
    
    var description: String {
        switch self {
        case .size256x256: return "Klein (256x256)"
        case .size512x512: return "Standard (512x512)"
        case .size1024x1024: return "Groß (1024x1024)"
        case .size1792x1024: return "Breitformat (1792x1024)"
        case .size1024x1792: return "Hochformat (1024x1792)"
        }
    }
}

enum AudioFormat: String, CaseIterable {
    case mp3 = "mp3"
    case mp4 = "mp4"
    case mpeg = "mpeg"
    case mpga = "mpga"
    case m4a = "m4a"
    case wav = "wav"
    case webm = "webm"
    
    var mimeType: String {
        return "audio/\(rawValue)"
    }
}

struct OpenAIParameters {
    var maxTokens: Int?
    var temperature: Double?
    var topP: Double?
    var frequencyPenalty: Double?
    var presencePenalty: Double?
    
    static let `default` = OpenAIParameters()
}

enum OpenAIResponse {
    case chat(OpenAIChatResponse)
    case image(OpenAIImageResponse)
}

enum OpenAIError: Error, LocalizedError {
    case invalidAPIKey
    case requestInProgress
    case networkError(String)
    case decodingError(String)
    case noData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "OpenAI API Key ist ungültig oder nicht konfiguriert"
        case .requestInProgress:
            return "Eine Anfrage wird bereits verarbeitet"
        case .networkError(let message):
            return "Netzwerkfehler: \(message)"
        case .decodingError(let message):
            return "Dekodierungsfehler: \(message)"
        case .noData:
            return "Keine Daten erhalten"
        case .apiError(let message):
            return "OpenAI API Fehler: \(message)"
        }
    }
}

// MARK: - Response Models

struct OpenAIUsageStats: Codable {
    var totalTokens: Int = 0
    var promptTokens: Int = 0
    var completionTokens: Int = 0
    var requests: Int = 0
    var costEstimate: Double = 0.0
    var lastRequest: Date?
    var dailyUsage: [String: Int] = [:]
    var monthlyUsage: Int = 0
}

enum OpenAIRequest {
    case text(URLRequest)
    case image(URLRequest)
    case transcription(URLRequest)
}