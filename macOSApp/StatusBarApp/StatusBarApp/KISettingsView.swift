//
//  KISettingsView.swift
//  StatusBarApp
//
//  KI Provider Settings UI
//

import SwiftUI

struct KISettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @State private var selectedProvider = "openai"
    @State private var testConnectionInProgress = false
    @State private var testResult: TestResult?
    
    enum TestResult {
        case success(String)
        case error(String)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Provider Selection
                GroupBox("KI-Provider Auswahl") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Verfügbare KI-Provider")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            ForEach(["openai", "openrouter", "local"], id: \.self) { provider in
                                ProviderToggleRow(
                                    provider: provider,
                                    isEnabled: isProviderEnabled(provider),
                                    onToggle: { toggleProvider(provider) }
                                )
                            }
                        }
                        
                        // Primary Provider
                        if !coordinator.settings.ki.enabledProviders.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Primärer Provider")
                                    .font(.headline)
                                Picker("Primärer Provider", selection: $coordinator.settings.ki.primaryProvider) {
                                    ForEach(coordinator.settings.ki.enabledProviders, id: \.self) { provider in
                                        Text(provider.capitalized).tag(provider)
                                    }
                                }
                                .pickerStyle(RadioGroupPickerStyle())
                            }
                        }
                    }
                }
                
                // OpenAI Settings
                if selectedProvider == "openai" || coordinator.settings.ki.enabledProviders.contains("openai") {
                    GroupBox("OpenAI Konfiguration") {
                        VStack(alignment: .leading, spacing: 16) {
                            // API Key
                            SecureField("API Key", text: $coordinator.settings.ki.openAI.apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            // Model Selection
                            VStack(alignment: .leading) {
                                Text("Model")
                                    .font(.headline)
                                Picker("Model", selection: $coordinator.settings.ki.openAI.model) {
                                    Text("GPT-4").tag("gpt-4")
                                    Text("GPT-4 Turbo").tag("gpt-4-turbo")
                                    Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                                    Text("GPT-4o").tag("gpt-4o")
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            // Advanced Settings
                            CollapsibleSection("Erweiterte Einstellungen") {
                                VStack(alignment: .leading, spacing: 12) {
                                    VStack(alignment: .leading) {
                                        Text("Max Tokens: \(coordinator.settings.ki.openAI.maxTokens)")
                                            .font(.caption)
                                        Slider(value: $coordinator.settings.ki.openAI.maxTokens, in: 100...8000, step: 100)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Temperature: \(String(format: "%.1f", coordinator.settings.ki.openAI.temperature))")
                                            .font(.caption)
                                        Slider(value: $coordinator.settings.ki.openAI.temperature, in: 0.0...2.0, step: 0.1)
                                    }
                                    
                                    Toggle("Stream", isOn: $coordinator.settings.ki.openAI.stream)
                                }
                            }
                            
                            // Test Connection
                            HStack {
                                Button("Verbindung testen") {
                                    testConnection(provider: "openai")
                                }
                                .disabled(testConnectionInProgress)
                                
                                if testConnectionInProgress {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            
                            // Test Result
                            if let result = testResult {
                                TestResultView(result: result)
                            }
                        }
                    }
                }
                
                // OpenRouter Settings
                if coordinator.settings.ki.enabledProviders.contains("openrouter") {
                    GroupBox("OpenRouter Konfiguration") {
                        VStack(alignment: .leading, spacing: 16) {
                            SecureField("API Key", text: $coordinator.settings.ki.openRouter.apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            VStack(alignment: .leading) {
                                Text("Base URL")
                                    .font(.caption)
                                TextField("https://openrouter.ai/api/v1", text: $coordinator.settings.ki.openRouter.baseURL)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Default Model")
                                    .font(.headline)
                                TextField("meta-llama/llama-2-70b-chat", text: $coordinator.settings.ki.openRouter.defaultModel)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Max Tokens: \(coordinator.settings.ki.openRouter.maxTokens)")
                                    .font(.caption)
                                Slider(value: $coordinator.settings.ki.openRouter.maxTokens, in: 100...8000, step: 100)
                            }
                            
                            HStack {
                                Button("Verbindung testen") {
                                    testConnection(provider: "openrouter")
                                }
                                .disabled(testConnectionInProgress)
                            }
                        }
                    }
                }
                
                // Local Models Settings
                if coordinator.settings.ki.enabledProviders.contains("local") {
                    GroupBox("Lokale Modelle") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Lokale LLM-Modelle konfigurieren")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading) {
                                Text("Model Pfad")
                                    .font(.caption)
                                HStack {
                                    TextField("/pfad/zu/model.llamafile", text: $coordinator.settings.ki.localModels.modelPath)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Button("Durchsuchen") {
                                        selectLocalModel()
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Context Length: \(coordinator.settings.ki.localModels.contextLength)")
                                    .font(.caption)
                                Slider(value: $coordinator.settings.ki.localModels.contextLength, in: 512...8192, step: 256)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("GPU Layers: \(coordinator.settings.ki.localModels.gpuLayers)")
                                    .font(.caption)
                                Slider(value: $coordinator.settings.ki.localModels.gpuLayers, in: 0...100, step: 1)
                            }
                        }
                    }
                }
                
                // Global KI Settings
                GroupBox("Globale KI-Einstellungen") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Timeout (Sekunden): \(Int(coordinator.settings.ki.timeout))")
                                .font(.caption)
                            Slider(value: $coordinator.settings.ki.timeout, in: 10...120, step: 5)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Wiederholungsversuche: \(coordinator.settings.ki.retryAttempts)")
                                .font(.caption)
                            Stepper("\(coordinator.settings.ki.retryAttempts)", value: $coordinator.settings.ki.retryAttempts, in: 1...10)
                        }
                        
                        Toggle("Logging aktivieren", isOn: $coordinator.settings.ki.enableLogging)
                        
                        if !coordinator.validationErrors["ki"].isEmpty {
                            Text("Fehler: \(coordinator.validationErrors["ki"] ?? "")")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onChange(of: coordinator.settings.ki) { _ in
            saveSettings()
        }
    }
    
    private func isProviderEnabled(_ provider: String) -> Bool {
        coordinator.settings.ki.enabledProviders.contains(provider)
    }
    
    private func toggleProvider(_ provider: String) {
        if isProviderEnabled(provider) {
            coordinator.settings.ki.enabledProviders.removeAll { $0 == provider }
        } else {
            coordinator.settings.ki.enabledProviders.append(provider)
        }
    }
    
    private func testConnection(provider: String) {
        testConnectionInProgress = true
        testResult = nil
        
        // Simuliere API-Test
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let success = Bool.random()
            if success {
                testResult = .success("Verbindung zu \(provider) erfolgreich!")
            } else {
                testResult = .error("Verbindung fehlgeschlagen - Bitte API-Key überprüfen")
            }
            testConnectionInProgress = false
        }
    }
    
    private func selectLocalModel() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["llamafile", "gguf", "ggml", "bin"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            coordinator.settings.ki.localModels.modelPath = url.path
        }
    }
    
    private func saveSettings() {
        do {
            try SettingsPersistence.shared.save(coordinator.settings)
            print("KI Settings gespeichert")
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
}

// MARK: - Provider Toggle Row

struct ProviderToggleRow: View {
    let provider: String
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Toggle(provider.capitalized, isOn: .constant(isEnabled))
                .onTapGesture {
                    onToggle()
                }
            
            Spacer()
            
            // Provider Icon/Status
            HStack(spacing: 4) {
                Circle()
                    .fill(isEnabled ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                if provider == "openai" {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                } else if provider == "openrouter" {
                    Image(systemName: "network")
                        .font(.caption)
                } else {
                    Image(systemName: "internaldrive")
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Test Result View

struct TestResultView: View {
    let result: TestResult
    
    var body: some View {
        HStack {
            switch result {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(result.message)
                    .foregroundColor(.green)
            case .error:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text(result.message)
                    .foregroundColor(.red)
            }
        }
        .font(.caption)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(result == .success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

extension TestResult {
    var message: String {
        switch self {
        case .success(let msg): return msg
        case .error(let msg): return msg
        }
    }
}

// MARK: - Preview

struct KISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        KISettingsView(coordinator: SettingsCoordinator())
            .frame(width: 500, height: 600)
    }
}