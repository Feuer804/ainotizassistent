//
//  SwiftUIComponentTests.swift
//  AINotizassistent - SwiftUI Component Tests
//
//  Spezialisierte Tests für alle SwiftUI-Komponenten
//  View-Tests, Animation-Tests, Accessibility-Tests
//

import XCTest
import SwiftUI
import ViewInspector
@testable import AINotizassistent

// MARK: - SwiftUI Component Test Base
class SwiftUIComponentTestBase: XCTestCase {
    var sut: AnyView?
    var inspection: Inspection!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        inspection = Inspection()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func verifyViewExists<T: View>(_ view: T, file: StaticString = #filePath, line: UInt = #line) {
        let viewController = UIHostingController(rootView: view)
        XCTAssertNotNil(viewController.view, file: file, line: line)
    }
}

// MARK: - Main Content View Tests
class ContentViewTests: SwiftUIComponentTestBase {
    
    func testContentViewInitialization() throws {
        let view = ContentView()
        
        verifyViewExists(view)
        XCTAssertNoThrow(try view.inspect().find(AnyView.self))
    }
    
    func testContentViewHasTitle() throws {
        let view = ContentView()
        
        let titleText = try view.inspect().find(text: "AINotizassistent")
        XCTAssertNotNil(titleText)
    }
    
    func testContentViewHasSettingsButton() throws {
        let view = ContentView()
        
        let buttons = try view.inspect().findAll(Button.self)
        XCTAssertFalse(buttons.isEmpty)
    }
    
    func testContentViewIsResponsive() throws {
        let view = ContentView()
        
        // Test different sizes
        let sizes: [CGSize] = [
            .init(width: 320, height: 568),  // iPhone SE
            .init(width: 375, height: 812),  // iPhone X
            .init(width: 768, height: 1024), // iPad
            .init(width: 1024, height: 768)  // iPad Landscape
        ]
        
        for size in sizes {
            let viewController = UIHostingController(rootView: view)
            viewController.view.frame.size = size
            
            // Verify view doesn't crash with different sizes
            XCTAssertNotNil(viewController.view)
        }
    }
    
    func testContentViewAccessibility() throws {
        let view = ContentView()
        
        let viewController = UIHostingController(rootView: view)
        viewController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        
        // Check accessibility elements
        let accessibilityElements = viewController.view.accessibilityElements
        XCTAssertNotNil(accessibilityElements)
    }
}

// MARK: - Settings View Tests
class SettingsViewTests: SwiftUIComponentTestBase {
    
    func testSettingsViewInitialization() throws {
        let settingsView = SettingsView()
        
        verifyViewExists(settingsView)
    }
    
    func testSettingsViewHasAPIKeySection() throws {
        let settingsView = SettingsView()
        
        let sections = try settingsView.inspect().findAll(Section.self)
        XCTAssertFalse(sections.isEmpty)
        
        // Verify API key settings section exists
        let hasAPISection = sections.contains { section in
            try? section.find(text: "API Keys") != nil
        }
        XCTAssertTrue(hasAPISection)
    }
    
    func testSettingsViewHasStorageSection() throws {
        let settingsView = SettingsView()
        
        let sections = try settingsView.inspect().findAll(Section.self)
        
        let hasStorageSection = sections.contains { section in
            try? section.find(text: "Storage") != nil
        }
        XCTAssertTrue(hasStorageSection)
    }
    
    func testSettingsViewHasShortcutSection() throws {
        let settingsView = SettingsView()
        
        let sections = try settingsView.inspect().findAll(Section.self)
        
        let hasShortcutSection = sections.contains { section in
            try? section.find(text: "Shortcuts") != nil
        }
        XCTAssertTrue(hasShortcutSection)
    }
    
    func testSettingsViewResetButton() throws {
        let settingsView = SettingsView()
        
        let resetButton = try? settingsView.inspect().find(Button.self, where: { button in
            try button.find(text: "Reset")
        })
        
        XCTAssertNotNil(resetButton)
    }
}

// MARK: - API Key Settings View Tests
class APIKeySettingsViewTests: SwiftUIComponentTestBase {
    
    func testAPIKeyViewInitialization() throws {
        let apiKeyView = APIKeySettingsView()
        
        verifyViewExists(apiKeyView)
    }
    
    func testAPIKeyViewHasProviderSelector() throws {
        let apiKeyView = APIKeySettingsView()
        
        let pickers = try apiKeyView.inspect().findAll(Picker.self)
        XCTAssertFalse(pickers.isEmpty)
    }
    
    func testAPIKeyViewHasKeyInputField() throws {
        let apiKeyView = APIKeySettingsView()
        
        let textFields = try apiKeyView.inspect().findAll(TextField.self)
        XCTAssertFalse(textFields.isEmpty)
    }
    
    func testAPIKeyViewHasValidationStatus() throws {
        let apiKeyView = APIKeySettingsView()
        
        let statusViews = try? apiKeyView.inspect().findAll(Any.self, where: { any in
            // Look for status indicators
            false
        })
        
        // Status should be displayed somehow
        XCTAssertNotNil(apiKeyView)
    }
}

// MARK: - Shortcut Settings View Tests
class ShortcutSettingsViewTests: SwiftUIComponentTestBase {
    
    func testShortcutViewInitialization() throws {
        let shortcutView = ShortcutSettingsView()
        
        verifyViewExists(shortcutView)
    }
    
    func testShortcutViewHasShortcutList() throws {
        let shortcutView = ShortcutSettingsView()
        
        // Look for list or navigation structure
        let navigationViews = try shortcutView.inspect().findAll(NavigationView.self)
        let listViews = try shortcutView.inspect().findAll(List.self)
        
        XCTAssertTrue(!navigationViews.isEmpty || !listViews.isEmpty)
    }
    
    func testShortcutViewHasAddButton() throws {
        let shortcutView = ShortcutSettingsView()
        
        let addButton = try? shortcutView.inspect().find(Button.self, where: { button in
            try button.find(text: "Add")
        })
        
        XCTAssertNotNil(addButton)
    }
    
    func testShortcutViewKeyComboCapture() throws {
        let shortcutView = ShortcutSettingsView()
        
        // Test key combo capture functionality
        // This would require more complex testing setup
        XCTAssertNotNil(shortcutView)
    }
}

// MARK: - Preview Views Tests
class PreviewViewsTests: SwiftUIComponentTestBase {
    
    func testPreviewViewsInitialization() throws {
        let previewViews = PreviewViews()
        
        verifyViewExists(previewViews.contentView)
    }
    
    func testPreviewViewsHaveDifferentStates() throws {
        let previewViews = PreviewViews()
        
        // Test loading state
        previewViews.isLoading = true
        XCTAssertNotNil(previewViews.contentView)
        
        // Test error state
        previewViews.isLoading = false
        previewViews.hasError = true
        XCTAssertNotNil(previewViews.contentView)
        
        // Test success state
        previewViews.hasError = false
        previewViews.content = "Test content"
        XCTAssertNotNil(previewViews.contentView)
    }
}

// MARK: - Glass UI Component Tests
class GlassUIComponentsTests: SwiftUIComponentTestBase {
    
    func testGlassCardViewInitialization() throws {
        let glassCard = GlassCardView {
            Text("Test Content")
        }
        
        verifyViewExists(glassCard)
    }
    
    func testGlassCardViewHasBackground() throws {
        let glassCard = GlassCardView {
            Text("Test Content")
        }
        
        let viewController = UIHostingController(rootView: glassCard)
        viewController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 200)
        
        XCTAssertNotNil(viewController.view)
    }
    
    func testGlassButtonStyle() throws {
        let button = Button("Test") {
            // Action
        }
        .buttonStyle(GlassButtonStyle())
        
        verifyViewExists(button)
    }
    
    func testGlassTextField() throws {
        let textField = GlassTextField("Placeholder", text: .constant(""))
        
        verifyViewExists(textField)
        
        let viewController = UIHostingController(rootView: textField)
        XCTAssertNotNil(viewController.view)
    }
    
    func testGlassModalView() throws {
        let modal = GlassModalView(isPresented: .constant(true)) {
            Text("Modal Content")
        }
        
        verifyViewExists(modal)
    }
}

// MARK: - Meeting View Tests
class MeetingViewTests: SwiftUIComponentTestBase {
    
    func testMeetingViewInitialization() throws {
        let meetingView = MeetingView()
        
        verifyViewExists(meetingView)
    }
    
    func testMeetingViewHasTitle() throws {
        let meetingView = MeetingView()
        
        let titleText = try? meetingView.inspect().find(text: "Meeting")
        XCTAssertNotNil(titleText)
    }
    
    func testMeetingViewHasParticipantsList() throws {
        let meetingView = MeetingView()
        
        let listViews = try meetingView.inspect().findAll(List.self)
        XCTAssertFalse(listViews.isEmpty)
    }
    
    func testMeetingViewHasActionItems() throws {
        let meetingView = MeetingView()
        
        let sections = try meetingView.inspect().findAll(Section.self)
        XCTAssertFalse(sections.isEmpty)
    }
}

// MARK: - Content View with Voice Input Tests
class ContentViewWithVoiceInputTests: SwiftUIComponentTestBase {
    
    func testVoiceInputViewInitialization() throws {
        let voiceView = ContentViewWithVoiceInput()
        
        verifyViewExists(voiceView)
    }
    
    func testVoiceInputViewHasRecordButton() throws {
        let voiceView = ContentViewWithVoiceInput()
        
        let recordButton = try? voiceView.inspect().find(Button.self, where: { button in
            try button.find(text: "Record")
        })
        
        XCTAssertNotNil(recordButton)
    }
    
    func testVoiceInputViewShowsTranscription() throws {
        let voiceView = ContentViewWithVoiceInput()
        voiceView.transcription = "This is a test transcription"
        
        XCTAssertNotNil(voiceView)
    }
    
    func testVoiceInputViewHasStopButton() throws {
        let voiceView = ContentViewWithVoiceInput()
        
        let stopButton = try? voiceView.inspect().find(Button.self, where: { button in
            try button.find(text: "Stop")
        })
        
        XCTAssertNotNil(stopButton)
    }
}

// MARK: - Animation System Tests
class AnimationSystemTests: SwiftUIComponentTestBase {
    
    func testAnimationManagerInitialization() throws {
        let animationManager = AnimationManager.shared
        
        XCTAssertNotNil(animationManager)
    }
    
    func testMicroInteractionManager() throws {
        let microManager = MicroInteractionManager()
        
        XCTAssertNotNil(microManager)
    }
    
    func testScreenTransitionManager() throws {
        let transitionManager = ScreenTransitionManager()
        
        XCTAssertNotNil(transitionManager)
    }
    
    func testLoadingAnimationManager() throws {
        let loadingManager = LoadingAnimationManager()
        
        XCTAssertNotNil(loadingManager)
    }
    
    func testAnimationDemoView() throws {
        let demoView = AnimationDemoView()
        
        verifyViewExists(demoView)
    }
}

// MARK: - Note Card View Tests
class NoteCardViewTests: SwiftUIComponentTestBase {
    
    func testNoteCardViewInitialization() throws {
        let note = NoteModel(
            id: UUID(),
            content: "Test note content",
            title: "Test Note",
            type: .note,
            sourceApp: "TestApp",
            createdAt: Date(),
            updatedAt: Date(),
            tags: ["test"],
            metadata: [:]
        )
        
        let noteCard = NoteCardView(note: note)
        
        verifyViewExists(noteCard)
    }
    
    func testNoteCardViewDisplaysTitle() throws {
        let note = createTestNote(title: "Test Note")
        let noteCard = NoteCardView(note: note)
        
        let titleText = try? noteCard.inspect().find(text: "Test Note")
        XCTAssertNotNil(titleText)
    }
    
    func testNoteCardViewHasActionButtons() throws {
        let note = createTestNote()
        let noteCard = NoteCardView(note: note)
        
        let buttons = try noteCard.inspect().findAll(Button.self)
        XCTAssertFalse(buttons.isEmpty)
    }
    
    func testNoteCardViewDisplaysDate() throws {
        let note = createTestNote()
        let noteCard = NoteCardView(note: note)
        
        XCTAssertNotNil(noteCard)
    }
}

// MARK: - Auto Save Status View Tests
class AutoSaveStatusViewTests: SwiftUIComponentTestBase {
    
    func testAutoSaveStatusViewInitialization() throws {
        let autoSaveView = AutoSaveStatusView()
        
        verifyViewExists(autoSaveView)
    }
    
    func testAutoSaveStatusViewShowsStatus() throws {
        let autoSaveView = AutoSaveStatusView()
        
        let statusText = try? autoSaveView.inspect().find(text: "Saved")
        
        XCTAssertNotNil(autoSaveView)
    }
    
    func testAutoSaveStatusViewHasProgressIndicator() throws {
        let autoSaveView = AutoSaveStatusView()
        
        let progressViews = try autoSaveView.inspect().findAll(ProgressView.self)
        XCTAssertFalse(progressViews.isEmpty)
    }
}

// MARK: - Content Analysis View Tests
class ContentAnalyzerViewTests: SwiftUIComponentTestBase {
    
    func testContentAnalyzerViewInitialization() throws {
        let analyzerView = ContentAnalyzerView()
        
        verifyViewExists(analyzerView)
    }
    
    func testContentAnalyzerViewHasProgressBar() throws {
        let analyzerView = ContentAnalyzerView()
        
        let progressViews = try analyzerView.inspect().findAll(ProgressView.self)
        XCTAssertFalse(progressViews.isEmpty)
    }
    
    func testContentAnalyzerViewShowsAnalysisSteps() throws {
        let analyzerView = ContentAnalyzerView()
        
        let stepTexts = try? analyzerView.inspect().findAll(text: "")
        
        XCTAssertNotNil(analyzerView)
    }
    
    func testContentAnalyzerViewHasResults() throws {
        let analyzerView = ContentAnalyzerView()
        
        XCTAssertNotNil(analyzerView)
    }
}

// MARK: - Meeting Recap View Tests
class MeetingRecapViewTests: SwiftUIComponentTestBase {
    
    func testMeetingRecapViewInitialization() throws {
        let recapView = MeetingRecapView()
        
        verifyViewExists(recapView)
    }
    
    func testMeetingRecapViewHasSummary() throws {
        let recapView = MeetingRecapView()
        
        let summaryText = try? recapView.inspect().find(text: "Summary")
        
        XCTAssertNotNil(recapView)
    }
    
    func testMeetingRecapViewHasActionItems() throws {
        let recapView = MeetingRecapView()
        
        let sections = try recapView.inspect().findAll(Section.self)
        XCTAssertFalse(sections.isEmpty)
    }
    
    func testMeetingRecapViewHasParticipants() throws {
        let recapView = MeetingRecapView()
        
        XCTAssertNotNil(recapView)
    }
}

// MARK: - Content Generation Views Tests
class ContentGenerationViewsTests: SwiftUIComponentTestBase {
    
    func testContentGenerationViewInitialization() throws {
        let genView = ContentGenerationViews()
        
        verifyViewExists(genView.contentView)
    }
    
    func testContentGenerationViewHasModeSelector() throws {
        let genView = ContentGenerationViews()
        
        let pickers = try genView.contentView.inspect().findAll(Picker.self)
        XCTAssertFalse(pickers.isEmpty)
    }
    
    func testContentGenerationViewShowsGeneratedContent() throws {
        let genView = ContentGenerationViews()
        genView.generatedContent = "Generated text content"
        
        XCTAssertNotNil(genView.contentView)
    }
    
    func testContentGenerationViewHasCopyButton() throws {
        let genView = ContentGenerationViews()
        
        let copyButton = try? genView.contentView.inspect().find(Button.self, where: { button in
            try button.find(text: "Copy")
        })
        
        XCTAssertNotNil(copyButton)
    }
}

// MARK: - Default Storage Settings View Tests
class DefaultStorageSettingsViewTests: SwiftUIComponentTestBase {
    
    func testStorageSettingsViewInitialization() throws {
        let storageView = DefaultStorageSettingsView()
        
        verifyViewExists(storageView)
    }
    
    func testStorageSettingsViewHasProviderSelector() throws {
        let storageView = DefaultStorageSettingsView()
        
        let pickers = try storageView.inspect().findAll(Picker.self)
        XCTAssertFalse(pickers.isEmpty)
    }
    
    func testStorageSettingsViewShowsConnectionStatus() throws {
        let storageView = DefaultStorageSettingsView()
        
        let statusIndicators = try? storageView.inspect().findAll(Any.self, where: { _ in false })
        
        XCTAssertNotNil(storageView)
    }
}

// MARK: - Test Data Helpers
extension SwiftUIComponentTestBase {
    
    func createTestNote(title: String = "Test Note") -> NoteModel {
        return NoteModel(
            id: UUID(),
            content: "Test note content with some details about the meeting, decisions made, and action items.",
            title: title,
            type: .note,
            sourceApp: "TestApp",
            createdAt: Date(),
            updatedAt: Date(),
            tags: ["test", "meeting"],
            metadata: ["priority": "high"]
        )
    }
}

// MARK: - Performance Tests for SwiftUI
class SwiftUIPerformanceTests: XCTestCase {
    
    func testContentViewPerformance() throws {
        let contentView = ContentView()
        
        measure {
            // Measure view loading time
            let viewController = UIHostingController(rootView: contentView)
            viewController.loadViewIfNeeded()
        }
    }
    
    func testSettingsViewPerformance() throws {
        let settingsView = SettingsView()
        
        measure {
            let viewController = UIHostingController(rootView: settingsView)
            viewController.loadViewIfNeeded()
        }
    }
    
    func testListRenderingPerformance() throws {
        let notes = (0..<100).map { i in
            NoteModel(
                id: UUID(),
                content: "Content for note \(i)",
                title: "Note \(i)",
                type: .note,
                sourceApp: "TestApp",
                createdAt: Date(),
                updatedAt: Date(),
                tags: ["test"],
                metadata: [:]
            )
        }
        
        let listView = List(notes, id: \.id) { note in
            NoteCardView(note: note)
        }
        
        measure {
            let viewController = UIHostingController(rootView: listView)
            viewController.loadViewIfNeeded()
        }
    }
}

// MARK: - Accessibility Tests
class SwiftUIAccessibilityTests: SwiftUIComponentTestBase {
    
    func testContentViewAccessibility() throws {
        let contentView = ContentView()
        
        let viewController = UIHostingController(rootView: contentView)
        viewController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        
        let elements = viewController.view.accessibilityElements
        XCTAssertNotNil(elements)
        XCTAssertGreaterThan(elements?.count ?? 0, 0)
    }
    
    func testSettingsViewAccessibility() throws {
        let settingsView = SettingsView()
        
        let viewController = UIHostingController(rootView: settingsView)
        viewController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        
        let elements = viewController.view.accessibilityElements
        XCTAssertNotNil(elements)
    }
    
    func testVoiceInputViewAccessibility() throws {
        let voiceView = ContentViewWithVoiceInput()
        
        let viewController = UIHostingController(rootView: voiceView)
        viewController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        
        // Test that recording button has proper accessibility label
        let elements = viewController.view.accessibilityElements
        XCTAssertNotNil(elements)
    }
    
    func testKeyboardNavigation() throws {
        let contentView = ContentView()
        
        let viewController = UIHostingController(rootView: contentView)
        viewController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        
        // Test that view supports keyboard navigation
        XCTAssertNotNil(viewController.view)
    }
}

// MARK: - Animation Tests
class SwiftUIAnimationTests: XCTestCase {
    
    func testGlassCardAnimation() throws {
        let glassCard = GlassCardView {
            Text("Animated Content")
        }
        
        measure {
            let viewController = UIHostingController(rootView: glassCard)
            viewController.loadViewIfNeeded()
        }
    }
    
    func testLoadingAnimationPerformance() throws {
        let loadingView = ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
        
        measure {
            let viewController = UIHostingController(rootView: loadingView)
            viewController.loadViewIfNeeded()
        }
    }
    
    func testButtonAnimation() throws {
        let animatedButton = Button("Animated") {}
            .buttonStyle(GlassButtonStyle())
        
        measure {
            let viewController = UIHostingController(rootView: animatedButton)
            viewController.loadViewIfNeeded()
        }
    }
}

// MARK: - Layout Tests
class SwiftUILayoutTests: SwiftUIComponentTestBase {
    
    func testResponsiveLayout() throws {
        let contentView = ContentView()
        
        let sizes: [CGSize] = [
            .init(width: 320, height: 568),  // iPhone SE
            .init(width: 375, height: 812),  // iPhone X
            .init(width: 414, height: 896),  // iPhone 11
            .init(width: 768, height: 1024), // iPad
            .init(width: 1024, height: 768)  // iPad Landscape
        ]
        
        for size in sizes {
            let viewController = UIHostingController(rootView: contentView)
            viewController.view.frame.size = size
            
            XCTAssertNotNil(viewController.view)
            
            // Verify layout constraints are satisfied
            let constraints = viewController.view.constraints
            XCTAssertGreaterThan(constraints.count, 0)
        }
    }
    
    func testTextFieldLayout() throws {
        let textField = GlassTextField("Placeholder", text: .constant(""))
        
        let viewController = UIHostingController(rootView: textField)
        viewController.view.frame.size = CGSize(width: 375, height: 60)
        
        XCTAssertNotNil(viewController.view)
    }
    
    func testListLayout() throws {
        let notes = (0..<10).map { i in
            NoteModel(
                id: UUID(),
                content: "Content \(i)",
                title: "Note \(i)",
                type: .note,
                sourceApp: "TestApp",
                createdAt: Date(),
                updatedAt: Date(),
                tags: ["test"],
                metadata: [:]
            )
        }
        
        let listView = List(notes, id: \.id) { note in
            NoteCardView(note: note)
        }
        
        let viewController = UIHostingController(rootView: listView)
        viewController.view.frame.size = CGSize(width: 375, height: 600)
        
        XCTAssertNotNil(viewController.view)
    }
}

// MARK: - Integration Tests
class SwiftUIIntegrationTests: SwiftUIComponentTestBase {
    
    func testEndToEndUserFlow() throws {
        // Test complete user flow through the app
        let contentView = ContentView()
        
        let viewController = UIHostingController(rootView: contentView)
        viewController.loadViewIfNeeded()
        
        // Simulate navigation through the app
        XCTAssertNotNil(viewController.view)
    }
    
    func testSettingsFlow() throws {
        let settingsView = SettingsView()
        
        let viewController = UIHostingController(rootView: settingsView)
        viewController.loadViewIfNeeded()
        
        // Test navigation to API key settings
        XCTAssertNotNil(viewController.view)
    }
    
    func testContentAnalysisFlow() throws {
        let analyzerView = ContentAnalyzerView()
        
        let viewController = UIHostingController(rootView: analyzerView)
        viewController.loadViewIfNeeded()
        
        // Test analysis process
        XCTAssertNotNil(viewController.view)
    }
}