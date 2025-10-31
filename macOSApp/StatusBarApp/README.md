# StatusBarApp - macOS Menüleisten-Anwendung

Eine moderne macOS Menüleisten-Anwendung mit globaler Tastenkombination und erweiterten Funktionen.

## 🚀 Funktionen

### ✅ Implementierte Features

- **Menüleisten-Integration**: Vollständige NSStatusItem-Integration
- **Globale Tastenkombination**: ⌘⇧N für schnellen Zugriff
- **Symbol-Icon**: Moderne SF Symbols für die Menüleiste
- **Dropdown-Menü**: Mit Status-Anzeige und Einstellungen
- **SwiftUI-Integration**: Moderne UI-Komponenten
- **GlobalShortcutManager**: Erweiterte Tastenkombination-Verwaltung

### 📋 Menüleisten-Features

- **Status-Anzeige**: Zeigt aktuellen App-Status an
- **Ein-Klick-Status-Toggle**: Schnelle Status-Wechsel
- **Einstellungen**: Zugang zu App-Konfiguration
- **Über-Information**: App-Version und Details
- **Sauberes Beenden**: Graceful App-Shutdown

## 🛠️ Implementierung

### Core-Dateien

1. **AppDelegate.swift** - Haupt-App-Koordination
   - NSApplicationDelegate-Implementierung
   - Menüleisten-Icon Setup
   - App-Lifecycle-Management

2. **StatusBarController.swift** - Menüleisten-Verhalten
   - NSStatusItem-Management
   - Dropdown-Menü-Konfiguration
   - Status-Updates und UI-Interaktion

3. **GlobalShortcutManager.swift** - Tastenkombination
   - NSEvent.addGlobalMonitorForEvents
   - Konfigurierbare Shortcuts
   - Notification-basiertes Event-Handling

4. **StatusBarAppView.swift** - SwiftUI-Komponenten
   - Moderne UI-Views
   - Status-Anzeige-Widgets
   - Responsive Design

### 🔧 API-Verwendung

#### NSStatusItem-Setup
```swift
statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
statusItem?.button?.image = NSImage(systemSymbolName: "app.dashed", accessibilityDescription: "StatusBarApp")
```

#### Globale Tastenkombination
```swift
NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
    if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 45 {
        // Handle ⌘⇧N
    }
}
```

#### SF Symbols Integration
```swift
let symbolName = isRunning ? "checkmark.circle.fill" : "checkmark.circle"
button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Status")
```

## 🚀 Kompilierung und Ausführung

### Voraussetzungen
- macOS 10.15+
- Xcode 12+
- Swift 5.3+

### Build-Instruktionen
```bash
# Xcode-Projekt öffnen
open StatusBarApp.xcodeproj

# Oder mit xcodebuild kompilieren
xcodebuild -project StatusBarApp.xcodeproj -scheme StatusBarApp build
```

### App-Installation
1. Projekt in Xcode öffnen
2. Target auf "StatusBarApp" setzen
3. Build & Run (⌘R)
4. App wird in Menüleiste angezeigt

## 📝 Verwendung

### Menüleisten-Icon
- **Klick**: Dropdown-Menü öffnen/schließen
- **Status-Toggle**: Direkter Status-Wechsel

### Globale Tastenkombination
- **⌘⇧N**: Toggle Menüleisten-Menü (von überall)

### Menü-Optionen
- **Status**: Aktuelle App-Information anzeigen
- **Einstellungen**: App-Konfiguration öffnen
- **Über**: Versions-Information
- **Beenden**: App ordnungsgemäß schließen

## 🎯 Erweiterte Features

### Notification-System
- Observer-basierte Kommunikation
- Cross-Komponenten-Event-Handling
- Thread-sichere Event-Verarbeitung

### Status-Management
- Live-Status-Updates
- Zeitstempel-Tracking
- Icon-Status-Änderungen

### Cleanup-Mechanismen
- Memory-Management
- Observer-Bereinigung
- Graceful Shutdown

## 🔧 Anpassung

### Tastenkombination ändern
```swift
// In StatusBarController.swift
shortcutManager?.setupGlobalShortcut(shortcutKey: "s", modifierFlags: [.command, .control])
```

### Icon anpassen
```swift
// Symbol in setupStatusItemIcon() ändern
button.image = NSImage(systemSymbolName: "custom.icon", accessibilityDescription: "Custom")
```

### Menü-Items erweitern
```swift
// In createMenuItems() neue NSMenuItem hinzufügen
let newItem = NSMenuItem(title: "Custom Action", action: #selector(customAction(_:)), keyEquivalent: "")
statusMenu?.addItem(newItem)
```

## 🐛 Debugging

### Console-Output
Die App gibt detaillierte Debug-Informationen aus:
- App-Startup-Status
- Menüleisten-Icon-Setup
- Tastenkombination-Events
- Status-Änderungen

### Häufige Probleme
1. **Icon nicht sichtbar**: Prüfen der System-Berechtigungen
2. **Tastenkombination funktioniert nicht**: Andere Apps könnten Konflikte verursachen
3. **Menü öffnet sich nicht**: StatusItem-Konfiguration prüfen

## 📋 Nächste Schritte

- [ ] Benutzerdefinierte Tastenkombinationen
- [ ] Settings-Panel mit SwiftUI
- [ ] App-Icon-Anpassung
- [ ] Automatische Updates
- [ ] Apple Script-Integration
- [ ] Preferences-Persistenz

## 🏗️ Projektstruktur

```
StatusBarApp/
├── StatusBarApp/
│   ├── AppDelegate.swift          # Haupt-App-Controller
│   ├── StatusBarController.swift  # Menüleisten-Management
│   ├── GlobalShortcutManager.swift # Tastenkombinationen
│   ├── StatusBarAppView.swift     # SwiftUI-Komponenten
│   └── Info.plist                 # App-Konfiguration
└── README.md                      # Diese Datei
```

## 📄 Lizenz

MIT License - Siehe LICENSE-Datei für Details.

---

**Entwickelt mit Swift und modernen macOS APIs** 🚀