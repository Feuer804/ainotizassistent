//
//  GeneralSettingsView.swift
//  StatusBarApp
//
//  General Settings UI Components
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // App Preferences
            GroupBox("App-Einstellungen") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Automatisch bei Systemstart", isOn: $coordinator.settings.general.autoStart)
                    Toggle("In Dock anzeigen", isOn: $coordinator.settings.general.showInDock)
                    Toggle("Willkommen beim Start anzeigen", isOn: $coordinator.settings.general.showWelcomeOnStartup)
                    
                    // Theme Selection
                    VStack(alignment: .leading) {
                        Text("Design")
                            .font(.headline)
                        Picker("Design", selection: $coordinator.settings.general.theme) {
                            ForEach(Theme.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Language Selection
                    VStack(alignment: .leading) {
                        Text("Sprache")
                            .font(.headline)
                        Picker("Sprache", selection: $coordinator.settings.general.language) {
                            Text("Deutsch").tag("de")
                            Text("English").tag("en")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
            
            // Privacy & Analytics
            GroupBox("Datenschutz & Analytics") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Analytics aktivieren", isOn: $coordinator.settings.general.enableAnalytics)
                    Toggle("Crash-Reporting aktivieren", isOn: $coordinator.settings.general.enableCrashReporting)
                    
                    Text("Hinweise:")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Analytics hilft uns, die App zu verbessern")
                        }
                        HStack {
                            Image(systemName: "shield")
                                .foregroundColor(.green)
                            Text("Crash-Reporting ist anonym und sicher")
                        }
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.orange)
                            Text("Alle Daten werden lokal verarbeitet")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            // Help & Documentation
            GroupBox("Hilfe & Dokumentation") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button("Benutzerhandbuch") {
                            openDocumentation()
                        }
                        .buttonStyle(HelpButtonStyle())
                        
                        Button("Support-Kontakt") {
                            openSupport()
                        }
                        .buttonStyle(HelpButtonStyle())
                    }
                    
                    Text("Benötigen Sie Hilfe? Unser Support-Team ist für Sie da.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: coordinator.settings.general) { _ in
            saveSettings()
        }
    }
    
    private func saveSettings() {
        do {
            try SettingsPersistence.shared.save(coordinator.settings)
            print("General Settings gespeichert")
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
    
    private func openDocumentation() {
        if let url = URL(string: coordinator.settings.about.documentationURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openSupport() {
        if let url = URL(string: coordinator.settings.about.supportURL) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Help Button Style

struct HelpButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        configuration.isPressed
                        ? Color.blue.opacity(0.2)
                        : Color.white.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Preview

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView(coordinator: SettingsCoordinator())
            .frame(width: 500, height: 400)
    }
}