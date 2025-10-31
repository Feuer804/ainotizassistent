# API-Key Management System Dokumentation

## Übersicht

Das API-Key Management System ist eine umfassende Lösung für die sichere Verwaltung von API-Schlüsseln für verschiedene KI-Provider. Es bietet höchste Sicherheit durch Verschlüsselung, automatisierte Validierung und umfassende Überwachung.

## 🏗️ Architektur

### Hauptkomponenten

1. **APIKeyManager.swift** - Zentraler Manager für alle API-Keys
2. **KeychainManager.swift** - Sichere Keychain-Integration
3. **Provider-spezifische Manager**:
   - `OpenAIProviderManager.swift`
   - `OpenRouterProviderManager.swift` 
   - `NotionProviderManager.swift`
   - `WhisperProviderManager.swift`
4. **APIResponseModels.swift** - Gemeinsame Datenmodelle
5. **APIKeySettingsView.swift** - User Interface

### Sicherheitsfeatures

- **AES-GCM Verschlüsselung** für alle gespeicherten Keys
- **macOS Keychain Integration** für zusätzliche Sicherheit
- **Automatische Re-Verschlüsselung** bei Key-Änderungen
- **Emergency Disable Funktion** für kompromittierte Keys
- **Security Alert System** für Sicherheitsvorfälle

## 🔐 Sicherheitsfunktionen

### Verschlüsselung
```swift
// Automatische Verschlüsselung beim Speichern
private func encryptKey(_ key: String, with encryptionKey: SymmetricKey? = nil) -> String
private func decryptKey(_ encryptedKey: String, with encryptionKey: SymmetricKey? = null) -> String
```

### Keychain Integration
```swift
// Sichere Speicherung im macOS Keychain
class KeychainManager {
    func set(_ data: Data, for key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws
    func get(key: String) throws -> Data
    func delete(key: String) throws
}
```

### Emergency Functions
```swift
// Notfall-Deaktivierung aller Keys
func emergencyDisableAllKeys(for provider: APIProvider? = nil)

// Key Rotierung
func rotateKey(for provider: APIProvider, newKey: String) -> Bool
```

## 📊 API Provider Support

### OpenAI
- **Modelle**: GPT-3.5 Turbo, GPT-4, GPT-4 Turbo, DALL-E 3, Whisper-1
- **Features**: Text-Generation, Image-Generation, Speech-to-Text
- **Rate Limiting**: Automatische Überwachung und Anpassung
- **Usage Tracking**: Token-Verbrauch und Kosten

### OpenRouter
- **Modelle**: OpenAI, Anthropic, Mistral, Meta, Google, Cohere
- **Features**: Multi-Provider Zugriff über ein Interface
- **Credits System**: Integriertes Guthaben-Management
- **Flexible Pricing**: Pay-per-use Modell

### Notion
- **Integration**: Vollständige Notion API Unterstützung
- **Features**: Database Management, Page Operations, Search
- **Real-time Sync**: Automatische Daten-Synchronisation
- **Workspace Management**: Multi-Workspace Unterstützung

### Whisper
- **Features**: Speech-to-Text, Audio Translation
- **Formate**: MP3, WAV, M4A, MP4, AAC, WebM
- **Sprachen**: 20+ unterstützte Sprachen
- **Export**: TXT, SRT, VTT, JSON

## 🔄 Automatisierte Prozesse

### Validierung
```swift
// Automatische Key-Validierung alle 30 Minuten
private func startPeriodicValidation() {
    Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
        self?.validateAllKeys()
    }
}
```

### Provider Status Monitoring
```swift
// Überwachung der Provider-Verfügbarkeit
func checkAllProviderStatuses() {
    for provider in APIProvider.allCases {
        checkProviderStatus(provider)
    }
}
```

### Quota Monitoring
```swift
// Automatische Quota-Überwachung
func trackUsage(for provider: APIProvider, tokensUsed: Int = 0, cost: Double = 0.0) {
    if let quota = key.monthlyQuota, key.monthlyUsage >= quota {
        createSecurityAlert(for: provider, type: .quotaExceeded, message: "Monats-Quote erreicht")
    }
}
```

## 🚨 Security Alert System

### Alert Types
- **Key Compromised**: Kompromittierte Keys
- **Suspicious Activity**: Verdächtige Aktivitäten
- **Quota Exceeded**: Quota-Überschreitung
- **Key Expired**: Abgelaufene Keys
- **Provider Down**: Nicht erreichbare Provider
- **Security Breach**: Sicherheitsverletzungen

### Severity Levels
- **Low**: Informative Meldungen
- **Medium**: Warnungen
- **High**: Dringende Aktion erforderlich
- **Critical**: Kritische Sicherheitsbedrohung

```swift
func createSecurityAlert(for provider: APIProvider, type: SecurityAlertType, message: String, severity: AlertSeverity = .medium) {
    let alert = SecurityAlert(
        type: type,
        provider: provider,
        message: message,
        severity: severity,
        createdAt: Date(),
        isRead: false,
        actionRequired: severity == .high || severity == .critical
    )
    
    securityAlerts.insert(alert, at: 0)
    notificationCenter.post(name: .securityAlert, object: alert)
}
```

## 📈 Usage Tracking & Analytics

### Metriken
- **Request Count**: Anzahl der API-Anfragen
- **Token Usage**: Token-Verbrauch pro Provider
- **Cost Estimation**: Kosten-Schätzungen
- **Response Times**: Antwortzeiten
- **Success Rates**: Erfolgsraten

### Visualisierung
- **Usage Charts**: Grafische Darstellung der Nutzung
- **Trend Analysis**: Trendanalyse über Zeit
- **Provider Comparison**: Vergleich zwischen Providern
- **Cost Optimization**: Kostenspar-Empfehlungen

## 💾 Backup & Export

### Export Formate
```swift
// Vollständiges Backup mit Metadaten
struct APIKeysExport: Codable {
    let version: String
    let exportedAt: Date
    let keys: [ExportedAPIKey]
}
```

### Sicherheitsfeatures beim Backup
- **Verschlüsselte Exporte**: Keys bleiben verschlüsselt
- **Metadaten**: Erstelldatum, Version, Provider-Info
- **Integritätsprüfung**: Prüfsummen für Backup-Validierung

### Wiederherstellung
```swift
func importKeys(from exportString: String) -> Bool {
    // Validiere Export-Format
    // Prüfe Encryption-Version
    // Importiere Keys sicher
}
```

## 🔧 Benutzeroberfläche

### Hauptbereiche
1. **Allgemeine Einstellungen**: Auto-Validation, Security, Notifications
2. **Provider Management**: Key-Verwaltung pro Provider
3. **Security Alerts**: Sicherheitswarnungen und -meldungen
4. **Usage Statistics**: Nutzungsstatistiken und Analysen
5. **Backup & Export**: Backup-Erstellung und -Wiederherstellung

### Features
- **Responsive Design**: Optimiert für verschiedene Bildschirmgrößen
- **Real-time Updates**: Live-Updates von Status und Statistiken
- **Search & Filter**: Schneller Zugriff auf spezifische Keys
- **Quick Actions**: Schnellzugriff auf häufige Aktionen

## 🔄 Synchronisation

### macOS Credential Manager
```swift
func syncWithMacOSCredentials() throws {
    // Integration mit macOS System Credentials
    // Automatische Sync zwischen Apps
    // Cross-Device Key-Sharing (optional)
}
```

### Keychain Sync
```swift
func syncWithKeychain() {
    // Sync mit macOS Keychain
    // App Groups Support für Extensions
    // Multi-Device Synchronisation
}
```

## ⚡ Performance Optimierungen

### Caching
- **UserDefaults**: Für häufig verwendete Konfigurationen
- **Memory Caching**: Für API-Response Models
- **Disk Caching**: Für große Datenmengen

### Background Processing
- **DispatchQueue**: Für asynchrone API-Calls
- **Background Tasks**: Für lang laufende Operationen
- **Lazy Loading**: Für große Listen und Datenmengen

## 🛡️ Compliance & Standards

### Datenschutz
- **GDPR-konform**: EU-Datenschutzverordnung
- **Local Storage**: Alle Daten bleiben lokal
- **No Telemetry**: Keine Telemetrie-Daten

### Sicherheitsstandards
- **AES-256**: Industriestandard Verschlüsselung
- **NIST Guidelines**: Nationale Sicherheitsstandards
- **OWASP**: Web-Sicherheitsstandards

## 🔮 Zukunftige Erweiterungen

### Geplante Features
- **Multi-Factor Authentication**: 2FA Integration
- **Hardware Security Modules**: HSM Support
- **Blockchain Integration**: Dezentrale Key-Verwaltung
- **AI-Powered Anomaly Detection**: KI-basierte Bedrohungserkennung

### Provider-Erweiterungen
- **Anthropic Claude**: Direkter Claude API Support
- **Google PaLM**: Google AI Modelle
- **Azure OpenAI**: Microsoft Azure Integration
- **Custom Providers**: Plugin-System für eigene Provider

## 📚 API Referenz

### Hauptklassen

#### APIKeyManager
```swift
class APIKeyManager: ObservableObject {
    @Published var apiKeys: [APIKey]
    @Published var providerStatuses: [APIProvider: ProviderStatus]
    @Published var securityAlerts: [SecurityAlert]
    
    func addAPIKey(_ key: APIKey)
    func removeAPIKey(_ key: APIKey)
    func validateAPIKey(_ key: inout APIKey)
    func trackUsage(for provider: APIProvider)
    func emergencyDisableAllKeys()
}
```

#### KeychainManager
```swift
class KeychainManager {
    func set(_ data: Data, for key: String) throws
    func get(key: String) throws -> Data
    func delete(key: String) throws
    func exportAll() throws -> Data
    func importFrom(_ data: Data) throws
}
```

### Datenmodelle

#### APIKey
```swift
struct APIKey: Codable, Identifiable {
    let id: UUID
    let provider: APIProvider
    var keyValue: String
    var status: APIKeyStatus
    var createdAt: Date
    var lastValidatedAt: Date?
    var expiresAt: Date?
    var isPrimary: Bool
    var usageCount: Int
}
```

#### SecurityAlert
```swift
struct SecurityAlert: Codable, Identifiable {
    let id: UUID
    let type: SecurityAlertType
    let provider: APIProvider
    let message: String
    let severity: AlertSeverity
    let createdAt: Date
    let isRead: Bool
    let actionRequired: Bool
}
```

## 🧪 Testing

### Unit Tests
- **Keychain Operations**: Tests für Keychain-Operationen
- **Encryption/Decryption**: Verschlüsselungstests
- **API Validation**: API-Key Validierungstests
- **Security Alerts**: Alert-System Tests

### Integration Tests
- **Provider APIs**: End-to-End Tests mit echten APIs
- **Backup/Restore**: Backup-Funktionalitätstests
- **UI Tests**: Interface-Tests

### Sicherheitstests
- **Penetration Tests**: Sicherheitsüberprüfungen
- **Encryption Tests**: Verschlüsselungsstärke
- **Access Control Tests**: Zugriffskontrolltests

## 📞 Support & Kontakt

Bei Fragen oder Problemen:
1. Prüfen Sie die Logs in der Console
2. Überprüfen Sie die Netzwerkverbindung
3. Stellen Sie sicher, dass die API-Keys gültig sind
4. Kontaktieren Sie den Support mit detaillierten Fehlerberichten

---

**Version**: 1.0.0  
**Letzte Aktualisierung**: Oktober 2024  
**Kompatibilität**: macOS 12.0+, iOS 15.0+