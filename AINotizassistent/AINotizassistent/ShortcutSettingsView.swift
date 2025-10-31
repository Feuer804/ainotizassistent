//
//  ShortcutSettingsView.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI
import Carbon

struct ShortcutSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shortcutManager = ShortcutManager()
    
    @State private var selectedCategory: ShortcutCategory = .primary
    @State private var editingShortcut: AppShortcut?
    @State private var isCapturingKey = false
    @State private var showAddCustom = false
    @State private var newCustomName = ""
    @State private var newCustomDescription = ""
    @State private var newCustomKeyCombo: KeyCombo?
    
    @State private var showImportDialog = false
    @State private var showExportDialog = false
    @State private var showConflictResolver = false
    @State private var selectedConflict: SystemShortcutConflict?
    
    private let categories = ShortcutCategory.allCases
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Category Tabs
            categoryTabs
            
            // Shortcut List
            shortcutList
            
            // Conflict Detection
            if !shortcutManager.systemConflicts.isEmpty {
                conflictWarningSection
            }
            
            // Gesture & Voice Shortcuts
            gestureVoiceSection
            
            Spacer()
            
            // Action Buttons
            actionButtons
        }
        .padding()
        .frame(width: 700, height: 800)
        .sheet(isPresented: $showAddCustom) {
            addCustomShortcutView
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
        .sheet(isPresented: $showConflictResolver, onDismiss: {
            selectedConflict = nil
        }) {
            if let conflict = selectedConflict {
                conflictResolverView(conflict)
            }
        }
        .onAppear {
            shortcutManager.detectSystemConflicts()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Shortcut-Einstellungen")
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
            
            Button("Schließen") {
                dismiss()
            }
        }
    }
    
    // MARK: - Category Tabs
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack {
                            Text(category.icon)
                            Text(category.displayName)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == category ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Shortcut List
    private var shortcutList: some View {
        GroupBox("Tastatur-Shortcuts") {
            VStack(alignment: .leading, spacing: 12) {
                // Add Custom Shortcut Button
                if selectedCategory == .custom {
                    Button {
                        newCustomName = ""
                        newCustomDescription = ""
                        newCustomKeyCombo = nil
                        showAddCustom = true
                    } label: {
                        Label("Benutzerdefinierten Shortcut hinzufügen", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                }
                
                // Shortcut Items
                let filteredShortcuts = shortcutManager.shortcuts.filter { $0.category == selectedCategory }
                
                if filteredShortcuts.isEmpty {
                    Text("Keine Shortcuts in dieser Kategorie")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(filteredShortcuts) { shortcut in
                                shortcutRowView(shortcut)
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Shortcut Row View
    private func shortcutRowView(_ shortcut: AppShortcut) -> some View {
        HStack {
            // Icon and Name
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(shortcut.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if shortcut.category == .custom {
                        Button(role: .destructive) {
                            shortcutManager.removeCustomShortcut(shortcut.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }
                }
                
                Text(shortcut.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Key Combo
            HStack {
                Text(shortcut.keyCombo.displayString)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                    .onTapGesture {
                        startKeyCapture(for: shortcut)
                    }
                
                // Enable/Disable Toggle
                Toggle("", isOn: .constant(shortcut.isEnabled))
                    .onChange(of: shortcut.isEnabled) { _, newValue in
                        shortcutManager.setShortcutEnabled(shortcut.id, enabled: newValue)
                    }
                    .labelsHidden()
                
                // Conflict Indicator
                if let conflict = shortcutManager.systemConflicts.first(where: { $0.appShortcut.id == shortcut.id }) {
                    Button {
                        selectedConflict = conflict
                        showConflictResolver = true
                    } label: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .help("Konflikt erkannt")
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(shortcut.isEnabled ? Color.clear : Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Conflict Warning Section
    private var conflictWarningSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Shortcut-Konflikte erkannt")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button("Alle anzeigen") {
                        showConflictResolver = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(shortcutManager.systemConflicts.prefix(3), id: \.appShortcut.id) { conflict in
                        HStack {
                            Text("\(conflict.appShortcut.name)")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(conflict.conflictingApps.count) Konflikte")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Gesture & Voice Section
    private var gestureVoiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Gesture Shortcuts
            GroupBox("Trackpad-Gesten") {
                VStack(alignment: .leading, spacing: 8) {
                    if shortcutManager.gestureShortcuts.isEmpty {
                        Text("Keine Gesture-Shortcuts konfiguriert")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(shortcutManager.gestureShortcuts) { gesture in
                            HStack {
                                Text(gesture.name)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text(gesture.gestureType.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Toggle("", isOn: .constant(gesture.isEnabled))
                                    .labelsHidden()
                            }
                            .padding(4)
                        }
                    }
                }
                .padding()
            }
            
            // Voice Command Shortcuts
            GroupBox("Sprachbefehle") {
                VStack(alignment: .leading, spacing: 8) {
                    if shortcutManager.voiceCommandShortcuts.isEmpty {
                        Text("Keine Sprachbefehle konfiguriert")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(shortcutManager.voiceCommandShortcuts) { voice in
                            HStack {
                                Text(voice.trigger)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(Int(voice.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Toggle("", isOn: .constant(voice.isEnabled))
                                    .labelsHidden()
                            }
                            .padding(4)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Key Capture
    private func startKeyCapture(for shortcut: AppShortcut) {
        editingShortcut = shortcut
        isCapturingKey = true
        
        // Key capture implementation would go here
        // This would involve setting up a global event tap to capture key presses
    }
    
    // MARK: - Add Custom Shortcut View
    private var addCustomShortcutView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Form {
                    Section("Details") {
                        TextField("Name", text: $newCustomName)
                        TextField("Beschreibung", text: $newCustomDescription, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    
                    Section("Tastatur-Shortcut") {
                        HStack {
                            Text("Taste:")
                            Spacer()
                            Text(newCustomKeyCombo?.displayString ?? "Drücken zum Definieren...")
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                                .onTapGesture {
                                    startKeyCapture()
                                }
                        }
                        
                        if let keyCombo = newCustomKeyCombo {
                            let validation = shortcutManager.validateKeyCombo(keyCombo)
                            Text(validation.message)
                                .font(.caption)
                                .foregroundColor(validation.isValid ? .green : .red)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Benutzerdefinierter Shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        showAddCustom = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        if let keyCombo = newCustomKeyCombo,
                           !newCustomName.isEmpty,
                           !newCustomDescription.isEmpty {
                            shortcutManager.addCustomShortcut(
                                newCustomName,
                                description: newCustomDescription,
                                keyCombo: keyCombo
                            ) {
                                print("Custom shortcut '\(newCustomName)' triggered")
                            }
                            showAddCustom = false
                        }
                    }
                    .disabled(newCustomName.isEmpty || newCustomDescription.isEmpty || newCustomKeyCombo == nil)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func startKeyCapture() {
        shortcutManager.startKeyComboCapture()
    }
    
    // MARK: - Conflict Resolver View
    private func conflictResolverView(_ conflict: SystemShortcutConflict) -> some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shortcut-Konflikt")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Shortcut:")
                        Spacer()
                        Text(conflict.appShortcut.name)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Aktuelle Taste:")
                        Spacer()
                        Text(conflict.appShortcut.keyCombo.displayString)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                GroupBox("Erkannte Konflikte") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(conflict.conflictingApps, id: \.self) { appName in
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                
                                Text(appName)
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding(4)
                        }
                    }
                }
                
                GroupBox("Lösungsempfehlung") {
                    Text(conflict.suggestion)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Konflikt beheben")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        showConflictResolver = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Shortcut ändern") {
                        // Open key capture for this specific shortcut
                        startKeyCapture(for: conflict.appShortcut)
                        showConflictResolver = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    // MARK: - Export View
    private var exportView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Shortcut-Einstellungen exportieren")
                    .font(.headline)
                
                Text("Diese Datei enthält alle aktuellen Tastatur-Shortcuts, Gesture- und Sprachbefehl-Konfigurationen.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                let data = shortcutManager.exportShortcuts()
                ShareLink(
                    item: data,
                    preview: SharePreview(
                        "Shortcut Settings Export",
                        icon: Image(systemName: "keyboard.fill.badge.plus")
                    )
                ) {
                    Label("Export erstellen", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                
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
                shortcutManager.resetToDefaults()
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
            
            Button("Teste Shortcuts") {
                testAllShortcuts()
            }
            .buttonStyle(.bordered)
            
            Button("OK") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Testing
    private func testAllShortcuts() {
        for shortcut in shortcutManager.shortcuts where shortcut.isEnabled {
            shortcutManager.triggerShortcut(shortcut)
        }
    }
    
    // MARK: - Import
    private func importFromURL(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                try shortcutManager.importShortcuts(from: data)
            } catch {
                print("Import fehlgeschlagen: \(error)")
            }
        case .failure(let error):
            print("Import fehlgeschlagen: \(error)")
        }
    }
}

// MARK: - Preview
struct ShortcutSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutSettingsView()
    }
}

// MARK: - Key Capture Sheet
struct KeyCaptureSheet: View {
    @Binding var isPresented: Bool
    @Binding var capturedKeyCombo: KeyCombo?
    @State private var captureText = "Drücken Sie eine Tasten-Kombination..."
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tastatur-Shortcut definieren")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(captureText)
                .font(.system(.body, design: .monospaced))
                .padding(20)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            HStack {
                Button("Abbrechen") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                if capturedKeyCombo != nil {
                    Button("Übernehmen") {
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}

// MARK: - Shortcut Validation Badge
struct ShortcutValidationBadge: View {
    let validation: (isValid: Bool, message: String)
    
    var body: some View {
        HStack {
            Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(validation.isValid ? .green : .red)
            
            Text(validation.message)
                .font(.caption)
                .foregroundColor(validation.isValid ? .green : .red)
        }
    }
}