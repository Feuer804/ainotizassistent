//
//  StatusBarAppView.swift
//  StatusBarApp
//
//  SwiftUI View für erweiterte UI-Komponenten
//

import SwiftUI

struct StatusBarAppView: View {
    @State private var isActive = false
    @State private var lastUpdate = Date()
    @State private var statusMessage = "Bereit"
    @State private var isAutoSaveEnabled = true
    @State private var currentKIProvider = "OpenAI"
    @State private var currentStorageProvider = "iCloud"
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(isActive ? .green : .gray)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("StatusBarApp")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Status-Karte
            GroupBox("Anwendungsstatus") {
                VStack(alignment: .leading, spacing: 12) {
                    StatusRow(label: "Läuft", value: isActive ? "Ja" : "Nein", isActive: isActive)
                    StatusRow(label: "Letzte Aktualisierung", 
                             value: formatDate(lastUpdate), 
                             isActive: false)
                    StatusRow(label: "Menüleisten-Icon", value: "Aktiv", isActive: true)
                    StatusRow(label: "Global Shortcut", value: "⌘⇧N", isActive: true)
                }
            }
            
            // Aktionen
            GroupBox("Aktionen") {
                VStack(spacing: 8) {
                    Button(action: toggleStatus) {
                        HStack {
                            Image(systemName: isActive ? "pause.fill" : "play.fill")
                            Text(isActive ? "Stoppen" : "Starten")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Einstellungen öffnen") {
                        openSettings()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("KI-Einstellungen") {
                        openKISettings()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Auto-Save") {
                        toggleAutoSave()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Info") {
                        showInfo()
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            // Settings-Section mit Glassmorphism
            GroupBox("Einstellungen") {
                VStack(spacing: 12) {
                    HStack {
                        SettingsButtonView(
                            icon: "brain.head.profile",
                            title: "KI-Provider",
                            subtitle: getCurrentKIProvider(),
                            action: openKISettings
                        )
                        
                        SettingsButtonView(
                            icon: "internaldrive",
                            title: "Storage",
                            subtitle: getCurrentStorageProvider(),
                            action: openStorageSettings
                        )
                    }
                    
                    HStack {
                        SettingsButtonView(
                            icon: "doc.richtext",
                            title: "Auto-Save",
                            subtitle: isAutoSaveEnabled ? "Aktiv" : "Inaktiv",
                            action: toggleAutoSave
                        )
                        
                        SettingsButtonView(
                            icon: "keyboard",
                            title: "Shortcuts",
                            subtitle: "Konfigurieren",
                            action: openShortcutsSettings
                        )
                    }
                    
                    HStack {
                        SettingsButtonView(
                            icon: "bell",
                            title: "Benachrichtigungen",
                            subtitle: "Privacy & Alerts",
                            action: openNotificationSettings
                        )
                        
                        SettingsButtonView(
                            icon: "questionmark.circle",
                            title: "Hilfe",
                            subtitle: "Onboarding & Docs",
                            action: openHelp
                        )
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 500)
    }
    
    // MARK: - Actions
    
    private func toggleStatus() {
        isActive.toggle()
        statusMessage = isActive ? "Aktiv" : "Bereit"
        lastUpdate = Date()
    }
    
    private func openSettings() {
        // Settings-Dialog öffnen
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showSettings()
        }
    }
    
    private func openKISettings() {
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let statusBarController = appDelegate.getStatusBarController() {
            statusBarController.settingsCoordinator?.showKISettings()
        }
    }
    
    private func openStorageSettings() {
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let statusBarController = appDelegate.getStatusBarController() {
            statusBarController.settingsCoordinator?.showStorageSettings()
        }
    }
    
    private func toggleAutoSave() {
        isAutoSaveEnabled.toggle()
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let statusBarController = appDelegate.getStatusBarController() {
            statusBarController.settingsCoordinator?.toggleAutoSave()
        }
    }
    
    private func openShortcutsSettings() {
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let statusBarController = appDelegate.getStatusBarController() {
            statusBarController.settingsCoordinator?.showShortcutsSettings()
        }
    }
    
    private func openNotificationSettings() {
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let statusBarController = appDelegate.getStatusBarController() {
            statusBarController.settingsCoordinator?.showNotificationSettings()
        }
    }
    
    private func openHelp() {
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let statusBarController = appDelegate.getStatusBarController() {
            statusBarController.settingsCoordinator?.showHelp()
        }
    }
    
    private func showInfo() {
        showAboutDialog()
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentKIProvider() -> String {
        return currentKIProvider
    }
    
    private func getCurrentStorageProvider() -> String {
        return currentStorageProvider
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func showSettingsDialog() {
        let alert = NSAlert()
        alert.messageText = "Einstellungen"
        alert.informativeText = """
        Konfigurationsoptionen für StatusBarApp:
        
        • Globale Tastenkombination: ⌘⇧N
        • Menüleisten-Integration aktiviert
        • Automatische Status-Updates aktiviert
        
        (Diese Funktion wird in der nächsten Version implementiert)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showAboutDialog() {
        let alert = NSAlert()
        alert.messageText = "Über StatusBarApp"
        alert.informativeText = """
        StatusBarApp v1.0
        
        Eine moderne macOS Menüleisten-Anwendung
        
        Funktionen:
        • Menüleisten-Integration mit NSStatusItem
        • Globale Tastenkombination ⌘⇧N
        • Dropdown-Menü mit Status-Anzeige
        • Symbol-Icon mit SF Symbols
        • Moderne SwiftUI-Benutzeroberfläche
        
        Entwickelt mit Swift und macOS APIs.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - StatusRow Component

struct StatusRow: View {
    let label: String
    let value: String
    let isActive: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 4) {
                if isActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Preview

struct StatusBarAppView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarAppView()
    }
}