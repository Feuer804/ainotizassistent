# 🚀 GitHub Setup für Feuer804 - Schritt für Schritt

## ✅ Ihre Daten:
- **GitHub Username:** Feuer804
- **Email:** feuer78787@gmail.com
- **Repository Name:** ainotizassistent

---

## 📝 **SCHRITT 1: GitHub Repository erstellen** (2 Minuten)

### Was Sie tun müssen:

1. **Öffnen Sie diesen Link:** https://github.com/new

2. **Füllen Sie aus:**
   - **Repository name:** `ainotizassistent`
   - **Description:** (optional) z.B. "AI Notizassistent für macOS"
   - **Visibility:** ✅ **Public** (wichtig für kostenlose Builds!)
   - ❌ **NICHT ankreuzen:** "Add a README file"

3. **Klicken Sie:** Grüner Button "Create repository"

✅ **Fertig! Repository ist erstellt.**

---

## 💻 **SCHRITT 2: Code hochladen** (3 Minuten)

### Jetzt in GitHub Codespaces (dieses Terminal hier):

**Kopieren Sie diese Befehle nacheinander:**

```bash
# 1. Git konfigurieren
git config --global user.name "Feuer804"
git config --global user.email "feuer78787@gmail.com"
```

```bash
# 2. Ins richtige Verzeichnis wechseln
cd /workspace
```

```bash
# 3. Repository verbinden
git remote add origin https://github.com/Feuer804/ainotizassistent.git
```

```bash
# 4. Branch umbenennen
git branch -M main
```

```bash
# 5. Code hochladen
git push -u origin main
```

### ⚠️ **Was passiert bei Schritt 5?**

GitHub fragt nach **Username** und **Password**:

- **Username:** `Feuer804`
- **Password:** ❌ NICHT Ihr normales Passwort!
  - Sie brauchen ein **Personal Access Token**
  - Ich zeige Ihnen gleich, wie Sie das erstellen

---

## 🔑 **SCHRITT 2.5: Personal Access Token erstellen** (nur wenn gefragt)

**Wenn GitHub nach Passwort fragt:**

1. **Öffnen Sie:** https://github.com/settings/tokens/new

2. **Füllen Sie aus:**
   - **Note:** `Codespaces Upload`
   - **Expiration:** 90 days (oder länger)
   - **Select scopes:** ✅ Haken bei `repo` (ganz oben)

3. **Klicken Sie:** "Generate token" (grün, unten)

4. **WICHTIG:** Token wird EINMAL angezeigt!
   - Kopieren Sie ihn sofort!
   - Format: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx`

5. **Verwenden Sie Token statt Passwort:**
   ```
   Username: Feuer804
   Password: <HIER TOKEN EINFÜGEN>
   ```

✅ **Nach erfolgreichem Push:** Code ist auf GitHub!

---

## 🎬 **SCHRITT 3: Build starten** (1 Minute)

1. **Öffnen Sie:** https://github.com/Feuer804/ainotizassistent

2. **Klicken Sie:** Tab "Actions" (oben in der Mitte)

3. **Links sehen Sie:** "Build macOS App"
   - **Klicken Sie darauf**

4. **Rechts sehen Sie:** Blauer Button "Run workflow"
   - **Klicken Sie darauf**
   - Ein Dropdown öffnet sich

5. **Im Dropdown:** Nochmal grüner Button "Run workflow"
   - **Klicken Sie darauf**

✅ **Build startet automatisch!**

---

## ⏰ **SCHRITT 4: Warten** (5-10 Minuten)

Sie sehen jetzt eine Liste:

- 🟡 **Gelber Punkt = Build läuft gerade**
- ✅ **Grüner Haken = Build fertig!**
- ❌ **Rotes X = Fehler (sagen Sie mir Bescheid!)**

**Live zuschauen:**
1. Klicken Sie auf die gelbe Zeile
2. Klicken Sie auf "Build AI Notizassistent"
3. Sie sehen live, was passiert!

⏳ **Jetzt einfach warten...**

---

## 📥 **SCHRITT 5: App herunterladen** (1 Minute)

**Wenn Build fertig (grüner Haken):**

1. **Scrollen Sie runter** auf der Workflow-Seite

2. **Finden Sie:** Bereich "Artifacts"

3. **Klicken Sie:** "AINotizassistent-macOS"

4. **Download startet:** Eine ZIP-Datei (ca. 10-50 MB)

✅ **Sie haben jetzt:** `AINotizassistent-macOS.zip`

---

## 🎉 **SCHRITT 6: App verwenden** (auf Ihrem Mac)

```bash
# 1. ZIP entpacken
unzip AINotizassistent-macOS.zip

# 2. App starten
open AINotizassistent.app
```

### ⚠️ **Wenn macOS sagt "App kann nicht geöffnet werden":**

**Lösung 1 (Terminal):**
```bash
xattr -cr AINotizassistent.app
open AINotizassistent.app
```

**Lösung 2 (Finder):**
1. Rechtsklick auf `AINotizassistent.app`
2. Halten Sie ⌥ (Option-Taste) gedrückt
3. Klicken Sie "Öffnen"
4. Bestätigen Sie "Öffnen" im Dialog

✅ **App läuft!**

---

## 📊 **Zusammenfassung:**

| Schritt | Was | Dauer |
|---------|-----|-------|
| 1 | GitHub Repository erstellen | 2 Min |
| 2 | Code hochladen | 3 Min |
| 3 | Build starten | 1 Min |
| 4 | Warten | 5-10 Min |
| 5 | App herunterladen | 1 Min |
| 6 | App nutzen | 1 Min |
| **GESAMT** | | **~15 Min** |

---

## 🆘 **Bei Problemen:**

### Problem: "git push" funktioniert nicht
**Lösung:** Personal Access Token erstellen (siehe Schritt 2.5)

### Problem: Build ist rot (❌)
**Lösung:** 
1. Screenshot der Fehlermeldung machen
2. Mir zeigen, ich helfe!

### Problem: App öffnet nicht auf Mac
**Lösung:** 
```bash
xattr -cr AINotizassistent.app
```

---

## ✅ **Checkliste:**

- [ ] GitHub Repository erstellt
- [ ] Code hochgeladen (git push)
- [ ] Build gestartet
- [ ] Build erfolgreich (grün)
- [ ] App heruntergeladen
- [ ] App geöffnet auf Mac

---

## 🎯 **Bereit zum Starten?**

**Beginnen Sie mit SCHRITT 1:** https://github.com/new

Ich bin hier und helfe bei jedem Schritt! 🚀
