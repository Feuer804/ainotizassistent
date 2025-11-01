//
//  NotionTemplates.swift
//  AINotizassistent
//
//  Notion Templates für verschiedene Note-Types
//

import Foundation

// MARK: - Template Protocol
protocol NotionTemplate {
    var name: String { get }
    var description: String { get }
    func createProperties() -> [String: NotionProperty]
    func createBlocks() -> [NotionBlock]
}

// MARK: - Meeting Notes Template
struct MeetingNotesTemplate: NotionTemplate {
    let name = "Meeting Notes"
    let description = "Template für Meeting-Protokolle"
    
    func createProperties() -> [String: NotionProperty] {
        return [
            "Title": NotionProperty(
                id: "title",
                type: .title,
                title: EmptyContent(),
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: nil,
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Date": NotionProperty(
                id: "date",
                type: .date,
                title: nil,
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: EmptyContent(),
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Attendees": NotionProperty(
                id: "attendees",
                type: .people,
                title: nil,
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: nil,
                people: EmptyContent(),
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Status": NotionProperty(
                id: "status",
                type: .status,
                title: nil,
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: nil,
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: StatusProperty(
                    options: [
                        StatusOption(id: "upcoming", name: "Anstehend", color: "blue"),
                        StatusOption(id: "completed", name: "Abgeschlossen", color: "green"),
                        StatusOption(id: "cancelled", name: "Abgesagt", color: "red")
                    ],
                    groups: []
                ),
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Priority": NotionProperty(
                id: "priority",
                type: .select,
                title: nil,
                rich_text: nil,
                number: nil,
                select: SelectProperty(
                    options: [
                        SelectOption(id: "high", name: "Hoch", color: "red"),
                        SelectOption(id: "medium", name: "Mittel", color: "yellow"),
                        SelectOption(id: "low", name: "Niedrig", color: "green")
                    ]
                ),
                multi_select: nil,
                date: nil,
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            )
        ]
    }
    
    func createBlocks() -> [NotionBlock] {
        return [
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_1,
                content: BlockContent(paragraph: nil, heading_1: RichTextContent(rich_text: [RichText(text: TextContent(content: "Meeting", link: nil), annotations: TextAnnotations(bold: true, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), heading_2: nil, heading_3: nil, bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: EmptyContent(), image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: RichTextContent(rich_text: [RichText(text: TextContent(content: "Datum", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), heading_3: nil, bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: nil, heading_3: RichTextContent(rich_text: [RichText(text: TextContent(content: "Teilnehmer", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: nil, heading_3: RichTextContent(rich_text: [RichText(text: TextContent(content: "Agenda", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: nil, heading_3: RichTextContent(rich_text: [RichText(text: TextContent(content: "Besprechungspunkte", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: nil, heading_3: RichTextContent(rich_text: [RichText(text: TextContent(content: "Entscheidungen", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: nil, heading_3: RichTextContent(rich_text: [RichText(text: TextContent(content: "Nächste Schritte", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            )
        ]
    }
}

// MARK: - Task Management Template
struct TaskManagementTemplate: NotionTemplate {
    let name = "Task Management"
    let description = "Template für Aufgabenverwaltung"
    
    func createProperties() -> [String: NotionProperty] {
        return [
            "Task Name": NotionProperty(
                id: "title",
                type: .title,
                title: EmptyContent(),
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: nil,
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Status": NotionProperty(
                id: "status",
                type: .status,
                title: nil,
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: nil,
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: StatusProperty(
                    options: [
                        StatusOption(id: "todo", name: "Zu erledigen", color: "default"),
                        StatusOption(id: "in_progress", name: "In Bearbeitung", color: "blue"),
                        StatusOption(id: "review", name: "Überprüfung", color: "yellow"),
                        StatusOption(id: "done", name: "Abgeschlossen", color: "green")
                    ],
                    groups: []
                ),
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Priority": NotionProperty(
                id: "priority",
                type: .select,
                title: nil,
                rich_text: nil,
                number: nil,
                select: SelectProperty(
                    options: [
                        SelectOption(id: "urgent", name: "Dringend", color: "red"),
                        SelectOption(id: "high", name: "Hoch", color: "orange"),
                        SelectOption(id: "medium", name: "Mittel", color: "yellow"),
                        SelectOption(id: "low", name: "Niedrig", color: "green")
                    ]
                ),
                multi_select: nil,
                date: nil,
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Due Date": NotionProperty(
                id: "due_date",
                type: .date,
                title: nil,
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: EmptyContent(),
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Assigned": NotionProperty(
                id: "assigned",
                type: .people,
                title: nil,
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: nil,
                people: EmptyContent(),
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Tags": NotionProperty(
                id: "tags",
                type: .multi_select,
                title: nil,
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: MultiSelectProperty(
                    options: [
                        SelectOption(id: "bug", name: "Bug", color: "red"),
                        SelectOption(id: "feature", name: "Feature", color: "blue"),
                        SelectOption(id: "improvement", name: "Verbesserung", color: "green"),
                        SelectOption(id: "documentation", name: "Dokumentation", color: "purple")
                    ]
                ),
                date: nil,
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            )
        ]
    }
    
    func createBlocks() -> [NotionBlock] {
        return [
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_1,
                content: BlockContent(paragraph: nil, heading_1: RichTextContent(rich_text: [RichText(text: TextContent(content: "Task Details", link: nil), annotations: TextAnnotations(bold: true, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), heading_2: nil, heading_3: nil, bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: EmptyContent(), image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: RichTextContent(rich_text: [RichText(text: TextContent(content: "Beschreibung", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), heading_3: nil, bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: nil, heading_3: RichTextContent(rich_text: [RichText(text: TextContent(content: "Anforderungen", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: nil, heading_3: RichTextContent(rich_text: [RichText(text: TextContent(content: "Lösungsschritte", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: nil, heading_3: RichTextContent(rich_text: [RichText(text: TextContent(content: "Notizen", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            )
        ]
    }
}

// MARK: - Project Notes Template
struct ProjectNotesTemplate: NotionTemplate {
    let name = "Project Notes"
    let description = "Template für Projekt-Dokumentation"
    
    func createProperties() -> [String: NotionProperty] {
        return [
            "Project Name": NotionProperty(
                id: "title",
                type: .title,
                title: EmptyContent(),
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: nil,
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Start Date": NotionProperty(
                id: "start_date",
                type: .date,
                title: nil,
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: EmptyContent(),
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "End Date": NotionProperty(
                id: "end_date",
                type: .date,
                title: nil,
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: EmptyContent(),
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Status": NotionProperty(
                id: "status",
                type: .select,
                title: nil,
                rich_text: nil,
                number: nil,
                select: SelectProperty(
                    options: [
                        SelectOption(id: "planning", name: "Planung", color: "blue"),
                        SelectOption(id: "active", name: "Aktiv", color: "green"),
                        SelectOption(id: "on_hold", name: "Pausiert", color: "yellow"),
                        SelectOption(id: "completed", name: "Abgeschlossen", color: "gray")
                    ]
                ),
                multi_select: nil,
                date: nil,
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Team": NotionProperty(
                id: "team",
                type: .people,
                title: nil,
                rich_text: nil,
                number: nil,
                select: nil,
                multi_select: nil,
                date: nil,
                people: EmptyContent(),
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            ),
            "Budget": NotionProperty(
                id: "budget",
                type: .number,
                title: nil,
                rich_text: nil,
                number: EmptyContent(),
                select: nil,
                multi_select: nil,
                date: nil,
                people: nil,
                files: nil,
                checkbox: nil,
                url: nil,
                email: nil,
                phone_number: nil,
                created_time: nil,
                created_by: nil,
                last_edited_time: nil,
                last_edited_by: nil,
                formula: nil,
                relation: nil,
                rollup: nil,
                status: nil,
                button: nil,
                unique_id: nil,
                verification: nil
            )
        ]
    }
    
    func createBlocks() -> [NotionBlock] {
        return [
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_1,
                content: BlockContent(paragraph: nil, heading_1: RichTextContent(rich_text: [RichText(text: TextContent(content: "Projektübersicht", link: nil), annotations: TextAnnotations(bold: true, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), heading_2: nil, heading_3: nil, bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: EmptyContent(), image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: RichTextContent(rich_text: [RichText(text: TextContent(content: "Projektziele", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), heading_3: nil, bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: RichTextContent(rich_text: [RichText(text: TextContent(content: "Projektstruktur", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), heading_3: nil, bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: RichTextContent(rich_text: [RichText(text: TextContent(content: "Meilensteine", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), heading_3: nil, bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            ),
            NotionBlock(
                id: UUID().uuidString,
                type: .heading_2,
                content: BlockContent(paragraph: nil, heading_1: nil, heading_2: RichTextContent(rich_text: [RichText(text: TextContent(content: "Risiken und Abhängigkeiten", link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)]), heading_3: nil, bulleted_list_item: nil, numbered_list_item: nil, to_do: nil, toggle: nil, code: nil, quote: nil, divider: nil, image: nil, file: nil, bookmark: nil, callout: nil, column_list: nil, child_database: nil, child_page: nil),
                created_time: "",
                last_edited_time: ""
            )
        ]
    }
}

// MARK: - Template Manager
class NotionTemplateManager {
    static let shared = NotionTemplateManager()
    
    private var templates: [String: NotionTemplate] = [
        "MeetingNotes": MeetingNotesTemplate(),
        "TaskManagement": TaskManagementTemplate(),
        "ProjectNotes": ProjectNotesTemplate()
    ]
    
    private init() {}
    
    func getTemplate(named name: String) -> NotionTemplate? {
        return templates[name]
    }
    
    func getAllTemplates() -> [NotionTemplate] {
        return Array(templates.values)
    }
    
    func registerTemplate(_ template: NotionTemplate, for key: String) {
        templates[key] = template
    }
    
    func createPageFromTemplate(databaseId: String, templateName: String, title: String, additionalProperties: [String: NotionPropertyValue] = [:]) async throws -> NotionPage {
        guard let template = getTemplate(named: templateName) else {
            throw NotionError(code: "TEMPLATE_NOT_FOUND", message: "Template '\(templateName)' nicht gefunden")
        }
        
        let integration = NotionIntegration()
        
        // Basis-Properties mit Title
        var properties = template.createProperties()
        var propertyValues: [String: NotionPropertyValue] = [:]
        
        // Title Property
        propertyValues["Title"] = NotionPropertyValue(
            id: "title",
            type: .title,
            title: [RichText(text: TextContent(content: title, link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)],
            rich_text: nil,
            number: nil,
            select: nil,
            multi_select: nil,
            date: nil,
            people: nil,
            files: nil,
            checkbox: nil,
            url: nil,
            email: nil,
            phone_number: nil,
            created_time: nil,
            created_by: nil,
            last_edited_time: nil,
            last_edited_by: nil,
            formula: nil,
            relation: nil,
            rollup: nil,
            status: nil,
            button: nil,
            unique_id: nil,
            verification: nil
        )
        
        // Additional properties hinzufügen
        for (key, value) in additionalProperties {
            propertyValues[key] = value
        }
        
        let blocks = template.createBlocks()
        
        return try await integration.createPage(
            databaseId: databaseId,
            properties: propertyValues,
            blocks: blocks
        )
    }
}