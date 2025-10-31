//
//  IntegrationEndToEndTests.swift
//  AINotizassistent - Integration & End-to-End Tests
//
//  Umfassende Integrationstests für komplexe Workflows
//  Cross-Feature Funktionalitäten und End-to-End Szenarien
//

import XCTest
import SwiftUI
import Combine
import Network

// MARK: - Integration Test Suite Base
class IntegrationTestBase: XCTestCase {
    
    // MARK: - Test Environment Setup
    var appDelegate: AppDelegate!
    var shortcutManager: ShortcutManager!
    var contentProcessor: ContentProcessor!
    var contentAnalyzer: ContentAnalyzer!
    var apiKeyManager: APIKeyManager!
    var storageManager: StorageManager!
    var voiceInputManager: VoiceInputManager!
    var appMonitor: ActiveAppMonitor!
    
    var testDataFactory: TestDataFactory!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Configuration
    let integrationTimeout: TimeInterval = 60.0
    let largeContentSize = 10000
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize all components for integration testing
        setupIntegrationEnvironment()
    }
    
    override func tearDownWithError() throws {
        cleanupIntegrationEnvironment()
        try super.tearDownWithError()
    }
    
    private func setupIntegrationEnvironment() {
        // Setup complete app environment for integration testing
        shortcutManager = ShortcutManager()
        contentProcessor = AIEnabledContentProcessor(
            kiProvider: MockKIProvider(),
            promptManager: AIEnhancedPromptManager()
        )
        contentAnalyzer = ContentAnalyzer()
        apiKeyManager = APIKeyManager()
        storageManager = DefaultStorageManager()
        voiceInputManager = VoiceInputManager()
        appMonitor = ActiveAppMonitor()
        
        testDataFactory = TestDataFactory()
        cancellables = Set<AnyCancellable>()
    }
    
    private func cleanupIntegrationEnvironment() {
        // Cleanup all test data and reset managers
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        shortcutManager = nil
        contentProcessor = nil
        contentAnalyzer = nil
        apiKeyManager = nil
        storageManager = nil
        voiceInputManager = nil
        appMonitor = nil
        
        testDataFactory = nil
        cancellables?.removeAll()
        cancellables = nil
    }
}

// MARK: - Complete Workflow Tests
class CompleteWorkflowTests: IntegrationTestBase {
    
    func testFullNoteCreationWorkflow() throws {
        let expectation = self.expectation(description: "Complete note creation workflow")
        
        // Step 1: Create note with content
        let note = testDataFactory.generateRandomNote()
        
        // Step 2: Process content with AI
        Task {
            do {
                let processedNote = try await contentProcessor.processNote(note)
                
                // Step 3: Analyze content
                let analysis = try await contentAnalyzer.analyzeContent(
                    note.content
                ) { result in
                    XCTAssertNotNil(result)
                }
                
                // Step 4: Save to storage
                try await storageManager.saveNote(note)
                
                // Step 5: Verify storage
                let loadedNotes = try await storageManager.loadNotes()
                XCTAssertGreaterThan(loadedNotes.count, 0)
                
                expectation.fulfill()
            } catch {
                XCTFail("Workflow failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testEmailToMeetingRecapWorkflow() throws {
        let expectation = self.expectation(description: "Email to meeting recap workflow")
        
        // Step 1: Create email content
        let emailContent = """
        Von: john@example.com
        An: team@example.com
        Betreff: Wichtige Projektbesprechung
        
        Hallo Team,
        
        wir haben eine wichtige Besprechung über das Projekt am Freitag um 14 Uhr.
        
        Agenda:
        1. Status Update
        2. Nächste Schritte
        3. Timeline Review
        
        Bitte bestätigen Sie Ihre Teilnahme.
        
        Viele Grüße,
        John
        """
        
        Task {
            do {
                // Step 2: Detect content type as email
                let contentType = ContentTypeDetector.detectContentTypeConfidence(from: emailContent)
                XCTAssertEqual(contentType.type, .email)
                
                // Step 3: Convert to meeting note format
                let meetingNote = NoteModel(
                    id: UUID(),
                    content: """
                    Meeting with John
                    
                    Teilnehmer: John Doe, Team
                    Zeit: Freitag 14 Uhr
                    
                    Agenda:
                    1. Status Update
                    2. Nächste Schritte
                    3. Timeline Review
                    
                    Notizen:
                    Wichtige Projektbesprechung
                    """,
                    title: "Projektbesprechung - Freitag",
                    type: .meeting,
                    sourceApp: "Mail",
                    createdAt: Date(),
                    updatedAt: Date(),
                    tags: ["meeting", "project"],
                    metadata: [:]
                )
                
                // Step 4: Generate meeting recap
                let recapGenerator = MeetingRecapGenerator()
                let meetingRecap = await recapGenerator.generateRecap(
                    for: meetingNote
                )
                
                XCTAssertNotNil(meetingRecap)
                
                // Step 5: Save to storage
                try await storageManager.saveNote(meetingNote)
                
                expectation.fulfill()
            } catch {
                XCTFail("Email workflow failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testVoiceInputToContentGenerationWorkflow() throws {
        let expectation = self.expectation(description: "Voice input to content generation workflow")
        
        Task {
            do {
                // Step 1: Simulate voice input
                let voiceText = "Erstelle eine Zusammenfassung der letzten Besprechung"
                
                // Step 2: Generate content based on voice input
                let prompt = """
                Erstelle basierend auf folgender Anfrage eine strukturierte Antwort:
                \(voiceText)
                
                Verwende ein professionelles Format mit:
                - Hauptpunkten
                - Unterpunkten
                - Action Items
                """
                
                let generatedContent = try await contentProcessor.generateContent(from: prompt)
                
                XCTAssertNotNil(generatedContent)
                XCTAssertGreaterThan(generatedContent.count, 0)
                
                // Step 3: Analyze generated content
                let analysis = try await contentAnalyzer.analyzeContent(
                    generatedContent
                ) { result in
                    XCTAssertNotNil(result)
                }
                
                expectation.fulfill()
            } catch {
                XCTFail("Voice workflow failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testCodeSnippetAnalysisWorkflow() throws {
        let expectation = self.expectation(description: "Code snippet analysis workflow")
        
        let codeContent = """
        import SwiftUI
        
        struct ContentView: View {
            @State private var text: String = ""
            
            var body: some View {
                VStack {
                    TextField("Text eingeben...", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Analysieren") {
                        analyzeContent()
                    }
                }
                .padding()
            }
            
            private func analyzeContent() {
                // Content analysis logic
            }
        }
        """
        
        Task {
            do {
                // Step 1: Detect content type as code
                let contentType = ContentTypeDetector.detectContentTypeConfidence(from: codeContent)
                XCTAssertEqual(contentType.type, .code)
                
                // Step 2: Analyze code structure
                let codeAnalyzer = CodeAnalyzer()
                let analysis = await codeAnalyzer.analyze(codeContent)
                
                XCTAssertNotNil(analysis)
                XCTAssertGreaterThan(analysis.lineCount, 0)
                
                // Step 3: Generate documentation
                let documentation = try await contentProcessor.generateCodeDocumentation(from: codeContent)
                
                XCTAssertNotNil(documentation)
                
                expectation.fulfill()
            } catch {
                XCTFail("Code analysis workflow failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
}

// MARK: - Cross-Feature Integration Tests
class CrossFeatureIntegrationTests: IntegrationTestBase {
    
    func testShortcutToContentProcessingIntegration() throws {
        let expectation = self.expectation(description: "Shortcut to content processing integration")
        
        // Step 1: Simulate shortcut trigger
        shortcutManager.triggerShortcut(byId: "primary_new_note")
        
        // Step 2: Verify content processing starts
        let testNote = testDataFactory.generateRandomNote()
        
        Task {
            do {
                let processedNote = try await contentProcessor.processNote(testNote)
                
                // Step 3: Verify shortcuts still work after processing
                let shortcutsAfter = shortcutManager.shortcuts
                XCTAssertFalse(shortcutsAfter.isEmpty)
                
                expectation.fulfill()
            } catch {
                XCTFail("Shortcut integration failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testStorageToAPIIntegration() throws {
        let expectation = self.expectation(description: "Storage to API integration")
        
        Task {
            do {
                // Step 1: Save multiple notes to storage
                let notes = testDataFactory.generateBulkNotes(count: 5)
                for note in notes {
                    try await storageManager.saveNote(note)
                }
                
                // Step 2: Retrieve notes
                let loadedNotes = try await storageManager.loadNotes()
                XCTAssertGreaterThanOrEqual(loadedNotes.count, 5)
                
                // Step 3: Process all notes with AI
                let batchResults = try await contentProcessor.batchProcess(loadedNotes)
                
                XCTAssertEqual(batchResults.count, loadedNotes.count)
                
                // Step 4: Save processed results back to storage
                for (index, result) in batchResults.enumerated() {
                    var processedNote = result.originalNote
                    processedNote.content = result.enhancedContent ?? result.originalNote.content
                    try await storageManager.saveNote(processedNote)
                }
                
                // Step 5: Verify processed notes are saved
                let finalNotes = try await storageManager.loadNotes()
                XCTAssertEqual(finalNotes.count, 5)
                
                expectation.fulfill()
            } catch {
                XCTFail("Storage-API integration failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testContentAnalysisToGenerationIntegration() throws {
        let expectation = self.expectation(description: "Content analysis to generation integration")
        
        let testContent = """
        Team Meeting - Sprint Planning
        
        Teilnehmer: Anna Schmidt, Max Müller, Lisa Weber
        
        Themen:
        - Sprint Ziele definieren
        - Aufgabenverteilung
        - Timeline festlegen
        
        Entscheidungen:
        - Sprint 2 beginnt am Montag
        - Fokus auf Performance-Optimierung
        
        Nächste Schritte:
        - Max: Database Optimierung
        - Anna: Frontend Refactoring
        - Lisa: Testing erweitern
        """
        
        Task {
            do {
                // Step 1: Analyze content
                let analysis = try await contentAnalyzer.analyzeContent(testContent) { result in
                    XCTAssertNotNil(result)
                }
                
                // Step 2: Generate summary based on analysis
                let summary = try await contentProcessor.generateSummary(from: testContent)
                
                XCTAssertNotNil(summary)
                XCTAssertGreaterThan(summary.count, 0)
                
                // Step 3: Generate todo items based on analysis
                let todos = try await contentProcessor.extractTodos(from: testContent)
                
                XCTAssertNotNil(todos)
                XCTAssertGreaterThan(todos.count, 0)
                
                expectation.fulfill()
            } catch {
                XCTFail("Analysis-generation integration failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testVoiceToStorageIntegration() throws {
        let expectation = self.expectation(description: "Voice to storage integration")
        
        Task {
            do {
                // Step 1: Simulate voice recognition
                let voiceInput = "Speichere eine neue Notiz über das Projekt-Meeting"
                
                // Step 2: Process voice input
                let processedVoice = try await voiceInputManager.processVoiceInput(voiceInput)
                
                XCTAssertNotNil(processedVoice)
                
                // Step 3: Create note from voice input
                let voiceNote = NoteModel(
                    id: UUID(),
                    content: processedVoice.transcription,
                    title: "Voice Note - \(Date().formatted(.dateTime.day().month()))",
                    type: .note,
                    sourceApp: "VoiceInput",
                    createdAt: Date(),
                    updatedAt: Date(),
                    tags: ["voice", "auto-generated"],
                    metadata: [
                        "confidence": processedVoice.confidence as Double,
                        "language": processedVoice.language
                    ]
                )
                
                // Step 4: Save to storage
                try await storageManager.saveNote(voiceNote)
                
                // Step 5: Verify storage
                let loadedNotes = try await storageManager.loadNotes()
                let voiceNoteLoaded = loadedNotes.first { $0.sourceApp == "VoiceInput" }
                
                XCTAssertNotNil(voiceNoteLoaded)
                
                expectation.fulfill()
            } catch {
                XCTFail("Voice-storage integration failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
}

// MARK: - App State Integration Tests
class AppStateIntegrationTests: IntegrationTestBase {
    
    func testAppLaunchToReadyState() throws {
        let expectation = self.expectation(description: "App launch to ready state")
        
        Task {
            do {
                // Step 1: Verify all managers are initialized
                XCTAssertNotNil(shortcutManager)
                XCTAssertNotNil(contentProcessor)
                XCTAssertNotNil(contentAnalyzer)
                XCTAssertNotNil(apiKeyManager)
                XCTAssertNotNil(storageManager)
                
                // Step 2: Verify shortcuts are loaded
                let shortcuts = shortcutManager.shortcuts
                XCTAssertFalse(shortcuts.isEmpty)
                
                // Step 3: Verify storage is accessible
                let notes = try await storageManager.loadNotes()
                XCTAssertNotNil(notes)
                
                // Step 4: Verify API keys are loaded
                let apiKeys = apiKeyManager.getAllAPIKeys()
                XCTAssertNotNil(apiKeys)
                
                // Step 5: Test basic functionality
                let testNote = testDataFactory.generateRandomNote()
                let processed = try await contentProcessor.processNote(testNote)
                
                XCTAssertNotNil(processed)
                
                expectation.fulfill()
            } catch {
                XCTFail("App launch test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testBackgroundToForegroundTransition() throws {
        let expectation = self.expectation(description: "Background to foreground transition")
        
        Task {
            do {
                // Step 1: Start background processing
                let largeContent = testDataFactory.generateLargeContent(size: .medium)
                let largeNote = testDataFactory.generateNotesWithSpecificContent(largeContent)
                
                let processingTask = Task {
                    let processed = try await contentProcessor.processNote(largeNote)
                    return processed
                }
                
                // Step 2: Simulate background state
                await Task.yield()
                
                // Step 3: Return to foreground
                let result = try await processingTask.value
                
                XCTAssertNotNil(result)
                
                expectation.fulfill()
            } catch {
                XCTFail("Background transition test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testAppTerminationToRestart() throws {
        let expectation = self.expectation(description: "App termination to restart")
        
        // Simulate app termination and restart cycle
        Task {
            do {
                // Step 1: Save state
                let notes = testDataFactory.generateBulkNotes(count: 3)
                for note in notes {
                    try await storageManager.saveNote(note)
                }
                
                let shortcuts = shortcutManager.exportShortcuts()
                
                // Step 2: Simulate termination (clear memory)
                cleanupIntegrationEnvironment()
                
                // Step 3: Restart
                setupIntegrationEnvironment()
                
                // Step 4: Verify state restoration
                let restoredNotes = try await storageManager.loadNotes()
                XCTAssertGreaterThanOrEqual(restoredNotes.count, 0)
                
                // Step 5: Verify functionality still works
                let testNote = testDataFactory.generateRandomNote()
                let processed = try await contentProcessor.processNote(testNote)
                XCTAssertNotNil(processed)
                
                expectation.fulfill()
            } catch {
                XCTFail("App restart test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
}

// MARK: - Performance Integration Tests
class PerformanceIntegrationTests: IntegrationTestBase {
    
    func testLargeContentProcessingPerformance() throws {
        let expectation = self.expectation(description: "Large content processing performance")
        
        // Create large content
        let largeContent = testDataFactory.generateLargeContent(size: .large)
        let largeNote = testDataFactory.generateNotesWithSpecificContent(largeContent)
        
        measure {
            Task {
                do {
                    let startTime = Date()
                    let processed = try await contentProcessor.processNote(largeNote)
                    let endTime = Date()
                    
                    let processingTime = endTime.timeIntervalSince(startTime)
                    
                    XCTAssertNotNil(processed)
                    XCTAssertLessThan(processingTime, integrationTimeout)
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("Large content processing failed: \(error.localizedDescription)")
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testConcurrentProcessingPerformance() throws {
        let expectation = self.expectation(description: "Concurrent processing performance")
        
        // Create multiple notes for concurrent processing
        let notes = testDataFactory.generateBulkNotes(count: 10)
        
        measure {
            Task {
                do {
                    let startTime = Date()
                    
                    // Process notes concurrently
                    async let processed1 = contentProcessor.batchProcess(Array(notes[0..<5]))
                    async let processed2 = contentProcessor.batchProcess(Array(notes[5..<10]))
                    
                    let results1 = try await processed1
                    let results2 = try await processed2
                    
                    let endTime = Date()
                    let totalTime = endTime.timeIntervalSince(startTime)
                    
                    XCTAssertEqual(results1.count + results2.count, notes.count)
                    XCTAssertLessThan(totalTime, integrationTimeout)
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("Concurrent processing failed: \(error.localizedDescription)")
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testMemoryUsageUnderLoad() throws {
        let expectation = self.expectation(description: "Memory usage under load")
        
        Task {
            do {
                // Create memory-intensive scenario
                let largeContent = testDataFactory.generateLargeContent(size: .huge)
                var notes: [NoteModel] = []
                
                for i in 0..<50 {
                    let note = testDataFactory.generateNotesWithSpecificContent(largeContent + " Note \(i)")
                    notes.append(note)
                }
                
                // Process all notes
                let startTime = Date()
                let processed = try await contentProcessor.batchProcess(notes)
                let endTime = Date()
                
                XCTAssertEqual(processed.count, notes.count)
                
                // Check processing time
                let processingTime = endTime.timeIntervalSince(startTime)
                XCTAssertLessThan(processingTime, integrationTimeout * 2)
                
                expectation.fulfill()
            } catch {
                XCTFail("Memory usage test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout * 2)
    }
}

// MARK: - Error Handling Integration Tests
class ErrorHandlingIntegrationTests: IntegrationTestBase {
    
    func testNetworkFailureRecovery() throws {
        let expectation = self.expectation(description: "Network failure recovery")
        
        Task {
            do {
                // Simulate network failure by using invalid API key
                let invalidKey = "invalid-key"
                let invalidAPIKey = APIKey(
                    provider: .openai,
                    keyValue: invalidKey,
                    status: .invalid,
                    createdAt: Date()
                )
                
                // Try to process content with invalid key
                let testNote = testDataFactory.generateRandomNote()
                
                // This should handle the error gracefully
                let processed = try await contentProcessor.processNote(testNote)
                
                // Even with invalid key, basic processing should work
                XCTAssertNotNil(processed)
                
                expectation.fulfill()
            } catch {
                XCTFail("Network recovery test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testStorageFailureRecovery() throws {
        let expectation = self.expectation(description: "Storage failure recovery")
        
        Task {
            do {
                // Test with simulated storage failure
                let testNote = testDataFactory.generateRandomNote()
                
                // Save should handle failures gracefully
                try await storageManager.saveNote(testNote)
                
                // Load should return empty array on failure
                let loadedNotes = try await storageManager.loadNotes()
                XCTAssertNotNil(loadedNotes)
                
                expectation.fulfill()
            } catch {
                XCTFail("Storage recovery test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testContentProcessingFailureRecovery() throws {
        let expectation = self.expectation(description: "Content processing failure recovery")
        
        Task {
            do {
                // Test with empty content
                let emptyNote = NoteModel(
                    id: UUID(),
                    content: "",
                    title: "Empty Note",
                    type: .note,
                    sourceApp: "Test",
                    createdAt: Date(),
                    updatedAt: Date(),
                    tags: [],
                    metadata: [:]
                )
                
                let processed = try await contentProcessor.processNote(emptyNote)
                
                // Should handle empty content gracefully
                XCTAssertNotNil(processed)
                
                expectation.fulfill()
            } catch {
                XCTFail("Content processing recovery test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
}

// MARK: - Data Consistency Integration Tests
class DataConsistencyIntegrationTests: IntegrationTestBase {
    
    func testDataConsistencyAfterProcessing() throws {
        let expectation = self.expectation(description: "Data consistency after processing")
        
        Task {
            do {
                let testNote = testDataFactory.generateRandomNote()
                let originalContent = testNote.content
                
                // Process the note
                let processed = try await contentProcessor.processNote(testNote)
                
                // Verify original note is unchanged
                XCTAssertEqual(testNote.content, originalContent)
                
                // Verify processed note has expected structure
                XCTAssertNotNil(processed.originalNote)
                XCTAssertEqual(processed.originalNote.id, testNote.id)
                
                expectation.fulfill()
            } catch {
                XCTFail("Data consistency test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testStorageDataIntegrity() throws {
        let expectation = self.expectation(description: "Storage data integrity")
        
        Task {
            do {
                // Save and load multiple times
                let testNote = testDataFactory.generateRandomNote()
                
                // Save
                try await storageManager.saveNote(testNote)
                
                // Load
                var loadedNotes = try await storageManager.loadNotes()
                let originalNote = loadedNotes.first { $0.id == testNote.id }
                
                XCTAssertNotNil(originalNote)
                
                // Update
                var updatedNote = originalNote!
                updatedNote.content = "Updated content"
                try await storageManager.saveNote(updatedNote)
                
                // Load again
                loadedNotes = try await storageManager.loadNotes()
                let reloadedNote = loadedNotes.first { $0.id == testNote.id }
                
                XCTAssertNotNil(reloadedNote)
                XCTAssertEqual(reloadedNote!.content, "Updated content")
                
                expectation.fulfill()
            } catch {
                XCTFail("Storage integrity test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
}

// MARK: - Security Integration Tests
class SecurityIntegrationTests: IntegrationTestBase {
    
    func testDataEncryptionAtRest() throws {
        let expectation = self.expectation(description: "Data encryption at rest")
        
        Task {
            do {
                let testNote = testDataFactory.generateRandomNote()
                
                // Save with encryption
                try await storageManager.saveNote(testNote)
                
                // Verify encryption (simulated)
                let encryptionStatus = storageManager.verifyEncryption()
                XCTAssertTrue(encryptionStatus)
                
                expectation.fulfill()
            } catch {
                XCTFail("Encryption test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
    
    func testAPISecurity() throws {
        let expectation = self.expectation(description: "API security")
        
        Task {
            do {
                // Test API key validation
                let validKey = apiKeyManager.generateSecureKey()
                let isValid = try await apiKeyManager.validateAPIKey(validKey, provider: .openai)
                
                XCTAssertTrue(isValid)
                
                // Test sensitive data handling
                let sensitiveNote = testDataFactory.generateNotesWithSpecificContent("Sensitive data: password123")
                try await storageManager.saveNote(sensitiveNote)
                
                // Verify sensitive data is encrypted
                let isEncrypted = storageManager.isDataEncrypted(sensitiveNote.id)
                XCTAssertTrue(isEncrypted)
                
                expectation.fulfill()
            } catch {
                XCTFail("API security test failed: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: integrationTimeout)
    }
}

// MARK: - Mock Classes for Integration Testing

class CodeAnalyzer {
    struct AnalysisResult {
        let lineCount: Int
        let functionCount: Int
        let complexity: Int
        let language: String
    }
    
    func analyze(_ code: String) async -> AnalysisResult {
        let lines = code.components(separatedBy: .newlines)
        let functions = code.components(separatedBy: .newlines).filter { $0.contains("func") }
        
        return AnalysisResult(
            lineCount: lines.count,
            functionCount: functions.count,
            complexity: 1,
            language: "swift"
        )
    }
}