//
//  KIProvider.swift
//  Intelligente Notizen App
//

import Foundation
import Network

// MARK: - KI Provider Protocol
protocol KIProvider: AnyObject {
    var name: String { get }
    var isAvailable: Bool { get }
    
    func generateSummary(for text: String) async throws -> String
    func extractKeywords(from text: String) async throws -> [String]
    func categorizeContent(_ text: String) async throws -> ContentType
    func enhanceContent(_ text: String, type: ContentType) async throws -> String
    func generateQuestions(from text: String) async throws -> [String]
}

// MARK: - Provider Configuration
struct KIProviderConfig {
    let apiKey: String
    let baseURL: String
    let model: String
    let maxTokens: Int
    let temperature: Double
    let timeout: TimeInterval
    
    init(apiKey: String, baseURL: String, model: String, maxTokens: Int = 1000, temperature: Double = 0.7, timeout: TimeInterval = 30) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.timeout = timeout
    }
}

// MARK: - OpenAI Provider
final class OpenAIProvider: KIProvider {
    let name: String = "OpenAI"
    var isAvailable: Bool {
        return !config.apiKey.isEmpty && NetworkMonitor.shared.isConnected
    }
    
    private let config: KIProviderConfig
    private let session: URLSession
    private let jsonDecoder = JSONDecoder()
    
    init(config: KIProviderConfig) {
        self.config = config
        self.session = URLSession(configuration: .default)
        jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    func generateSummary(for text: String) async throws -> String {
        let prompt = """
        Erstelle eine prägnante Zusammenfassung des folgenden Textes in maximal 3 Sätzen:
        
        \(text)
        
        Zusammenfassung:
        """
        
        let request = createChatRequest(prompt: prompt, systemPrompt: "Du bist ein hilfreicher Assistent, der prägnante und informative Zusammenfassungen erstellt.")
        
        return try await performRequest(request, expectedType: .summary)
    }
    
    func extractKeywords(from text: String) async throws -> [String] {
        let prompt = """
        Extrahiere die wichtigsten Keywords aus dem folgenden Text. 
        Gib nur die Keywords zurück, getrennt durch Kommas, ohne zusätzliche Erklärungen:
        
        \(text)
        """
        
        let request = createChatRequest(prompt: prompt, systemPrompt: "Extrahiere die wichtigsten Keywords und Begriffe aus dem gegebenen Text.")
        
        let response = try await performRequest(request, expectedType: .keywords)
        let keywords = response.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return keywords.filter { !$0.isEmpty }
    }
    
    func categorizeContent(_ text: String) async throws -> ContentType {
        let contentTypes = ContentType.allCases.map { "\($0.rawValue): \($0.defaultTags.joined(separator: ", "))" }.joined(separator: "\n")
        
        let prompt = """
        Kategorisiere den folgenden Text in eine der folgenden Content-Types:
        \(contentTypes)
        
        Text zu kategorisieren:
        \(text)
        
        Antworte nur mit dem Namen der passendsten Content-Type ohne weitere Erklärung.
        """
        
        let request = createChatRequest(prompt: prompt, systemPrompt: "Du kategorisierst Texte präzise in vordefinierte Kategorien.")
        
        let response = try await performRequest(request, expectedType: .categorization)
        
        // Try to match the response to a ContentType
        if let matchedType = ContentType.allCases.first(where: { $0.rawValue.lowercased() == response.lowercased() }) {
            return matchedType
        }
        
        // Fallback to detected content type
        return ContentTypeDetector.detectContentType(from: text)
    }
    
    func enhanceContent(_ text: String, type: ContentType) async throws -> String {
        let typeSpecificPrompts: [ContentType: String] = [
            .email: "Verbessere die E-Mail-Formatierung und füge höfliche Formulierungen hinzu.",
            .meeting: "Strukturiere die Meeting-Notizen mit klaren Abschnitten für Agenda, Diskussionen und Ergebnisse.",
            .article: "Verbessere die Artikelstruktur und füge Zusammenfassungen hinzu.",
            .task: "Strukturiere die Aufgaben mit klaren Action Items und Prioritäten.",
            .note: "Verbessere die Lesbarkeit und Struktur der Notiz.",
            .idea: "Formuliere die Idee klarer und füge mögliche Umsetzungsschritte hinzu.",
            .code: "Verbessere die Code-Formatierung und füge Kommentare hinzu.",
            .question: "Strukturiere die Frage klarer und füge mögliche Lösungsansätze hinzu.",
            .research: "Verbessere die Forschungsstruktur und füge Schlussfolgerungen hinzu.",
            .personal: "Formuliere persönliche Notizen klarer und strukturierter."
        ]
        
        let enhancementPrompt = typeSpecificPrompts[type] ?? "Verbessere die allgemeine Struktur und Lesbarkeit des Textes."
        
        let prompt = """
        \(enhancementPrompt)
        
        Originaltext:
        \(text)
        
        Verbesserter Text:
        """
        
        let request = createChatRequest(prompt: prompt, systemPrompt: "Du verbesserst Texte strukturiert und behältst dabei die ursprüngliche Bedeutung bei.")
        
        return try await performRequest(request, expectedType: .enhancement)
    }
    
    func generateQuestions(from text: String) async throws -> [String] {
        let prompt = """
        Generiere 3-5 relevante Fragen basierend auf dem folgenden Text:
        
        \(text)
        
        Formatiere jede Frage auf einer neuen Zeile ohne Nummerierung oder Bullet Points.
        """
        
        let request = createChatRequest(prompt: prompt, systemPrompt: "Du generierst insightful und relevante Fragen basierend auf gegebenem Text.")
        
        let response = try await performRequest(request, expectedType: .questions)
        let questions = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains("?") }
        
        return questions
    }
    
    // MARK: - Private Methods
    private func createChatRequest(prompt: String, systemPrompt: String) -> APIRequest {
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "max_tokens": config.maxTokens,
            "temperature": config.temperature
        ]
        
        return APIRequest(
            url: "\(config.baseURL)/v1/chat/completions",
            method: "POST",
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(config.apiKey)"
            ],
            body: requestBody
        )
    }
    
    private func performRequest(_ request: APIRequest, expectedType: ResponseType) async throws -> String {
        guard let url = URL(string: request.url) else {
            throw KIProviderError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.allHTTPHeaderFields = request.headers
        
        if let body = request.body {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        urlRequest.timeoutInterval = config.timeout
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KIProviderError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw KIProviderError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let openAIResponse = try jsonDecoder.decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw KIProviderError.emptyResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Ollama Provider (Lokal)
/// TODO: Implementation later
/// Lokale Ollama Integration für Privatsphäre-fokussierte KI-Verarbeitung
final class OllamaProvider: KIProvider {
    let name: String = "Ollama (Lokal)"
    var isAvailable: Bool {
        return NetworkMonitor.shared.isConnected && ollamaClient.isAvailable
    }
    
    private let config: KIProviderConfig
    private let ollamaClient: OllamaClient
    private let session: URLSession
    private let jsonDecoder = JSONDecoder()
    
    init(config: KIProviderConfig) {
        self.config = config
        self.ollamaClient = OllamaClient(baseURL: config.baseURL)
        self.session = URLSession(configuration: .default)
        jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    func generateSummary(for text: String) async throws -> String {
        // TODO: Implementation later
        print("🤖 OllamaProvider: Generiere Zusammenfassung lokal")
        
        let prompt = """
        Erstelle eine prägnante Zusammenfassung des folgenden Textes in maximal 3 Sätzen:
        
        \(text)
        
        Zusammenfassung:
        """
        
        let systemPrompt = "Du bist ein lokaler KI-Assistent, der prägnante und informative Zusammenfassungen erstellt. Alle Daten werden lokal verarbeitet für maximalen Datenschutz."
        
        return try await ollamaClient.generateText("\(systemPrompt)\n\n\(prompt)", modelName: config.model)
    }
    
    func extractKeywords(from text: String) async throws -> [String] {
        // TODO: Implementation later
        print("🔍 OllamaProvider: Extrahiere Keywords lokal")
        
        let prompt = """
        Extrahiere die wichtigsten Keywords aus dem folgenden Text. 
        Gib nur die Keywords zurück, getrennt durch Kommas, ohne zusätzliche Erklärungen:
        
        \(text)
        """
        
        let response = try await ollamaClient.generateText(prompt, modelName: config.model)
        let keywords = response.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return keywords.filter { !$0.isEmpty }
    }
    
    func categorizeContent(_ text: String) async throws -> ContentType {
        // TODO: Implementation later
        print("📂 OllamaProvider: Kategorisiere Content lokal")
        
        let contentTypes = ContentType.allCases.map { "\($0.rawValue): \($0.defaultTags.joined(separator: ", "))" }.joined(separator: "\n")
        
        let prompt = """
        Kategorisiere den folgenden Text in eine der folgenden Content-Types:
        \(contentTypes)
        
        Text zu kategorisieren:
        \(text)
        
        Antworte nur mit dem Namen der passendsten Content-Type ohne weitere Erklärung.
        """
        
        let response = try await ollamaClient.generateText(prompt, modelName: config.model)
        
        if let matchedType = ContentType.allCases.first(where: { 
            $0.rawValue.lowercased() == response.lowercased() 
        }) {
            return matchedType
        }
        
        return ContentTypeDetector.detectContentType(from: text)
    }
    
    func enhanceContent(_ text: String, type: ContentType) async throws -> String {
        // TODO: Implementation later
        print("✨ OllamaProvider: Enhance Content lokal")
        
        let typeSpecificPrompts: [ContentType: String] = [
            .email: "Verbessere die E-Mail-Formatierung und füge höfliche Formulierungen hinzu.",
            .meeting: "Strukturiere die Meeting-Notizen mit klaren Abschnitten für Agenda, Diskussionen und Ergebnisse.",
            .article: "Verbessere die Artikelstruktur und füge Zusammenfassungen hinzu.",
            .task: "Strukturiere die Aufgaben mit klaren Action Items und Prioritäten.",
            .note: "Verbessere die Lesbarkeit und Struktur der Notiz.",
            .idea: "Formuliere die Idee klarer und füge mögliche Umsetzungsschritte hinzu.",
            .code: "Verbessere die Code-Formatierung und füge Kommentare hinzu.",
            .question: "Strukturiere die Frage klarer und füge mögliche Lösungsansätze hinzu.",
            .research: "Verbessere die Forschungsstruktur und füge Schlussfolgerungen hinzu.",
            .personal: "Formuliere persönliche Notizen klarer und strukturierter."
        ]
        
        let enhancementPrompt = typeSpecificPrompts[type] ?? "Verbessere die allgemeine Struktur und Lesbarkeit des Textes."
        
        let prompt = """
        \(enhancementPrompt)
        
        Originaltext:
        \(text)
        
        Verbesserter Text:
        """
        
        return try await ollamaClient.generateText(prompt, modelName: config.model)
    }
    
    func generateQuestions(from text: String) async throws -> [String] {
        // TODO: Implementation later
        print("❓ OllamaProvider: Generiere Fragen lokal")
        
        let prompt = """
        Generiere 3-5 relevante Fragen basierend auf dem folgenden Text:
        
        \(text)
        
        Formatiere jede Frage auf einer neuen Zeile ohne Nummerierung oder Bullet Points.
        """
        
        let response = try await ollamaClient.generateText(prompt, modelName: config.model)
        let questions = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains("?") }
        
        return questions
    }
}

// MARK: - OpenRouter Provider
final class OpenRouterProvider: KIProvider {
    let name: String = "OpenRouter"
    var isAvailable: Bool {
        return !config.apiKey.isEmpty && NetworkMonitor.shared.isConnected
    }
    
    private let config: KIProviderConfig
    private let session: URLSession
    private let jsonDecoder = JSONDecoder()
    
    init(config: KIProviderConfig) {
        self.config = config
        self.session = URLSession(configuration: .default)
        jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    func generateSummary(for text: String) async throws -> String {
        let prompt = """
        Erstelle eine prägnante deutsche Zusammenfassung des folgenden Textes in maximal 3 Sätzen:
        
        \(text)
        """
        
        let request = createChatRequest(prompt: prompt, systemPrompt: "Du bist ein deutscher Assistent, der prägnante und informative Zusammenfassungen erstellt.")
        
        return try await performRequest(request)
    }
    
    func extractKeywords(from text: String) async throws -> [String] {
        let prompt = """
        Extrahiere die wichtigsten deutschen Keywords aus dem folgenden Text. 
        Gib nur die Keywords zurück, getrennt durch Kommas:
        
        \(text)
        """
        
        let request = createChatRequest(prompt: prompt, systemPrompt: "Extrahiere wichtige deutsche Keywords.")
        
        let response = try await performRequest(request)
        let keywords = response.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return keywords.filter { !$0.isEmpty }
    }
    
    func categorizeContent(_ text: String) async throws -> ContentType {
        let categories = ContentType.allCases.map { $0.rawValue }.joined(separator: ", ")
        
        let prompt = """
        Kategorisiere den folgenden deutschen Text in eine dieser Kategorien: \(categories)
        
        Text: \(text)
        
        Antworte nur mit dem Namen der passendsten Kategorie.
        """
        
        let request = createChatRequest(prompt: prompt, systemPrompt: "Kategorisiere deutsche Texte präzise.")
        
        let response = try await performRequest(request)
        
        if let matchedType = ContentType.allCases.first(where: { 
            $0.rawValue.lowercased() == response.lowercased() 
        }) {
            return matchedType
        }
        
        return ContentTypeDetector.detectContentType(from: text)
    }
    
    func enhanceContent(_ text: String, type: ContentType) async throws -> String {
        let prompt = """
        Verbessere den folgenden deutschen Text und mache ihn strukturierter und lesbarer:
        
        \(text)
        
        Content-Type: \(type.rawValue)
        """
        
        let request = createChatRequest(prompt: prompt, systemPrompt: "Du verbesserst deutsche Texte strukturiert.")
        
        return try await performRequest(request)
    }
    
    func generateQuestions(from text: String) async throws -> [String] {
        let prompt = """
        Generiere 3-5 relevante deutsche Fragen basierend auf dem folgenden Text:
        
        \(text)
        """
        
        let request = createChatRequest(prompt: prompt, systemPrompt: "Generiere insightful deutsche Fragen.")
        
        let response = try await performRequest(request)
        let questions = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains("?") }
        
        return questions
    }
    
    private func createChatRequest(prompt: String, systemPrompt: String) -> APIRequest {
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "max_tokens": config.maxTokens,
            "temperature": config.temperature,
            "top_p": 0.95,
            "frequency_penalty": 0.1,
            "presence_penalty": 0.1
        ]
        
        return APIRequest(
            url: "\(config.baseURL)/v1/chat/completions",
            method: "POST",
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(config.apiKey)",
                "HTTP-Referer": "https://intelligente-notizen-app.com",
                "X-Title": "Intelligente Notizen App"
            ],
            body: requestBody
        )
    }
    
    private func performRequest(_ request: APIRequest) async throws -> String {
        guard let url = URL(string: request.url) else {
            throw KIProviderError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.allHTTPHeaderFields = request.headers
        
        if let body = request.body {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        urlRequest.timeoutInterval = config.timeout
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KIProviderError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw KIProviderError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let openAIResponse = try jsonDecoder.decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw KIProviderError.emptyResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Provider Factory
final class KIProviderFactory {
    static func createProvider(type: KIProviderType, config: KIProviderConfig) -> KIProvider {
        switch type {
        case .openAI:
            return OpenAIProvider(config: config)
        case .openRouter:
            return OpenRouterProvider(config: config)
        case .ollama:
            // TODO: Implementation later - Create OllamaProvider
            return OllamaProvider(config: config)
        }
    }
}

// MARK: - Provider Type
enum KIProviderType: String, CaseIterable {
    case openAI = "OpenAI"
    case openRouter = "OpenRouter"
    case ollama = "Ollama (Lokal)"
}

// MARK: - Supporting Types
struct APIRequest {
    let url: String
    let method: String
    let headers: [String: String]
    let body: [String: Any]?
}

enum ResponseType {
    case summary
    case keywords
    case categorization
    case enhancement
    case questions
}

enum KIProviderError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case emptyResponse
    case serverError(statusCode: Int, message: String)
    case networkError
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige URL"
        case .invalidResponse:
            return "Ungültige Serverantwort"
        case .emptyResponse:
            return "Leere Antwort vom Server"
        case .serverError(let code, let message):
            return "Server-Fehler \(code): \(message)"
        case .networkError:
            return "Netzwerkverbindung nicht verfügbar"
        case .decodingError(let error):
            return "Dekodierungsfehler: \(error.localizedDescription)"
        }
    }
}

// MARK: - OpenAI API Response Models
struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
}

struct Choice: Codable {
    let index: Int
    let message: Message
    let finishReason: String
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct Message: Codable {
    let role: String
    let content: String
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Network Monitor
final class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isConnected: Bool = true
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }
}

// MARK: - Provider Manager
final class KIProviderManager: ObservableObject {
    @Published var currentProvider: KIProvider?
    @Published var availableProviders: [KIProvider] = []
    @Published var selectedProviderType: KIProviderType = .openAI
    
    private var providerConfigs: [KIProviderType: KIProviderConfig] = [
        .openAI: KIProviderConfig(
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "",
            baseURL: "https://api.openai.com",
            model: "gpt-3.5-turbo"
        ),
        .openRouter: KIProviderConfig(
            apiKey: ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? "",
            baseURL: "https://openrouter.ai/api",
            model: "openai/gpt-3.5-turbo"
        ),
        .ollama: KIProviderConfig(
            apiKey: "", // Lokal, kein API-Key nötig
            baseURL: "http://localhost:11434",
            model: "llama2"
        )
    ]
    
    func setProviderType(_ type: KIProviderType) {
        selectedProviderType = type
        if let config = providerConfigs[type] {
            currentProvider = KIProviderFactory.createProvider(type: type, config: config)
        }
    }
    
    func updateConfig(for type: KIProviderType, config: KIProviderConfig) {
        providerConfigs[type] = config
        if selectedProviderType == type {
            setProviderType(type)
        }
    }
    
    func refreshAvailableProviders() {
        availableProviders = providerConfigs.compactMap { type, config in
            let provider = KIProviderFactory.createProvider(type: type, config: config)
            return provider.isAvailable ? provider : nil
        }
        
        // Set current provider if not available
        if currentProvider == nil || !currentProvider!.isAvailable {
            currentProvider = availableProviders.first
        }
    }
}