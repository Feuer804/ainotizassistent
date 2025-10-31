//
//  APIKeyManager.swift
//  AINotizassistent
//
//  Ein sicheres API-Key Management System für verschiedene KI-APIs
//

import Foundation
import Security
import CryptoKit
import Network

// MARK: - API Provider Types

enum APIProvider: String, CaseIterable {
    case openai = "openai"
    case openrouter = "openrouter"
    case notion = "notion"
    case whisper = "whisper"
    
    var displayName: String {
        switch self {
        case .openai:
            return "OpenAI"
        case .openrouter:
            return "OpenRouter"
        case .notion:
            return "Notion"
        case .whisper:
            return "Whisper"
        }
    }
    
    var validationEndpoint: String {
        switch self {
        case .openai:
            return "https://api.openai.com/v1/models"
        case .openrouter:
            return "https://openrouter.ai/api/v1/models"
        case .notion:
            return "https://api.notion.com/v1/me"
        case .whisper:
            return "https://api.openai.com/v1/models"
        }
    }
    
    var requiresAuth: Bool {
        return true
    }
}

// MARK: - API Key Status

enum APIKeyStatus: String, Codable {
    case valid = "valid"
    case invalid = "invalid"
    case expired = "expired"
    case disabled = "disabled"
    case pending = "pending"
    case compromised = "compromised"
    
    var displayName: String {
        switch self {
        case .valid:
            return "Gültig"
        case .invalid:
            return "Ungültig"
        case .expired:
            return "Abgelaufen"
        case .disabled:
            return "Deaktiviert"
        case .pending:
            return "Wird geprüft"
        case .compromised:
            return "Kompromittiert"
        }
    }
    
    var color: String {
        switch self {
        case .valid:
            return "green"
        case .invalid, .expired, .compromised:
            return "red"
        case .disabled:
            return "gray"
        case .pending:
            return "yellow"
        }
    }
}

// MARK: - API Key Model

struct APIKey: Codable, Identifiable {
    let id = UUID()
    let provider: APIProvider
    var keyValue: String
    var status: APIKeyStatus
    var createdAt: Date
    var lastValidatedAt: Date?
    var expiresAt: Date?
    var isPrimary: Bool
    var usageCount: Int
    var monthlyQuota: Int?
    var lastUsed: Date?
    var displayName: String
    var notes: String?
    var isEmergencyDisabled: Bool = false
    
    // API-Statistiken
    var dailyUsage: [String: Int] = [:]
    var monthlyUsage: Int = 0
    
    init(provider: APIProvider, keyValue: String, displayName: String = "") {
        self.provider = provider
        self.keyValue = keyValue
        self.status = .pending
        self.createdAt = Date()
        self.lastValidatedAt = nil
        self.isPrimary = false
        self.usageCount = 0
        self.displayName = displayName.isEmpty ? "\(provider.displayName) API Key" : displayName
        self.notes = nil
    }
}

// MARK: - Usage Tracking

struct APIUsageData: Codable {
    let provider: APIProvider
    let date: Date
    let requestsCount: Int
    let tokensUsed: Int
    let costEstimate: Double
    let responseTime: Double
}

// MARK: - Provider Status

struct ProviderStatus: Codable {
    let provider: APIProvider
    let isOnline: Bool
    let lastCheck: Date
    let responseTime: Double?
    let errorMessage: String?
    let uptime: Double
    let maintenanceMode: Bool
}

// MARK: - Security Alert

struct SecurityAlert: Codable, Identifiable {
    let id = UUID()
    let type: SecurityAlertType
    let provider: APIProvider
    let message: String
    let severity: AlertSeverity
    let createdAt: Date
    let isRead: Bool
    let actionRequired: Bool
}

enum SecurityAlertType: String, Codable {
    case keyCompromised = "key_compromised"
    case suspiciousActivity = "suspicious_activity"
    case quotaExceeded = "quota_exceeded"
    case keyExpired = "key_expired"
    case providerDown = "provider_down"
    case securityBreach = "security_breach"
}

enum AlertSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Main API Key Manager

class APIKeyManager: ObservableObject {
    @Published var apiKeys: [APIKey] = []
    @Published var providerStatuses: [APIProvider: ProviderStatus] = [:]
    @Published var securityAlerts: [SecurityAlert] = []
    @Published var isLoading = false
    @Published var lastSync: Date?
    
    private let keychain = KeychainManager()
    private let networkMonitor = NWPathMonitor()
    private let validationQueue = DispatchQueue(label: "api.validation", qos: .utility)
    private let monitoringQueue = DispatchQueue(label: "api.monitoring", qos: .background)
    
    // Encryption key für Keychain
    private var encryptionKey: SymmetricKey?
    
    // Notifications
    let notificationCenter = NotificationCenter.default
    
    // Singleton
    static let shared = APIKeyManager()
    
    private init() {
        setupEncryption()
        setupNetworkMonitoring()
        loadAPIKeys()
        startPeriodicValidation()
    }
    
    // MARK: - Setup and Initialization
    
    private func setupEncryption() {
        // Versuche existierenden Encryption Key zu laden, sonst erstelle neuen
        if let existingKeyData = try? keychain.get(key: "encryption_key") {
            encryptionKey = SymmetricKey(data: existingKeyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            encryptionKey = newKey
            if let keyData = try? newKey.withUnsafeBytes({ Data($0) }) {
                try? keychain.set(keyData, for: "encryption_key")
            }
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.checkAllProviderStatuses()
            }
        }
        networkMonitor.start(queue: monitoringQueue)
    }
    
    // MARK: - Key Management
    
    func addAPIKey(_ key: APIKey) {
        let encryptedKey = encryptKey(key.keyValue)
        
        var newKey = key
        newKey.keyValue = encryptedKey
        
        // Speichere in Keychain
        if let keyData = encryptedKey.data(using: .utf8) {
            try? keychain.set(keyData, for: "\(key.provider.rawValue)_\(key.id)")
        }
        
        apiKeys.append(newKey)
        saveAPIKeys()
        
        // Validiere den neuen Key
        validationQueue.async { [weak self] in
            self?.validateAPIKey(&newKey)
            DispatchQueue.main.async {
                self?.updateAPIKey(newKey)
            }
        }
        
        notificationCenter.post(name: .apiKeyAdded, object: key)
    }
    
    func removeAPIKey(_ key: APIKey) {
        // Entferne aus Keychain
        try? keychain.delete(key: "\(key.provider.rawValue)_\(key.id)")
        
        // Entferne aus Liste
        apiKeys.removeAll { $0.id == key.id }
        saveAPIKeys()
        
        notificationCenter.post(name: .apiKeyRemoved, object: key)
    }
    
    func updateAPIKey(_ updatedKey: APIKey) {
        if let index = apiKeys.firstIndex(where: { $0.id == updatedKey.id }) {
            let encryptedKey = encryptKey(updatedKey.keyValue)
            
            var key = updatedKey
            key.keyValue = encryptedKey
            
            // Update in Keychain
            if let keyData = encryptedKey.data(using: .utf8) {
                try? keychain.set(keyData, for: "\(key.provider.rawValue)_\(key.id)")
            }
            
            apiKeys[index] = key
            saveAPIKeys()
            
            notificationCenter.post(name: .apiKeyUpdated, object: key)
        }
    }
    
    func getDecryptedKey(for provider: APIProvider) -> String? {
        guard let key = apiKeys.first(where: { $0.provider == provider && $0.status == .valid && !$0.isEmergencyDisabled }) else {
            return nil
        }
        
        return decryptKey(key.keyValue)
    }
    
    func getAllKeys(for provider: APIProvider) -> [APIKey] {
        return apiKeys.filter { $0.provider == provider }
    }
    
    // MARK: - Key Validation
    
    func validateAPIKey(_ key: inout APIKey) {
        key.status = .pending
        updateAPIKey(key)
        
        guard let url = URL(string: key.provider.validationEndpoint) else {
            key.status = .invalid
            updateAPIKey(key)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(decryptKey(key.keyValue))", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if key.provider == .notion {
            request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    key.status = .invalid
                    self?.createSecurityAlert(for: key.provider, type: .keyCompromised, message: "Validation failed: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        key.status = .valid
                        key.lastValidatedAt = Date()
                    case 401, 403:
                        key.status = .invalid
                    case 429:
                        key.status = .expired // Quota exceeded
                    default:
                        key.status = .invalid
                    }
                } else {
                    key.status = .invalid
                }
                
                self?.updateAPIKey(key)
            }
        }
        
        task.resume()
    }
    
    func validateAllKeys() {
        for i in 0..<apiKeys.count {
            var key = apiKeys[i]
            validationQueue.async { [weak self] in
                self?.validateAPIKey(&key)
                DispatchQueue.main.async {
                    self?.apiKeys[i] = key
                }
            }
        }
    }
    
    // MARK: - Usage Tracking
    
    func trackUsage(for provider: APIProvider, tokensUsed: Int = 0, cost: Double = 0.0) {
        guard let index = apiKeys.firstIndex(where: { $0.provider == provider && $0.isPrimary }) else { return }
        
        var key = apiKeys[index]
        key.usageCount += 1
        key.lastUsed = Date()
        key.monthlyUsage += tokensUsed
        
        // Tägliche Usage tracken
        let today = DateFormatter.dateOnly.string(from: Date())
        key.dailyUsage[today, default: 0] += 1
        
        apiKeys[index] = key
        saveAPIKeys()
        
        // Check quotas
        if let quota = key.monthlyQuota, key.monthlyUsage >= quota {
            createSecurityAlert(for: provider, type: .quotaExceeded, message: "Monats-Quote erreicht: \(key.monthlyUsage)/\(quota)")
        }
    }
    
    func getUsageStats(for provider: APIProvider) -> APIUsageData? {
        let keys = apiKeys.filter { $0.provider == provider && $0.isPrimary }
        guard let key = keys.first else { return nil }
        
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start
        
        let monthlyRequests = key.dailyUsage.values.reduce(0, +)
        let averageCost = Double(monthlyRequests) * 0.001 // Beispiel-Kalkulation
        
        return APIUsageData(
            provider: provider,
            date: today,
            requestsCount: monthlyRequests,
            tokensUsed: key.monthlyUsage,
            costEstimate: averageCost,
            responseTime: 0.0 // Would be tracked separately
        )
    }
    
    // MARK: - Provider Status Monitoring
    
    func checkProviderStatus(_ provider: APIProvider) {
        let status = ProviderStatus(
            provider: provider,
            isOnline: false,
            lastCheck: Date(),
            responseTime: nil,
            errorMessage: nil,
            uptime: 0.0,
            maintenanceMode: false
        )
        
        guard let url = URL(string: provider.validationEndpoint) else {
            providerStatuses[provider] = status
            return
        }
        
        let startTime = Date()
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            let responseTime = Date().timeIntervalSince(startTime) * 1000
            
            var updatedStatus = status
            updatedStatus.responseTime = responseTime
            updatedStatus.lastCheck = Date()
            
            if let error = error {
                updatedStatus.errorMessage = error.localizedDescription
                updatedStatus.isOnline = false
            } else if let httpResponse = response as? HTTPURLResponse {
                updatedStatus.isOnline = httpResponse.statusCode < 500
                
                if httpResponse.statusCode >= 500 {
                    updatedStatus.errorMessage = "Server Error: \(httpResponse.statusCode)"
                    self?.createSecurityAlert(for: provider, type: .providerDown, message: "Provider \(provider.displayName) ist nicht erreichbar")
                }
            }
            
            self?.providerStatuses[provider] = updatedStatus
        }
        
        task.resume()
    }
    
    func checkAllProviderStatuses() {
        for provider in APIProvider.allCases {
            checkProviderStatus(provider)
        }
    }
    
    // MARK: - Emergency Functions
    
    func emergencyDisableAllKeys(for provider: APIProvider? = nil) {
        let keysToDisable: [APIKey]
        if let provider = provider {
            keysToDisable = apiKeys.filter { $0.provider == provider }
        } else {
            keysToDisable = apiKeys
        }
        
        for key in keysToDisable {
            var updatedKey = key
            updatedKey.isEmergencyDisabled = true
            updatedKey.status = .disabled
            updateAPIKey(updatedKey)
        }
        
        createSecurityAlert(
            for: provider ?? .openai,
            type: .securityBreach,
            message: "Alle API Keys für \(provider?.displayName ?? "alle Provider") wurden notfallmäßig deaktiviert"
        )
    }
    
    func reenableKey(_ key: APIKey) {
        var updatedKey = key
        updatedKey.isEmergencyDisabled = false
        updateAPIKey(updatedKey)
        
        // Revalidate
        validationQueue.async { [weak self] in
            self?.validateAPIKey(&updatedKey)
        }
    }
    
    func revokeKey(_ key: APIKey) {
        removeAPIKey(key)
        createSecurityAlert(for: key.provider, type: .keyCompromised, message: "API Key für \(key.provider.displayName) wurde widerrufen")
    }
    
    // MARK: - Security Features
    
    func createSecurityAlert(for provider: APIProvider, type: SecurityAlertType, message: String, severity: AlertSeverity = .medium) {
        let alert = SecurityAlert(
            type: type,
            provider: provider,
            message: message,
            severity: severity,
            createdAt: Date(),
            isRead: false,
            actionRequired: severity == .high || severity == .critical
        )
        
        securityAlerts.insert(alert, at: 0)
        
        // Send notification
        notificationCenter.post(name: .securityAlert, object: alert)
    }
    
    func markAlertAsRead(_ alert: SecurityAlert) {
        if let index = securityAlerts.firstIndex(where: { $0.id == alert.id }) {
            securityAlerts[index].isRead = true
        }
    }
    
    func clearAllAlerts() {
        securityAlerts.removeAll()
    }
    
    // MARK: - Import/Export
    
    func exportKeys() -> String? {
        let exportData = APIKeysExport(
            version: "1.0",
            exportedAt: Date(),
            keys: apiKeys.map { key in
                ExportedAPIKey(
                    provider: key.provider.rawValue,
                    encryptedKey: key.keyValue,
                    displayName: key.displayName,
                    notes: key.notes,
                    isPrimary: key.isPrimary
                )
            }
        )
        
        let jsonData = try? JSONEncoder().encode(exportData)
        return jsonData?.base64EncodedString()
    }
    
    func importKeys(from exportString: String) -> Bool {
        guard let jsonData = Data(base64Encoded: exportString),
              let exportData = try? JSONDecoder().decode(APIKeysExport.self, from: jsonData) else {
            return false
        }
        
        for exportedKey in exportData.keys {
            guard let provider = APIProvider(rawValue: exportedKey.provider) else { continue }
            
            let key = APIKey(provider: provider, keyValue: exportedKey.encryptedKey)
            key.displayName = exportedKey.displayName
            key.notes = exportedKey.notes
            key.isPrimary = exportedKey.isPrimary
            
            addAPIKey(key)
        }
        
        return true
    }
    
    func backupToFile() -> URL? {
        guard let exportString = exportKeys() else { return nil }
        
        let backupData = exportString.data(using: .utf8)!
        let fileName = "api_keys_backup_\(DateFormatter.iso8601.string(from: Date())).json"
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsPath.appendingPathComponent(fileName)
        
        try? backupData.write(to: backupURL)
        return backupURL
    }
    
    func restoreFromFile(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let exportString = String(data: data, encoding: .utf8) else {
            return false
        }
        
        return importKeys(from: exportString)
    }
    
    // MARK: - Key Rotation
    
    func rotateKey(for provider: APIProvider, newKey: String) -> Bool {
        guard let oldKey = apiKeys.first(where: { $0.provider == provider && $0.isPrimary }) else {
            return false
        }
        
        // Deaktiviere alten Key temporär
        var disabledKey = oldKey
        disabledKey.isEmergencyDisabled = true
        updateAPIKey(disabledKey)
        
        // Füge neuen Key hinzu
        var newAPIKey = APIKey(provider: provider, keyValue: newKey)
        newAPIKey.isPrimary = true
        addAPIKey(newAPIKey)
        
        // Validiere neuen Key
        validationQueue.async { [weak self] in
            self?.validateAPIKey(&newAPIKey)
            
            if newAPIKey.status == .valid {
                // Entferne alten Key
                self?.removeAPIKey(oldKey)
                
                // Re-encrypt alle Keys mit neuem Encryption Key
                self?.reencryptAllKeys()
            } else {
                // Reaktiviere alten Key
                self?.reenableKey(oldKey)
            }
        }
        
        return true
    }
    
    func reencryptAllKeys() {
        guard let oldEncryptionKey = encryptionKey else { return }
        
        // Generiere neuen Encryption Key
        let newKey = SymmetricKey(size: .bits256)
        encryptionKey = newKey
        
        // Update Encryption Key in Keychain
        if let keyData = try? newKey.withUnsafeBytes({ Data($0) }) {
            try? keychain.set(keyData, for: "encryption_key")
        }
        
        // Re-encrypt alle API Keys
        for i in 0..<apiKeys.count {
            var key = apiKeys[i]
            let decryptedValue = decryptKey(key.keyValue, with: oldEncryptionKey)
            key.keyValue = encryptKey(decryptedValue, with: newKey)
            apiKeys[i] = key
            
            // Update in Keychain
            if let keyData = key.keyValue.data(using: .utf8) {
                try? keychain.set(keyData, for: "\(key.provider.rawValue)_\(key.id)")
            }
        }
    }
    
    // MARK: - macOS Credential Management
    
    func syncWithKeychain() {
        // Sync mit macOS Credential Manager
        for provider in APIProvider.allCases {
            let credentialKey = "api_key_\(provider.rawValue)"
            
            // Query macOS Keychain
            if let keychainKey = try? keychain.get(key: credentialKey) as String? {
                if let existingKey = keychainKey {
                    if !apiKeys.contains(where: { $0.provider == provider && decryptKey($0.keyValue) == existingKey }) {
                        // Neuen Key hinzufügen
                        var newKey = APIKey(provider: provider, keyValue: encryptKey(existingKey))
                        addAPIKey(newKey)
                    }
                }
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadAPIKeys() {
        // Load from UserDefaults
        if let savedKeysData = UserDefaults.standard.data(forKey: "api_keys"),
           let savedKeys = try? JSONDecoder().decode([APIKey].self, from: savedKeysData) {
            apiKeys = savedKeys
            lastSync = Date()
        }
    }
    
    private func saveAPIKeys() {
        if let encoded = try? JSONEncoder().encode(apiKeys) {
            UserDefaults.standard.set(encoded, forKey: "api_keys")
            lastSync = Date()
        }
    }
    
    // MARK: - Encryption/Decryption
    
    private func encryptKey(_ key: String, with encryptionKey: SymmetricKey? = nil) -> String {
        let keyToUse = encryptionKey ?? self.encryptionKey!
        let data = key.data(using: .utf8)!
        
        let sealedBox = try? AES.GCM.seal(data, using: keyToUse)
        return sealedBox?.combined!.base64EncodedString() ?? key
    }
    
    private func decryptKey(_ encryptedKey: String, with encryptionKey: SymmetricKey? = nil) -> String {
        let keyToUse = encryptionKey ?? self.encryptionKey!
        
        guard let encryptedData = Data(base64Encoded: encryptedKey),
              let sealedBox = try? AES.GCM.SealedBox(combined: encryptedData),
              let decryptedData = try? AES.GCM.open(sealedBox, using: keyToUse) else {
            return encryptedKey
        }
        
        return String(data: decryptedData, encoding: .utf8) ?? encryptedKey
    }
    
    // MARK: - Periodic Tasks
    
    private func startPeriodicValidation() {
        // Validiere Keys alle 30 Minuten
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.validateAllKeys()
        }
        
        // Check Provider Status alle 5 Minuten
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.checkAllProviderStatuses()
        }
    }
}

// MARK: - Supporting Types

struct APIKeysExport: Codable {
    let version: String
    let exportedAt: Date
    let keys: [ExportedAPIKey]
}

struct ExportedAPIKey: Codable {
    let provider: String
    let encryptedKey: String
    let displayName: String
    let notes: String?
    let isPrimary: Bool
}

// MARK: - Notification Names

extension Notification.Name {
    static let apiKeyAdded = Notification.Name("APIKeyAdded")
    static let apiKeyRemoved = Notification.Name("APIKeyRemoved")
    static let apiKeyUpdated = Notification.Name("APIKeyUpdated")
    static let securityAlert = Notification.Name("SecurityAlert")
    static let providerStatusChanged = Notification.Name("ProviderStatusChanged")
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        return formatter
    }()
    
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}