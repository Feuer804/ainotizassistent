# User Guide - AINotizassistent Packaging & Distribution System

## 🎯 Übersicht

Dieses Handbuch führt Sie durch die Verwendung des AINotizassistent Packaging & Distribution Systems. Das System bietet eine vollständige Lösung für die Erstellung, Signierung, Notarization und Distribution von macOS Apps.

## 📋 Inhaltsverzeichnis

1. [Erste Schritte](#-erste-schritte)
2. [Build-Prozess](#-build-prozess)
3. [Code Signierung](#-code-signierung)
4. [Notarization](#-notarization)
5. [Distribution](#-distribution)
6. [Update System](#-update-system)
7. [License Management](#-license-management)
8. [App Store Connect](#-app-store-connect)
9. [Analytics und Monitoring](#-analytics-und-monitoring)
10. [Advanced Features](#-advanced-features)

## 🚀 Erste Schritte

### Schnellstart

```bash
# 1. Repository klonen oder entpacken
cd PackagingDistribution

# 2. Berechtigung für Scripts setzen
chmod +x Scripts/*.sh

# 3. Erster Build
./Scripts/build_app.sh --configuration Debug --clean

# 4. App testen
open Build/Debug/AINotizassistent.app
```

### Grundlegende Kommandos

```bash
# Build-Status prüfen
./Scripts/build_app.sh --help

# App signieren
./Scripts/sign_and_notarize.sh /path/to/app.app --team-id YOUR_TEAM_ID

# Notarization starten
./Scripts/sign_and_notarize.sh /path/to/app.app --notarize-only

# App Store vorbereiten
./Scripts/appstore_connect.sh generate-templates
```

## 🏗️ Build-Prozess

### Debug Build (Entwicklung)

```bash
# Debug Build für lokale Tests
./Scripts/build_app.sh \
  --configuration Debug \
  --clean

# Mit erweiterten Debug-Optionen
./Scripts/build_app.sh \
  --configuration Debug \
  --clean \
  --enable-debug-symbols
```

### Release Build (Distribution)

```bash
# Standard Release Build
./Scripts/build_app.sh \
  --configuration Release \
  --team-id YOUR_TEAM_ID \
  --clean

# Mit Distribution-Paketen
./Scripts/build_app.sh \
  --configuration Release \
  --team-id YOUR_TEAM_ID \
  --sign \
  --distribution \
  --clean
```

### Build-Konfigurationen

| Configuration | Verwendung | Features |
|---------------|------------|----------|
| Debug | Entwicklung | Debug Symbols, Debug Optimizations |
| Release | Distribution | Code Optimization, Signing |
| Release-Testing | Beta Tests | Signing, Limited Distribution |

### Build-Output

```
Build/
├── Debug/
│   └── AINotizassistent.app
├── Release/
│   ├── AINotizassistent.app
│   └── ...
└── Distribution/
    ├── AINotizassistent-v1.0.0.dmg
    ├── AINotizassistent-v1.0.0.pkg
    ├── AINotizassistent-v1.0.0.zip
    ├── ReleaseNotes.md
    └── *.sha256
```

## 🔐 Code Signierung

### Developer ID Signierung

```bash
# Basis Signierung
./Scripts/sign_and_notarize.sh \
  /path/to/app.app \
  --team-id YOUR_TEAM_ID

# Mit spezifischem Certificate
./Scripts/sign_and_notarize.sh \
  /path/to/app.app \
  --team-id YOUR_TEAM_ID \
  --signing-identity "Developer ID Application: YOUR_TEAM_ID"
```

### Signierung prüfen

```bash
# Signatur verifizieren
codesign --verify --verbose=4 /path/to/app.app

# Signierungs-Chain prüfen
spctl -t exec -vv /path/to/app.app

# Signierungs-Details anzeigen
codesign -dv --verbose=4 /path/to/app.app
```

### Häufige Signierungsprobleme

#### Team ID nicht gefunden

```bash
# Team ID aus Keychain extrahieren
TEAM_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk '{print $2}' | cut -d'=' -f2 | tr -d '"')

# Build mit extrahierter ID
./Scripts/build_app.sh --team-id $TEAM_ID
```

#### Zertifikat abgelaufen

```bash
# Zertifikate anzeigen
security find-identity -v -p codesigning

# Abgelaufene Zertifikate finden
security find-identity -v -p codesigning | grep "expired"

# Neue Zertifikate aus Developer Portal herunterladen
# Xcode > Preferences > Accounts > Download Manual Profiles
```

## 📋 Notarization

### Automatische Notarization

```bash
# Komplette Signierung und Notarization
./Scripts/build_app.sh \
  --configuration Release \
  --team-id YOUR_TEAM_ID \
  --sign \
  --notarize \
  --distribution
```

### Manuelle Notarization

```bash
# Signierte App notarization
./Scripts/sign_and_notarize.sh \
  /path/to/app.app \
  --team-id YOUR_TEAM_ID \
  --notarize-only

# Mit Fortschrittsanzeige
./Scripts/sign_and_notarize.sh \
  --verbose \
  /path/to/app.app \
  --notarize-only
```

### Notarization Status prüfen

```bash
# Aktuelle Notarization Jobs
xcrun notarytool list

# Notarization Details
xcrun notarytool info SUBMISSION_ID

# Notarization Logs
xcrun notarytool log SUBMISSION_ID
```

### Notarization Fehler beheben

#### "Unable to validate software"

```bash
# Häufige Ursachen und Lösungen:

# 1. Fehlende Signatur - Zuerst signieren
./Scripts/sign_and_notarize.sh /path/to/app.app --sign

# 2. Private Frameworks entfernen
find /path/to/app -name "*.framework" | grep -v Apple | head -10

# 3. Entitlements prüfen
codesign -d --entitlements - /path/to/app.app
```

#### "Invalid signature"

```bash
# Signatur reparieren
codesign --remove-signature /path/to/app.app
codesign --force --sign "Developer ID Application: YOUR_TEAM_ID" /path/to/app.app

# Verification
codesign --verify --verbose=4 /path/to/app.app
```

## 📦 Distribution

### DMG Erstellung

```bash
# DMG mit Standard-Background
./Scripts/create_dmg.sh \
  --app-path /path/to/app.app \
  --team-id YOUR_TEAM_ID

# Mit benutzerdefiniertem Background
./Scripts/create_dmg.sh \
  --app-path /path/to/app.app \
  --background /path/to/custom_background.png \
  --team-id YOUR_TEAM_ID
```

### PKG Installer

```bash
# PKG Installer erstellen
./Scripts/create_pkg.sh \
  --app-path /path/to/app.app \
  --bundle-id com.yourcompany.yourapp \
  --version 1.0.0 \
  --team-id YOUR_TEAM_ID
```

### GitHub Releases

```bash
# Release mit automatischer Asset-Upload
./Scripts/github_release.sh \
  --tag v1.0.0 \
  --title "Version 1.0.0 - Initial Release" \
  --assets Build/Distribution/ \
  --notes-file ReleaseNotes.md
```

### Website Distribution

```bash
# Website Download-Seite generieren
./Scripts/generate_download_page.sh \
  --app-name AINotizassistent \
  --version 1.0.0 \
  --assets Build/Distribution/ \
  --template website_template.html
```

## 🔄 Update System

### Sparkle Konfiguration

```swift
// Info.plist konfigurieren
<key>SUEnableAutomaticChecks</key>
<true/>
<key>SUScheduledCheckInterval</key>
<integer>86400</integer>
<key>SUFeedURL</key>
<string>https://yourdomain.com/appcast.xml</string>
<key>SUSignUpdateURL</key>
<string>your-sparkle-public-key</string>
```

### Appcast Feed Generation

```bash
# Appcast Feed erstellen
./Scripts/generate_appcast.sh \
  --version 1.0.0 \
  --update-url "https://yourdomain.com/updates/AINotizassistent-1.0.0.zip" \
  --dsa-signature "your-dsa-signature" \
  --notes-file changelog.md

# Feed hochladen
./Scripts/upload_appcast.sh \
  --feed-path appcast.xml \
  --server-url https://yourdomain.com
```

### Delta Updates

```bash
# Delta Update erstellen
./Scripts/create_delta_update.sh \
  --old-version 1.0.0 \
  --new-version 1.0.1 \
  --old-app-path Build/Release/AINotizassistent-1.0.0.app \
  --new-app-path Build/Release/AINotizassistent-1.0.1.app \
  --output-path updates/
```

## 🔑 License Management

### License Key Generation

```swift
// Swift Code für License Generation
import Foundation

let licenseManager = LicenseManager(configuration: licenseConfig)

// Test-Lizenz generieren
let trialLicense = try await licenseManager.generateTrialLicense()

// Vollversion Lizenz
let fullLicense = try await licenseManager.generateLicenseKey(
    for: "user@example.com",
    plan: .subscription(months: 12)
)

// Promo-Lizenz
let promoLicense = try await licenseManager.generatePromoLicense(
    email: "promo@user.com",
    promoCode: "SUMMER2025"
)
```

### License Validation

```swift
// Lizenz validieren
let validationResult = try await licenseManager.validateLicenseKey(licenseKey)

if validationResult.isValid {
    // Lizenz gültig
    print("Plan: \(validationResult.plan)")
    print("Features: \(validationResult.features)")
    print("Gültig bis: \(validationResult.expiryDate)")
} else {
    // Lizenz ungültig
    print("License Error")
}
```

### Trial Management

```swift
// Trial starten
licenseManager.startTrial()

// Trial Status prüfen
licenseManager.checkTrialStatus()

if licenseManager.licenseStatus == .trial {
    print("Testzeitraum aktiv. Verbleibende Tage: \(remainingTrialDays)")
}

// Trial abgelaufen
if licenseManager.isTrialExpired() {
    licenseManager.showTrialUpgradePrompt()
}
```

## 🏪 App Store Connect

### Neue App erstellen

```bash
# App Store Template generieren
./Scripts/appstore_connect.sh generate-templates

# App erstellen
./Scripts/appstore_connect.sh create-app \
  --title "AINotizassistent" \
  --bundle-id com.yourcompany.AINotizassistent \
  --category productivity \
  --rating "4+" \
  --subtitle "Intelligenter Notizassistent"
```

### Metadata Management

```bash
# App-Beschreibung aktualisieren
./Scripts/appstore_connect.sh update-metadata \
  -a APP_ID \
  --description "Ein intelligenter Notizassistent mit AI-Integration..." \
  --keywords "notiz,assistent,ai,productivity" \
  --whats-new "• Neue AI-Features\n• Verbesserte Performance\n• Bugfixes"

# Kategorie ändern
./Scripts/appstore_connect.sh update-metadata \
  -a APP_ID \
  --category education
```

### Screenshots verwalten

```bash
# Screenshot-Verzeichnis strukturieren
mkdir -p screenshots/{iphone,ipad}

# Screenshots für iPhone (6.7" Display)
# Place screenshots in screenshots/iphone/6.7/

# Screenshots hochladen
./Scripts/appstore_connect.sh upload-screenshots \
  -a APP_ID \
  --iphone-path screenshots/iphone \
  --ipad-path screenshots/ipad
```

### Build Upload und Review

```bash
# Build für App Store erstellen
./Scripts/build_app.sh \
  --configuration Release \
  --team-id YOUR_TEAM_ID \
  --archive

# Build hochladen
./Scripts/appstore_connect.sh upload-build \
  -a APP_ID \
  --path Build/Release/AINotizassistent.xcarchive

# Für Review einreichen
./Scripts/appstore_connect.sh submit-for-review \
  -a APP_ID \
  --changelog "Version 1.0 - Neue AI-Features und Verbesserungen" \
  --demo-account "Optional: Demo-Kontodaten"
```

## 📊 Analytics und Monitoring

### Crash Reporting (Sentry)

```swift
// Sentry Konfiguration
import Sentry

SentrySDK.start { options in
    options.dsn = "https://your-sentry-dsn@sentry.io/project-id"
    options.environment = "production"
    options.beforeSend = { event in
        // PII entfernen
        event.user?.email = nil
        return event
    }
}

// Crash Context hinzufügen
SentrySDK.configureScope { scope in
    scope.setTag(value: "AINotizassistent", key: "app")
    scope.setContext(value: ["license": licenseStatus], key: "license")
}
```

### Usage Analytics

```swift
// Event Tracking
analytics.trackEvent("app_launched", parameters: [
    "version": appVersion,
    "platform": "macOS",
    "license_status": licenseStatus.rawValue
])

// Feature Usage
analytics.trackFeatureEvent("ai_generation", parameters: [
    "feature_type": "meeting_summary",
    "duration": generationTime,
    "success": isSuccess
])

// Performance Tracking
analytics.trackPerformanceEvent("startup_time", value: startupTime)
analytics.trackPerformanceEvent("memory_usage", value: memoryUsage)
```

### Custom Metrics

```swift
// App Performance
let performanceManager = PerformanceManager()

// Startup Time messen
let startupTimer = performanceManager.startTimer("app_startup")
// App initialisieren...
startupTimer.stop()

// Memory Usage
let memoryUsage = performanceManager.getMemoryUsage()
analytics.trackMemoryUsage(memoryUsage)

// CPU Usage
let cpuUsage = performanceManager.getCPUUsage()
analytics.trackCPUUsage(cpuUsage)
```

## 🔧 Advanced Features

### CI/CD Integration

#### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build and Deploy

on:
  push:
    tags: ['v*']
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Environment
      run: |
        echo "APP_NAME=AINotizassistent" >> $GITHUB_ENV
        echo "TEAM_ID=${{ secrets.TEAM_ID }}" >> $GITHUB_ENV
    
    - name: Build App
      run: |
        cd PackagingDistribution
        chmod +x Scripts/*.sh
        ./Scripts/build_app.sh \
          --configuration Release \
          --team-id $TEAM_ID \
          --sign \
          --distribution
    
    - name: Upload to Release
      uses: softprops/action-gh-release@v1
      with:
        files: Build/Distribution/*
        tag_name: ${{ github.ref_name }}
```

#### Fastlane Integration

```ruby
# Fastfile
default_platform(:mac)

platform :mac do
  desc "Build and distribute app"
  lane :build_and_distribute do
    # Build app
    xcodebuild(
      scheme: "AINotizassistent",
      configuration: "Release",
      archive_path: "build/AINotizassistent.xcarchive"
    )
    
    # Sign and notarize
    sign_and_notarize(
      app_path: "build/Release/AINotizassistent.app",
      team_id: ENV["TEAM_ID"]
    )
    
    # Create distribution packages
    create_packages(
      app_path: "build/Release/AINotizassistent.app",
      version: ENV["VERSION_NUMBER"]
    )
    
    # Upload to App Store
    upload_to_app_store(
      app_identifier: "com.yourcompany.AINotizassistent"
    ) if ENV["UPLOAD_TO_APP_STORE"] == "true"
  end
end
```

### Custom Build Scripts

#### Post-Build Hooks

```bash
# scripts/post_build.sh
#!/bin/bash

APP_PATH="$1"
BUILD_CONFIG="$2"

# App Icon Validation
echo "Validating app icons..."
./Scripts/validate_icons.sh "$APP_PATH"

# Code Analysis
echo "Running code analysis..."
./Scripts/code_analysis.sh "$APP_PATH"

# Security Scan
echo "Scanning for security issues..."
./Scripts/security_scan.sh "$APP_PATH"

# Performance Benchmark
echo "Running performance benchmarks..."
./Scripts/benchmark.sh "$APP_PATH"

echo "Post-build tasks completed"
```

### Automated Testing

#### Unit Tests

```bash
# Tests ausführen
xcodebuild test \
  -project AINotizassistent.xcodeproj \
  -scheme AINotizassistent \
  -destination 'platform=macOS'

# Coverage Report
xcodebuild test \
  -project AINotizassistent.xcodeproj \
  -scheme AINotizassistent \
  -enableCodeCoverage YES \
  -destination 'platform=macOS'

# Coverage HTML Report
xcrun llvm-cov export -format="lcov" \
  -instr-profile Build/Release/AINotizassistent.xcodeproj/Logs/Test/*.profdata \
  -arch x86_64 \
  Build/Release/AINotizassistent.app/Contents/MacOS/AINotizassistent > coverage.lcov
```

#### UI Tests

```swift
// UITests.swift
import XCTest

class AINotizassistentUITests: XCTestCase {
    
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test basic functionality
        XCTAssertTrue(app.buttons["New Note"].exists)
        XCTAssertTrue(app.textFields["Note Title"].exists)
    }
    
    func testAIGeneration() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["New Note"].click()
        app.textFields["Note Title"].typeText("AI Test Note")
        app.buttons["Generate with AI"].click()
        
        // Wait for AI generation
        let aiGeneratedText = app.textViews["Generated Content"]
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: aiGeneratedText)
        wait(for: [expectation], timeout: 10.0)
        
        XCTAssertTrue(aiGeneratedText.value as? String != nil)
    }
}
```

### Performance Optimization

#### App Size Optimization

```bash
# Binary Analysis
size Build/Release/AINotizassistent.app/Contents/MacOS/AINotizassistent

# Unused Symbols entfernen
./Scripts/optimize_binary.sh \
  --input Build/Release/AINotizassistent.app \
  --output Build/Release/AINotizassistent-Optimized.app \
  --strip-symbols

# Asset Optimization
./Scripts/optimize_assets.sh \
  --app-path Build/Release/AINotizassistent.app \
  --compress-images \
  --remove-unused-assets
```

#### Startup Performance

```swift
// Startup Profiling
import os.log

class StartupProfiler {
    static let logger = os.Logger(subsystem: "com.yourcompany.AINotizassistent", 
                                 category: "startup")
    
    static func measureStartup() {
        let startTime = CACurrentMediaTime()
        
        // App Initialization
        AppDelegate.applicationDidFinishLaunching
        
        let startupTime = CACurrentMediaTime() - startTime
        
        logger.log("App startup time: \(startupTime) seconds")
        
        // Send to analytics
        analytics.trackPerformanceEvent("startup_time", value: startupTime)
    }
}
```

## 📚 Best Practices

### Code Signierung

1. **Automatische Signierung**: Nutzen Sie automatische Code-Signierung in Xcode
2. **Team Management**: Verwenden Sie Team-spezifische Konfigurationen
3. **Zertifikat Renewal**: Überwachen Sie Zertifikat-Ablaufdaten
4. **Backup**: Sichern Sie Zertifikate und Private Keys

### Build Pipeline

1. **Consistent Environment**: Verwenden Sie固定的 Build-Umgebungen
2. **Cache Management**: Implementieren Sie intelligente Caching-Strategien
3. **Parallel Builds**: Nutzen Sie parallele Build-Prozesse
4. **Artifact Management**: Verwalten Sie Build-Artefakte systematisch

### Security

1. **Code Obfuscation**: Schützen Sie sensiblen Code
2. **Certificate Security**: Sichern Sie Zertifikate und Keys
3. **Runtime Protection**: Implementieren Sie Anti-Tampering
4. **Regular Updates**: Halten Sie Sicherheitsbibliotheken aktuell

### Performance

1. **Binary Size**: Überwachen Sie App-Größe
2. **Startup Time**: Optimieren Sie Start-up-Zeit
3. **Memory Usage**: Kontrollieren Sie Speicherverbrauch
4. **Network Efficiency**: Minimieren Sie Netzwerk-Overhead

---

**Für weitere Informationen konsultieren Sie:**

- [Installation Guide](INSTALLATION.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [API Documentation](../Sources/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)