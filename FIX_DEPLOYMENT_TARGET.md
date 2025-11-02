# Behebung: Exit Code 65 - macOS Version Konflikt

## Problem
Ihr Xcode-Projekt ist auf **macOS 10.15** konfiguriert, verwendet aber Code-Features die **macOS 11.0+** erfordern.

## Lösung: Deployment Target erhöhen

### Option 1: In Xcode (Empfohlen)

1. **Öffnen Sie das Projekt** in Xcode:
   ```bash
   open AINotizassistent/AINotizassistent.xcodeproj
   ```

2. **Wählen Sie das Projekt** im Navigator (linke Sidebar)

3. **Wählen Sie das Target** "AINotizassistent"

4. **General Tab**:
   - Finden Sie "Minimum Deployments"
   - Ändern Sie "macOS" von `10.15` auf **`13.0`**

5. **Build Settings Tab**:
   - Suchen Sie nach "macOS Deployment Target"
   - Ändern Sie alle Werte von `10.15` auf **`13.0`**

6. **Speichern** (Cmd+S)

7. **Commit & Push**:
   ```bash
   cd AINotizassistent
   git add AINotizassistent.xcodeproj/project.pbxproj
   git commit -m "FIX: Update macOS Deployment Target to 13.0"
   git push
   ```

### Option 2: Direkte Dateibearbeitung

Falls Sie kein Xcode haben, können Sie die Datei manuell bearbeiten:

1. Öffnen Sie in einem Texteditor:
   ```
   AINotizassistent/AINotizassistent.xcodeproj/project.pbxproj
   ```

2. Suchen Sie **alle Vorkommen** von:
   ```
   MACOSX_DEPLOYMENT_TARGET = 10.15;
   ```

3. Ersetzen Sie **alle** durch:
   ```
   MACOSX_DEPLOYMENT_TARGET = 13.0;
   ```

4. Speichern und committen:
   ```bash
   cd AINotizassistent
   git add AINotizassistent.xcodeproj/project.pbxproj
   git commit -m "FIX: Update macOS Deployment Target to 13.0"
   git push
   ```

## Warum macOS 13.0?

Ihr Code verwendet folgende Features:
- `@main`, `WindowGroup`, `StateObject` → erfordern macOS 11.0+
- `windowResizability` → erfordert macOS 13.0+

**macOS 13.0** ist die sicherste Wahl für alle Features.

## Zusätzliche Probleme (optional)

Ihr Code referenziert fehlende Dateien. Diese Fehler könnten nach der Deployment-Target-Änderung auftreten:

```swift
// Fehlen:
- AnimationManager
- MicroInteractionManager  
- ScreenTransitionManager
- LoadingAnimationManager
- Note (Datenmodell)
- NoteCardView
- SettingsView
- AnimationDemoView
```

**Entweder**:
- Erstellen Sie diese Dateien in Xcode
- **ODER** entfernen Sie die Referenzen aus `AINotizassistentApp.swift` und `ContentView.swift`

## Nach der Änderung

Der GitHub Actions Build sollte erfolgreich sein!
