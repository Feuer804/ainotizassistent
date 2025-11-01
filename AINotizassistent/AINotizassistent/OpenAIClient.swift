//
//  OpenAIClient.swift
//  AINotizassistent
//
//  Created by Claude on 2025-10-31.
//  OpenAI API Integration für macOS App
//

import Foundation
import Combine

// MARK: - OpenAI API Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let max_tokens: Int?
    let temperature: Double?
    let stream: Bool?
    let top_p: Double?
    let frequency_penalty: Double?
    let presence_penalty: Double?
    
    init(model: String, messages: [OpenAIMessage], maxTokens: Int? = nil, temperature: Double? = nil, stream: Bool? = nil, topP: Double? = nil, frequencyPenalty: Double? = nil, presencePenalty: Double? = nil) {
        self.model = model
        self.messages = messages
        self.max_tokens = maxTokens
        self.temperature = temperature
        self.stream = stream
        self.top_p = topP
        self.frequency_penalty = frequencyPenalty
        self.presence_penalty = presencePenalty
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIMessage?
    let finish_reason: String?
    let delta: OpenAIMessage?
}

struct OpenAIUsage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

struct OpenAIStreamResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIStreamChoice]
}

struct OpenAIStreamChoice: Codable {
    let index: Int
    let delta: OpenAIDelta
    let finish_reason: String?
}

struct OpenAIDelta: Codable {
    let role: String?
    let content: String?
}

// MARK: - API Key Management

class APIKeyManager {
    private let service = "com.ainotizassistent.openai"
    private let account = "api_key"
    
    func storeAPIKey(_ key: String) throws {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        // Lösche existierenden Key
        SecItemDelete(keychainQuery as CFDictionary)
        
        // Speichere neuen Key
        let status = SecItemAdd(keychainQuery as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw APIKeyManagerError.storageFailed
        }
    }
    
    func retrieveAPIKey() throws -> String? {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data else {
            throw APIKeyManagerError.retrievalFailed
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func clearAPIKey() throws {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(keychainQuery as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw APIKeyManagerError.clearFailed
        }
    }
    
    func hasValidAPIKey() -> Bool {
        return (try? retrieveAPIKey()) != nil
    }
}

enum APIKeyManagerError: Error {
    case storageFailed
    case retrievalFailed
    case clearFailed
}

// MARK: - Rate Limiter

class RateLimiter {
    private let requests: NSMutableArray = []
    private let maxRequestsPerMinute: Int = 60
    private let maxRequestsPerDay: Int = 1000
    
    func canMakeRequest() -> Bool {
        cleanupOldRequests()
        return requests.count < maxRequestsPerMinute
    }
    
    func canMakeRequestToday() -> Bool {
        cleanupOldRequests()
        return getTodayRequestCount() < maxRequestsPerDay
    }
    
    func recordRequest() {
        cleanupOldRequests()
        requests.add(Date())
    }
    
    private func cleanupOldRequests() {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        // Entferne alle Requests älter als 1 Minute
        requests.filter { ($0 as? Date)?.compare(oneMinuteAgo) == .orderedDescending }
        
        // Manuell filtern (NSMutableArray hat keine filter Methode)
        let validRequests = NSMutableArray()
        for request in requests {
            if let date = request as? Date {
                if date.compare(oneMinuteAgo) == .orderedDescending {
                    validRequests.add(date)
                }
            }
        }
        requests.removeAllObjects()
        requests.addObjects(from: validRequests as [AnyObject])
    }
    
    private func getTodayRequestCount() -> Int {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        return requests.filter { ($0 as? Date)?.compare(today) == .orderedDescending }.count
    }
    
    var timeUntilNextRequest: TimeInterval {
        cleanupOldRequests()
        guard let oldestRequest = requests.firstObject as? Date else { return 0 }
        let minuteAgo = Date().addingTimeInterval(-60)
        return max(0, minuteAgo.timeIntervalSince(oldestRequest))
    }
}

// MARK: - Usage Tracker

class UsageTracker {
    private let userDefaults = UserDefaults.standard
    private let dateKey = "lastUsageDate"
    private let usageKeyPrefix = "usage_"
    
    struct DailyUsage {
        let date: Date
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        let requestCount: Int
        
        var totalCost: Double {
            // GPT-4: $0.03/1K prompt tokens, $0.06/1K completion tokens
            // GPT-3.5-Turbo: $0.0015/1K prompt tokens, $0.002/1K completion tokens
            let gpt4CostPer1KPrompt = 0.03
            let gpt4CostPer1KCompletion = 0.06
            let gpt35CostPer1KPrompt = 0.0015
            let gpt35CostPer1KCompletion = 0.002
            
            // Vereinfachte Berechnung (nur GPT-4 als Referenz)
            let estimatedCost = (Double(promptTokens) / 1000.0) * gpt4CostPer1KPrompt +
                               (Double(completionTokens) / 1000.0) * gpt4CostPer1KCompletion
            return estimatedCost
        }
    }
    
    func recordUsage(promptTokens: Int, completionTokens: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let dateString = dateFormatter.string(from: today)
        
        if userDefaults.string(forKey: dateKey) != dateString {
            // Neuer Tag, reset
            resetDailyUsage()
            userDefaults.set(dateString, forKey: dateKey)
        }
        
        // Update usage
        let currentUsage = getCurrentDailyUsage()
        let updatedUsage = DailyUsage(
            date: today,
            promptTokens: currentUsage.promptTokens + promptTokens,
            completionTokens: currentUsage.completionTokens + completionTokens,
            totalTokens: currentUsage.totalTokens + promptTokens + completionTokens,
            requestCount: currentUsage.requestCount + 1
        )
        
        saveDailyUsage(updatedUsage)
    }
    
    func getCurrentDailyUsage() -> DailyUsage {
        let today = Calendar.current.startOfDay(for: Date())
        let dateString = dateFormatter.string(from: today)
        
        if let savedData = userDefaults.dictionary(forKey: "\(usageKeyPrefix)\(dateString)") {
            return DailyUsage(
                date: today,
                promptTokens: savedData["promptTokens"] as? Int ?? 0,
                completionTokens: savedData["completionTokens"] as? Int ?? 0,
                totalTokens: savedData["totalTokens"] as? Int ?? 0,
                requestCount: savedData["requestCount"] as? Int ?? 0
            )
        }
        
        return DailyUsage(date: today, promptTokens: 0, completionTokens: 0, totalTokens: 0, requestCount: 0)
    }
    
    func getUsageHistory(days: Int = 7) -> [DailyUsage] {
        var history: [DailyUsage] = []
        let calendar = Calendar.current
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let dayStart = calendar.startOfDay(for: date)
                let dateString = dateFormatter.string(from: dayStart)
                
                if let savedData = userDefaults.dictionary(forKey: "\(usageKeyPrefix)\(dateString)") {
                    let usage = DailyUsage(
                        date: dayStart,
                        promptTokens: savedData["promptTokens"] as? Int ?? 0,
                        completionTokens: savedData["completionTokens"] as? Int ?? 0,
                        totalTokens: savedData["totalTokens"] as? Int ?? 0,
                        requestCount: savedData["requestCount"] as? Int ?? 0
                    )
                    history.append(usage)
                } else {
                    history.append(DailyUsage(date: dayStart, promptTokens: 0, completionTokens: 0, totalTokens: 0, requestCount: 0))
                }
            }
        }
        
        return history.reversed()
    }
    
    private func saveDailyUsage(_ usage: DailyUsage) {
        let dateString = dateFormatter.string(from: usage.date)
        let data: [String: Any] = [
            "promptTokens": usage.promptTokens,
            "completionTokens": usage.completionTokens,
            "totalTokens": usage.totalTokens,
            "requestCount": usage.requestCount,
            "date": dateString
        ]
        userDefaults.set(data, forKey: "\(usageKeyPrefix)\(dateString)")
    }
    
    private func resetDailyUsage() {
        userDefaults.removeObject(forKey: dateKey)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - OpenAI Client

class OpenAIClient {
    static let shared = OpenAIClient()
    
    private let apiKeyManager = APIKeyManager()
    private let rateLimiter = RateLimiter()
    private let usageTracker = UsageTracker()
    private let baseURL = "https://api.openai.com/v1"
    
    private var session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        session = URLSession(configuration: configuration)
    }
    
    // MARK: - API Key Management
    
    func setAPIKey(_ key: String) throws {
        try apiKeyManager.storeAPIKey(key)
    }
    
    func getAPIKey() throws -> String? {
        return try apiKeyManager.retrieveAPIKey()
    }
    
    func hasValidAPIKey() -> Bool {
        return apiKeyManager.hasValidAPIKey()
    }
    
    func clearAPIKey() throws {
        try apiKeyManager.clearAPIKey()
    }
    
    // MARK: - Chat Completion (GPT-4 & GPT-3.5-Turbo)
    
    func sendMessage(
        messages: [OpenAIMessage],
        model: String = "gpt-4",
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil
    ) async throws -> OpenAIResponse {
        guard rateLimiter.canMakeRequest() else {
            let waitTime = rateLimiter.timeUntilNextRequest
            throw OpenAIError.rateLimited(waitTime: waitTime)
        }
        
        guard rateLimiter.canMakeRequestToday() else {
            throw OpenAIError.dailyLimitExceeded
        }
        
        guard let apiKey = try getAPIKey() else {
            throw OpenAIError.noAPIKey
        }
        
        let request = OpenAIRequest(
            model: model,
            messages: messages,
            maxTokens: maxTokens,
            temperature: temperature,
            stream: false,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty
        )
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        rateLimiter.recordRequest()
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            throw OpenAIError.rateLimited(waitTime: 60) // Default 1 Minute bei 429
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        // Usage tracking
        if let usage = openAIResponse.usage {
            usageTracker.recordUsage(
                promptTokens: usage.prompt_tokens,
                completionTokens: usage.completion_tokens
            )
        }
        
        return openAIResponse
    }
    
    // MARK: - Streaming Chat Completion
    
    func sendMessageStream(
        messages: [OpenAIMessage],
        model: String = "gpt-4",
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil
    ) async throws -> AsyncThrowingStream<String, Error> {
        guard rateLimiter.canMakeRequest() else {
            let waitTime = rateLimiter.timeUntilNextRequest
            throw OpenAIError.rateLimited(waitTime: waitTime)
        }
        
        guard let apiKey = try getAPIKey() else {
            throw OpenAIError.noAPIKey
        }
        
        let request = OpenAIRequest(
            model: model,
            messages: messages,
            maxTokens: maxTokens,
            temperature: temperature,
            stream: true,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty
        )
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        rateLimiter.recordRequest()
        
        return AsyncThrowingStream { continuation in
            let task = session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.finish(throwing: OpenAIError.noData)
                    return
                }
                
                // Parse SSE Stream
                let lines = String(data: data, encoding: .utf8)?.components(separatedBy: "\n") ?? []
                
                for line in lines {
                    if line.hasPrefix("data: ") {
                        let dataPart = line.replacingOccurrences(of: "data: ", with: "")
                        
                        if dataPart == "[DONE]" {
                            continuation.finish()
                            return
                        }
                        
                        if let jsonData = dataPart.data(using: .utf8),
                           let streamResponse = try? JSONDecoder().decode(OpenAIStreamResponse.self, from: jsonData),
                           let content = streamResponse.choices.first?.delta.content {
                            continuation.yield(content)
                        }
                    }
                }
                
                continuation.finish()
            }
            
            task.resume()
            
            continuation.onTermination = { @Sendable [weak task] _ in
                task?.cancel()
            }
        }
    }
    
    // MARK: - Content Type Specific Methods
    
    func generateEmail(
        content: String,
        model: String = "gpt-4",
        emailType: EmailType = .general
    ) async throws -> OpenAIResponse {
        let systemPrompt = generateEmailPrompt(emailType: emailType)
        let messages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: content)
        ]
        
        return try await sendMessage(
            messages: messages,
            model: model,
            maxTokens: 1000,
            temperature: 0.7
        )
    }
    
    func generateMeeting(
        content: String,
        model: String = "gpt-4",
        meetingType: MeetingType = .general
    ) async throws -> OpenAIResponse {
        let systemPrompt = generateMeetingPrompt(meetingType: meetingType)
        let messages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: content)
        ]
        
        return try await sendMessage(
            messages: messages,
            model: model,
            maxTokens: 1500,
            temperature: 0.8
        )
    }
    
    func generateArticle(
        content: String,
        model: String = "gpt-4",
        articleType: ArticleType = .general
    ) async throws -> OpenAIResponse {
        let systemPrompt = generateArticlePrompt(articleType: articleType)
        let messages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: content)
        ]
        
        return try await sendMessage(
            messages: messages,
            model: model,
            maxTokens: 2000,
            temperature: 0.6
        )
    }
    
    // MARK: - Usage Statistics
    
    func getCurrentUsage() -> UsageTracker.DailyUsage {
        return usageTracker.getCurrentDailyUsage()
    }
    
    func getUsageHistory(days: Int = 7) -> [UsageTracker.DailyUsage] {
        return usageTracker.getUsageHistory(days: days)
    }
}

// MARK: - Content Type Definitions

enum EmailType {
    case general
    case business
    case support
    case marketing
    case followUp
    case thankYou
}

enum MeetingType {
    case general
    case project
    case planning
    case review
    case brainstorming
}

enum ArticleType {
    case general
    case technical
    case blog
    case news
    case tutorial
}

// MARK: - Prompt Generators

private extension OpenAIClient {
    func generateEmailPrompt(emailType: EmailType) -> String {
        switch emailType {
        case .general:
            return """
            Du bist ein professioneller E-Mail-Assistent. Erstelle prägnante, höfliche und gut strukturierte E-Mails.
            Verwende eine klare Betreffzeile, eine angemessene Anrede, den Hauptinhalt und einen professionellen Abschluss.
            """
        case .business:
            return """
            Du bist ein Geschäfts-E-Mail-Experte. Erstelle professionelle Geschäftsmails mit:
            - Präziser Betreffzeile
            - Höflicher, aber direkter Anrede
            - Klar strukturiertem Inhalt
            - Call-to-Action wenn nötig
            - Professionellem Abschluss
            """
        case .support:
            return """
            Du bist ein Kundensupport-Experte. Erstelle hilfsbereite und lösungsorientierte E-Mails mit:
            - Verständnisvollem Ton
            - Klaren Schritten zur Lösung
            - Zusätzlicher Hilfsangebot
            - Freundlichem Abschluss
            """
        case .marketing:
            return """
            Du bist ein Marketing-Experte. Erstelle überzeugende Marketing-E-Mails mit:
            - Aufmerksamkeitsstarker Betreffzeile
            - Wertversprechen
            - Klaren Call-to-Actions
            - Überzeugendem Inhalt
            """
        case .followUp:
            return """
            Du bist ein Follow-up-Experte. Erstelle höfliche Nachfass-E-Mails mit:
            - Höflichem Hinweis auf vorherige Kommunikation
            - Klarem Zweck der Nachfrage
            - Höflichem Abschluss
            """
        case .thankYou:
            return """
            Du bist ein Dankes-E-Mail-Experte. Erstelle aufrichtige Danksagungen mit:
            - Aufrichtigem Dank
            - Spezifischen Details warum
            - Persönlichem Ton
            - Höflichem Abschluss
            """
        }
    }
    
    func generateMeetingPrompt(meetingType: MeetingType) -> String {
        switch meetingType {
        case .general:
            return """
            Du bist ein Meeting-Assistent. Erstelle strukturierte Meeting-Notizen mit:
            - Meeting-Ziele
            - Diskussionspunkte
            - Beschlüsse und Ergebnisse
            - Aufgaben und Verantwortlichkeiten
            - Follow-up Schritte
            """
        case .project:
            return """
            Du bist ein Projekt-Management-Experte. Erstelle detaillierte Projekt-Meeting-Notizen mit:
            - Projektstatus Update
            - Meilensteine und Zeitplan
            - Risiken und Probleme
            -分配 задач und Verantwortlichkeiten
            - Nächste Schritte
            """
        case .planning:
            return """
            Du bist ein Planungs-Experte. Erstelle strukturierten Meeting-Plan mit:
            - Meeting-Ziele
            - Agenda Punkte
            - Erwartete Ergebnisse
            - Zeitrahmen für jeden Punkt
            - Vorbereitung erforderlich
            """
        case .review:
            return """
            Du bist ein Review-Experte. Erstelle umfassende Review-Notizen mit:
            - Was wurde Reviewt
            - Bewertung und Feedback
            - Gefundene Probleme
            - Empfohlene Verbesserungen
            - Nächste Schritte
            """
        case .brainstorming:
            return """
            Du bist ein Brainstorming-Facilitator. Erstelle kreative Ideensammlung mit:
            - Ideen mit Beschreibungen
            - Kategorisierung der Ideen
            - Bewertung und Priorisierung
            - Umsetzbarkeit Bewertung
            - Nächste Schritte zur Umsetzung
            """
        }
    }
    
    func generateArticlePrompt(articleType: ArticleType) -> String {
        switch articleType {
        case .general:
            return """
            Du bist ein Content-Experte. Erstelle ansprechende Artikel mit:
            - Fesselnder Titel
            - Einleitung
            - Gut strukturierte Abschnitte
            - Praktische Beispiele
            - Fazit und Zusammenfassung
            """
        case .technical:
            return """
            Du bist ein technischer Redakteur. Erstelle präzise technische Artikel mit:
            - Technischer Titel
            - Kontext und Problemstellung
            - Schritt-für-Schritt Lösung
            - Code-Beispiele wenn relevant
            - Erklärungen für technische Begriffe
            """
        case .blog:
            return """
            Du bist ein Blog-Autor. Erstelle engaging Blog-Posts mit:
            - Click-bait Titel
            - Persönliche Einleitung
            - Unterhaltsamer Inhalt
            - Praktische Tipps
            - Call-to-Action am Ende
            """
        case .news:
            return """
            Du bist ein Nachrichten-Reporter. Erstelle objektive News-Artikel mit:
            - Informative Überschrift
            - Fakten und Events
            - Quellen wenn verfügbar
            - Hintergrund-Informationen
            - Ausgewogene Perspektive
            """
        case .tutorial:
            return """
            Du bist ein Tutorial-Autor. Erstelle lehrreiche Anleitungen mit:
            - Lernziel-Definition
            - Voraussetzungen
            - Schritt-für-Schritt Anleitung
            - Screenshots/Beispiele wo nötig
            - Zusammenfassung und weitere Ressourcen
            """
        }
    }
}

// MARK: - Error Types

enum OpenAIError: Error, LocalizedError {
    case noAPIKey
    case rateLimited(waitTime: TimeInterval)
    case dailyLimitExceeded
    case invalidResponse
    case noData
    case httpError(statusCode: Int, message: String)
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Kein OpenAI API Key konfiguriert"
        case .rateLimited(let waitTime):
            return "Rate limit erreicht. Bitte warten Sie \(Int(waitTime)) Sekunden."
        case .dailyLimitExceeded:
            return "Tägliches Rate Limit erreicht"
        case .invalidResponse:
            return "Ungültige API-Antwort"
        case .noData:
            return "Keine Daten erhalten"
        case .httpError(let statusCode, let message):
            return "HTTP Fehler \(statusCode): \(message)"
        case .decodingFailed(let error):
            return "Dekodierung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}