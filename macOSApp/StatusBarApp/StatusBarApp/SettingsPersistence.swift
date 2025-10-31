//
//  SettingsPersistence.swift
//  StatusBarApp
//
//  Settings Persistenz Layer mit Verschlüsselung
//

import Foundation

class SettingsPersistence: ObservableObject {
    static let shared = SettingsPersistence()
    
    private let settingsKey = "StatusBarApp_Settings"
    private let encryptionKey = "StatusBarApp_EncryptionKey"
    
    private init() {}
    
    // MARK: - Save Settings
    
    func save(_ settings: AppSettings) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        var data: Data
        do {
            data = try encoder.encode(settings)
        } catch {
            throw SettingsError.encodingFailed(underlying: error)
        }
        
        // Verschlüsselung wenn aktiviert
        if settings.privacy.enableEncryption {
            data = try encrypt(data)
        }
        
        // UserDefaults für kleine Settings, File für große
        if data.count < 1024 * 1024 { // 1MB
            UserDefaults.standard.set(data, forKey: settingsKey)
        } else {
            try saveToFile(data)
        }
        
        print("Settings erfolgreich gespeichert (\(data.count) bytes)")
    }
    
    // MARK: - Load Settings
    
    func load() throws -> AppSettings {
        var data: Data?
        
        // Zuerst UserDefaults probieren
        if let userDefaultsData = UserDefaults.standard.data(forKey: settingsKey) {
            data = userDefaultsData
        } else {
            // Dann File probieren
            data = try loadFromFile()
        }
        
        guard let settingsData = data else {
            throw SettingsError.noSettingsFound
        }
        
        var decodedData = settingsData
        
        // Entschlüsselung wenn erforderlich
        if isDataEncrypted(settingsData) {
            decodedData = try decrypt(settingsData)
        }
        
        let decoder = JSONDecoder()
        do {
            let settings = try decoder.decode(AppSettings.self, from: decodedData)
            print("Settings erfolgreich geladen (\(settingsData.count) bytes)")
            return settings
        } catch {
            throw SettingsError.decodingFailed(underlying: error)
        }
    }
    
    // MARK: - File Operations
    
    private func saveToFile(_ data: Data) throws {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let settingsPath = documentsPath.appendingPathComponent("settings.enc")
        
        try data.write(to: settingsPath)
        print("Settings zu Datei gespeichert: \(settingsPath.path)")
    }
    
    private func loadFromFile() throws -> Data? {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let settingsPath = documentsPath.appendingPathComponent("settings.enc")
        
        if fileManager.fileExists(atPath: settingsPath.path) {
            let data = try Data(contentsOf: settingsPath)
            print("Settings von Datei geladen: \(settingsPath.path)")
            return data
        }
        
        return nil
    }
    
    // MARK: - Encryption/Decryption
    
    private func encrypt(_ data: Data) throws -> Data {
        let key = getEncryptionKey()
        
        var encryptedData = data
        
        // Einfache XOR-Verschlüsselung für Demo (in Produktion AES verwenden)
        for i in 0..<encryptedData.count {
            encryptedData[i] ^= key[i % key.count]
        }
        
        return Data([0x45, 0x4E, 0x43]) + encryptedData // "ENC" prefix
    }
    
    private func decrypt(_ encryptedData: Data) throws -> Data {
        guard encryptedData.count > 3, encryptedData.prefix(3) == Data([0x45, 0x4E, 0x43]) else {
            throw SettingsError.invalidDataFormat
        }
        
        let key = getEncryptionKey()
        var decryptedData = encryptedData.dropFirst(3)
        
        // XOR-Entschlüsselung
        for i in 0..<decryptedData.count {
            decryptedData[i] ^= key[i % key.count]
        }
        
        return decryptedData
    }
    
    private func getEncryptionKey() -> [UInt8] {
        let password = "StatusBarApp2025SecureKey"
        let keyData = password.data(using: .utf8) ?? Data()
        return Array(keyData)
    }
    
    private func isDataEncrypted(_ data: Data) -> Bool {
        return data.count > 3 && data.prefix(3) == Data([0x45, 0x4E, 0x43])
    }
    
    // MARK: - Backup Operations
    
    func createBackup() throws -> URL {
        let settings = try load()
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        
        let fileName = "StatusBarApp_Backup_\(timestamp).json"
        let tempPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(settings)
        
        try data.write(to: tempPath)
        print("Backup erstellt: \(tempPath.path)")
        
        return tempPath
    }
    
    func restoreBackup(from url: URL) throws -> AppSettings {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        let settings = try decoder.decode(AppSettings.self, from: data)
        print("Backup wiederhergestellt: \(url.path)")
        
        return settings
    }
    
    func cleanup() {
        // Settings-Dateien bereinigen
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let settingsPath = documentsPath.appendingPathComponent("settings.enc")
        
        if fileManager.fileExists(atPath: settingsPath.path) {
            try? fileManager.removeItem(at: settingsPath)
            print("Settings-Datei bereinigt")
        }
        
        UserDefaults.standard.removeObject(forKey: settingsKey)
        print("Settings aus UserDefaults bereinigt")
    }
}

// MARK: - Export/Import Manager

class SettingsExportImport {
    static let shared = SettingsExportImport()
    
    private init() {}
    
    // MARK: - Export
    
    func export(_ settings: AppSettings) throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        
        let fileName = "StatusBarApp_Settings_\(timestamp).json"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportPath = documentsPath.appendingPathComponent(fileName)
        
        // Sanitize settings für Export (sensitive Daten entfernen)
        let sanitizedSettings = sanitizeSettingsForExport(settings)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(sanitizedSettings)
        
        try data.write(to: exportPath)
        print("Settings exportiert: \(exportPath.path)")
        
        return exportPath
    }
    
    // MARK: - Import
    
    func import(from url: URL) throws -> AppSettings {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        let importedSettings = try decoder.decode(AppSettings.self, from: data)
        print("Settings importiert: \(url.path)")
        
        return importedSettings
    }
    
    // MARK: - Validation
    
    func validateSettingsFile(_ url: URL) throws -> Bool {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        do {
            _ = try decoder.decode(AppSettings.self, from: data)
            print("Settings-Datei ist gültig")
            return true
        } catch {
            print("Settings-Datei ist ungültig: \(error)")
            return false
        }
    }
    
    // MARK: - Sanitization
    
    private func sanitizeSettingsForExport(_ settings: AppSettings) -> AppSettings {
        var sanitized = settings
        
        // API Keys entfernen für Sicherheit
        sanitized.ki.openAI.apiKey = "***HIDDEN***"
        sanitized.ki.openRouter.apiKey = "***HIDDEN***"
        sanitized.storage.dropbox.accessToken = "***HIDDEN***"
        
        // Lokale Pfade neutralisieren
        sanitized.storage.local.path = "/path/to/local/storage"
        
        print("Settings für Export sanitisiert")
        return sanitized
    }
}

// MARK: - Settings Error Types

enum SettingsError: Error, LocalizedError {
    case noSettingsFound
    case encodingFailed(underlying: Error)
    case decodingFailed(underlying: Error)
    case invalidDataFormat
    case fileOperationFailed(underlying: Error)
    case encryptionFailed(underlying: Error)
    case decryptionFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .noSettingsFound:
            return "Keine Einstellungen gefunden"
        case .encodingFailed(let error):
            return "Fehler beim Kodieren: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Fehler beim Dekodieren: \(error.localizedDescription)"
        case .invalidDataFormat:
            return "Ungültiges Datenformat"
        case .fileOperationFailed(let error):
            return "Dateiverarbeitung fehlgeschlagen: \(error.localizedDescription)"
        case .encryptionFailed(let error):
            return "Verschlüsselung fehlgeschlagen: \(error.localizedDescription)"
        case .decryptionFailed(let error):
            return "Entschlüsselung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}

// MARK: - Export/Import View

struct ExportImportView: View {
    let type: ExportImportType
    @ObservedObject var coordinator: SettingsCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text(type.title)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(type.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if type == .export {
                HStack {
                    Button("Export starten") {
                        performExport()
                    }
                    .buttonStyle(ExportButtonStyle())
                    .disabled(isProcessing)
                    
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .buttonStyle(CancelButtonStyle())
                    
                    Spacer()
                }
            } else {
                HStack {
                    Button("Datei auswählen") {
                        selectImportFile()
                    }
                    .buttonStyle(ImportButtonStyle())
                    .disabled(isProcessing)
                    
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .buttonStyle(CancelButtonStyle())
                    
                    Spacer()
                }
            }
            
            if isProcessing {
                HStack {
                    ProgressView()
                    Text(type.processingText)
                }
            }
            
            Spacer()
        }
        .padding()
        .alert("Fehler", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func performExport() {
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            do {
                let exportURL = try SettingsExportImport.shared.export(coordinator.settings)
                
                // Export-Ordner öffnen
                NSWorkspace.shared.selectFile(exportURL.path, inFileViewerRootedAtPath: exportURL.deletingLastPathComponent().path)
                
                isProcessing = false
                dismiss()
            } catch {
                errorMessage = "Export fehlgeschlagen: \(error.localizedDescription)"
                showingError = true
                isProcessing = false
            }
        }
    }
    
    private func selectImportFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["json"]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            performImport(from: url)
        }
    }
    
    private func performImport(from url: URL) {
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            do {
                // Validierung
                guard SettingsExportImport.shared.validateSettingsFile(url) else {
                    throw SettingsError.invalidDataFormat
                }
                
                let importedSettings = try SettingsExportImport.shared.import(from: url)
                
                // Benutzer fragen
                let alert = NSAlert()
                alert.messageText = "Settings importieren?"
                alert.informativeText = "Möchten Sie die Einstellungen aus der Datei importieren? Dies überschreibt Ihre aktuellen Einstellungen."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Importieren")
                alert.addButton(withTitle: "Abbrechen", role: .cancel)
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    coordinator.settings = importedSettings
                    try coordinator.saveSettings()
                    
                    isProcessing = false
                    dismiss()
                } else {
                    isProcessing = false
                }
            } catch {
                errorMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
                showingError = true
                isProcessing = false
            }
        }
    }
}

// MARK: - Export/Import Types

enum ExportImportType {
    case export
    case import
    
    var title: String {
        switch self {
        case .export: return "Settings exportieren"
        case .import: return "Settings importieren"
        }
    }
    
    var description: String {
        switch self {
        case .export: 
            return "Exportiert Ihre Einstellungen in eine JSON-Datei. Sensitive Daten werden automatisch ausgeblendet."
        case .import:
            return "Importiert Einstellungen aus einer JSON-Datei. Aktuelle Einstellungen werden überschrieben."
        }
    }
    
    var processingText: String {
        switch self {
        case .export: return "Exportiere Einstellungen..."
        case .import: return "Importiere Einstellungen..."
        }
    }
}

// MARK: - Additional Button Styles

struct ImportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
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