# Installation Guide - AINotizassistent Packaging & Distribution System

## Voraussetzungen

### Systemanforderungen

- **macOS**: 11.0 (Big Sur) oder höher
- **Xcode**: 13.0 oder höher
- **Command Line Tools**: Aktuelle Version

### Apple Developer Program

- **Apple Developer Account**: Erforderlich für Code Signing
- **Team ID**: Von Apple Developer Portal
- **Zertifikate**: Developer ID Application, Developer ID Installer

### Third-Party Tools

```bash
# Homebrew (empfohlen)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Erforderliche Tools
brew install jq
brew install xcodes

# Optional für erweiterte Funktionen
brew install fastlane
brew install swiftformat
brew install swiftlint
```

## 🔧 Setup-Schritte

### 1. Apple Developer Konfiguration

#### Developer ID Zertifikate erstellen

1. **Developer Portal**: https://developer.apple.com
2. **Certificates**: Neue Zertifikate erstellen
   - Developer ID Application
   - Developer ID Installer
   - (Optional) Mac App Distribution

#### Team ID ermitteln

```bash
# Team ID anzeigen
security find-identity -v -p codesigning | grep "Developer ID" | head -1 | awk '{print $2}' | cut -d'=' -f2 | tr -d '"'
```

#### Notarization Setup

```bash
# Apple ID für Notarization einrichten
xcrun notarytool log in --apple-id your-apple-id@example.com

# Notarization Profile erstellen
xcrun notarytool store-credentials NOTARIZATION_PROFILE \
  --apple-id your-apple-id@example.com \
  --password app-specific-password
```

### 2. App Store Connect API Setup

#### API-Schlüssel erstellen

1. **App Store Connect**: Users and Access
2. **Keys**: Neue API-Schlüssel erstellen
3. **Download**: Private Key (.p8) herunterladen

#### API-Konfiguration

```bash
# Umgebungsvariablen setzen
export ASC_API_KEY_ID="YOUR_KEY_ID"
export ASC_API_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXXXXXXXXX.p8"
```

### 3. Projekt-Konfiguration

#### Hauptverzeichnis erstellen

```bash
cd /workspace
cp -r PackagingDistribution /path/to/your/project
cd PackagingDistribution
```

#### Umgebungsvariablen konfigurieren

```bash
# .env Datei erstellen
cat > .env << EOF
# App Configuration
APP_NAME=AINotizassistent
BUNDLE_ID=com.yourcompany.AINotizassistent
TEAM_ID=YOUR_TEAM_ID

# Signing
DEVELOPER_ID_APPLICATION="Developer ID Application: YOUR_TEAM_ID"
DEVELOPER_ID_INSTALLER="Developer ID Installer: YOUR_TEAM_ID"
NOTARIZATION_PROFILE=NOTARIZATION_PROFILE

# App Store Connect
ASC_API_KEY_ID=YOUR_API_KEY_ID
ASC_API_ISSUER_ID=YOUR_ISSUER_ID
ASC_PRIVATE_KEY_PATH=/path/to/AuthKey.p8
APPLE_ID=your-apple-id@example.com

# Updates
SPARKLE_PUBLIC_KEY=your-sparkle-public-key
UPDATE_FEED_URL=https://yourdomain.com/appcast.xml

# Analytics (Optional)
SENTRY_DSN=your-sentry-dsn
ANALYTICS_API_KEY=your-analytics-key

# License Server (Optional)
LICENSE_SERVER_URL=https://your-license-server.com
LICENSE_PUBLIC_KEY=your-license-public-key
EOF

# .env laden
source .env
```

#### Berechtigung für Build-Skripte

```bash
chmod +x Scripts/*.sh
```

### 4. Erster Build Test

#### Einfacher Debug-Build

```bash
# Debug Build (ohne Signierung)
./Scripts/build_app.sh --configuration Debug --clean

# Prüfe Build
ls -la Build/Debug/
```

#### Release Build mit Signierung

```bash
# Release Build mit Signierung
./Scripts/build_app.sh \
  --configuration Release \
  --team-id $TEAM_ID \
  --clean \
  --sign

# Prüfe Signierung
codesign --verify --verbose=4 Build/Release/AINotizassistent.app
spctl -t exec -vv Build/Release/AINotizassistent.app
```

## 🛠️ Erweiterte Konfiguration

### Xcode Projekt Setup

#### Automatisches Xcode Projekt erstellen

```bash
# Swift-Konfiguration verwenden
swift Sources/XcodeProjectConfig.swift --app-name AINotizassistent --bundle-id com.yourcompany.AINotizassistent --team-id YOUR_TEAM_ID
```

#### Manuelle Xcode Konfiguration

1. **Neues Xcode Projekt erstellen**
   - macOS App Template
   - Product Name: AINotizassistent
   - Bundle Identifier: com.yourcompany.AINotizassistent

2. **Build Settings optimieren**
   ```swift
   // Swift Compiler - Code Generation
   SWIFT_COMPILATION_MODE = wholemodule
   SWIFT_OPTIMIZATION_LEVEL = -O
   SWIFT_ACTIVE_COMPILATION_CONDITIONS = "$(PRODUCT_NAME)"
   
   // Code Signing
   CODE_SIGN_STYLE = Automatic
   DEVELOPMENT_TEAM = YOUR_TEAM_ID
   PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.AINotizassistent
   
   // Architecture
   ARCHS = x86_64 arm64
   ONLY_ACTIVE_ARCH = NO
   VALIDATE_PRODUCT = YES
   ```

3. **Entitlements konfigurieren**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>com.apple.security.app-sandbox</key>
       <true/>
       <key>com.apple.security.network.client</key>
       <true/>
       <key>com.apple.security.network.server</key>
       <true/>
       <key>com.apple.security.files.user-selected.read-write</key>
       <true/>
       <key>com.apple.security.files.downloads.read-write</key>
       <true/>
   </dict>
   </plist>
   ```

### License Management Setup

#### Lizenz-Server konfigurieren (Optional)

```bash
# Lizenz-Server Setup (Node.js Beispiel)
mkdir -p license-server
cd license-server

# Package.json erstellen
cat > package.json << EOF
{
  "name": "ainotizassistent-license-server",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "crypto": "^1.0.1",
    "sqlite3": "^5.1.0"
  }
}
EOF

# NPM Dependencies installieren
npm install
```

#### Lizenz-Keys generieren

```bash
# Test-Lizenz generieren
swift -c '
import Foundation
let licenseManager = LicenseManager(configuration: licenseConfig)
let licenseKey = try await licenseManager.generateTrialLicense()
print("Test License Key: \\(licenseKey)")
'
```

### Update System Setup

#### Sparkle konfigurieren

1. **Sparkle Framework hinzufügen**
   - SPM Package: https://github.com/sparkle-project/Sparkle.git
   - Oder manuell: Sparkle.xcframework

2. **Appcast Feed erstellen**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/sparkle">
       <channel>
           <title>AINotizassistent Updates</title>
           <description>Latest updates for AINotizassistent</description>
           <item>
               <title>Version 1.0.0</title>
               <description>Initial release with AI features</description>
               <pubDate>Thu, 01 Jan 2025 12:00:00 +0000</pubDate>
               <enclosure url="https://yourdomain.com/downloads/AINotizassistent-1.0.0.zip"
                          sparkle:shortVersionString="1.0.0"
                          sparkle:version="1"
                          sparkle:dsaSignature="your-dsa-signature"
                          type="application/octet-stream"/>
           </item>
       </channel>
   </rss>
   ```

3. **Sparkle Keys generieren**
   ```bash
   # DSA Key Pair generieren
   openssl dsaparam -out dsa_param.pem 2048
   openssl gendsa -out dsa_priv.pem dsa_param.pem
   openssl dsa -in dsa_priv.pem -pubout -out dsa_pub.pem
   
   # Public Key für Info.plist
   SPARKLE_PUBLIC_KEY=$(openssl dsa -in dsa_pub.pem -pubout -outform DER | base64 -p)
   ```

### Analytics Setup

#### Sentry Integration

```bash
# Sentry CLI installieren
npm install -g @sentry/cli

# Sentry Projekt einrichten
sentry-cli login
sentry-cli projects create macOS AINotizassistent

# DSN abrufen
SENTRY_DSN=$(sentry-cli projects info macOS AINotizassistent | grep dsn)
```

#### Crashlytics Setup (Firebase)

1. **Firebase Console**: https://console.firebase.google.com
2. **iOS App hinzufügen**
3. **GoogleService-Info.plist** herunterladen
4. **Firebase SDK integrieren**

## 🚀 Distribution Setup

### GitHub Releases

```bash
# GitHub Token erstellen (https://github.com/settings/tokens)
export GITHUB_TOKEN=your-github-token

# Release erstellen
./Scripts/distribute_github.sh \
  --repo yourusername/yourapp \
  --tag v1.0.0 \
  --assets Build/Distribution/ \
  --notes "Release Notes"
```

### Website Hosting

```bash
# Website Setup (Netlify Beispiel)
# Netlify CLI installieren
npm install -g netlify-cli

# Website deployen
netlify deploy --prod --dir=website-dist

# GitHub Pages Setup
git checkout -b gh-pages
git push origin gh-pages
```

### App Store Connect

```bash
# App erstellen
./Scripts/appstore_connect.sh create-app \
  --title "AINotizassistent" \
  --bundle-id com.yourcompany.AINotizassistent \
  --category productivity \
  --rating "4+"

# Screenshot-Verzeichnis
mkdir -p screenshots/ios
mkdir -p screenshots/ipad

# Screenshots hochladen (manuell über App Store Connect)
# Oder automatisiert mit Skript
./Scripts/appstore_connect.sh upload-screenshots \
  --app-id YOUR_APP_ID \
  --path screenshots/
```

## 🔍 Validierung

### Build Validation

```bash
# Build-Checks
./Scripts/validate_build.sh --app-path Build/Release/AINotizassistent.app

# Code Signing Verification
codesign --verify --verbose=4 Build/Release/AINotizassistent.app
spctl -t exec -vv Build/Release/AINotizassistent.app

# Notarization Check
xcrun stapler validate Build/Release/AINotizassistent.app
```

### App Store Validation

```bash
# App Store Konformität prüfen
./Scripts/validate_app_store.sh --app-path Build/Release/AINotizassistent.app

# Private Frameworks prüfen
find Build/Release/AINotizassistent.app -name "*.framework" | grep -v Apple

# Hardcoded Paths prüfen
find Build/Release/AINotizassistent.app -name "*.dylib" -o -name "*.app" | xargs otool -L | grep "/usr/local"
```

## 🐛 Debugging

### Häufige Probleme

#### Code Signing Issues

```bash
# Signierte identities anzeigen
security find-identity -v -p codesigning

# Zertifikat Details
security find-certificate -c "Developer ID Application" -p

# Signatur entfernen
codesign --remove-signature /path/to/app

# Neu signieren
codesign --force --sign "Developer ID Application: TEAM_ID" /path/to/app
```

#### Notarization Problems

```bash
# Notarization Log abrufen
xcrun notarytool log 1

# Notarization Status prüfen
xcrun notarytool info SUBMISSION_ID

# Staple Operation
xcrun stapler validate /path/to/app
```

#### Build Errors

```bash
# Detaillierte Build Logs
xcodebuild -project YourApp.xcodeproj -scheme YourApp -verbose

# Clean Build
xcodebuild clean -project YourApp.xcodeproj -scheme YourApp
rm -rf ~/Library/Developer/Xcode/DerivedData

# Build mit spezifischen Flags
xcodebuild build \
  -project YourApp.xcodeproj \
  -scheme YourApp \
  -configuration Release \
  GCC_PREPROCESSOR_DEFINITIONS="DEBUG=1" \
  ONLY_ACTIVE_ARCH=NO
```

## 📚 Weitere Ressourcen

### Dokumentation

- [Xcode Build Settings Reference](https://developer.apple.com/library/archive/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Notarization Guide](https://developer.apple.com/documentation/notarization)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)

### Tools

- **Fastlane**: Automatisierung für iOS/macOS
- **XcodeGen**: YAML-basierte Xcode Projekt-Generierung
- **SwiftGen**: Asset-Code-Generierung
- **SwiftLint**: Swift Code-Linting

### Community

- [Apple Developer Forums](https://developer.apple.com/forums/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/macos+swift)
- [GitHub Discussions](https://github.com/sparkle-project/Sparkle/discussions)

---

**Bei Problemen**: Konsultieren Sie das [Troubleshooting Guide](TROUBLESHOOTING.md) oder erstellen Sie ein Issue im Projekt-Repository.