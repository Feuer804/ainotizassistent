//
//  StorageSettingsView.swift
//  AINotizassistent
//
//  Storage Settings und Configuration Interface
//

import SwiftUI
import OSLog

struct StorageSettingsView: View {
    @StateObject private var storageManager = StorageManager.shared
    @StateObject private var preferences = StoragePreferences.shared
    @State private var showSyncProgress = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab View für verschiedene Storage-Einstellungen
                TabView(selection: $selectedTab) {
                    // Hauptkonfiguration
                    primaryConfigurationTab
                        .tabItem {
                            Image(systemName: "gear")
                            Text("Konfiguration")
                        }
                        .tag(0)
                    
                    // Backup & Restore
                    backupRestoreTab
                        .tabItem {
                            Image(systemName: "archivebox")
                            Text("Backup")
                        }
                        .tag(1)
                    
                    // Erweiterte Einstellungen
                    advancedSettingsTab
                        .tabItem {
                            Image(systemName: "ellipsis.circle")
                            Text("Erweitert")
                        }
                        .tag(2)
                    
                    // Statistiken
                    statisticsTab
                        .tabItem {
                            Image(systemName: "chart.bar")
                            Text("Statistiken")
                        }
                        .tag(3)
                }
            }
            .navigationTitle("Speicher-Einstellungen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        // View schließen
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Primary Configuration Tab
    
    private var primaryConfigurationTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Provider Selection
                providerSelectionSection
                
                // Sync Settings
                syncSettingsSection
                
                // Security Settings
                securitySettingsSection
                
                // Quick Actions
                quickActionsSection
            }
            .padding()
        }
    }
    
    private var providerSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Storage Provider", icon: "externaldrive")
            
            // Primary Provider
            VStack(alignment: .leading, spacing: 8) {
                Text("Primärer Provider")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ProviderSelector(
                    selected: $storageManager.configuration.primaryProvider,
                    availableProviders: storageManager.availableProviders
                )
            }
            
            // Secondary Provider
            VStack(alignment: .leading, spacing: 8) {
                Text("Backup Provider (Optional)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ProviderSelector(
                    selected: Binding(
                        get: { storageManager.configuration.secondaryProvider },
                        set: { newValue in
                            var config = storageManager.configuration
                            config.secondaryProvider = newValue
                            storageManager.updateConfiguration(config)
                        }
                    ),
                    availableProviders: storageManager.availableProviders + [nil].compactMap { $0 }
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var syncSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Synchronisation", icon: "arrow.triangle.2.circlepath")
            
            // Auto Sync Toggle
            HStack {
                Image(systemName: "timer")
                VStack(alignment: .leading) {
                    Text("Automatische Synchronisation")
                    Text("Automatisch alle \(Int(storageManager.configuration.syncInterval/60)) Minuten")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { storageManager.configuration.syncInterval > 0 },
                    set: { newValue in
                        var config = storageManager.configuration
                        config.syncInterval = newValue ? 300 : 0
                        storageManager.updateConfiguration(config)
                    }
                ))
            }
            
            // Sync Interval
            if storageManager.configuration.syncInterval > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sync-Intervall: \(Int(storageManager.configuration.syncInterval/60)) Minuten")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: Binding(
                            get: { storageManager.configuration.syncInterval / 60 },
                            set: { newValue in
                                var config = storageManager.configuration
                                config.syncInterval = newValue * 60
                                storageManager.updateConfiguration(config)
                            }
                        ),
                        in: 1...120,
                        step: 1
                    )
                }
            }
            
            // Sync Conflicts
            HStack {
                Image(systemName: "exclamationmark.triangle")
                Text("Sync-Konflikte behandeln")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { storageManager.configuration.enableSyncConflicts },
                    set: { newValue in
                        var config = storageManager.configuration
                        config.enableSyncConflicts = newValue
                        storageManager.updateConfiguration(config)
                    }
                ))
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var securitySettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Sicherheit", icon: "lock.fill")
            
            // Encryption Toggle
            HStack {
                Image(systemName: "key")
                VStack(alignment: .leading) {
                    Text("Verschlüsselung aktivieren")
                    Text("Sensitive Inhalte verschlüsselt speichern")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { storageManager.configuration.encryptionEnabled },
                    set: { newValue in
                        var config = storageManager.configuration
                        config.encryptionEnabled = newValue
                        storageManager.updateConfiguration(config)
                    }
                ))
            }
            
            // Compression
            HStack {
                Image(systemName: "archive")
                Text("Datenkomprimierung")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { storageManager.configuration.compressionEnabled },
                    set: { newValue in
                        var config = storageManager.configuration
                        config.compressionEnabled = newValue
                        storageManager.updateConfiguration(config)
                    }
                ))
            }
            
            // Versioning
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text("Versionsverwaltung")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { storageManager.configuration.versioningEnabled },
                    set: { newValue in
                        var config = storageManager.configuration
                        config.versioningEnabled = newValue
                        storageManager.updateConfiguration(config)
                    }
                ))
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Aktionen", icon: "bolt.fill")
            
            // Manual Sync
            Button(action: {
                Task {
                    await storageManager.performAutoSync()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                    Text("Jetzt synchronisieren")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
            }
            .disabled(storageManager.isSyncing)
            
            // Resolve Conflicts
            if !storageManager.syncConflicts.isEmpty {
                Button(action: {
                    Task {
                        try await storageManager.resolveSyncConflicts()
                    }
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("\(storageManager.syncConflicts.count) Konflikte lösen")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Backup & Restore Tab
    
    private var backupRestoreTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Backup Settings
                backupSettingsSection
                
                // Backup Management
                backupManagementSection
                
                // Import/Export
                importExportSection
            }
            .padding()
        }
    }
    
    private var backupSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Backup-Einstellungen", icon: "archivebox")
            
            // Auto Backup
            HStack {
                Image(systemName: "timer")
                VStack(alignment: .leading) {
                    Text("Automatisches Backup")
                    Text("Tägliche Sicherung der Daten")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { storageManager.configuration.autoBackup },
                    set: { newValue in
                        var config = storageManager.configuration
                        config.autoBackup = newValue
                        storageManager.updateConfiguration(config)
                    }
                ))
            }
            
            // Backup Frequency
            VStack(alignment: .leading, spacing: 8) {
                Text("Backup-Frequenz: \(backupFrequencyDescription)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { preferences.backupFrequency },
                        set: { newValue in
                            preferences.backupFrequency = newValue
                            preferences.savePreferences()
                        }
                    ),
                    in: 3600...604800, // 1 Stunde bis 1 Woche
                    step: 3600
                )
            }
            
            // Max Backup Count
            HStack {
                Image(systemName: "folder")
                Text("Max. Backup-Anzahl")
                Spacer()
                Stepper("\(preferences.maxBackupCount)", 
                       value: Binding(
                        get: { preferences.maxBackupCount },
                        set: { newValue in
                            preferences.maxBackupCount = newValue
                            preferences.savePreferences()
                        }
                       ),
                       in: 1...50
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var backupManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Backup-Verwaltung", icon: "folder.fill")
            
            // Create Backup
            Button(action: {
                Task {
                    do {
                        _ = try await storageManager.createBackup()
                        // Feedback anzeigen
                    } catch {
                        // Fehlerbehandlung
                    }
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Backup erstellen")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(8)
            }
            
            // Backup List (vereinfacht)
            VStack(alignment: .leading, spacing: 8) {
                Text("Letzte Backups")
                    .font(.headline)
                
                if let lastBackup = storageManager.statistics?.lastBackupDate {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Letztes Backup: \(lastBackup.formatted(date: .abbreviated, time: .shortened))")
                        Spacer()
                        Button("Wiederherstellen") {
                            // Restore Logik
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                } else {
                    Text("Keine Backups vorhanden")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var importExportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Import/Export", icon: "arrow.left.arrow.right")
            
            // Export All
            Button(action: {
                Task {
                    do {
                        _ = try await storageManager.exportAll()
                        // Feedback anzeigen
                    } catch {
                        // Fehlerbehandlung
                    }
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Alle Daten exportieren")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
            }
            
            // Import
            Button(action: {
                // File Picker für Import
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Daten importieren")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Advanced Settings Tab
    
    private var advancedSettingsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Storage Quota
                storageQuotaSection
                
                // Error Recovery
                errorRecoverySection
                
                // Data Migration
                dataMigrationSection
            }
            .padding()
        }
    }
    
    private var storageQuotaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Speicher-Quota", icon: "internaldrive")
            
            if let quota = storageManager.configuration.maxStorageQuota {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verwendeter Speicher: \(formatBytes(storageManager.statistics?.usedSpace ?? 0)) / \(formatBytes(quota))")
                        .font(.caption)
                    
                    ProgressView(value: storageManager.statistics?.quotaPercentage ?? 0)
                        .progressViewStyle(LinearProgressViewStyle())
                }
                
                // Quota Setting
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quota ändern: \(formatBytes(Int64($0)))")
                        .font(.caption)
                    
                    Slider(
                        value: Binding(
                            get: { Double(storageManager.configuration.maxStorageQuota ?? 1073741824) },
                            set: { newValue in
                                var config = storageManager.configuration
                                config.maxStorageQuota = Int64(newValue)
                                storageManager.updateConfiguration(config)
                            }
                        ),
                        in: 1073741824...10737418240, // 1GB bis 10GB
                        step: 1073741824
                    )
                }
            } else {
                Text("Unbegrenzter Speicher")
                    .foregroundColor(.secondary)
                
                Button("Quota setzen") {
                    // Quota Setzer anzeigen
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var errorRecoverySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Fehlerbehandlung", icon: "exclamationmark.shield")
            
            // Retry Mechanism
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Automatische Wiederholung")
                Spacer()
                Toggle("", isOn: .constant(true))
            }
            
            // Emergency Recovery
            Button(action: {
                Task {
                    await storageManager.retryFailedOperations()
                }
            }) {
                HStack {
                    Image(systemName: "wrench")
                    Text("Fehlerbehandlung ausführen")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var dataMigrationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Daten-Migration", icon: "arrow.right.arrow.left")
            
            Text("Daten zwischen verschiedenen Storage-Providern migrieren")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Picker("Von", selection: .constant(storageManager.configuration.primaryProvider)) {
                    ForEach(storageManager.availableProviders, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Image(systemName: "arrow.right")
                
                Picker("Nach", selection: .constant(storageManager.configuration.secondaryProvider ?? storageManager.configuration.primaryProvider)) {
                    ForEach(storageManager.availableProviders, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Button("Migration starten") {
                // Migration starten
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Statistics Tab
    
    private var statisticsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let stats = storageManager.statistics {
                    // Overview
                    storageOverviewSection(stats)
                    
                    // Provider Breakdown
                    providerBreakdownSection(stats)
                    
                    // Sync Status
                    syncStatusSection(stats)
                } else {
                    ProgressView("Lade Statistiken...")
                        .frame(maxWidth: .infinity, maxHeight: 200)
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                await storageManager.refreshStatistics()
            }
        }
    }
    
    private func storageOverviewSection(_ stats: StorageStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Übersicht", icon: "chart.pie")
            
            // Total Items
            HStack {
                Image(systemName: "doc.text")
                Text("Gesamt: \(stats.totalItems) Artikel")
                Spacer()
                Text(formatBytes(stats.totalSize))
                    .foregroundColor(.secondary)
            }
            
            // Used Space
            HStack {
                Image(systemName: "internaldrive")
                Text("Verwendet")
                Spacer()
                Text(formatBytes(stats.usedSpace))
                    .foregroundColor(.secondary)
            }
            
            // Available Space
            if let available = stats.availableSpace {
                HStack {
                    Image(systemName: "externaldrive")
                    Text("Verfügbar")
                    Spacer()
                    Text(formatBytes(available))
                        .foregroundColor(.secondary)
                }
                
                // Quota Usage
                if let quota = storageManager.configuration.maxStorageQuota {
                    ProgressView(value: stats.quotaPercentage)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func providerBreakdownSection(_ stats: StorageStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Provider-Aufschlüsselung", icon: "externaldrive")
            
            ForEach(Array(stats.providerBreakdown.keys), id: \.self) { provider in
                if let size = stats.providerBreakdown[provider] {
                    HStack {
                        Image(systemName: provider.iconName)
                        Text(provider.displayName)
                        Spacer()
                        Text(formatBytes(size))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func syncStatusSection(_ stats: StorageStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Sync-Status", icon: "arrow.triangle.2.circlepath")
            
            ForEach(Array(stats.syncStatusBreakdown.keys), id: \.self) { status in
                if let count = stats.syncStatusBreakdown[status] {
                    HStack {
                        Image(systemName: statusIcon(status))
                        Text(status.displayText)
                        Spacer()
                        Text("\(count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private var backupFrequencyDescription: String {
        let hours = Int(preferences.backupFrequency / 3600)
        if hours < 24 {
            return "\(hours) Stunde(n)"
        } else {
            let days = hours / 24
            return "\(days) Tag(e)"
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func statusIcon(_ status: SyncStatus) -> String {
        switch status {
        case .synced: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .uploading: return "arrow.up.circle.fill"
        case .downloading: return "arrow.down.circle.fill"
        case .conflict: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}

struct ProviderSelector: View {
    @Binding var selected: StorageProvider?
    let availableProviders: [StorageProvider?]
    
    var body: some View {
        HStack {
            Image(systemName: selected?.iconName ?? "questionmark")
            VStack(alignment: .leading) {
                Text(selected?.displayName ?? "Keine Auswahl")
                if let provider = selected {
                    Text(getProviderDescription(provider))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            
            Menu {
                ForEach(availableProviders, id: \.self) { provider in
                    Button(provider?.displayName ?? "Keine") {
                        selected = provider
                    }
                }
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func getProviderDescription(_ provider: StorageProvider) -> String {
        switch provider {
        case .local: return "Lokaler Speicher auf diesem Gerät"
        case .icloud: return "Synchronisation über iCloud"
        case .obsidian: return "Obsidian Vault Integration"
        case .notion: return "Notion Workspace Integration"
        case .dropbox: return "Dropbox Cloud Storage"
        case .googleDrive: return "Google Drive Cloud Storage"
        case .onedrive: return "Microsoft OneDrive Cloud Storage"
        }
    }
}

// MARK: - Provider Availability View

struct ProviderAvailabilityView: View {
    let provider: StorageProvider
    let isAvailable: Bool
    
    var body: some View {
        HStack {
            Image(systemName: provider.iconName)
                .foregroundColor(isAvailable ? .green : .red)
            VStack(alignment: .leading) {
                Text(provider.displayName)
                    .font(.headline)
                Text(isAvailable ? "Verfügbar" : "Nicht verfügbar")
                    .font(.caption)
                    .foregroundColor(isAvailable ? .green : .red)
            }
            Spacer()
            if isAvailable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Storage Settings App

struct StorageSettingsApp: App {
    var body: some Scene {
        WindowGroup {
            StorageSettingsView()
        }
    }
}

#Preview {
    StorageSettingsView()
}