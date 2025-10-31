//
//  AboutSettingsView.swift
//  StatusBarApp
//
//  About and Help Settings
//

import SwiftUI
import WebKit

struct AboutSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @State private var showingReleaseNotes = false
    @State private var showingUpdateSheet = false
    @State private var updateAvailable = false
    @State private var releaseNotes: [ReleaseNote] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // App Information
                GroupBox("App-Informationen") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            // App Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("StatusBarApp")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Version \(coordinator.settings.about.version) (\(coordinator.settings.about.buildNumber))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Moderne macOS Menüleisten-Anwendung")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // App Status
                        HStack {
                            VStack(alignment: .leading) {
                                Label("Status", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                Label("Updates", systemImage: "arrow.down.circle")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Aktiv")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                Text(updateAvailable ? "Verfügbar" : "Aktuell")
                                    .font(.caption)
                                    .foregroundColor(updateAvailable ? .orange : .green)
                            }
                        }
                    }
                }
                
                // Update Channel
                GroupBox("Update-Einstellungen") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Automatische Updates prüfen", isOn: $coordinator.settings.about.checkForUpdates)
                        
                        VStack(alignment: .leading) {
                            Text("Update-Kanal")
                                .font(.headline)
                            Picker("Update-Kanal", selection: $coordinator.settings.about.updateChannel) {
                                ForEach(UpdateChannel.allCases, id: \.self) { channel in
                                    Text(channel.rawValue).tag(channel)
                                }
                            }
                            .pickerStyle(RadioGroupPickerStyle())
                        }
                        
                        if updateAvailable {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Update verfügbar")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                    Text("Version 1.1.0 ist verfügbar")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Jetzt updaten") {
                                    performUpdate()
                                }
                                .buttonStyle(UpdateButtonStyle())
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }
                }
                
                // Release Notes
                GroupBox("Versionshistorie") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button("Release Notes anzeigen") {
                                showingReleaseNotes = true
                                loadReleaseNotes()
                            }
                            .buttonStyle(ReleaseNotesButtonStyle())
                            
                            Spacer()
                        }
                        
                        if !releaseNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(releaseNotes.prefix(3), id: \.id) { note in
                                    ReleaseNoteRow(note: note)
                                }
                            }
                        } else {
                            Text("Keine Release Notes verfügbar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Support & Help
                GroupBox("Support & Hilfe") {
                    VStack(alignment: .leading, spacing: 16) {
                        // Documentation
                        VStack(alignment: .leading) {
                            Text("Dokumentation")
                                .font(.headline)
                            
                            HStack {
                                Button("Benutzerhandbuch") {
                                    openUserGuide()
                                }
                                .buttonStyle(HelpButtonStyle())
                                
                                Button("API-Dokumentation") {
                                    openAPIDocs()
                                }
                                .buttonStyle(HelpButtonStyle())
                                
                                Button("FAQ") {
                                    openFAQ()
                                }
                                .buttonStyle(HelpButtonStyle())
                            }
                        }
                        
                        // Support
                        VStack(alignment: .leading) {
                            Text("Support")
                                .font(.headline)
                            
                            HStack {
                                Button("Support-Kontakt") {
                                    openSupport()
                                }
                                .buttonStyle(SupportButtonStyle())
                                
                                Button("Bug Report") {
                                    openBugReport()
                                }
                                .buttonStyle(SupportButtonStyle())
                                
                                Button("Feature Request") {
                                    openFeatureRequest()
                                }
                                .buttonStyle(SupportButtonStyle())
                            }
                        }
                        
                        // Community
                        VStack(alignment: .leading) {
                            Text("Community")
                                .font(.headline)
                            
                            HStack {
                                Button("GitHub") {
                                    openGitHub()
                                }
                                .buttonStyle(CommunityButtonStyle())
                                
                                Button("Discord") {
                                    openDiscord()
                                }
                                .buttonStyle(CommunityButtonStyle())
                                
                                Button("Forum") {
                                    openForum()
                                }
                                .buttonStyle(CommunityButtonStyle())
                            }
                        }
                    }
                }
                
                // Legal
                GroupBox("Rechtliches") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button("Datenschutzerklärung") {
                                openPrivacyPolicy()
                            }
                            .buttonStyle(LegalButtonStyle())
                            
                            Button("Nutzungsbedingungen") {
                                openTermsOfService()
                            }
                            .buttonStyle(LegalButtonStyle())
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lizenzen")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text("Diese App verwendet die folgenden Open Source Bibliotheken:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• SwiftUI • Combine • UserNotifications")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Diagnostics
                GroupBox("Diagnose") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Button("System-Information") {
                                showSystemInfo()
                            }
                            .buttonStyle(DiagnosticsButtonStyle())
                            
                            Button("Logs exportieren") {
                                exportLogs()
                            }
                            .buttonStyle(DiagnosticsButtonStyle())
                            
                            Button("App-Reset") {
                                resetApp()
                            }
                            .buttonStyle(DiagnosticsButtonStyle())
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("System-Status")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(systemDiagnostics, id: \.id) { diagnostic in
                                    HStack {
                                        Image(systemName: diagnostic.icon)
                                            .foregroundColor(diagnostic.color)
                                            .font(.caption2)
                                        Text(diagnostic.name)
                                            .font(.caption)
                                        
                                        Spacer()
                                        
                                        Text(diagnostic.status)
                                            .font(.caption)
                                            .foregroundColor(diagnostic.color)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingReleaseNotes) {
            ReleaseNotesView(releaseNotes: releaseNotes)
                .frame(width: 600, height: 400)
        }
        .sheet(isPresented: $showingUpdateSheet) {
            UpdateView()
                .frame(width: 500, height: 300)
        }
        .onAppear {
            checkForUpdates()
            loadSystemDiagnostics()
        }
    }
    
    // MARK: - State Properties
    
    @State private var systemDiagnostics: [SystemDiagnostic] = [
        SystemDiagnostic(id: "1", name: "Speicher", icon: "internaldrive", color: .green, status: "OK"),
        SystemDiagnostic(id: "2", name: "Berechtigungen", icon: "lock", color: .green, status: "OK"),
        SystemDiagnostic(id: "3", name: "Network", icon: "wifi", color: .green, status: "OK"),
        SystemDiagnostic(id: "4", name: "KI-Provider", icon: "brain.head.profile", color: .orange, status: "Konfigurieren")
    ]
    
    // MARK: - Methods
    
    private func checkForUpdates() {
        // Simulate update check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            updateAvailable = Bool.random()
        }
    }
    
    private func loadReleaseNotes() {
        releaseNotes = [
            ReleaseNote(id: "1", version: "1.0.1", date: Date(), changes: ["Bugfixes", "Performance-Verbesserungen"]),
            ReleaseNote(id: "2", version: "1.0.0", date: Date().addingTimeInterval(-86400), changes: ["Erste Version", "KI-Integration", "Auto-Save"])
        ]
    }
    
    private func loadSystemDiagnostics() {
        // Load actual system diagnostics
    }
    
    private func performUpdate() {
        showingUpdateSheet = true
    }
    
    private func openUserGuide() {
        if let url = URL(string: coordinator.settings.about.documentationURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openAPIDocs() {
        NSWorkspace.shared.open(URL(string: "https://docs.statusbarapp.com/api")!)
    }
    
    private func openFAQ() {
        NSWorkspace.shared.open(URL(string: "https://docs.statusbarapp.com/faq")!)
    }
    
    private func openSupport() {
        if let url = URL(string: coordinator.settings.about.supportURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openBugReport() {
        NSWorkspace.shared.open(URL(string: "https://github.com/statusbarapp/issues/new?template=bug_report.md")!)
    }
    
    private func openFeatureRequest() {
        NSWorkspace.shared.open(URL(string: "https://github.com/statusbarapp/issues/new?template=feature_request.md")!)
    }
    
    private func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/statusbarapp")!)
    }
    
    private func openDiscord() {
        NSWorkspace.shared.open(URL(string: "https://discord.gg/statusbarapp")!)
    }
    
    private func openForum() {
        NSWorkspace.shared.open(URL(string: "https://forum.statusbarapp.com")!)
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: coordinator.settings.about.privacyPolicyURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        if let url = URL(string: coordinator.settings.about.termsOfServiceURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showSystemInfo() {
        // Show system information dialog
    }
    
    private func exportLogs() {
        // Export app logs
    }
    
    private func resetApp() {
        // Reset app to defaults
        coordinator.resetSettings()
    }
}

// MARK: - Supporting Views

struct ReleaseNoteRow: View {
    let note: ReleaseNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Version \(note.version)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(note.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            ForEach(note.changes, id: \.self) { change in
                Text("• \(change)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct ReleaseNotesView: View {
    @Environment(\.dismiss) private var dismiss
    let releaseNotes: [ReleaseNote]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Release Notes")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Schließen") {
                    dismiss()
                }
                .buttonStyle(CloseButtonStyle())
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(releaseNotes, id: \.id) { note in
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Version \(note.version)")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text(note.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            ForEach(note.changes, id: \.self) { change in
                                Text("• \(change)")
                                    .font(.body)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                }
            }
        }
        .padding()
    }
}

struct UpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var updateProgress: Double = 0
    @State private var isUpdating = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Update wird heruntergeladen...")
                .font(.headline)
            
            ProgressView(value: updateProgress)
                .progressViewStyle(LinearProgressViewStyle())
            
            if isUpdating {
                Button("Abbrechen") {
                    dismiss()
                }
                .buttonStyle(CancelButtonStyle())
            }
        }
        .padding()
        .onAppear {
            startUpdate()
        }
    }
    
    private func startUpdate() {
        isUpdating = true
        
        // Simulate update download
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            updateProgress += 0.01
            
            if updateProgress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isUpdating = false
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Data Models

struct ReleaseNote: Identifiable {
    let id: String
    let version: String
    let date: Date
    let changes: [String]
}

struct SystemDiagnostic: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let status: String
}

// MARK: - Button Styles

struct UpdateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.orange.opacity(0.3)
                        : Color.orange.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
    }
}

struct ReleaseNotesButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.blue.opacity(0.3)
                        : Color.blue.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

struct SupportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.green.opacity(0.3)
                        : Color.green.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
    }
}

struct CommunityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.purple.opacity(0.3)
                        : Color.purple.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
    }
}

struct LegalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.gray.opacity(0.3)
                        : Color.gray.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

struct DiagnosticsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.orange.opacity(0.3)
                        : Color.orange.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
    }
}

struct CloseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.blue)
            .underline()
    }
}

// MARK: - Preview

struct AboutSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutSettingsView(coordinator: SettingsCoordinator())
            .frame(width: 500, height: 700)
    }
}