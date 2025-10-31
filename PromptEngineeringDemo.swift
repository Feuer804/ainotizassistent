//
//  PromptEngineeringDemo.swift
//  Intelligente Notizen App - Prompt Engineering Demonstration
//

import Foundation

// MARK: - Demo für Prompt Engineering System
@available(iOS 15.0, macOS 12.0, *)
class PromptEngineeringDemo {
    
    private let promptManager: PromptManager
    private let contentProcessor: ContentProcessor
    private let contentAnalyzer: ContentAnalyzer
    
    init() {
        self.promptManager = AIEnhancedPromptManager()
        self.contentProcessor = AIEnabledContentProcessor(kiProvider: KIProvider(), promptManager: promptManager)
        self.contentAnalyzer = ContentAnalyzer()
    }
    
    // MARK: - Demo: Email Processing mit Prompt Engineering
    func demoEmailProcessing() async {
        print("=== E-Mail Processing Demo ===")
        
        let emailContent = """
        Hallo Team,
        
        wir müssen bis nächsten Freitag das neue Feature fertigstellen. 
        Die Beta-Tests zeigen einige Probleme mit der Performance.
        
        Action Items:
        - Performance-Optimierung bis Mittwoch
        - Code Review am Donnerstag
        - Deployment am Freitag
        
        Bitte priorisiert diese Tasks entsprechend.
        
        Viele Grüße
        Sarah
        """
        
        do {
            // 1. Content Analysis
            let analysis = try await analyzeEmailContent(emailContent)
            print("📧 E-Mail analysiert:")
            print("   - Typ: \(analysis.contentType.displayName)")
            print("   - Confidence: \(String(format: "%.2f", analysis.confidence))")
            print("   - Sentiment: \(analysis.sentiment.polarity)")
            print("   - Dringlichkeit: \(analysis.urgency.level.level)")
            
            // 2. Prompt Generation
            let context = createPromptContext(from: emailContent, analysis: analysis)
            let promptResult = try await promptManager.generatePrompt(for: .email, with: context)
            
            print("\n🤖 Generierter Prompt:")
            print("   - Template: \(promptResult.templateId)")
            print("   - Sprache: \(promptResult.language.displayName)")
            print("   - Geschätzte Tokens: \(promptResult.estimatedTokens)")
            
            // 3. Process Note
            let note = NoteModel(
                id: UUID(),
                content: emailContent,
                contentType: .email,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            let processedNote = try await contentProcessor.processNote(note)
            
            print("\n📝 Verarbeitetes Ergebnis:")
            print("   - Verarbeitungszeit: \(String(format: "%.2f", processedNote.processingTime))s")
            print("   - Enhanced Content: \(processedNote.hasEnhancedContent ? "Ja" : "Nein")")
            print("   - AI Summary: \(processedNote.hasAiSummary ? "Ja" : "Nein")")
            print("   - Generierte Prompts: \(processedNote.promptCount)")
            
        } catch {
            print("❌ Fehler: \(error)")
        }
    }
    
    // MARK: - Demo: Meeting Notes Processing
    func demoMeetingProcessing() async {
        print("\n=== Meeting Notes Processing Demo ===")
        
        let meetingContent = """
        Projekt-Meeting - Sprint Planung
        
        Datum: 15.10.2025
        Teilnehmer: Max, Anna, Tom, Lisa
        
        Agenda:
        1. Sprint Review (30 min)
        2. Sprint Planning (45 min)
        3. Risk Assessment (15 min)
        
        Besprechung:
        - Sprint 7 war erfolgreich, 95% der Stories wurden abgeschlossen
        - Performance-Probleme bei der Suche identifiziert
        - Lisa übernimmt die Optimierung der Suchfunktion
        
        Beschlüsse:
        1. Suchfunktion wird als höchste Priorität behandelt
        2. Code Review wird verstärkt für neue Features
        
        Action Items:
        - Lisa: Suchfunktion-Optimierung bis 22.10.
        - Max: Code Review Guidelines aktualisieren
        - Anna: Performance Monitoring einrichten
        
        Nächstes Meeting: 22.10.2025 um 10:00
        """
        
        do {
            // Process with multiple languages
            let languages: [PromptLanguage] = [.german, .english]
            var results: [PromptResult] = []
            
            for language in languages {
                let context = PromptContext(
                    content: meetingContent,
                    language: DetectedLanguage(code: language == .german ? "de" : "en", confidence: 0.95, isReliable: true, localizedName: language.displayName),
                    sentiment: SentimentAnalysis(polarity: .neutral, confidence: 0.8, intensity: 0.5, emotions: []),
                    urgency: UrgencyLevel(level: .medium, score: 0.6, indicators: [], estimatedTimeToComplete: nil),
                    quality: ContentQuality(readabilityScore: 0.8, completenessScore: 0.9, engagementScore: 0.7, grammarScore: 0.9, structureScore: 0.8, suggestions: []),
                    topics: [],
                    keywords: [],
                    metadata: [:],
                    userPreferences: UserPromptPreferences(),
                    contentLength: meetingContent.count,
                    structure: ContentStructure(hasHeaders: true, hasLists: true, hasLinks: false, hasImages: false, hasCode: false, headerHierarchy: [], listTypes: [], paragraphCount: 8, sentenceCount: 15, wordCount: meetingContent.components(separatedBy: .whitespacesAndNewlines).count)
                )
                
                let promptResult = try await promptManager.generatePrompt(for: .meeting, with: context)
                results.append(promptResult)
            }
            
            print("📋 Meeting Notes verarbeitet:")
            print("   - Generierte Prompts: \(results.count)")
            for (index, result) in results.enumerated() {
                print("   - Prompt \(index + 1): \(result.language.displayName) (\(result.estimatedTokens) Tokens)")
            }
            
        } catch {
            print("❌ Fehler: \(error)")
        }
    }
    
    // MARK: - Demo: Code Review with Prompts
    func demoCodeReviewProcessing() async {
        print("\n=== Code Review Demo ===")
        
        let codeContent = """
        func processUserData(_ data: [String: Any]) -> UserModel? {
            guard let userId = data["id"] as? String else {
                return nil
            }
            
            let name = data["name"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            
            return UserModel(id: userId, name: name, email: email)
        }
        """
        
        do {
            let context = createCodePromptContext(from: codeContent)
            let promptResult = try await promptManager.generatePrompt(for: .code, with: context)
            
            print("💻 Code Review Prompt generiert:")
            print("   - Template: \(promptResult.templateId)")
            print("   - Geschätzte Tokens: \(promptResult.estimatedTokens)")
            print("   - Prompt Preview: \(String(promptResult.prompt.prefix(100))...)")
            
        } catch {
            print("❌ Fehler: \(error)")
        }
    }
    
    // MARK: - Demo: A/B Testing
    func demoABTesting() async {
        print("\n=== A/B Testing Demo ===")
        
        let contentType = ContentType.article
        
        // Create A/B test variants
        let variantA = ABTestPromptVariant(
            id: "variant_a",
            prompt: "Analysiere den Artikel und erstelle eine strukturierte Zusammenfassung mit Hauptpunkten und Fazit.",
            description: "Strukturierte Analyse",
            weight: 1.0,
            metadata: ["style": "structured"]
        )
        
        let variantB = ABTestPromptVariant(
            id: "variant_b",
            prompt: "Lese den Artikel aufmerksam und fasse die wichtigsten Erkenntnisse in natürlicher Sprache zusammen.",
            description: "Narrative Analyse",
            weight: 1.0,
            metadata: ["style": "narrative"]
        )
        
        do {
            let test = await (promptManager as? ABTestPromptManager)?.createTest(
                for: contentType,
                variants: [variantA, variantB]
            )
            
            print("🧪 A/B Test erstellt:")
            print("   - Test ID: \(test.id)")
            print("   - Varianten: \(test.variants.count)")
            print("   - Strategie: \(test.assignmentStrategy)")
            
            // Simulate some test results
            for variant in test.variants {
                for _ in 1...10 {
                    let success = Bool.random()
                    let responseTime = Double.random(in: 1...5)
                    let metrics = TestMetrics(
                        responseTime: responseTime,
                        tokensUsed: Int.random(in: 100...500),
                        qualityScore: Double.random(in: 0.7...1.0),
                        userSatisfaction: Double.random(in: 0.6...1.0)
                    )
                    
                    await (promptManager as? ABTestPromptManager)?.trackTestResult(
                        testId: test.id,
                        variantId: variant.id,
                        success: success,
                        metrics: metrics
                    )
                }
            }
            
            let results = await (promptManager as? ABTestPromptManager)?.getTestResults(testId: test.id)
            print("\n📊 Test Ergebnisse:")
            print("   - Teilnehmer: \(results?.totalParticipants ?? 0)")
            print("   - Signifikanz: \(String(format: "%.2f", results?.statisticalSignificance ?? 0.0))")
            
        } catch {
            print("❌ A/B Test Fehler: \(error)")
        }
    }
    
    // MARK: - Demo: Custom Template
    func demoCustomTemplate() async {
        print("\n=== Custom Template Demo ===")
        
        let customTemplate = CustomPromptTemplate(
            id: UUID().uuidString,
            name: "Technische Dokumentation",
            description: "Template für technische Dokumentations-Analyse",
            category: .technical,
            basePrompt: """
            Analysiere die folgende technische Dokumentation:
            
            {content}
            
            Extrahiere:
            1. **Funktionalität**: Hauptfunktionen
            2. **API-Endpoints**: Verfügbare Endpoints
            3. **Beispiele**: Code-Beispiele
            4. **Dependencies**: Benötigte Abhängigkeiten
            5. **Installation**: Installationsanweisungen
            
            Strukturiere die Antwort für Entwickler.
            """,
            parameters: ["content": "Die zu analysierende technische Dokumentation"],
            contentTypes: [.article],
            languages: [.german],
            createdAt: Date(),
            lastModified: Date(),
            tags: ["technisch", "dokumentation", "api"],
            isPublic: false,
            author: "Demo User",
            version: "1.0"
        )
        
        let templateManager = CustomPromptTemplateManager()
        
        do {
            let validation = await templateManager.validateTemplate(customTemplate)
            print("✅ Template Validierung:")
            print("   - Gültig: \(validation.isValid ? "Ja" : "Nein")")
            print("   - Fehler: \(validation.errors.count)")
            print("   - Warnungen: \(validation.warnings.count)")
            print("   - Vorschläge: \(validation.suggestions.count)")
            
            if validation.isValid {
                let generatedPrompt = try await templateManager.createTemplate(from: customTemplate)
                print("\n🤖 Generierter Prompt:")
                print("   - Länge: \(generatedPrompt.count) Zeichen")
                print("   - Preview: \(String(generatedPrompt.prefix(150))...)")
            }
            
        } catch {
            print("❌ Template Fehler: \(error)")
        }
    }
    
    // MARK: - Demo: Analytics
    func demoAnalytics() async {
        print("\n=== Analytics Demo ===")
        
        // Generate some usage data
        let contentTypes: [ContentType] = [.email, .meeting, .article, .code]
        
        for contentType in contentTypes {
            for _ in 1...20 {
                let context = createRandomPromptContext()
                let promptResult = try? await promptManager.generatePrompt(for: contentType, with: context)
                
                if let promptResult = promptResult {
                    await promptManager.trackPromptUsage(
                        promptResult.templateId,
                        success: Bool.random(),
                        responseTime: Double.random(in: 0.5...3.0)
                    )
                }
            }
        }
        
        let analytics = await promptManager.getPromptAnalytics()
        print("📈 Prompt Analytics:")
        print("   - Gesamt Prompts: \(analytics.totalPromptsGenerated)")
        print("   - Ø Antwortzeit: \(String(format: "%.2f", analytics.averageResponseTime))s")
        print("   - Erfolgsrate: \(String(format: "%.1f", analytics.successRate * 100))%")
        print("   - Meistgenutzte Templates: \(analytics.mostUsedTemplates.count)")
        print("   - Optimierungsvorschläge: \(analytics.optimizationSuggestions.count)")
        
        for suggestion in analytics.optimizationSuggestions.prefix(3) {
            print("     - \(suggestion.description)")
        }
    }
    
    // MARK: - Helper Methods
    private func analyzeEmailContent(_ content: String) async throws -> ExtendedAnalysisResult {
        return try await withCheckedThrowingContinuation { continuation in
            contentAnalyzer.analyzeContent(content) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    private func createPromptContext(from content: String, analysis: ExtendedAnalysisResult) -> PromptContext {
        return PromptContext(
            content: content,
            language: analysis.language,
            sentiment: analysis.sentiment,
            urgency: analysis.urgency,
            quality: analysis.quality,
            topics: analysis.topics,
            keywords: analysis.keywords,
            metadata: analysis.metadata,
            userPreferences: UserPromptPreferences(),
            contentLength: content.count,
            structure: analysis.structure
        )
    }
    
    private func createCodePromptContext(from code: String) -> PromptContext {
        return PromptContext(
            content: code,
            language: DetectedLanguage(code: "en", confidence: 0.9, isReliable: true, localizedName: "English"),
            sentiment: SentimentAnalysis(polarity: .neutral, confidence: 0.8, intensity: 0.5, emotions: []),
            urgency: UrgencyLevel(level: .low, score: 0.3, indicators: [], estimatedTimeToComplete: nil),
            quality: ContentQuality(readabilityScore: 0.7, completenessScore: 0.6, engagementScore: 0.5, grammarScore: 0.8, structureScore: 0.7, suggestions: []),
            topics: [Topic(name: "Code Review", confidence: 0.9, keywords: ["function", "processing"], category: .technology)],
            keywords: [Keyword(term: "func", relevance: 0.9, frequency: 1, positions: [0], category: .technical)],
            metadata: [:],
            userPreferences: UserPromptPreferences(),
            contentLength: code.count,
            structure: ContentStructure(hasHeaders: false, hasLists: false, hasLinks: false, hasImages: false, hasCode: true, headerHierarchy: [], listTypes: [], paragraphCount: 1, sentenceCount: 1, wordCount: code.components(separatedBy: .whitespacesAndNewlines).count)
        )
    }
    
    private func createRandomPromptContext() -> PromptContext {
        let languages = ["de", "en"]
        let sentiments: [SentimentAnalysis.Polarity] = [.positive, .neutral, .negative]
        
        return PromptContext(
            content: "Random content for testing",
            language: DetectedLanguage(code: languages.randomElement() ?? "de", confidence: 0.8, isReliable: true, localizedName: "Language"),
            sentiment: SentimentAnalysis(polarity: sentiments.randomElement() ?? .neutral, confidence: 0.7, intensity: 0.5, emotions: []),
            urgency: UrgencyLevel(level: .medium, score: 0.5, indicators: [], estimatedTimeToComplete: nil),
            quality: ContentQuality(readabilityScore: 0.8, completenessScore: 0.7, engagementScore: 0.6, grammarScore: 0.9, structureScore: 0.8, suggestions: []),
            topics: [],
            keywords: [],
            metadata: [:],
            userPreferences: UserPromptPreferences(),
            contentLength: 100,
            structure: ContentStructure(hasHeaders: false, hasLists: false, hasLinks: false, hasImages: false, hasCode: false, headerHierarchy: [], listTypes: [], paragraphCount: 1, sentenceCount: 1, wordCount: 20)
        )
    }
    
    // MARK: - Run All Demos
    func runAllDemos() async {
        print("🚀 Starte Prompt Engineering Demos...")
        print("=" * 50)
        
        await demoEmailProcessing()
        await demoMeetingProcessing()
        await demoCodeReviewProcessing()
        await demoABTesting()
        await demoCustomTemplate()
        await demoAnalytics()
        
        print("\n" + "=" * 50)
        print("✅ Alle Demos abgeschlossen!")
    }
}

// MARK: - Demo Usage
@available(iOS 15.0, macOS 12.0, *)
struct PromptEngineeringDemoRunner {
    static func runDemo() async {
        let demo = PromptEngineeringDemo()
        await demo.runAllDemos()
    }
}

// MARK: - CLI Demo Runner
#if canImport(FoundationNetworking)
import FoundationNetworking

@available(iOS 15.0, macOS 12.0, *)
class CLIDemoRunner {
    static func run() async {
        print("Intelligente Notizen App - Prompt Engineering Demo")
        print("=" * 50)
        
        let demo = PromptEngineeringDemo()
        
        while true {
            print("\nWählen Sie eine Demo:")
            print("1. E-Mail Processing")
            print("2. Meeting Notes")
            print("3. Code Review")
            print("4. A/B Testing")
            print("5. Custom Templates")
            print("6. Analytics")
            print("7. Alle Demos")
            print("0. Beenden")
            
            if let choice = readLine(), let option = Int(choice) {
                switch option {
                case 1:
                    await demo.demoEmailProcessing()
                case 2:
                    await demo.demoMeetingProcessing()
                case 3:
                    await demo.demoCodeReviewProcessing()
                case 4:
                    await demo.demoABTesting()
                case 5:
                    await demo.demoCustomTemplate()
                case 6:
                    await demo.demoAnalytics()
                case 7:
                    await demo.runAllDemos()
                case 0:
                    print("Auf Wiedersehen!")
                    return
                default:
                    print("Ungültige Option!")
                }
            } else {
                print("Ungültige Eingabe!")
            }
        }
    }
}
#endif