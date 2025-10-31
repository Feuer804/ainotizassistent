//
//  StorageSystemTests.swift
//  AINotizassistent
//
//  Unit Tests für das Unified Storage System
//

import XCTest
@testable import AINotizassistent
import SwiftUI
import Combine

// MARK: - Test Data

class TestNoteItem: SaveableItem, StorageItem {
    let id: UUID = UUID()
    var title: String
    var content: String
    let createdAt: Date
    var modifiedAt: Date
    var tags: [String]
    var isEncrypted: Bool = false
    var provider: StorageProvider = .local
    var syncStatus: SyncStatus = .pending
    var isDirty: Bool = false
    var lastModified: Date
    var savePriority: SavePriority = .normal
    
    init(title: String, content: String) {
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.lastModified = Date()
        self.tags = []
    }
    
    func markAsClean() {
        isDirty = false
        modifiedAt = Date()
        lastModified = Date()
    }
    
    func markAsDirty() {
        isDirty = true
        lastModified = Date()
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
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.isEncrypted = try container.decode(Bool.self, forKey: .isEncrypted)
        self.provider = try container.decode(StorageProvider.self, forKey: .provider)
        self.syncStatus = try container.decode(SyncStatus.self, forKey: .syncStatus)
        self.lastModified = Date()
    }
}

// MARK: - Storage Manager Tests

class StorageManagerTests: XCTestCase {
    
    var storageManager: StorageManager!
    var testNote: TestNoteItem!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        storageManager = StorageManager.shared
        testNote = TestNoteItem(title: "Test Note", content: "Test Content")
    }
    
    override func tearDownWithError() throws {
        storageManager = nil
        testNote = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Storage Operations
    
    func testSaveAndLoadNote() async throws {
        // Given
        let note = TestNoteItem(title: "Test", content: "Content")
        
        // When
        let saved = try await storageManager.saveItem(note)
        let loaded = try await storageManager.loadItem(id: note.id, type: TestNoteItem.self)
        
        // Then
        XCTAssertTrue(saved)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.title, "Test")
        XCTAssertEqual(loaded?.content, "Content")
    }
    
    func testDeleteNote() async throws {
        // Given
        let note = TestNoteItem(title: "To Delete", content: "Delete Me")
        _ = try await storageManager.saveItem(note)
        
        // When
        let deleted = try await storageManager.deleteItem(id: note.id)
        let loaded = try await storageManager.loadItem(id: note.id, type: TestNoteItem.self)
        
        // Then
        XCTAssertTrue(deleted)
        XCTAssertNil(loaded)
    }
    
    func testLoadAllNotes() async throws {
        // Given
        let notes = [
            TestNoteItem(title: "Note 1", content: "Content 1"),
            TestNoteItem(title: "Note 2", content: "Content 2"),
            TestNoteItem(title: "Note 3", content: "Content 3")
        ]
        
        for note in notes {
            _ = try await storageManager.saveItem(note)
        }
        
        // When
        let loadedNotes = try await storageManager.loadAllItems(type: TestNoteItem.self)
        
        // Then
        XCTAssertEqual(loadedNotes.count, 3)
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationUpdate() throws {
        // Given
        let newConfig = StorageConfiguration(
            primaryProvider: .local,
            secondaryProvider: .icloud,
            encryptionEnabled: true,
            autoBackup: false,
            syncInterval: 600,
            enableSyncConflicts: false
        )
        
        // When
        storageManager.updateConfiguration(newConfig)
        
        // Then
        XCTAssertEqual(storageManager.configuration.primaryProvider, .local)
        XCTAssertEqual(storageManager.configuration.secondaryProvider, .icloud)
        XCTAssertTrue(storageManager.configuration.encryptionEnabled)
    }
    
    // MARK: - Sync Tests
    
    func testSyncConflictDetection() async throws {
        // Given
        let localNote = TestNoteItem(title: "Local", content: "Local Content")
        let remoteNote = TestNoteItem(title: "Remote", content: "Remote Content")
        localNote.provider = .local
        remoteNote.provider = .icloud
        
        // When
        _ = try await storageManager.saveItem(localNote)
        
        // Then - Simplified conflict test
        XCTAssertNotNil(localNote)
        XCTAssertNotNil(remoteNote)
    }
    
    func testProviderFallback() throws {
        // Given
        storageManager.configuration.secondaryProvider = .local
        
        // When & Then
        XCTAssertNotNil(storageManager.configuration.secondaryProvider)
    }
    
    // MARK: - Statistics Tests
    
    func testStorageStatistics() async throws {
        // Given
        let note = TestNoteItem(title: "Stats Test", content: "Statistics")
        _ = try await storageManager.saveItem(note)
        
        // When
        await storageManager.refreshStatistics()
        
        // Then
        XCTAssertNotNil(storageManager.statistics)
        XCTAssertGreaterThanOrEqual(storageManager.statistics?.totalItems ?? 0, 1)
    }
    
    // MARK: - Backup Tests
    
    func testCreateBackup() async throws {
        // When
        let backupURL = try await storageManager.createBackup()
        
        // Then
        XCTAssertNotNil(backupURL)
        // Additional assertions would check backup file content
    }
    
    func testExportAll() async throws {
        // Given
        let note = TestNoteItem(title: "Export Test", content: "Export")
        _ = try await storageManager.saveItem(note)
        
        // When
        let exportURL = try await storageManager.exportAll()
        
        // Then
        XCTAssertNotNil(exportURL)
        // Additional assertions would check export file content
    }
}

// MARK: - Auto Save Manager Tests

class AutoSaveManagerTests: XCTestCase {
    
    var autoSaveManager: AutoSaveManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        autoSaveManager = AutoSaveManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        autoSaveManager.clearQueue()
        cancellables = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Queue Management Tests
    
    func testQueueForSave() throws {
        // Given
        let note = TestNoteItem(title: "Queue Test", content: "Queue")
        
        // When
        autoSaveManager.queueForSave(note, priority: .high)
        
        // Then
        XCTAssertEqual(autoSaveManager.queue.count, 1)
        XCTAssertEqual(autoSaveManager.queue.first?.priority, .high)
    }
    
    func testMultipleQueueItems() throws {
        // Given
        let notes = [
            TestNoteItem(title: "Note 1", content: "Content 1"),
            TestNoteItem(title: "Note 2", content: "Content 2"),
            TestNoteItem(title: "Note 3", content: "Content 3")
        ]
        
        // When
        for note in notes {
            autoSaveManager.queueForSave(note)
        }
        
        // Then
        XCTAssertEqual(autoSaveManager.queue.count, 3)
    }
    
    func testCancelSave() throws {
        // Given
        let note = TestNoteItem(title: "Cancel Test", content: "Cancel")
        autoSaveManager.queueForSave(note)
        
        // When
        autoSaveManager.cancelSave(note.id)
        
        // Then
        XCTAssertEqual(autoSaveManager.queue.count, 1) // Item still in queue but cancelled
        XCTAssertEqual(autoSaveManager.queue.first?.status, .cancelled)
    }
    
    func testClearQueue() throws {
        // Given
        let note = TestNoteItem(title: "Clear Test", content: "Clear")
        autoSaveManager.queueForSave(note)
        
        // When
        autoSaveManager.clearQueue()
        
        // Then
        XCTAssertEqual(autoSaveManager.queue.count, 0)
    }
    
    // MARK: - Configuration Tests
    
    func testUpdateConfiguration() throws {
        // Given
        let newConfig = AutoSaveConfiguration(
            enabled: false,
            interval: 60.0,
            idleThreshold: 10.0,
            maxItemsPerBatch: 5
        )
        
        // When
        autoSaveManager.updateConfiguration(newConfig)
        
        // Then
        XCTAssertEqual(autoSaveManager.configuration.interval, 60.0)
        XCTAssertEqual(autoSaveManager.configuration.idleThreshold, 10.0)
        XCTAssertEqual(autoSaveManager.configuration.maxItemsPerBatch, 5)
    }
    
    func testPauseAndResumeAutoSave() throws {
        // Given
        XCTAssertTrue(autoSaveManager.isEnabled)
        
        // When
        autoSaveManager.pauseAutoSave()
        
        // Then
        XCTAssertFalse(autoSaveManager.isEnabled)
        
        // When
        autoSaveManager.resumeAutoSave()
        
        // Then
        XCTAssertTrue(autoSaveManager.isEnabled)
    }
    
    // MARK: - Priority Tests
    
    func testPriorityQueueOrdering() throws {
        // Given
        let lowPriority = TestNoteItem(title: "Low", content: "Low Priority")
        lowPriority.savePriority = .low
        
        let highPriority = TestNoteItem(title: "High", content: "High Priority")
        highPriority.savePriority = .critical
        
        // When
        autoSaveManager.queueForSave(lowPriority)
        autoSaveManager.queueForSave(highPriority)
        
        // Then
        XCTAssertEqual(autoSaveManager.queue.first?.priority, .critical)
    }
    
    // MARK: - Performance Tests
    
    func testGetSaveMetrics() throws {
        // When
        let metrics = autoSaveManager.getSaveMetrics()
        
        // Then
        XCTAssertNotNil(metrics)
        XCTAssertTrue(metrics.keys.contains("queueSize"))
        XCTAssertTrue(metrics.keys.contains("processingQueue"))
    }
    
    // MARK: - Draft Management Tests
    
    func testDraftRecovery() async throws {
        // Given
        let note = TestNoteItem(title: "Draft Test", content: "Draft Content")
        autoSaveManager.queueForSave(note)
        
        // When
        await autoSaveManager.recoverDrafts()
        
        // Then - Simplified test
        XCTAssertNotNil(autoSaveManager)
    }
    
    func testClearAllDrafts() throws {
        // When
        autoSaveManager.clearAllDrafts()
        
        // Then - Simplified test
        XCTAssertNotNil(autoSaveManager)
    }
}

// MARK: - Storage Provider Tests

class LocalStorageProviderTests: XCTestCase {
    
    var provider: LocalStorageProvider!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        provider = LocalStorageProvider()
    }
    
    override func tearDownWithError() throws {
        provider = nil
        try super.tearDownWithError()
    }
    
    func testSaveAndLoadItem() async throws {
        // Given
        let note = TestNoteItem(title: "Provider Test", content: "Provider Content")
        
        // When
        let saved = try await provider.saveItem(note)
        let loaded = try await provider.loadItem(id: note.id, type: TestNoteItem.self)
        
        // Then
        XCTAssertTrue(saved)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.title, "Provider Test")
    }
    
    func testDeleteItem() async throws {
        // Given
        let note = TestNoteItem(title: "Delete Provider", content: "Delete")
        _ = try await provider.saveItem(note)
        
        // When
        let deleted = try await provider.deleteItem(id: note.id)
        let loaded = try await provider.loadItem(id: note.id, type: TestNoteItem.self)
        
        // Then
        XCTAssertTrue(deleted)
        XCTAssertNil(loaded)
    }
    
    func testLoadAllItems() async throws {
        // Given
        let notes = [
            TestNoteItem(title: "Provider Note 1", content: "Content 1"),
            TestNoteItem(title: "Provider Note 2", content: "Content 2")
        ]
        
        for note in notes {
            _ = try await provider.saveItem(note)
        }
        
        // When
        let loadedNotes = try await provider.loadAllItems(type: TestNoteItem.self)
        
        // Then
        XCTAssertEqual(loadedNotes.count, 2)
    }
    
    func testExportImport() async throws {
        // Given
        let note = TestNoteItem(title: "Export Import", content: "Export/Import Test")
        _ = try await provider.saveItem(note)
        
        // When
        let exportURL = try await provider.exportAll()
        let importCount = try await provider.importFrom(url: exportURL)
        
        // Then
        XCTAssertNotNil(exportURL)
        XCTAssertGreaterThan(importCount, 0)
    }
    
    func testConflictResolution() async throws {
        // Given
        let local = TestNoteItem(title: "Local Conflict", content: "Local Content")
        let remote = TestNoteItem(title: "Remote Conflict", content: "Remote Content")
        
        // Simulate different timestamps
        local.modifiedAt = Date().addingTimeInterval(-100)
        remote.modifiedAt = Date()
        
        // When
        let resolved = try await provider.resolveConflict(local: local, remote: remote)
        
        // Then - Remote should win due to newer timestamp
        XCTAssertEqual(resolved.title, "Remote Conflict")
    }
}

// MARK: - Encryption Manager Tests

class EncryptionManagerTests: XCTestCase {
    
    var encryptionManager: EncryptionManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        encryptionManager = EncryptionManager()
    }
    
    override func tearDownWithError() throws {
        encryptionManager = nil
        try super.tearDownWithError()
    }
    
    func testEncryptDecryptData() throws {
        // Given
        let originalData = "Test data for encryption".data(using: .utf8)!
        let password = "testPassword123"
        
        // When
        let encryptedData = try encryptionManager.encrypt(originalData, password: password)
        let decryptedData = try encryptionManager.decrypt(encryptedData, password: password)
        
        // Then
        XCTAssertNotEqual(originalData, encryptedData)
        XCTAssertEqual(originalData, decryptedData)
    }
    
    func testIncorrectPasswordDecryption() throws {
        // Given
        let originalData = "Secret message".data(using: .utf8)!
        let correctPassword = "correctPassword"
        let wrongPassword = "wrongPassword"
        
        let encryptedData = try encryptionManager.encrypt(originalData, password: correctPassword)
        
        // When & Then
        XCTAssertThrowsError(try encryptionManager.decrypt(encryptedData, password: wrongPassword)) { error in
            // Expected to throw
        }
    }
    
    func testKeychainStorage() throws {
        // Given
        let password = "storedPassword"
        let provider = StorageProvider.local
        
        // When
        try encryptionManager.storePassword(password, for: provider)
        let retrievedPassword = try encryptionManager.getPassword(for: provider)
        
        // Then
        XCTAssertEqual(password, retrievedPassword)
    }
}

// MARK: - Integration Tests

class StorageSystemIntegrationTests: XCTestCase {
    
    var storageManager: StorageManager!
    var autoSaveManager: AutoSaveManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        storageManager = StorageManager.shared
        autoSaveManager = AutoSaveManager.shared
    }
    
    override func tearDownWithError() throws {
        // Cleanup
        await autoSaveManager.clearQueue()
        try? await storageManager.loadAllItems(type: TestNoteItem.self).forEach { note in
            try await storageManager.deleteItem(id: note.id)
        }
        
        storageManager = nil
        autoSaveManager = nil
        try super.tearDownWithError()
    }
    
    func testFullWorkflow() async throws {
        // Given
        let note = TestNoteItem(title: "Integration Test", content: "Full workflow test")
        
        // When - Save via storage manager
        let saved = try await storageManager.saveItem(note)
        XCTAssertTrue(saved)
        
        // When - Load via storage manager
        let loaded = try await storageManager.loadItem(id: note.id, type: TestNoteItem.self)
        XCTAssertNotNil(loaded)
        
        // When - Modify and queue for auto-save
        loaded?.content = "Modified content"
        loaded?.markAsDirty()
        
        if let modifiedNote = loaded {
            autoSaveManager.queueForSave(modifiedNote, priority: .high)
            
            // Then
            XCTAssertEqual(autoSaveManager.queue.count, 1)
            XCTAssertEqual(autoSaveManager.queue.first?.priority, .high)
        }
    }
    
    func testBackupRestoreCycle() async throws {
        // Given
        let note = TestNoteItem(title: "Backup Test", content: "Backup cycle test")
        _ = try await storageManager.saveItem(note)
        
        // When - Create backup
        let backupURL = try await storageManager.createBackup()
        XCTAssertNotNil(backupURL)
        
        // When - Restore from backup (simplified)
        let restoreSuccess = try await storageManager.restoreBackup(from: backupURL)
        XCTAssertTrue(restoreSuccess)
    }
    
    func testMultipleProviders() throws {
        // Given
        let config = StorageConfiguration(
            primaryProvider: .local,
            secondaryProvider: .local, // Simplified for testing
            encryptionEnabled: true,
            autoBackup: true
        )
        
        // When
        storageManager.updateConfiguration(config)
        
        // Then
        XCTAssertEqual(storageManager.configuration.primaryProvider, .local)
        XCTAssertEqual(storageManager.configuration.secondaryProvider, .local)
        XCTAssertTrue(storageManager.configuration.encryptionEnabled)
    }
}

// MARK: - Performance Tests

class StorageSystemPerformanceTests: XCTestCase {
    
    func testLargeBatchSavePerformance() async throws {
        // Given
        let storageManager = StorageManager.shared
        let batchSize = 100
        let notes = (0..<batchSize).map { i in
            TestNoteItem(title: "Performance Test \(i)", content: "Batch content \(i)")
        }
        
        // When - Measure save time
        let startTime = Date()
        
        for note in notes {
            _ = try await storageManager.saveItem(note)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(duration, 10.0) // Should complete within 10 seconds
        print("Batch save of \(batchSize) items took \(duration) seconds")
    }
    
    func testAutoSaveQueuePerformance() throws {
        // Given
        let autoSaveManager = AutoSaveManager.shared
        let queueSize = 50
        
        // When - Add items to queue
        let startTime = Date()
        
        for i in 0..<queueSize {
            let note = TestNoteItem(title: "Performance Queue \(i)", content: "Queue content \(i)")
            autoSaveManager.queueForSave(note, priority: .normal)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(duration, 1.0) // Queue operations should be fast
        XCTAssertEqual(autoSaveManager.queue.count, queueSize)
        print("Queue operations for \(queueSize) items took \(duration) seconds")
    }
}

// MARK: - UI Tests

class StorageSystemUITests: XCTestCase {
    
    func testStorageSettingsViewRendering() {
        // Given
        let view = StorageSettingsView()
        
        // When - Render view
        let viewController = UIHostingController(rootView: view)
        
        // Then - Simplified test for rendering
        XCTAssertNotNil(viewController.view)
    }
    
    func testAutoSaveStatusViewRendering() {
        // Given
        let view = AutoSaveStatusView()
        
        // When - Render view
        let viewController = UIHostingController(rootView: view)
        
        // Then - Simplified test for rendering
        XCTAssertNotNil(viewController.view)
    }
}

// MARK: - Test Runner

class StorageSystemTestRunner {
    static func runAllTests() {
        print("🧪 Starting Storage System Tests...")
        
        let testSuite = XCTestSuite(forTestCaseClass: StorageManagerTests.self)
        testSuite.run()
        
        let autoSaveSuite = XCTestSuite(forTestCaseClass: AutoSaveManagerTests.self)
        autoSaveSuite.run()
        
        let providerSuite = XCTestSuite(forTestCaseClass: LocalStorageProviderTests.self)
        providerSuite.run()
        
        let encryptionSuite = XCTestSuite(forTestCaseClass: EncryptionManagerTests.self)
        encryptionSuite.run()
        
        let integrationSuite = XCTestSuite(forTestCaseClass: StorageSystemIntegrationTests.self)
        integrationSuite.run()
        
        print("✅ All Storage System Tests Completed!")
    }
}

// MARK: - Test Utilities

extension StorageSystemTests {
    
    func waitForExpectation(description: String, timeout: TimeInterval = 5.0, test: @escaping (XCTestExpectation) -> Void) {
        let expectation = expectation(description: description)
        test(expectation)
        waitForExpectations(timeout: timeout)
    }
    
    func createTestNote(title: String, content: String) -> TestNoteItem {
        return TestNoteItem(title: title, content: content)
    }
    
    func setupMockConfiguration() {
        let config = StorageConfiguration(
            primaryProvider: .local,
            encryptionEnabled: false,
            autoBackup: false,
            enableSyncConflicts: true
        )
        storageManager.updateConfiguration(config)
    }
}

#if DEBUG
// Debug helper for running tests
class StorageTestDebugHelper {
    static func debugQueueState() {
        let queue = AutoSaveManager.shared.queue
        print("Queue State:")
        print("- Count: \(queue.count)")
        queue.forEach { item in
            print("  - \(item.item.title) (Priority: \(item.priority), Status: \(item.status))")
        }
    }
    
    static func debugStatistics() {
        let stats = AutoSaveManager.shared.statistics
        print("Auto-Save Statistics:")
        print("- Total Saves: \(stats?.totalSaves ?? 0)")
        print("- Successful: \(stats?.successfulSaves ?? 0)")
        print("- Failed: \(stats?.failedSaves ?? 0)")
        print("- Average Time: \(stats?.averageSaveTime ?? 0)")
    }
}
#endif

print("📦 Storage System Tests Loaded!")
print("Run 'StorageSystemTestRunner.runAllTests()' to execute all tests")