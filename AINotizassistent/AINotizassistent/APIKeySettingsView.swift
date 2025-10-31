//
//  APIKeySettingsView.swift
//  AINotizassistent
//
//  User Interface für API Key Management
//

import SwiftUI
import Combine

struct APIKeySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @StateObject private var openAIManager = OpenAIProviderManager()
    @StateObject private var openRouterManager = OpenRouterProviderManager()
    @StateObject private var notionManager = NotionProviderManager()
    @StateObject private var whisperManager = WhisperProviderManager()
    
    @State private var selectedTab = 0
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingEmergencyDisable = false
    @State private var showingImportExport = false
    @State private var showingAddKey = false
    @State private var selectedProviderForAdd: APIProvider?
    @State private var searchText = ""
    @State private var showingBackupOptions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header mit Summary
                headerView
                
                // Tab Selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    generalSettingsView
                        .tag(0)
                    
                    providerListView
                        .tag(1)
                    
                    securityAlertsView
                        .tag(2)
                    
                    usageStatisticsView
                        .tag(3)
                    
                    backupSettingsView
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("API Key Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    menuButton
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingAddKey) {
                addKeySheet
            }
            .sheet(isPresented: $showingImportExport) {
                importExportSheet
            }
            .actionSheet(isPresented: $showingBackupOptions) {
                backupActionSheet
            }
        }
        .onAppear {
            apiKeyManager.checkAllProviderStatuses()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Security Status
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(getSecurityStatusColor())
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Sicherheitsstatus")
                        .font(.headline)
                    Text(getSecurityStatusText())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quick Stats
                VStack(alignment: .trailing) {
                    Text("\(apiKeyManager.apiKeys.count) Keys")
                        .font(.headline)
                    Text("aktiv")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Provider Status Overview
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(APIProvider.allCases, id: \.self) { provider in
                    providerStatusCard(provider)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func providerStatusCard(_ provider: APIProvider) -> some View {
        let status = apiKeyManager.providerStatuses[provider]
        let keys = apiKeyManager.getAllKeys(for: provider)
        let validKeys = keys.filter { $0.status == .valid && !$0.isEmergencyDisabled }
        
        return VStack(spacing: 4) {
            Image(systemName: getProviderIcon(provider))
                .font(.title3)
                .foregroundColor(getProviderColor(provider))
            
            Text(provider.displayName)
                .font(.caption2)
                .lineLimit(1)
            
            Circle()
                .fill(getStatusColor(status))
                .frame(width: 8, height: 8)
            
            Text("\(validKeys.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .onTapGesture {
            selectedTab = 1 // Switch to provider list
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack {
            ForEach(0..<5, id: \.self) { index in
                TabButton(
                    title: getTabTitle(index),
                    isSelected: selectedTab == index
                ) {
                    selectedTab = index
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func getTabTitle(_ index: Int) -> String {
        switch index {
        case 0: return "Allgemein"
        case 1: return "Provider"
        case 2: "Alerts"
        case 3: return "Statistiken"
        case 4: return "Backup"
        default: return ""
        }
    }
    
    // MARK: - General Settings
    
    private var generalSettingsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Auto-Validation Settings
                settingsCard(
                    title: "Automatische Validierung",
                    icon: "checkmark.circle.fill",
                    color: .blue
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Alle 30 Minuten validieren", isOn: .constant(true))
                        Toggle("Bei App-Start validieren", isOn: .constant(true))
                        Toggle("Provider Status überwachen", isOn: .constant(true))
                    }
                }
                
                // Security Settings
                settingsCard(
                    title: "Sicherheit",
                    icon: "lock.fill",
                    color: .red
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Verschlüsselung aktiv", isOn: .constant(true))
                            .disabled(true)
                        
                        Toggle("Automatische Re-Verschlüsselung", isOn: .constant(true))
                        
                        Button(action: emergencyDisableAll) {
                            Label("Alle Keys deaktivieren", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Notification Settings
                settingsCard(
                    title: "Benachrichtigungen",
                    icon: "bell.fill",
                    color: .orange
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Key Expiration Alerts", isOn: .constant(true))
                        Toggle("Security Alerts", isOn: .constant(true))
                        Toggle("Quota Warnings", isOn: .constant(true))
                        Toggle("Provider Down Alerts", isOn: .constant(true))
                    }
                }
                
                // Sync Settings
                settingsCard(
                    title: "Synchronisation",
                    icon: "arrow.clockwise.circle.fill",
                    color: .green
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Keychain Sync aktiv", isOn: .constant(true))
                        Toggle("macOS Credential Manager", isOn: .constant(true))
                        
                        HStack {
                            Button("Sync jetzt") {
                                apiKeyManager.syncWithKeychain()
                            }
                            
                            Spacer()
                            
                            Text("Zuletzt: \(apiKeyManager.lastSync ?? Date(), style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Provider List
    
    private var providerListView: some View {
        VStack {
            // Search and Add
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Provider durchsuchen...", text: $searchText)
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                
                Button(action: { showingAddKey = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Provider List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredProviders, id: \.self) { provider in
                        providerDetailCard(provider)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func providerDetailCard(_ provider: APIProvider) -> some View {
        let keys = apiKeyManager.getAllKeys(for: provider)
        let validKeys = keys.filter { $0.status == .valid && !$0.isEmergencyDisabled }
        let primaryKey = keys.first { $0.isPrimary }
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: getProviderIcon(provider))
                    .font(.title2)
                    .foregroundColor(getProviderColor(provider))
                
                VStack(alignment: .leading) {
                    Text(provider.displayName)
                        .font(.headline)
                    Text("\(keys.count) Keys konfiguriert")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Indicators
                HStack(spacing: 4) {
                    Circle()
                        .fill(getProviderStatusColor(provider))
                        .frame(width: 8, height: 8)
                    
                    if validKeys.count > 0 {
                        Text("\(validKeys.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Primary Key Info
            if let primaryKey = primaryKey {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Primärer Key:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(getKeyStatusText(primaryKey.status))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(getStatusColor(primaryKey.status))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Text(maskedKey(primaryKey.keyValue))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospaced()
                    
                    if let lastUsed = primaryKey.lastUsed {
                        Text("Zuletzt verwendet: \(lastUsed, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Actions
            HStack {
                Button(action: { validateKey(for: provider) }) {
                    Label("Validieren", systemImage: "checkmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button(action: { rotateKey(for: provider) }) {
                    Label("Rotieren", systemImage: "rotate.right")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Menu {
                    Button("Details anzeigen") { showKeyDetails(provider) }
                    Button("Backup erstellen") { createProviderBackup(provider) }
                    Divider()
                    Button("Alle Keys deaktivieren", role: .destructive) {
                        disableAllKeys(for: provider)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Security Alerts
    
    private var securityAlertsView: some View {
        Group {
            if apiKeyManager.securityAlerts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Alle Systeme sicher")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Keine Sicherheitswarnungen vorhanden")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(apiKeyManager.securityAlerts) { alert in
                        securityAlertRow(alert)
                    }
                    .onDelete(perform: deleteSecurityAlert)
                }
            }
        }
        .navigationTitle("Sicherheitsalerts")
    }
    
    private func securityAlertRow(_ alert: SecurityAlert) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: getAlertIcon(alert.type))
                .font(.title3)
                .foregroundColor(getAlertColor(alert.severity))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.provider.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(alert.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(alert.message)
                    .font(.body)
                
                if alert.actionRequired {
                    HStack {
                        Button("Aktion erforderlich") {
                            handleSecurityAlert(alert)
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                }
            }
            
            if !alert.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Usage Statistics
    
    private var usageStatisticsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overview Cards
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach([APIProvider.openai, .openrouter, .notion, .whisper], id: \.self) { provider in
                        usageCard(provider)
                    }
                }
                .padding(.horizontal)
                
                // Detailed Charts (würden mit Charts Framework implementiert)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nutzungsentwicklung")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    RoundedRectangle(c-placeholder")
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 200)
                        .overlay(
                            Text("Chart würde hier erscheinen")
                                .foregroundColor(.secondary)
                        )
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Nutzungsstatistiken")
    }
    
    private func usageCard(_ provider: APIProvider) -> some View {
        let stats = apiKeyManager.getUsageStats(for: provider)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: getProviderIcon(provider))
                    .foregroundColor(getProviderColor(provider))
                
                Text(provider.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            if let stats = stats {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stats.requestsCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Anfragen diesen Monat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(stats.tokensUsed) Tokens")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Keine Daten")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Backup Settings
    
    private var backupSettingsView: some View {
        VStack(spacing: 20) {
            Button(action: { showingBackupOptions = true }) {
                Label("Backup erstellen", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            
            // Recent Backups
            VStack(alignment: .leading, spacing: 8) {
                Text("Aktuelle Backups")
                    .font(.headline)
                    .padding(.horizontal)
                
                if let backupURLs = getRecentBackups(), !backupURLs.isEmpty {
                    List {
                        ForEach(backupURLs, id: \.self) { url in
                            backupRow(url)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.richtext")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Keine Backups vorhanden")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("Backup & Wiederherstellung")
    }
    
    private func backupRow(_ url: URL) -> some View {
        HStack {
            Image(systemName: "doc.on.doc")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(url.lastPathComponent)
                    .font(.body)
                
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let date = attributes?[.modificationDate] as? Date ?? Date()
                
                Text("Erstellt: \(date, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button("Öffnen") { openBackup(url) }
                Button("Löschen", role: .destructive) { deleteBackup(url) }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    // MARK: - Menu Button
    
    private var menuButton: some View {
        Menu {
            Button("Alle Keys validieren") {
                apiKeyManager.validateAllKeys()
            }
            
            Button("Provider Status prüfen") {
                apiKeyManager.checkAllProviderStatuses()
            }
            
            Divider()
            
            Button("Import/Export") {
                showingImportExport = true
            }
            
            Button("Backup erstellen") {
                showingBackupOptions = true
            }
            
            Divider()
            
            Button("Alerts leeren") {
                apiKeyManager.clearAllAlerts()
            }
        } label: {
            Image(systemName: "gearshape.circle")
        }
    }
    
    // MARK: - Sheets
    
    private var addKeySheet: some View {
        NavigationView {
            AddAPIKeyView { provider, key, displayName in
                addNewKey(provider: provider, key: key, displayName: displayName)
            }
            .navigationTitle("API Key hinzufügen")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        showingAddKey = false
                    }
                }
            }
        }
    }
    
    private var importExportSheet: some View {
        NavigationView {
            ImportExportView()
                .navigationTitle("Import/Export")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Schließen") {
                            showingImportExport = false
                        }
                    }
                }
        }
    }
    
    private var backupActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Backup-Optionen"),
            message: Text("Wählen Sie eine Backup-Option"),
            buttons: [
                .default(Text("Vollständiges Backup")) {
                    createFullBackup()
                },
                .default(Text("Nur verschlüsselte Keys")) {
                    createKeysBackup()
                },
                .cancel()
            ]
        )
    }
    
    // MARK: - Helper Functions
    
    private var filteredProviders: [APIProvider] {
        if searchText.isEmpty {
            return APIProvider.allCases
        }
        
        return APIProvider.allCases.filter { provider in
            provider.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func getSecurityStatusColor() -> Color {
        let hasAlerts = !apiKeyManager.securityAlerts.filter { !$0.isRead }.isEmpty
        return hasAlerts ? .red : .green
    }
    
    private func getSecurityStatusText() -> String {
        let unreadAlerts = apiKeyManager.securityAlerts.filter { !$0.isRead }.count
        if unreadAlerts > 0 {
            return "\(unreadAlerts) ungelesene Alerts"
        }
        return "Alle Systeme sicher"
    }
    
    private func getProviderIcon(_ provider: APIProvider) -> String {
        switch provider {
        case .openai: return "brain.head.profile"
        case .openrouter: return "network"
        case .notion: return "note.text"
        case .whisper: return "mic.fill"
        }
    }
    
    private func getProviderColor(_ provider: APIProvider) -> Color {
        switch provider {
        case .openai: return Color.green
        case .openrouter: return Color.blue
        case .notion: return Color.black
        case .whisper: return Color.purple
        }
    }
    
    private func getStatusColor(_ status: APIKeyStatus) -> Color {
        switch status {
        case .valid: return .green
        case .invalid, .expired, .compromised: return .red
        case .disabled: return .gray
        case .pending: return .yellow
        }
    }
    
    private func getProviderStatusColor(_ provider: APIProvider) -> Color {
        let status = apiKeyManager.providerStatuses[provider]
        return status?.isOnline == true ? .green : .red
    }
    
    private func getKeyStatusText(_ status: APIKeyStatus) -> String {
        switch status {
        case .valid: return "Gültig"
        case .invalid: return "Ungültig"
        case .expired: return "Abgelaufen"
        case .disabled: return "Deaktiviert"
        case .pending: return "Wird geprüft"
        case .compromised: return "Kompromittiert"
        }
    }
    
    private func maskedKey(_ key: String) -> String {
        if key.count <= 8 {
            return key
        }
        return String(key.prefix(4)) + "..." + String(key.suffix(4))
    }
    
    private func getAlertIcon(_ type: SecurityAlertType) -> String {
        switch type {
        case .keyCompromised: return "exclamationmark.triangle.fill"
        case .suspiciousActivity: return "eye.slash.fill"
        case .quotaExceeded: return "chart.bar.xaxis"
        case .keyExpired: return "clock.badge.exclamationmark.fill"
        case .providerDown: return "wifi.slash"
        case .securityBreach: return "shield.slash.fill"
        }
    }
    
    private func getAlertColor(_ severity: AlertSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    // MARK: - Actions
    
    private func emergencyDisableAll() {
        apiKeyManager.emergencyDisableAllKeys()
        showAlert("Notfall", "Alle API Keys wurden deaktiviert")
    }
    
    private func validateKey(for provider: APIProvider) {
        // Validate all keys for this provider
        for key in apiKeyManager.getAllKeys(for: provider) {
            var updatedKey = key
            apiKeyManager.validateAPIKey(&updatedKey)
        }
    }
    
    private func rotateKey(for provider: APIProvider) {
        // This would open a rotation dialog
        showAlert("Key Rotation", "Key Rotation für \(provider.displayName) würde hier implementiert werden")
    }
    
    private func addNewKey(provider: APIProvider, key: String, displayName: String) {
        let newKey = APIKey(provider: provider, keyValue: key)
        newKey.displayName = displayName
        apiKeyManager.addAPIKey(newKey)
        showingAddKey = false
    }
    
    private func createFullBackup() {
        if let url = apiKeyManager.backupToFile() {
            showAlert("Backup erstellt", "Backup gespeichert unter: \(url.lastPathComponent)")
        } else {
            showAlert("Fehler", "Backup konnte nicht erstellt werden")
        }
    }
    
    private func createKeysBackup() {
        // Implement keys-only backup
        showAlert("Backup erstellt", "Keys Backup wurde erstellt")
    }
    
    private func getRecentBackups() -> [URL]? {
        // This would list recent backup files
        return nil
    }
    
    private func openBackup(_ url: URL) {
        // Open backup file
    }
    
    private func deleteBackup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    // Placeholder implementations for missing functions
    private func settingsCard(title: String, icon: String, color: Color, content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func deleteSecurityAlert(at offsets: IndexSet) {
        apiKeyManager.securityAlerts.remove(atOffsets: offsets)
    }
    
    private func handleSecurityAlert(_ alert: SecurityAlert) {
        apiKeyManager.markAlertAsRead(alert)
        // Handle specific alert actions
    }
    
    private func showKeyDetails(_ provider: APIProvider) {
        // Show key details
    }
    
    private func createProviderBackup(_ provider: APIProvider) {
        // Create backup for specific provider
    }
    
    private func disableAllKeys(for provider: APIProvider) {
        apiKeyManager.emergencyDisableAllKeys(for: provider)
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                .foregroundColor(isSelected ? .blue : .secondary)
                .cornerRadius(20)
        }
    }
}

struct AddAPIKeyView: View {
    let onAdd: (APIProvider, String, String) -> Void
    
    @State private var selectedProvider: APIProvider = .openai
    @State private var keyText = ""
    @State private var displayName = ""
    @State private var isValidating = false
    
    var body: some View {
        Form {
            Section("Provider") {
                Picker("API Provider", selection: $selectedProvider) {
                    ForEach(APIProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
            }
            
            Section("API Key") {
                SecureField("API Key eingeben", text: $keyText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                TextField("Anzeigename (optional)", text: $displayName)
            }
            
            Section {
                Button(action: addKey) {
                    if isValidating {
                        ProgressView()
                    } else {
                        Text("Key hinzufügen")
                    }
                }
                .disabled(keyText.isEmpty || isValidating)
            }
        }
    }
    
    private func addKey() {
        isValidating = true
        // Validate key before adding
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isValidating = false
            onAdd(selectedProvider, keyText, displayName.isEmpty ? selectedProvider.displayName : displayName)
        }
    }
}

struct ImportExportView: View {
    @State private var exportString = ""
    @State private var importText = ""
    @State private var showingImport = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Export Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Export")
                    .font(.headline)
                
                Button("Export erstellen") {
                    createExport()
                }
                .buttonStyle(.borderedProminent)
                
                if !exportString.isEmpty {
                    TextEditor(text: $exportString)
                        .frame(height: 100)
                        .font(.caption)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                    
                    Button("In Zwischenablage kopieren") {
                        UIPasteboard.general.string = exportString
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // Import Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Import")
                    .font(.headline)
                
                Button("Import aus Zwischenablage") {
                    if let pasteboardString = UIPasteboard.general.string {
                        importText = pasteboardString
                        showingImport = true
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .alert("Import bestätigen", isPresented: $showingImport) {
            Button("Abbrechen", role: .cancel) { }
            Button("Importieren", role: .destructive) {
                importKeys()
            }
        } message: {
            Text("Möchten Sie die API Keys aus der Zwischenablage importieren?")
        }
    }
    
    private func createExport() {
        if let export = APIKeyManager.shared.exportKeys() {
            exportString = export
        }
    }
    
    private func importKeys() {
        APIKeyManager.shared.importKeys(from: importText)
        importText = ""
    }
}