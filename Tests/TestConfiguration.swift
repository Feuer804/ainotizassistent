//
//  TestConfiguration.swift
//  AINotizassistent - Test Configuration
//
//  Konfigurationsdatei für alle Test-Parameter und -Einstellungen
//  Zentrale Stelle für Test-Management und CI/CD Integration
//

import Foundation
import Network

// MARK: - Global Test Configuration
struct TestConfig {
    
    // MARK: - Environment Settings
    static let environment: TestEnvironment = .development
    static let isRunningInCI = ProcessInfo.processInfo.environment["CI"] != nil
    static let isRunningInXcode = ProcessInfo.processInfo.processName.contains("xcodebuild")
    
    // MARK: - Timeout Configuration
    static let defaultTimeout: TimeInterval = 30.0
    static let networkTimeout: TimeInterval = 45.0
    static let aiResponseTimeout: TimeInterval = 60.0
    static let largeContentTimeout: TimeInterval = 120.0
    static let integrationTestTimeout: TimeInterval = 300.0
    
    // MARK: - Performance Thresholds
    static let maxResponseTime: TimeInterval = 5.0
    static let maxMemoryUsage: UInt64 = 100 * 1024 * 1024 // 100MB
    static let maxCPUUsage: Double = 80.0 // Percentage
    static let minThroughput: Double = 10.0 // operations per second
    
    // MARK: - Coverage Requirements
    static let minimumCoverage: Double = 80.0
    static let targetCoverage: Double = 90.0
    static let criticalCoverage: Double = 95.0
    
    // MARK: - Test Data Configuration
    static let bulkTestDataCount = 100
    static let largeContentSize = 10000
    static let stressTestIterations = 1000
    
    // MARK: - Parallel Execution
    static let maxParallelTests = 5
    static let maxConcurrentProcesses = 3
    
    // MARK: - API Configuration for Testing
    static let testAPIKeys: [APIProvider: String] = [
        .openai: "sk-test-key-for-testing",
        .openrouter: "ork-test-key-for-testing",
        .notion: "secret_test_key_for_testing",
        .whisper: "whisper_test_key_for_testing"
    ]
    
    // MARK: - Mock Server Configuration
    static let mockServerPort = 8080
    static let mockServerBaseURL = "http://localhost:\(mockServerPort)"
    
    // MARK: - Test Database Configuration
    static let testDatabaseName = "AINotizassistent_Test"
    static let testDatabaseURL = "sqlite:///tmp/\(testDatabaseName).db"
    
    // MARK: - Report Configuration
    static let generateHTMLReports = true
    static let generateJSONReports = true
    static let generateMarkdownReports = true
    static let reportRetentionDays = 30
    static let enableSlackNotifications = false
    static let slackWebhookURL: String? = nil
    
    // MARK: - Security Test Configuration
    static let enableSecurityTests = true
    static let enablePenetrationTests = false
    static let encryptionTestEnabled = true
    static let apiSecurityTestEnabled = true
    
    // MARK: - Accessibility Test Configuration
    static let enableAccessibilityTests = true
    static let enableVoiceOverTests = true
    static let enableKeyboardNavigationTests = true
    static let enableColorBlindnessTests = true
    
    // MARK: - Network Simulation Configuration
    static let networkConditions: [NetworkCondition] = [
        NetworkCondition(name: "Fast 3G", bandwidth: 1.6, latency: 150),
        NetworkCondition(name: "Slow 3G", bandwidth: 0.4, latency: 400),
        NetworkCondition(name: "WiFi", bandwidth: 25.0, latency: 20),
        NetworkCondition(name: "Offline", bandwidth: 0, latency: 0)
    ]
    
    // MARK: - Device Configuration for Testing
    static let testDevices: [TestDevice] = [
        TestDevice(name: "iPhone 15", model: "iPhone16,2", screenSize: CGSize(width: 393, height: 852)),
        TestDevice(name: "iPhone SE", model: "iPhone14,6", screenSize: CGSize(width: 375, height: 667)),
        TestDevice(name: "iPad Pro", model: "iPad14,3", screenSize: CGSize(width: 1024, height: 1366)),
        TestDevice(name: "MacBook Pro", model: "MacBookPro18,1", screenSize: CGSize(width: 1512, height: 982))
    ]
    
    // MARK: - Feature Flags for Testing
    static let enableExperimentalFeatures = false
    static let enableBetaFeatures = false
    static let enableDebugLogging = true
    static let enableVerboseOutput = false
    
    // MARK: - CI/CD Specific Configuration
    static let ciConfiguration = CIConfig(
        runPerformanceTests: true,
        runSecurityTests: true,
        runAccessibilityTests: true,
        runRegressionTests: true,
        generateCodeCoverage: true,
        uploadCoverage: true,
        buildNumber: ProcessInfo.processInfo.environment["BUILD_NUMBER"] ?? "0",
        commitHash: ProcessInfo.processInfo.environment["GIT_COMMIT"] ?? "unknown",
        branchName: ProcessInfo.processInfo.environment["GIT_BRANCH"] ?? "unknown"
    )
}

// MARK: - Test Environment Enum
enum TestEnvironment: String, CaseIterable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    case testing = "testing"
    
    var displayName: String {
        switch self {
        case .development: return "Entwicklung"
        case .staging: return "Staging"
        case .production: return "Produktion"
        case .testing: return "Testing"
        }
    }
    
    var isDevelopment: Bool { self == .development }
    var isTesting: Bool { self == .testing }
    var isProduction: Bool { self == .production }
}

// MARK: - Supporting Types
struct NetworkCondition {
    let name: String
    let bandwidth: Double // Mbps
    let latency: Double // ms
}

struct TestDevice {
    let name: String
    let model: String
    let screenSize: CGSize
}

struct CIConfig {
    let runPerformanceTests: Bool
    let runSecurityTests: Bool
    let runAccessibilityTests: Bool
    let runRegressionTests: Bool
    let generateCodeCoverage: Bool
    let uploadCoverage: Bool
    let buildNumber: String
    let commitHash: String
    let branchName: String
}

// MARK: - Test Suite Configuration
struct TestSuiteConfig {
    let name: String
    let categories: [TestCategory]
    let isEnabled: Bool
    let parallelExecution: Bool
    let timeout: TimeInterval
    let retryCount: Int
    let expectedDuration: TimeInterval
    
    static let allFeatures = TestSuiteConfig(
        name: "All Features",
        categories: [.menuBar, .textInput, .appDetection, .contentType, .aiIntegration],
        isEnabled: true,
        parallelExecution: true,
        timeout: 300.0,
        retryCount: 2,
        expectedDuration: 180.0
    )
    
    static let integration = TestSuiteConfig(
        name: "Integration",
        categories: [.automation, .cicd, .realDevice],
        isEnabled: true,
        parallelExecution: false,
        timeout: 600.0,
        retryCount: 1,
        expectedDuration: 300.0
    )
    
    static let performance = TestSuiteConfig(
        name: "Performance",
        categories: [.performance, .memoryLeaks, .concurrent],
        isEnabled: true,
        parallelExecution: true,
        timeout: 1200.0,
        retryCount: 1,
        expectedDuration: 600.0
    )
    
    static let security = TestSuiteConfig(
        name: "Security",
        categories: [.security, .errorHandling],
        isEnabled: true,
        parallelExecution: false,
        timeout: 900.0,
        retryCount: 1,
        expectedDuration: 450.0
    )
    
    static let accessibility = TestSuiteConfig(
        name: "Accessibility",
        categories: [.accessibility],
        isEnabled: true,
        parallelExecution: true,
        timeout: 600.0,
        retryCount: 2,
        expectedDuration: 300.0
    )
}

// MARK: - Test Data Configuration
struct TestDataConfig {
    static let emailTemplates = [
        """
        Von: john@example.com
        An: team@example.com
        Betreff: Projekt Update
        
        Hallo Team,
        
        hier ein kurzer Status-Update zu unserem aktuellen Projekt.
        
        Beste Grüße,
        John
        """,
        
        """
        Meeting with Client
        
        Date: Tomorrow 2 PM
        Location: Conference Room A
        Participants: John, Jane, Mike
        
        Agenda:
        1. Project Status Review
        2. Timeline Discussion
        3. Budget Planning
        
        Please confirm your attendance.
        """
    ]
    
    static let meetingTemplates = [
        """
        Sprint Planning Meeting
        
        Teilnehmer: Anna Schmidt, Max Müller, Lisa Weber
        
        Agenda:
        1. Sprint Ziele definieren
        2. Aufgabenverteilung
        3. Timeline Review
        
        Entscheidungen:
        - Sprint 2 beginnt am Montag
        - Fokus auf Performance-Optimierung
        
        Nächste Schritte:
        - Max: Database Optimierung
        - Anna: Frontend Refactoring
        - Lisa: Testing erweitern
        """,
        
        """
        Weekly Team Standup
        
        Team: Development Team
        
        Updates:
        - Anna: UI Components 80% complete
        - Max: Backend API integration finished
        - Lisa: Unit tests coverage at 85%
        
        Blockers:
        - Need approval for new design assets
        
        Next Steps:
        - Complete remaining UI components
        - Start integration testing
        - Schedule client demo
        """
    ]
    
    static let codeSnippets = [
        """
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
        """,
        
        """
        class ContentProcessor {
            async process(content: string): Promise<ProcessedContent> {
                const analysis = await this.analyzer.analyze(content);
                const enhanced = await this.enhancer.enhance(content);
                
                return {
                    original: content,
                    analysis,
                    enhanced,
                    metadata: this.generateMetadata(analysis)
                };
            }
        }
        """
    ]
}

// MARK: - Mock Configuration
struct MockConfig {
    static let enableMockAPI = true
    static let enableMockStorage = true
    static let enableMockVoiceInput = true
    static let enableMockShortcutManager = true
    
    static let mockResponseDelays: [TestCategory: TimeInterval] = [
        .aiIntegration: 1.0,
        .voiceInput: 2.0,
        .contentGeneration: 1.5,
        .storage: 0.5
    ]
    
    static let mockFailureRates: [TestCategory: Double] = [
        .aiIntegration: 0.05, // 5% failure rate
        .voiceInput: 0.10,    // 10% failure rate
        .storage: 0.02,       // 2% failure rate
        .contentGeneration: 0.03 // 3% failure rate
    ]
}

// MARK: - Report Configuration
struct ReportConfig {
    static let outputDirectory = "TestReports"
    static let reportFormats: [ReportFormat] = [.html, .json, .markdown, .xml]
    
    static let coverageThresholds = CoverageThresholds(
        overall: 80.0,
        critical: 95.0,
        warning: 70.0
    )
    
    static let performanceThresholds = PerformanceThresholds(
        responseTime: 5.0,
        memoryUsage: 100 * 1024 * 1024, // 100MB
        cpuUsage: 80.0,
        diskUsage: 500 * 1024 * 1024    // 500MB
    )
    
    static let slackConfig = SlackConfig(
        enabled: false,
        webhookURL: "",
        channel: "#testing",
        mentionOnFailure: true,
        includeScreenshots: true
    )
}

// MARK: - Supporting Report Types
struct CoverageThresholds {
    let overall: Double
    let critical: Double
    let warning: Double
}

struct PerformanceThresholds {
    let responseTime: TimeInterval
    let memoryUsage: UInt64
    let cpuUsage: Double
    let diskUsage: UInt64
}

struct SlackConfig {
    let enabled: Bool
    let webhookURL: String
    let channel: String
    let mentionOnFailure: Bool
    let includeScreenshots: Bool
}

enum ReportFormat: String, CaseIterable {
    case html = "html"
    case json = "json"
    case markdown = "md"
    case xml = "xml"
    
    var displayName: String {
        switch self {
        case .html: return "HTML"
        case .json: return "JSON"
        case .markdown: return "Markdown"
        case .xml: return "XML"
        }
    }
}

// MARK: - Environment Detection
extension TestConfig {
    
    static func isRunningInXCTest() -> Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    static func getTestDeviceInfo() -> TestDevice {
        let model = ProcessInfo.processInfo.machineType
        
        if model.contains("iPhone") {
            return TestDevice(name: "iPhone", model: model, screenSize: CGSize(width: 375, height: 812))
        } else if model.contains("iPad") {
            return TestDevice(name: "iPad", model: model, screenSize: CGSize(width: 768, height: 1024))
        } else {
            return TestDevice(name: "Mac", model: model, screenSize: CGSize(width: 1280, height: 800))
        }
    }
    
    static func getCurrentTestSuite() -> TestSuiteConfig {
        // Determine current test suite based on environment or command line
        if isRunningInCI {
            return TestSuiteConfig.integration
        } else {
            return TestSuiteConfig.allFeatures
        }
    }
}

// MARK: - Configuration Validation
extension TestConfig {
    
    static func validateConfiguration() -> ValidationResult {
        var issues: [String] = []
        
        // Validate timeouts
        if defaultTimeout <= 0 {
            issues.append("Default timeout must be positive")
        }
        
        if minimumCoverage < 0 || minimumCoverage > 100 {
            issues.append("Minimum coverage must be between 0 and 100")
        }
        
        // Validate API keys format
        for (provider, key) in testAPIKeys {
            if key.isEmpty {
                issues.append("API key for \(provider.displayName) is empty")
            }
        }
        
        // Validate network conditions
        for condition in networkConditions {
            if condition.bandwidth < 0 {
                issues.append("Bandwidth for \(condition.name) is negative")
            }
            if condition.latency < 0 {
                issues.append("Latency for \(condition.name) is negative")
            }
        }
        
        return ValidationResult(isValid: issues.isEmpty, issues: issues)
    }
}

struct ValidationResult {
    let isValid: Bool
    let issues: [String]
}

// MARK: - Configuration Manager
class ConfigurationManager {
    
    static let shared = ConfigurationManager()
    
    private init() {}
    
    func loadConfiguration(from filePath: String) throws {
        // Load configuration from file
        print("📁 Lade Konfiguration von: \(filePath)")
    }
    
    func saveConfiguration(to filePath: String) throws {
        // Save current configuration to file
        print("💾 Speichere Konfiguration nach: \(filePath)")
    }
    
    func resetToDefaults() {
        print("🔄 Setze Konfiguration auf Standardwerte zurück")
    }
    
    func updateSetting<T>(_ key: String, value: T) {
        print("⚙️ Update Setting \(key) = \(value)")
    }
    
    func getSetting<T>(_ key: String, defaultValue: T) -> T {
        // Return setting value or default
        return defaultValue
    }
}

// MARK: - Environment Variables Helper
struct EnvVars {
    
    static func get(_ key: String, defaultValue: String = "") -> String {
        return ProcessInfo.processInfo.environment[key] ?? defaultValue
    }
    
    static func getInt(_ key: String, defaultValue: Int = 0) -> Int {
        return Int(ProcessInfo.processInfo.environment[key] ?? "") ?? defaultValue
    }
    
    static func getBool(_ key: String, defaultValue: Bool = false) -> Bool {
        return ProcessInfo.processInfo.environment[key].map { $0.lowercased() == "true" } ?? defaultValue
    }
    
    static func getDouble(_ key: String, defaultValue: Double = 0.0) -> Double {
        return Double(ProcessInfo.processInfo.environment[key] ?? "") ?? defaultValue
    }
}

// MARK: - CI/CD Environment Variables
extension EnvVars {
    
    static var isCI: Bool {
        return get("CI", defaultValue: "false").lowercased() == "true"
    }
    
    static var buildNumber: String {
        return get("BUILD_NUMBER", defaultValue: "local")
    }
    
    static var commitHash: String {
        return get("GIT_COMMIT", defaultValue: "unknown")
    }
    
    static var branchName: String {
        return get("GIT_BRANCH", defaultValue: "unknown")
    }
    
    static var pullRequestNumber: String? {
        return ProcessInfo.processInfo.environment["GITHUB_PR_NUMBER"]
    }
    
    static var slackWebhook: String? {
        return ProcessInfo.processInfo.environment["SLACK_WEBHOOK"]
    }
    
    static var testFlightAPIKey: String? {
        return ProcessInfo.processInfo.environment["TESTFLIGHT_API_KEY"]
    }
}