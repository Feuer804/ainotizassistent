//
//  TestDataFactory.swift
//  AINotizassistent - Realistische Testdaten
//
//  Factory-Klasse für realistische Testdaten zur Simulation
//  verschiedener Anwendungsfälle und Szenarien
//

import Foundation
import SwiftUI
import CoreGraphics

// MARK: - Test Data Types
enum TestDataCategory {
    case email
    case meeting
    case article
    case code
    case notes
    case todo
    case project
    case documentation
    
    var displayName: String {
        switch self {
        case .email: return "E-Mail"
        case .meeting: return "Meeting"
        case .article: return "Artikel"
        case .code: return "Code"
        case .notes: return "Notizen"
        case .todo: return "Aufgaben"
        case .project: return "Projekt"
        case .documentation: return "Dokumentation"
        }
    }
}

enum TestDataLanguage: String, CaseIterable {
    case german = "de"
    case english = "en"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    
    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "Englisch"
        case .french: return "Französisch"
        case .spanish: return "Spanisch"
        case .italian: return "Italienisch"
        }
    }
}

enum ContentComplexity {
    case simple
    case medium
    case complex
    
    var description: String {
        switch self {
        case .simple: return "Einfach"
        case .medium: return "Mittel"
        case .complex: return "Komplex"
        }
    }
}

// MARK: - Test Data Models
struct TestEmailData {
    let from: String
    let to: [String]
    let subject: String
    let content: String
    let isHtml: Bool
    let attachments: [String]
    let priority: EmailPriority
    let timestamp: Date
    
    enum EmailPriority {
        case low, normal, high, urgent
    }
}

struct TestMeetingData {
    let title: String
    let participants: [String]
    let agenda: [String]
    let startTime: Date
    let duration: TimeInterval
    let location: String?
    let meetingType: MeetingType
    let notes: String
    let actionItems: [String]
    
    enum MeetingType {
        case standup, planning, review, brainstorming, decision, followup
    }
}

struct TestCodeData {
    let language: String
    let content: String
    let filename: String
    let description: String
    let complexity: ContentComplexity
    let lineCount: Int
    let hasComments: Bool
    let hasDocumentation: Bool
}

struct TestArticleData {
    let title: String
    let author: String
    let content: String
    let category: String
    let tags: [String]
    let wordCount: Int
    let hasImages: Bool
    let language: TestDataLanguage
    let publicationDate: Date
}

struct TestProjectData {
    let name: String
    let description: String
    let status: ProjectStatus
    let tasks: [TestTaskData]
    let team: [String]
    let startDate: Date
    let deadline: Date?
    let priority: ProjectPriority
    
    enum ProjectStatus {
        case planning, active, onHold, completed, cancelled
    }
    
    enum ProjectPriority {
        case low, medium, high, critical
    }
}

struct TestTaskData {
    let id: String
    let title: String
    let description: String
    let assignee: String
    let status: TaskStatus
    let priority: TaskPriority
    let dueDate: Date?
    let estimatedHours: Double
    let tags: [String]
    
    enum TaskStatus {
        case todo, inProgress, review, completed, blocked
    }
    
    enum TaskPriority {
        case low, medium, high, urgent
    }
}

// MARK: - Main Test Data Factory
class TestDataFactory {
    
    // MARK: - Random Data Generators
    private let germanNames = [
        "Max Müller", "Anna Schmidt", "Thomas Weber", "Maria Fischer",
        "Michael Klein", "Sarah Bauer", "David Wagner", "Lisa Schneider",
        "Jan Hoffmann", "Nina Peters", "Marco Wolf", "Julia Berg"
    ]
    
    private let englishNames = [
        "John Smith", "Emma Johnson", "Michael Brown", "Sarah Davis",
        "David Miller", "Lisa Wilson", "James Taylor", "Olivia Anderson",
        "Robert Thomas", "Jennifer Jackson", "William White", "Jessica Harris"
    ]
    
    private let germanCompanies = [
        "TechCorp GmbH", "Digital Solutions AG", "Innovation Labs",
        "Smart Systems", "FutureTech", "DataDriven GmbH", "CloudFirst AG"
    ]
    
    private let englishCompanies = [
        "TechCorp Inc", "Digital Solutions Ltd", "Innovation Labs",
        "Smart Systems", "FutureTech", "DataDriven Corp", "CloudFirst Inc"
    ]
    
    private let germanProjects = [
        "MobilApp Entwicklung", "Website Redesign", "Datenbank Migration",
        "API Integration", "User Experience Verbesserung", "Performance Optimierung",
        "Sicherheitsaudit", "Automatisierung", "Testing Framework"
    ]
    
    private let englishProjects = [
        "Mobile App Development", "Website Redesign", "Database Migration",
        "API Integration", "UX Enhancement", "Performance Optimization",
        "Security Audit", "Automation", "Testing Framework"
    ]
    
    private let topics = [
        "KI Integration", "Machine Learning", "Data Analysis",
        "User Interface Design", "API Development", "Database Design",
        "Cloud Architecture", "DevOps", "Testing Strategy"
    ]
    
    private let languages = ["Swift", "Python", "JavaScript", "Java", "C++", "TypeScript", "Go"]
    private let frameworks = ["SwiftUI", "React", "Vue.js", "Angular", "Node.js", "Spring Boot", ".NET"]
    
    // MARK: - Main Factory Methods
    
    func generateRandomNote() -> NoteModel {
        let categories: [TestDataCategory] = [.email, .meeting, .article, .code, .notes, .todo, .project, .documentation]
        let category = categories.randomElement()!
        
        switch category {
        case .email:
            return generateEmailNote()
        case .meeting:
            return generateMeetingNote()
        case .article:
            return generateArticleNote()
        case .code:
            return generateCodeNote()
        case .notes:
            return generateNotesNote()
        case .todo:
            return generateTodoNote()
        case .project:
            return generateProjectNote()
        case .documentation:
            return generateDocumentationNote()
        }
    }
    
    func generateTestAPIKey() -> APIKey {
        let providers: [APIProvider] = [.openai, .openrouter, .notion, .whisper]
        let provider = providers.randomElement()!
        
        let keyString: String
        switch provider {
        case .openai:
            keyString = "sk-\(String.randomHexString(length: 51))"
        case .openrouter:
            keyString = "ork-\(String.randomHexString(length: 51))"
        case .notion:
            keyString = "secret_\(String.randomHexString(length: 32))"
        case .whisper:
            keyString = "whisper_\(String.randomHexString(length: 32))"
        }
        
        return APIKey(
            provider: provider,
            keyValue: keyString,
            status: .valid,
            createdAt: Date().addingTimeInterval(-TimeInterval.random(in: 0...(30 * 24 * 60 * 60)))
        )
    }
    
    func generateTestShortcuts() -> [AppShortcut] {
        let keyCombos = [
            KeyCombo(key: kVK_ANSI_N, modifiers: cmdKey | shiftKey),
            KeyCombo(key: kVK_ANSI_Q, modifiers: cmdKey | shiftKey),
            KeyCombo(key: kVK_Space, modifiers: cmdKey),
            KeyCombo(key: kVK_ANSI_T, modifiers: cmdKey),
            KeyCombo(key: kVK_ANSI_P, modifiers: cmdKey | shiftKey)
        ]
        
        let names = ["Neue Notiz", "App beenden", "Quick Capture", "Neuer Tab", "Print"]
        let descriptions = [
            "Erstellt eine neue Notiz",
            "Beendet die App",
            "Schneller Notiz-Modus",
            "Öffnet neuen Tab",
            "Druckt aktuelle Notiz"
        ]
        
        var shortcuts: [AppShortcut] = []
        
        for i in 0..<min(keyCombos.count, names.count) {
            let shortcut = AppShortcut(
                id: "test_shortcut_\(i)",
                name: names[i],
                description: descriptions[i],
                keyCombo: keyCombos[i],
                category: .primary
            )
            shortcuts.append(shortcut)
        }
        
        return shortcuts
    }
    
    func generateBulkNotes(count: Int) -> [NoteModel] {
        var notes: [NoteModel] = []
        
        for _ in 0..<count {
            notes.append(generateRandomNote())
        }
        
        return notes
    }
    
    func generateNotesWithSpecificContent(_ content: String) -> NoteModel {
        let languages: [TestDataLanguage] = [.german, .english]
        let language = languages.randomElement()!
        
        return NoteModel(
            id: UUID(),
            content: content,
            title: generateTitle(for: content, language: language),
            type: .note,
            sourceApp: "Test App",
            createdAt: Date(),
            updatedAt: Date(),
            tags: generateRandomTags(),
            metadata: [:]
        )
    }
    
    // MARK: - Specific Content Generators
    
    private func generateEmailNote() -> NoteModel {
        let emailData = generateRandomEmail()
        
        let content = """
        Von: \(emailData.from)
        An: \(emailData.to.joined(separator: ", "))
        Betreff: \(emailData.subject)
        
        \(emailData.content)
        """
        
        return NoteModel(
            id: UUID(),
            content: content,
            title: emailData.subject,
            type: .email,
            sourceApp: "Mail",
            createdAt: emailData.timestamp,
            updatedAt: emailData.timestamp,
            tags: ["email", "business"],
            metadata: ["from": emailData.from, "to": emailData.to.joined(separator: ",")]
        )
    }
    
    private func generateMeetingNote() -> NoteModel {
        let meetingData = generateRandomMeeting()
        
        let content = """
        \(meetingData.title)
        
        Teilnehmer: \(meetingData.participants.joined(separator: ", "))
        
        Agenda:
        \(meetingData.agenda.map { "• \($0)" }.joined(separator: "\n"))
        
        Notizen:
        \(meetingData.notes)
        
        Action Items:
        \(meetingData.actionItems.map { "• \($0)" }.joined(separator: "\n"))
        """
        
        return NoteModel(
            id: UUID(),
            content: content,
            title: meetingData.title,
            type: .meeting,
            sourceApp: "Calendar",
            createdAt: meetingData.startTime,
            updatedAt: meetingData.startTime,
            tags: ["meeting", "team"],
            metadata: [
                "participants": meetingData.participants.joined(separator: ","),
                "agenda": meetingData.agenda.joined(separator: ","),
                "duration": meetingData.duration as Double
            ]
        )
    }
    
    private func generateArticleNote() -> NoteModel {
        let articleData = generateRandomArticle()
        
        let content = """
        # \(articleData.title)
        
        Autor: \(articleData.author)
        Kategorie: \(articleData.category)
        Tags: \(articleData.tags.joined(separator: ", "))
        
        \(articleData.content)
        """
        
        return NoteModel(
            id: UUID(),
            content: content,
            title: articleData.title,
            type: .article,
            sourceApp: "Safari",
            createdAt: articleData.publicationDate,
            updatedAt: articleData.publicationDate,
            tags: ["article"] + articleData.tags,
            metadata: [
                "author": articleData.author,
                "category": articleData.category,
                "wordCount": articleData.wordCount as Int
            ]
        )
    }
    
    private func generateCodeNote() -> NoteModel {
        let codeData = generateRandomCode()
        
        let content = """
        // \(codeData.description)
        // Datei: \(codeData.filename)
        // Sprache: \(codeData.language)
        
        \(codeData.content)
        """
        
        return NoteModel(
            id: UUID(),
            content: content,
            title: codeData.filename,
            type: .code,
            sourceApp: "Xcode",
            createdAt: Date(),
            updatedAt: Date(),
            tags: ["code", codeData.language.lowercased()],
            metadata: [
                "language": codeData.language,
                "filename": codeData.filename,
                "lineCount": codeData.lineCount as Int,
                "complexity": codeData.complexity.description
            ]
        )
    }
    
    private func generateNotesNote() -> NoteModel {
        let topics = ["Projektplanung", "Ideensammlung", "Research Notes", "Meeting Follow-up", "Feature Ideas"]
        let topic = topics.randomElement()!
        
        let sampleTexts = [
            """
            Wichtige Erkenntnisse:
            • Die User Experience muss verbessert werden
            • Performance ist ein kritischer Faktor
            • Sicherheitsaspekte sind zu berücksichtigen
            
            Nächste Schritte:
            1. UX Research durchführen
            2. Performance Tests implementieren
            3. Security Audit planen
            """,
            
            """
            Brainstorming Session - \(topic):
            
            🎯 Hauptziele:
            - Benutzerfreundlichkeit erhöhen
            - Systemstabilität verbessern
            - Performance optimieren
            
            💡 Ideen:
            - Mobile-first Design
            - Progressive Web App
            - Offline-Funktionalität
            - Echtzeit-Updates
            """,
            
            """
            \(topic) - Wichtige Notizen:
            
            📋 Was funktioniert gut:
            - Intuitive Navigation
            - Schnelle Ladezeiten
            - Responsive Design
            
            ⚠️ Verbesserungsbereiche:
            - Fehlerbehandlung
            - Accessibility
            - Dokumentation
            """
        ]
        
        let content = sampleTexts.randomElement()!
        
        return NoteModel(
            id: UUID(),
            content: content,
            title: topic,
            type: .note,
            sourceApp: "Notes",
            createdAt: Date(),
            updatedAt: Date(),
            tags: ["notes", topic.lowercased().replacingOccurrences(of: " ", with: "-")],
            metadata: [:]
        )
    }
    
    private func generateTodoNote() -> NoteModel {
        let taskData = generateRandomTask()
        
        let content = """
        📝 Aufgabenliste
        
        \(taskData.title)
        \(taskData.description)
        
        👤 Zuständig: \(taskData.assignee)
        ⭐ Priorität: \(taskData.priority.displayName)
        📅 Fällig: \(taskData.dueDate?.formatted(.dateTime.day().month().year()) ?? "Nicht gesetzt")
        ⏱️ Geschätzte Zeit: \(taskData.estimatedHours) Stunden
        
        # \(taskData.tags.joined(separator: " #"))
        """
        
        return NoteModel(
            id: UUID(),
            content: content,
            title: taskData.title,
            type: .todo,
            sourceApp: "Reminders",
            createdAt: Date(),
            updatedAt: Date(),
            tags: taskData.tags,
            metadata: [
                "assignee": taskData.assignee,
                "priority": taskData.priority.displayName,
                "status": taskData.status.displayName
            ]
        )
    }
    
    private func generateProjectNote() -> NoteModel {
        let projectData = generateRandomProject()
        
        let content = """
        # \(projectData.name)
        
        \(projectData.description)
        
        📊 Status: \(projectData.status.displayName)
        🎯 Priorität: \(projectData.priority.displayName)
        📅 Start: \(projectData.startDate.formatted(.dateTime.day().month().year()))
        
        👥 Team:
        \(projectData.team.map { "• \($0)" }.joined(separator: "\n"))
        
        ✅ Aufgaben:
        \(projectData.tasks.map { "• [\($0.status.displayName.first?.uppercased() ?? "")] \($0.title)" }.joined(separator: "\n"))
        
        📅 Deadline: \(projectData.deadline?.formatted(.dateTime.day().month().year()) ?? "Nicht gesetzt")
        """
        
        return NoteModel(
            id: UUID(),
            content: content,
            title: projectData.name,
            type: .project,
            sourceApp: "Projects",
            createdAt: projectData.startDate,
            updatedAt: Date(),
            tags: ["project", "planning"],
            metadata: [
                "status": projectData.status.displayName,
                "priority": projectData.priority.displayName,
                "teamSize": projectData.team.count as Int,
                "taskCount": projectData.tasks.count as Int
            ]
        )
    }
    
    private func generateDocumentationNote() -> NoteModel {
        let docTopics = [
            ("API Documentation", "Vollständige API-Dokumentation mit Endpoints, Parametern und Beispielen."),
            ("User Guide", "Benutzerhandbuch mit Schritt-für-Schritt-Anleitungen."),
            ("Developer Setup", "Entwicklungsumgebung Setup und Konfiguration."),
            ("Deployment Guide", "Anleitung für Deployment auf verschiedenen Plattformen."),
            ("Troubleshooting", "Häufige Probleme und deren Lösungen.")
        ]
        
        let (title, description) = docTopics.randomElement()!
        
        let content = """
        # \(title)
        
        \(description)
        
        ## Übersicht
        Diese Dokumentation beschreibt \(title.lowercased()) für das AINotizassistent-Projekt.
        
        ## Inhaltsverzeichnis
        1. Einführung
        2. Installation
        3. Konfiguration
        4. Verwendung
        5. Best Practices
        6. Troubleshooting
        7. FAQ
        
        ## Schnellstart
        Folgen Sie diesen Schritten für einen schnellen Einstieg:
        1. Installieren Sie die App
        2. Konfigurieren Sie die Grundeinstellungen
        3. Testen Sie die Kernfunktionen
        4. Lesen Sie die erweiterte Dokumentation
        
        ## Weiterführende Informationen
        - GitHub Repository
        - Support Forum
        - Video Tutorials
        """
        
        return NoteModel(
            id: UUID(),
            content: content,
            title: title,
            type: .documentation,
            sourceApp: "Notes",
            createdAt: Date(),
            updatedAt: Date(),
            tags: ["documentation", "guide"],
            metadata: [:]
        )
    }
    
    // MARK: - Data Generation Helpers
    
    private func generateRandomEmail() -> TestEmailData {
        let companies = germanCompanies
        let fromName = germanNames.randomElement()!
        let toNames = Array(repeating: 0, count: Int.random(in: 1...3)).map { _ in germanNames.randomElement()! }
        
        let subjects = [
            "Wichtige Ankündigung: Neue Features",
            "Projekt Update - Woche 42",
            "Meeting Einladung: Team Standup",
            "Feedback zu aktuellen Entwicklungen",
            "Urlaubsplanung für Q4",
            "Technische Spezifikationen überprüfen",
            "Budget Review Termin",
            "Kundengespräch - Nächste Woche"
        ]
        
        let contents = [
            """
            Hallo Team,
            
            ich möchte euch über die neuesten Entwicklungen informieren.
            
            Wichtige Punkte:
            • Feature X wurde erfolgreich implementiert
            • Testing zeigt vielversprechende Ergebnisse
            • Feedback von Beta-Usern ist sehr positiv
            
            Bitte um Feedback bis Freitag.
            
            Viele Grüße,
            \(fromName.components(separatedBy: " ").first!)
            """,
            
            """
            Hi everyone,
            
            hier ein kurzer Update zu unserem Projekt:
            
            ✅ Abgeschlossen:
            - Datenbank Migration
            - API Endpoints implementiert
            - Unit Tests erstellt
            
            🚧 In Arbeit:
            - Frontend Integration
            - Performance Tests
            
            📅 Nächste Woche:
            - Code Review
            - User Testing
            - Deployment Planung
            
            Vielen Dank für eure Unterstützung!
            """,
            
            """
            Sehr geehrte Damen und Herren,
            
            hiermit möchte ich Sie über den aktuellen Stand informieren.
            
            Kernpunkte:
            1. Zeitplan wird eingehalten
            2. Qualität der Implementierung ist hoch
            3. Risiken sind unter Kontrolle
            
            Bei Fragen stehe ich gerne zur Verfügung.
            
            Freundliche Grüße
            """
        ]
        
        return TestEmailData(
            from: fromName + " <" + companies.randomElement()!.lowercased().replacingOccurrences(of: " ", with: ".") + "@example.com>",
            to: toNames.map { $0 + " <" + companies.randomElement()!.lowercased().replacingOccurrences(of: " ", with: ".") + "@example.com>" },
            subject: subjects.randomElement()!,
            content: contents.randomElement()!,
            isHtml: Bool.random(),
            attachments: [],
            priority: [.low, .normal, .high, .urgent].randomElement()!,
            timestamp: Date().addingTimeInterval(-TimeInterval.random(in: 0...(7 * 24 * 60 * 60)))
        )
    }
    
    private func generateRandomMeeting() -> TestMeetingData {
        let participants = Array(Set(germanNames.shuffled().prefix(Int.random(in: 3...8))))
        
        let meetingTypes: [TestMeetingData.MeetingType] = [.standup, .planning, .review, .brainstorming, .decision, .followup]
        let meetingType = meetingTypes.randomElement()!
        
        let titles = [
            "Weekly Standup - \(Calendar.current.component(.weekOfYear, from: Date()))",
            "Projektplanung Q4",
            "Sprint Review & Retrospective",
            "Feature Planning Session",
            "Technical Decision Meeting",
            "User Feedback Review",
            "Architecture Discussion",
            "Testing Strategy Meeting"
        ]
        
        let agendas: [[String]] = [
            ["Status Updates", "Blockers", "Next Steps", "Q&A"],
            ["Requirements Review", "Timeline Planning", "Resource Allocation", "Risk Assessment"],
            ["Demo", "Feedback Collection", "Process Improvements", "Next Sprint Planning"],
            ["Feature Brainstorming", "Technical Feasibility", "Priority Setting", "Action Items"]
        ]
        
        let notes = [
            "Intensive Diskussion über Implementierungsdetails. Einige technische Herausforderungen identifiziert.",
            "Team zeigt hohe Motivation. Gute Zusammenarbeit bei der Problemlösung.",
            "Wichtige Entscheidungen getroffen. Roadmap für nächste Sprint definiert.",
            "Constructive feedback received. Several action items assigned to specific team members."
        ]
        
        let actionItems = [
            "• [John] Recherche zu Performance-Optimierung bis Freitag",
            "• [Anna] Wireframes für neue Features erstellen",
            "• [Mike] Technical spikes für kritische Features planen",
            "• [Lisa] Test-Automatisierung erweitern",
            "• [Team] Code Review bis Montag abschließen"
        ]
        
        return TestMeetingData(
            title: titles.randomElement()!,
            participants: participants,
            agenda: agendas.randomElement()!,
            startTime: Date().addingTimeInterval(TimeInterval.random(in: -604800...604800)),
            duration: TimeInterval.random(in: 1800...7200), // 30 min - 2 hours
            location: Bool.random() ? ["Konferenzraum A", "Meeting Room 2", "Online", "Office"].randomElement()! : nil,
            meetingType: meetingType,
            notes: notes.randomElement()!,
            actionItems: Array(actionItems.shuffled().prefix(Int.random(in: 3...6)))
        )
    }
    
    private func generateRandomArticle() -> TestArticleData {
        let languages: [TestDataLanguage] = [.german, .english]
        let language = languages.randomElement()!
        
        let titles: [String]
        let categories: [String]
        
        switch language {
        case .german:
            titles = [
                "Künstliche Intelligenz in der modernen Softwareentwicklung",
                "Best Practices für effiziente Teamarbeit",
                "Die Zukunft der mobilen Anwendungsentwicklung",
                "Cloud-native Anwendungen: Trends und Herausforderungen",
                "Microservices-Architektur: Ein umfassender Leitfaden"
            ]
            categories = ["Technologie", "Softwareentwicklung", "Business", "Innovation", "Trends"]
        case .english:
            titles = [
                "Artificial Intelligence in Modern Software Development",
                "Best Practices for Effective Team Collaboration",
                "The Future of Mobile Application Development",
                "Cloud-Native Applications: Trends and Challenges",
                "Microservices Architecture: A Comprehensive Guide"
            ]
            categories = ["Technology", "Software Development", "Business", "Innovation", "Trends"]
        }
        
        let tags: [[String]]
        switch language {
        case .german:
            tags = [
                ["KI", "Machine Learning", "Innovation"],
                ["Teamwork", "Methodik", "Produktivität"],
                ["Mobile", "Apps", "Entwicklung"],
                ["Cloud", "DevOps", "Skalierung"],
                ["Microservices", "Architektur", "Design"]
            ]
        case .english:
            tags = [
                ["AI", "Machine Learning", "Innovation"],
                ["Teamwork", "Methodology", "Productivity"],
                ["Mobile", "Apps", "Development"],
                ["Cloud", "DevOps", "Scaling"],
                ["Microservices", "Architecture", "Design"]
            ]
        }
        
        let authors = language == .german ? germanNames : englishNames
        
        let content = """
        Die moderne Softwareentwicklung steht vor zahlreichen Herausforderungen und Chancen. 
        Technologien entwickeln sich rasant weiter und neue Paradigmen entstehen.
        
        In diesem Artikel erfahren Sie:
        • Die wichtigsten Trends der aktuellen Entwicklung
        • Bewährte Methoden und Praktiken
        • Praktische Tipps für die Umsetzung
        • Ausblick auf zukünftige Entwicklungen
        
        Fazit: Die Zukunft der Softwareentwicklung ist vielversprechend und bietet 
        enorme Möglichkeiten für innovative Lösungen.
        """
        
        return TestArticleData(
            title: titles.randomElement()!,
            author: authors.randomElement()!,
            content: content,
            category: categories.randomElement()!,
            tags: tags.randomElement()!,
            wordCount: Int.random(in: 800...2000),
            hasImages: Bool.random(),
            language: language,
            publicationDate: Date().addingTimeInterval(-TimeInterval.random(in: 0...(90 * 24 * 60 * 60)))
        )
    }
    
    private func generateRandomCode() -> TestCodeData {
        let language = languages.randomElement()!
        let complexity: ContentComplexity = [.simple, .medium, .complex].randomElement()!
        
        let codeExamples: [String: String] = [
            "Swift": """
            import SwiftUI
            import Combine
            
            struct ContentView: View {
                @State private var inputText: String = ""
                @State private var analysisResult: String?
                @ObservedObject var contentAnalyzer = ContentAnalyzer()
                
                var body: some View {
                    VStack(spacing: 20) {
                        TextField("Text eingeben...", text: $inputText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Analysieren") {
                            analyzeContent()
                        }
                        .disabled(inputText.isEmpty)
                        
                        if let result = analysisResult {
                            Text(result)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                        }
                    }
                    .padding()
                }
                
                private func analyzeContent() {
                    contentAnalyzer.analyze(inputText) { result in
                        self.analysisResult = result
                    }
                }
            }
            """,
            
            "Python": """
            import asyncio
            import aiohttp
            from typing import List, Dict, Optional
            
            class ContentProcessor:
                def __init__(self, api_key: str):
                    self.api_key = api_key
                    self.session: Optional[aiohttp.ClientSession] = None
                
                async def __aenter__(self):
                    self.session = aiohttp.ClientSession()
                    return self
                
                async def __aexit__(self, exc_type, exc_val, exc_tb):
                    if self.session:
                        await self.session.close()
                
                async def process_content(self, text: str) -> Dict:
                    '''Process content with AI analysis'''
                    payload = {
                        'text': text,
                        'analysis_type': 'comprehensive'
                    }
                    
                    async with self.session.post(
                        'https://api.example.com/analyze',
                        json=payload,
                        headers={'Authorization': f'Bearer {self.api_key}'}
                    ) as response:
                        return await response.json()
            
            async def main():
                processor = ContentProcessor("api-key-here")
                async with processor:
                    result = await processor.process_content("Hello, World!")
                    print(result)
            
            if __name__ == "__main__":
                asyncio.run(main())
            """,
            
            "JavaScript": """
            import React, { useState, useEffect } from 'react';
            import { ContentAnalyzer } from './services/ContentAnalyzer';
            
            const ContentProcessor = () => {
                const [inputText, setInputText] = useState('');
                const [analysisResult, setAnalysisResult] = useState(null);
                const [isProcessing, setIsProcessing] = useState(false);
                
                const analyzer = new ContentAnalyzer();
                
                const analyzeContent = async () => {
                    if (!inputText.trim()) return;
                    
                    setIsProcessing(true);
                    try {
                        const result = await analyzer.analyze({
                            text: inputText,
                            options: {
                                language: 'de',
                                includeSentiment: true,
                                extractEntities: true
                            }
                        });
                        
                        setAnalysisResult(result);
                    } catch (error) {
                        console.error('Analysis failed:', error);
                    } finally {
                        setIsProcessing(false);
                    }
                };
                
                return (
                    <div className="content-processor">
                        <textarea
                            value={inputText}
                            onChange={(e) => setInputText(e.target.value)}
                            placeholder="Text hier eingeben..."
                            rows={5}
                        />
                        
                        <button 
                            onClick={analyzeContent}
                            disabled={isProcessing || !inputText.trim()}
                        >
                            {isProcessing ? 'Analysiere...' : 'Analysieren'}
                        </button>
                        
                        {analysisResult && (
                            <div className="analysis-result">
                                <h3>Analyseresultat</h3>
                                <pre>{JSON.stringify(analysisResult, null, 2)}</pre>
                            </div>
                        )}
                    </div>
                );
            };
            
            export default ContentProcessor;
            """
        ]
        
        let filename = "sample.\(language.lowercased())"
        let description = "Sample \(language) code for testing"
        
        return TestCodeData(
            language: language,
            content: codeExamples[language] ?? "// Sample code",
            filename: filename,
            description: description,
            complexity: complexity,
            lineCount: codeExamples[language]?.components(separatedBy: .newlines).count ?? 10,
            hasComments: true,
            hasDocumentation: complexity != .simple
        )
    }
    
    private func generateRandomTask() -> TestTaskData {
        let assignees = germanNames
        let taskTitles = [
            "UI/UX Design überarbeiten",
            "API Endpoints implementieren",
            "Unit Tests schreiben",
            "Performance Optimierung",
            "Dokumentation aktualisieren",
            "Bug-Fix: Login Problem",
            "Feature Integration testen",
            "Code Review durchführen"
        ]
        
        let descriptions = [
            "Überarbeitung der Benutzeroberfläche basierend auf User Feedback",
            "Implementierung der neuen REST API Endpoints für User Management",
            "Umfassende Unit Tests für kritische Business Logic",
            "Performance-Analyse und Optimierung der Ladezeiten",
            "Aktualisierung der technischen Dokumentation",
            "Behebung des Login-Problems bei der Authentifizierung",
            "Integration Testing für neue Features",
            "Code Review für Pull Request #123"
        ]
        
        return TestTaskData(
            id: UUID().uuidString,
            title: taskTitles.randomElement()!,
            description: descriptions.randomElement()!,
            assignee: assignees.randomElement()!,
            status: [.todo, .inProgress, .review, .completed, .blocked].randomElement()!,
            priority: [.low, .medium, .high, .urgent].randomElement()!,
            dueDate: Bool.random() ? Date().addingTimeInterval(TimeInterval.random(in: 86400...(30 * 86400))) : nil,
            estimatedHours: Double.random(in: 2...40),
            tags: ["development", "priority-high"]
        )
    }
    
    private func generateRandomProject() -> TestProjectData {
        let projectNames = [
            "MobilApp Redesign",
            "API Modernisierung", 
            "Cloud Migration",
            "Data Pipeline Build",
            "User Dashboard Entwicklung",
            "Security Audit",
            "Testing Framework Setup",
            "Performance Monitoring"
        ]
        
        let projectDescriptions = [
            "Vollständige Überarbeitung der mobilen Anwendung mit modernem Design und verbesserter UX.",
            "Modernisierung der bestehenden API-Infrastruktur für bessere Performance und Skalierbarkeit.",
            "Migration der Anwendung von On-Premise zu Cloud-Infrastruktur für bessere Verfügbarkeit.",
            "Entwicklung einer robusten Datenpipeline für Real-Time Analytics und Reporting.",
            "Neues User Dashboard mit erweiterten Funktionen und verbesserter Benutzerfreundlichkeit.",
            "Umfassendes Security Audit zur Identifikation und Behebung von Sicherheitslücken.",
            "Aufbau eines automatisierten Testing Frameworks für Qualitätssicherung.",
            "Implementierung von Performance Monitoring und Alerting-Systemen."
        ]
        
        let teamSize = Int.random(in: 3...8)
        let team = Array(germanNames.shuffled().prefix(teamSize))
        let taskCount = Int.random(in: 5...15)
        
        var tasks: [TestTaskData] = []
        for _ in 0..<taskCount {
            tasks.append(generateRandomTask())
        }
        
        return TestProjectData(
            name: projectNames.randomElement()!,
            description: projectDescriptions.randomElement()!,
            status: [.planning, .active, .onHold, .completed, .cancelled].randomElement()!,
            tasks: tasks,
            team: team,
            startDate: Date().addingTimeInterval(-TimeInterval.random(in: 0...(60 * 24 * 60 * 60))),
            deadline: Bool.random() ? Date().addingTimeInterval(TimeInterval.random(in: 86400...(120 * 24 * 60 * 60))) : nil,
            priority: [.low, .medium, .high, .critical].randomElement()!
        )
    }
    
    private func generateRandomTags() -> [String] {
        let allTags = [
            "important", "business", "personal", "project", "idea",
            "meeting", "research", "development", "design", "testing",
            "bug", "feature", "documentation", "review", "planning"
        ]
        
        let tagCount = Int.random(in: 1...5)
        return Array(Set(allTags.shuffled().prefix(tagCount)))
    }
    
    private func generateTitle(for content: String, language: TestDataLanguage) -> String {
        let lines = content.components(separatedBy: .newlines)
        let firstNonEmptyLine = lines.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? "Neue Notiz"
        
        let title = firstNonEmptyLine
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "Von:", with: "")
            .replacingOccurrences(of: "Betreff:", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        return title.isEmpty ? "Notiz vom \(Date().formatted(.dateTime.day().month()))" : title
    }
}

// MARK: - Utility Extensions

extension String {
    static func randomHexString(length: Int) -> String {
        let chars = "0123456789abcdef"
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}

extension Date {
    func addingTimeInterval(_ timeInterval: TimeInterval) -> Date {
        return self.addingTimeInterval(timeInterval)
    }
}

extension TestDataFactory {
    // MARK: - Performance Test Data
    
    func generateLargeContent(size: ContentSize) -> String {
        let baseText = """
        Dies ist ein Testdokument für Performance-Tests.
        Es enthält verschiedene Arten von Inhalten zur Simulation realer Anwendungsszenarien.
        
        ## E-Mail Inhalt
        Von: max.mueller@example.com
        An: team@example.com
        Betreff: Projekt Update
        
        Hallo Team,
        
        hier ein kurzer Status-Update zu unserem aktuellen Projekt.
        
        ## Meeting Notizen
        Teilnehmer: Anna Schmidt, Thomas Weber, Maria Fischer
        Agenda: 
        1. Status Update
        2. Nächste Schritte
        3. Timeline Review
        
        ## Code Beispiel
        func processContent(text: String) {
            let analyzer = ContentAnalyzer()
            let result = analyzer.analyze(text)
            return result
        }
        
        ## Aufgabenliste
        - [ ] Feature X implementieren
        - [ ] Tests schreiben
        - [ ] Dokumentation aktualisieren
        - [ ] Code Review
        """
        
        switch size {
        case .small:
            return baseText
        case .medium:
            return String(repeating: baseText + "\n\n", count: 10)
        case .large:
            return String(repeating: baseText + "\n\n", count: 100)
        case .huge:
            return String(repeating: baseText + "\n\n", count: 1000)
        }
    }
    
    enum ContentSize {
        case small
        case medium
        case large
        case huge
    }
    
    // MARK: - Stress Test Data
    
    func generateStressTestData() -> [NoteModel] {
        var notes: [NoteModel] = []
        
        // Generate notes with various content types
        for _ in 0..<1000 {
            notes.append(generateRandomNote())
        }
        
        return notes
    }
    
    // MARK: - Regression Test Data
    
    func generateRegressionTestScenarios() -> [TestScenario] {
        return [
            TestScenario(
                name: "E-Mail Processing",
                content: generateRandomEmail().content,
                expectedType: .email,
                expectedProcessingTime: 5.0
            ),
            TestScenario(
                name: "Meeting Notes",
                content: generateRandomMeeting().notes,
                expectedType: .meeting,
                expectedProcessingTime: 3.0
            ),
            TestScenario(
                name: "Code Content",
                content: generateRandomCode().content,
                expectedType: .code,
                expectedProcessingTime: 2.0
            )
        ]
    }
}

struct TestScenario {
    let name: String
    let content: String
    let expectedType: ContentType
    let expectedProcessingTime: TimeInterval
}

// MARK: - Extension for Project Status & Task Status
extension TestProjectData.ProjectStatus {
    var displayName: String {
        switch self {
        case .planning: return "Planung"
        case .active: return "Aktiv"
        case .onHold: return "Pausiert"
        case .completed: return "Abgeschlossen"
        case .cancelled: return "Abgebrochen"
        }
    }
}

extension TestTaskData.TaskStatus {
    var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "In Bearbeitung"
        case .review: return "Review"
        case .completed: return "Abgeschlossen"
        case .blocked: return "Blockiert"
        }
    }
}

extension TestTaskData.TaskPriority {
    var displayName: String {
        switch self {
        case .low: return "Niedrig"
        case .medium: return "Mittel"
        case .high: return "Hoch"
        case .urgent: return "Dringend"
        }
    }
}