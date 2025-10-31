//
//  PrivacySettingsView.swift
//  StatusBarApp
//
//  Privacy and Security Settings
//

import SwiftUI

struct PrivacySettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @State private var showingSecurityAlert = false
    @State private var showingDataExport = false
    @State private var auditLogEntries: [AuditLogEntry] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Data Collection
                GroupBox("Datensammlung") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Datensammlung aktivieren", isOn: $coordinator.settings.privacy.dataCollection)
                        
                        if coordinator.settings.privacy.dataCollection {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                    Text("Datensammlung hilft uns, die App zu verbessern")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    // What data is collected
                                    Text("Gesammelte Daten:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(collectedDataItems, id: \.id) { item in
                                            HStack {
                                                Image(systemName: item.icon)
                                                    .foregroundColor(item.color)
                                                    .font(.caption2)
                                                Text(item.description)
                                                    .font(.caption2)
                                                Text(item.status)
                                                    .font(.caption2)
                                                    .foregroundColor(item.statusColor)
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("Datensammlung ist deaktiviert. Ihre Privatsphäre ist geschützt.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                
                // Security Settings
                GroupBox("Sicherheit") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Verschlüsselung aktiviert", isOn: $coordinator.settings.privacy.enableEncryption)
                        
                        if coordinator.settings.privacy.enableEncryption {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.green)
                                    Text("Ihre Daten werden mit AES-256 verschlüsselt")
                                        .font(.caption)
                                }
                                
                                HStack {
                                    Image(systemName: "shield.fill")
                                        .foregroundColor(.green)
                                    Text("Sichere Speicherung lokal")
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Toggle("Biometrische Authentifizierung", isOn: $coordinator.settings.privacy.biometricAuth)
                        
                        if coordinator.settings.privacy.biometricAuth {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "faceid")
                                        .foregroundColor(.blue)
                                    Text("Face ID / Touch ID für kritische Aktionen")
                                        .font(.caption)
                                }
                                
                                Button("Biometrie testen") {
                                    testBiometricAuth()
                                }
                                .buttonStyle(TestButtonStyle())
                            }
                        }
                        
                        Toggle("Automatische Sperre", isOn: $coordinator.settings.privacy.autoLock)
                        
                        if coordinator.settings.privacy.autoLock {
                            VStack(alignment: .leading) {
                                Text("Session Timeout: \(Int(coordinator.settings.privacy.sessionTimeout / 60)) Minuten")
                                    .font(.caption)
                                Slider(
                                    value: Binding(
                                        get: { coordinator.settings.privacy.sessionTimeout / 60 },
                                        set: { coordinator.settings.privacy.sessionTimeout = $0 * 60 }
                                    ),
                                    in: 5...240,
                                    step: 5
                                )
                            }
                        }
                    }
                }
                
                // Audit Logging
                GroupBox("Audit-Protokoll") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Audit-Protokoll aktiviert", isOn: $coordinator.settings.privacy.auditLogging)
                        
                        if coordinator.settings.privacy.auditLogging {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Button("Protokoll anzeigen") {
                                        showAuditLog()
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                    
                                    Button("Protokoll leeren") {
                                        clearAuditLog()
                                    }
                                    .buttonStyle(DestructiveButtonStyle())
                                    
                                    Spacer()
                                    
                                    Text("\(auditLogEntries.count) Einträge")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !auditLogEntries.isEmpty {
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(auditLogEntries.prefix(10), id: \.id) { entry in
                                                AuditLogEntryView(entry: entry)
                                            }
                                        }
                                    }
                                    .frame(maxHeight: 200)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                                } else {
                                    Text("Keine Audit-Einträge verfügbar")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding()
                                }
                            }
                        } else {
                            Text("Audit-Protokoll ist deaktiviert. Aktivieren Sie es für detaillierte Sicherheitsüberwachung.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                
                // Data Management
                GroupBox("Datenverwaltung") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Button("Daten exportieren") {
                                exportUserData()
                            }
                            .buttonStyle(ExportButtonStyle())
                            
                            Button("Daten löschen") {
                                showingSecurityAlert = true
                            }
                            .buttonStyle(DestructiveButtonStyle())
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Verfügbare Daten:")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(availableDataTypes, id: \.id) { dataType in
                                    HStack {
                                        Image(systemName: dataType.icon)
                                            .foregroundColor(dataType.color)
                                            .font(.caption2)
                                        Text(dataType.description)
                                            .font(.caption2)
                                        Text(formatSize(dataType.size))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Secure Delete
                GroupBox("Sicheres Löschen") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Sicheres Löschen aktiviert", isOn: $coordinator.settings.privacy.secureDelete)
                        
                        if coordinator.settings.privacy.secureDelete {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.orange)
                                    Text("Daten werden sicher überschrieben")
                                        .font(.caption)
                                }
                                
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("3-fache Überschreibung für maximale Sicherheit")
                                        .font(.caption)
                                }
                            }
                        } else {
                            Text("Standard-Löschung verwendet. Daten könnten wiederherstellbar sein.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                
                // Privacy Resources
                GroupBox("Datenschutz-Ressourcen") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Datenschutzerklärung") {
                            openPrivacyPolicy()
                        }
                        .buttonStyle(HelpButtonStyle())
                        
                        Button("Nutzungsbedingungen") {
                            openTermsOfService()
                        }
                        .buttonStyle(HelpButtonStyle())
                        
                        Button("Datenschutz-Einstellungen") {
                            openSystemPrivacySettings()
                        }
                        .buttonStyle(HelpButtonStyle())
                        
                        Text("Erfahren Sie mehr über unseren Umgang mit Ihren Daten.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .alert("Sicherheitswarnung", isPresented: $showingSecurityAlert) {
            Button("Alle Daten löschen", role: .destructive) {
                deleteAllUserData()
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Diese Aktion löscht unwiderruflich alle Ihre Daten, Einstellungen und gespeicherten Informationen.")
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
                .frame(width: 400, height: 300)
        }
        .onAppear {
            loadAuditLogEntries()
            loadDataSizes()
        }
        .onChange(of: coordinator.settings.privacy) { _ in
            saveSettings()
        }
    }
    
    // MARK: - Data Models
    
    @State private var collectedDataItems: [CollectedDataItem] = []
    @State private var availableDataTypes: [DataTypeItem] = []
    
    private func testBiometricAuth() {
        // Test biometric authentication
        print("Biometric auth test would go here")
    }
    
    private func showAuditLog() {
        // Show detailed audit log
        loadAuditLogEntries()
    }
    
    private func clearAuditLog() {
        auditLogEntries.removeAll()
        // Clear actual audit log
    }
    
    private func exportUserData() {
        showingDataExport = true
    }
    
    private func deleteAllUserData() {
        // Delete all user data securely
        coordinator.settings = AppSettings.default
        auditLogEntries.removeAll()
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
    
    private func openSystemPrivacySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
    }
    
    private func loadAuditLogEntries() {
        // Load audit log entries
        auditLogEntries = [
            AuditLogEntry(id: "1", action: "Settings geändert", timestamp: Date().addingTimeInterval(-3600), details: "KI-Provider aktiviert"),
            AuditLogEntry(id: "2", action: "Auto-Save aktiviert", timestamp: Date().addingTimeInterval(-7200), details: "Interval: 5 Minuten"),
            AuditLogEntry(id: "3", action: "Anmeldung", timestamp: Date().addingTimeInterval(-86400), details: "Lokale Authentifizierung")
        ]
    }
    
    private func loadDataSizes() {
        availableDataTypes = [
            DataTypeItem(id: "1", description: "Einstellungen", icon: "gearshape", color: .blue, size: 1024),
            DataTypeItem(id: "2", description: "Auto-Save Daten", icon: "doc.richtext", color: .green, size: 51200),
            DataTypeItem(id: "3", description: "KI-Sessions", icon: "brain.head.profile", color: .purple, size: 25600),
            DataTypeItem(id: "4", description: "Cache", icon: "internaldrive", color: .orange, size: 102400)
        ]
        
        collectedDataItems = [
            CollectedDataItem(id: "1", description: "Anwendung Nutzung", icon: "chart.bar", color: .blue, status: "Aktiv", statusColor: .green),
            CollectedDataItem(id: "2", description: "Performance Metriken", icon: "speedometer", color: .orange, status: "Aktiv", statusColor: .green),
            CollectedDataItem(id: "3", description: "Crash Reports", icon: "exclamationmark.triangle", color: .red, status: "Optional", statusColor: .gray),
            CollectedDataItem(id: "4", description: "Analytics", icon: "chart.line.uptrend.xyaxis", color: .purple, status: "Aktiv", statusColor: .green)
        ]
    }
    
    private func saveSettings() {
        do {
            try SettingsPersistence.shared.save(coordinator.settings)
            print("Privacy Settings gespeichert")
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
    
    private func formatSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.style = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Supporting Views

struct AuditLogEntryView: View {
    let entry: AuditLogEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.action)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(entry.details)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatTimestamp(entry.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.5))
        )
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exportOptions: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Datenexport")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Wählen Sie die Daten aus, die exportiert werden sollen:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(exportDataOptions, id: \.id) { option in
                    HStack {
                        Toggle(option.name, isOn: .constant(exportOptions.contains(option.id)))
                            .onTapGesture {
                                if exportOptions.contains(option.id) {
                                    exportOptions.remove(option.id)
                                } else {
                                    exportOptions.insert(option.id)
                                }
                            }
                        
                        Spacer()
                        
                        Text(option.size)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                Button("Exportieren") {
                    performExport()
                }
                .buttonStyle(ExportButtonStyle())
                
                Button("Abbrechen") {
                    dismiss()
                }
                .buttonStyle(CancelButtonStyle())
                
                Spacer()
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    private func performExport() {
        // Perform data export
        dismiss()
    }
}

// MARK: - Data Models

struct AuditLogEntry: Identifiable {
    let id: String
    let action: String
    let timestamp: Date
    let details: String
}

struct DataTypeItem: Identifiable {
    let id: String
    let description: String
    let icon: String
    let color: Color
    let size: Int
}

struct CollectedDataItem: Identifiable {
    let id: String
    let description: String
    let icon: String
    let color: Color
    let status: String
    let statusColor: Color
}

// MARK: - Data

let exportDataOptions = [
    ExportOption(id: "settings", name: "Einstellungen", size: "1 KB"),
    ExportOption(id: "autosave", name: "Auto-Save Daten", size: "50 KB"),
    ExportOption(id: "ki", name: "KI-Sessions", size: "25 KB"),
    ExportOption(id: "cache", name: "Cache", size: "100 KB")
]

struct ExportOption: Identifiable {
    let id: String
    let name: String
    let size: String
}

// MARK: - Button Styles

struct TestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
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

struct ExportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
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

struct CancelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
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

// MARK: - Preview

struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacySettingsView(coordinator: SettingsCoordinator())
            .frame(width: 500, height: 700)
    }
}