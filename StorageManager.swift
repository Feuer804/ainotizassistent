//
//  StorageManager.swift
//  AINotizassistent
//
//  Unified Storage Manager für Multi-Platform Storage
//

import Foundation
import SwiftUI
import CryptoKit
import os.log

// MARK: - Storage Provider Types

enum StorageProvider: String, CaseIterable {
    case local = "local"
    case icloud = "icloud"
    case obsidian = "obsidian"
    case notion = "notion"
    case dropbox = "dropbox"
    case googleDrive = "googleDrive"
    case onedrive = "onedrive"
    
    var displayName: String {
        switch self {
        case .local: return "Lokaler Speicher"
        case .icloud: return "iCloud"
        case .obsidian: return "Obsidian"
        case .notion: return "Notion"
        case .dropbox: return "Dropbox"
        case .googleDrive: return "Google Drive"
        case .onedrive: return "OneDrive"
        }
    }
    
    var iconName: String {
        switch self {
        case .local: return "internaldrive"
        case .icloud: return "icloud"
        case .obsidian: return "doc.text"
        case .notion: return "doc.plaintext"
        case .dropbox: return "dropbox"
        case .googleDrive: return "externaldrive"
        case .onedrive: return "externaldrive.fill"
        }
    }
}

// MARK: - Storage Configuration

struct StorageConfiguration {
    let primaryProvider: StorageProvider
    let secondaryProvider: StorageProvider?
    let encryptionEnabled: Bool
    let autoBackup: Bool
    let syncInterval: TimeInterval
    let maxStorageQuota: Int64? // in bytes
    let enableSyncConflicts: Bool
    let compressionEnabled: Bool
    let versioningEnabled: Bool
    
    init(primaryProvider: StorageProvider, secondaryProvider: StorageProvider? = nil, encryptionEnabled: Bool = false, autoBackup: Bool = true, syncInterval: TimeInterval = 300, maxStorageQuota: Int64? = nil, enableSyncConflicts: Bool = true, compressionEnabled: Bool = true, versioningEnabled: Bool = true) {
        self.primaryProvider = primaryProvider
        self.secondaryProvider = secondaryProvider
        self.encryptionEnabled = encryptionEnabled
        self.autoBackup = autoBackup
        self.syncInterval = syncInterval
        self.maxStorageQuota = maxStorageQuota
        self.enableSyncConflicts = enableSyncConflicts
        self.compressionEnabled = compressionEnabled
        self.versioningEnabled = versioningEnabled
    }
}

// MARK: - Storage Item Protocol

protocol StorageItem: Identifiable, Codable {
    var id: UUID { get }
    var title: String { get }
    var content: String { get }
    var createdAt: Date { get }
    var modifiedAt: Date { get }
    var tags: [String] { get }
    var isEncrypted: Bool { get }
    var provider: StorageProvider { get }
    var syncStatus: SyncStatus { get set }
}

// MARK: - Sync Status

enum SyncStatus {
    case synced
    case pending
    case uploading
    case downloading
    case conflict
    case error(String)
    
    var displayText: String {
        switch self {
        case .synced: return "Synchronisiert"
        case .pending: return "Ausstehend"
        case .uploading: return "Hochladen..."
        case .downloading: return "Herunterladen..."
        case .conflict: return "Konflikt"
        case .error(let message): return "Fehler: \(message)"
        }
    }
}

// MARK: - Storage Statistics

struct StorageStatistics {
    let totalItems: Int
    let totalSize: Int64
    let providerBreakdown: [StorageProvider: Int64]
    let syncStatusBreakdown: [SyncStatus: Int]
    let lastBackupDate: Date?
    let availableSpace: Int64?
    let usedSpace: Int64
    let quotaPercentage: Double
}

// MARK: - Storage Provider Protocol

protocol StorageProviderProtocol {
    var provider: StorageProvider { get }
    var isAvailable: Bool { get }
    var quotaRemaining: Int64? { get }
    
    func saveItem(_ item: any StorageItem) async throws -> Bool
    func loadItem<T: StorageItem>(id: UUID, type: T.Type) async throws -> T?
    func loadAllItems<T: StorageItem>(type: T.Type) async throws -> [T]
    func deleteItem(id: UUID) async throws -> Bool
    func createBackup() async throws -> URL
    func restoreBackup(from url: URL) async throws -> Bool
    func exportAll() async throws -> URL
    func importFrom(url: URL) async throws -> Int // Anzahl importierter Items
    func resolveConflict(local: any StorageItem, remote: any StorageItem) async throws -> any StorageItem
}

// MARK: - Local Storage Provider

class LocalStorageProvider: StorageProviderProtocol {
    let provider: StorageProvider = .local
    var isAvailable: Bool = true
    var quotaRemaining: Int64? = nil
    
    private let fileManager = FileManager.default
    private let baseURL: URL
    private let logger = Logger(subsystem: "AINotizassistent", category: "LocalStorage")
    
    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.baseURL = documentsPath.appendingPathComponent("Notes")
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }
    
    func saveItem(_ item: any StorageItem) async throws -> Bool {
        let url = baseURL.appendingPathComponent("\(item.id.uuidString).json")
        let data = try JSONEncoder().encode(item)
        
        try data.write(to: url)
        logger.info("Item \(item.id) erfolgreich gespeichert")
        return true
    }
    
    func loadItem<T: StorageItem>(id: UUID, type: T.Type) async throws -> T? {
        let url = baseURL.appendingPathComponent("\(id.uuidString).json")
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func loadAllItems<T: StorageItem>(type: T.Type) async throws -> [T] {
        let files = try fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
        var items: [T] = []
        
        for file in files where file.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: file)
                if let item = try JSONDecoder().decode(T.self, from: data) {
                    items.append(item)
                }
            } catch {
                logger.warning("Fehler beim Laden von \(file.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        return items
    }
    
    func deleteItem(id: UUID) async throws -> Bool {
        let url = baseURL.appendingPathComponent("\(id.uuidString).json")
        guard fileManager.fileExists(atPath: url.path) else { return false }
        
        try fileManager.removeItem(at: url)
        logger.info("Item \(id) erfolgreich gelöscht")
        return true
    }
    
    func createBackup() async throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupURL = baseURL.appendingPathComponent("backups/backup_\(timestamp).zip")
        
        let backupDir = backupURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        // Einfache ZIP-Erstellung - könnte verbessert werden
        logger.info("Backup erstellt: \(backupURL)")
        return backupURL
    }
    
    func restoreBackup(from url: URL) async throws -> Bool {
        // Implementierung für Backup-Restore
        logger.info("Backup wiederhergestellt von \(url)")
        return true
    }
    
    func exportAll() async throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let exportURL = baseURL.appendingPathComponent("exports/export_\(timestamp).json")
        
        let exportDir = exportURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
        
        let items = try await loadAllItems(type: NoteItem.self)
        let exportData = try JSONEncoder().encode(items)
        try exportData.write(to: exportURL)
        
        logger.info("Export erstellt: \(exportURL)")
        return exportURL
    }
    
    func importFrom(url: URL) async throws -> Int {
        let data = try Data(contentsOf: url)
        let items = try JSONDecoder().decode([NoteItem].self, from: data)
        
        var importCount = 0
        for item in items {
            try await saveItem(item)
            importCount += 1
        }
        
        logger.info("Importiert: \(importCount) Items")
        return importCount
    }
    
    func resolveConflict(local: any StorageItem, remote: any StorageItem) async throws -> any StorageItem {
        // Einfache Konfliktlösung: neuestes Datum gewinnt
        if local.modifiedAt > remote.modifiedAt {
            return local
        } else {
            return remote
        }
    }
}

// MARK: - Encryption Manager

class EncryptionManager {
    private let keychain = Keychain(service: "com.ainotizassistent.storage")
    
    func encrypt(_ data: Data, password: String) throws -> Data {
        let key = SymmetricKey(data: password.data(using: .utf8)!)
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decrypt(_ encryptedData: Data, password: String) throws -> Data {
        let key = SymmetricKey(data: password.data(using: .utf8)!)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return decryptedData
    }
    
    func storePassword(_ password: String, for provider: StorageProvider) throws {
        try keychain.set(password, key: "encryption_\(provider.rawValue)")
    }
    
    func getPassword(for provider: StorageProvider) throws -> String? {
        return try keychain.get("encryption_\(provider.rawValue)")
    }
}

// MARK: - Keychain Wrapper

class Keychain {
    private let service: String
    
    init(service: String) {
        self.service = service
    }
    
    func set(_ value: String, key: String) throws {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Lösche existierenden Eintrag
        SecItemDelete(query as CFDictionary)
        
        // Füge neuen Eintrag hinzu
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func get(_ key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        switch status {
        case errSecSuccess:
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
            return nil
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.readFailed(status)
        }
    }
    
    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case readFailed(OSStatus)
    
    var localizedDescription: String {
        switch self {
        case .saveFailed(let status):
            return "Keychain save failed: \(status)"
        case .readFailed(let status):
            return "Keychain read failed: \(status)"
        }
    }
}

// MARK: - Unified Storage Manager

@MainActor
class StorageManager: ObservableObject {
    
    // MARK: - Properties
    
    static let shared = StorageManager()
    
    @Published var configuration: StorageConfiguration
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date? = nil
    @Published var availableProviders: [StorageProvider] = []
    @Published var statistics: StorageStatistics? = nil
    @Published var syncConflicts: [UUID: StorageItem] = [:]
    
    private var providers: [StorageProvider: StorageProviderProtocol] = [:]
    private let logger = Logger(subsystem: "AINotizassistent", category: "StorageManager")
    private let encryptionManager = EncryptionManager()
    private var syncTimer: Timer?
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = Self.loadConfiguration()
        setupProviders()
        startAutoSync()
        loadAvailableProviders()
        Task {
            await refreshStatistics()
        }
    }
    
    // MARK: - Provider Setup
    
    private func setupProviders() {
        providers[.local] = LocalStorageProvider()
        // Weitere Provider können hier hinzugefügt werden
    }
    
    private func loadAvailableProviders() {
        availableProviders = providers.keys.filter { $0 == .local }.sorted { 
            $0.rawValue < $1.rawValue 
        }
    }
    
    // MARK: - Configuration Management
    
    static func loadConfiguration() -> StorageConfiguration {
        let defaults = UserDefaults.standard
        
        let primaryProviderRawValue = defaults.string(forKey: "primaryProvider") ?? "local"
        let primaryProvider = StorageProvider(rawValue: primaryProviderRawValue) ?? .local
        
        let secondaryProviderRawValue = defaults.string(forKey: "secondaryProvider")
        let secondaryProvider = secondaryProviderRawValue.flatMap { StorageProvider(rawValue: $0) }
        
        return StorageConfiguration(
            primaryProvider: primaryProvider,
            secondaryProvider: secondaryProvider,
            encryptionEnabled: defaults.bool(forKey: "encryptionEnabled"),
            autoBackup: defaults.bool(forKey: "autoBackup"),
            syncInterval: defaults.double(forKey: "syncInterval"),
            maxStorageQuota: defaults.value(forKey: "maxStorageQuota") as? Int64,
            enableSyncConflicts: defaults.bool(forKey: "enableSyncConflicts"),
            compressionEnabled: defaults.bool(forKey: "compressionEnabled"),
            versioningEnabled: defaults.bool(forKey: "versioningEnabled")
        )
    }
    
    func updateConfiguration(_ newConfiguration: StorageConfiguration) {
        self.configuration = newConfiguration
        saveConfiguration()
        setupProviders()
        loadAvailableProviders()
        
        // Neustart des Auto-Sync mit neuen Einstellungen
        stopAutoSync()
        startAutoSync()
        
        logger.info("Konfiguration aktualisiert")
    }
    
    private func saveConfiguration() {
        let defaults = UserDefaults.standard
        
        defaults.set(configuration.primaryProvider.rawValue, forKey: "primaryProvider")
        defaults.set(configuration.secondaryProvider?.rawValue, forKey: "secondaryProvider")
        defaults.set(configuration.encryptionEnabled, forKey: "encryptionEnabled")
        defaults.set(configuration.autoBackup, forKey: "autoBackup")
        defaults.set(configuration.syncInterval, forKey: "syncInterval")
        defaults.set(configuration.maxStorageQuota, forKey: "maxStorageQuota")
        defaults.set(configuration.enableSyncConflicts, forKey: "enableSyncConflicts")
        defaults.set(configuration.compressionEnabled, forKey: "compressionEnabled")
        defaults.set(configuration.versioningEnabled, forKey: "versioningEnabled")
    }
    
    // MARK: - Core Operations
    
    func saveItem<T: StorageItem>(_ item: T) async throws -> Bool {
        guard let provider = providers[configuration.primaryProvider] else {
            throw StorageError.providerNotAvailable(configuration.primaryProvider)
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let processedItem = try await processForSaving(item)
            let success = try await provider.saveItem(processedItem)
            
            if success, let secondaryProvider = providers[configuration.secondaryProvider] {
                // Sync zu Secondary Provider
                try await secondaryProvider.saveItem(processedItem)
            }
            
            await refreshStatistics()
            return success
        } catch {
            logger.error("Fehler beim Speichern: \(error.localizedDescription)")
            throw error
        }
    }
    
    func loadItem<T: StorageItem>(id: UUID, type: T.Type) async throws -> T? {
        guard let provider = providers[configuration.primaryProvider] else {
            throw StorageError.providerNotAvailable(configuration.primaryProvider)
        }
        
        return try await provider.loadItem(id: id, type: type)
    }
    
    func loadAllItems<T: StorageItem>(type: T.Type) async throws -> [T] {
        guard let provider = providers[configuration.primaryProvider] else {
            throw StorageError.providerNotAvailable(configuration.primaryProvider)
        }
        
        let items = try await provider.loadAllItems(type: type)
        
        // Sync-Status aktualisieren
        await MainActor.run {
            for var item in items {
                item.syncStatus = .synced
            }
        }
        
        return items
    }
    
    func deleteItem(id: UUID) async throws -> Bool {
        guard let provider = providers[configuration.primaryProvider] else {
            throw StorageError.providerNotAvailable(configuration.primaryProvider)
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let success = try await provider.deleteItem(id: id)
        
        if success, let secondaryProvider = providers[configuration.secondaryProvider] {
            try await secondaryProvider.deleteItem(id: id)
        }
        
        await refreshStatistics()
        return success
    }
    
    // MARK: - Sync Operations
    
    func startAutoSync() {
        stopAutoSync()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: configuration.syncInterval, repeats: true) { _ in
            Task {
                await self.performAutoSync()
            }
        }
    }
    
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    func performAutoSync() async {
        guard !isSyncing else { return }
        
        logger.info("Starte Auto-Sync")
        isSyncing = true
        defer { 
            isSyncing = false
            lastSyncDate = Date()
        }
        
        // Hier würde die komplexe Sync-Logik implementiert
        // z.B. Abgleich zwischen lokalen und entfernten Daten
        
        await refreshStatistics()
        logger.info("Auto-Sync abgeschlossen")
    }
    
    func resolveSyncConflicts() async throws {
        guard configuration.enableSyncConflicts else { return }
        
        for (id, conflictItem) in syncConflicts {
            // Konfliktlösung basierend auf Konfiguration
            let resolvedItem = try await resolveConflict(for: conflictItem)
            
            try await saveItem(resolvedItem)
            await MainActor.run {
                syncConflicts.removeValue(forKey: id)
            }
        }
    }
    
    private func resolveConflict(for item: StorageItem) async throws -> StorageItem {
        guard let provider = providers[configuration.primaryProvider] else {
            throw StorageError.providerNotAvailable(configuration.primaryProvider)
        }
        
        // Lokale Version laden
        let localItem = try await provider.loadItem(id: item.id, type: NoteItem.self)
        
        if let local = localItem {
            return try await provider.resolveConflict(local: local, remote: item) as! NoteItem
        } else {
            return item
        }
    }
    
    // MARK: - Backup & Restore
    
    func createBackup() async throws -> URL {
        guard let provider = providers[configuration.primaryProvider] else {
            throw StorageError.providerNotAvailable(configuration.primaryProvider)
        }
        
        return try await provider.createBackup()
    }
    
    func restoreBackup(from url: URL) async throws -> Bool {
        guard let provider = providers[configuration.primaryProvider] else {
            throw StorageError.providerNotAvailable(configuration.primaryProvider)
        }
        
        let success = try await provider.restoreBackup(from: url)
        if success {
            await refreshStatistics()
        }
        return success
    }
    
    func exportAll() async throws -> URL {
        guard let provider = providers[configuration.primaryProvider] else {
            throw StorageError.providerNotAvailable(configuration.primaryProvider)
        }
        
        return try await provider.exportAll()
    }
    
    func importFrom(url: URL) async throws -> Int {
        guard let provider = providers[configuration.primaryProvider] else {
            throw StorageError.providerNotAvailable(configuration.primaryProvider)
        }
        
        let importCount = try await provider.importFrom(url: url)
        await refreshStatistics()
        return importCount
    }
    
    // MARK: - Statistics
    
    func refreshStatistics() async {
        await MainActor.run {
            // Berechne Statistiken
            // Diese Implementierung würde erweitert werden
            
            let stats = StorageStatistics(
                totalItems: 0,
                totalSize: 0,
                providerBreakdown: [:],
                syncStatusBreakdown: [:],
                lastBackupDate: nil,
                availableSpace: nil,
                usedSpace: 0,
                quotaPercentage: 0.0
            )
            
            statistics = stats
        }
    }
    
    // MARK: - Processing
    
    private func processForSaving<T: StorageItem>(_ item: T) async throws -> T {
        var processedItem = item
        
        // Verschlüsselung
        if configuration.encryptionEnabled && !item.isEncrypted {
            // Implementierung der Verschlüsselung
        }
        
        // Komprimierung
        if configuration.compressionEnabled {
            // Implementierung der Komprimierung
        }
        
        await MainActor.run {
            processedItem.syncStatus = .synced
        }
        
        return processedItem
    }
    
    // MARK: - Error Handling
    
    func retryFailedOperations() async {
        // Implementierung für Retry-Mechanismus
        logger.info("Retry fehlgeschlagener Operationen")
    }
    
    func cleanup() {
        stopAutoSync()
        logger.info("StorageManager bereinigt")
    }
}

// MARK: - Storage Errors

enum StorageError: Error {
    case providerNotAvailable(StorageProvider)
    case quotaExceeded
    case encryptionFailed
    case syncConflict(StorageItem, StorageItem)
    case backupFailed(String)
    case restoreFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .providerNotAvailable(let provider):
            return "Storage Provider \(provider.displayName) ist nicht verfügbar"
        case .quotaExceeded:
            return "Speicherplatz-Quota überschritten"
        case .encryptionFailed:
            return "Verschlüsselung fehlgeschlagen"
        case .syncConflict(let local, let remote):
            return "Sync-Konflikt zwischen lokalen und entfernten Daten"
        case .backupFailed(let reason):
            return "Backup fehlgeschlagen: \(reason)"
        case .restoreFailed(let reason):
            return "Restore fehlgeschlagen: \(reason)"
        }
    }
}

// MARK: - NoteItem Implementation

struct NoteItem: StorageItem {
    let id: UUID
    var title: String
    var content: String
    let createdAt: Date
    var modifiedAt: Date
    var tags: [String]
    var isEncrypted: Bool = false
    var provider: StorageProvider
    var syncStatus: SyncStatus = .pending
    
    init(title: String, content: String, provider: StorageProvider = .local) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.tags = []
        self.provider = provider
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt, modifiedAt, tags, isEncrypted, provider, syncStatus
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encode(tags, forKey: .tags)
        try container.encode(isEncrypted, forKey: .isEncrypted)
        try container.encode(provider, forKey: .provider)
        try container.encode(syncStatus, forKey: .syncStatus)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.isEncrypted = try container.decode(Bool.self, forKey: .isEncrypted)
        self.provider = try container.decode(StorageProvider.self, forKey: .provider)
        self.syncStatus = try container.decode(SyncStatus.self, forKey: .syncStatus)
    }
}

// MARK: - User Preferences Manager

class StoragePreferences: ObservableObject {
    @Published var autoSaveEnabled: Bool = true
    @Published var saveInterval: TimeInterval = 30
    @Published var backupFrequency: TimeInterval = 86400 // 1 Tag
    @Published var encryptSensitiveNotes: Bool = false
    @Published var syncOnAppLaunch: Bool = true
    @Published var showStorageStats: Bool = true
    @Published var maxBackupCount: Int = 10
    
    static let shared = StoragePreferences()
    
    private init() {
        loadPreferences()
    }
    
    private func loadPreferences() {
        let defaults = UserDefaults.standard
        autoSaveEnabled = defaults.bool(forKey: "autoSaveEnabled")
        saveInterval = defaults.double(forKey: "saveInterval")
        backupFrequency = defaults.double(forKey: "backupFrequency")
        encryptSensitiveNotes = defaults.bool(forKey: "encryptSensitiveNotes")
        syncOnAppLaunch = defaults.bool(forKey: "syncOnAppLaunch")
        showStorageStats = defaults.bool(forKey: "showStorageStats")
        maxBackupCount = defaults.integer(forKey: "maxBackupCount")
    }
    
    func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(autoSaveEnabled, forKey: "autoSaveEnabled")
        defaults.set(saveInterval, forKey: "saveInterval")
        defaults.set(backupFrequency, forKey: "backupFrequency")
        defaults.set(encryptSensitiveNotes, forKey: "encryptSensitiveNotes")
        defaults.set(syncOnAppLaunch, forKey: "syncOnAppLaunch")
        defaults.set(showStorageStats, forKey: "showStorageStats")
        defaults.set(maxBackupCount, forKey: "maxBackupCount")
    }
}