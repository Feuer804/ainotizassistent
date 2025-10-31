# AINotizassistent - macOS Menüleisten-App

Eine intelligente macOS-Menüleisten-App für die Aufnahme und Transkription von Notizen mit KI-Unterstützung.

## 📋 Überblick

Der AI Notizassistent ist eine moderne macOS-Anwendung, die in der Menüleiste läuft und es Benutzern ermöglicht:
- Sprachaufnahmen direkt aus der Menüleiste zu starten/stoppen
- Automatische Transkription von gesprochenen Wörtern
- Notizen zu erstellen und zu verwalten
- KI-gestützte Arbeitsabläufe

## 🚀 Features

- **Menüleisten-Integration**: Direkter Zugriff aus der macOS-Menüleiste
- **Sprachaufnahme**: Hochwertige Audio-Aufnahme mit verschiedenen Qualitätseinstellungen
- **Live-Transkription**: Echtzeit-Konvertierung von Sprache zu Text
- **Notizen-Verwaltung**: Intelligente Notizen mit Zeitstempel und Quelle
- **Benutzereinstellungen**: Umfangreiche Konfigurationsmöglichkeiten
- **macOS Catalina (10.15)+ Kompatibilität**: Optimiert für die neuesten macOS-Versionen

## 📦 Systemanforderungen

- **Betriebssystem**: macOS 10.15 (Catalina) oder höher
- **Xcode**: 15.0 oder höher
- **Swift**: 5.0+
- **Berechtigungen**:
  - Accessibility-Zugriff
  - Screen Recording-Berechtigung
  - Mikrofon-Zugriff

## 🔧 Build-Anweisungen

### Voraussetzungen installieren

1. **Xcode installieren**:
   ```bash
   # Über den Mac App Store
   # Oder von der Apple Developer Website herunterladen
   ```

2. **macOS Command Line Tools**:
   ```bash
   xcode-select --install
   ```

### Projekt klonen und öffnen

1. **Repository klonen** (falls nicht bereits vorhanden):
   ```bash
   git clone <repository-url>
   cd AINotizassistent
   ```

2. **Xcode-Projekt öffnen**:
   ```bash
   open AINotizassistent.xcodeproj
   ```

### Build-Konfiguration

1. **Development Team einrichten**:
   - Xcode > AINotizassistent Target > Signing & Capabilities
   - Team auswählen oder "Add Account" verwenden
   - Bundle Identifier anpassen (z.B. `com.ihrfirma.notizassistent`)

2. **Code-Signing**:
   - "Automatically manage signing" aktivieren
   - Provisioning Profile wird automatisch erstellt

3. **Build-Schema** auswählen:
   - "AINotizassistent" als Target
   - macOS als Destination

### Build ausführen

#### Debug-Build
```bash
# In Xcode: Product > Run (⌘+R)
# Oder über die Kommandozeile:
xcodebuild -project AINotizassistent.xcodeproj -scheme AINotizassistent -configuration Debug build
```

#### Release-Build
```bash
# In Xcode: Product > Archive
# Oder über die Kommandozeile:
xcodebuild -project AINotizassistent.xcodeproj -scheme AINotizassistent -configuration Release build
```

### App-Installation

1. **Build aus Xcode**:
   - Product > Run (⌘+R) zum Testen
   - Product > Archive zum Erstellen der distribuierten App

2. **Manuelle Installation**:
   ```bash
   # Kopiere die App in das Applications-Verzeichnis
   cp -R build/Release/AINotizassistent.app /Applications/
   ```

## 🔐 Berechtigungen konfigurieren

### Runtime-Berechtigungen

Beim ersten Start der App müssen folgende Berechtigungen erteilt werden:

1. **Mikrofon-Zugriff**:
   - Systemeinstellungen > Datenschutz & Sicherheit > Mikrofon
   - "AINotizassistent" aktivieren

2. **Screen Recording**:
   - Systemeinstellungen > Datenschutz & Sicherheit > Screen Recording
   - "AINotizassistent" aktivieren

3. **Accessibility**:
   - Systemeinstellungen > Datenschutz & Sicherheit > Accessibility
   - "AINotizassistent" aktivieren

### Entwickler-Signatur (für erweiterte Features)

Für die Nutzung aller Features muss die App mit einer Developer-ID signiert sein:

```bash
# Codesign mit Developer-ID
codesign --deep --force --options runtime --entitlements AINotizassistent/AINotizassistent.entitlements --sign "Developer ID Application: Your Name (TEAMID)" AINotizassistent.app
```

## 🏗️ Projektstruktur

```
AINotizassistent/
├── AINotizassistent.xcodeproj/          # Xcode-Projektdatei
│   └── project.pbxproj
├── AINotizassistent/                     # Haupt-App-Bundle
│   ├── AINotizassistentApp.swift         # Haupt-App-Einstiegspunkt
│   ├── ContentView.swift                 # Hauptbenutzeroberfläche
│   ├── AppDelegate.swift                 # macOS App-Delegat & Menüleisten-Integration
│   ├── Note.swift                        # Datenmodell für Notizen
│   ├── NoteCardView.swift                # Notizen-Anzeige-Komponente
│   ├── SettingsView.swift                # Einstellungen-Interface
│   ├── Info.plist                        # App-Konfiguration & Berechtigungen
│   ├── AINotizassistent.entitlements     # App-Berechtigungen
│   └── Assets.xcassets/                  # Bilder und Icons
└── README.md                             # Diese Datei
```

## 🔧 Entwicklung

### Abhängigkeiten

Das Projekt verwendet nur native macOS-Frameworks:
- **SwiftUI**: Moderne Benutzeroberfläche
- **AppKit**: macOS-spezifische Integration
- **AVFoundation**: Audio-Aufnahme und -Verarbeitung

### Code-Anpassungen

#### Bundle-ID ändern
1. Xcode > Project Navigator > AINotizassistent
2. Target > General > Identity > Bundle Identifier

#### App-Name anpassen
1. `AINotizassistentApp.swift`: `CFBundleDisplayName` in Info.plist
2. `ContentView.swift`: Titel in der Benutzeroberfläche

#### Neue Features hinzufügen
- **Sprachmodelle**: `ContentViewModel.swift` erweitern
- **Benutzeroberfläche**: `ContentView.swift` anpassen
- **App-Verhalten**: `AppDelegate.swift` modifizieren

### Testing

```bash
# Unit Tests ausführen
xcodebuild test -project AINotizassistent.xcodeproj -scheme AINotizassistent

# UI Tests ausführen
xcodebuild test -project AINotizassistent.xcodeproj -scheme AINotizassistent -only-testing:AINotizassistentUITests
```

## 📱 Verteilung

### App Store Distribution

1. **Archive erstellen**:
   - Product > Archive in Xcode
   - Organizer öffnet sich automatisch

2. **App Store Connect**:
   - App über Xcode oder Application Loader hochladen
   - Metadaten in App Store Connect vervollständigen

### Developer-ID Distribution

```bash
# Developer-ID Signierung
codesign --deep --force --options runtime --sign "Developer ID Application: Your Name (TEAMID)" AINotizassistent.app

# Notarization
xcrun notarytool submit AINotizassistent.app --apple-id your-apple-id --team-id TEAMID --password app-specific-password

# Staple Ticket
xcrun stapler staple AINotizassistent.app
```

## 🐛 Troubleshooting

### Häufige Build-Fehler

1. **"Code signing failed"**:
   - Development Team in Xcode konfigurieren
   - Provisioning Profile erstellen/erneuern

2. **"Swift compiler error"**:
   - Xcode auf neueste Version aktualisieren
   - Swift-Version in Build Settings prüfen

3. **"Runtime issues"**:
   - macOS Version-Kompatibilität prüfen
   - Berechtigungen in Info.plist validieren

### Berechtigungsprobleme

1. **"Microphone access denied"**:
   - Systemeinstellungen > Datenschutz > Mikrofon prüfen
   - App neu starten nach Berechtigungsänderung

2. **"Accessibility access denied"**:
   - Accessibility-Berechtigung in Systemeinstellungen prüfen
   - System-Login nach Änderung möglicherweise erforderlich

## 📄 Lizenz

Copyright © 2025 AI Notizassistent Team. Alle Rechte vorbehalten.

## 👥 Kontakt

- **Entwicklungsteam**: AI Notizassistent Team
- **Support**: [Support-E-Mail]
- **Website**: [Projekt-Website]

---

**Entwickelt mit ❤️ für macOS**