# App-Konfiguration: Standard-Speicherziel und Shortcut-Management

## Übersicht

Dieses umfassende System bietet eine vollständige Konfiguration für die AI Notizassistent App mit intelligenten Speicherziel-Verwaltung und fortschrittlicher Shortcut-Konfiguration.

## Komponenten

### 1. DefaultStorageManager.swift
**Zweck**: Verwaltung der Standard-Speicherziele mit intelligenter Content-Analyse

**Hauptfunktionen**:
- ✅ Primary/Secondary Storage Targets (Apple Notes, Obsidian, Notion, Local, Cloud)
- ✅ Content-Type spezifische Speicherziele
  - Email → Notes (mit Dropbox Backup)
  - Meeting → Notion (mit Local Backup)
  - Article → Obsidian (mit Google Drive Backup)
  - Code → Local + Obsidian
- ✅ Smart Storage Suggestions durch Content-Analyse
- ✅ Konflikt-Resolution bei mehreren Speicheroptionen
- ✅ Batch Operations mit selected storage targets
- ✅ Workflow-spezifische Storage-Präferenzen
- ✅ Auto-Sync und Backup-Konfiguration
- ✅ Import/Export der Storage-Einstellungen

**Key Classes & Enums**:
- `StorageTarget` - Verfügbare Speicherziele mit Icons und Verfügbarkeitsprüfung
- `ContentTypeStorageConfig` - Content-Type spezifische Konfiguration
- `StorageSuggestion` - Intelligente Speicher-Vorschläge mit Confidence-Scoring
- `StorageConflict` - Konflikt-Management zwischen Storage-Versionen
- `BatchStorageOperation` - Batch-Processing für mehrere Inhalte
- `ContentItem` - Strukturierte Inhalte für Storage-Operationen

### 2. ShortcutManager.swift
**Zweck**: Vollständige Shortcut- und Hotkey-Verwaltung mit macOS Integration

**Hauptfunktionen**:
- ✅ Global Shortcut Konfiguration:
  - Primary: ⌘⇧N (einstellbar)
  - Quick Capture: ⌃N
  - Summary Mode: ⌥N
  - Meeting Mode: ⇧N
  - Settings: ⌘, (einstellbar)
- ✅ Conflict Detection mit System-Shortcuts
- ✅ App-spezifische Shortcuts (für Popup)
- ✅ Voice Command Shortcuts (vorbereitet)
- ✅ Gesture Shortcuts (Trackpad-Gesten)
- ✅ Keyboard Shortcut Validation & Testing
- ✅ Import/Export für Backup
- ✅ macOS System Integration für Shortcut-Konflikte

**Key Classes & Enums**:
- `AppShortcut` - Definierte App-Shortcuts mit Kategorien
- `KeyCombo` - Tasten-Kombinationen mit Display-String
- `ShortcutCategory` - Kategorisierung (Primary, Quick, Mode, Settings, Navigation, Custom)
- `SystemShortcutConflict` - System-Konflikt-Erkennung
- `GestureShortcut` - Trackpad-Gesten für Quick-Actions
- `VoiceCommandShortcut` - Sprachbefehl-Integration

### 3. DefaultStorageSettingsView.swift
**Zweck**: Benutzerfreundliche UI für Storage-Konfiguration

**Features**:
- Übersichtliche Tab-Navigation für Einstellungsbereiche
- Primary & Secondary Storage Target Auswahl
- Content-Type spezifische Konfiguration mit Beschreibungen
- Workflow-Management mit aktivem Workflow-Tracking
- Batch-Operation Monitoring mit Progress-Tracking
- Intelligente Speicher-Vorschläge mit Confidence-Anzeige
- Import/Export-Funktionalität für Settings-Backup
- Add Workflow Dialog für benutzerdefinierte Workflows

### 4. ShortcutSettingsView.swift
**Zweck**: Intuitive UI für Shortcut-Management

**Features**:
- Kategorie-basierte Tab-Navigation (Primary, Quick, Mode, Settings, Navigation, Custom)
- Interactive Key Combo Capture mit Visual Feedback
- System-Conflict Detection mit Warnung-UI
- Conflict Resolver mit Lösungsempfehlungen
- Custom Shortcut Creation mit Validation
- Gesture & Voice Command Configuration
- Shortcut Testing Funktionalität
- Import/Export für Shortcut-Settings

## Integration in die App

### 1. In ContentView.swift einbinden

```swift
import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var storageManager = DefaultStorageManager()
    @StateObject private var shortcutManager = ShortcutManager()
    @StateObject private var contentAnalyzer = ContentAnalyzer()
    
    var body: some View {
        VStack {
            // Hauptinhalt
            
            // Settings Button mit Shortcuts
            Button("Einstellungen") {
                // Settings mit Shortcut Manager
                shortcutManager.triggerShortcut(byId: "open_settings")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        .sheet(isPresented: $showStorageSettings) {
            DefaultStorageSettingsView()
        }
        .sheet(isPresented: $showShortcutSettings) {
            ShortcutSettingsView()
        }
        .onAppear {
            setupShortcuts()
        }
    }
    
    private func setupShortcuts() {
        // Shortcut Actions registrieren
        shortcutManager.addCustomShortcut(
            name: "Toggle Settings",
            description: "Einstellungen ein-/ausblenden",
            keyCombo: KeyCombo(key: UInt16(kVK_ANSI_Space), modifiers: cmdKey | shiftKey)
        ) {
            // Toggle Settings Action
        }
    }
}
```

### 2. In SettingsView.swift erweitern

```swift
struct SettingsView: View {
    @StateObject private var storageManager = DefaultStorageManager()
    @StateObject private var shortcutManager = ShortcutManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // ... bestehende Einstellungen ...
            
            // Storage Einstellungen
            GroupBox("Speicherziele") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Primäres Ziel:")
                        Spacer()
                        Text(storageManager.primaryStorage.icon + " " + storageManager.primaryStorage.displayName)
                    }
                    
                    Button("Speicherziel-Verwaltung") {
                        // Öffne Storage Settings
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // Shortcut Einstellungen
            GroupBox("Tastatur-Shortcuts") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(shortcutManager.shortcuts.filter { $0.isEnabled }.prefix(3)) { shortcut in
                        HStack {
                            Text(shortcut.name)
                            Spacer()
                            Text(shortcut.keyCombo.displayString)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    
                    Button("Shortcut-Verwaltung") {
                        // Öffne Shortcut Settings
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
```

## Smart Features

### 1. Intelligente Storage-Suggestions

Der DefaultStorageManager analysiert Content automatisch:

```swift
// Beispiel: Smart Suggestions basierend auf Content
let suggestions = storageManager.suggestStorage(for: contentItem)

// Erwartete Suggestions:
[
    StorageSuggestion(target: .notion, confidence: 0.9, reason: "Meeting-Inhalte werden strukturiert in Notion gespeichert"),
    StorageSuggestion(target: .obsidian, confidence: 0.7, reason: "Inhalte mit Links eignen sich gut für Obsidian"),
    StorageSuggestion(target: .local, confidence: 0.8, reason: "Code-Blöcke sollten lokal gespeichert werden")
]
```

### 2. Content-Type automatische Erkennung

Das System nutzt den bestehenden `ContentTypeDetector` für intelligente Speicherziel-Zuordnung:

- **Email**: Apple Notes (strukturiert) + Dropbox (Backup)
- **Meeting**: Notion (Team-Kollaboration) + Local (Offline)
- **Article**: Obsidian (Markdown) + Google Drive (Sync)
- **Code**: Local (Performance) + Obsidian (Organisation)
- **Task**: Notion (Projektmanagement) + Apple Notes (Einfacher Zugriff)

### 3. Shortcut-Konflikt-Management

Automatische Erkennung und Lösung von Shortcut-Konflikten:

```swift
// SystemReserved Shortcuts
let systemReserved = [
    (KeyCombo(key: kVK_Space, modifiers: controlKey), "System: Spotlight"),
    (KeyCombo(key: kVK_Q, modifiers: cmdKey), "System: Quit App"),
    (KeyCombo(key: kVK_Tab, modifiers: cmdKey), "System: App Switcher")
]

// Automatische Alternativ-Vorschläge
func suggestAlternativeCombinations(for category: ShortcutCategory) -> [String] {
    switch category {
    case .primary: return ["⌘⌥N", "⌘⌃N", "⌘⇧⌥N"]
    case .quick: return ["⌃⇧N", "⌥⇧N", "⌃⌥N"]
    // ... weitere Kategorien
    }
}
```

## Workflow Management

### Benutzerdefinierte Workflows

Das System unterstützt Workflow-spezifische Speicherpräferenzen:

```swift
// Workflow definieren
storageManager.addWorkflowPreference("Work", config: ContentTypeStorageConfig(
    primary: .notion,
    secondary: .dropbox,
    autoSync: true,
    createBackup: true
))

// Workflow aktivieren
storageManager.setActiveWorkflow("Work")

// Workflow verwenden (automatisch bei Content-Type Speicherung)
let config = storageManager.getStorageConfig(for: .meeting)
```

## Batch Operations

```swift
// Batch Storage Operation
let items = [contentItem1, contentItem2, contentItem3]
let operationId = try await storageManager.batchStoreItems(items, to: .obsidian)

// Progress Monitoring
ForEach(storageManager.batchOperations) { operation in
    ProgressView(value: operation.progress)
    Text("\(operation.items.count) Elemente")
}
```

## Conflict Resolution

```swift
// Konflikt-Erkennung
let conflicts = storageManager.detectConflicts(for: item)

// Konflikt-Auflösung
try await storageManager.resolveConflict(conflict, using: .merge)
```

## Voice Commands & Gesture Integration

### Sprachbefehle

```swift
let voiceCommands = [
    VoiceCommandShortcut(trigger: "Neue Notiz", action: "primary_new_note"),
    VoiceCommandShortcut(trigger: "Meeting starten", action: "meeting_mode"),
    VoiceCommandShortcut(trigger: "Zusammenfassung", action: "summary_mode")
]
```

### Trackpad-Gesten

```swift
let gestureShortcuts = [
    GestureShortcut(name: "Quick Note", gestureType: .tapWithThreeFingers),
    GestureShortcut(name: "Meeting Mode", gestureType: .pinchWithThreeFingers)
]
```

## Import/Export

### Storage Settings

```swift
// Export
let settingsData = storageManager.exportStorageSettings()
try settingsData.write(to: fileURL)

// Import
let importedData = try Data(contentsOf: fileURL)
try storageManager.importStorageSettings(from: importedData)
```

### Shortcut Settings

```swift
// Export
let shortcutsData = shortcutManager.exportShortcuts()
try shortcutsData.write(to: fileURL)

// Import
let importedShortcuts = try Data(contentsOf: fileURL)
try shortcutManager.importShortcuts(from: importedShortcuts)
```

## System Integration

### macOS Permission Requirements

Für globale Shortcuts sind zusätzliche Berechtigungen erforderlich:

1. **Accessibility Permission** (für Event Tap)
2. **Input Monitoring Permission** (für Keyboard Events)

### App Delegate Integration

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // Initialize managers
    let storageManager = DefaultStorageManager()
    let shortcutManager = ShortcutManager()
    
    // Setup notification observers
    NotificationCenter.default.addObserver(
        forName: .shortcutTriggered,
        object: nil,
        queue: .main
    ) { notification in
        if let shortcut = notification.object as? AppShortcut {
            handleShortcut(shortcut)
        }
    }
}
```

## Performance Considerations

- **Event Tap**: Optimiert mit minimalen Events of Interest
- **Batch Operations**: Parallele Verarbeitung für bessere Performance
- **Smart Suggestions**: Caching der Content-Analyse für häufige Patterns
- **Conflict Detection**: Batched Detection um UI Blocking zu vermeiden

## Testing

```swift
// Shortcut Testing
func testAllShortcuts() {
    for shortcut in shortcutManager.shortcuts where shortcut.isEnabled {
        shortcutManager.triggerShortcut(shortcut)
        XCTAssertTrue(isActionTriggered(shortcut))
    }
}

// Storage Testing
func testBatchOperations() {
    let items = createTestItems()
    let operationId = try await storageManager.batchStoreItems(items, to: .local)
    
    // Wait for completion
    let operation = await waitForOperation(operationId)
    XCTAssertEqual(operation.status, .completed)
}
```

## Erweiterungsmöglichkeiten

1. **Machine Learning Integration**: Intelligente Shortcut-Empfehlungen basierend auf Nutzungsverhalten
2. **Cloud Sync**: Settings-Synchronisation zwischen Geräten
3. **Team Shortcuts**: Geteilte Shortcut-Konfigurationen
4. **Advanced Gesture Support**: Multi-Touch Gestures und Apple Pencil Integration
5. **Voice Command Training**: Personalisierte Spracherkennung
6. **Auto-Shortcut Learning**: Automatische Optimierung basierend auf Nutzungsstatistiken

## Fazit

Dieses umfassende System bietet eine professionelle, benutzerfreundliche und erweiterbare Lösung für App-Konfiguration mit:

- **Intelligente Automatisierung** durch Content-Analyse
- **Vollständige Shortcut-Kontrolle** mit macOS Integration
- **Flexible Workflow-Unterstützung** für verschiedene Nutzungsszenarien
- **Professionelle UI** mit intuitivem Design
- **Erweiterbares Framework** für zukünftige Features

Das System integriert sich nahtlos in die bestehende App-Architektur und bietet eine solide Basis für weitere Entwicklungen.