#!/bin/bash

# 🚀 GitHub Actions Setup - Schnell-Kommandos
# Kopieren Sie diese Befehle und passen Sie sie an!

echo "=================================="
echo "🚀 AI Notizassistent - GitHub Setup"
echo "=================================="
echo ""

# WICHTIG: Ersetzen Sie IHR_USERNAME mit Ihrem GitHub Username!
GITHUB_USERNAME="IHR_USERNAME"
REPO_NAME="ainotizassistent"

echo "📋 Schritt 1: Git konfigurieren"
git config --global user.name "Ihr Name"
git config --global user.email "ihre.email@example.com"

echo ""
echo "📋 Schritt 2: Remote hinzufügen"
echo "Befehl: git remote add origin https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
echo ""
read -p "Drücken Sie Enter, um fortzufahren..."

git remote add origin https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git

echo ""
echo "📋 Schritt 3: Branch auf main umbenennen"
git branch -M main

echo ""
echo "📋 Schritt 4: Code hochladen"
echo "Dies kann nach GitHub Username und Token fragen!"
git push -u origin main

echo ""
echo "=================================="
echo "✅ Upload erfolgreich!"
echo "=================================="
echo ""
echo "🎯 Nächste Schritte:"
echo "1. Gehen Sie zu: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
echo "2. Klicken Sie: 'Actions' Tab"
echo "3. Klicken Sie: 'Run workflow'"
echo "4. Warten Sie 5-10 Minuten"
echo "5. Laden Sie die App unter 'Artifacts' herunter"
echo ""
echo "🎉 Viel Erfolg!"
