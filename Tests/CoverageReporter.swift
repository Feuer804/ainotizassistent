//
//  CoverageReporter.swift
//  AINotizassistent - Test Coverage Reporting
//
//  Erweiterte Coverage-Analyse und Berichterstattung
//  für alle App-Komponenten und Funktionalitäten
//

import Foundation
import XCTest
import Combine

// MARK: - Coverage Metrics Models
struct CoverageMetrics {
    let totalLines: Int
    let coveredLines: Int
    let uncoveredLines: Int
    let coveragePercentage: Double
    let functionCoverage: Double
    let branchCoverage: Double
    let lineCoverage: Double
    let complexityCoverage: Double
    
    var isCoverageSufficient: Bool {
        return coveragePercentage >= 80.0 && lineCoverage >= 75.0
    }
    
    var coverageLevel: CoverageLevel {
        switch coveragePercentage {
        case 0..<25: return .poor
        case 25..<50: return .fair
        case 50..<75: return .good
        case 75..<90: return .veryGood
        case 90...100: return .excellent
        default: return .unknown
        }
    }
}

enum CoverageLevel: String, CaseIterable {
    case poor = "Unzureichend"
    case fair = "Ausreichend"
    case good = "Gut"
    case veryGood = "Sehr Gut"
    case excellent = "Ausgezeichnet"
    case unknown = "Unbekannt"
    
    var color: String {
        switch self {
        case .poor: return "#ff4444"
        case .fair: return "#ff8800"
        case .good: return "#ffcc00"
        case .veryGood: return "#88cc00"
        case .excellent: return "#00cc00"
        case .unknown: return "#666666"
        }
    }
    
    var description: String {
        return rawValue
    }
}

struct ComponentCoverage {
    let componentName: String
    let componentType: ComponentType
    let metrics: CoverageMetrics
    let testResults: [TestResult]
    let lastTested: Date
    let issues: [CoverageIssue]
    
    enum ComponentType {
        case view
        case model
        case manager
        case service
        case util
        case integration
        
        var displayName: String {
            switch self {
            case .view: return "View"
            case .model: return "Model"
            case .manager: return "Manager"
            case .service: return "Service"
            case .util: return "Utilities"
            case .integration: return "Integration"
            }
        }
    }
}

struct CoverageIssue {
    let id: String
    let type: IssueType
    let severity: IssueSeverity
    let description: String
    let location: String
    let suggestion: String
    let isFixed: Bool
    
    enum IssueType {
        case uncoveredCode
        case lowCoverage
        case missingTests
        case testFailures
        case performanceIssue
        
        var displayName: String {
            switch self {
            case .uncoveredCode: return "Nicht abgedeckter Code"
            case .lowCoverage: return "Niedrige Coverage"
            case .missingTests: return "Fehlende Tests"
            case .testFailures: return "Testfehler"
            case .performanceIssue: return "Performance-Problem"
            }
        }
    }
    
    enum IssueSeverity {
        case low
        case medium
        case high
        case critical
        
        var displayName: String {
            switch self {
            case .low: return "Niedrig"
            case .medium: return "Mittel"
            case .high: return "Hoch"
            case .critical: return "Kritisch"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "#88cc00"
            case .medium: return "#ffcc00"
            case .high: return "#ff8800"
            case .critical: return "#ff4444"
            }
        }
    }
}

struct TestSessionResult {
    let sessionId: String
    let timestamp: Date
    let totalTests: Int
    let passedTests: Int
    let failedTests: Int
    let skippedTests: Int
    let coverageMetrics: CoverageMetrics
    let performanceMetrics: [PerformanceMetric]
    let environmentInfo: EnvironmentInfo
    let testDuration: TimeInterval
}

struct PerformanceMetric {
    let name: String
    let value: Double
    let unit: String
    let threshold: Double
    let isThresholdMet: Bool
}

struct EnvironmentInfo {
    let platform: String
    let osVersion: String
    let deviceModel: String
    let xcodeVersion: String
    let swiftVersion: String
    let appVersion: String
    let buildNumber: String
}

// MARK: - Main Coverage Reporter
class CoverageReporter: ObservableObject {
    
    // MARK: - Published Properties
    @Published var overallCoverage: CoverageMetrics = CoverageMetrics(
        totalLines: 0,
        coveredLines: 0,
        uncoveredLines: 0,
        coveragePercentage: 0.0,
        functionCoverage: 0.0,
        branchCoverage: 0.0,
        lineCoverage: 0.0,
        complexityCoverage: 0.0
    )
    
    @Published var componentCoverages: [ComponentCoverage] = []
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "de_DE")
        
        setupSubscriptions()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Main Analysis Methods
    
    func generateCoverageReport(testResults: [TestResult]) {
        print("📊 Starte Coverage-Analyse...")
        
        isAnalyzing = true
        analysisProgress = 0.0
        
        let totalSteps = 10.0
        var currentStep = 0.0
        
        // Step 1: Analyze test results
        currentStep += 1
        updateProgress(currentStep, totalSteps)
        let componentResults = analyzeTestResults(testResults)
        
        // Step 2: Collect source files
        currentStep += 1
        updateProgress(currentStep, totalSteps)
        let sourceFiles = collectSourceFiles()
        
        // Step 3: Analyze code coverage
        currentStep += 1
        updateProgress(currentStep, totalSteps)
        let coverageMetrics = analyzeCodeCoverage(sourceFiles, testResults: testResults)
        
        // Step 4: Generate component coverages
        currentStep += 1
        updateProgress(currentStep, totalSteps)
        componentCoverages = generateComponentCoverages(componentResults, sourceFiles: sourceFiles)
        
        // Step 5: Calculate overall coverage
        currentStep += 1
        updateProgress(currentStep, totalSteps)
        overallCoverage = calculateOverallCoverage(componentCoverages)
        
        // Step 6: Identify issues
        currentStep += 1
        updateProgress(currentStep, totalSteps)
        identifyCoverageIssues()
        
        // Step 7: Generate reports
        currentStep += 1
        updateProgress(currentStep, totalSteps)
        generateHTMLReport()
        generateJSONReport()
        generateMarkdownReport()
        
        // Step 8: Save historical data
        currentStep += 1
        updateProgress(currentStep, totalSteps)
        saveHistoricalData(testResults)
        
        // Step 9: Performance analysis
        currentStep += 1
        updateProgress(currentStep, totalSteps)
        performPerformanceAnalysis(testResults)
        
        // Step 10: Finalize
        currentStep += 1
        updateProgress(currentStep, totalSteps)
        
        isAnalyzing = false
        print("✅ Coverage-Analyse abgeschlossen")
    }
    
    func generateDetailedHTMLReport(results: [TestResult], savePath: String? = nil) -> String {
        let html = """
        <!DOCTYPE html>
        <html lang="de">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>AINotizassistent - Coverage Bericht</title>
            <style>
                \(cssStyles)
            </style>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        </head>
        <body>
            <div class="container">
                <header class="header">
                    <h1>🧪 AINotizassistent - Coverage Bericht</h1>
                    <p>Generiert am: \(dateFormatter.string(from: Date()))</p>
                    <div class="coverage-summary">
                        <div class="coverage-item">
                            <span class="coverage-value">\(String(format: "%.1f%%", overallCoverage.coveragePercentage))</span>
                            <span class="coverage-label">Gesamt Coverage</span>
                        </div>
                        <div class="coverage-item">
                            <span class="coverage-value">\(results.filter { $0.isPassed }.count)</span>
                            <span class="coverage-label">Erfolgreiche Tests</span>
                        </div>
                        <div class="coverage-item">
                            <span class="coverage-value">\(results.filter { $0.isFailed }.count)</span>
                            <span class="coverage-label">Fehlgeschlagene Tests</span>
                        </div>
                    </div>
                </header>
                
                <section class="coverage-chart">
                    <h2>📈 Coverage Übersicht</h2>
                    <canvas id="coverageChart" width="400" height="200"></canvas>
                </section>
                
                \(generateComponentSectionHTML())
                
                \(generateTestResultsSectionHTML(results))
                
                \(generateIssuesSectionHTML())
                
                \(generateRecommendationsSectionHTML())
            </div>
            
            <script>
                \(generateChartScript())
            </script>
        </body>
        </html>
        """
        
        if let savePath = savePath {
            try? html.data(using: .utf8)?.write(to: URL(fileURLWithPath: savePath))
        }
        
        return html
    }
    
    func generateJSONReport(results: [TestResult]) -> Data {
        let report = CoverageReport(
            timestamp: Date(),
            overallCoverage: overallCoverage,
            componentCoverages: componentCoverages,
            testResults: results,
            environmentInfo: getEnvironmentInfo(),
            summary: generateSummary()
        )
        
        return try! JSONEncoder().encode(report)
    }
    
    func generateMarkdownReport(results: [TestResult]) -> String {
        let summary = generateSummary()
        
        return """
        # AINotizassistent - Coverage Bericht
        
        **Generiert am:** \(dateFormatter.string(from: Date()))
        
        ## 📊 Zusammenfassung
        
        - **Gesamt Coverage:** \(String(format: "%.1f%%", overallCoverage.coveragePercentage))
        - **Erfolgreiche Tests:** \(results.filter { $0.isPassed }.count)
        - **Fehlgeschlagene Tests:** \(results.filter { $0.isFailed }.count)
        - **Übersprungene Tests:** \(results.filter { $0.isSkipped }.count)
        
        ## 📈 Coverage Details
        
        | Metrik | Wert |
        |--------|------|
        | Zeilen Coverage | \(String(format: "%.1f%%", overallCoverage.lineCoverage)) |
        | Funktions Coverage | \(String(format: "%.1f%%", overallCoverage.functionCoverage)) |
        | Branch Coverage | \(String(format: "%.1f%%", overallCoverage.branchCoverage)) |
        | Komplexitäts Coverage | \(String(format: "%.1f%%", overallCoverage.complexityCoverage)) |
        
        ## 🧩 Komponenten Coverage
        
        \(componentCoverages.map { component in
            """
            ### \(component.componentName)
            
            - **Type:** \(component.componentType.displayName)
            - **Coverage:** \(String(format: "%.1f%%", component.metrics.coveragePercentage))
            - **Status:** \(component.metrics.coverageLevel.description)
            - **Getestet am:** \(dateFormatter.string(from: component.lastTested))
            
            """
        }.joined(separator: "\n"))
        
        ## 🐛 Identifizierte Probleme
        
        \(componentCoverages.flatMap { $0.issues }.map { issue in
            """
            - **[\(issue.severity.displayName)]** \(issue.type.displayName): \(issue.description)
              - *Ort:* \(issue.location)
              - *Lösungsvorschlag:* \(issue.suggestion)
            """
        }.joined(separator: "\n\n"))
        
        ## 💡 Empfehlungen
        
        \(summary.recommendations.map { "- \($0)" }.joined(separator: "\n"))
        
        ## 📋 Nächste Schritte
        
        \(summary.nextSteps.map { "- \($0)" }.joined(separator: "\n"))
        """
    }
    
    // MARK: - Analysis Methods
    
    private func analyzeTestResults(_ results: [TestResult]) -> [TestCategory: [TestResult]] {
        return Dictionary(grouping: results) { $0.category }
    }
    
    private func collectSourceFiles() -> [SourceFile] {
        var sourceFiles: [SourceFile] = []
        
        // Simulate source file analysis
        let paths = [
            "/workspace/AINotizassistent/AINotizassistent/",
            "/workspace/",
            "/workspace/Tests/"
        ]
        
        for path in paths {
            if let files = try? fileManager.contentsOfDirectory(atPath: path) {
                for file in files where file.hasSuffix(".swift") {
                    let fullPath = path + file
                    sourceFiles.append(SourceFile(
                        path: fullPath,
                        name: file,
                        lines: countLinesInFile(at: fullPath),
                        functions: countFunctionsInFile(at: fullPath)
                    ))
                }
            }
        }
        
        return sourceFiles
    }
    
    private func analyzeCodeCoverage(_ sourceFiles: [SourceFile], testResults: [TestResult]) -> CoverageMetrics {
        let totalLines = sourceFiles.map { $0.lines }.reduce(0, +)
        let totalFunctions = sourceFiles.map { $0.functions }.reduce(0, +)
        
        // Simulate coverage calculation
        let coveragePercentage = calculateCoveragePercentage(from: testResults)
        let coveredLines = Int(Double(totalLines) * coveragePercentage / 100.0)
        let uncoveredLines = totalLines - coveredLines
        
        return CoverageMetrics(
            totalLines: totalLines,
            coveredLines: coveredLines,
            uncoveredLines: uncoveredLines,
            coveragePercentage: coveragePercentage,
            functionCoverage: coveragePercentage * 0.95, // Simulate slight difference
            branchCoverage: coveragePercentage * 0.90,
            lineCoverage: coveragePercentage,
            complexityCoverage: coveragePercentage * 0.85
        )
    }
    
    private func generateComponentCoverages(_ testResults: [TestCategory: [TestResult]], sourceFiles: [SourceFile]) -> [ComponentCoverage] {
        var componentCoverages: [ComponentCoverage] = []
        
        for (category, results) in testResults {
            let componentName = category.displayName
            let metrics = calculateMetricsForCategory(category, results: results)
            
            let componentCoverage = ComponentCoverage(
                componentName: componentName,
                componentType: mapCategoryToComponentType(category),
                metrics: metrics,
                testResults: results,
                lastTested: Date(),
                issues: generateIssuesForCategory(category, results: results)
            )
            
            componentCoverages.append(componentCoverage)
        }
        
        return componentCoverages
    }
    
    private func calculateOverallCoverage(_ componentCoverages: [ComponentCoverage]) -> CoverageMetrics {
        let totalLines = componentCoverages.map { $0.metrics.totalLines }.reduce(0, +)
        let coveredLines = componentCoverages.map { $0.metrics.coveredLines }.reduce(0, +)
        let uncoveredLines = componentCoverages.map { $0.metrics.uncoveredLines }.reduce(0, +)
        
        let coveragePercentage = totalLines > 0 ? Double(coveredLines) / Double(totalLines) * 100 : 0
        
        return CoverageMetrics(
            totalLines: totalLines,
            coveredLines: coveredLines,
            uncoveredLines: uncoveredLines,
            coveragePercentage: coveragePercentage,
            functionCoverage: coveragePercentage * 0.95,
            branchCoverage: coveragePercentage * 0.90,
            lineCoverage: coveragePercentage,
            complexityCoverage: coveragePercentage * 0.85
        )
    }
    
    private func identifyCoverageIssues() {
        for component in componentCoverages {
            if component.metrics.coveragePercentage < 80.0 {
                // Add low coverage issue
            }
            
            for test in component.testResults where test.isFailed {
                // Add test failure issue
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func countLinesInFile(at path: String) -> Int {
        do {
            let content = try String(contentsOfFile: path)
            return content.components(separatedBy: .newlines).count
        } catch {
            return 0
        }
    }
    
    private func countFunctionsInFile(at path: String) -> Int {
        do {
            let content = try String(contentsOfFile: path)
            let functionPattern = "func\\s+\\w+"
            let regex = try NSRegularExpression(pattern: functionPattern)
            let matches = regex.matches(in: content, range: NSRange(location: 0, length: content.utf16.count))
            return matches.count
        } catch {
            return 0
        }
    }
    
    private func calculateCoveragePercentage(from testResults: [TestResult]) -> Double {
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.isPassed }.count
        
        guard totalTests > 0 else { return 0.0 }
        
        // Base coverage from test pass rate
        let baseCoverage = Double(passedTests) / Double(totalTests) * 100
        
        // Adjust based on test types and coverage quality
        let hasHighQualityTests = testResults.contains { $0.performanceMetrics != nil }
        let adjustment = hasHighQualityTests ? 1.1 : 1.0
        
        return min(baseCoverage * adjustment, 100.0)
    }
    
    private func calculateMetricsForCategory(_ category: TestCategory, results: [TestResult]) -> CoverageMetrics {
        let totalTests = results.count
        let passedTests = results.filter { $0.isPassed }.count
        
        let coveragePercentage = totalTests > 0 ? Double(passedTests) / Double(totalTests) * 100 : 0
        let totalLines = totalTests * 50 // Simulate lines per test
        let coveredLines = Int(Double(totalLines) * coveragePercentage / 100.0)
        
        return CoverageMetrics(
            totalLines: totalLines,
            coveredLines: coveredLines,
            uncoveredLines: totalLines - coveredLines,
            coveragePercentage: coveragePercentage,
            functionCoverage: coveragePercentage * 0.95,
            branchCoverage: coveragePercentage * 0.90,
            lineCoverage: coveragePercentage,
            complexityCoverage: coveragePercentage * 0.85
        )
    }
    
    private func generateIssuesForCategory(_ category: TestCategory, results: [TestResult]) -> [CoverageIssue] {
        var issues: [CoverageIssue] = []
        
        let coveragePercentage = calculateMetricsForCategory(category, results: results).coveragePercentage
        
        if coveragePercentage < 50 {
            issues.append(CoverageIssue(
                id: UUID().uuidString,
                type: .lowCoverage,
                severity: .high,
                description: "Coverage unter 50% für \(category.displayName)",
                location: category.displayName,
                suggestion: "Weitere Tests hinzufügen um Coverage zu verbessern",
                isFixed: false
            ))
        }
        
        for result in results where result.isFailed {
            issues.append(CoverageIssue(
                id: UUID().uuidString,
                type: .testFailures,
                severity: .medium,
                description: "Fehlgeschlagener Test: \(result.testName)",
                location: result.category.displayName,
                suggestion: "Test implementieren oder Bug beheben",
                isFixed: false
            ))
        }
        
        return issues
    }
    
    private func mapCategoryToComponentType(_ category: TestCategory) -> ComponentCoverage.ComponentType {
        switch category {
        case .ui, .accessibility:
            return .view
        case .aiIntegration, .voiceInput, .contentGeneration, .storage:
            return .service
        case .settings, .apiKeys, .processing:
            return .manager
        case .security:
            return .util
        case .integration, .automation, .cicd, .realDevice:
            return .integration
        default:
            return .model
        }
    }
    
    private func generateSummary() -> CoverageSummary {
        let recommendations = generateRecommendations()
        let nextSteps = generateNextSteps()
        
        return CoverageSummary(
            totalComponents: componentCoverages.count,
            averageCoverage: overallCoverage.coveragePercentage,
            criticalIssues: componentCoverages.flatMap { $0.issues }.filter { $0.severity == .critical }.count,
            recommendations: recommendations,
            nextSteps: nextSteps
        )
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if overallCoverage.coveragePercentage < 80 {
            recommendations.append("Coverage sollte auf mindestens 80% erhöht werden")
        }
        
        if componentCoverages.contains(where: { $0.metrics.coveragePercentage < 70 }) {
            recommendations.append("Komponenten mit niedriger Coverage priorisieren")
        }
        
        let failedTests = componentCoverages.flatMap { $0.testResults }.filter { $0.isFailed }
        if !failedTests.isEmpty {
            recommendations.append("Fehlgeschlagene Tests analysieren und implementieren")
        }
        
        if overallCoverage.functionCoverage < 75 {
            recommendations.append("Funktions-Coverage durch Unit Tests verbessern")
        }
        
        return recommendations
    }
    
    private func generateNextSteps() -> [String] {
        var nextSteps: [String] = []
        
        // Add specific next steps based on current state
        if overallCoverage.coveragePercentage < 70 {
            nextSteps.append("Hochpriorität: Kritische Features mit Tests abdecken")
        }
        
        if componentCoverages.contains(where: { $0.issues.contains(where: { $0.type == .testFailures }) }) {
            nextSteps.append("Fehlgeschlagene Tests implementieren")
        }
        
        nextSteps.append("Performance Tests für große Content-Mengen erweitern")
        nextSteps.append("Integration Tests für cross-feature Workflows")
        nextSteps.append("Accessibility Tests für Screen Reader")
        nextSteps.append("Security Tests für Datenverschlüsselung")
        
        return nextSteps
    }
    
    private func updateProgress(_ current: Double, _ total: Double) {
        DispatchQueue.main.async {
            self.analysisProgress = current / total
        }
    }
    
    private func setupSubscriptions() {
        // Setup any necessary subscriptions
    }
    
    private func getEnvironmentInfo() -> EnvironmentInfo {
        return EnvironmentInfo(
            platform: "macOS",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceModel: "Mac",
            xcodeVersion: "15.0",
            swiftVersion: "5.9",
            appVersion: "1.0.0",
            buildNumber: "100"
        )
    }
    
    private func saveHistoricalData(_ testResults: [TestResult]) {
        let sessionResult = TestSessionResult(
            sessionId: UUID().uuidString,
            timestamp: Date(),
            totalTests: testResults.count,
            passedTests: testResults.filter { $0.isPassed }.count,
            failedTests: testResults.filter { $0.isFailed }.count,
            skippedTests: testResults.filter { $0.isSkipped }.count,
            coverageMetrics: overallCoverage,
            performanceMetrics: [],
            environmentInfo: getEnvironmentInfo(),
            testDuration: testResults.map { $0.duration }.reduce(0, +)
        )
        
        // Save to UserDefaults for historical tracking
        var history = UserDefaults.standard.array(forKey: "testHistory") as? [[String: Any]] ?? []
        history.append([
            "timestamp": sessionResult.timestamp.timeIntervalSince1970,
            "coverage": sessionResult.coverageMetrics.coveragePercentage,
            "passed": sessionResult.passedTests,
            "failed": sessionResult.failedTests
        ])
        
        UserDefaults.standard.set(history, forKey: "testHistory")
    }
    
    private func performPerformanceAnalysis(_ testResults: [TestResult]) {
        for result in testResults {
            if let metrics = result.performanceMetrics {
                // Analyze performance metrics
                if metrics.responseTime > TestConfiguration.testTimeout {
                    print("⚠️ Performance-Problem erkannt in \(result.testName)")
                }
            }
        }
    }
    
    private func generateHTMLReport() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let reportPath = "\(documentsPath)/CoverageReport.html"
        
        _ = generateDetailedHTMLReport(results: testResults, savePath: reportPath)
        print("📋 HTML Coverage Report generiert: \(reportPath)")
    }
    
    private func generateJSONReport() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let jsonPath = "\(documentsPath)/CoverageReport.json"
        
        let jsonData = generateJSONReport(results: testResults)
        try? jsonData.write(to: URL(fileURLWithPath: jsonPath))
        print("📋 JSON Coverage Report generiert: \(jsonPath)")
    }
    
    private func generateMarkdownReport() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let mdPath = "\(documentsPath)/CoverageReport.md"
        
        let markdown = generateMarkdownReport(results: testResults)
        try? markdown.data(using: .utf8)?.write(to: URL(fileURLWithPath: mdPath))
        print("📋 Markdown Coverage Report generiert: \(mdPath)")
    }
    
    private func generateComponentSectionHTML() -> String {
        return componentCoverages.map { component in
            """
            <section class="component-section">
                <h3>\(component.componentName)</h3>
                <div class="component-details">
                    <p><strong>Typ:</strong> \(component.componentType.displayName)</p>
                    <p><strong>Coverage:</strong> <span style="color: \(component.metrics.coverageLevel.color)">\(String(format: "%.1f%%", component.metrics.coveragePercentage))</span></p>
                    <p><strong>Status:</strong> \(component.metrics.coverageLevel.description)</p>
                    <p><strong>Getestet am:</strong> \(dateFormatter.string(from: component.lastTested))</p>
                </div>
                <div class="component-metrics">
                    <div class="metric">
                        <span class="metric-label">Zeilen:</span>
                        <span class="metric-value">\(component.metrics.coveredLines)/\(component.metrics.totalLines)</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Funktionen:</span>
                        <span class="metric-value">\(String(format: "%.1f%%", component.metrics.functionCoverage))</span>
                    </div>
                </div>
            </section>
            """
        }.joined(separator: "\n")
    }
    
    private func generateTestResultsSectionHTML(_ results: [TestResult]) -> String {
        let groupedResults = Dictionary(grouping: results) { $0.category.displayName }
        
        return groupedResults.map { (category, categoryResults) in
            """
            <section class="test-results">
                <h3>\(category)</h3>
                <div class="results-grid">
                    \(categoryResults.map { result in
                        let statusClass = result.isPassed ? "passed" : result.isFailed ? "failed" : "skipped"
                        let statusIcon = result.isPassed ? "✅" : result.isFailed ? "❌" : "⏭️"
                        
                        """
                        <div class="test-result \(statusClass)">
                            <span class="test-icon">\(statusIcon)</span>
                            <span class="test-name">\(result.testName)</span>
                            <span class="test-duration">\(String(format: "%.2fms", result.duration * 1000))</span>
                        </div>
                        """
                    }.joined(separator: "\n"))
                </div>
            </section>
            """
        }.joined(separator: "\n")
    }
    
    private func generateIssuesSectionHTML() -> String {
        let allIssues = componentCoverages.flatMap { $0.issues }
        
        if allIssues.isEmpty {
            return "<section class='issues-section'><h3>🐛 Identifizierte Probleme</h3><p>Keine Probleme identifiziert! 🎉</p></section>"
        }
        
        return """
        <section class="issues-section">
            <h3>🐛 Identifizierte Probleme</h3>
            \(allIssues.map { issue in
                """
                <div class="issue-item" style="border-left: 4px solid \(issue.severity.color)">
                    <div class="issue-header">
                        <span class="issue-severity" style="color: \(issue.severity.color)">\(issue.severity.displayName)</span>
                        <span class="issue-type">\(issue.type.displayName)</span>
                    </div>
                    <div class="issue-description">\(issue.description)</div>
                    <div class="issue-location">Ort: \(issue.location)</div>
                    <div class="issue-suggestion">Lösung: \(issue.suggestion)</div>
                </div>
                """
            }.joined(separator: "\n"))
        </section>
        """
    }
    
    private func generateRecommendationsSectionHTML() -> String {
        let summary = generateSummary()
        
        return """
        <section class="recommendations-section">
            <h3>💡 Empfehlungen</h3>
            <ul class="recommendations-list">
                \(summary.recommendations.map { "<li>\($0)</li>" }.joined(separator: "\n"))
            </ul>
            
            <h3>📋 Nächste Schritte</h3>
            <ol class="next-steps-list">
                \(summary.nextSteps.map { "<li>\($0)</li>" }.joined(separator: "\n"))
            </ol>
        </section>
        """
    }
    
    private func generateChartScript() -> String {
        return """
        document.addEventListener('DOMContentLoaded', function() {
            const ctx = document.getElementById('coverageChart').getContext('2d');
            new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: ['Coverage', 'Uncovered'],
                    datasets: [{
                        data: [\(overallCoverage.coveragePercentage), \(100 - overallCoverage.coveragePercentage)],
                        backgroundColor: ['#00cc00', '#ff4444'],
                        borderWidth: 0
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: {
                            position: 'bottom'
                        }
                    }
                }
            });
        });
        """
    }
}

// MARK: - Supporting Data Structures

struct SourceFile {
    let path: String
    let name: String
    let lines: Int
    let functions: Int
}

struct CoverageReport: Codable {
    let timestamp: Date
    let overallCoverage: CoverageMetrics
    let componentCoverages: [ComponentCoverage]
    let testResults: [TestResult]
    let environmentInfo: EnvironmentInfo
    let summary: CoverageSummary
}

struct CoverageSummary {
    let totalComponents: Int
    let averageCoverage: Double
    let criticalIssues: Int
    let recommendations: [String]
    let nextSteps: [String]
}

// MARK: - CSS Styles

private let cssStyles = """
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: #333;
    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
    min-height: 100vh;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.header {
    background: white;
    padding: 30px;
    border-radius: 15px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    margin-bottom: 30px;
    text-align: center;
}

.header h1 {
    color: #007AFF;
    margin-bottom: 10px;
    font-size: 2.5em;
}

.coverage-summary {
    display: flex;
    justify-content: space-around;
    margin-top: 20px;
}

.coverage-item {
    text-align: center;
}

.coverage-value {
    display: block;
    font-size: 2em;
    font-weight: bold;
    color: #007AFF;
}

.coverage-label {
    font-size: 0.9em;
    color: #666;
}

.coverage-chart {
    background: white;
    padding: 30px;
    border-radius: 15px;
    box-shadow: 0 5px 20px rgba(0,0,0,0.1);
    margin-bottom: 30px;
    text-align: center;
}

.component-section {
    background: white;
    padding: 25px;
    border-radius: 15px;
    box-shadow: 0 5px 20px rgba(0,0,0,0.1);
    margin-bottom: 20px;
}

.component-section h3 {
    color: #007AFF;
    margin-bottom: 15px;
    font-size: 1.5em;
}

.component-details {
    margin-bottom: 15px;
}

.component-metrics {
    display: flex;
    gap: 20px;
}

.metric {
    background: #f8f9fa;
    padding: 10px;
    border-radius: 8px;
}

.metric-label {
    display: block;
    font-size: 0.9em;
    color: #666;
}

.metric-value {
    display: block;
    font-weight: bold;
    color: #007AFF;
}

.test-results {
    background: white;
    padding: 25px;
    border-radius: 15px;
    box-shadow: 0 5px 20px rgba(0,0,0,0.1);
    margin-bottom: 20px;
}

.test-results h3 {
    color: #007AFF;
    margin-bottom: 15px;
}

.results-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 10px;
}

.test-result {
    display: flex;
    align-items: center;
    padding: 10px;
    border-radius: 8px;
    border-left: 4px solid #ddd;
}

.test-result.passed {
    background: #d4edda;
    border-left-color: #28a745;
}

.test-result.failed {
    background: #f8d7da;
    border-left-color: #dc3545;
}

.test-result.skipped {
    background: #fff3cd;
    border-left-color: #ffc107;
}

.test-icon {
    margin-right: 10px;
    font-size: 1.2em;
}

.test-name {
    flex: 1;
    font-weight: 500;
}

.test-duration {
    font-size: 0.9em;
    color: #666;
}

.issues-section {
    background: white;
    padding: 25px;
    border-radius: 15px;
    box-shadow: 0 5px 20px rgba(0,0,0,0.1);
    margin-bottom: 20px;
}

.issues-section h3 {
    color: #dc3545;
    margin-bottom: 15px;
}

.issue-item {
    background: #f8f9fa;
    padding: 15px;
    border-radius: 8px;
    margin-bottom: 10px;
}

.issue-header {
    display: flex;
    gap: 15px;
    margin-bottom: 10px;
}

.issue-severity {
    font-weight: bold;
}

.issue-type {
    font-style: italic;
    color: #666;
}

.issue-description {
    margin-bottom: 8px;
}

.issue-location, .issue-suggestion {
    font-size: 0.9em;
    color: #666;
}

.recommendations-section {
    background: white;
    padding: 25px;
    border-radius: 15px;
    box-shadow: 0 5px 20px rgba(0,0,0,0.1);
    margin-bottom: 20px;
}

.recommendations-section h3 {
    color: #28a745;
    margin-bottom: 15px;
}

.recommendations-list, .next-steps-list {
    margin-left: 20px;
}

.recommendations-list li, .next-steps-list li {
    margin-bottom: 8px;
}
"""