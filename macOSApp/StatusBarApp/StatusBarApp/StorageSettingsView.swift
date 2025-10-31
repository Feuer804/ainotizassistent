//
//  StorageSettingsView.swift
//  StatusBarApp
//
//  Storage Provider Settings UI
//

import SwiftUI

struct StorageSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @State private var showingCloudSetup = false
    @State private var syncInProgress = false
    @State private var storageUsage: StorageUsage = StorageUsage()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Primary/Secondary Storage Selection
                GroupBox("Storage Provider Konfiguration") {
                    VStack(alignment: .leading, spacing: 16) {
                        // Primary Storage
                        VStack(alignment: .leading) {
                            Text("Primary Storage Provider")
                                .font(.headline)
                            
                            Picker("Primary Provider", selection: $coordinator.settings.storage.primaryProvider) {
                                Text("iCloud").tag("icloud")
                                Text("Lokaler Ordner").tag("local")
                                Text("Dropbox").tag("dropbox")
                            }
                            .pickerStyle(RadioGroupPickerStyle())
                        }
                        
                        // Secondary Storage
                        VStack(alignment: .leading) {
                            Text("Secondary Storage Provider (Optional)")
                                .font(.headline)
                            Picker("Secondary Provider", selection: Binding(
                                get: { coordinator.settings.storage.secondaryProvider ?? "none" },
                                set: { coordinator.settings.storage.secondaryProvider = $0 == "none" ? nil : $0 }
                            )) {
                                Text("Keine").tag("none")
                                Text("iCloud").tag("icloud")
                                Text("Lokaler Ordner").tag("local")
                                Text("Dropbox").tag("dropbox")
                            }
                            .pickerStyle(RadioGroupPickerStyle())
                        }
                        
                        // Storage Status
                        HStack {
                            Label("Status", systemImage: "internaldrive")
                                .font(.headline)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Verfügbar: \(formattedBytes(storageUsage.available))")
                                    .font(.caption)
                                Text("Verwendet: \(formattedBytes(storageUsage.used))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // iCloud Settings
                if coordinator.settings.storage.primaryProvider == "icloud" || coordinator.settings.storage.secondaryProvider == "icloud" {
                    GroupBox("iCloud Einstellungen") {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("iCloud aktiviert", isOn: $coordinator.settings.storage.icloud.enabled)
                            
                            VStack(alignment: .leading) {
                                Text("Container ID")
                                    .font(.caption)
                                TextField("iCloud Container", text: $coordinator.settings.storage.icloud.containerId)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            Toggle("Sync aktiviert", isOn: $coordinator.settings.storage.icloud.syncEnabled)
                            Toggle("Verschlüsselung", isOn: $coordinator.settings.storage.icloud.encryptionEnabled)
                            
                            HStack {
                                Button("iCloud-Freigabe anfordern") {
                                    requestiCloudAccess()
                                }
                                .disabled(!isSystemSetup)
                                
                                Spacer()
                                
                                if !isSystemSetup {
                                    Text("iCloud muss in Systemeinstellungen aktiviert werden")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
                
                // Local Storage Settings
                if coordinator.settings.storage.primaryProvider == "local" || coordinator.settings.storage.secondaryProvider == "local" {
                    GroupBox("Lokaler Storage") {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Speicherort")
                                        .font(.caption)
                                    Text(coordinator.settings.storage.local.path.isEmpty ? "Kein Ordner ausgewählt" : coordinator.settings.storage.local.path)
                                        .font(.caption)
                                        .foregroundColor(coordinator.settings.storage.local.path.isEmpty ? .red : .secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                Button("Durchsuchen") {
                                    selectLocalStorage()
                                }
                            }
                            
                            Toggle("Automatische Backups", isOn: $coordinator.settings.storage.local.autoBackup)
                            
                            if coordinator.settings.storage.local.autoBackup {
                                VStack(alignment: .leading) {
                                    Text("Backup Intervall: \(Int(coordinator.settings.storage.local.backupInterval / 3600)) Stunden")
                                        .font(.caption)
                                    Slider(value: Binding(
                                        get: { coordinator.settings.storage.local.backupInterval / 3600 },
                                        set: { coordinator.settings.storage.local.backupInterval = $0 * 3600 }
                                    ), in: 1...168, step: 1)
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Max Backup Count: \(coordinator.settings.storage.local.maxBackupCount)")
                                    .font(.caption)
                                Stepper("\(coordinator.settings.storage.local.maxBackupCount)", value: $coordinator.settings.storage.local.maxBackupCount, in: 1...50)
                            }
                        }
                    }
                }
                
                // Dropbox Settings
                if coordinator.settings.storage.primaryProvider == "dropbox" || coordinator.settings.storage.secondaryProvider == "dropbox" {
                    GroupBox("Dropbox Einfiguration") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("Access Token")
                                    .font(.caption)
                                SecureField("Dropbox Access Token", text: $coordinator.settings.storage.dropbox.accessToken)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading) {
                                Text("App Key")
                                    .font(.caption)
                                TextField("Dropbox App Key", text: $coordinator.settings.storage.dropbox.appKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Root Ordner")
                                    .font(.caption)
                                TextField("/StatusBarApp", text: $coordinator.settings.storage.dropbox.rootFolder)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            Toggle("Sync aktiviert", isOn: $coordinator.settings.storage.dropbox.syncEnabled)
                            
                            HStack {
                                Button("Dropbox verbinden") {
                                    connectDropbox()
                                }
                                .disabled(coordinator.settings.storage.dropbox.accessToken.isEmpty)
                                
                                if syncInProgress {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                    }
                }
                
                // Global Storage Settings
                GroupBox("Globale Storage-Einstellungen") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Verschlüsselung aktiviert", isOn: $coordinator.settings.storage.enableEncryption)
                        Toggle("Komprimierung aktiviert", isOn: $coordinator.settings.storage.compressionEnabled)
                        Toggle("Automatische Bereinigung", isOn: $coordinator.settings.storage.autoCleanup)
                        
                        if coordinator.settings.storage.autoCleanup {
                            VStack(alignment: .leading) {
                                Text("Retention Tage: \(coordinator.settings.storage.retentionDays)")
                                    .font(.caption)
                                Stepper("\(coordinator.settings.storage.retentionDays)", value: $coordinator.settings.storage.retentionDays, in: 7...3650)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Max Storage Size: \(formattedBytes(coordinator.settings.storage.maxStorageSize))")
                                .font(.caption)
                            Slider(value: Binding(
                                get: { Double(coordinator.settings.storage.maxStorageSize) / (1024 * 1024 * 1024) },
                                set: { coordinator.settings.storage.maxStorageSize = Int64($0 * 1024 * 1024 * 1024) }
                            ), in: 0.1...100, step: 0.1)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Sync Intervall: \(Int(coordinator.settings.storage.syncInterval / 60)) Minuten")
                                .font(.caption)
                            Slider(value: Binding(
                                get: { coordinator.settings.storage.syncInterval / 60 },
                                set: { coordinator.settings.storage.syncInterval = $0 * 60 }
                            ), in: 1...60, step: 1)
                        }
                        
                        if !coordinator.validationErrors["storage"].isEmpty {
                            Text("Fehler: \(coordinator.validationErrors["storage"] ?? "")")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                // Storage Actions
                GroupBox("Storage-Aktionen") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button("Sync starten") {
                                startSync()
                            }
                            .disabled(syncInProgress)
                            
                            Button("Storage bereinigen") {
                                cleanupStorage()
                            }
                            
                            Spacer()
                        }
                        
                        Text("Hier können Sie Storage-Aktionen ausführen und den Status überwachen.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onChange(of: coordinator.settings.storage) { _ in
            saveSettings()
        }
        .onAppear {
            loadStorageUsage()
        }
    }
    
    private func selectLocalStorage() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Ordner auswählen"
        
        if panel.runModal() == .OK, let url = panel.url {
            coordinator.settings.storage.local.path = url.path
        }
    }
    
    private func requestiCloudAccess() {
        // Request iCloud access through macOS system
        // This would typically involve entitlements and system permissions
        showingCloudSetup = true
    }
    
    private func connectDropbox() {
        syncInProgress = true
        // Simulate Dropbox connection test
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            syncInProgress = false
            // Connection logic would go here
        }
    }
    
    private func startSync() {
        syncInProgress = true
        // Simulate sync operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            syncInProgress = false
            loadStorageUsage()
        }
    }
    
    private func cleanupStorage() {
        // Implement storage cleanup logic
        loadStorageUsage()
    }
    
    private func loadStorageUsage() {
        // Load actual storage usage from system
        storageUsage = StorageUsage(total: 1024 * 1024 * 1024, used: 256 * 1024 * 1024, available: 768 * 1024 * 1024)
    }
    
    private func saveSettings() {
        do {
            try SettingsPersistence.shared.save(coordinator.settings)
            print("Storage Settings gespeichert")
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
    
    private var isSystemSetup: Bool {
        // Check if iCloud is set up in system
        return FileManager.default.ubiquityIdentityToken != nil
    }
    
    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.style = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Storage Usage Model

struct StorageUsage {
    var total: Int64 = 0
    var used: Int64 = 0
    var available: Int64 = 0
    
    var usedPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }
}

// MARK: - Preview

struct StorageSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        StorageSettingsView(coordinator: SettingsCoordinator())
            .frame(width: 500, height: 700)
    }
}