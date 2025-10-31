# macOS-Version Kompatibilität - Implementierungsanleitung

## Überblick

Diese Anleitung beschreibt die Integration der macOS-Version-Kompatibilitätslösung in ein bestehendes macOS-Projekt.

## Schnellstart

### 1. Dateien in Projekt einbinden

```swift
// Dateien zu Ihrem Xcode-Projekt hinzufügen:
- CompatibilityManager.swift
- macOSVersionChecker.swift
- macOSUIAdaptation.swift
- macOSCompatibilityTests.swift
```

### 2. Info.plist erweitern

```xml
<!-- Zusätzliche Berechtigungen für verschiedene macOS-Versionen -->
<key>com.apple.security.automation.apple-events</key>
<true/>
<key>com.apple.security.automation.shortcuts</key>
<true/>
<key>com.apple.security.accessibility</key>
<true/>
<key>com.apple.security.app-sandbox</key>
<true/>
```

## Integration in bestehenden Code

### 1. In der AppDelegate.swift

```swift
import SwiftUI
import CompatibilityManager

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize compatibility system
        initializeCompatibility()
        
        // Configure features based on version
        configureVersionSpecificFeatures()
        
        // Set up UI adaptation
        setupUIAdaptation()
    }
    
    private func initializeCompatibility() {
        // CompatibilityManager wird automatisch initialisiert
        let version = CompatibilityManager.shared.version
        print("macOS Version erkannt: \(version?.name ?? "Unbekannt")")
    }
    
    private func configureVersionSpecificFeatures() {
        let manager = CompatibilityManager.shared
        let version = manager.version ?? .catalina
        
        switch version {
        case .catalina:
            configureCatalinaFeatures()
        case .bigSur:
            configureBigSurFeatures()
        case .monterey:
            configureMontereyFeatures()
        case .ventura:
            configureVenturaFeatures()
        case .sonoma:
            configureSonomaFeatures()
        case .sequoia:
            configureSequoiaFeatures()
        }
    }
    
    private func configureCatalinaFeatures() {
        // Grundfunktionen ohne Shortcuts oder Glaseffekte
        print("Konfiguriere Catalina-Features")
        enableBasicVoiceFeatures()
        enableNotesIntegration()
    }
    
    private func configureBigSurFeatures() {
        // Kurze Feature-Enable-Logik
        enableShortcutsIntegration()
        enableModernUI()
    }
    
    private func configureMontereyFeatures() {
        enableEnhancedVoice()
        enableLiveText()
    }
    
    private func configureVenturaFeatures() {
        enableAdvancedShortcuts()
        enableStageManager()
    }
    
    private func configureSonomaFeatures() {
        enableGlassEffects()
        enableInteractiveWidgets()
    }
    
    private func configureSequoiaFeatures() {
        // Neueste Features
        enableAdvancedFeatures()
    }
    
    private func setupUIAdaptation() {
        let uiManager = macOSUIAdaptationManager.shared
        // UI-Anpassung wird automatisch gehandhabt
    }
}
```

### 2. In ContentView.swift integrieren

```swift
import SwiftUI
import CompatibilityManager
import macOSUIAdaptation

struct ContentView: View {
    @State private var versionInfo: macOSVersion?
    @State private var supportedFeatures: Set<FeatureSupport> = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Version Display
            versionDisplay
            
            // Feature Support Status
            featureStatusDisplay
            
            // Adapted UI Components
            adaptedUIContent
            
            // Diagnostics Button
            Button("Diagnose erstellen") {
                showDiagnostics()
            }
            .buttonStyle(macOSUIAdaptationManager.shared.getButtonStyle())
        }
        .padding()
        .frame(width: 500, height: 400)
        .onAppear {
            setupCompatibilityMonitoring()
        }
    }
    
    private var versionDisplay: some View {
        Group {
            if let version = versionInfo {
                VStack {
                    Text("macOS Version: \(version.name)")
                        .font(.headline)
                    Text("Version: \(version.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Version wird erkannt...")
            }
        }
    }
    
    private var featureStatusDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unterstützte Features:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                FeatureRow(title: "Shortcuts Integration", supported: supportedFeatures.contains(.shortcutsIntegration))
                FeatureRow(title: "Glaseffekte", supported: supportedFeatures.contains(.glassEffects))
                FeatureRow(title: "Erweiterte Sprachfeatures", supported: supportedFeatures.contains(.enhancedVoice))
                FeatureRow(title: "Moderne UI", supported: supportedFeatures.contains(.modernUI))
            }
        }
    }
    
    private var adaptedUIContent: some View {
        Group {
            // Version-spezifische UI-Inhalte
            if versionInfo == .sonoma || versionInfo == .sequoia {
                VStack {
                    Text("Erweiterte UI-Komponenten")
                        .font(.title)
                    
                    // Glass Card - nur auf Sonoma+
                    VStack {
                        Text("Glass Card")
                        Text("Verfügbar auf Sonoma+")
                            .font(.caption)
                    }
                    .modifier(macOSUIAdaptationManager.shared.getCardStyle())
                }
            } else {
                VStack {
                    Text("Standard UI-Komponenten")
                        .font(.title)
                    
                    Text("Vollständige Funktionalität auf älteren Versionen")
                        .font(.caption)
                }
            }
        }
    }
    
    private func setupCompatibilityMonitoring() {
        let manager = CompatibilityManager.shared
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            versionInfo = manager.version
            supportedFeatures = manager.getSupportedFeatures()
        }
    }
    
    private func showDiagnostics() {
        let checker = macOSVersionChecker.shared
        let report = checker.createDiagnosticReport()
        
        // Present diagnostic report (e.g., in a dialog)
        print(report)
    }
}

struct FeatureRow: View {
    let title: String
    let supported: Bool
    
    var body: some View {
        HStack {
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(supported ? .green : .red)
            Text(title)
            Spacer()
        }
        .font(.subheadline)
    }
}
```

### 3. In bestehende Services integrieren

#### Apple Notes Integration

```swift
import Foundation
import AppKit
import CompatibilityManager

class AppleNotesService {
    private let compatibilityManager = CompatibilityManager.shared
    
    func createNote(title: String, content: String) -> Bool {
        let version = compatibilityManager.version ?? .catalina
        
        switch version {
        case .catalina:
            return createNoteCatalina(title: title, content: content)
        case .bigSur, .monterey, .ventura, .sonoma, .sequoia:
            return createNoteModern(title: title, content: content)
        }
    }
    
    private func createNoteCatalina(title: String, content: String) -> Bool {
        // AppleScript-based note creation for Catalina
        let appleScript = """
        tell application "Notes"
            make new note at folder "Notes" with properties {name: "\(title)", body: "\(content)"}
        end tell
        """
        
        if let script = NSAppleScript(source: appleScript) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            return error == nil
        }
        
        return false
    }
    
    private func createNoteModern(title: String, content: String) -> Bool {
        // Modern Notes API for Big Sur+
        // Using modern Swift/Objective-C Notes framework
        return true // Implementation would use actual Notes API
    }
}
```

#### Voice Input Service

```swift
import Foundation
import Speech
import CompatibilityManager

class VoiceInputService {
    private let compatibilityManager = CompatibilityManager.shared
    
    func enableVoiceInput() {
        let version = compatibilityManager.version ?? .catalina
        
        switch version {
        case .catalina:
            enableBasicVoiceInput()
        case .bigSur, .monterey:
            enableEnhancedVoiceInput()
        case .ventura, .sonoma, .sequoia:
            enableAdvancedVoiceInput()
        }
    }
    
    private func enableBasicVoiceInput() {
        // Basic speech recognition
        let recognizer = SFSpeechRecognizer()
        recognizer?.delegate = self
    }
    
    private func enableEnhancedVoiceInput() {
        // Enhanced speech features available in Monterey+
        enableContinousRecognition()
        enableSpeechSegmentation()
    }
    
    private func enableAdvancedVoiceInput() {
        // Most advanced features for Ventura+
        enableLiveSpeechRecognition()
        enableVoiceCommands()
    }
}
```

#### Shortcuts Integration

```swift
import Foundation
import Shortcuts
import CompatibilityManager

class ShortcutsService {
    private let compatibilityManager = CompatibilityManager.shared
    
    func createQuickNoteShortcut() -> Bool {
        let version = compatibilityManager.version ?? .catalina
        
        if !compatibilityManager.supports(.shortcutsIntegration) {
            print("Shortcuts nicht verfügbar auf dieser macOS-Version")
            return false
        }
        
        switch version {
        case .bigSur:
            return createBasicShortcut()
        case .monterey, .ventura:
            return createEnhancedShortcut()
        case .sonoma, .sequoia:
            return createAdvancedShortcut()
        default:
            return false
        }
    }
    
    private func createBasicShortcut() -> Bool {
        // Basic Shortcuts integration for Big Sur
        return true
    }
    
    private func createEnhancedShortcut() -> Bool {
        // Enhanced Shortcuts for Monterey/Ventura
        return true
    }
    
    private func createAdvancedShortcut() -> Bool {
        // Advanced Shortcuts for Sonoma+
        return true
    }
}
```

## Erweiterte Konfiguration

### 1. Build-Settings anpassen

In der `xcconfig`-Datei oder Build Settings:

```swift
// Swift Compiler - Language
SWIFT_VERSION = 5.0

// Deployment Target
MACOSX_DEPLOYMENT_TARGET = 10.15

// Conditional Compilation
ENABLE_VERSION_CHECK = YES
ENABLE_ADVANCED_FEATURES = YES
```

### 2. Scheme Configuration

In Xcode Scheme → Run → Arguments:

```bash
// Environment Variables
COMPATIBILITY_MODE=strict
VERSION_CHECK_ENABLED=YES
UI_ADAPTATION_ENABLED=YES
```

### 3. Build Phases hinzufügen

1. **Run Script Phase** für macOS-Versions-Check:

```bash
#!/bin/bash

# macOS Version Check Script
echo "Checking macOS compatibility..."
SYSTEM_VERSION=$(sw_vers -productVersion)
echo "Detected macOS version: $SYSTEM_VERSION"

# Validate minimum version
if [[ "$SYSTEM_VERSION" < "10.15" ]]; then
    echo "Error: macOS 10.15 (Catalina) or later required"
    exit 1
fi

echo "macOS compatibility check passed."
```

## Test-Integration

### 1. Unit Tests erweitern

```swift
import XCTest
@testable import YourAppName

class AppCompatibilityTests: XCTestCase {
    
    func testAppStartsOnCurrentVersion() {
        let version = CompatibilityManager.shared.version
        XCTAssertNotNil(version, "App should start on supported macOS version")
        
        // Test specific features based on detected version
        if version! >= .bigSur {
            testShortcutsIntegration()
        }
        
        if version! >= .sonoma {
            testGlassEffects()
        }
    }
    
    private func testShortcutsIntegration() {
        let shortcuts = ShortcutsService()
        let success = shortcuts.createQuickNoteShortcut()
        XCTAssertTrue(success, "Shortcuts should work on Big Sur+")
    }
    
    private func testGlassEffects() {
        let uiManager = macOSUIAdaptationManager.shared
        let shouldUseGlass = uiManager.shouldUseGlassEffects()
        XCTAssertTrue(shouldUseGlass, "Glass effects should be available on Sonoma+")
    }
}
```

### 2. UI Tests

```swift
import XCTest

class macOSCompatibilityUITests: XCTestCase {
    
    func testUIRendersCorrectly() {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for version detection
        sleep(1)
        
        // Verify UI adapts correctly
        let version = CompatibilityManager.shared.version
        
        if version! >= .sonoma {
            // Test glass effects are present
            let window = app.windows.firstMatch
            XCTAssertTrue(window.exists, "Window should exist")
        }
    }
}
```

## Monitoring und Logging

### 1. Kompatibilitäts-Monitoring

```swift
import Logging

class CompatibilityLogger {
    private let logger = Logger(subsystem: "com.yourcompany.app", category: "compatibility")
    
    func logVersionDetection() {
        let version = CompatibilityManager.shared.version
        let info = macOSVersionChecker.shared.getVersionInfo()
        
        logger.info("macOS Version detected: \(version?.name ?? "Unknown") (\(version?.rawValue ?? "Unknown"))")
        logger.info("Build number: \(info.buildNumber)")
        logger.info("Features supported: \(info.features.count)")
    }
    
    func logFeatureUsage(feature: FeatureSupport) {
        let supported = CompatibilityManager.shared.supports(feature)
        logger.info("Feature \(feature.rawValue) used: \(supported ? "Supported" : "Fallback used")")
    }
}
```

### 2. Performance Monitoring

```swift
import os.log

class PerformanceMonitor {
    private let log = OSLog(subsystem: "com.yourcompany.app", category: "performance")
    
    func measureCompatibilityCheck() {
        let start = CFAbsoluteTimeGetCurrent()
        
        // Run compatibility checks
        _ = macOSVersionChecker.shared.getVersionInfo()
        _ = CompatibilityManager.shared.getSupportedFeatures()
        
        let end = CFAbsoluteTimeGetCurrent()
        let duration = end - start
        
        os_log("Compatibility check took %.2f seconds", log: log, type: .info, duration)
        
        if duration > 0.1 { // Warn if takes longer than 100ms
            os_log("Compatibility check performance issue detected", log: log, type: .error)
        }
    }
}
```

## Deployment und Distribution

### 1. App Store Submission

```xml
<!-- Additional Info.plist keys for App Store -->
<key>LSMinimumSystemVersion</key>
<string>10.15.0</string>
<key>CFBundleShortVersionString</key>
<string>1.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 2. Code Signing

```bash
# Update your signing script to include version checks
echo "Signing for macOS compatibility..."
codesign --force --options runtime --entitlements Entitlements.plist --sign "Developer ID Application: Your Name" "YourApp.app"

# Verify signing
codesign -v --deep --strict "YourApp.app"
```

### 3. Notarization

```bash
# Prepare for notarization with compatibility checks
echo "Preparing for notarization..."

# Check for hardened runtime compatibility
spctl --assess --verbose "YourApp.app"

# Submit for notarization
xcrun notarytool submit "YourApp.dmg" --apple-id "your@email.com" --password "app-password" --team-id "YOUR_TEAM_ID" --wait
```

## Troubleshooting

### 1. Häufige Probleme

#### Problem: Version nicht erkannt
```swift
// Debug: Version detection fallback
let fallbackVersion = macOSVersion(rawValue: "10.15") // Default to Catalina
let version = CompatibilityManager.shared.version ?? fallbackVersion
```

#### Problem: Feature-Detection liefert falsche Ergebnisse
```swift
// Debug: Manual feature verification
let hasShortcutApp = FileManager.default.fileExists(atPath: "/System/Library/CoreServices/Shortcuts.app")
let hasNotesApp = FileManager.default.fileExists(atPath: "/System/Library/CoreServices/Notes.app")
```

#### Problem: UI-Adaptation funktioniert nicht
```swift
// Debug: UI adaptation check
let shouldUseModernUI = CompatibilityManager.shared.shouldUseModernUI()
let uiManagerGlass = macOSUIAdaptationManager.shared.shouldUseGlassEffects()
print("Modern UI: \(shouldUseModernUI), Glass: \(uiManagerGlass)")
```

### 2. Debug-Modus

```swift
#if DEBUG
class CompatibilityDebug {
    static func enableDebugMode() {
        UserDefaults.standard.set(true, forKey: "CompatibilityDebug")
        print("Compatibility debug mode enabled")
    }
    
    static func printAllCapabilities() {
        let capabilities = macOSVersionChecker.shared.detectSystemCapabilities()
        let features = CompatibilityManager.shared.getSupportedFeatures()
        
        print("=== Capabilities ===")
        print("Shortcuts: \(capabilities.hasBasicShortcuts)")
        print("Glass Effects: \(capabilities.hasGlassEffects)")
        print("Enhanced Voice: \(capabilities.hasEnhancedVoice)")
        
        print("=== Features ===")
        features.forEach { print("Feature: \($0)") }
    }
}
#endif
```

## Wartung und Updates

### 1. Regelmäßige Kompatibilitätstests

```bash
#!/bin/bash
# weekly_compatibility_test.sh

echo "Running weekly compatibility tests..."

# Test on current system
swift test macOSCompatibilityTests

# Check for new macOS versions
echo "Checking for macOS updates..."
softwareupdate --list

echo "Compatibility tests completed."
```

### 2. Version-Update Monitoring

```swift
import Foundation

class VersionUpdateMonitor {
    private let currentVersion: macOSVersion
    private let updateCheckInterval: TimeInterval = 86400 // 24 hours
    
    init() {
        self.currentVersion = CompatibilityManager.shared.version ?? .catalina
        startMonitoring()
    }
    
    private func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: updateCheckInterval, repeats: true) { _ in
            self.checkForUpdates()
        }
    }
    
    private func checkForUpdates() {
        let latestVersion = checkLatestAvailableVersion()
        
        if latestVersion > currentVersion {
            notifyUser(about: latestVersion)
        }
    }
    
    private func checkLatestAvailableVersion() -> macOSVersion {
        // Implementation would check Apple's servers for latest version
        return .sequoia // Placeholder
    }
    
    private func notifyUser(about version: macOSVersion) {
        // Show update notification to user
        print("New macOS version available: \(version.name)")
    }
}
```

## Fazit

Diese Implementierungsanleitung ermöglicht die nahtlose Integration der macOS-Kompatibilitätslösung in bestehende macOS-Anwendungen. Die Lösung bietet:

- **Automatische Version-Erkennung** und Feature-Erkennung
- **Graceful Degradation** für ältere macOS-Versionen
- **UI-Adaptation** für optimale Darstellung auf allen Versionen
- **Umfassendes Testing** und Debugging-Tools
- **Performance-Monitoring** und Logging

Durch Befolgung dieser Anleitung können Entwickler robuste, zukunftssichere macOS-Anwendungen erstellen, die über mehrere macOS-Versionen hinweg optimal funktionieren.