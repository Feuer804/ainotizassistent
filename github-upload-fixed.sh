#!/bin/bash
# 🚀 Automatisches Setup für GitHub Upload
# Für: Feuer804

echo "🔧 Git konfigurieren..."
git config --global user.name "Feuer804"
git config --global user.email "feuer78787@gmail.com"

echo "🔗 GitHub Repository verbinden..."
git remote add origin https://github.com/Feuer804/ainotizassistent.git

echo "🌿 Branch auf main umbenennen..."
git branch -M main

echo "📤 Code hochladen..."
echo ""
echo "⚠️  WICHTIG: GitHub wird nach Username und Password fragen:"
echo "   Username: Feuer804"
echo "   Password: <Ihr Personal Access Token>"
echo ""
echo "   Noch kein Token? Erstellen Sie eines hier:"
echo "   https://github.com/settings/tokens/new"
echo "   (Haken bei 'repo' setzen!)"
echo ""

git push -u origin main

echo ""
echo "✅ Fertig!"
echo ""
echo "🎯 Nächster Schritt:"
echo "   1. Öffnen Sie: https://github.com/Feuer804/ainotizassistent"
echo "   2. Klicken Sie: 'Actions' Tab"
echo "   3. Klicken Sie: 'Run workflow'"
echo ""
