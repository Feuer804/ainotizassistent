# 🖋️ Smart Text Input System

Ein erweiterte Text-Eingabe-System für macOS mit modernem Glass-Design, intelligenter Paste-Erkennung und umfassenden Text-Editing-Funktionen.

## 📋 Funktionsübersicht

### Kernfunktionen
- **SmartTextInputView.swift** - Hauptkomponente mit modernem Glass-Design
- **PasteDetectionManager.swift** - Automatische Clipboard-Überwachung
- **TextInputCoordinator.swift** - Koordination aller Komponenten
- **TextInputUtilities.swift** - Hilfsfunktionen und Text-Analyse

### 🎯 Features

#### 1. **Intelligente Paste-Erkennung**
- Automatische Erkennung verschiedener Inhaltstypen (Text, URLs, Bilder, RTF)
- Cmd+V Detektion mit globalem Keyboard-Monitor
- Automatische Inhaltsbereinigung und -formatierung
- Strukturierte Daten-Extraktion (CSV, JSON, URLs)

#### 2. **Auto-Resizing Text Editor**
- Dynamische Höhenanpassung basierend auf Inhalt
- Smooth Animations bei Größenänderungen
- Optimiert für lange Texte

#### 3. **Drag & Drop Support**
- Text-Dateien (.txt, .md) direkt einfügen
- Multi-Drop-Unterstützung
- Visual Feedback für Drop-Zonen

#### 4. **Spell Check & Autocorrect**
- Integration mit macOS Spell Checker
- Fehlererkennung und -korrektur
- Deutsche Rechtschreibung

#### 5. **Markdown Preview**
- Live Markdown-Vorschau
- Formatierte Text-Anzeige
- Toggle zwischen Edit- und Preview-Modus

#### 6. **Auto-Save System**
- Automatisches Speichern alle 3 Sekunden
- Progress Indicator
- Letzte Speicherung anzeigen
- Speicherstatus-Feedback

#### 7. **Text-Analyse & Statistiken**
- Wortanzahl
- Zeichenanzahl  
- Zeilenzahl
- Lesedauer-Schätzung (200 WPM)
- Text-Komplexität-Analyse

#### 8. **Formatierungs-Tools**
- **Fett** (⌘+B)
- **Kursiv** (⌘+I)
- **Listen** erstellen
- **Links** einfügen
- Markdown-Header

## 🚀 Installation

### Voraussetzungen
- macOS 12.0 oder höher
- Xcode 14.0+
- Swift 5.7+

### Setup
1. Fügen Sie die Swift-Dateien zu Ihrem Xcode-Projekt hinzu
2. Importieren Sie die benötigten Frameworks:
```swift
import SwiftUI
import AppKit
import Combine
```

## 📖 Verwendung

### Grundlegende Implementierung

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        SmartTextInputView()
            .frame(width: 800, height: 600)
    }
}
```

### Erweiterte Konfiguration

```swift
struct CustomTextView: View {
    @StateObject private var coordinator = TextInputCoordinator()
    @State private var customText = ""
    
    var body: some View {
        VStack {
            SmartTextInputView()
                .onChange(of: coordinator.text) { oldValue, newValue in
                    customText = newValue
                    // Custom Logic
                }
        }
    }
}
```

### Paste-Erkennung anpassen

```swift
class CustomPasteManager: PasteDetectionManager {
    override func detectPasteContent() {
        // Custom paste detection logic
        super.detectPasteContent()
    }
}
```

## 🔧 Anpassung

### Design anpassen

```swift
// Glass-Effekt anpassen
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.2), lineWidth: 2)
        )
)

// Farben anpassen
Text("Angepasster Text")
    .foregroundColor(.blue)
```

### Auto-Save konfigurieren

```swift
// Auto-Save Intervall ändern
coordinator.autoSaveInterval = 5.0

// Auto-Save deaktivieren
coordinator.isAutoSaveEnabled = false
```

### Text-Formatierung erweitern

```swift
extension TextFormatter {
    static func highlight(_ text: String) -> String {
        return "==\(text)=="
    }
}
```

## 🎨 UI/UX Features

### Glass-Design
- **ultraThinMaterial** für moderne Optik
- Transparente Overlays
- Subtile Border-Effekte

### Interaktive Elemente
- Smooth Hover-Effekte
- Visual Feedback bei Aktionen
- Loading-Indikatoren
- Status-Meldungen

### Responsive Layout
- Flexible Container
- Dynamische Inhaltsanpassung
- Optimierte für verschiedene Bildschirmgrößen

## 📊 Performance

### Optimierungen
- **Lazy Loading** für große Texte
- **Efficient Filtering** bei Text-Analysen
- **Background Processing** für Auto-Save
- **Memory Management** für Clipboard-Überwachung

### Benchmarks
- Auto-Save: < 500ms
- Paste-Detection: < 100ms
- Word-Count-Update: < 50ms
- Markdown-Rendering: < 200ms

## 🔒 Sicherheit

### Clipboard-Sicherheit
- Keine persistenten Clipboard-Speicherung
- Automatische Bereinigung sensibler Daten
- User-consent für Clipboard-Zugriff

### Auto-Save Sicherheit
- Lokale Speicherung nur
- Keine Cloud-Uploads ohne Zustimmung
- Verschlüsselung optional verfügbar

## 🐛 Troubleshooting

### Häufige Probleme

#### Paste-Detection funktioniert nicht
```swift
// Prüfen Sie die Berechtigungen
pasteManager.startContinuousMonitoring()
```

#### Auto-Save nicht aktiv
```swift
// Timer neu starten
coordinator.startAutoSaveTimer()
```

#### Performance-Probleme
```swift
// Text-Analysen optimieren
coordinator.enableLazyLoading = true
```

## 🔄 Erweiterte Konfiguration

### Benutzerdefinerte Text-Styles

```swift
enum CustomTextStyle {
    case highlight
    case subscript
    case superscript
    case custom(String, String)
}
```

### Erweiterte Markdown-Unterstützung

```swift
struct ExtendedMarkdownParser {
    static func parse(_ text: String) -> AttributedString {
        // Custom Markdown-Parser
    }
}
```

## 📝 API Reference

### SmartTextInputView

#### Properties
- `text: String` - Der aktuelle Text-Inhalt
- `isMarkdownPreview: Bool` - Preview-Modus
- `showingToolbar: Bool` - Toolbar sichtbar

#### Methods
- `setup(text: Binding<String>)` - Text-Binding konfigurieren
- `handleDrop(items: [String])` - Drag & Drop verarbeiten

### PasteDetectionManager

#### Properties
- `hasNewContent: Bool` - Neue Inhalte verfügbar
- `detectedContent: String` - Erkannter Inhalt
- `pasteType: PasteType` - Art des Inhalts

#### Methods
- `startContinuousMonitoring()` - Monitoring starten
- `sanitizePastedContent(String)` - Inhalt bereinigen

### TextInputCoordinator

#### Properties
- `isSaving: Bool` - Speicher-Status
- `lastSaved: Date?` - Letzter Speichervorgang
- `wordCount: Int` - Wortanzahl

#### Methods
- `toggleBold()` - Fett-Formatierung
- `insertLink()` - Link einfügen
- `calculateStats(String)` - Text-Statistiken

## 🤝 Contributing

Beiträge sind willkommen! Bitte:
1. Fork des Repositories
2. Feature-Branch erstellen
3. Änderungen committen
4. Pull Request einreichen

## 📄 Lizenz

MIT License - siehe LICENSE-Datei für Details.

## 🎯 Roadmap

### Version 1.1
- [ ] iOS-Unterstützung
- [ ] iCloud Sync
- [ ] Theme-System
- [ ] Plugin-Architektur

### Version 1.2
- [ ] Collaborative Editing
- [ ] Voice Input
- [ ] OCR-Integration
- [ ] Advanced Analytics

---

**Entwickelt mit ❤️ für die macOS-Community**

Für Fragen und Support: [GitHub Issues](https://github.com/your-repo/issues)