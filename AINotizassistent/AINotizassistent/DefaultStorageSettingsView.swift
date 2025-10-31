//
//  DefaultStorageSettingsView.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI

struct DefaultStorageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storageManager = DefaultStorageManager()
    @StateObject private var contentAnalyzer = ContentAnalyzer()
    
    @State private var selectedContentType: ContentType = .note
    @State private var editingConfig: ContentTypeStorageConfig?
    @State private var showAddWorkflow = false
    @State private var newWorkflowName = ""
    @State private var showImportDialog = false
    @State private var showExportDialog = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Primary & Secondary Storage
            storageTargetsSection
            
            // Content Type Specific Configurations
            contentTypeConfigSection
            
            // Workflow Preferences
            workflowSection
            
            // Batch Operations
            batchOperationsSection
            
            // Smart Suggestions
            smartSuggestionsSection
            
            Spacer()
            
            // Action Buttons
            actionButtons
        }
        .padding()
        .frame(width: 600, height: 700)
        .sheet(isPresented: $showAddWorkflow) {
            addWorkflowView
        }
        .sheet(isPresented: $showExportDialog) {
            exportView
        }
        .fileImporter(
            isPresented: $showImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            importFromURL(result)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Speicherziele-Einstellungen")
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
            
            Button("Schließen") {
                dismiss()
            }
        }
    }
    
    // MARK: - Storage Targets Section
    private var storageTargetsSection: some View {
        GroupBox("Standard Speicherziele") {
            VStack(alignment: .leading, spacing: 12) {
                // Primary Storage
                HStack {
                    Text("Primäres Speicherziel:")
                    Spacer()
                    Picker("Primäres Ziel", selection: $storageManager.primaryStorage) {
                        ForEach(storageManager.availableTargets, id: \.self) { target in
                            HStack {
                                Text(target.icon)
                                Text(target.displayName)
                            }
                            .tag(target)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: storageManager.primaryStorage) { _, _ in
                        storageManager.checkAvailableTargets()
                    }
                }
                
                // Secondary Storage
                HStack {
                    Text("Backup Speicherziel:")
                    Spacer()
                    Picker("Backup Ziel", selection: $storageManager.secondaryStorage) {
                        Text("Kein Backup").tag(Optional<StorageTarget>.none)
                        ForEach(storageManager.availableTargets, id: \.self) { target in
                            HStack {
                                Text(target.icon)
                                Text(target.displayName)
                            }
                            .tag(Optional(target))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .onChange(of: storageManager.secondaryStorage) { _, _ in
                    storageManager.checkAvailableTargets()
                }
                
                // Storage Availability Status
                HStack {
                    Text("Verfügbare Ziele:")
                    Spacer()
                    Text(storageManager.availableTargets.count.description + "/" + String(StorageTarget.allCases.count))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Content Type Configuration Section
    private var contentTypeConfigSection: some View {
        GroupBox("Content-Type spezifische Konfiguration") {
            VStack(alignment: .leading, spacing: 12) {
                // Content Type Selector
                HStack {
                    Text("Content-Typ:")
                    Spacer()
                    Picker("Content-Typ", selection: $selectedContentType) {
                        ForEach(ContentType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 400)
                }
                
                // Configuration Display
                if let config = storageManager.contentTypeConfigs[selectedContentType] {
                    contentTypeConfigView(config)
                }
                
                // Edit Button
                Button("Konfiguration bearbeiten") {
                    editingConfig = storageManager.getStorageConfig(for: selectedContentType)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
    
    // MARK: - Content Type Config View
    private func contentTypeConfigView(_ config: ContentTypeStorageConfig) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            HStack {
                Text("Primäres Ziel:")
                Spacer()
                Text("\(config.primary.icon) \(config.primary.displayName)")
                    .fontWeight(.medium)
            }
            
            if let secondary = config.secondary {
                HStack {
                    Text("Backup Ziel:")
                    Spacer()
                    Text("\(secondary.icon) \(secondary.displayName)")
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                Toggle("Auto-Synchronisation", isOn: .constant(config.autoSync))
                    .disabled(true)
                
                Spacer()
                
                Toggle("Backup erstellen", isOn: .constant(config.createBackup))
                    .disabled(true)
            }
            
            Divider()
            
            Text("Beschreibung:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(getDescriptionForContentType(selectedContentType))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Workflow Section
    private var workflowSection: some View {
        GroupBox("Workflow-Präferenzen") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Aktiver Workflow:")
                    Spacer()
                    if let activeWorkflow = storageManager.activeWorkflow {
                        Text(activeWorkflow)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        
                        Button("Deaktivieren") {
                            storageManager.setActiveWorkflow("")
                        }
                    } else {
                        Text("Kein aktiver Workflow")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                // Workflow List
                if !storageManager.workflowPreferences.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(storageManager.workflowPreferences.sorted(by: { $0.key < $1.key }), id: \.key) { workflow, config in
                                workflowRowView(workflow, config)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
                
                HStack {
                    Button("Workflow hinzufügen") {
                        newWorkflowName = ""
                        showAddWorkflow = true
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
            }
            .padding()
        }
    }
    
    // MARK: - Workflow Row View
    private func workflowRowView(_ workflow: String, _ config: ContentTypeStorageConfig) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(workflow)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(config.primary.icon) \(config.primary.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if storageManager.activeWorkflow == workflow {
                Button("Aktiv") {
                    storageManager.setActiveWorkflow(workflow)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Button("Aktivieren") {
                    storageManager.setActiveWorkflow(workflow)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Button(role: .destructive) {
                storageManager.removeWorkflowPreference(workflow)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }
    
    // MARK: - Batch Operations Section
    private var batchOperationsSection: some View {
        GroupBox("Batch-Operationen") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Aktuelle Operationen:")
                    Spacer()
                    
                    if !storageManager.batchOperations.isEmpty {
                        Text("\(storageManager.batchOperations.count)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                
                if !storageManager.batchOperations.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(storageManager.batchOperations) { operation in
                                batchOperationView(operation)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Batch Operation View
    private func batchOperationView(_ operation: BatchStorageOperation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(operation.target.icon) \(operation.target.displayName)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(operation.status.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: operation.progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            HStack {
                Text("\(operation.items.count) Elemente")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let error = operation.error {
                    Text("Fehler: \(error.localizedDescription)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
    }
    
    // MARK: - Smart Suggestions Section
    private var smartSuggestionsSection: some View {
        GroupBox("Intelligente Speicher-Vorschläge") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Die App analysiert Content automatisch und schlägt optimale Speicherziele vor.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Toggle("Content-Analyse aktiviert", isOn: .constant(true))
                        .disabled(true)
                    
                    Spacer()
                }
                
                if let sampleContent = contentAnalyzer.sampleContent {
                    Divider()
                    
                    Text("Beispiel-Analyse:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    suggestionPreviewView
                }
            }
            .padding()
        }
    }
    
    // MARK: - Suggestion Preview
    private var suggestionPreviewView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sample Content: \"Meeting with John tomorrow at 2 PM to discuss project status\"")
                .font(.caption)
                .italic()
                .foregroundColor(.secondary)
            
            let suggestions = storageManager.suggestStorage(for: ContentItem(
                content: "Meeting with John tomorrow at 2 PM to discuss project status",
                type: .meeting
            ))
            
            ForEach(suggestions.prefix(3), id: \.target) { suggestion in
                HStack {
                    Text(suggestion.target.icon)
                    Text(suggestion.target.displayName)
                    Spacer()
                    Text("\(Int(suggestion.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                
                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
            }
        }
    }
    
    // MARK: - Add Workflow View
    private var addWorkflowView: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Workflow-Name", text: $newWorkflowName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !newWorkflowName.isEmpty {
                    // Workflow Configuration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workflow-Konfiguration")
                            .font(.headline)
                        
                        // Add workflow-specific configuration here
                        Text("Hier können Workflow-spezifische Content-Type Konfigurationen definiert werden.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Neuer Workflow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        showAddWorkflow = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        if !newWorkflowName.isEmpty {
                            let config = storageManager.getStorageConfig(for: .note)
                            storageManager.addWorkflowPreference(newWorkflowName, config: config)
                            showAddWorkflow = false
                        }
                    }
                    .disabled(newWorkflowName.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
    
    // MARK: - Export View
    private var exportView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Speicher-Einstellungen exportieren")
                    .font(.headline)
                
                Text("Diese Datei enthält alle aktuellen Speicher-Präferenzen, Content-Type Konfigurationen und Workflow-Einstellungen.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let data = try? storageManager.exportStorageSettings() {
                    ShareLink(
                        item: data,
                        preview: SharePreview(
                            "Storage Settings Export",
                            icon: Image(systemName: "externaldrive.fill.badge.plus")
                        )
                    ) {
                        Label("Export erstellen", systemImage: "externaldrive.fill.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        showExportDialog = false
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack {
            Button(role: .destructive) {
                // Reset to defaults
                storageManager = DefaultStorageManager()
            } label: {
                Label("Zurücksetzen", systemImage: "arrow.clockwise")
            }
            
            Spacer()
            
            Button("Import") {
                showImportDialog = true
            }
            .buttonStyle(.bordered)
            
            Button("Export") {
                showExportDialog = true
            }
            .buttonStyle(.bordered)
            
            Button("OK") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Helper Methods
    private func getDescriptionForContentType(_ type: ContentType) -> String {
        switch type {
        case .email:
            return "E-Mails werden strukturiert in Apple Notes gespeichert, mit Backup in Dropbox für zusätzliche Sicherheit."
        case .meeting:
            return "Meeting-Notizen werden in Notion strukturiert gespeichert, lokales Backup für Offline-Zugriff."
        case .article:
            return "Artikel und News werden in Obsidian als Markdown gespeichert, Cloud-Backup für Synchronisation."
        case .code:
            return "Code-Snippets werden lokal gespeichert (Performance) und zusätzlich in Obsidian für bessere Organisation."
        case .note:
            return "Allgemeine Notizen werden lokal gespeichert für schnellen Zugriff, Apple Notes als sekundäres Ziel."
        case .task:
            return "Aufgaben werden strukturiert in Notion gespeichert, Apple Notes für einfachen Zugriff."
        case .idea:
            return "Ideen werden in Obsidian als Markdown-Notizen gespeichert für flexible Verknüpfungen."
        case .research:
            return "Recherche-Inhalte werden strukturiert gespeichert mit umfangreichen Metadaten und Verknüpfungen."
        case .question:
            return "Fragen werden mit Antworten und Quellenangaben strukturiert gespeichert."
        case .personal:
            return "Persönliche Inhalte werden privat in Apple Notes gespeichert ohne automatische Synchronisation."
        }
    }
    
    private func importFromURL(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                try storageManager.importStorageSettings(from: data)
            } catch {
                print("Import fehlgeschlagen: \(error)")
            }
        case .failure(let error):
            print("Import fehlgeschlagen: \(error)")
        }
    }
}

// MARK: - Preview
struct DefaultStorageSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultStorageSettingsView()
    }
}