import XCTest
@testable import SmartTextInputSystem

class SmartTextInputSystemTests: XCTestCase {
    
    var coordinator: TextInputCoordinator!
    var pasteManager: PasteDetectionManager!
    
    override func setUpWithError() throws {
        coordinator = TextInputCoordinator()
        pasteManager = PasteDetectionManager()
    }
    
    override func tearDownWithError() throws {
        coordinator = nil
        pasteManager = nil
    }
    
    func testTextAnalysis() throws {
        let testText = "Das ist ein Test. Hier ist noch ein Satz. Und noch ein dritter Satz!"
        
        let analysis = testText.analyze()
        
        XCTAssertEqual(analysis.wordCount, 12)
        XCTAssertEqual(analysis.sentenceCount, 3)
        XCTAssertGreaterThan(analysis.estimatedReadingTime, 0)
    }
    
    func testMarkdownFormatting() throws {
        let plainText = "Das ist ein Test\nDas ist noch ein Test"
        let formatted = plainText.toFormattedMarkdown()
        
        XCTAssertTrue(formatted.contains("#"))
    }
    
    func testPasteContentSanitization() throws {
        let dirtyText = "Text   mit    vielen    Leerzeichen\n\rZeile2"
        let cleanText = pasteManager.sanitizePastedContent(dirtyText)
        
        XCTAssertFalse(cleanText.contains("   "))
        XCTAssertTrue(cleanText.contains("\n\n"))
    }
    
    func testTextStatsCalculation() throws {
        let testText = "Ein zwei drei vier fünf sechs sieben acht neun zehn"
        
        let stats = coordinator.calculateStats(testText)
        
        XCTAssertEqual(stats.wordCount, 10)
        XCTAssertGreaterThan(stats.charCount, 0)
        XCTAssertGreaterThan(stats.readingTime, 0)
    }
    
    func testAutoSaveFunctionality() throws {
        let expectation = self.expectation(description: "Auto-save completion")
        
        coordinator.text = "Test Content"
        
        coordinator.performAutoSave()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertNotNil(self.coordinator.lastSaved)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testSpellingErrorDetection() throws {
        let spellChecker = SpellCheckManager()
        let textWithErrors = "Das ist ein teh Test mit Fehlern."
        
        let errors = spellChecker.checkSpelling(in: textWithErrors)
        
        XCTAssertGreaterThan(errors.count, 0)
        XCTAssertTrue(spellChecker.hasSpellingErrors)
    }
    
    func testTextFormatter() throws {
        let originalText = "Test"
        
        let boldText = TextFormatter.applyStyle(originalText, style: .bold)
        let italicText = TextFormatter.applyStyle(originalText, style: .italic)
        
        XCTAssertEqual(boldText, "**Test**")
        XCTAssertEqual(italicText, "*Test*")
    }
    
    func testStructuredDataExtraction() throws {
        let csvData = "Name,Age,City\nJohn,25,Berlin\nJane,30,München"
        
        let extracted = pasteManager.extractStructuredData(csvData)
        
        XCTAssertEqual(extracted["type"], "csv")
        XCTAssertEqual(extracted["rows"], "2")
    }
    
    func testURLAutoLinking() throws {
        let textWithURL = "Besuchen Sie https://example.com für mehr Infos"
        let formatted = textWithURL.toFormattedMarkdown()
        
        XCTAssertTrue(formatted.contains("[https://example.com](https://example.com)"))
    }
    
    func testPerformanceLargeText() throws {
        let largeText = String(repeating: "Dies ist ein Test Satz. ", count: 1000)
        
        measure {
            _ = largeText.analyze()
            _ = coordinator.calculateStats(largeText)
        }
    }
}

// MARK: - Performance Tests

extension SmartTextInputSystemTests {
    
    func testPasteDetectionPerformance() throws {
        let largeContent = String(repeating: "Test Content ", count: 5000)
        
        measure {
            pasteManager.handleLargePaste(largeContent) { isLarge in
                XCTAssertTrue(isLarge)
            }
        }
    }
    
    func testTextAnalysisPerformance() throws {
        let testText = String(repeating: "Das ist ein sehr langer Testtext mit vielen Sätzen. ", count: 500)
        
        measure {
            _ = testText.analyze()
        }
    }
}

// MARK: - Integration Tests

extension SmartTextInputSystemTests {
    
    func testFullTextInputWorkflow() throws {
        let expectation = self.expectation(description: "Complete workflow")
        
        // 1. Text eingeben
        coordinator.text = "Test workflow"
        
        // 2. Auto-save simulieren
        coordinator.performAutoSave()
        
        // 3. Stats berechnen
        let stats = coordinator.calculateStats(coordinator.text)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(stats.wordCount, 2)
            XCTAssertNotNil(self.coordinator.lastSaved)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
}