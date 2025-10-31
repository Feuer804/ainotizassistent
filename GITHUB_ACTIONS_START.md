# 🚀 GitHub Actions Setup - Schritt für Schritt

## ✅ Status: Workflow-Datei ist bereit!

Die GitHub Actions Workflow-Datei existiert bereits in `.github/workflows/build-macos.yml`

---

## 📋 **Nächste Schritte:**

### **Schritt 1: GitHub Repository erstellen** (2 Min)

1. **Gehen Sie zu:** https://github.com/new
2. **Repository Name:** `ainotizassistent` (oder beliebiger Name)
3. **Visibility:** Public (für kostenlose GitHub Actions) ✅
4. **WICHTIG:** ❌ NICHT "Add a README" ankreuzen
5. **Klicken Sie:** "Create repository"

---

### **Schritt 2: Repository mit Code verbinden** (2 Min)

Nach Repository-Erstellung zeigt GitHub Ihnen Befehle. Verwenden Sie diese in GitHub Codespaces:

```bash
# In Ihrem Codespaces Terminal:
cd /workspace

# Remote hinzufügen (ERSETZEN Sie USERNAME/REPONAME!)
git remote add origin https://github.com/IHR_USERNAME/ainotizassistent.git

# Branch umbenennen auf main
git branch -M main

# Alles hochladen
git push -u origin main
```

**Beispiel:**
Wenn Ihr GitHub Username "MaxMuster" ist:
```bash
git remote add origin https://github.com/MaxMuster/ainotizassistent.git
git branch -M main
git push -u origin main
```

---

### **Schritt 3: GitHub Actions Workflow starten** (1 Min)

1. **Gehen Sie zu:** https://github.com/IHR_USERNAME/ainotizassistent
2. **Klicken Sie:** "Actions" Tab (oben)
3. **Wählen Sie:** "Build macOS App" (links)
4. **Klicken Sie:** "Run workflow" Button (rechts, grün)
5. **Bestätigen Sie:** "Run workflow"

---

### **Schritt 4: Build läuft automatisch** (5-10 Min)

Sie sehen jetzt:
- 🟡 Gelb = Build läuft
- ✅ Grün = Build erfolgreich
- ❌ Rot = Fehler (sagen Sie mir Bescheid!)

**Live-Logs ansehen:**
- Klicken Sie auf den gelben/laufenden Workflow
- Klicken Sie auf "Build AI Notizassistent"
- Sehen Sie Live-Output!

---

### **Schritt 5: App herunterladen** (1 Min)

Nach erfolgreichem Build:

1. **Scroll nach unten** auf der Workflow-Seite
2. **Finden Sie:** "Artifacts" Sektion
3. **Klicken Sie:** "AINotizassistent-macOS"
4. **Download startet:** ZIP-Datei (ca. 10-50 MB)

---

## 📦 **Was Sie erhalten:**

```
AINotizassistent-macOS.zip
└── AINotizassistent.app    ← Ihre fertige macOS App!
```

**Entpacken & verwenden:**
```bash
# ZIP entpacken
unzip AINotizassistent-macOS.zip

# App starten
open AINotizassistent.app
```

---

## ⚠️ **"App kann nicht geöffnet werden"?**

Da die App nicht signiert ist, müssen Sie beim ersten Öffnen:

**Methode 1: Terminal**
```bash
xattr -cr /Pfad/zu/AINotizassistent.app
```

**Methode 2: Finder**
1. Rechtsklick auf `AINotizassistent.app`
2. "Öffnen" bei gedrückter ⌥ (Option)-Taste
3. "Öffnen" bestätigen im Dialog

---

## 🆘 **Brauchen Sie Hilfe?**

**Bei Push-Problemen:**
```bash
# Username/Password wird abgefragt?
# → Verwenden Sie "Personal Access Token" statt Passwort
# → Erstellen unter: https://github.com/settings/tokens
```

**Bei Build-Fehlern:**
- Screenshot der Fehlermeldung
- Zeigen Sie mir die GitHub Actions Logs

---

## ✅ **Zusammenfassung**

1. ✅ GitHub Repository erstellen
2. ✅ Code hochladen (`git push`)
3. ✅ Workflow starten ("Run workflow")
4. ✅ Warten (5-10 Min)
5. ✅ App herunterladen (Artifacts)

**Gesamtzeit: ~15 Minuten**

---

## 🎉 **Danach haben Sie:**

✅ Funktionierende macOS App (.app Datei)
✅ Automatischer Build bei jedem Code-Update
✅ Kostenlos (2000 Build-Minuten/Monat)

**Starten Sie mit Schritt 1! Ich helfe bei Problemen.**
