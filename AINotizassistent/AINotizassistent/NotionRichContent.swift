//
//  NotionRichContent.swift
//  AINotizassistent
//
//  Rich Content Support für Notion Blocks
//

import Foundation
import UIKit

// MARK: - Rich Content Builder
class NotionRichContentBuilder {
    
    // MARK: - Text Formatting
    func createRichText(
        content: String,
        bold: Bool = false,
        italic: Bool = false,
        strikethrough: Bool = false,
        underline: Bool = false,
        code: Bool = false,
        color: String = "default",
        link: String? = nil
    ) -> RichText {
        
        return RichText(
            text: TextContent(
                content: content,
                link: link.map { Link(url: $0) }
            ),
            annotations: TextAnnotations(
                bold: bold,
                italic: italic,
                strikethrough: strikethrough,
                underline: underline,
                code: code,
                color: color
            ),
            href: link
        )
    }
    
    // MARK: - Block Creation Methods
    func createHeadingBlock(level: Int, content: String) -> NotionBlock {
        let richText = createRichText(content: content)
        
        let contentValue: BlockContent
        
        switch level {
        case 1:
            contentValue = BlockContent(
                paragraph: nil,
                heading_1: RichTextContent(rich_text: [richText]),
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: EmptyContent(),
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            )
        case 2:
            contentValue = BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: RichTextContent(rich_text: [richText]),
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            )
        case 3:
            contentValue = BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: RichTextContent(rich_text: [richText]),
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            )
        default:
            contentValue = BlockContent(
                paragraph: RichTextContent(rich_text: [richText]),
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            )
        }
        
        return NotionBlock(
            id: UUID().uuidString,
            type: BlockType(rawValue: "heading_\(level)") ?? .paragraph,
            content: contentValue,
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createParagraphBlock(content: String) -> NotionBlock {
        return NotionBlock(
            id: UUID().uuidString,
            type: .paragraph,
            content: BlockContent(
                paragraph: RichTextContent(rich_text: [createRichText(content: content)]),
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createCodeBlock(content: String, language: String = "plain text") -> NotionBlock {
        return NotionBlock(
            id: UUID().uuidString,
            type: .code,
            content: BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: CodeContent(
                    rich_text: [createRichText(content: content)],
                    language: language,
                    caption: []
                ),
                quote: nil,
                divider: nil,
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createBulletedListItem(content: String) -> NotionBlock {
        return NotionBlock(
            id: UUID().uuidString,
            type: .bullet_list_item,
            content: BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: RichTextContent(rich_text: [createRichText(content: content)]),
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createNumberedListItem(content: String) -> NotionBlock {
        return NotionBlock(
            id: UUID().uuidString,
            type: .number_list_item,
            content: BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: RichTextContent(rich_text: [createRichText(content: content)]),
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createTodoItem(content: String, checked: Bool = false) -> NotionBlock {
        return NotionBlock(
            id: UUID().uuidString,
            type: .to_do,
            content: BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: TodoContent(
                    rich_text: [createRichText(content: content)],
                    checked: checked
                ),
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createQuoteBlock(content: String) -> NotionBlock {
        return NotionBlock(
            id: UUID().uuidString,
            type: .quote,
            content: BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: RichTextContent(rich_text: [createRichText(content: content)]),
                divider: nil,
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createDividerBlock() -> NotionBlock {
        return NotionBlock(
            id: UUID().uuidString,
            type: .divider,
            content: BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: EmptyContent(),
                image: nil,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createImageBlock(url: String, caption: String = "") -> NotionBlock {
        let imageContent = FileContent(
            type: "external",
            file: nil,
            external: ExternalFile(url: url),
            caption: caption.isEmpty ? [] : [createRichText(content: caption)]
        )
        
        return NotionBlock(
            id: UUID().uuidString,
            type: .image,
            content: BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: imageContent,
                file: nil,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createFileBlock(url: String, fileName: String, caption: String = "") -> NotionBlock {
        let fileContent = FileContent(
            type: "external",
            file: nil,
            external: ExternalFile(url: url),
            caption: caption.isEmpty ? [] : [createRichText(content: caption)]
        )
        
        return NotionBlock(
            id: UUID().uuidString,
            type: .file,
            content: BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: nil,
                file: fileContent,
                bookmark: nil,
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createCalloutBlock(content: String, icon: String = "💡", color: String = "yellow") -> NotionBlock {
        let iconContent = IconContent(emoji: icon, external: nil, file: nil)
        
        return NotionBlock(
            id: UUID().uuidString,
            type: .callout,
            content: BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: nil,
                file: nil,
                bookmark: nil,
                callout: CalloutContent(
                    rich_text: [createRichText(content: content)],
                    icon: iconContent,
                    color: color
                ),
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    func createBookmarkBlock(url: String, title: String = "", description: String = "") -> NotionBlock {
        let richTexts = []
        
        return NotionBlock(
            id: UUID().uuidString,
            type: .bookmark,
            content: BlockContent(
                paragraph: nil,
                heading_1: nil,
                heading_2: nil,
                heading_3: nil,
                bulleted_list_item: nil,
                numbered_list_item: nil,
                to_do: nil,
                toggle: nil,
                code: nil,
                quote: nil,
                divider: nil,
                image: nil,
                file: nil,
                bookmark: BookmarkContent(
                    url: url,
                    caption: []
                ),
                callout: nil,
                column_list: nil,
                child_database: nil,
                child_page: nil
            ),
            created_time: "",
            last_edited_time: ""
        )
    }
    
    // MARK: - Complex Content Creation
    func createTableFromData(_ data: [[String]], headers: [String]? = nil) -> [NotionBlock] {
        var blocks: [NotionBlock] = []
        
        // Add table headers
        if let headers = headers {
            blocks.append(createHeadingBlock(level: 3, content: "Tabelle: \(headers.joined(separator: " | "))"))
        }
        
        // Add data rows
        for (index, row) in data.enumerated() {
            if index == 0 && headers == nil {
                // First row becomes header if no headers provided
                blocks.append(createHeadingBlock(level: 4, content: row.joined(separator: " | ")))
            } else {
                blocks.append(createParagraphBlock(content: row.joined(separator: " | ")))
            }
        }
        
        return blocks
    }
    
    func createCodeBlockWithLanguage(content: String, language: String, title: String = "") -> [NotionBlock] {
        var blocks: [NotionBlock] = []
        
        if !title.isEmpty {
            blocks.append(createHeadingBlock(level: 3, content: title))
        }
        
        blocks.append(createCodeBlock(content: content, language: language))
        
        return blocks
    }
    
    func createMarkdownFormattedText(_ markdown: String) -> [NotionBlock] {
        let lines = markdown.components(separatedBy: .newlines)
        var blocks: [NotionBlock] = []
        
        for line in lines {
            if line.isEmpty {
                continue
            }
            
            if line.hasPrefix("# ") {
                blocks.append(createHeadingBlock(level: 1, content: String(line.dropFirst(2))))
            } else if line.hasPrefix("## ") {
                blocks.append(createHeadingBlock(level: 2, content: String(line.dropFirst(3))))
            } else if line.hasPrefix("### ") {
                blocks.append(createHeadingBlock(level: 3, content: String(line.dropFirst(4))))
            } else if line.hasPrefix("- ") {
                blocks.append(createBulletedListItem(content: String(line.dropFirst(2))))
            } else if line.hasPrefix("> ") {
                blocks.append(createQuoteBlock(content: String(line.dropFirst(2))))
            } else if line.hasPrefix("```") {
                // Start of code block - would need more sophisticated parsing
                blocks.append(createCodeBlock(content: "Code Block", language: "plain text"))
            } else {
                blocks.append(createParagraphBlock(content: line))
            }
        }
        
        return blocks
    }
    
    func createMeetingAgenda(_ agendaItems: [String], title: String = "Agenda") -> [NotionBlock] {
        var blocks: [NotionBlock] = []
        
        blocks.append(createHeadingBlock(level: 1, content: title))
        
        for (index, item) in agendaItems.enumerated() {
            blocks.append(createNumberedListItem(content: item))
        }
        
        return blocks
    }
    
    func createTaskList(_ tasks: [(text: String, completed: Bool)]) -> [NotionBlock] {
        var blocks: [NotionBlock] = []
        
        blocks.append(createHeadingBlock(level: 2, content: "Aufgabenliste"))
        
        for task in tasks {
            blocks.append(createTodoItem(content: task.text, checked: task.completed))
        }
        
        return blocks
    }
    
    func createChecklistWithProgress(_ items: [String]) -> [NotionBlock] {
        var blocks: [NotionBlock] = []
        
        blocks.append(createHeadingBlock(level: 2, content: "Checkliste"))
        
        for item in items {
            blocks.append(createTodoItem(content: item, checked: false))
        }
        
        return blocks
    }
    
    func createImageGallery(_ images: [(url: String, caption: String)]) -> [NotionBlock] {
        var blocks: [NotionBlock] = []
        
        blocks.append(createHeadingBlock(level: 2, content: "Bildergalerie"))
        blocks.append(createDividerBlock())
        
        for image in images {
            blocks.append(createImageBlock(url: image.url, caption: image.caption))
            blocks.append(createDividerBlock())
        }
        
        return blocks
    }
}

// MARK: - File Upload Manager
class NotionFileManager {
    
    // MARK: - Image Handling
    func compressImage(_ image: UIImage, maxWidth: CGFloat = 1200, quality: CGFloat = 0.8) -> Data? {
        let aspectRatio = image.size.height / image.size.width
        let newSize = CGSize(width: maxWidth, height: maxWidth * aspectRatio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        
        let compressedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return compressedImage?.jpegData(compressionQuality: quality)
    }
    
    func uploadImageToExternalService(_ imageData: Data, service: String = "cloudinary") async throws -> String {
        // This would integrate with services like Cloudinary, AWS S3, etc.
        // For now, return a placeholder URL
        return "https://example.com/uploads/\(UUID().uuidString).jpg"
    }
    
    // MARK: - File Validation
    func validateImageFile(_ url: URL) -> Bool {
        let supportedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"]
        return supportedTypes.contains(url.pathExtension.lowercased())
    }
    
    func validateFileSize(_ data: Data, maxSizeInMB: Int = 10) -> Bool {
        let maxSize = maxSizeInMB * 1024 * 1024 // Convert to bytes
        return data.count <= maxSize
    }
}

// MARK: - Database Query Builder
class NotionDatabaseQueryBuilder {
    private var filters: [FilterObject] = []
    private var sorts: [SortObject] = []
    
    func where(_ property: String, _ condition: FilterCondition, _ value: Any) -> Self {
        let filter = FilterObject(
            and: nil,
            or: nil,
            property: property,
            type: propertyTypeForValue(value),
            condition: condition.rawValue,
            value: AnyCodable(value)
        )
        
        filters.append(filter)
        return self
    }
    
    func orderBy(_ property: String, ascending: Bool = true) -> Self {
        let sort = SortObject(
            timestamp: nil,
            direction: ascending ? "ascending" : "descending",
            property: property
        )
        
        sorts.append(sort)
        return self
    }
    
    func limit(_ count: Int) -> Self {
        // This would be applied in the query request
        return self
    }
    
    func build() -> (filter: FilterObject?, sorts: [SortObject]?) {
        let finalFilter = filters.count == 1 ? filters.first : 
                          filters.count > 1 ? FilterObject(and: filters, or: nil, property: nil, type: nil, condition: nil, value: nil) : nil
        
        return (finalFilter, sorts.isEmpty ? nil : sorts)
    }
    
    private func propertyTypeForValue(_ value: Any) -> String {
        switch value {
        case is String:
            return "rich_text"
        case is Int, is Double:
            return "number"
        case is Bool:
            return "checkbox"
        default:
            return "rich_text"
        }
    }
}

// MARK: - Filter Conditions
enum FilterCondition: String {
    case equals = "equals"
    case doesNotEqual = "does_not_equal"
    case contains = "contains"
    case doesNotContain = "does_not_contain"
    case startsWith = "starts_with"
    case endsWith = "ends_with"
    case isEmpty = "is_empty"
    case isNotEmpty = "is_not_empty"
    case greaterThan = "greater_than"
    case lessThan = "less_than"
    case onOrAfter = "on_or_after"
    case onOrBefore = "on_or_before"
}

// MARK: - Utility Extensions
extension String {
    var notionColor: String {
        switch self.lowercased() {
        case "red": return "red"
        case "green": return "green"
        case "blue": return "blue"
        case "yellow": return "yellow"
        case "purple": return "purple"
        case "pink": return "pink"
        case "orange": return "orange"
        case "brown": return "brown"
        default: return "default"
        }
    }
}