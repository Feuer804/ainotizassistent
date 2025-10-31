# 🚀 GitHub Actions - Automatischer macOS App Build

## ✅ **Lösung für Ihr Problem**

GitHub Codespaces = Linux → **kein xcodebuild**
**Lösung:** GitHub Actions mit macOS Runner → **funktioniert perfekt!**

---

## 📋 **Schritt-für-Schritt Anleitung**

### **1. Repository vorbereiten**

```bash
# Falls noch nicht auf GitHub:
cd /workspaces/ainotizassistent
git add .
git commit -m "Add GitHub Actions workflow for macOS build"
git push origin main
```

### **2. Workflow-Datei ist bereits erstellt! ✅**

Die Datei `.github/workflows/build-macos.yml` ist bereits in Ihrem Repository!

**Sie müssen nur noch:**
1. Die Datei zu GitHub pushen (siehe oben)
2. Auf GitHub.com zum Repository gehen
3. Workflow manuell starten (siehe unten)

---

## 🎯 **Workflow manuell starten**

### **Auf GitHub.com:**

1. **Gehen Sie zu Ihrem Repository**
   - `https://github.com/IHR_USERNAME/ainotizassistent`

2. **Klicken Sie auf "Actions" Tab**
   - Oben in der Navigation

3. **Wählen Sie "Build macOS App" Workflow**
   - Links in der Sidebar

4. **Klicken Sie "Run workflow"**
   - Rechts oben, grüner Button
   - Branch: `main` auswählen
   - "Run workflow" bestätigen

5. **Warten Sie 5-10 Minuten**
   - Workflow wird ausgeführt
   - Sie sehen Live-Logs

6. **App herunterladen**
   - Nach Abschluss: Scroll nach unten
   - "Artifacts" Sektion
   - Klick auf "AINotizassistent-macOS"
   - ZIP wird heruntergeladen

---

## 📦 **Was Sie erhalten**

Nach erfolgreichem Build:

```
AINotizassistent-macOS.zip
├── AINotizassistent.app          ← Ihre fertige macOS App!
└── AINotizassistent.zip          ← Alternativ-Format
```

**Die `.app` Datei können Sie direkt verwenden!**

---

## 🔧 **Workflow-Features**

✅ **Automatische Builds** bei jedem Push auf `main`
✅ **Manuelle Builds** über "Run workflow" Button
✅ **Keine Code-Signierung** (funktioniert für Development)
✅ **30 Tage Artifact-Speicherung**
✅ **Kostenlos** (2000 Minuten/Monat für public repos)

---

## ⚙️ **Workflow-Details**

### **Was der Workflow macht:**

1. **Checkout** - Lädt Ihr Repository herunter
2. **Xcode Setup** - Wählt richtige Xcode-Version
3. **Build** - Kompiliert Ihre Swift-App
4. **Package** - Erstellt ZIP-Archiv
5. **Upload** - Stellt App als Artifact bereit

### **Build-Konfiguration:**

```yaml
- Plattform: macOS 13 (Ventura)
- Xcode: 15.0
- Konfiguration: Release
- Code Signing: Deaktiviert (für Development OK)
```

---

## 🎨 **Optional: Code-Signierung aktivieren**

Falls Sie die App verteilen möchten, brauchen Sie Code-Signierung:

### **Secrets hinzufügen:**

1. **GitHub Repository** → Settings → Secrets and variables → Actions
2. **Neue Secrets hinzufügen:**
   - `APPLE_CERTIFICATE_BASE64` - Ihr Developer Certificate (Base64)
   - `APPLE_CERTIFICATE_PASSWORD` - Passwort für Certificate
   - `APPLE_TEAM_ID` - Ihre Team ID

3. **Workflow anpassen:**

```yaml
- name: Import Certificate
  env:
    CERTIFICATE_BASE64: ${{ secrets.APPLE_CERTIFICATE_BASE64 }}
    CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
  run: |
    echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
    security create-keychain -p actions build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p actions build.keychain
    security import certificate.p12 -k build.keychain -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: -s -k actions build.keychain

- name: Build Signed App
  run: |
    xcodebuild clean build \
      -project AINotizassistent.xcodeproj \
      -scheme AINotizassistent \
      -configuration Release \
      CODE_SIGN_IDENTITY="Developer ID Application: YOUR_TEAM_NAME"
```

---

## 🐛 **Troubleshooting**

### **Build schlägt fehl?**

**Fehlermeldung ansehen:**
1. GitHub Actions → Fehlgeschlagener Workflow
2. Klick auf rotes "X"
3. Logs durchlesen

**Häufige Probleme:**

| Problem | Lösung |
|---------|--------|
| `Scheme not found` | Prüfen Sie Scheme-Namen in Xcode |
| `Build failed` | Dependency-Probleme? Siehe Logs |
| `No .app found` | Build-Pfad stimmt nicht |

### **App funktioniert nicht auf Ihrem Mac?**

**"App kann nicht geöffnet werden" (unsigniert):**

```bash
# Im Terminal:
xattr -cr /Pfad/zur/AINotizassistent.app
```

**Oder:**
- Rechtsklick auf App
- "Öffnen" mit gedrückter ⌥ (Option)-Taste
- "Öffnen" bestätigen

---

## 💡 **Tipps**

### **Schnellere Builds:**
- Deaktivieren Sie Tests im Workflow
- Cachen Sie Dependencies
- Verwenden Sie `macos-latest` statt `macos-13`

### **Automatische Releases:**
- Bei Git Tags automatisch Release erstellen
- App zu Release anhängen
- Siehe GitHub Actions Marketplace: `softprops/action-gh-release`

---

## 📞 **Nächste Schritte**

**Jetzt:**
1. ✅ Code zu GitHub pushen
2. ✅ Workflow manuell starten
3. ✅ App herunterladen
4. ✅ Testen!

**Später (optional):**
- [ ] Code-Signierung einrichten
- [ ] Automatische Releases konfigurieren
- [ ] Notarization hinzufügen

---

## 🎉 **Fertig!**

**Ihre App wird jetzt auf echten macOS-Maschinen gebaut!**

GitHub Actions → 100% kostenlos → Echte macOS App

Haben Sie Fragen? Fragen Sie mich!
