# 📝 Copy & Paste Befehle - GitHub Actions

## 🎯 **Schnellstart in 3 Schritten**

---

### **Schritt 1: GitHub Repository erstellen**

1. **Browser öffnen:** https://github.com/new
2. **Name eingeben:** `ainotizassistent`
3. **Public** wählen (für kostenlose GitHub Actions)
4. **Repository erstellen** (grüner Button)
5. **NICHT** "Add README" ankreuzen!

---

### **Schritt 2: Diese Befehle ausführen**

**WICHTIG:** Ersetzen Sie `IHR_USERNAME` mit Ihrem echten GitHub Username!

```bash
# Git konfigurieren (einmal ausführen)
git config --global user.name "Ihr Name"
git config --global user.email "ihre.email@example.com"

# Zum Workspace wechseln
cd /workspace

# Remote hinzufügen - ERSETZEN Sie IHR_USERNAME!
git remote add origin https://github.com/IHR_USERNAME/ainotizassistent.git

# Branch auf main umbenennen
git branch -M main

# Alles hochladen (GitHub fragt nach Username & Token)
git push -u origin main
```

**Beispiel für Username "maxmuster":**
```bash
git remote add origin https://github.com/maxmuster/ainotizassistent.git
git branch -M main
git push -u origin main
```

---

### **Schritt 3: Workflow starten**

**Auf GitHub.com:**

1. **Repository öffnen:** `https://github.com/IHR_USERNAME/ainotizassistent`
2. **Tab klicken:** "Actions"
3. **Workflow wählen:** "Build macOS App"
4. **Button klicken:** "Run workflow" (grün, rechts)
5. **Bestätigen:** "Run workflow"

**Dann warten:** 5-10 Minuten

---

## 📥 **App herunterladen**

Nach erfolgreichem Build:

1. **Workflow-Seite:** Grüner Haken = Fertig ✅
2. **Runterscrollen:** Bis "Artifacts"
3. **Klicken:** "AINotizassistent-macOS"
4. **Download:** ZIP-Datei (~10-50 MB)

---

## 🎉 **Fertig!**

**Sie haben jetzt:**
```
AINotizassistent.app  ← Ihre fertige macOS App!
```

**App öffnen:**
1. ZIP entpacken
2. Rechtsklick auf App → "Öffnen"
3. Bei Sicherheitswarnung: "Öffnen" bestätigen

---

## ⚠️ **Häufige Probleme**

### **Problem: "Username and password" abgefragt**

**Lösung:** GitHub benötigt einen Personal Access Token statt Passwort

1. **Token erstellen:** https://github.com/settings/tokens
2. **Button klicken:** "Generate new token (classic)"
3. **Scopes wählen:** `repo` (voller Repository-Zugriff)
4. **Token kopieren:** Speichern Sie ihn sicher!
5. **Bei "Password":** Token einfügen (nicht Ihr GitHub-Passwort!)

### **Problem: "remote origin already exists"**

```bash
# Remote löschen und neu hinzufügen
git remote remove origin
git remote add origin https://github.com/IHR_USERNAME/ainotizassistent.git
```

### **Problem: Build schlägt fehl (roter X)**

1. **Logs ansehen:** Actions → fehlgeschlagener Workflow → Build-Logs
2. **Fehlermeldung kopieren**
3. **Mir zeigen:** Ich helfe!

---

## 🆘 **Brauchen Sie Hilfe?**

**Sagen Sie mir:**
- Bei welchem Schritt Sie sind
- Welche Fehlermeldung Sie sehen
- Screenshot (falls möglich)

**Ich helfe sofort!**
