# Notion API Integration für iOS/Swift

## Übersicht

Eine vollständige Swift-basierte Integration der Notion API für iOS-Apps, die umfassende Funktionen für Notion-Datenbanken, Seiten-Erstellung, Echtzeit-Synchronisation und Rich Content Management bietet.

## Architektur

### Hauptkomponenten

1. **NotionIntegration.swift** - Kern-API Integration
2. **NotionTemplates.swift** - Vordefinierte Templates
3. **NotionRateLimiter.swift** - Rate Limiting & Retry-Mechanismen
4. **NotionWebhooks.swift** - Echtzeit Webhook-Unterstützung
5. **NotionView.swift** - SwiftUI Database Management UI
6. **NotionRichContent.swift** - Rich Content Builder
7. **NotionAPI.swift** - Basis-API Models und Requests

## Features

### ✅ Implementierte Funktionalität

#### 1. Authentication & API Management
- **API Key Management**: Sichere Speicherung mit UserDefaults
- **Authentication State**: Observable Status-Tracking
- **Error Handling**: Umfassendes Fehlerbehandlung-System

```swift
let notionIntegration = NotionIntegration()
notionIntegration.setApiKey("your-notion-api-key")
```

#### 2. Database Management
- **Database Creation**: Erstellung neuer Datenbanken
- **Database Queries**: Flexible Filter- und Sortiermöglichkeiten
- **Real-time Updates**: Webhook-basierte Live-Synchronisation

```swift
// Erstelle Datenbank mit Template
let properties = templateManager.getTemplate(named: "MeetingNotes")?.createProperties() ?? [:]
let database = try await notionIntegration.createDatabase(
    title: "Team Meetings",
    parentDatabaseId: parentId,
    properties: properties
)
```

#### 3. Page Creation & Management
- **Template-basierte Seiten**: Vordefinierte Layouts
- **Rich Content Support**: Überschriften, Listen, Code-Blöcke, Bilder
- **Properties**: Vollständige Unterstützung aller Notion Property-Typen

```swift
// Seite mit Template erstellen
let page = try await NotionTemplateManager.shared.createPageFromTemplate(
    databaseId: databaseId,
    templateName: "TaskManagement",
    title: "Neue Aufgabe",
    additionalProperties: additionalProps
)
```

#### 4. Rich Content Builder
- **Block-Typen**: Alle Notion Block-Typen unterstützt
- **Text-Formatting**: Fett, kursiv, durchgestrichen, unterstrichen
- **Code-Blöcke**: Syntax-Highlighting für verschiedene Sprachen
- **Bilder & Dateien**: Upload und Embedding
- **Markdown-Import**: Automatische Konvertierung von Markdown

```swift
let contentBuilder = NotionRichContentBuilder()
let blocks = contentBuilder.createMarkdownFormattedText("""
# Meeting Notes

## Attendees
- John Doe
- Jane Smith

## Agenda
1. Project Status
2. Next Steps
""")
```

#### 5. Template System
- **Meeting Notes Template**: Vollständiges Meeting-Protokoll Layout
- **Task Management Template**: Aufgabenverwaltung mit Status & Prioritäten
- **Project Notes Template**: Projekt-Dokumentation
- **Eigene Templates**: Erweiterbares Template-System

#### 6. Rate Limiting & Retry
- **Intelligentes Rate Limiting**: 3 Requests/Sekunde, 100/Minute
- **Exponential Backoff**: Automatische Backoff-Strategie
- **Status Monitoring**: Echtzeit-Status der Rate Limits
- **Batch Operations**: Effiziente Stapelverarbeitung

```swift
// Batch-Erstellung mit Retry
let results = try await notionIntegration.createMultiplePagesWithRetry(
    databaseId: databaseId,
    pages: pageDataArray
)
```

#### 7. Webhook Support
- **Echtzeit-Synchronisation**: WebSocket-basierte Live-Updates
- **Event Handling**: Automatische Reaktion auf Seiten-Änderungen
- **Auto-Reconnection**: Intelligente Wiederherstellung bei Netzwerkproblemen
- **Event Filtering**: Selektive Abonnements für spezifische Datenbanken

```swift
// Webhook Setup
try await notionIntegration.setupWebhookListener(endpoint: webhookUrl)
notionIntegration.onPageCreated { page in
    print("Neue Seite erstellt: \(page.id)")
}
```

#### 8. Database Management UI
- **SwiftUI-basiert**: Moderne iOS-UI-Komponenten
- **Search & Filter**: Flexible Such- und Filter-Funktionen
- **Database Explorer**: Übersichtliche Datenbank-Navigation
- **Live Sync Indicator**: Visueller Status der Echtzeit-Verbindung

#### 9. File & Image Management
- **Image Upload**: Automatische Komprimierung und Upload
- **External URLs**: Integration mit Cloud-Services
- **File Validation**: Automatische Überprüfung von Dateigröße und -typ
- **Gallery Support**: Bildergalerien mit Beschriftungen

```swift
let fileManager = NotionFileManager()
if let compressedImage = fileManager.compressImage(originalImage) {
    let imageUrl = try await fileManager.uploadImageToExternalService(compressedImage)
    let imageBlock = contentBuilder.createImageBlock(url: imageUrl, caption: "Screenshot")
}
```

### 🚀 Erweiterte Features

#### Batch Operations
```swift
// Multiple Seiten mit Retry-Mechanismus
let batchResults = try await notionIntegration.createMultiplePagesWithRetry(
    databaseId: databaseId,
    pages: [(properties: props, blocks: blocks)]
)
```

#### Complex Queries
```swift
// Komplexe Filter mit Query Builder
let query = NotionDatabaseQueryBuilder()
    .where("Status", .equals, "In Progress")
    .orderBy("Due Date")
    .limit(50)
    
let (filter, sorts) = query.build()
let (pages, nextCursor, hasMore) = try await notionIntegration.queryDatabase(
    databaseId: databaseId,
    filter: filter,
    sorts: sorts
)
```

#### Custom Properties
```swift
// Erweiterte Property-Erstellung
let customProperties: [String: NotionProperty] = [
    "Priority": .priority,
    "Due Date": .date,
    "Assigned Team": .people,
    "Budget": .number,
    "Tags": .multiSelect,
    "Status": .status
]
```

## Installation & Setup

### 1. Notion Integration erstellen
1. Gehen Sie zu [Notion My Integrations](https://www.notion.so/my-integrations)
2. Erstellen Sie eine neue Integration
3. Kopieren Sie den API-Schlüssel

### 2. Integration in iOS App

```swift
import SwiftUI

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            NotionDatabaseView()
        }
    }
}
```

### 3. API-Schlüssel konfigurieren

```swift
// In Ihrer App
let notionIntegration = NotionIntegration()
notionIntegration.setApiKey("your-notion-integration-token")
```

## API-Referenz

### Hauptklassen

#### `NotionIntegration`
Kern-API Klasse für alle Notion-Operationen

```swift
// Database Operations
func createDatabase(title: String, parentDatabaseId: String, properties: [String: NotionProperty]) async throws -> NotionDatabase
func queryDatabase(databaseId: String, filter: FilterObject?, sorts: [SortObject]?) async throws -> ([NotionPage], String?, Bool)

// Page Operations  
func createPage(databaseId: String, properties: [String: NotionPropertyValue], blocks: [NotionBlock]?) async throws -> NotionPage
func updatePage(pageId: String, properties: [String: NotionPropertyValue]) async throws -> NotionPage

// Search Operations
func search(query: String, filter: [String: Any]?) async throws -> ([SearchResult], String?, Bool)
```

#### `NotionTemplateManager`
Template-Management für wiederverwendbare Layouts

```swift
let templateManager = NotionTemplateManager.shared

// Vordefinierte Templates
let meetingTemplate = templateManager.getTemplate(named: "MeetingNotes")
let taskTemplate = templateManager.getTemplate(named: "TaskManagement")
let projectTemplate = templateManager.getTemplate(named: "ProjectNotes")

// Seite aus Template erstellen
let page = try await templateManager.createPageFromTemplate(
    databaseId: "database-id",
    templateName: "TaskManagement", 
    title: "Neue Aufgabe",
    additionalProperties: customProps
)
```

#### `NotionRateLimiter`
Rate Limiting und Retry-Mechanismen

```swift
let rateLimiter = NotionRateLimiter()

// Rate Limit Status abrufen
let status = rateLimiter.getRateLimitStatus()
print("Requests/Minute: \(status.requestsInLastMinute)/\(status.maxRequestsPerMinute)")

// Request mit automatischen Retry
let result = try await rateLimiter.executeWithRetry(maxRetries: 3) {
    return try await someNotionRequest()
}
```

#### `NotionWebhookManager`
Webhook-Unterstützung für Echtzeit-Synchronisation

```swift
let webhookManager = NotionWebhookManager()

// Webhook verbinden
try await webhookManager.connect(endpoint: "your-webhook-url")

// Event-Listener
webhookManager.onPageCreated { page in
    // Handle new page
}

webhookManager.onPageUpdated { page in
    // Handle page update  
}
```

#### `NotionRichContentBuilder`
Rich Content Erstellung für Blöcke

```swift
let builder = NotionRichContentBuilder()

// Verschiedene Block-Typen erstellen
let heading = builder.createHeadingBlock(level: 1, content: "Meeting Notes")
let paragraph = builder.createParagraphBlock(content: "Dies ist ein Absatz.")
let code = builder.createCodeBlock(content: "print('Hello, World!')", language: "swift")
let todo = builder.createTodoItem(content: "Aufgabe erledigen", checked: false)
let image = builder.createImageBlock(url: "https://example.com/image.jpg", caption: "Screenshot")

// Markdown zu Blöcken konvertieren
let blocks = builder.createMarkdownFormattedText(markdownText)
```

### Property-Typen

#### Unterstützte Notion Properties
- **Title**: Seitentitel
- **Rich Text**: Formatierter Text
- **Number**: Zahlenwerte
- **Select**: Einfache Auswahl (Dropdown)
- **Multi Select**: Mehrfach-Auswahl
- **Date**: Datum und Uhrzeit
- **People**: Benutzer-Zuweisung
- **Checkbox**: Boolean-Werte
- **URL**: Web-Links
- **Email**: E-Mail-Adressen
- **Phone Number**: Telefonnummern
- **Files**: Datei-Anhänge
- **Status**: Fortschritts-Status
- **Formula**: Berechnete Werte
- **Relation**: Verknüpfungen zu anderen Datenbanken

### Block-Typen

#### Vollständig unterstützte Blöcke
- **Paragraph**: Absätze
- **Headings (1-3)**: Überschriften
- **Bulleted List**: Aufzählungslisten
- **Numbered List**: Nummerierte Listen
- **To-Do**: Aufgaben-Listen
- **Code**: Code-Blöcke mit Syntax-Highlighting
- **Quote**: Zitate
- **Divider**: Trennlinien
- **Image**: Bilder
- **File**: Datei-Anhänge
- **Bookmark**: Lesezeichen
- **Callout**: Hervorgehobene Textboxen

## Erweiterte Anwendungsfälle

### 1. Automatisierte Meeting-Protokolle

```swift
func createMeetingPage(meetingData: MeetingData) async throws -> NotionPage {
    let template = NotionTemplateManager.shared.getTemplate(named: "MeetingNotes")!
    
    let properties: [String: NotionPropertyValue] = [
        "Date": .date(start: meetingData.date.iso8601),
        "Attendees": .people(meetingData.attendees.map { User(id: $0.id, name: $0.name, avatar_url: $0.avatar, type: "person", person: Person(email: $0.email), bot: nil) }),
        "Status": .status(name: "Anstehend"),
        "Priority": .select(name: "Mittel")
    ]
    
    let blocks = template.createBlocks()
    
    // Agenda hinzufügen
    let agendaBlocks = contentBuilder.createMeetingAgenda(meetingData.agenda)
    
    return try await notionIntegration.createPage(
        databaseId: meetingDatabaseId,
        properties: properties,
        blocks: agendaBlocks + blocks
    )
}
```

### 2. Projekt-Task Management

```swift
func createProjectTasks(projectId: String, tasks: [Task]) async throws -> [NotionPage] {
    let template = NotionTemplateManager.shared.getTemplate(named: "TaskManagement")!
    
    let taskData = tasks.map { task in
        let properties: [String: NotionPropertyValue] = [
            "Task Name": .title(task.title),
            "Priority": .select(name: task.priority.rawValue),
            "Due Date": .date(start: task.dueDate.iso8601),
            "Status": .status(name: "Zu erledigen"),
            "Assigned": task.assignedTo.map { .people([$0]) } ?? nil,
            "Tags": .multiSelect(task.tags.map { SelectOption(id: $0.lowercased(), name: $0, color: "default") })
        ]
        
        let blocks = template.createBlocks()
        
        return (properties: properties, blocks: blocks)
    }
    
    return try await notionIntegration.createMultiplePagesWithRetry(
        databaseId: taskDatabaseId,
        pages: taskData
    )
}
```

### 3. Echtzeit Dashboard

```swift
class NotionDashboardViewModel: ObservableObject {
    @Published var pages: [NotionPage] = []
    @Published var isLoading = false
    
    private let notionIntegration = NotionIntegration()
    private let webhookManager = NotionWebhookManager.shared
    
    init() {
        setupRealTimeUpdates()
        loadDashboardData()
    }
    
    private func setupRealTimeUpdates() {
        // Webhook für Live-Updates
        webhookManager.onPageCreated { [weak self] page in
            self?.pages.insert(page, at: 0)
        }
        
        webhookManager.onPageUpdated { [weak self] page in
            if let index = self?.pages.firstIndex(where: { $0.id == page.id }) {
                self?.pages[index] = page
            }
        }
    }
    
    func loadDashboardData() {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                let (pagesResult, _, _) = try await notionIntegration.queryDatabaseWithRetry(
                    databaseId: dashboardDatabaseId
                )
                
                await MainActor.run {
                    self.pages = pagesResult
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Fehler beim Laden des Dashboards: \(error)")
                }
            }
        }
    }
}
```

## Fehlerbehandlung

### Rate Limiting
```swift
do {
    let result = try await notionIntegration.createPageWithRetry(...)
} catch let error as RateLimitError {
    print("Rate Limit erreicht. Versuchen Sie es in \(error.retryAfter) Sekunden erneut.")
} catch let error as NotionError {
    print("Notion API Fehler: \(error.message)")
}
```

### Webhook-Verbindung
```swift
webhookManager.$connectionError
    .filter { $0 != nil }
    .sink { error in
        print("Webhook-Verbindung fehlgeschlagen: \(error?.localizedDescription ?? "")")
    }
    .store(in: &cancellables)
```

### Netzwerk-Validierung
```swift
// Automatische Erkennung von API-Limit-Erschöpfung
func handleRateLimit(_ error: Error) {
    if let notionError = error as? NotionError, 
       notionError.code == "rate_limited" {
        // Implementiere Backoff-Strategie
        scheduleRetry()
    }
}
```

## Best Practices

### 1. API Key Sicherheit
- Nie API-Schlüssel im Code hardcodieren
- Sichere Speicherung mit Keychain (falls verfügbar)
- Environment-Variablen für Development

### 2. Rate Limiting
- Immer RateLimiter für alle API-Calls verwenden
- Batch-Operationen für mehrere Änderungen
- Exponential Backoff implementieren

### 3. Error Handling
- Alle API-Calls mit do-catch umgeben
- User-freundliche Fehlermeldungen anzeigen
- Retry-Mechanismen für temporäre Fehler

### 4. Webhook Security
- Webhook-URLs validieren
- Event-Verifikation implementieren
- Sichere WebSocket-Verbindungen verwenden

### 5. Performance
- Caching für häufig verwendete Daten
- Lazy Loading für große Listen
- Background Updates mit @MainActor

## Troubleshooting

### Häufige Probleme

#### 1. "Unauthorized" Fehler
- **Lösung**: API-Schlüssel prüfen und neu setzen
- **Prüfung**: `notionIntegration.isAuthenticated`

#### 2. "Rate Limit Exceeded"
- **Lösung**: RateLimiter verwenden
- **Prüfung**: `notionIntegration.getRateLimitStatus()`

#### 3. Webhook nicht verbunden
- **Lösung**: Webhook-URL validieren, Netzwerk prüfen
- **Prüfung**: `webhookManager.isConnected`

#### 4. Template-Fehler
- **Lösung**: Template-Name prüfen, Properties validieren
- **Verfügbare Templates**: `NotionTemplateManager.shared.getAllTemplates()`

### Debug-Tools

```swift
// Rate Limit Status anzeigen
let rateStatus = notionIntegration.getRateLimitStatus()
print("Usage: \(rateStatus.minuteUsagePercentage)%")

// Webhook Events loggen
webhookManager.events.forEach { event in
    print("Event: \(event.type.rawValue) at \(event.event_time)")
}

// API Request-Status
if notionIntegration.isLoading {
    print("API Request in Bearbeitung...")
}
```

## Erweiterte Konfiguration

### Custom Templates
```swift
class CustomNotionTemplate: NotionTemplate {
    let name = "Custom Report"
    let description = "Template für Berichte"
    
    func createProperties() -> [String: NotionProperty] {
        // Custom Properties definieren
    }
    
    func createBlocks() -> [NotionBlock] {
        // Custom Block-Layout
    }
}

// Template registrieren
NotionTemplateManager.shared.registerTemplate(CustomNotionTemplate(), for: "CustomReport")
```

### Webhook Event Handling
```swift
// Custom Event Handler
extension NotionIntegration {
    func setupCustomEventHandlers() {
        onPageCreated { [weak self] page in
            self?.handleCustomPageCreated(page)
        }
        
        onDatabaseUpdated { [weak self] database in
            self?.handleCustomDatabaseUpdated(database)
        }
    }
    
    private func handleCustomPageCreated(_ page: NotionPage) {
        // Custom Logic
    }
}
```

## Lizenz & Support

Diese Notion API Integration ist Teil des AINotizassistent Projekts.

Für Support und weitere Fragen erstellen Sie ein Issue im Projekt-Repository.

---

**Version**: 1.0.0  
**Letzte Aktualisierung**: 31. Oktober 2025  
**Kompatibilität**: iOS 15.0+, Swift 5.7+