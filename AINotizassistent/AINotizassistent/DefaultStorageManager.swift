//
//  DefaultStorageManager.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Storage Target Definition
enum StorageTarget: String, CaseIterable, Codable {
    case appleNotes = "Apple Notes"
    case obsidian = "Obsidian"
    case notion = "Notion"
    case local = "Lokaler Speicher"
    case dropbox = "Dropbox"
    case googleDrive = "Google Drive"
    case oneDrive = "OneDrive"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .appleNotes:
            return "📱"
        case .obsidian:
            return "🔍"
        case .notion:
            return "📋"
        case .local:
            return "💾"
        case .dropbox:
            return "📦"
        case .googleDrive:
            return "🗂️"
        case .oneDrive:
            return "☁️"
        }
    }
    
    var isAvailable: Bool {
        // Prüft Verfügbarkeit der Storage-Targets
        switch self {
        case .appleNotes:
            return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Notes") != nil
        case .obsidian:
            return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "md.obsidian") != nil
        case .notion:
            return true // Notion Web ist immer verfügbar
        case .local:
            return true
        case .dropbox, .googleDrive, .oneDrive:
            return true // Cloud-Services sind über APIs verfügbar
        }
    }
    
    var requiresConfiguration: Bool {
        switch self {
        case .appleNotes, .local:
            return false
        case .obsidian, .notion, .dropbox, .googleDrive, .oneDrive:
            return true
        }
    }
}

// MARK: - Content Type Specific Storage Configuration
struct ContentTypeStorageConfig {
    let primary: StorageTarget
    let secondary: StorageTarget?
    let autoSync: Bool
    let createBackup: Bool
    
    init(primary: StorageTarget, secondary: StorageTarget? = nil, autoSync: Bool = true, createBackup: Bool = true) {
        self.primary = primary
        self.secondary = secondary
        self.autoSync = autoSync
        self.createBackup = createBackup
    }
}

// MARK: - Smart Storage Suggestions
struct StorageSuggestion {
    let target: StorageTarget
    let confidence: Double
    let reason: String
    let metadata: [String: Any]
}

// MARK: - Storage Conflict Resolution
struct StorageConflict {
    let contentId: String
    let versions: [(target: StorageTarget, timestamp: Date, url: URL)]
    let resolution: ConflictResolution
}

enum ConflictResolution {
    case keepLatest
    case merge
    case keepBoth
    case manual
    case usePrimary
}

// MARK: - Batch Storage Operation
struct BatchStorageOperation {
    let operationId: String
    let items: [ContentItem]
    let target: StorageTarget
    let progress: Double
    let status: OperationStatus
    let error: Error?
}

enum OperationStatus {
    case pending
    case running
    case completed
    case failed
    case cancelled
}

// MARK: - Content Item for Storage
struct ContentItem: Identifiable, Codable {
    let id = UUID()
    let content: String
    let type: ContentType
    let metadata: [String: AnyCodable]
    let tags: [String]
    let createdAt: Date
    let modifiedAt: Date
    
    init(content: String, type: ContentType, metadata: [String: AnyCodable] = [:], tags: [String] = []) {
        self.content = content
        self.type = type
        self.metadata = metadata
        self.tags = tags
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

// MARK: - Default Storage Manager
@MainActor
class DefaultStorageManager: ObservableObject {
    @Published var availableTargets: [StorageTarget] = []
    @Published var primaryStorage: StorageTarget = .local
    @Published var secondaryStorage: StorageTarget? = nil
    @Published var contentTypeConfigs: [ContentType: ContentTypeStorageConfig] = [:]
    @Published var batchOperations: [BatchStorageOperation] = []
    @Published var conflicts: [StorageConflict] = []
    @Published var isProcessing: Bool = false
    
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    private let storageQueue = DispatchQueue(label: "storage.queue", qos: .userInitiated)
    
    // User Workflow Specific Preferences
    @Published var workflowPreferences: [String: ContentTypeStorageConfig] = [:]
    @Published var activeWorkflow: String? = nil
    
    init() {
        setupDefaultConfigurations()
        loadStorageSettings()
        checkAvailableTargets()
    }
    
    // MARK: - Configuration Setup
    private func setupDefaultConfigurations() {
        // Standard Content-Type spezifische Speicherziele
        contentTypeConfigs[.email] = ContentTypeStorageConfig(
            primary: .appleNotes,
            secondary: .dropbox,
            autoSync: true,
            createBackup: true
        )
        
        contentTypeConfigs[.meeting] = ContentTypeStorageConfig(
            primary: .notion,
            secondary: .local,
            autoSync: true,
            createBackup: true
        )
        
        contentTypeConfigs[.article] = ContentTypeStorageConfig(
            primary: .obsidian,
            secondary: .googleDrive,
            autoSync: true,
            createBackup: true
        )
        
        contentTypeConfigs[.code] = ContentTypeStorageConfig(
            primary: .local,
            secondary: .obsidian,
            autoSync: false,
            createBackup: true
        )
        
        contentTypeConfigs[.note] = ContentTypeStorageConfig(
            primary: .local,
            secondary: .appleNotes,
            autoSync: true,
            createBackup: false
        )
        
        contentTypeConfigs[.task] = ContentTypeStorageConfig(
            primary: .notion,
            secondary: .appleNotes,
            autoSync: true,
            createBackup: true
        )
        
        contentTypeConfigs[.idea] = ContentTypeStorageConfig(
            primary: .obsidian,
            secondary: .local,
            autoSync: true,
            createBackup: false
        )
        
        contentTypeConfigs[.personal] = ContentTypeStorageConfig(
            primary: .appleNotes,
            secondary: nil,
            autoSync: false,
            createBackup: true
        )
    }
    
    // MARK: - Storage Target Management
    func checkAvailableTargets() {
        availableTargets = StorageTarget.allCases.filter { $0.isAvailable }
        
        // Primary Storage validieren
        if !availableTargets.contains(primaryStorage) {
            primaryStorage = availableTargets.first ?? .local
        }
        
        // Secondary Storage validieren
        if let secondary = secondaryStorage, !availableTargets.contains(secondary) {
            secondaryStorage = nil
        }
    }
    
    func setPrimaryStorage(_ target: StorageTarget) {
        guard availableTargets.contains(target) else { return }
        
        primaryStorage = target
        saveStorageSettings()
        NotificationCenter.default.post(name: .primaryStorageChanged, object: target)
    }
    
    func setSecondaryStorage(_ target: StorageTarget?) {
        guard target == nil || availableTargets.contains(target!) else { return }
        
        secondaryStorage = target
        saveStorageSettings()
        NotificationCenter.default.post(name: .secondaryStorageChanged, object: target)
    }
    
    // MARK: - Content Type Specific Storage
    func setContentTypeConfig(_ type: ContentType, config: ContentTypeStorageConfig) {
        guard availableTargets.contains(config.primary) else { return }
        
        if let secondary = config.secondary {
            guard availableTargets.contains(secondary) else { return }
        }
        
        contentTypeConfigs[type] = config
        saveContentTypeConfigs()
        NotificationCenter.default.post(name: .contentTypeConfigChanged, object: (type, config))
    }
    
    func getStorageConfig(for type: ContentType) -> ContentTypeStorageConfig {
        return contentTypeConfigs[type] ?? ContentTypeStorageConfig(
            primary: primaryStorage,
            secondary: secondaryStorage,
            autoSync: true,
            createBackup: true
        )
    }
    
    // MARK: - Smart Storage Suggestions
    func suggestStorage(for item: ContentItem) -> [StorageSuggestion] {
        var suggestions: [StorageSuggestion] = []
        
        // Content-Type basierte Vorschläge
        let typeConfig = getStorageConfig(for: item.type)
        let primarySuggestion = StorageSuggestion(
            target: typeConfig.primary,
            confidence: 0.8,
            reason: "Standard für \(item.type.displayName)",
            metadata: ["type": "default"]
        )
        suggestions.append(primarySuggestion)
        
        // Content-Analyse für intelligentere Vorschläge
        let contentAnalysis = analyzeContentForStorage(item.content)
        suggestions.append(contentsOf: contentAnalysis)
        
        // Workflow-basierte Vorschläge
        if let workflow = activeWorkflow,
           let workflowConfig = workflowPreferences[workflow] {
            let workflowSuggestion = StorageSuggestion(
                target: workflowConfig.primary,
                confidence: 0.9,
                reason: "Aktiver Workflow: \(workflow)",
                metadata: ["type": "workflow", "workflow": workflow]
            )
            suggestions.insert(workflowSuggestion, at: 0)
        }
        
        // Nach Confidence sortieren
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    private func analyzeContentForStorage(_ content: String) -> [StorageSuggestion] {
        var suggestions: [StorageSuggestion] = []
        
        // Intelligente Erkennung basierend auf Content-Eigenschaften
        if containsUrls(content) {
            suggestions.append(StorageSuggestion(
                target: .obsidian,
                confidence: 0.7,
                reason: "Inhalte mit Links eignen sich gut für Obsidian",
                metadata: ["type": "content_analysis", "feature": "links"]
            ))
        }
        
        if containsCodeBlocks(content) {
            suggestions.append(StorageSuggestion(
                target: .local,
                confidence: 0.8,
                reason: "Code-Blöcke sollten lokal gespeichert werden",
                metadata: ["type": "content_analysis", "feature": "code"]
            ))
        }
        
        if containsMeetingKeywords(content) {
            suggestions.append(StorageSuggestion(
                target: .notion,
                confidence: 0.75,
                reason: "Meeting-Inhalte werden strukturiert in Notion gespeichert",
                metadata: ["type": "content_analysis", "feature": "meeting"]
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Content Analysis Helpers
    private func containsUrls(_ content: String) -> Bool {
        let urlPattern = #"https?://[^\s]+"#
        return content.range(of: urlPattern, options: .regularExpression) != nil
    }
    
    private func containsCodeBlocks(_ content: String) -> Bool {
        return content.contains("```") || content.contains("`") || content.lowercased().contains("code")
    }
    
    private func containsMeetingKeywords(_ content: String) -> Bool {
        let meetingKeywords = ["meeting", "besprechung", "termin", "agenda", "protokoll"]
        let lowercaseContent = content.lowercased()
        return meetingKeywords.contains { lowercaseContent.contains($0) }
    }
    
    // MARK: - Batch Operations
    func batchStoreItems(_ items: [ContentItem], to target: StorageTarget) async throws -> String {
        let operationId = UUID().uuidString
        
        let operation = BatchStorageOperation(
            operationId: operationId,
            items: items,
            target: target,
            progress: 0.0,
            status: .pending,
            error: nil
        )
        
        batchOperations.append(operation)
        
        Task {
            await executeBatchOperation(operation)
        }
        
        return operationId
    }
    
    private func executeBatchOperation(_ operation: BatchStorageOperation) async {
        var updatedOperation = operation
        updatedOperation.status = .running
        updateOperation(updatedOperation)
        
        let totalItems = Double(operation.items.count)
        var processedItems = 0
        
        for item in operation.items {
            do {
                try await storeItem(item, to: operation.target)
                processedItems += 1
                updatedOperation.progress = processedItems / totalItems
                updateOperation(updatedOperation)
            } catch {
                updatedOperation.status = .failed
                updatedOperation.error = error
                updateOperation(updatedOperation)
                return
            }
        }
        
        updatedOperation.status = .completed
        updatedOperation.progress = 1.0
        updateOperation(updatedOperation)
        
        // Operation aus Liste entfernen nach kurzer Verzögerung
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.batchOperations.removeAll { $0.operationId == operation.operationId }
        }
    }
    
    private func updateOperation(_ operation: BatchStorageOperation) {
        if let index = batchOperations.firstIndex(where: { $0.operationId == operation.operationId }) {
            batchOperations[index] = operation
        }
    }
    
    private func storeItem(_ item: ContentItem, to target: StorageTarget) async throws {
        // Implementierung für spezifische Storage-Targets
        switch target {
        case .appleNotes:
            try await storeInAppleNotes(item)
        case .obsidian:
            try await storeInObsidian(item)
        case .notion:
            try await storeInNotion(item)
        case .local:
            try await storeLocally(item)
        case .dropbox, .googleDrive, .oneDrive:
            try await storeInCloud(target, item)
        }
    }
    
    // MARK: - Specific Storage Implementations
    private func storeInAppleNotes(_ item: ContentItem) async throws {
        // Apple Notes Integration
        let appleScript = createAppleNotesScript(for: item)
        try await runAppleScript(appleScript)
    }
    
    private func storeInObsidian(_ item: ContentItem) async throws {
        // Obsidian Integration über Dateisystem
        let fileName = "\(item.type.rawValue)_\(Date().timeIntervalSince1970).md"
        let vaultPath = getObsidianVaultPath() ?? ""
        let fileURL = URL(fileURLWithPath: vaultPath).appendingPathComponent(fileName)
        
        let content = formatContentForMarkdown(item)
        try content.data(using: .utf8)?.write(to: fileURL)
    }
    
    private func storeInNotion(_ item: ContentItem) async throws {
        // Notion API Integration
        // Placeholder für Notion API Aufruf
        try await Task.sleep(nanoseconds: 100_000_000) // Simulierte API Latenz
    }
    
    private func storeLocally(_ item: ContentItem) async throws {
        // Lokaler Speicher in der App
        try await CoreDataManager.shared.saveNote(from: item)
    }
    
    private func storeInCloud(_ target: StorageTarget, _ item: ContentItem) async throws {
        // Cloud Storage Integration
        try await Task.sleep(nanoseconds: 200_000_000) // Simulierte API Latenz
    }
    
    // MARK: - Conflict Detection and Resolution
    func detectConflicts(for item: ContentItem) -> [StorageConflict] {
        // Placeholder für Konflikt-Erkennung
        // In einer echten Implementierung würde dies historische Versionen prüfen
        return []
    }
    
    func resolveConflict(_ conflict: StorageConflict, using resolution: ConflictResolution) async throws {
        switch resolution {
        case .keepLatest:
            try await keepLatestVersion(conflict)
        case .merge:
            try await mergeVersions(conflict)
        case .keepBoth:
            try await keepBothVersions(conflict)
        case .manual:
            // Manual resolution wird an UI delegiert
            break
        case .usePrimary:
            try await usePrimaryVersion(conflict)
        }
    }
    
    private func keepLatestVersion(_ conflict: StorageConflict) async throws {
        // Implementierung für Latest Version
    }
    
    private func mergeVersions(_ conflict: StorageConflict) async throws {
        // Implementierung für Version Merging
    }
    
    private func keepBothVersions(_ conflict: StorageConflict) async throws {
        // Implementierung für Beide Versionen behalten
    }
    
    private func usePrimaryVersion(_ conflict: StorageConflict) async throws {
        // Implementierung für Primary Version verwenden
    }
    
    // MARK: - User Workflow Management
    func setActiveWorkflow(_ workflow: String) {
        activeWorkflow = workflow
        saveWorkflowPreferences()
        NotificationCenter.default.post(name: .activeWorkflowChanged, object: workflow)
    }
    
    func addWorkflowPreference(_ workflow: String, config: ContentTypeStorageConfig) {
        workflowPreferences[workflow] = config
        saveWorkflowPreferences()
    }
    
    func removeWorkflowPreference(_ workflow: String) {
        workflowPreferences.removeValue(forKey: workflow)
        saveWorkflowPreferences()
    }
    
    // MARK: - Utility Methods
    private func createAppleNotesScript(for item: ContentItem) -> String {
        return """
        tell application "Notes"
            set newNote to make new note at folder "AI Notizassistent"
            set name of newNote to "\(item.type.rawValue) - \(Date())"
            set body of newNote to "\(item.content)"
        end tell
        """
    }
    
    private func runAppleScript(_ script: String) async throws {
        // AppleScript ausführen
        try await withCheckedThrowingContinuation { continuation in
            var error: NSError?
            let scriptObject = NSAppleScript(source: script)
            scriptObject?.executeAndReturnError(&error)
            
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: ())
            }
        }
    }
    
    private func getObsidianVaultPath() -> String? {
        // Obsidian Vault Pfad ermitteln
        return nil // Placeholder
    }
    
    private func formatContentForMarkdown(_ item: ContentItem) -> String {
        var content = "# \(item.type.rawValue)\n\n"
        content += item.content
        content += "\n\n---\n"
        content += "**Tags:** \(item.tags.joined(separator: ", "))\n"
        content += "**Erstellt:** \(item.createdAt.formatted(date: .abbreviated, time: .shortened))\n"
        
        return content
    }
    
    // MARK: - Settings Persistence
    private func loadStorageSettings() {
        if let savedPrimary = defaults.string(forKey: "primaryStorage"),
           let target = StorageTarget(rawValue: savedPrimary) {
            primaryStorage = target
        }
        
        if let savedSecondary = defaults.string(forKey: "secondaryStorage"),
           let target = StorageTarget(rawValue: savedSecondary) {
            secondaryStorage = target
        }
        
        // Workflow Preferences laden
        if let workflowData = defaults.data(forKey: "workflowPreferences"),
           let decoded = try? JSONDecoder().decode([String: ContentTypeStorageConfig].self, from: workflowData) {
            workflowPreferences = decoded
        }
    }
    
    private func saveStorageSettings() {
        defaults.set(primaryStorage.rawValue, forKey: "primaryStorage")
        if let secondary = secondaryStorage {
            defaults.set(secondary.rawValue, forKey: "secondaryStorage")
        }
    }
    
    private func saveContentTypeConfigs() {
        if let encoded = try? JSONEncoder().encode(contentTypeConfigs) {
            defaults.set(encoded, forKey: "contentTypeConfigs")
        }
    }
    
    private func saveWorkflowPreferences() {
        if let encoded = try? JSONEncoder().encode(workflowPreferences) {
            defaults.set(encoded, forKey: "workflowPreferences")
        }
    }
    
    func exportStorageSettings() -> Data {
        let settings = StorageSettingsExport(
            primaryStorage: primaryStorage,
            secondaryStorage: secondaryStorage,
            contentTypeConfigs: contentTypeConfigs,
            workflowPreferences: workflowPreferences
        )
        
        return try! JSONEncoder().encode(settings)
    }
    
    func importStorageSettings(from data: Data) throws {
        let settings = try JSONDecoder().decode(StorageSettingsExport.self, from: data)
        
        primaryStorage = settings.primaryStorage
        secondaryStorage = settings.secondaryStorage
        contentTypeConfigs = settings.contentTypeConfigs
        workflowPreferences = settings.workflowPreferences
        
        saveStorageSettings()
        saveContentTypeConfigs()
        saveWorkflowPreferences()
    }
}

// MARK: - Storage Settings Export Structure
struct StorageSettingsExport: Codable {
    let primaryStorage: StorageTarget
    let secondaryStorage: StorageTarget?
    let contentTypeConfigs: [ContentType: ContentTypeStorageConfig]
    let workflowPreferences: [String: ContentTypeStorageConfig]
}

// MARK: - Notification Names
extension Notification.Name {
    static let primaryStorageChanged = Notification.Name("PrimaryStorageChanged")
    static let secondaryStorageChanged = Notification.Name("SecondaryStorageChanged")
    static let contentTypeConfigChanged = Notification.Name("ContentTypeConfigChanged")
    static let activeWorkflowChanged = Notification.Name("ActiveWorkflowChanged")
}

// MARK: - AnyCodable Helper
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            self.value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            self.value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            self.value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            self.value = boolValue
        } else {
            self.value = try container.decode(String.self)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        default:
            try container.encode(String(describing: value))
        }
    }
}