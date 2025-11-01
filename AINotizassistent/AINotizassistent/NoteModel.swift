//
//  NoteModel.swift
//  Intelligente Notizen App
//

import Foundation
import SwiftUI

// MARK: - Note Model
struct NoteModel: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var contentType: ContentType
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var priority: NotePriority
    var isBookmarked: Bool
    var isArchived: Bool
    var aiSummary: String?
    var aiKeywords: [String]?
    var metadata: [String: AnyCodable]
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        contentType: ContentType,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tags: [String] = [],
        priority: NotePriority = .medium,
        isBookmarked: Bool = false,
        isArchived: Bool = false,
        aiSummary: String? = nil,
        aiKeywords: [String]? = nil,
        metadata: [String: AnyCodable] = [:]
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.contentType = contentType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.priority = priority
        self.isBookmarked = isBookmarked
        self.isArchived = isArchived
        self.aiSummary = aiSummary
        self.aiKeywords = aiKeywords
        self.metadata = metadata
    }
    
    // MARK: - Convenience Initializers
    init(from text: String, contentType: ContentType) {
        self.init(
            title: NoteModel.extractTitle(from: text) ?? "Neue Notiz",
            content: text,
            contentType: contentType
        )
    }
    
    // MARK: - Helper Methods
    private static func extractTitle(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        let firstNonEmptyLine = lines.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return firstNonEmptyLine?.trimmingCharacters(in: .whitespacesAndNewlines).prefix(50).description
    }
    
    func updateContent(_ newContent: String) -> NoteModel {
        var copy = self
        copy.content = newContent
        copy.updatedAt = Date()
        copy.title = NoteModel.extractTitle(from: newContent) ?? title
        return copy
    }
    
    func addTag(_ tag: String) -> NoteModel {
        var copy = self
        if !copy.tags.contains(tag) {
            copy.tags.append(tag)
        }
        copy.updatedAt = Date()
        return copy
    }
    
    func removeTag(_ tag: String) -> NoteModel {
        var copy = self
        copy.tags.removeAll { $0 == tag }
        copy.updatedAt = Date()
        return copy
    }
    
    func toggleBookmark() -> NoteModel {
        var copy = self
        copy.isBookmarked.toggle()
        copy.updatedAt = Date()
        return copy
    }
    
    func setAISummary(_ summary: String) -> NoteModel {
        var copy = self
        copy.aiSummary = summary
        copy.updatedAt = Date()
        return copy
    }
    
    func setAIKeywords(_ keywords: [String]) -> NoteModel {
        var copy = self
        copy.aiKeywords = keywords
        copy.updatedAt = Date()
        return copy
    }
}

// MARK: - Note Priority
enum NotePriority: String, CaseIterable, Codable {
    case low = "niedrig"
    case medium = "mittel"
    case high = "hoch"
    case critical = "kritisch"
    
    var color: Color {
        switch self {
        case .low:
            return Color.gray
        case .medium:
            return Color.blue
        case .high:
            return Color.orange
        case .critical:
            return Color.red
        }
    }
    
    var icon: String {
        switch self {
        case .low:
            return "⬇️"
        case .medium:
            return "➡️"
        case .high:
            return "⬆️"
        case .critical:
            return "🔴"
        }
    }
}

// MARK: - AnyCodable for flexible metadata
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let date = try? container.decode(Date.self) {
            self.init(date)
        } else if let array = try? container.decode([AnyCodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath,
                                    debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let date as Date:
            try container.encode(date)
        case let array as [Any]:
            try container.encode(array.map(AnyCodable.init))
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues(AnyCodable.init))
        default:
            throw EncodingError.invalidValue(value,
                EncodingError.Context(codingPath: container.codingPath,
                                    debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Note ViewModel
final class NoteViewModel: ObservableObject {
    @Published var notes: [NoteModel] = []
    @Published var searchQuery: String = ""
    @Published var selectedContentType: ContentType?
    @Published var selectedPriority: NotePriority?
    
    var filteredNotes: [NoteModel] {
        var filtered = notes
        
        // Filter by search query
        if !searchQuery.isEmpty {
            filtered = filtered.filter { note in
                note.title.localizedCaseInsensitiveContains(searchQuery) ||
                note.content.localizedCaseInsensitiveContains(searchQuery) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }
        
        // Filter by content type
        if let contentType = selectedContentType {
            filtered = filtered.filter { $0.contentType == contentType }
        }
        
        // Filter by priority
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        // Sort by updated date (newest first)
        return filtered.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // MARK: - CRUD Operations
    func addNote(_ note: NoteModel) {
        notes.append(note)
        objectWillChange.send()
    }
    
    func updateNote(_ updatedNote: NoteModel) {
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
            objectWillChange.send()
        }
    }
    
    func deleteNote(_ note: NoteModel) {
        notes.removeAll { $0.id == note.id }
        objectWillChange.send()
    }
    
    func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        objectWillChange.send()
    }
    
    // MARK: - Search and Filter
    func searchNotes(query: String) {
        searchQuery = query
    }
    
    func filterByContentType(_ type: ContentType?) {
        selectedContentType = type
    }
    
    func filterByPriority(_ priority: NotePriority?) {
        selectedPriority = priority
    }
    
    func clearFilters() {
        selectedContentType = nil
        selectedPriority = nil
        searchQuery = ""
    }
    
    // MARK: - Bulk Operations
    func bookmarkMultipleNotes(_ notesToBookmark: [NoteModel]) {
        for note in notesToBookmark {
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index].isBookmarked = true
                notes[index].updatedAt = Date()
            }
        }
        objectWillChange.send()
    }
    
    func archiveMultipleNotes(_ notesToArchive: [NoteModel]) {
        for note in notesToArchive {
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index].isArchived = true
                notes[index].updatedAt = Date()
            }
        }
        objectWillChange.send()
    }
}