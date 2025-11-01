//
//  NotionIntegration.swift
//  AINotizassistent
//
//  Umfassende Notion API Integration für iOS
//

import Foundation
import UIKit
import Combine

// MARK: - Notion API Models
struct NotionError: Codable, Error {
    let code: String
    let message: String
}

struct NotionResponse<T: Codable>: Codable {
    let results: [T]
    let next_cursor: String?
    let has_more: Bool
}

struct NotionDatabase: Codable {
    let id: String
    let title: [RichText]
    let properties: [String: NotionProperty]
    let parent: DatabaseParent
    let url: String
    let created_time: String
    let last_edited_time: String
}

struct NotionPage: Codable {
    let id: String
    let properties: [String: NotionPropertyValue]
    let content: [NotionBlock]?
    let parent: PageParent
    let url: String
    let created_time: String
    let last_edited_time: String
}

struct NotionBlock: Codable {
    let id: String
    let type: BlockType
    let content: BlockContent
    let created_time: String
    let last_edited_time: String
}

enum BlockType: String, Codable {
    case paragraph
    case heading_1 = "heading_1"
    case heading_2 = "heading_2"
    case heading_3 = "heading_3"
    case bullet_list_item = "bulleted_list_item"
    case number_list_item = "numbered_list_item"
    case to_do = "to_do"
    case toggle
    case code
    case quote
    case divider
    case image
    case file
    case bookmark
    case callout
    case column_list = "column_list"
    case child_database = "child_database"
    case child_page = "child_page"
}

struct BlockContent: Codable {
    let paragraph: RichTextContent?
    let heading_1: RichTextContent?
    let heading_2: RichTextContent?
    let heading_3: RichTextContent?
    let bulleted_list_item: RichTextContent?
    let numbered_list_item: RichTextContent?
    let to_do: TodoContent?
    let toggle: RichTextContent?
    let code: CodeContent?
    let quote: RichTextContent?
    let divider: EmptyContent?
    let image: FileContent?
    let file: FileContent?
    let bookmark: BookmarkContent?
    let callout: CalloutContent?
    case column_list: ColumnListContent?
    case child_database: ChildDatabaseContent?
    case child_page: ChildPageContent?
}

struct RichText: Codable {
    let text: TextContent
    let annotations: TextAnnotations
    let href: String?
}

struct RichTextContent: Codable {
    let rich_text: [RichText]
}

struct TextContent: Codable {
    let content: String
    let link: Link?
}

struct TextAnnotations: Codable {
    let bold: Bool
    let italic: Bool
    let strikethrough: Bool
    let underline: Bool
    let code: Bool
    let color: String
}

struct Link: Codable {
    let url: String
}

struct CodeContent: Codable {
    let rich_text: [RichText]
    let language: String
    let caption: [RichText]?
}

struct TodoContent: Codable {
    let rich_text: [RichText]
    let checked: Bool
}

struct FileContent: Codable {
    let type: String
    let file: FileObject?
    let external: ExternalFile?
    let caption: [RichText]?
}

struct BookmarkContent: Codable {
    let url: String
    let caption: [RichText]?
}

struct CalloutContent: Codable {
    let rich_text: [RichText]
    let icon: IconContent?
    let color: String
}

struct IconContent: Codable {
    let emoji: String?
    let external: ExternalFile?
    let file: FileObject?
}

struct ColumnListContent: Codable {
    let has_column_header: Bool
    let column_ratio: Double
}

struct ChildDatabaseContent: Codable {
    let title: [RichText]
}

struct ChildPageContent: Codable {
    let title: [RichText]
}

struct EmptyContent: Codable {}

struct FileObject: Codable {
    let url: String
    let expiry_time: String
}

struct ExternalFile: Codable {
    let url: String
}

// MARK: - Properties and Values
struct NotionProperty: Codable {
    let id: String
    let type: PropertyType
    let title: EmptyContent?
    let rich_text: EmptyContent?
    let number: EmptyContent?
    let select: SelectProperty?
    let multi_select: MultiSelectProperty?
    let date: EmptyContent?
    let people: EmptyContent?
    let files: EmptyContent?
    let checkbox: EmptyContent?
    let url: EmptyContent?
    let email: EmptyContent?
    let phone_number: EmptyContent?
    let created_time: EmptyContent?
    let created_by: EmptyContent?
    let last_edited_time: EmptyContent?
    let last_edited_by: EmptyContent?
    let formula: EmptyContent?
    let relation: EmptyContent?
    let rollup: EmptyContent?
    let status: StatusProperty?
    let button: EmptyContent?
    let unique_id: EmptyContent?
    let verification: EmptyContent?
}

enum PropertyType: String, Codable {
    case title, rich_text, number, select, multi_select, date, people, files, checkbox, url, email, phone_number, created_time, created_by, last_edited_time, last_edited_by, formula, relation, rollup, status, button, unique_id, verification
}

struct SelectProperty: Codable {
    let options: [SelectOption]
}

struct MultiSelectProperty: Codable {
    let options: [SelectOption]
}

struct SelectOption: Codable {
    let id: String
    let name: String
    let color: String
}

struct StatusProperty: Codable {
    let options: [StatusOption]
    let groups: [StatusGroup]
}

struct StatusOption: Codable {
    let id: String
    let name: String
    let color: String
}

struct StatusGroup: Codable {
    let id: String
    let name: String
    let color: String
    let option_ids: [String]
}

struct NotionPropertyValue: Codable {
    let id: String
    let type: PropertyType
    let title: [RichText]?
    let rich_text: [RichText]?
    let number: Double?
    let select: SelectOption?
    let multi_select: [SelectOption]?
    let date: DateValue?
    let people: [User]?
    let files: [FileValue]?
    let checkbox: Bool?
    let url: String?
    let email: String?
    let phone_number: String?
    let created_time: String?
    let created_by: User?
    let last_edited_time: String?
    let last_edited_by: User?
    let formula: FormulaValue?
    let relation: [RelationValue]?
    let rollup: RollupValue?
    let status: SelectOption?
    let button: EmptyContent?
    let unique_id: UniqueIdValue?
    let verification: VerificationValue?
}

struct DateValue: Codable {
    let start: String
    let end: String?
    let time_zone: String?
}

struct User: Codable {
    let id: String
    let name: String
    let avatar_url: String?
    let type: String
    let person: Person?
    let bot: Bot?
}

struct Person: Codable {
    let email: String?
}

struct Bot: Codable {
    let owner: BotOwner?
}

struct BotOwner: Codable {
    let type: String
    let workspace: Bool
    let workspace_name: String?
}

struct FileValue: Codable {
    let name: String
    let type: String
    let file: FileObject?
    let external: ExternalFile?
}

struct FormulaValue: Codable {
    let type: String
    let string: String?
    let number: Double?
    let boolean: Bool?
    let date: DateValue?
}

struct RelationValue: Codable {
    let id: String
}

struct RollupValue: Codable {
    let type: String
    let number: Double?
    let date: DateValue?
    let array: [Any]?
}

struct UniqueIdValue: Codable {
    let prefix: String?
    let number: Int
}

struct VerificationValue: Codable {
    let type: String
    let verified: Bool
}

struct DatabaseParent: Codable {
    let type: String
    let workspace: Bool?
}

struct PageParent: Codable {
    let type: String
    let database_id: String?
    let page_id: String?
}

// MARK: - API Requests
struct NotionCreatePageRequest: Codable {
    let parent: PageParent
    let properties: [String: NotionPropertyValue]
    let children: [NotionBlock]?
}

struct NotionUpdatePageRequest: Codable {
    let properties: [String: NotionPropertyValue]
}

struct NotionCreateDatabaseRequest: Codable {
    let parent: DatabaseParent
    let title: [RichText]
    let properties: [String: NotionProperty]
}

struct NotionQueryDatabaseRequest: Codable {
    let page_size: Int?
    let start_cursor: String?
    let sorts: [SortObject]?
    let filter: FilterObject?
}

struct SortObject: Codable {
    let timestamp: String?
    let direction: String
    let property: String?
}

struct FilterObject: Codable {
    let and: [FilterObject]?
    let or: [FilterObject]?
    let property: String?
    let type: String?
    let condition: String?
    let value: AnyCodable?
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        case let date as Date:
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: date))
        default:
            try container.encodeNil()
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let array = try? container.decode([AnyCodable].self) {
            self.init(array.map { $0.value })
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.init(dict.mapValues { $0.value })
        } else {
            self.init(NSNull())
        }
    }
}

// MARK: - Main Notion Integration Class
@MainActor
class NotionIntegration: ObservableObject {
    private let baseURL = "https://api.notion.com/v1"
    private let apiVersion = "2022-06-28"
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isAuthenticated = false
    @Published var currentDatabase: NotionDatabase?
    @Published var pages: [NotionPage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var apiKey: String? {
        didSet {
            isAuthenticated = apiKey != nil
        }
    }
    
    init(apiKey: String? = nil) {
        self.session = URLSession.shared
        self.apiKey = apiKey
    }
    
    // MARK: - Authentication
    func setApiKey(_ key: String) {
        self.apiKey = key
        UserDefaults.standard.set(key, forKey: "NotionAPIKey")
    }
    
    func loadApiKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "NotionAPIKey") {
            setApiKey(savedKey)
        }
    }
    
    func clearApiKey() {
        apiKey = nil
        UserDefaults.standard.removeObject(forKey: "NotionAPIKey")
    }
    
    // MARK: - Database Management
    func createDatabase(title: String, parentDatabaseId: String, properties: [String: NotionProperty]) async throws -> NotionDatabase {
        guard let apiKey = apiKey else {
            throw NotionError(code: "AUTH_ERROR", message: "API Key nicht verfügbar")
        }
        
        let request = NotionCreateDatabaseRequest(
            parent: DatabaseParent(type: "page_id", workspace: false),
            title: [RichText(text: TextContent(content: title, link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)],
            properties: properties
        )
        
        return try await makeRequest(endpoint: "/databases", method: "POST", body: request)
    }
    
    func getDatabase(databaseId: String) async throws -> NotionDatabase {
        return try await makeRequest(endpoint: "/databases/\(databaseId)", method: "GET")
    }
    
    func queryDatabase(databaseId: String, filter: FilterObject? = nil, sorts: [SortObject]? = nil) async throws -> ([NotionPage], String?, Bool) {
        let request = NotionQueryDatabaseRequest(
            page_size: 50,
            sorts: sorts,
            filter: filter
        )
        
        let response: NotionResponse<NotionPage> = try await makeRequest(
            endpoint: "/databases/\(databaseId)/query",
            method: "POST",
            body: request
        )
        
        return (response.results, response.next_cursor, response.has_more)
    }
    
    // MARK: - Page Management
    func createPage(databaseId: String, properties: [String: NotionPropertyValue], blocks: [NotionBlock]? = nil) async throws -> NotionPage {
        let request = NotionCreatePageRequest(
            parent: PageParent(type: "database_id", database_id: databaseId, page_id: nil),
            properties: properties,
            children: blocks
        )
        
        return try await makeRequest(endpoint: "/pages", method: "POST", body: request)
    }
    
    func updatePage(pageId: String, properties: [String: NotionPropertyValue]) async throws -> NotionPage {
        let request = NotionUpdatePageRequest(properties: properties)
        return try await makeRequest(endpoint: "/pages/\(pageId)", method: "PATCH", body: request)
    }
    
    func getPage(pageId: String) async throws -> NotionPage {
        return try await makeRequest(endpoint: "/pages/\(pageId)", method: "GET")
    }
    
    func getPageBlocks(pageId: String) async throws -> [NotionBlock] {
        var allBlocks: [NotionBlock] = []
        var nextCursor: String?
        
        repeat {
            let response: NotionResponse<NotionBlock> = try await makeRequest(
                endpoint: "/blocks/\(pageId)/children",
                method: "GET",
                queryItems: nextCursor.map { ["start_cursor": $0] } ?? [:]
            )
            
            allBlocks.append(contentsOf: response.results)
            nextCursor = response.next_cursor
        } while nextCursor != nil
        
        return allBlocks
    }
    
    // MARK: - Block Management
    func appendBlocks(pageId: String, blocks: [NotionBlock]) async throws -> [NotionBlock] {
        let response: NotionResponse<NotionBlock> = try await makeRequest(
            endpoint: "/blocks/\(pageId)/children",
            method: "POST",
            body: ["children": blocks]
        )
        
        return response.results
    }
    
    func updateBlock(blockId: String, block: NotionBlock) async throws -> NotionBlock {
        return try await makeRequest(endpoint: "/blocks/\(blockId)", method: "PATCH", body: block)
    }
    
    // MARK: - Search
    func search(query: String, filter: [String: Any]? = nil) async throws -> ([SearchResult], String?, Bool) {
        var queryItems: [String: String] = ["query": query]
        
        if let filter = filter {
            let jsonData = try JSONSerialization.data(withJSONObject: filter)
            if let filterString = String(data: jsonData, encoding: .utf8) {
                queryItems["filter"] = filterString
            }
        }
        
        let response: SearchResponse = try await makeRequest(
            endpoint: "/search",
            method: "GET",
            queryItems: queryItems
        )
        
        return (response.results, response.next_cursor, response.has_more)
    }
    
    // MARK: - File Upload
    func uploadFile(fileData: Data, fileName: String, contentType: String) async throws -> FileObject {
        // Notion unterstützt kein direktes File Upload via REST API
        // Files müssen über externe URLs eingebunden werden
        throw NotionError(code: "UPLOAD_ERROR", message: "Direkter File Upload wird nicht unterstützt. Verwenden Sie externe URLs.")
    }
    
    // MARK: - Batch Operations
    func createMultiplePages(databaseId: String, pages: [(properties: [String: NotionPropertyValue], blocks: [NotionBlock]?)]) async throws -> [NotionPage] {
        var results: [NotionPage] = []
        
        for pageData in pages {
            do {
                let page = try await createPage(
                    databaseId: databaseId,
                    properties: pageData.properties,
                    blocks: pageData.blocks
                )
                results.append(page)
                
                // Rate limiting: 3 Requests pro Sekunde
                try await Task.sleep(nanoseconds: 333_333_333) // ~0.33 Sekunden
            } catch {
                print("Fehler beim Erstellen der Seite: \(error)")
            }
        }
        
        return results
    }
    
    // MARK: - Helper Methods
    private func makeRequest<T: Codable>(endpoint: String, method: String, body: Codable? = nil, queryItems: [String: String] = [:]) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NotionError(code: "INVALID_URL", message: "Ungültige URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiVersion, forHTTPHeaderField: "Notion-Version")
        
        if method != "GET", let body = body {
            let jsonData = try JSONEncoder().encode(AnyCodable(body))
            request.httpBody = jsonData
        }
        
        // Query parameters für GET requests
        if !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
            request.url = components.url
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NotionError(code: "INVALID_RESPONSE", message: "Ungültige Server-Antwort")
            }
            
            if httpResponse.statusCode >= 400 {
                let errorData = try JSONDecoder().decode(NotionError.self, from: data)
                throw errorData
            }
            
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as NotionError {
            throw error
        } catch {
            throw NotionError(code: "NETWORK_ERROR", message: "Netzwerk-Fehler: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types for Search
struct SearchResponse: Codable {
    let results: [SearchResult]
    let next_cursor: String?
    let has_more: Bool
}

enum SearchResult: Codable {
    case database(NotionDatabase)
    case page(NotionPage)
    case block(NotionBlock)
    
    enum CodingKeys: String, CodingKey {
        case object
        case database
        case page
        case block
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let object = try container.decode(String.self, forKey: .object)
        
        switch object {
        case "database":
            self = .database(try container.decode(NotionDatabase.self, forKey: .database))
        case "page":
            self = .page(try container.decode(NotionPage.self, forKey: .page))
        case "block":
            self = .block(try container.decode(NotionBlock.self, forKey: .block))
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                    debugDescription: "Unbekannter Object-Typ: \(object)")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .database(let database):
            try container.encode("database", forKey: .object)
            try container.encode(database, forKey: .database)
        case .page(let page):
            try container.encode("page", forKey: .object)
            try container.encode(page, forKey: .page)
        case .block(let block):
            try container.encode("block", forKey: .object)
            try container.encode(block, forKey: .block)
        }
    }
}