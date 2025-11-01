//
//  AutoSaveManager.swift
//  AINotizassistent
//
//  Automatisches Speichern mit intelligenter Verzögerung und Konfliktvermeidung
//

import Foundation
import SwiftUI
import Combine
import os.log

// MARK: - Auto Save Configuration

struct AutoSaveConfiguration {
    let enabled: Bool
    let interval: TimeInterval
    let idleThreshold: TimeInterval
    let maxItemsPerBatch: Int
    let retryAttempts: Int
    let exponentialBackoff: Bool
    let preserveDrafts: Bool
    let notifyOnSave: Bool
    
    init(enabled: Bool = true, interval: TimeInterval = 30.0, idleThreshold: TimeInterval = 5.0, maxItemsPerBatch: Int = 10, retryAttempts: Int = 3, exponentialBackoff: Bool = true, preserveDrafts: Bool = true, notifyOnSave: Bool = false) {
        self.enabled = enabled
        self.interval = interval
        self.idleThreshold = idleThreshold
        self.maxItemsPerBatch = maxItemsPerBatch
        self.retryAttempts = retryAttempts
        self.exponentialBackoff = exponentialBackoff
        self.preserveDrafts = preserveDrafts
        self.notifyOnSave = notifyOnSave
    }
    
    static let `default` = AutoSaveConfiguration()
    static let aggressive = AutoSaveConfiguration(interval: 10.0, idleThreshold: 2.0)
    static let conservative = AutoSaveConfiguration(interval: 120.0, idleThreshold: 15.0)
    static let manual = AutoSaveConfiguration(enabled: false)
}

// MARK: - Save Item Protocol

protocol SaveableItem {
    var id: UUID { get }
    var isDirty: Bool { get }
    var lastModified: Date { get }
    var savePriority: SavePriority { get }
    
    func markAsClean()
    func markAsDirty()
}

// MARK: - Save Priority

enum SavePriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    static func < (lhs: SavePriority, rhs: SavePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Save Operation Status

enum SaveOperationStatus {
    case pending
    case inProgress
    case completed
    case failed(Error)
    case cancelled
    
    var isActive: Bool {
        switch self {
        case .pending, .inProgress:
            return true
        case .completed, .failed, .cancelled:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .pending: return "Ausstehend"
        case .inProgress: return "Speichere..."
        case .completed: return "Gespeichert"
        case .failed(let error): return "Fehler: \(error.localizedDescription)"
        case .cancelled: return "Abgebrochen"
        }
    }
}

// MARK: - Save Queue Item

struct SaveQueueItem: Identifiable, Comparable {
    let id = UUID()
    let item: any SaveableItem
    let addedAt: Date
    let priority: SavePriority
    var retryCount: Int = 0
    var status: SaveOperationStatus = .pending
    var lastError: Error? = nil
    
    var age: TimeInterval {
        Date().timeIntervalSince(addedAt)
    }
    
    static func < (lhs: SaveQueueItem, rhs: SaveQueueItem) -> Bool {
        if lhs.priority == rhs.priority {
            return lhs.addedAt < rhs.addedAt
        }
        return lhs.priority > rhs.priority
    }
    
    static func == (lhs: SaveQueueItem, rhs: SaveQueueItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Save Statistics

struct SaveStatistics {
    let totalSaves: Int
    let successfulSaves: Int
    let failedSaves: Int
    let averageSaveTime: TimeInterval
    let lastSaveDate: Date?
    let queueSize: Int
    let longestPendingTime: TimeInterval
}

// MARK: - Notification Manager

class SaveNotificationManager: ObservableObject {
    @Published var lastSavedItem: (any SaveableItem)? = nil
    @Published var saveErrors: [Error] = []
    
    private let notificationCenter = NotificationCenter.default
    
    func notifySaveSuccess(item: any SaveableItem) {
        lastSavedItem = item
        
        // System Notification für kritische Items
        if item.savePriority == .critical {
            let notification = UNUserNotificationCenter.current()
            notification.add(.saveSuccess(item: item))
        }
    }
    
    func notifySaveFailure(error: Error, item: any SaveableItem) {
        saveErrors.append(error)
        
        // System Notification für kritische Fehler
        if item.savePriority == .critical {
            let notification = UNUserNotificationCenter.current()
            notification.add(.saveFailure(item: item, error: error))
        }
    }
}

// MARK: - Save Performance Monitor

class SavePerformanceMonitor {
    private var saveTimes: [TimeInterval] = []
    private let maxHistorySize = 100
    
    func recordSaveTime(_ time: TimeInterval) {
        saveTimes.append(time)
        if saveTimes.count > maxHistorySize {
            saveTimes.removeFirst()
        }
    }
    
    var averageSaveTime: TimeInterval {
        guard !saveTimes.isEmpty else { return 0 }
        return saveTimes.reduce(0, +) / Double(saveTimes.count)
    }
    
    var lastSaveTime: TimeInterval? {
        saveTimes.last
    }
    
    func reset() {
        saveTimes.removeAll()
    }
}

// MARK: - Draft Manager

class DraftManager: ObservableObject {
    @Published var drafts: [UUID: Data] = [:]
    private let fileManager = FileManager.default
    private let draftDirectory: URL
    
    private let logger = Logger(subsystem: "AINotizassistent", category: "DraftManager")
    
    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.draftDirectory = documentsPath.appendingPathComponent("Drafts")
        try? fileManager.createDirectory(at: draftDirectory, withIntermediateDirectories: true)
    }
    
    func saveDraft(_ item: any SaveableItem, data: Data) {
        let draftURL = draftDirectory.appendingPathComponent("\(item.id.uuidString).draft")
        
        do {
            try data.write(to: draftURL)
            await MainActor.run {
                drafts[item.id] = data
            }
            logger.info("Draft für Item \(item.id) gespeichert")
        } catch {
            logger.error("Fehler beim Speichern des Drafts: \(error.localizedDescription)")
        }
    }
    
    func loadDraft(for id: UUID) -> Data? {
        let draftURL = draftDirectory.appendingPathComponent("\(id.uuidString).draft")
        
        guard fileManager.fileExists(atPath: draftURL.path) else { return nil }
        
        do {
            return try Data(contentsOf: draftURL)
        } catch {
            logger.error("Fehler beim Laden des Drafts: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteDraft(for id: UUID) {
        let draftURL = draftDirectory.appendingPathComponent("\(id.uuidString).draft")
        
        if fileManager.fileExists(atPath: draftURL.path) {
            try? fileManager.removeItem(at: draftURL)
        }
        
        drafts.removeValue(forKey: id)
        logger.info("Draft für Item \(id) gelöscht")
    }
    
    func clearAllDrafts() {
        guard let contents = try? fileManager.contentsOfDirectory(at: draftDirectory, includingPropertiesForKeys: nil) else { return }
        
        for file in contents where file.pathExtension == "draft" {
            try? fileManager.removeItem(at: file)
        }
        
        drafts.removeAll()
        logger.info("Alle Drafts gelöscht")
    }
}

// MARK: - Conflict Resolver

class ConflictResolver {
    private let storageManager: StorageManager
    
    init(storageManager: StorageManager = .shared) {
        self.storageManager = storageManager
    }
    
    func resolveConflict(localItem: any SaveableItem, remoteItem: any SaveableItem) async throws -> any SaveableItem {
        // Strategien zur Konfliktlösung basierend auf Priorität und Zeit
        let conflictStrategy = determineConflictStrategy(localItem, remoteItem)
        
        switch conflictStrategy {
        case .localWins:
            return localItem
        case .remoteWins:
            return remoteItem
        case .merge:
            return try await mergeItems(localItem, remoteItem)
        case .manual:
            // User-Input für manuelle Konfliktlösung erforderlich
            throw SaveError.manualConflictResolutionRequired(localItem, remoteItem)
        }
    }
    
    private func determineConflictStrategy(_ local: any SaveableItem, _ remote: any SaveableItem) -> ConflictResolutionStrategy {
        // Kritische Items gewinnen immer
        if local.savePriority == .critical || remote.savePriority == .critical {
            return local.savePriority > remote.savePriority ? .localWins : .remoteWins
        }
        
        // Neueste Änderung gewinnt (bei normalen Items)
        if abs(local.lastModified.timeIntervalSince(remote.lastModified)) > 300 { // 5 Minuten Differenz
            return local.lastModified > remote.lastModified ? .localWins : .remoteWins
        }
        
        // Bei ähnlichen Zeitstempeln: Manual Resolution
        return .manual
    }
    
    private func mergeItems(_ local: any SaveableItem, _ remote: any SaveableItem) async throws -> any SaveableItem {
        // Implementierung der Merge-Logik für komplexere Konfliktlösung
        // Dies könnte auf Item-Typ basieren
        return local // Fallback: lokale Version behalten
    }
}

// MARK: - Auto Save Manager

@MainActor
class AutoSaveManager: ObservableObject {
    
    // MARK: - Properties
    
    static let shared = AutoSaveManager()
    
    @Published var isEnabled: Bool = StoragePreferences.shared.autoSaveEnabled
    @Published var configuration: AutoSaveConfiguration
    @Published var queue: [SaveQueueItem] = []
    @Published var isProcessingQueue: Bool = false
    @Published var lastProcessedItem: UUID? = nil
    @Published var statistics: SaveStatistics?
    
    // Dependencies
    private let storageManager = StorageManager.shared
    private let notificationManager = SaveNotificationManager()
    private let performanceMonitor = SavePerformanceMonitor()
    private let draftManager = DraftManager()
    private let conflictResolver = ConflictResolver()
    
    // Internals
    private var saveTimer: Timer?
    private var idleTimer: Timer?
    private var processQueueTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "AINotizassistent", category: "AutoSaveManager")
    
    // Backoff tracking
    private var currentBackoffInterval: TimeInterval = 1.0
    private let maxBackoffInterval: TimeInterval = 60.0
    private let backoffMultiplier: Double = 2.0
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = Self.loadConfiguration()
        setupObservers()
        startTimers()
        Task {
            await refreshStatistics()
        }
    }
    
    deinit {
        stopTimers()
        processQueueTask?.cancel()
    }
    
    // MARK: - Configuration Management
    
    private static func loadConfiguration() -> AutoSaveConfiguration {
        let defaults = UserDefaults.standard
        let enabled = defaults.bool(forKey: "autoSaveEnabled")
        let interval = defaults.double(forKey: "autoSaveInterval")
        let idleThreshold = defaults.double(forKey: "autoSaveIdleThreshold")
        
        return AutoSaveConfiguration(
            enabled: enabled,
            interval: interval > 0 ? interval : 30.0,
            idleThreshold: idleThreshold > 0 ? idleThreshold : 5.0
        )
    }
    
    func updateConfiguration(_ newConfiguration: AutoSaveConfiguration) {
        self.configuration = newConfiguration
        
        // UserDefaults aktualisieren
        let defaults = UserDefaults.standard
        defaults.set(newConfiguration.enabled, forKey: "autoSaveEnabled")
        defaults.set(newConfiguration.interval, forKey: "autoSaveInterval")
        defaults.set(newConfiguration.idleThreshold, forKey: "autoSaveIdleThreshold")
        
        // Timer neu starten
        restartTimers()
        
        logger.info("AutoSave-Konfiguration aktualisiert")
    }
    
    // MARK: - Queue Management
    
    func queueForSave(_ item: any SaveableItem, priority: SavePriority = .normal) {
        guard configuration.enabled else { return }
        
        // Überprüfe ob Item bereits in Queue ist
        if let existingIndex = queue.firstIndex(where: { $0.item.id == item.id }) {
            queue[existingIndex].priority = priority
            queue[existingIndex].retryCount = 0 // Reset retry count
            queue[existingIndex].status = .pending
            queue.sort()
            return
        }
        
        // Neues Item zur Queue hinzufügen
        let queueItem = SaveQueueItem(
            item: item,
            addedAt: Date(),
            priority: priority
        )
        
        queue.append(queueItem)
        queue.sort()
        
        // Draft speichern wenn konfiguriert
        if configuration.preserveDrafts, let data = try? JSONEncoder().encode(item as any Encodable) {
            draftManager.saveDraft(item, data: data)
        }
        
        // Sofortiger Prozess bei kritischen Items
        if priority == .critical {
            processQueue()
        }
        
        logger.debug("Item \(item.id) zur Save-Queue hinzugefügt (Priorität: \(priority))")
    }
    
    func cancelSave(_ itemId: UUID) {
        if let index = queue.firstIndex(where: { $0.item.id == itemId }) {
            queue[index].status = .cancelled
            queue.remove(at: index)
            logger.debug("Save für Item \(itemId) abgebrochen")
        }
    }
    
    func clearQueue() {
        queue.removeAll()
        logger.info("Save-Queue geleert")
    }
    
    // MARK: - Queue Processing
    
    private func processQueue() {
        guard configuration.enabled && !isProcessingQueue else { return }
        guard !queue.isEmpty else { return }
        
        processQueueTask?.cancel() // Vorherige Task beenden
        processQueueTask = Task { [weak self] in
            await self?.processQueueAsync()
        }
    }
    
    private func processQueueAsync() async {
        isProcessingQueue = true
        defer {
            isProcessingQueue = false
            currentBackoffInterval = 1.0 // Reset backoff
        }
        
        var processedCount = 0
        
        while !Task.isCancelled && processedCount < configuration.maxItemsPerBatch {
            guard let nextItem = await getNextQueueItem() else { break }
            
            let success = await processItem(nextItem)
            if success {
                await refreshStatistics()
            }
            
            processedCount += 1
            
            // Kleine Pause zwischen Items
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 Sekunden
        }
        
        logger.info("Queue-Verarbeitung abgeschlossen: \(processedCount) Items verarbeitet")
    }
    
    private func getNextQueueItem() async -> SaveQueueItem? {
        return await MainActor.run {
            // Erst alle nicht-cancelled Items
            let pendingItems = queue.filter { !$0.status.isActive && $0.status != .cancelled }
            return pendingItems.first
        }
    }
    
    private func processItem(_ queueItem: SaveQueueItem) async -> Bool {
        let item = queueItem.item
        
        // Status auf "inProgress" setzen
        await setItemStatus(queueItem.id, status: .inProgress)
        
        let startTime = Date()
        var success = false
        var lastError: Error? = nil
        
        do {
            // Item basierend auf Typ speichern
            if let noteItem = item as? NoteItem {
                success = try await storageManager.saveItem(noteItem)
            } else {
                // Generische Speicher-Implementierung
                success = try await storageManager.saveItem(item as any StorageItem)
            }
            
            if success {
                item.markAsClean()
                await setItemStatus(queueItem.id, status: .completed)
                
                // Erfolgsmeldung
                if configuration.notifyOnSave {
                    notificationManager.notifySaveSuccess(item: item)
                }
                
                // Performance aufzeichnen
                let saveTime = Date().timeIntervalSince(startTime)
                performanceMonitor.recordSaveTime(saveTime)
                
                // Draft löschen
                draftManager.deleteDraft(for: item.id)
                
                logger.debug("Item \(item.id) erfolgreich gespeichert")
            } else {
                throw SaveError.unknownError
            }
            
        } catch {
            lastError = error
            await setItemStatus(queueItem.id, status: .failed(error))
            notificationManager.notifySaveFailure(error: error, item: item)
            
            logger.error("Fehler beim Speichern von Item \(item.id): \(error.localizedDescription)")
        }
        
        // Backoff-Strategie bei Fehlern
        if let error = lastError, !success {
            await handleSaveError(error, for: queueItem)
        }
        
        return success
    }
    
    private func setItemStatus(_ itemId: UUID, status: SaveOperationStatus) async {
        if let index = queue.firstIndex(where: { $0.item.id == itemId }) {
            queue[index].status = status
            queue[index].lastError = status == .failed ? queue[index].lastError : nil
        }
    }
    
    private func handleSaveError(_ error: Error, for queueItem: SaveQueueItem) async {
        queueItem.retryCount += 1
        
        if queueItem.retryCount < configuration.retryAttempts {
            // Retry mit Backoff
            let delay = configuration.exponentialBackoff ? 
                currentBackoffInterval : 
                Double(queueItem.retryCount)
            
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            if configuration.exponentialBackoff {
                currentBackoffInterval = min(currentBackoffInterval * backoffMultiplier, maxBackoffInterval)
            }
            
            queueItem.status = .pending
            logger.debug("Retry für Item \(queueItem.item.id) (Versuch \(queueItem.retryCount + 1))")
        } else {
            // Max Retries erreicht - Draft beibehalten
            logger.warning("Max Retries erreicht für Item \(queueItem.item.id)")
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimers() {
        stopTimers()
        
        // Save Timer für periodische Verarbeitung
        if configuration.enabled {
            saveTimer = Timer.scheduledTimer(withTimeInterval: configuration.interval, repeats: true) { [weak self] _ in
                Task {
                    await self?.checkAndProcessQueue()
                }
            }
        }
        
        // Idle Timer für verzögertes Speichern
        startIdleTimer()
    }
    
    private func stopTimers() {
        saveTimer?.invalidate()
        saveTimer = nil
        idleTimer?.invalidate()
        idleTimer = nil
    }
    
    private func restartTimers() {
        stopTimers()
        startTimers()
    }
    
    private func startIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: configuration.idleThreshold, repeats: false) { [weak self] _ in
            Task {
                await self?.processQueue()
            }
        }
    }
    
    private func checkAndProcessQueue() async {
        // Prüfe ob Items in Queue sind und verarbeite sie
        let hasItems = await MainActor.run { !queue.isEmpty }
        if hasItems {
            processQueue()
        }
    }
    
    // MARK: - Application Lifecycle
    
    func applicationWillTerminate() {
        // Finale Queue-Verarbeitung beim Beenden
        processQueue()
        
        // Alle Drafts speichern
        for queueItem in queue {
            if let data = try? JSONEncoder().encode(queueItem.item as any Encodable) {
                draftManager.saveDraft(queueItem.item, data: data)
            }
        }
        
        stopTimers()
        logger.info("AutoSaveManager beim App-Beenden heruntergefahren")
    }
    
    func applicationDidEnterBackground() {
        // Verzögerte Verarbeitung im Hintergrund
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2.0) {
            Task {
                await self.processQueue()
            }
        }
    }
    
    // MARK: - Statistics
    
    private func refreshStatistics() async {
        let queueSize = queue.count
        let totalSaves = await MainActor.run { 
            // Diese Daten würden aus einem persistenten Store kommen
            0 
        }
        
        statistics = SaveStatistics(
            totalSaves: totalSaves,
            successfulSaves: queue.filter { $0.status == .completed }.count,
            failedSaves: queue.filter { 
                if case .failed = $0.status { return true }
                return false
            }.count,
            averageSaveTime: performanceMonitor.averageSaveTime,
            lastSaveDate: nil, // Would be tracked
            queueSize: queueSize,
            longestPendingTime: queue.map { $0.age }.max() ?? 0
        )
    }
    
    // MARK: - Draft Recovery
    
    func recoverDrafts() async {
        // Alle Draft-Dateien laden und zur Queue hinzufügen
        let draftIds = await MainActor.run { Array(draftManager.drafts.keys) }
        
        for draftId in draftIds {
            // Draft-Daten laden und als dirty markieren
            if let draftData = draftManager.loadDraft(for: draftId) {
                // Item aus Draft rekonstruieren (Implementation würde vom Item-Typ abhängen)
                logger.info("Draft für Item \(draftId) wiederhergestellt")
            }
        }
    }
    
    func clearAllDrafts() {
        draftManager.clearAllDrafts()
    }
    
    // MARK: - User Interaction
    
    func forceSaveAll() async {
        guard !isProcessingQueue else { return }
        
        logger.info("Manuelles Speichern aller Items gestartet")
        processQueue()
        
        // Warten bis Queue leer ist
        while !queue.isEmpty && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        logger.info("Manuelles Speichern abgeschlossen")
    }
    
    func pauseAutoSave() {
        updateConfiguration(AutoSaveConfiguration(
            enabled: false,
            interval: configuration.interval,
            idleThreshold: configuration.idleThreshold
        ))
    }
    
    func resumeAutoSave() {
        updateConfiguration(AutoSaveConfiguration(
            enabled: true,
            interval: configuration.interval,
            idleThreshold: configuration.idleThreshold
        ))
    }
    
    // MARK: - Monitoring
    
    func getSaveMetrics() -> [String: Any] {
        [
            "queueSize": queue.count,
            "processingQueue": isProcessingQueue,
            "averageSaveTime": performanceMonitor.averageSaveTime,
            "lastSaveTime": performanceMonitor.lastSaveTime ?? 0,
            "draftsCount": draftManager.drafts.count,
            "isEnabled": isEnabled
        ]
    }
}

// MARK: - Save Errors

enum SaveError: Error {
    case unknownError
    case itemNotFound(UUID)
    case networkError
    case storageQuotaExceeded
    case encryptionFailed
    case conflictDetected
    case manualConflictResolutionRequired(any SaveableItem, any SaveableItem)
    case validationFailed(String)
    case backupFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .unknownError:
            return "Unbekannter Speicherfehler"
        case .itemNotFound(let id):
            return "Element mit ID \(id) nicht gefunden"
        case .networkError:
            return "Netzwerkfehler beim Speichern"
        case .storageQuotaExceeded:
            return "Speicherplatz-Quota überschritten"
        case .encryptionFailed:
            return "Verschlüsselung fehlgeschlagen"
        case .conflictDetected:
            return "Synchronisationskonflikt erkannt"
        case .manualConflictResolutionRequired(let local, let remote):
            return "Manuelle Konfliktlösung für Items \(local.id) und \(remote.id) erforderlich"
        case .validationFailed(let message):
            return "Validierung fehlgeschlagen: \(message)"
        case .backupFailed(let reason):
            return "Backup fehlgeschlagen: \(reason)"
        }
    }
}

// MARK: - Conflict Resolution Strategy

enum ConflictResolutionStrategy {
    case localWins
    case remoteWins
    case merge
    case manual
}

// MARK: - User Notifications Extension

extension UNUserNotificationCenter {
    func add(_ notification: UNNotificationRequest) {
        add(notification) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}

// MARK: - Notification Content Builders

extension UNUserNotificationCenter {
    static func saveSuccess(item: any SaveableItem) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Element gespeichert"
        content.body = "'\(getItemTitle(item))' wurde erfolgreich gespeichert."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        return UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    }
    
    static func saveFailure(item: any SaveableItem, error: Error) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Speicherfehler"
        content.body = "Fehler beim Speichern von '\(getItemTitle(item))': \(error.localizedDescription)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        return UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    }
    
    private static func getItemTitle(_ item: any SaveableItem) -> String {
        if let noteItem = item as? NoteItem {
            return noteItem.title
        }
        return "Unbekanntes Element"
    }
}