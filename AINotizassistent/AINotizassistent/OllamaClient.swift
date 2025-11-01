//
//  OllamaClient.swift
//  Intelligente Notizen App
//  Client für Ollama Local LLM Integration
//

import Foundation
import Network

// MARK: - Ollama Client
final class OllamaClient: ObservableObject {
    
    // MARK: - Properties
    private let baseURL: String
    private let session: URLSession
    private var isRunning = false
    private let queue = DispatchQueue(label: "OllamaClient")
    
    // MARK: - Published Properties
    @Published var availableModels: [OllamaModel] = []
    @Published var isAvailable: Bool = false
    @Published var currentModel: String?
    @Published var status: String = "Nicht verbunden"
    
    // MARK: - Initialization
    init(baseURL: String = "http://localhost:11434") {
        self.baseURL = baseURL
        self.session = URLSession(configuration: .default)
        checkConnection()
    }
    
    // MARK: - Public Methods
    
    /// Check if Ollama service is available
    func checkConnection() {
        Task {
            await checkConnectionAsync()
        }
    }
    
    /// List available models
    func listModels() async throws -> [OllamaModel] {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            throw OllamaError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forType: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OllamaError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let modelResponse = try JSONDecoder().decode(OllamaModelResponse.self, from: data)
        
        DispatchQueue.main.async {
            self.availableModels = modelResponse.models
            self.isAvailable = !modelResponse.models.isEmpty
            self.status = modelResponse.models.isEmpty ? "Keine Modelle gefunden" : "\(modelResponse.models.count) Modelle verfügbar"
        }
        
        return modelResponse.models
    }
    
    /// Generate text using Ollama
    func generateText(_ prompt: String, modelName: String = "llama2") async throws -> String {
        guard availableModels.contains(where: { $0.name == modelName }) else {
            throw OllamaError.modelNotFound(modelName)
        }
        
        let requestBody = OllamaGenerateRequest(
            model: modelName,
            prompt: prompt,
            stream: false,
            options: OllamaOptions(
                temperature: 0.7,
                topK: 40,
                topP: 0.9,
                numPredict: 1000,
                numCtx: 4000
            )
        )
        
        return try await performGenerateRequest(requestBody)
    }
    
    /// Generate text with streaming response
    func generateTextStream(_ prompt: String, modelName: String = "llama2") async throws -> AsyncThrowingStream<String, Error> {
        guard availableModels.contains(where: { $0.name == modelName }) else {
            throw OllamaError.modelNotFound(modelName)
        }
        
        let requestBody = OllamaGenerateRequest(
            model: modelName,
            prompt: prompt,
            stream: true,
            options: OllamaOptions(
                temperature: 0.7,
                topK: 40,
                topP: 0.9,
                numPredict: 1000,
                numCtx: 4000
            )
        )
        
        return try await performStreamGenerateRequest(requestBody)
    }
    
    /// Pull/download a model
    func pullModel(_ modelName: String) async throws {
        let requestBody = OllamaPullRequest(name: modelName, stream: true)
        
        let url = URL(string: "\(baseURL)/api/pull")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forType: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (bytes, response) = try await session.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OllamaError.serverError(statusCode: httpResponse.statusCode)
        }
        
        for try await line in bytes.lines {
            if let data = line.data(using: .utf8),
               let pullResponse = try? JSONDecoder().decode(OllamaPullResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.status = "Lade \(modelName): \(pullResponse.status ?? "")"
                }
            }
        }
        
        // Refresh models list after pull
        try await listModels()
    }
    
    // MARK: - Private Methods
    
    private func checkConnectionAsync() async {
        do {
            try await listModels()
            DispatchQueue.main.async {
                self.isAvailable = !self.availableModels.isEmpty
                self.status = self.isAvailable ? "Verbunden" : "Ollama nicht verfügbar"
            }
        } catch {
            DispatchQueue.main.async {
                self.isAvailable = false
                self.status = "Verbindungsfehler: \(error.localizedDescription)"
            }
        }
    }
    
    private func performGenerateRequest(_ requestBody: OllamaGenerateRequest) async throws -> String {
        let url = URL(string: "\(baseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forType: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OllamaError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let generateResponse = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
        
        return generateResponse.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func performStreamGenerateRequest(_ requestBody: OllamaGenerateRequest) async throws -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = URL(string: "\(baseURL)/api/generate")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forType: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(requestBody)
                    
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: OllamaError.invalidResponse)
                        return
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: OllamaError.serverError(statusCode: httpResponse.statusCode))
                        return
                    }
                    
                    for try await line in bytes.lines {
                        if let data = line.data(using: .utf8) {
                            do {
                                let streamResponse = try JSONDecoder().decode(OllamaStreamResponse.self, from: data)
                                
                                if let responseText = streamResponse.response {
                                    continuation.yield(responseText)
                                }
                                
                                if streamResponse.done == true {
                                    continuation.finish()
                                    return
                                }
                            } catch {
                                // Continue on JSON decode errors for streaming
                                continue
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Ollama Models and Responses

struct OllamaModel: Codable, Identifiable, Hashable {
    let name: String
    let modifiedAt: Date
    let size: Int64
    let digest: String
    let details: OllamaModelDetails
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case modifiedAt = "modified_at"
        case size
        case digest
        case details
    }
}

struct OllamaModelDetails: Codable {
    let parentModel: String
    let format: String
    let family: String
    let families: [String]
    let parameterSize: String
    let quantizationLevel: String
    
    enum CodingKeys: String, CodingKey {
        case parentModel = "parent_model"
        case format
        case family
        case families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }
}

struct OllamaModelResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaGenerateRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
    let options: OllamaOptions?
}

struct OllamaOptions: Codable {
    let temperature: Double
    let topK: Int
    let topP: Double
    let numPredict: Int
    let numCtx: Int
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case topK = "top_k"
        case topP = "top_p"
        case numPredict = "num_predict"
        case numCtx = "num_ctx"
    }
}

struct OllamaGenerateResponse: Codable {
    let model: String
    let createdAt: Date
    let response: String
    let done: Bool
    let totalDuration: Int64
    let loadDuration: Int64
    let promptEvalCount: Int
    let promptEvalDuration: Int64
    let evalCount: Int
    let evalDuration: Int64
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response
        case done
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case promptEvalDuration = "prompt_eval_duration"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
    }
}

struct OllamaStreamResponse: Codable {
    let model: String?
    let createdAt: Date?
    let response: String?
    let done: Bool?
    let totalDuration: Int64?
    let loadDuration: Int64?
    let promptEvalCount: Int?
    let promptEvalDuration: Int64?
    let evalCount: Int?
    let evalDuration: Int64?
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response
        case done
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case promptEvalDuration = "prompt_eval_duration"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
    }
}

struct OllamaPullRequest: Codable {
    let name: String
    let stream: Bool
}

struct OllamaPullResponse: Codable {
    let status: String?
    let digest: String?
    let total: Int64?
    let completed: Int64?
}

// MARK: - Ollama Error Types

enum OllamaError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String = "")
    case modelNotFound(String)
    case networkError
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige Ollama-URL"
        case .invalidResponse:
            return "Ungültige Server-Antwort von Ollama"
        case .serverError(let code, let message):
            let baseMessage = "Ollama Server-Fehler \(code)"
            return message.isEmpty ? baseMessage : "\(baseMessage): \(message)"
        case .modelNotFound(let modelName):
            return "Modell '\(modelName)' nicht gefunden"
        case .networkError:
            return "Netzwerkfehler beim Verbinden mit Ollama"
        case .decodingError(let error):
            return "JSON-Dekodierungsfehler: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension OllamaClient {
    convenience init() {
        self.init(baseURL: "http://localhost:11434")
    }
}

extension OllamaModel {
    var sizeInMB: String {
        let mb = Double(size) / (1024 * 1024)
        if mb < 1024 {
            return String(format: "%.1f MB", mb)
        } else {
            let gb = mb / 1024
            return String(format: "%.1f GB", gb)
        }
    }
    
    var familyDescription: String {
        if families.isEmpty {
            return family
        } else {
            return families.joined(separator: ", ")
        }
    }
}