# OpenAI API Integration für macOS App

Diese Implementierung bietet eine vollständige OpenAI API Integration für macOS-Apps mit modernen Swift-Technologien.

## 📋 Inhaltsverzeichnis

- [Features](#-features)
- [Architektur](#-architektur)
- [Installation](#-installation)
- [Verwendung](#-verwendung)
- [API Key Management](#-api-key-management)
- [Content-Generierung](#-content-generierung)
- [Rate Limiting & Usage Tracking](#-rate-limiting--usage-tracking)
- [Fehlerbehandlung](#-fehlerbehandlung)
- [Beispiele](#-beispiele)

## ✨ Features

### 🔑 API Key Management
- **Secure Keychain Storage**: API Keys werden sicher in der macOS Keychain gespeichert
- **Easy Setup**: Einfache Konfiguration über SwiftUI Settings
- **Key Validation**: Automatische Validierung bei der Eingabe

### 🤖 AI Model Support
- **GPT-4**: Vollständige GPT-4 Integration
- **GPT-4 Turbo**: Neueste Turbo-Variante
- **GPT-3.5-Turbo**: Kostengünstige Alternative
- **Configurable Parameters**: Temperature, Max Tokens, etc.

### 💬 Chat & Streaming
- **Real-time Chat**: Vollständiger Chat-Client
- **Streaming Responses**: Live-Streaming für bessere UX
- **Message History**: Vollständige Chat-Historie
- **Multiple Conversations**: Parallel verwaltbare Chats

### 📧 Content-Generierung
- **Email Generation**: Spezialisierte E-Mail-Vorlagen
- **Meeting Notes**: Strukturierte Meeting-Protokolle
- **Article Writing**: Verschiedene Artikel-Typen
- **Content Type Prompts**: Optimierte Prompts je Anwendungsfall

### 📊 Usage & Monitoring
- **Real-time Usage**: Tägliche Usage-Statistiken
- **Cost Tracking**: Detaillierte Kostenanalyse
- **Rate Limiting**: Automatisches Rate Limiting
- **Usage History**: 30-Tage Verlaufsdaten

### 🔒 Security & Performance
- **Keychain Storage**: Enterprise-sichere Keychain-Integration
- **Rate Limiting**: Automatisches API Rate Management
- **Error Handling**: Umfassende Fehlerbehandlung
- **Network Resilience**: Robuste Netzwerkbehandlung

## 🏗️ Architektur

### Core Components

```
OpenAIClient.swift          # Haupt-API-Client
├── API Key Management      # Keychain-Integration
├── Rate Limiter           # API-Limit-Management
├── Usage Tracker          # Usage-Statistiken
└── Network Layer          # URLSession-basierte Requests

OpenAIStreamHandler.swift   # Streaming & View Models
├── OpenAIStreamHandler    # Real-time Streaming
├── ChatViewModel          # Chat-Logik
├── Content ViewModels     # Content-Generierung
└── Usage ViewModels       # Statistiken

OpenAISettingsView.swift    # Konfiguration & UI
├── API Key Settings       # Key-Management UI
├── Model Configuration    # Parameter-Einstellungen
├── Usage Statistics       # Usage-Darstellung
└── Content Type Selection # Typ-Auswahl

ContentGenerationViews.swift # Content-UI
├── Email Generation       # E-Mail-Generator
├── Meeting Generation     # Meeting-Protokolle
├── Article Generation     # Artikel-Erstellung
└── Chat Interface         # Chat-Client
```

### Technology Stack

- **Swift 5.9+**: Modern Swift mit async/await
- **SwiftUI**: Native iOS/macOS UI Framework
- **URLSession**: Native Networking
- **Keychain Services**: Sichere Credential-Verwaltung
- **Combine**: Reactive Programming für UI-Updates
- **Codable**: Type-safe JSON Serialization

## 🚀 Installation

### Voraussetzungen

```bash
# macOS 12.0+ oder iOS 15.0+
# Xcode 14.0+
# Swift 5.9+
```

### Dateien hinzufügen

1. Kopieren Sie alle Swift-Dateien in Ihr Xcode-Projekt:

```bash
OpenAIClient.swift          # Core API Client
OpenAIStreamHandler.swift   # Streaming & View Models
OpenAISettingsView.swift    # Settings UI
ContentGenerationViews.swift # Content UI
OpenAIDemoApp.swift         # Demo App
```

2. Xcode Target Dependencies prüfen:
   - Link against Foundation framework
   - Security framework für Keychain (automatisch eingebunden)

### Info.plist Konfiguration

Keine zusätzlichen Berechtigungen erforderlich für Keychain.

## 💡 Verwendung

### Grundlegende Nutzung

```swift
import SwiftUI

struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // API Key Setup
                    setupOpenAI()
                }
        }
    }
    
    private func setupOpenAI() {
        let client = OpenAIClient.shared
        
        // Prüfe ob API Key vorhanden
        if !client.hasValidAPIKey() {
            print("API Key muss konfiguriert werden")
        }
    }
}
```

### API Key Konfiguration

```swift
// API Key setzen
let client = OpenAIClient.shared

do {
    try client.setAPIKey("sk-your-openai-api-key-here")
    print("API Key erfolgreich gespeichert")
} catch {
    print("Fehler beim Speichern: \(error)")
}
```

### Einfacher Chat

```swift
import SwiftUI

struct ChatView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(chatViewModel.messages) { message in
                    Text(message.content)
                }
            }
            
            HStack {
                TextField("Nachricht...", text: $chatViewModel.inputText)
                Button("Senden") {
                    chatViewModel.sendMessage()
                }
            }
        }
    }
}
```

### Content-Generierung

```swift
// E-Mail generieren
struct EmailView: View {
    @StateObject private var emailViewModel = EmailGenerationViewModel()
    
    var body: some View {
        VStack {
            TextEditor(text: $emailViewModel.inputText)
                .frame(height: 100)
            
            Button("E-Mail generieren") {
                emailViewModel.generateEmail()
            }
            
            if !emailViewModel.generatedEmail.isEmpty {
                Text(emailViewModel.generatedEmail)
                    .padding()
            }
        }
    }
}
```

## 🔑 API Key Management

### Keychain-basierte Speicherung

```swift
let apiKeyManager = APIKeyManager()

// API Key speichern
try apiKeyManager.storeAPIKey("your-api-key")

// API Key abrufen
let apiKey = try apiKeyManager.retrieveAPIKey()

// API Key löschen
try apiKeyManager.clearAPIKey()
```

### Settings UI Integration

```swift
struct SettingsView: View {
    @StateObject private var apiKeyViewModel = APIKeyViewModel()
    
    var body: some View {
        Form {
            Section("OpenAI API") {
                if apiKeyViewModel.hasAPIKey {
                    Text("✅ API Key konfiguriert")
                    Button("Entfernen") {
                        apiKeyViewModel.removeAPIKey()
                    }
                } else {
                    Text("❌ Kein API Key konfiguriert")
                    Button("API Key eingeben") {
                        // Show input dialog
                    }
                }
            }
        }
    }
}
```

## 📧 Content-Generierung

### E-Mail-Typen

```swift
// Verschiedene E-Mail-Typen
enum EmailType {
    case general     // Allgemeine E-Mails
    case business    // Geschäftliche E-Mails
    case support     // Support-E-Mails
    case marketing   // Marketing-E-Mails
    case followUp    // Nachfragen
    case thankYou    // Danksagungen
}

// Verwendung
let emailVM = EmailGenerationViewModel()
emailVM.emailType = .business
emailVM.generateEmail()
```

### Meeting-Typen

```swift
enum MeetingType {
    case general      // Allgemeine Meetings
    case project      // Projekt-Meetings
    case planning     // Planungs-Meetings
    case review       // Review-Meetings
    case brainstorming // Brainstorming
}
```

### Artikel-Typen

```swift
enum ArticleType {
    case general     // Allgemeine Artikel
    case technical   // Technische Artikel
    case blog        // Blog-Posts
    case news        // News-Artikel
    case tutorial    // Tutorials
}
```

## 📊 Usage & Rate Limiting

### Automatisches Rate Limiting

```swift
let rateLimiter = RateLimiter()

// Prüfe ob Request erlaubt
if rateLimiter.canMakeRequest() {
    // Request ausführen
    rateLimiter.recordRequest()
} else {
    let waitTime = rateLimiter.timeUntilNextRequest
    print("Warten Sie \(Int(waitTime)) Sekunden")
}
```

### Usage Tracking

```swift
let usageTracker = UsageTracker()

// Usage abrufen
let currentUsage = usageTracker.getCurrentDailyUsage()
print("Heute: \(currentUsage.requestCount) Requests")
print("Tokens: \(currentUsage.totalTokens)")
print("Kosten: $\(currentUsage.totalCost)")

// History abrufen
let history = usageTracker.getUsageHistory(days: 30)
```

## 🛠️ Fehlerbehandlung

### Error Types

```swift
enum OpenAIError: Error {
    case noAPIKey
    case rateLimited(waitTime: TimeInterval)
    case dailyLimitExceeded
    case httpError(statusCode: Int, message: String)
    case decodingFailed(Error)
}
```

### Fehlerbehandlung in Views

```swift
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            // UI Content
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}
```

### Retry Logic

```swift
func sendMessageWithRetry() {
    Task {
        do {
            let response = try await openAIClient.sendMessage(messages: messages)
            // Handle success
        } catch OpenAIError.rateLimited(let waitTime) {
            // Wait and retry
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            await sendMessageWithRetry()
        } catch {
            // Handle other errors
        }
    }
}
```

## 🎯 Beispiele

### Streaming Chat

```swift
struct StreamingChatView: View {
    @StateObject private var streamHandler = OpenAIStreamHandler()
    
    var body: some View {
        VStack {
            // Display streaming response
            if streamHandler.isStreaming {
                Text(streamHandler.currentResponse)
                    .multilineTextAlignment(.leading)
                
                ProgressView(value: streamHandler.progress)
            }
            
            HStack {
                TextField("Nachricht...", text: $inputText)
                Button("Senden") {
                    startStreaming()
                }
            }
        }
    }
    
    private func startStreaming() {
        let messages = currentMessages.map { 
            OpenAIMessage(role: $0.role, content: $0.content) 
        }
        
        streamHandler.startStreaming(
            client: OpenAIClient.shared,
            messages: messages
        )
    }
}
```

### Usage Statistics View

```swift
struct UsageStatisticsView: View {
    @StateObject private var viewModel = UsageStatisticsViewModel()
    
    var body: some View {
        VStack {
            // Current Usage
            if let usage = viewModel.currentUsage {
                Text("Heutige Requests: \(usage.requestCount)")
                Text("Tokens verbraucht: \(usage.totalTokens.formatted())")
                Text("Geschätzte Kosten: $\(String(format: "%.4f", usage.totalCost))")
            }
            
            // Monthly Summary
            Text("Monatliche Kosten: $\(String(format: "%.2f", viewModel.totalCostThisMonth))")
            Text("Ø täglich: $\(String(format: "%.2f", viewModel.averageDailyCost))")
            
            Button("Aktualisieren") {
                viewModel.refreshData()
            }
        }
    }
}
```

### Content Generation mit Presets

```swift
struct EmailPresetView: View {
    @StateObject private var emailVM = EmailGenerationViewModel()
    
    var body: some View {
        VStack {
            // Preset Buttons
            HStack {
                Button("Meeting Follow-up") {
                    emailVM.inputText = "Follow-up E-Mail für unser Projekt-Meeting..."
                    emailVM.emailType = .followUp
                }
                
                Button("Support Reply") {
                    emailVM.inputText = "Professionelle Antwort auf Kundenanfrage..."
                    emailVM.emailType = .support
                }
            }
            
            TextEditor(text: $emailVM.inputText)
            
            Button("Generieren") {
                emailVM.generateEmail()
            }
        }
    }
}
```

## 🔧 Konfiguration

### Model-Parameter anpassen

```swift
// In OpenAIClient oder via AppStorage
struct Settings {
    @AppStorage("preferredModel") static var preferredModel = "gpt-4"
    @AppStorage("temperature") static var temperature = 0.7
    @AppStorage("maxTokens") static var maxTokens = 1000
}

// Verwendung
let response = try await openAIClient.sendMessage(
    messages: messages,
    model: Settings.preferredModel,
    temperature: Settings.temperature,
    maxTokens: Settings.maxTokens
)
```

### Rate Limits anpassen

```swift
// In RateLimiter Klasse
private let maxRequestsPerMinute: Int = 60
private let maxRequestsPerDay: Int = 1000

// Custom Limits
let customLimiter = RateLimiter()
customLimiter.maxRequestsPerMinute = 100
customLimiter.maxRequestsPerDay = 2000
```

## 🐛 Debugging

### Logging aktivieren

```swift
// In OpenAIClient
private let enableLogging = true

private func log(_ message: String) {
    if enableLogging {
        print("[OpenAI] \(message)")
    }
}

// Usage
log("Starting request to \(model)")
log("Request completed: \(response.choices.count) choices")
log("Error occurred: \(error.localizedDescription)")
```

### Network Monitoring

```swift
// URLSession delegate für detailed logging
class OpenAIDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, 
                   didCompleteWithError error: Error?) {
        if let error = error {
            print("Request failed: \(error)")
        } else {
            print("Request completed successfully")
        }
    }
}
```

## 📈 Performance-Optimierung

### Connection Pooling

```swift
private lazy var session: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30.0
    config.timeoutIntervalForResource = 60.0
    config.httpMaximumConnectionsPerHost = 5
    return URLSession(configuration: config, delegate: nil, delegateQueue: nil)
}()
```

### Caching

```swift
// Response Caching für identische Requests
private var responseCache: [String: OpenAIResponse] = [:]

func sendMessageCached(messages: [OpenAIMessage]) async throws -> OpenAIResponse {
    let cacheKey = messages.map { "\($0.role):\($0.content)" }.joined(separator: "|")
    
    if let cached = responseCache[cacheKey] {
        return cached
    }
    
    let response = try await sendMessage(messages: messages)
    responseCache[cacheKey] = response
    return response
}
```

## 🔒 Sicherheit

### API Key Schutz

```swift
// Nie API Key in Code hardcoden
// Immer Keychain verwenden

// Validation vor jedem Request
func validateAPIKey() throws {
    guard hasValidAPIKey() else {
        throw OpenAIError.noAPIKey
    }
    
    // Zusätzliche Validierung
    guard let apiKey = try getAPIKey(),
          apiKey.starts(with: "sk-") else {
        throw OpenAIError.invalidAPIKey
    }
}
```

### Input Sanitization

```swift
// User Input bereinigen
func sanitizeInput(_ input: String) -> String {
    return input
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
        .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
}
```

## 📝 Lizenz

Diese OpenAI Integration ist Teil der AINotizassistent macOS App und unterliegt den gleichen Lizenzbedingungen.

## 🤝 Beitragen

Für Beiträge und Verbesserungen:

1. Fork das Repository
2. Feature Branch erstellen
3. Änderungen testen
4. Pull Request einreichen

## 📞 Support

Für Fragen und Support:
- Issue im Repository erstellen
- Dokumentation konsultieren
- Code-Beispiele als Referenz nutzen

---

**Hinweis**: Diese Implementation nutzt die offizielle OpenAI API. Stellen Sie sicher, dass Sie gültige API-Credentials haben und die OpenAI Terms of Service einhalten.