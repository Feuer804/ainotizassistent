# Apple Notes Integration für AINotizassistent

Eine umfassende Integration der Apple Notes App mit erweiterten Features für Notiz-Management, Synchronisation und Rich Text Support.

## 🏗️ Architektur

### Hauptkomponenten

1. **NotesIntegration.swift** - Zentrale Verwaltungsklasse
2. **NotesView.swift** - Haupt-Benutzeroberfläche
3. **ShortcutsManager.swift** - Shortcuts App Integration
4. **AppleScriptManager.swift** - macOS Fallback-Lösung
5. **SpotlightManager.swift** - Spotlight Suche-Integration
6. **RichTextConverter.swift** - Markdown ↔ Apple Notes Format
7. **ImageProcessor.swift** - Bildoptimierung für Attachments
8. **NotesIntegrationApp.swift** - App-spezifische Integration

## 🚀 Features

### ✅ Implementierte Features

- [x] **Notes Integration Manager** - Zentrale Verwaltung aller Apple Notes Funktionen
- [x] **Shortcuts App Integration** - Automatisierte Notiz-Operationen über Shortcuts
- [x] **Neue Notiz erstellen** - Mit Content, Tags und Kategorien
- [x] **Bestehende Notizen aktualisieren** - Mit Sync-Funktionalität
- [x] **Kategorien und Ordner Management** - Organisiere Notizen in Kategorien
- [x] **Spotlight Integration** - Schnelle Notiz-Suche über Spotlight
- [x] **Rich Text Support** - Markdown zu Apple Notes Format Konvertierung
- [x] **Bild und Attachment Support** - Automatische Bildoptimierung für Notes
- [x] **Notiz teilen** - iCloud Link, E-Mail und Copy-to-Clipboard
- [x] **AppleScript Integration** - Fallback für erweiterte macOS Features
- [x] **Error Handling** - Robuste Fehlerbehandlung für Offline/Online Szenarien
- [x] **Privacy Controls** - Lokale-only Storage Optionen

### 🎯 Zusätzliche Features

- [x] **Batch Operations** - Mehrere Notizen gleichzeitig verarbeiten
- [x] **Format Detection** - Automatische Erkennung von Textformaten
- [x] **Metadata Management** - Erweiterte Metadaten für Notizen
- [x] **Progressive Enhancement** - Graduelle Feature-Enablement basierend auf Plattform
- [x] **Deep Link Support** - URLs für direkte Notiz-Aktionen
- [x] **Search Filters** - Erweiterte Suchfilter nach Kategorien und Tags
- [x] **Image Categorization** - Automatische Kategorisierung von Bildern
- [x] **Export to Markdown** - Export von Notizen als Markdown-Dateien

## 📱 Plattform-Unterstützung

### iOS (15.0+)
- **Primary Integration**: Shortcuts App
- **Secondary**: URL Schemes
- **Features**: Spotlight, Rich Text, Images, Sharing

### macOS (12.0+)
- **Primary Integration**: AppleScript
- **Secondary**: Shortcuts (Catalina+)
- **Features**: Spotlight, Rich Text, Images, Advanced Sharing

## 🔧 Setup und Konfiguration

### 1. Shortcuts App Setup (iOS/Catalina+)

**Erstelle diese Shortcuts in der Shortcuts App:**

#### Shortcut: "CreateNote"
```
1. Get Variable: Shortcut Input
2. Ask for Input: Note Title
3. Ask for Input: Note Content
4. Ask for Input: Note Tags
5. Ask for Input: Note Category
6. Run Apple Script:
   tell application "Notes"
       make new note with properties {body:Content, name:Title}
   end tell
   return "SUCCESS:Note Created"
```

#### Shortcut: "GetAllNotes"
```
1. Run Apple Script:
   tell application "Notes"
       set allNotes to name of every note
       return allNotes as string
   end tell
   return "SUCCESS"
```

#### Shortcut: "SearchNotes"
```
1. Get Variable: Shortcut Input
2. Ask for Input: Search Query
3. Run Apple Script:
   tell application "Notes"
       set searchResults to every note whose body contains Search Query
       return name of searchResults as string
   end tell
   return "SUCCESS"
```

### 2. Berechtigungen aktivieren

#### macOS
1. Systemeinstellungen → Datenschutz & Sicherheit
2. AppleScript → AINotizassistent erlauben
3. Notizen → AINotizassistent erlauben

#### iOS
1. Einstellungen → Notes Integration
2. Shortcuts App-Berechtigung aktivieren
3. Notes App-Synchronisation aktivieren

## 💻 Verwendung

### Grundlegende Nutzung

```swift
// Notes Integration initialisieren
let notesIntegration = NotesIntegration()

// Neue Notiz erstellen
let note = try await notesIntegration.createNote(
    title: "Meine wichtige Notiz",
    content: "# Wichtige Informationen\\n\\nDies ist der Inhalt...",
    tags: ["wichtig", "arbeit"],
    category: "Work"
)

// Bestehende Notiz aktualisieren
try await notesIntegration.updateNote(
    note,
    title: "Neuer Titel",
    content: "Neuer Inhalt",
    tags: ["neue-tags"],
    category: "Personal"
)
```

### Suchfunktionen

```swift
// Spotlight-Suche
let results = try await notesIntegration.searchNotes("Arbeitsplanung", spotlight: true)

// Kategorien-Suche
let workNotes = try await notesIntegration.getNotes(in: "Work")

// Erweiterte Filterung
let filtered = try await notesIntegration.searchWithMetadataFilters(filters: .init(
    categories: ["Work", "Personal"],
    requiredTags: ["wichtig"],
    startDate: Date().addingTimeInterval(-86400), // Letzten 24h
    endDate: Date()
))
```

### Rich Text Konvertierung

```swift
let converter = RichTextConverter()

// Markdown zu Apple Notes
let notesFormat = converter.markdownToAppleNotesFormat("""
# Header
**Bold text** *italic*
- List item
""")

// Apple Notes zu Markdown
let markdown = converter.appleNotesFormatToMarkdown(notesFormat)
```

### Bildverarbeitung

```swift
// Bild für Notes optimieren
let optimizedData = try await ImageProcessor.optimizeImageForNotes(
    originalImageData,
    filename: "screenshot.png"
)

// Attachments erstellen
let attachment = try await ImageProcessor.createAttachmentForNotes(
    from: imageData,
    filename: "photo.jpg"
)
```

## 🎨 Benutzeroberfläche

### NotesView Hauptfunktionen

- **Such- und Filterbereich** - Schnelle Suche und Kategorien-Filter
- **Quick Actions** - Neue Notiz, Sync, Kategorien, Suche
- **Notes Liste** - Übersichtliche Anzeige aller synchronisierten Notizen
- **Detail-Ansicht** - Vollständige Bearbeitung von Notizen
- **Sharing** - Verschiedene Teilen-Optionen
- **Sync Status** - Echtzeit-Anzeige des Synchronisationsstatus

### Integration in bestehende App

```swift
// In ContentView.swift
import AppleNotesIntegration

struct ContentView: View {
    var body: some View {
        TabView {
            // Bestehende Tabs...
            
            if #available(iOS 15.0, *) {
                NotesView()
                    .tabItem {
                        Image(systemName: "note.text")
                        Text("Notes")
                    }
            }
        }
    }
}
```

## 🔍 Error Handling

### Fehlerbehandlung

```swift
do {
    try await notesIntegration.createNote(title: "Test", content: "Content")
} catch NotesError.permissionDenied {
    print("Zugriff verweigert - berechtigung erforderlich")
} catch NotesError.syncFailed(let underlyingError) {
    print("Sync fehlgeschlagen: \(underlyingError.localizedDescription)")
} catch NotesError.noteNotFound {
    print("Notiz nicht gefunden")
} catch {
    print("Unbekannter Fehler: \(error)")
}
```

### Offline/Online Handling

```swift
// Lokale Notizen erstellen (Offline)
let localNote = notesIntegration.createLocalNote(appNoteModel)

// Später synchronisieren
try await notesIntegration.syncLocalNotes()
```

## 📋 Testing

### Unit Tests

```swift
func testRichTextConversion() {
    let converter = RichTextConverter()
    let markdown = "# Test Header\\n\\n**Bold text**"
    let notesFormat = converter.markdownToAppleNotesFormat(markdown)
    
    XCTAssertTrue(notesFormat.contains("Test Header"))
    XCTAssertTrue(notesFormat.contains("Bold:"))
}

func testImageOptimization() {
    let testImageData = ... // Test image data
    let optimized = try await ImageProcessor.optimizeImageForNotes(testImageData, filename: "test.png")
    
    XCTAssertLessThan(optimized.count, testImageData.count)
}
```

## 🚀 Performance Optimierungen

### Batch Operations

```swift
// Mehrere Notizen gleichzeitig erstellen
let attachments = try await ImageProcessor.processMultipleImages([(data1, "img1.png"), (data2, "img2.png")])

// Batch Synchronisation
let syncResult = try await notesIntegration.syncWithAppleNotes()
```

### Caching

- Spotlight-Ergebnisse werden gecacht
- Kategorien-Liste wird lokal gespeichert
- Konvertierte Rich Text Format wird zwischengepuffert

## 🔒 Privacy und Sicherheit

### Lokale Storage Optionen

```swift
// Nur lokale Notizen verwenden
let localNote = notesIntegration.createLocalNote(noteModel)
```

### Berechtigungen

- **Notes App**: Nur Lese-/Schreibrechte
- **Shortcuts**: Nur erforderliche Aktionen
- **AppleScript**: Nur für Notes-Operationen

## 📈 Erweiterungen und Roadmap

### Geplante Features

- [ ] **Voice-to-Text Integration** - Sprachnotizen in Apple Notes
- [ ] **AI-Summarization** - Automatische Notiz-Zusammenfassungen
- [ ] **Collaborative Editing** - Echtzeit-Kollaboration über iCloud
- [ ] **Advanced Templates** - Vorlagen für verschiedene Notiz-Typen
- [ ] **Cross-Platform Sync** - iPhone ↔ iPad ↔ Mac Synchronisation
- [ ] **Version History** - Versionshistorie für Notizen
- [ ] **Encrypted Sync** - End-zu-End Verschlüsselung

### Plugin Architecture

Die Integration ist erweiterbar über ein Plugin-System:

```swift
protocol NotesPlugin {
    func processNote(_ note: AppleNotesNote) async throws -> AppleNotesNote
    func getCapabilities() -> [PluginCapability]
}

class RichTextPlugin: NotesPlugin {
    func processNote(_ note: AppleNotesNote) async throws -> AppleNotesNote {
        // Erweiterte Rich Text Verarbeitung
        return note
    }
}
```

## 🛠️ Debugging und Troubleshooting

### Log-Level

```swift
// Detailliertes Logging aktivieren
NotesIntegrationManager.shared.logger.logLevel = .debug
```

### Häufige Probleme

1. **"Permission Denied"**
   - Prüfe Notes App-Berechtigungen
   - Aktiviere AppleScript (macOS)

2. **"Shortcuts not found"**
   - Erstelle erforderliche Shortcuts
   - Prüfe Shortcuts-Namen

3. **"Sync failed"**
   - Prüfe Internetverbindung
   - Logs prüfen für Details

## 📚 API Referenz

### Hauptklassen

- **NotesIntegration**: Zentrale Verwaltung
- **ShortcutsManager**: Shortcuts App Integration
- **AppleScriptManager**: macOS AppleScript Fallback
- **SpotlightManager**: Spotlight Suche
- **RichTextConverter**: Format-Konvertierung
- **ImageProcessor**: Bildverarbeitung

### Erweiterte Typen

- **AppleNotesNote**: Notiz-Datenstruktur
- **AppleNotesCategory**: Kategorie-Management
- **SyncResult**: Synchronisationsergebnis
- **ShareMethod**: Teilen-Optionen

---

*Erstellt für AINotizassistent - Version 1.0*