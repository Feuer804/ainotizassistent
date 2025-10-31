//
//  ShortcutsSettingsView.swift
//  StatusBarApp
//
//  Shortcuts and Hotkeys Configuration
//

import SwiftUI

struct ShortcutsSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @State private var recordingShortcut: String? = nil
    @State private var conflictDetected: Bool = false
    @State private var testMode: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Global Shortcuts
                GroupBox("Globale Tastenkombinationen") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Globale Shortcuts aktiviert", isOn: $coordinator.settings.shortcuts.enableGlobalShortcuts)
                        
                        if coordinator.settings.shortcuts.enableGlobalShortcuts {
                            VStack(alignment: .leading, spacing: 12) {
                                ShortcutRow(
                                    title: "App anzeigen/verstecken",
                                    description: "Zeigt das StatusBar-Fenster an oder versteckt es",
                                    shortcut: $coordinator.settings.shortcuts.globalShortcut,
                                    action: { showShortcutHelp("global") }
                                )
                                
                                ShortcutRow(
                                    title: "Fenster anzeigen",
                                    description: "Öffnet das Hauptfenster",
                                    shortcut: $coordinator.settings.shortcuts.showWindowShortcut,
                                    action: { showShortcutHelp("show") }
                                )
                                
                                ShortcutRow(
                                    title: "Fenster verstecken",
                                    description: "Versteckt das Hauptfenster",
                                    shortcut: $coordinator.settings.shortcuts.hideWindowShortcut,
                                    action: { showShortcutHelp("hide") }
                                )
                            }
                        } else {
                            Text("Globale Shortcuts sind deaktiviert. Aktivieren Sie sie, um Tastenkombinationen zu verwenden.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                
                // Application Shortcuts
                GroupBox("App-Shortcuts") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("System-Shortcuts aktiviert", isOn: $coordinator.settings.shortcuts.enableSystemShortcuts)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ShortcutRow(
                                title: "Einstellungen öffnen",
                                description: "Öffnet das Einstellungsfenster",
                                shortcut: $coordinator.settings.shortcuts.settingsShortcut,
                                action: { showShortcutHelp("settings") }
                            )
                            
                            ShortcutRow(
                                title: "App beenden",
                                description: "Beendet die Anwendung",
                                shortcut: $coordinator.settings.shortcuts.quitShortcut,
                                action: { showShortcutHelp("quit") }
                            )
                        }
                    }
                }
                
                // Conflict Detection
                if coordinator.settings.shortcuts.conflictDetection {
                    GroupBox("Konflikt-Erkennung") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Konflikt-Erkennung aktiviert", isOn: $coordinator.settings.shortcuts.conflictDetection)
                            
                            if conflictDetected {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    VStack(alignment: .leading) {
                                        Text("Konflikt erkannt!")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text("Die Tastenkombination wird bereits von einem anderen Programm verwendet.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.orange.opacity(0.1))
                                )
                            }
                            
                            Button("Alle Shortcuts auf Konflikte prüfen") {
                                checkAllConflicts()
                            }
                            .buttonStyle(ConflictCheckButtonStyle())
                        }
                    }
                }
                
                // Custom Shortcuts
                GroupBox("Benutzerdefinierte Shortcuts") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Aktion hinzufügen")
                                .font(.headline)
                            
                            HStack {
                                TextField("Aktionsname", text: $newActionName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Tastenkombination", text: $newShortcutKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 120)
                                
                                Button("Hinzufügen") {
                                    addCustomShortcut()
                                }
                                .disabled(newActionName.isEmpty || newShortcutKey.isEmpty)
                            }
                        }
                        
                        if !coordinator.settings.shortcuts.customShortcuts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Benutzerdefinierte Aktionen")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                ForEach(Array(coordinator.settings.shortcuts.customShortcuts.keys.sorted()), id: \.self) { action in
                                    HStack {
                                        Text(action)
                                            .font(.caption)
                                        
                                        Spacer()
                                        
                                        Text(coordinator.settings.shortcuts.customShortcuts[action] ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Button("Entfernen") {
                                            removeCustomShortcut(action)
                                        }
                                        .buttonStyle(TextButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Test Mode
                GroupBox("Test-Modus") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Test-Modus aktiviert", isOn: $testMode)
                        
                        if testMode {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Im Test-Modus werden alle Tastenkombinationen erfasst und angezeigt.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Drücken Sie eine Tastenkombination:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    if let recordedShortcut = lastRecordedShortcut {
                                        Text(recordedShortcut)
                                            .font(.caption)
                                            .padding(4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.blue.opacity(0.1))
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Shortcuts List & Help
                GroupBox("Verfügbare Aktionen") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hier sind alle verfügbaren Aktionen und ihre aktuellen Tastenkombinationen:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // System Actions
                            ForEach(shortcutsData, id: \.id) { shortcut in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(shortcut.title)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text(shortcut.description)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(shortcut.shortcut)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.gray.opacity(0.2))
                                        )
                                }
                            }
                        }
                    }
                }
                
                // Shortcuts Help
                GroupBox("Hilfe") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Tastenkombination erstellen") {
                            showShortcutCreationHelp()
                        }
                        .buttonStyle(HelpButtonStyle())
                        
                        Button("Konflikte lösen") {
                            showConflictResolution()
                        }
                        .buttonStyle(HelpButtonStyle())
                        
                        Button("Standard-Shortcuts wiederherstellen") {
                            resetToDefaults()
                        }
                        .buttonStyle(DestructiveButtonStyle())
                        
                        Text("Tastenkombinationen-Format:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⌘ = Command/Strg")
                                .font(.caption)
                            Text("⇧ = Shift")
                                .font(.caption)
                            Text("⌥ = Option/Alt")
                                .font(.caption)
                            Text("⌃ = Control")
                                .font(.caption)
                            Text("⏎ = Enter/Return")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onChange(of: coordinator.settings.shortcuts) { _ in
            saveSettings()
            checkConflicts()
        }
        .onAppear {
            checkConflicts()
        }
    }
    
    @State private var newActionName = ""
    @State private var newShortcutKey = ""
    @State private var lastRecordedShortcut: String?
    
    private func addCustomShortcut() {
        guard !newActionName.isEmpty && !newShortcutKey.isEmpty else { return }
        
        coordinator.settings.shortcuts.customShortcuts[newActionName] = newShortcutKey
        newActionName = ""
        newShortcutKey = ""
    }
    
    private func removeCustomShortcut(_ action: String) {
        coordinator.settings.shortcuts.customShortcuts.removeValue(forKey: action)
    }
    
    private func showShortcutHelp(_ type: String) {
        // Show help for specific shortcut type
        print("Hilfe für Shortcut: \(type)")
    }
    
    private func checkAllConflicts() {
        // Check all shortcuts for conflicts
        conflictDetected = Bool.random() // Simulate conflict detection
    }
    
    private func checkConflicts() {
        // Real conflict checking logic would go here
        let hasConflicts = false // Placeholder
        withAnimation(.easeInOut(duration: 0.3)) {
            conflictDetected = hasConflicts
        }
    }
    
    private func showShortcutCreationHelp() {
        // Show detailed help for creating shortcuts
        let alert = NSAlert()
        alert.messageText = "Tastenkombination erstellen"
        alert.informativeText = """
        So erstellen Sie eine neue Tastenkombination:
        
        1. Klicken Sie auf das Textfeld für die Tastenkombination
        2. Drücken Sie die gewünschten Tasten (z.B. ⌘⇧K)
        3. Die Tastenkombination wird automatisch erkannt
        
        Gültige Modifier:
        ⌘ = Command/Strg
        ⇧ = Shift
        ⌥ = Option/Alt
        ⌃ = Control
        """
        alert.runModal()
    }
    
    private func showConflictResolution() {
        // Show conflict resolution dialog
        let alert = NSAlert()
        alert.messageText = "Konfliktlösung"
        alert.informativeText = """
        Wenn eine Tastenkombination bereits verwendet wird:
        
        1. Wählen Sie eine andere Kombination
        2. Oder deaktivieren Sie den Konflikt in der anderen App
        3. Oder behalten Sie beide - die zuletzt registrierte gewinnt
        
        Tipp: Verwenden Sie spezielle Modifier-Kombinationen um Konflikte zu vermeiden.
        """
        alert.runModal()
    }
    
    private func resetToDefaults() {
        let alert = NSAlert()
        alert.messageText = "Standard-Shortcuts wiederherstellen?"
        alert.informativeText = "Alle benutzerdefinierten Shortcuts werden gelöscht und die Standardwerte wiederhergestellt."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Wiederherstellen")
        alert.addButton(withTitle: "Abbrechen", role: .cancel)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            coordinator.settings.shortcuts = ShortcutsSettings()
        }
    }
    
    private func saveSettings() {
        do {
            try SettingsPersistence.shared.save(coordinator.settings)
            print("Shortcuts Settings gespeichert")
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
}

// MARK: - Shortcut Row Component

struct ShortcutRow: View {
    let title: String
    let description: String
    @Binding var shortcut: String
    let action: () -> Void
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isEditing {
                TextField("⌘⇧N", text: $shortcut, onCommit: {
                    isEditing = false
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 120)
            } else {
                Button(shortcut.isEmpty ? "Keine" : shortcut) {
                    isEditing = true
                }
                .buttonStyle(ShortcutButtonStyle())
            }
            
            Button("Hilfe") {
                action()
            }
            .buttonStyle(TextButtonStyle())
        }
    }
}

// MARK: - Button Styles

struct ShortcutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        configuration.isPressed
                        ? Color.blue.opacity(0.3)
                        : Color.white.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

struct TextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.blue)
            .underline()
    }
}

struct ConflictCheckButtonStyle: ButtonStyle {
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

// MARK: - Shortcuts Data

let shortcutsData = [
    ShortcutData(id: "1", title: "App anzeigen/verstecken", description: "Zeigt das StatusBar-Fenster an oder versteckt es", shortcut: "⌘⇧N"),
    ShortcutData(id: "2", title: "Fenster anzeigen", description: "Öffnet das Hauptfenster", shortcut: "⌘⇧W"),
    ShortcutData(id: "3", title: "Fenster verstecken", description: "Versteckt das Hauptfenster", shortcut: "⌘⇧H"),
    ShortcutData(id: "4", title: "Einstellungen", description: "Öffnet das Einstellungsfenster", shortcut: "⌘,"),
    ShortcutData(id: "5", title: "App beenden", description: "Beendet die Anwendung", shortcut: "⌘Q")
]

struct ShortcutData: Identifiable {
    let id: String
    let title: String
    let description: String
    let shortcut: String
}

// MARK: - Preview

struct ShortcutsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutsSettingsView(coordinator: SettingsCoordinator())
            .frame(width: 500, height: 700)
    }
}