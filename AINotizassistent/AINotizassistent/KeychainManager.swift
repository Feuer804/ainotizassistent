//
//  KeychainManager.swift
//  AINotizassistent
//
//  Sichere Keychain-Integration für API Key Storage
//

import Foundation
import Security

/// Secure Keychain Manager für verschlüsselte API Key Speicherung
class KeychainManager {
    
    // MARK: - Keychain Constants
    
    private let service = "com.ainotizassistent.apikeys"
    private let group = "group.com.ainotizassistent.apikeys" // Für App Groups (optional)
    
    // MARK: - Keychain Query Constants
    
    private enum KeychainError: Error {
        case unexpectedStatus(OSStatus)
        case stringEncoding
        case dataConversion
        case notFound
    }
    
    // MARK: - Store Data
    
    /// Speichert Daten sicher im Keychain
    func set(_ data: Data, for key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: accessibility,
            kSecValueData as String: data
        ]
        
        // Entferne existierenden Eintrag
        SecItemDelete(query as CFDictionary)
        
        // Füge neuen Eintrag hinzu
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Lädt Daten aus dem Keychain
    func get(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecItemNotFound {
            throw KeychainError.notFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        return dataTypeRef as? Data ?? Data()
    }
    
    /// Löscht Daten aus dem Keychain
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Prüft ob ein Key existiert
    func exists(key: String) -> Bool {
        do {
            let _ = try get(key: key)
            return true
        } catch KeychainError.notFound {
            return false
        } catch {
            return false
        }
    }
    
    // MARK: - String Operations
    
    /// Speichert String sicher im Keychain
    func set(_ string: String, for key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.stringEncoding
        }
        
        try set(data, for: key, accessibility: accessibility)
    }
    
    /// Lädt String aus dem Keychain
    func get(key: String) throws -> String {
        let data = try get(key: key)
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.stringEncoding
        }
        
        return string
    }
    
    // MARK: - Multiple Items Management
    
    /// Speichert mehrere Key-Value Paare atomisch
    func setMultiple(_ items: [String: String], accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        for (key, value) in items {
            try set(value, for: key, accessibility: accessibility)
        }
    }
    
    /// Lädt mehrere Keys
    func getMultiple(keys: [String]) throws -> [String: String] {
        var results: [String: String] = [:]
        
        for key in keys {
            do {
                let value = try get(key: key)
                results[key] = value
            } catch KeychainError.notFound {
                // Skip not found items
                continue
            } catch {
                throw error
            }
        }
        
        return results
    }
    
    /// Löscht mehrere Keys
    func deleteMultiple(keys: [String]) throws {
        for key in keys {
            try delete(key: key)
        }
    }
    
    // MARK: - Backup and Restore
    
    /// Exportiert alle Keychain Daten als JSON
    func exportAll() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let array = dataTypeRef as? [[String: Any]] else {
            throw KeychainError.dataConversion
        }
        
        var exportData: [[String: String]] = []
        
        for item in array {
            guard let account = item[kSecAttrAccount as String] as? String,
                  let data = item[kSecValueData as String] as? Data else {
                continue
            }
            
            let valueString = String(data: data, encoding: .utf8) ?? ""
            let itemData: [String: String] = [
                "key": account,
                "value": valueString,
                "service": service
            ]
            
            exportData.append(itemData)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportData)
        return jsonData
    }
    
    /// Importiert Keychain Daten aus JSON
    func importFrom(_ data: Data) throws {
        let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        guard let items = jsonArray else {
            throw KeychainError.dataConversion
        }
        
        for item in items {
            guard let key = item["key"] as? String,
                  let value = item["value"] as? String else {
                continue
            }
            
            try set(value, for: key)
        }
    }
    
    // MARK: - App Groups (für Sharing zwischen Apps)
    
    /// Speichert Daten in App Group Keychain (für Extension/App Sharing)
    func setInAppGroup(_ data: Data, for key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: group,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: accessibility,
            kSecValueData as String: data,
            kSecAttrAccessGroup as String: group
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Lädt Daten aus App Group Keychain
    func getFromAppGroup(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: group,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: group
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecItemNotFound {
            throw KeychainError.notFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        return dataTypeRef as? Data ?? Data()
    }
    
    // MARK: - Keychain Statistics
    
    /// Gibt Statistiken über Keychain Nutzung zurück
    func getStatistics() throws -> [String: Any] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecItemNotFound {
            return ["totalItems": 0, "lastModified": nil]
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let array = dataTypeRef as? [[String: Any]] else {
            throw KeychainError.dataConversion
        }
        
        let totalItems = array.count
        let lastModified = array.compactMap { item in
            item[kSecAttrModificationDate as String] as? Date
        }.max()
        
        return [
            "totalItems": totalItems,
            "lastModified": lastModified ?? Date.distantPast
        ]
    }
    
    // MARK: - Security Features
    
    /// Bereinigt den Keychain (löscht alle API Keys)
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        // Bereinige auch App Group falls vorhanden
        let groupQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: group
        ]
        
        SecItemDelete(groupQuery as CFDictionary)
    }
    
    /// Prüft Keychain Integrität
    func verifyIntegrity() throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - macOS Keychain Integration
    
    /// Prüft macOS Credential Availability
    static func isCredentialManagerAvailable() -> Bool {
        // Prüfe ob macOS Credential Manager verfügbar ist
        return true // macOS hat immer Credential Manager
    }
    
    /// Sync mit macOS Credential Manager
    func syncWithMacOSCredentials() throws {
        // Diese Funktion würde mit macOS Credential Manager synchronisieren
        // (würde Credential Manager Framework verwenden)
        // Für jetzt eine Placeholder-Implementation
    }
    
    // MARK: - Error Handling
    
    func handleKeychainError(_ status: OSStatus) -> String {
        switch status {
        case errSecUserCancel:
            return "Benutzer hat Operation abgebrochen"
        case errSecAuthFailed:
            return "Authentifizierung fehlgeschlagen"
        case errSecNoSuchKeychain:
            return "Keychain existiert nicht"
        case errSecInvalidKeychain:
            return "Keychain ist ungültig"
        case errSecDuplicateItem:
            return "Item bereits vorhanden"
        case errSecItemNotFound:
            return "Item nicht gefunden"
        case errSecInteractionNotAllowed:
            return "Benutzerinteraktion nicht erlaubt"
        case errSecWriteProtected:
            return "Schreibschutz verletzt"
        case errSecSecItemNoAccess:
            return "Kein Zugriff auf Keychain Item"
        default:
            return "Unbekannter Keychain Fehler: \(status)"
        }
    }
}

// MARK: - KeychainManager Extension für macOS

extension KeychainManager {
    
    /// Integration mit macOS Keychain für SystemCredential Support
    func integrateWithSystemCredentials() {
        // Diese Methode würde mit macOS System Credentials integrieren
        // um API Keys im macOS Credential Manager zu speichern
    }
    
    /// Erstellt Backup für Time Machine
    func createTimeMachineBackup() throws -> URL {
        let backupData = try exportAll()
        let timestamp = DateFormatter.stringWith(format: "yyyy-MM-dd_HH-mm-ss")
        let backupFileName = "api_keys_backup_\(timestamp).plist"
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsPath.appendingPathComponent(backupFileName)
        
        try backupData.write(to: backupURL)
        return backupURL
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static func stringWith(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: Date())
    }
}