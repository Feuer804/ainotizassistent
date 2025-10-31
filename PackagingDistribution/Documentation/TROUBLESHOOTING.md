# Troubleshooting Guide - AINotizassistent Packaging & Distribution

## 🚨 Häufige Probleme und Lösungen

### Build-Probleme

#### ❌ Build Failed - "No such file or directory"

**Symptome:**
```
error: No such file or directory: '/path/to/AINotizassistent/AINotizassistent.xcodeproj'
```

**Lösung:**
```bash
# Projekt-Struktur prüfen
ls -la /path/to/your/project/
ls -la /path/to/your/project/AINotizassistent/

# Xcode Projekt existiert?
find /path/to/your/project -name "*.xcodeproj" -type d

# Falls nicht vorhanden: Xcode Projekt erstellen
./Scripts/create_xcode_project.sh --app-name AINotizassistent --bundle-id com.yourcompany.AINotizassistent
```

**Prävention:**
```bash
# Vor Build prüfen
./Scripts/validate_project.sh --path /path/to/your/project
```

#### ❌ Build Failed - "Unable to find matching architecture"

**Symptome:**
```
ld: symbol(s) not found for architecture x86_64
```

**Lösung:**
```bash
# Architecture-Settings prüfen
xcodebuild -project YourApp.xcodeproj -scheme YourApp -showBuildSettings | grep ARCHS

# Build Script anpassen
./Scripts/build_app.sh --configuration Release --archs "x86_64 arm64" --only-active-arch NO
```

#### ❌ Swift Compilation Error

**Symptome:**
```
error: Values of type 'String' cannot be used as boolean; did you mean '!(a.isEmpty)'?
```

**Lösung:**
```bash
# Swift Linting aktivieren
swiftlint --strict

# Häufige Fehler beheben:
# 1. Bool-String Vergleiche
# Alt: if myString == "true"
# Neu: if myString == "true"

# 2. Force Casts vermeiden
# Alt: let url = URL(string: urlString)!
# Neu: let url = URL(string: urlString) ?? defaultURL
```

### Code Signing Probleme

#### ❌ "No matching signing identity found"

**Symptome:**
```
error: No matching signing identity found for Team ID: YOUR_TEAM_ID
```

**Lösung:**
```bash
# Verfügbare Signierungen anzeigen
security find-identity -v -p codesigning

# Team ID prüfen
security find-identity -v -p codesigning | grep "Developer ID Application"

# Zertifikat exportieren falls fehlend
# 1. Xcode > Preferences > Accounts
# 2. Developer Account auswählen
# 3. Download All Profiles
```

**Prävention:**
```bash
# Team ID Environment Variable setzen
export TEAM_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk '{print $2}' | cut -d'=' -f2 | tr -d '"')
```

#### ❌ "Code signature invalid"

**Symptome:**
```
spctl: the specified path "/path/to/app.app" could not be opened
```

**Lösung:**
```bash
# Signatur entfernen
codesign --remove-signature /path/to/app

# Neu signieren mit korrektem Identity
codesign --force --sign "Developer ID Application: YOUR_TEAM_ID" /path/to/app

# Signatur verifizieren
codesign --verify --verbose=4 /path/to/app
spctl -t exec -vv /path/to/app
```

#### ❌ "Entitlements file not found"

**Symptome:**
```
error: File not found: /path/to/app/Entitlements.plist
```

**Lösung:**
```bash
# Entitlements-Datei erstellen
cat > /path/to/your/app/YourApp.entitlements << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
EOF

# Xcode Build Settings anpassen
CODE_SIGN_ENTITLEMENTS = YourApp/YourApp.entitlements
```

### Notarization Probleme

#### ❌ "Notarization failed - Unable to validate software"

**Symptome:**
```
The validation of the software for notarization failed.
```

**Lösung:**
```bash
# Detaillierte Logs abrufen
xcrun notarytool log SUBMISSION_ID

# Häufige Ursachen:
# 1. Fehlende Signatur: App zuerst signieren
# 2. Ungültige Entitlements: Info.plist prüfen
# 3. Private Frameworks: Nur genehmigte Frameworks verwenden
```

#### ❌ "The binary is not signed with a valid Developer ID"

**Symptome:**
```
Notarization: The binary is not signed with a valid Developer ID application signing certificate.
```

**Lösung:**
```bash
# Signierung mit Developer ID prüfen
codesign -dv --verbose=4 /path/to/app

# Developer ID Certificate verwenden
codesign --force --sign "Developer ID Application: YOUR_TEAM_ID" /path/to/app

# Signatur erneut prüfen
codesign -dv --verbose=4 /path/to/app
```

#### ❌ "Staple operation failed"

**Symptome:**
```
The stapler tool was unable to staple the ticket.
```

**Lösung:**
```bash
# Notarization Status prüfen
xcrun notarytool info SUBMISSION_ID

# Staple Operation wiederholen
xcrun stapler staple /path/to/app

# Falls Fehler weiterhin: Notarization erneut einreichen
xcrun notarytool submit /path/to/app.zip --keychain-profile PROFILE --wait
xcrun stapler staple /path/to/app
```

### App Store Probleme

#### ❌ "Invalid Binary - Private frameworks detected"

**Symptome:**
```
Invalid Binary: Your app contains private APIs or uses private frameworks.
```

**Lösung:**
```bash
# Private Frameworks finden
find /path/to/app -name "*.framework" | grep -v Apple

# Ersetzung:
# Sparkle Framework: Sparkle.xcframework verwenden
# React Native: Nur React Native macOS verwenden
# Firebase: Nur offizielle Firebase Frameworks

# Build Clean
./Scripts/build_app.sh --clean --configuration Release
```

#### ❌ "Invalid Binary - Hardcoded paths detected"

**Symptome:**
```
Invalid Binary: Your app contains hardcoded file paths or library paths.
```

**Lösung:**
```bash
# Hardcoded Pfade finden
find /path/to/app -name "*.dylib" -o -name "*.app" | xargs otool -L

# Lösungen:
# 1. Relative Pfade verwenden
# 2. @executable_path/ verwenden
# 3. Library Search Paths prüfen

# CMake/Autoconf Projekte: RPATH konfigurieren
install_name_tool -change "/usr/local/lib/libxxx.dylib" "@executable_path/libxxx.dylib" /path/to/binary
```

#### ❌ "App Store Review Rejection - Functionality"

**Symptome:**
```
Your app doesn't meet the minimum functionality requirements.
```

**Lösung:**
```bash
# App Store Konformität prüfen
./Scripts/validate_app_store.sh --app-path /path/to/app

# Häufige Probleme:
# 1. App startet nicht: Main.storyboard oder Info.plist prüfen
# 2. Leere App: Mehr als nur Hello World
# 3. Test-Modus: Alle Test-Ausgaben entfernen
```

### Update System Probleme

#### ❌ "Sparkle Update Failed"

**Symptome:**
```
Sparkle: Error: The update could not be completed.
```

**Lösung:**
```bash
# Appcast Feed prüfen
curl -s https://yourdomain.com/appcast.xml | xmllint --format -

# DSA Signature verifizieren
openssl dgst -sha1 -verify sparkle_dsa_pub.pem -signature update_signature update.zip

# Common Issues:
# 1. Ungültige DSA Signature
# 2. Broken Appcast XML
# 3. Update URL nicht erreichbar
```

#### ❌ "Update Download Failed"

**Symptome:**
```
Sparkle: Error: Could not download update from server.
```

**Lösung:**
```bash
# Update URL testen
curl -I https://yourdomain.com/downloads/update.zip

# Server Response prüfen
curl -v https://yourdomain.com/downloads/update.zip

# Häufige Probleme:
# 1. HTTP 404: File nicht verfügbar
# 2. Certificate Error: SSL-Zertifikat prüfen
# 3. Redirect Loop: Appcast Feed URL prüfen
```

### License System Probleme

#### ❌ "License Validation Failed"

**Symptome:**
```
License Error: Invalid license key
```

**Lösung:**
```bash
# License Key Format prüfen
echo "LICENSE-KEY-FORMAT: XXXXX-XXXXX-XXXXX-XXXXX"

# Server Connection testen
curl -X POST https://your-license-server.com/api/validate \
  -H "Content-Type: application/json" \
  -d '{"licenseKey": "your-license-key"}'

# Local Validation
./Scripts/validate_license.sh --key your-license-key --verify-only
```

#### ❌ "Trial Period Expired"

**Symptome:**
```
Trial has expired. Please purchase a license to continue.
```

**Lösung:**
```bash
# Trial Status prüfen
defaults read com.yourcompany.yourapp trialStartDate
defaults read com.yourcompany.yourapp trialUsed

# Trial zurücksetzen (nur für Testing)
defaults delete com.yourcompany.yourapp trialStartDate
defaults delete com.yourcompany.yourapp trialUsed

# License erwerben
# Upgrade Prompt anzeigen
./Scripts/show_upgrade_prompt.sh
```

## 🔧 Debug-Tools

### Build-Debugging

```bash
# Detaillierte Build Logs
xcodebuild -project YourApp.xcodeproj -scheme YourApp -verbose -configuration Release

# Build Settings anzeigen
xcodebuild -project YourApp.xcodeproj -scheme YourApp -showBuildSettings

# Build Timeline
xcodebuild -project YourApp.xcodeproj -scheme YourApp -timeline

# Custom Build Variables
xcodebuild -project YourApp.xcodeproj -scheme YourApp GCC_PREPROCESSOR_DEFINITIONS="DEBUG=1" ONLY_ACTIVE_ARCH=NO
```

### Signing-Debugging

```bash
# Signierte Binaries anzeigen
codesign -vv /path/to/app --deep

# Signing Chain verifizieren
security verify-cert -c /path/to/app -v

# entitlements extrahieren
codesign -d --entitlements - /path/to/app

# Signierte Libraries prüfen
find /path/to/app -type f -exec codesign -v {} \;
```

### Notarization-Debugging

```bash
# Notarization History
xcrun notarytool history

# Notarization Details
xcrun notarytool info SUBMISSION_ID

# Notarization Logs
xcrun notarytool log SUBMISSION_ID

# Staple Status prüfen
xcrun stapler validate -v /path/to/app
```

### App Store Debugging

```bash
# Binary Analysis
otool -l /path/to/app/Contents/MacOS/YourApp

# Dependencies prüfen
find /path/to/app -type f -exec otool -L {} \; | grep "/usr/local\|/opt/homebrew"

# Private APIs prüfen
strings /path/to/app/Contents/MacOS/YourApp | grep -i "private\|undocumented"

# App Store Guidelines Konformität
./Scripts/validate_guidelines.sh --app-path /path/to/app
```

## 🆘 Emergency Fixes

### Build komplett neu erstellen

```bash
# Vollständiger Clean Build
./Scripts/clean_build.sh --full-clean

# Nur Xcode DerivedData löschen
rm -rf ~/Library/Developer/Xcode/DerivedData

# CocoaPods/Carthage Cache löschen
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/.cocoapods/repos/trunk
rm -rf Pods/
rm -rf ~/.cache/Carthage

# Build erneut versuchen
./Scripts/build_app.sh --configuration Release --clean
```

### Zertifikat-Probleme beheben

```bash
# Keychain öffnen
open "/Applications/Utilities/Keychain Access.app"

# Entwickler-Zertifikate löschen (falls korrupt)
# Developer ID Application: YOUR_TEAM_ID
# Developer ID Installer: YOUR_TEAM_ID

# Aus Xcode Preferences entfernen
# Preferences > Accounts > Download Manual Profiles

# Profile erneut herunterladen
xcodebuild -downloadPackages
```

### Notarization komplett wiederholen

```bash
# App komplett neu signieren
./Scripts/resign_app.sh --app-path /path/to/app --team-id YOUR_TEAM_ID

# ZIP erstellen
cd /path/to/app/..
zip -r app.zip YourApp.app

# Notarization erneut
xcrun notarytool submit app.zip --keychain-profile PROFILE --wait

# Staple
xcrun stapler staple YourApp.app
```

### App Store Binary neu hochladen

```bash
# Archive erstellen
xcodebuild archive \
  -project YourApp.xcodeproj \
  -scheme YourApp \
  -archivePath build.xcarchive

# Export für App Store
xcodebuild -exportArchive \
  -archivePath build.xcarchive \
  -exportPath export \
  -exportOptionsPlist exportOptions.plist

# Hochladen
xcrun altool --upload-app \
  -f export/YourApp.ipa \
  -u your-apple-id@example.com \
  -p your-app-specific-password \
  -t ios
```

## 📊 Monitoring und Logs

### Log-Dateien

```bash
# Build Logs
tail -f build.log

# Signing Logs
security show-keychain-log

# Notarization Logs
xcrun notarytool log LATEST_SUBMISSION_ID

# App Launch Logs
log stream --predicate 'process == "YourApp"'
```

### Performance Monitoring

```bash
# App Performance
 Instruments.app > Time Profiler > Start Recording

# Memory Leaks
 Instruments.app > Leaks > Start Recording

# File System Activity
 Instruments.app > File Activity > Start Recording

# Network Activity
 Instruments.app > Network > Start Recording
```

### Crash Analysis

```bash
# Crash Reports finden
ls ~/Library/Logs/DiagnosticReports/YourApp_*.crash

# Crash Report analysieren
symbolicatecrash YourApp.crash path/to/YourApp.app.dSYM

# System Logs
log show --predicate 'process == "YourApp"' --last 1h
```

## 🔄 Recovery Procedures

### Vollständiger System-Reset

```bash
#!/bin/bash
# emergency_reset.sh

echo "🚨 Starting Emergency System Reset..."

# 1. Clean Build Directory
rm -rf Build/
rm -rf DerivedData/
rm -rf *.xcworkspace/

# 2. Remove Caches
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/.cache/Carthage
rm -rf Pods/
rm -rf Carthage/

# 3. Reset Xcode Settings
rm -rf ~/Library/Developer/Xcode/DerivedData/
rm -rf ~/Library/Developer/Xcode/iOS\ Device\ Support/

# 4. Reset Keychain (CAUTION!)
# security delete-identity -c "Developer ID Application: YOUR_TEAM_ID"

# 5. Clean Environment
unset TEAM_ID
unset DEVELOPER_ID_APPLICATION
unset ASC_API_KEY_ID

echo "✅ Emergency Reset Complete"
echo "Please restart your computer and reconfigure the system."
```

### Backup und Recovery

```bash
# Backup wichtiger Dateien
./Scripts/backup_config.sh --output ./backup/

# Recovery aus Backup
./Scripts/restore_config.sh --backup ./backup/
```

---

**Bei ungelösten Problemen:**

1. Konsultieren Sie die [Apple Developer Documentation](https://developer.apple.com/documentation/)
2. Prüfen Sie die [GitHub Issues](https://github.com/your-repo/issues)
3. Kontaktieren Sie den [Support](mailto:support@yourcompany.com)

**Notfall-Hotline:** [Ihre Support-Kontakte hier einfügen]