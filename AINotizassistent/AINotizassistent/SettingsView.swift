//
//  SettingsView.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Einstellungen")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button("Schließen") {
                    dismiss()
                }
            }
            .padding(.bottom)
            
            // Spracheinstellungen
            GroupBox("Spracheinstellungen") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sprache:")
                        Spacer()
                        Picker("Sprache", selection: $settings.selectedLanguage) {
                            Text("Deutsch").tag("de")
                            Text("English").tag("en")
                            Text("Français").tag("fr")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                    }
                    
                    Toggle("Auto-Transkription", isOn: $settings.autoTranscription)
                    Toggle("Notizen automatisch speichern", isOn: $settings.autoSaveNotes)
                }
                .padding()
            }
            
            // Audioeinstellungen
            GroupBox("Audioeinstellungen") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Mikrofon:")
                        Spacer()
                        Picker("Mikrofon", selection: $settings.selectedMicrophone) {
                            Text("Standard-Mikrofon").tag(0)
                            Text("Externes Mikrofon").tag(1)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Aufnahmequalität:")
                        Spacer()
                        Picker("Qualität", selection: $settings.audioQuality) {
                            Text("Hoch (44.1 kHz)").tag(0)
                            Text("Standard (22 kHz)").tag(1)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 180)
                    }
                    
                    HStack {
                        Text("Empfindlichkeit:")
                        Spacer()
                        Slider(value: $settings.micSensitivity, in: 0...1) {
                            Text("Mikrofon-Empfindlichkeit")
                        }
                        Text("\(Int(settings.micSensitivity * 100))%")
                            .frame(width: 40, alignment: .trailing)
                    }
                }
                .padding()
            }
            
            // Benachrichtigungen
            GroupBox("Benachrichtigungen") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Notiz erstellt", isOn: $settings.notificationNoteCreated)
                    Toggle("Aufnahme gestartet", isOn: $settings.notificationRecordingStarted)
                    Toggle("Fehler", isOn: $settings.notificationErrors)
                }
                .padding()
            }
            
            // Erweiterte Einstellungen
            GroupBox("Erweiterte Einstellungen") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Debug-Modus", isOn: $settings.debugMode)
                    Toggle("Auto-Update", isOn: $settings.autoUpdate)
                    Toggle("Fehlerberichte senden", isOn: $settings.sendCrashReports)
                }
                .padding()
            }
            
            Spacer()
            
            // Aktions-Buttons
            HStack {
                Button("Zurücksetzen") {
                    settings.resetToDefaults()
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Button("OK") {
                    settings.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    @Published var selectedLanguage: String = "de"
    @Published var autoTranscription: Bool = true
    @Published var autoSaveNotes: Bool = true
    @Published var selectedMicrophone: Int = 0
    @Published var audioQuality: Int = 0
    @Published var micSensitivity: Double = 0.7
    @Published var notificationNoteCreated: Bool = true
    @Published var notificationRecordingStarted: Bool = false
    @Published var notificationErrors: Bool = true
    @Published var debugMode: Bool = false
    @Published var autoUpdate: Bool = true
    @Published var sendCrashReports: Bool = false
    
    private let defaults = UserDefaults.standard
    
    private let keys = [
        "selectedLanguage": "de",
        "autoTranscription": true,
        "autoSaveNotes": true,
        "selectedMicrophone": 0,
        "audioQuality": 0,
        "micSensitivity": 0.7,
        "notificationNoteCreated": true,
        "notificationRecordingStarted": false,
        "notificationErrors": true,
        "debugMode": false,
        "autoUpdate": true,
        "sendCrashReports": false
    ]
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Einstellungen aus UserDefaults laden
        selectedLanguage = defaults.string(forKey: "selectedLanguage") ?? "de"
        autoTranscription = defaults.bool(forKey: "autoTranscription")
        autoSaveNotes = defaults.bool(forKey: "autoSaveNotes")
        selectedMicrophone = defaults.integer(forKey: "selectedMicrophone")
        audioQuality = defaults.integer(forKey: "audioQuality")
        micSensitivity = defaults.double(forKey: "micSensitivity")
        notificationNoteCreated = defaults.bool(forKey: "notificationNoteCreated")
        notificationRecordingStarted = defaults.bool(forKey: "notificationRecordingStarted")
        notificationErrors = defaults.bool(forKey: "notificationErrors")
        debugMode = defaults.bool(forKey: "debugMode")
        autoUpdate = defaults.bool(forKey: "autoUpdate")
        sendCrashReports = defaults.bool(forKey: "sendCrashReports")
    }
    
    func save() {
        // Einstellungen in UserDefaults speichern
        defaults.set(selectedLanguage, forKey: "selectedLanguage")
        defaults.set(autoTranscription, forKey: "autoTranscription")
        defaults.set(autoSaveNotes, forKey: "autoSaveNotes")
        defaults.set(selectedMicrophone, forKey: "selectedMicrophone")
        defaults.set(audioQuality, forKey: "audioQuality")
        defaults.set(micSensitivity, forKey: "micSensitivity")
        defaults.set(notificationNoteCreated, forKey: "notificationNoteCreated")
        defaults.set(notificationRecordingStarted, forKey: "notificationRecordingStarted")
        defaults.set(notificationErrors, forKey: "notificationErrors")
        defaults.set(debugMode, forKey: "debugMode")
        defaults.set(autoUpdate, forKey: "autoUpdate")
        defaults.set(sendCrashReports, forKey: "sendCrashReports")
    }
    
    func resetToDefaults() {
        selectedLanguage = "de"
        autoTranscription = true
        autoSaveNotes = true
        selectedMicrophone = 0
        audioQuality = 0
        micSensitivity = 0.7
        notificationNoteCreated = true
        notificationRecordingStarted = false
        notificationErrors = true
        debugMode = false
        autoUpdate = true
        sendCrashReports = false
    }
}