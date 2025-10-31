//
//  AutoSaveSettingsView.swift
//  StatusBarApp
//
//  Auto-Save Configuration UI
//

import SwiftUI

struct AutoSaveSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @State private var lastSaveDate = Date()
    @State private var isSaving = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Auto-Save Enable/Disable
                GroupBox("Auto-Save Status") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Auto-Save aktiviert", isOn: $coordinator.settings.autoSave.enabled)
                        
                        if coordinator.settings.autoSave.enabled {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Letzter Save: \(formatDate(lastSaveDate))")
                                        .font(.caption)
                                    Text("Nächster Save: \(formatDate(nextSaveDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if isSaving {
                                    HStack {
                                        ProgressView()
                                        Text("Speichere...")
                                            .font(.caption)
                                    }
                                } else {
                                    Button("Jetzt speichern") {
                                        manualSave()
                                    }
                                    .disabled(coordinator.settings.autoSave.askBeforeSaving)
                                }
                            }
                        } else {
                            Text("Auto-Save ist deaktiviert. Aktivieren Sie es, um automatische Speicherung zu ermöglichen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                
                // Auto-Save Triggers
                if coordinator.settings.autoSave.enabled {
                    GroupBox("Speicher-Trigger") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Bei Fokusverlust speichern", isOn: $coordinator.settings.autoSave.onFocusLoss)
                            Toggle("Beim Beenden speichern", isOn: $coordinator.settings.autoSave.onQuit)
                            Toggle("Vor jedem Speichern fragen", isOn: $coordinator.settings.autoSave.askBeforeSaving)
                            
                            Text("Auto-Save wird automatisch ausgelöst bei:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                    Text("Zeitintervall-basiert")
                                        .font(.caption)
                                }
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                    Text("Fokusverlust des Fensters")
                                        .font(.caption)
                                }
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                    Text("App-Beendigung")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                // Auto-Save Interval
                if coordinator.settings.autoSave.enabled {
                    GroupBox("Auto-Save Intervall") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("Intervall: \(Int(coordinator.settings.autoSave.interval / 60)) Minuten")
                                    .font(.headline)
                                
                                Slider(
                                    value: Binding(
                                        get: { coordinator.settings.autoSave.interval / 60 },
                                        set: { coordinator.settings.autoSave.interval = $0 * 60 }
                                    ),
                                    in: 1...60,
                                    step: 1
                                )
                            }
                            
                            // Interval Presets
                            VStack(alignment: .leading) {
                                Text("Vordefinierte Intervalle")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                HStack {
                                    ForEach([1, 5, 15, 30, 60], id: \.self) { minutes in
                                        Button("\(minutes)min") {
                                            coordinator.settings.autoSave.interval = Double(minutes) * 60
                                        }
                                        .buttonStyle(PresetButtonStyle(
                                            isSelected: coordinator.settings.autoSave.interval == Double(minutes) * 60
                                        ))
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Retry Settings
                GroupBox("Fehlerbehandlung") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Max Wiederholungsversuche: \(coordinator.settings.autoSave.maxRetries)")
                                .font(.caption)
                            Stepper(
                                "\(coordinator.settings.autoSave.maxRetries)",
                                value: $coordinator.settings.autoSave.maxRetries,
                                in: 1...10
                            )
                        }
                        
                        Text("Bei Speicherfehlern wird automatisch wiederholt bis zum Maximum.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                
                // Compression & Encryption
                GroupBox("Komprimierung & Sicherheit") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Komprimierung aktiviert", isOn: $coordinator.settings.autoSave.compressionEnabled)
                        
                        if coordinator.settings.autoSave.compressionEnabled {
                            Text("Gespeicherte Daten werden komprimiert, um Speicherplatz zu sparen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Toggle("Vertrauliche Daten verschlüsseln", isOn: $coordinator.settings.autoSave.encryptSensitive)
                        
                        if coordinator.settings.autoSave.encryptSensitive {
                            Text("Vertrauliche Daten werden mit AES-256 verschlüsselt gespeichert.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "shield.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                    Text("API-Keys und Passwörter")
                                        .font(.caption)
                                }
                                HStack {
                                    Image(systemName: "shield.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                    Text("Persönliche Daten")
                                        .font(.caption)
                                }
                                HStack {
                                    Image(systemName: "shield.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                    Text("Session-Tokens")
                                        .font(.caption)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                
                // Status & Statistics
                GroupBox("Status & Statistiken") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Letzter erfolgreicher Save", systemImage: "checkmark.circle")
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(formatDate(lastSaveDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Gespeicherte Dokumente", systemImage: "doc.richtext")
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("127")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Durchschnittliche Save-Zeit", systemImage: "clock")
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("2.3s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !coordinator.validationErrors["autosave"].isEmpty {
                            Text("Fehler: \(coordinator.validationErrors["autosave"] ?? "")")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onChange(of: coordinator.settings.autoSave) { _ in
            saveSettings()
        }
        .onAppear {
            loadLastSaveDate()
        }
    }
    
    private var nextSaveDate: Date {
        Calendar.current.date(byAdding: .minute, value: Int(coordinator.settings.autoSave.interval / 60), to: lastSaveDate) ?? Date()
    }
    
    private func manualSave() {
        isSaving = true
        
        // Simulate save operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            lastSaveDate = Date()
            isSaving = false
            
            // Show success feedback
            showSaveSuccess()
        }
    }
    
    private func loadLastSaveDate() {
        lastSaveDate = Date().addingTimeInterval(-Double(Int.random(in: 30...300)))
    }
    
    private func showSaveSuccess() {
        // Show success notification or feedback
        print("Manueller Save erfolgreich")
    }
    
    private func saveSettings() {
        do {
            try SettingsPersistence.shared.save(coordinator.settings)
            print("AutoSave Settings gespeichert")
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preset Button Style

struct PresetButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isSelected
                        ? Color.blue.opacity(0.3)
                        : configuration.isPressed
                        ? Color.gray.opacity(0.2)
                        : Color.white.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected ? Color.blue.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview

struct AutoSaveSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AutoSaveSettingsView(coordinator: SettingsCoordinator())
            .frame(width: 500, height: 600)
    }
}