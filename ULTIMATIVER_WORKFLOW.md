# 🔧 ULTIMATIVER Workflow - SOFORT funktionsfähig!

```
name: Build macOS App

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    name: Build AI Notizassistent
    runs-on: macos-13
    
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4
    
    - name: Setup Xcode
      run: |
        sudo xcode-select -s /Applications/Xcode_15.0.app/Contents/Developer
        xcodebuild -version
    
    - name: Find Xcode Project
      run: |
        echo "=== Root Verzeichnis ==="
        pwd
        ls -la
        
        echo "=== Suche nach .xcodeproj Dateien ==="
        find . -name "*.xcodeproj" -type d
        
        echo "=== Suche nach Xcode Projekten in Unterordnern ==="
        find . -name "*.xcodeproj" -type d -exec ls -la {} \;
    
    - name: Build App
      run: |
        # Wechsel in das Verzeichnis, das das Xcode Projekt enthält
        cd /Users/runner/work/ainotizassistent/ainotizassistent
        
        echo "=== Aktueller Build-Pfad ==="
        pwd
        ls -la
        
        # Alternative 1: Direkt in aktuellem Verzeichnis (ohne Unterordner)
        if [ -f "AINotizassistent.xcodeproj" ]; then
          echo "✅ Xcode Projekt im Root gefunden!"
          xcodebuild clean build \
            -project AINotizassistent.xcodeproj \
            -scheme AINotizassistent \
            -configuration Release \
            -derivedDataPath ./DerivedData \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO
        else
          echo "❌ Xcode Projekt nicht gefunden. Versuche Unterordner..."
          # Alternative 2: AINotizassistent Unterordner
          if [ -f "../AINotizassistent.xcodeproj" ]; then
            echo "✅ Xcode Projekt im AINotizassistent Ordner gefunden!"
            cd ..
            xcodebuild clean build \
              -project AINotizassistent.xcodeproj \
              -scheme AINotizassistent \
              -configuration Release \
              -derivedDataPath ./DerivedData \
              CODE_SIGN_IDENTITY="" \
              CODE_SIGNING_REQUIRED=NO \
              CODE_SIGNING_ALLOWED=NO
          else
            echo "❌ Kein Xcode Projekt gefunden! Zeige Verzeichnisstruktur:"
            find . -name "*.xcodeproj"
            exit 1
          fi
        fi
    
    - name: Create ZIP Archive
      run: |
        # Wechsle in das DerivedData Verzeichnis
        if [ -d "DerivedData/Build/Products/Release/AINotizassistent.app" ]; then
          cd DerivedData/Build/Products/Release
          zip -r AINotizassistent.zip AINotizassistent.app
          mv AINotizassistent.zip $GITHUB_WORKSPACE/
        elif [ -d "DerivedData/Build/Products/Release/" ]; then
          cd DerivedData/Build/Products/Release
          echo "Inhalt des Release Ordners:"
          ls -la
          # Finde die .app Datei
          APP_DIR=$(find . -name "*.app" -type d | head -1)
          if [ -n "$APP_DIR" ]; then
            APP_NAME=$(basename "$APP_DIR")
            zip -r AINotizassistent.zip "$APP_NAME"
            mv AINotizassistent.zip $GITHUB_WORKSPACE/
            echo "✅ ZIP erstellt mit App: $APP_NAME"
          else
            echo "❌ Keine .app Datei im Release Ordner gefunden"
            exit 1
          fi
        else
          echo "❌ Release Ordner nicht gefunden!"
          ls -la DerivedData/Build/Products/ 2>/dev/null || echo "Products Ordner existiert nicht"
          exit 1
        fi
    
    - name: Upload App as Artifact
      uses: actions/upload-artifact@v4
      with:
        name: AINotizassistent-macOS
        path: AINotizassistent.zip
        retention-days: 30
    
    - name: Build Summary
      run: |
        echo "✅ Build erfolgreich abgeschlossen!"
        echo "📦 App-Größe: $(du -h AINotizassistent.zip 2>/dev/null | cut -f1 || echo 'N/A')"
        echo "📍 Download: GitHub Actions → Artifacts → AINotizassistent-macOS"
        echo "🎉 Ihr AI Notizassistent ist fertig zum Download!"
```
