//
//  NotionProviderManager.swift
//  AINotizassistent
//
//  Spezialisierter Manager für Notion API Integration
//

import Foundation
import Network

/// Spezialisierter Manager für Notion API Integration
class NotionProviderManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isInitialized = false
    @Published var workspaces: [NotionWorkspace] = []
    @Published var databases: [NotionDatabase] = []
    @Published var pages: [NotionPage] = []
    @Published var isLoading = false
    @Published var lastSync: Date?
    @Published var rateLimitStatus: NotionRateLimitStatus = .unknown
    @Published var usageStats: NotionUsageStats?
    
    // MARK: - Notion Configuration
    
    struct NotionConfig {
        static let baseURL = "https://api.notion.com/v1"
        static let apiVersion = "2022-06-28"
        static let timeoutInterval: TimeInterval = 30
    }
    
    // MARK: - Rate Limiting
    
    enum NotionRateLimitStatus {
        case normal
        case approaching
        case limited(interval: TimeInterval)
    }
    
    private var rateLimitInfo: (remaining: Int, resetTime: Date)?
    private let requestQueue = DispatchQueue(label: "notion.requests", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init() {
        loadCachedData()
    }
    
    // MARK: - API Key Management
    
    var isAPIKeyValid: Bool {
        guard let key = APIKeyManager.shared.getDecryptedKey(for: .notion) else { return false }
        return !key.isEmpty
    }
    
    var currentAPIKey: String? {
        return APIKeyManager.shared.getDecryptedKey(for: .notion)
    }
    
    // MARK: - User Information
    
    func getCurrentUser() async throws -> NotionUser {
        guard isAPIKeyValid else {
            throw NotionError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                let url = URL(string: "\(NotionConfig.baseURL)/users/me")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(self.currentAPIKey!)", forHTTPHeaderField: "Authorization")
                request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: NotionError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NotionError.noData)
                        return
                    }
                    
                    do {
                        let user = try JSONDecoder().decode(NotionUser.self, from: data)
                        continuation.resume(returning: user)
                    } catch {
                        continuation.resume(throwing: NotionError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    // MARK: - Database Management
    
    func listDatabases() async throws -> [NotionDatabase] {
        guard isAPIKeyValid else {
            throw NotionError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                let url = URL(string: "\(NotionConfig.baseURL)/search")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(self.currentAPIKey!)", forHTTPHeaderField: "Authorization")
                request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "filter": [
                        "property": "object",
                        "value": "database"
                    ],
                    "page_size": 100
                ]
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.updateRateLimit(from: response)
                    
                    if let error = error {
                        continuation.resume(throwing: NotionError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NotionError.noData)
                        return
                    }
                    
                    do {
                        let result = try JSONDecoder().decode(NotionSearchResponse.self, from: data)
                        let databases = result.results.compactMap { item in
                            if case .database(let database) = item {
                                return database
                            }
                            return nil
                        }
                        
                        self.databases = databases
                        continuation.resume(returning: databases)
                    } catch {
                        continuation.resume(throwing: NotionError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func getDatabase(_ databaseId: String) async throws -> NotionDatabase {
        guard isAPIKeyValid else {
            throw NotionError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                let url = URL(string: "\(NotionConfig.baseURL)/databases/\(databaseId)")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(self.currentAPIKey!)", forHTTPHeaderField: "Authorization")
                request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.updateRateLimit(from: response)
                    
                    if let error = error {
                        continuation.resume(throwing: NotionError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NotionError.noData)
                        return
                    }
                    
                    do {
                        let database = try JSONDecoder().decode(NotionDatabase.self, from: data)
                        continuation.resume(returning: database)
                    } catch {
                        continuation.resume(throwing: NotionError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func createDatabase(name: String, description: String? = nil, parent: NotionParent) async throws -> NotionDatabase {
        guard isAPIKeyValid else {
            throw NotionError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                let url = URL(string: "\(NotionConfig.baseURL)/databases")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(self.currentAPIKey!)", forHTTPHeaderField: "Authorization")
                request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "title": [[
                        "type": "text",
                        "text": ["content": name]
                    ]],
                    "parent": [
                        "type": parent.type.rawValue,
                        parent.type.rawValue: parent.id
                    ]
                ]
                
                if let description = description {
                    body["description"] = [[
                        "type": "text",
                        "text": ["content": description]
                    ]]
                }
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.updateRateLimit(from: response)
                    
                    if let error = error {
                        continuation.resume(throwing: NotionError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NotionError.noData)
                        return
                    }
                    
                    do {
                        let database = try JSONDecoder().decode(NotionDatabase.self, from: data)
                        self.databases.append(database)
                        continuation.resume(returning: database)
                    } catch {
                        continuation.resume(throwing: NotionError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    // MARK: - Page Management
    
    func listPages() async throws -> [NotionPage] {
        guard isAPIKeyValid else {
            throw NotionError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                let url = URL(string: "\(NotionConfig.baseURL)/search")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(self.currentAPIKey!)", forHTTPHeaderField: "Authorization")
                request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "filter": [
                        "property": "object",
                        "value": "page"
                    ],
                    "page_size": 100
                ]
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.updateRateLimit(from: response)
                    
                    if let error = error {
                        continuation.resume(throwing: NotionError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NotionError.noData)
                        return
                    }
                    
                    do {
                        let result = try JSONDecoder().decode(NotionSearchResponse.self, from: data)
                        let pages = result.results.compactMap { item in
                            if case .page(let page) = item {
                                return page
                            }
                            return nil
                        }
                        
                        self.pages = pages
                        continuation.resume(returning: pages)
                    } error {
                        continuation.resume(throwing: NotionError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func getPage(_ pageId: String) async throws -> NotionPage {
        guard isAPIKeyValid else {
            throw NotionError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                let url = URL(string: "\(NotionConfig.baseURL)/pages/\(pageId)")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(self.currentAPIKey!)", forHTTPHeaderField: "Authorization")
                request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.updateRateLimit(from: response)
                    
                    if let error = error {
                        continuation.resume(throwing: NotionError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NotionError.noData)
                        return
                    }
                    
                    do {
                        let page = try JSONDecoder().decode(NotionPage.self, from: data)
                        continuation.resume(returning: page)
                    } catch {
                        continuation.resume(throwing: NotionError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func createPage(title: String, parent: NotionParent, properties: [String: NotionProperty] = [:]) async throws -> NotionPage {
        guard isAPIKeyValid else {
            throw NotionError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                let url = URL(string: "\(NotionConfig.baseURL)/pages")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(self.currentAPIKey!)", forHTTPHeaderField: "Authorization")
                request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                var pageProperties: [String: Any] = [
                    "title": [[
                        "type": "text",
                        "text": ["content": title]
                    ]]
                ]
                
                for (key, property) in properties {
                    pageProperties[key] = property.toDict()
                }
                
                let body: [String: Any] = [
                    "properties": pageProperties,
                    "parent": [
                        "type": parent.type.rawValue,
                        parent.type.rawValue: parent.id
                    ]
                ]
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.updateRateLimit(from: response)
                    
                    if let error = error {
                        continuation.resume(throwing: NotionError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NotionError.noData)
                        return
                    }
                    
                    do {
                        let page = try JSONDecoder().decode(NotionPage.self, from: data)
                        self.pages.append(page)
                        continuation.resume(returning: page)
                    } catch {
                        continuation.resume(throwing: NotionError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func updatePage(_ pageId: String, properties: [String: NotionProperty]) async throws -> NotionPage {
        guard isAPIKeyValid else {
            throw NotionError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                let url = URL(string: "\(NotionConfig.baseURL)/pages/\(pageId)")!
                var request = URLRequest(url: url)
                request.httpMethod = "PATCH"
                request.setValue("Bearer \(self.currentAPIKey!)", forHTTPHeaderField: "Authorization")
                request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                var pageProperties: [String: Any] = [:]
                for (key, property) in properties {
                    pageProperties[key] = property.toDict()
                }
                
                let body: [String: Any] = [
                    "properties": pageProperties
                ]
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.updateRateLimit(from: response)
                    
                    if let error = error {
                        continuation.resume(throwing: NotionError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NotionError.noData)
                        return
                    }
                    
                    do {
                        let page = try JSONDecoder().decode(NotionPage.self, from: data)
                        
                        // Update local cache
                        if let index = self.pages.firstIndex(where: { $0.id == pageId }) {
                            self.pages[index] = page
                        }
                        
                        continuation.resume(returning: page)
                    } catch {
                        continuation.resume(throwing: NotionError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    // MARK: - Search and Query
    
    func search(query: String, filter: NotionSearchFilter? = nil) async throws -> [NotionSearchResult] {
        guard isAPIKeyValid else {
            throw NotionError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                let url = URL(string: "\(NotionConfig.baseURL)/search")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(self.currentAPIKey!)", forHTTPHeaderField: "Authorization")
                request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                var body: [String: Any] = [
                    "query": query,
                    "page_size": 100
                ]
                
                if let filter = filter {
                    body["filter"] = filter.toDict()
                }
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.updateRateLimit(from: response)
                    
                    if let error = error {
                        continuation.resume(throwing: NotionError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NotionError.noData)
                        return
                    }
                    
                    do {
                        let result = try JSONDecoder().decode(NotionSearchResponse.self, from: data)
                        continuation.resume(returning: result.results)
                    } error {
                        continuation.resume(throwing: NotionError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func queryDatabase(databaseId: String, filter: NotionFilter? = nil, sorts: [NotionSort]? = nil) async throws -> [NotionPage] {
        guard isAPIKeyValid else {
            throw NotionError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                let url = URL(string: "\(NotionConfig.baseURL)/databases/\(databaseId)/query")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(self.currentAPIKey!)", forHTTPHeaderField: "Authorization")
                request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                var body: [String: Any] = [
                    "page_size": 100
                ]
                
                if let filter = filter {
                    body["filter"] = filter.toDict()
                }
                
                if let sorts = sorts {
                    body["sorts"] = sorts.map { $0.toDict() }
                }
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.updateRateLimit(from: response)
                    
                    if let error = error {
                        continuation.resume(throwing: NotionError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NotionError.noData)
                        return
                    }
                    
                    do {
                        let result = try JSONDecoder().decode(NotionDatabaseQueryResponse.self, from: data)
                        continuation.resume(returning: result.results)
                    } catch {
                        continuation.resume(throwing: NotionError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    // MARK: - Rate Limiting
    
    private func updateRateLimit(from response: URLResponse?) {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        if let remaining = Int(httpResponse.value(forHTTPHeaderField: "X-Notion-Rate-Limit-Remaining") ?? ""),
           let resetTimeString = httpResponse.value(forHTTPHeaderField: "X-Notion-Rate-Limit-Reset") {
            
            let resetTime = Date(timeIntervalSinceNow: Double(resetTimeString) ?? 0)
            rateLimitInfo = (remaining, resetTime)
            updateRateLimitStatus()
        }
    }
    
    private func updateRateLimitStatus() {
        guard let info = rateLimitInfo else { return }
        
        if info.remaining <= 0 {
            rateLimitStatus = .limited(interval: info.resetTime.timeIntervalSinceNow)
        } else if info.remaining < 5 {
            rateLimitStatus = .approaching
        } else {
            rateLimitStatus = .normal
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: "notion_databases"),
           let cached = try? JSONDecoder().decode([NotionDatabase].self, from: data) {
            databases = cached
        }
        
        if let data = UserDefaults.standard.data(forKey: "notion_pages"),
           let cached = try? JSONDecoder().decode([NotionPage].self, from: data) {
            pages = cached
        }
        
        if let data = UserDefaults.standard.data(forKey: "notion_usage_stats"),
           let cached = try? JSONDecoder().decode(NotionUsageStats.self, from: data) {
            usageStats = cached
        }
    }
    
    private func saveCachedData() {
        if let data = try? JSONEncoder().encode(databases) {
            UserDefaults.standard.set(data, forKey: "notion_databases")
        }
        
        if let data = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(data, forKey: "notion_pages")
        }
        
        if let data = try? JSONEncoder().encode(usageStats ?? NotionUsageStats()) {
            UserDefaults.standard.set(data, forKey: "notion_usage_stats")
        }
    }
    
    func syncData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let _ = try await listDatabases()
            let _ = try await listPages()
            saveCachedData()
            lastSync = Date()
        } catch {
            print("Notion sync error: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum NotionError: Error, LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case decodingError(String)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Notion API Key ist ungültig oder nicht konfiguriert"
        case .networkError(let message):
            return "Netzwerkfehler: \(message)"
        case .decodingError(let message):
            return "Dekodierungsfehler: \(message)"
        case .noData:
            return "Keine Daten erhalten"
        }
    }
}

struct NotionUsageStats: Codable {
    var totalRequests: Int = 0
    var successfulRequests: Int = 0
    var failedRequests: Int = 0
    var lastSync: Date?
    var dailyUsage: [String: Int] = [:]
}

// MARK: - Notion Data Models

// Für die vollständigen Notion API Models würde ich die offizielle Notion Swift SDK verwenden
// oder die Models nach der offiziellen API Dokumentation implementieren.
// Hier sind die wichtigsten Models als Platzhalter:

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
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = ["type": type]
        
        switch type {
        case "title":
            dict["title"] = title?.map { $0.toDict() } ?? []
        case "rich_text":
            dict["rich_text"] = rich_text?.map { $0.toDict() } ?? []
        case "number":
            dict["number"] = number ?? 0
        case "select":
            dict["select"] = ["name": select?.name ?? ""]
        case "multi_select":
            dict["multi_select"] = multi_select?.map { ["name": $0.name] } ?? []
        case "date":
            dict["date"] = ["start": date?.start ?? ""]
        case "checkbox":
            dict["checkbox"] = checkbox ?? false
        case "url":
            dict["url"] = url ?? ""
        case "email":
            dict["email"] = email ?? ""
        case "phone_number":
            dict["phone_number"] = phone_number ?? ""
        default:
            break
        }
        
        return dict
    }
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

enum NotionParentType: String {
    case page = "page_id"
    case database = "database_id"
    case workspace = "workspace"
}

struct NotionParent {
    let type: NotionParentType
    let id: String
}

struct NotionSearchFilter {
    let property: String
    let value: String
    
    func toDict() -> [String: Any] {
        return [
            "property": property,
            "value": value
        ]
    }
}

struct NotionFilter {
    let property: String
    let condition: String
    let value: Any
    
    func toDict() -> [String: Any] {
        return [
            "property": property,
            condition: value
        ]
    }
}

struct NotionSort {
    let timestamp: String?
    let direction: String
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = ["direction": direction]
        if let timestamp = timestamp {
            dict["timestamp"] = timestamp
        }
        return dict
    }
}

enum NotionSearchResult {
    case page(NotionPage)
    case database(NotionDatabase)
}

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

// MARK: - Extensions

extension NotionRichText {
    func toDict() -> [String: Any] {
        return [
            "type": type,
            "text": [
                "content": text.content
            ]
        ]
    }
}