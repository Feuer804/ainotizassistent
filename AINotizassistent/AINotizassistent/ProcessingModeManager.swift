//
//  ProcessingModeManager.swift
//  Intelligente Notizen App
//  Flexible KI-Verarbeitungs-Modi mit intelligenter Auswahl
//

import Foundation
import Combine
import SwiftUI

// MARK: - Processing Mode Enums
enum ProcessingMode: String, CaseIterable, Codable {
    case cloudOnly = "Cloud Only"
    case localOnly = "Lokal Only"
    case hybrid = "Hybrid"
    case costOptimized = "Kosten-optimiert"
    case privacyFirst = "Privacy-First"
    
    var icon: String {
        switch self {
        case .cloudOnly: return "☁️"
        case .localOnly: return "💻"
        case .hybrid: return "🔄"
        case .costOptimized: return "💰"
        case .privacyFirst: return "🔒"
        }
    }
    
    var description: String {
        switch self {
        case .cloudOnly: return "Nur Cloud-Services nutzen"
        case .localOnly: return "Nur lokale Modelle verwenden"
        case .hybrid: return "Intelligente Automatik-Auswahl"
        case .costOptimized: return "Günstigste verfügbare Option"
        case .privacyFirst: return "Immer lokale Verarbeitung"
        }
    }
}

enum ProcessingTaskType: String, CaseIterable {
    case summary = "Zusammenfassung"
    case keywords = "Keywords"
    case categorization = "Kategorisierung"
    case enhancement = "Verbesserung"
    case questions = "Fragen"
    case analysis = "Analyse"
}

enum SensitivityLevel: String, CaseIterable {
    case public = "Öffentlich"
    case internal = "Intern"
    case confidential = "Vertraulich"
    case highlyConfidential = "Hochvertraulich"
    
    var privacyRisk: Double {
        switch self {
        case .public: return 0.0
        case .internal: return 0.25
        case .confidential: return 0.75
        case .highlyConfidential: return 1.0
        }
    }
}

// MARK: - Processing Decision
struct ProcessingDecision {
    let selectedProvider: KIProviderType
    let selectedMode: ProcessingMode
    let confidence: Double
    let reasoning: String
    let fallbackProvider: KIProviderType?
    let estimatedCost: Double
    let estimatedTime: TimeInterval
    let privacyCompliance: Bool
}

// MARK: - Processing Metrics
struct ProcessingMetrics: Codable {
    var totalRequests: Int = 0
    var cloudRequests: Int = 0
    var localRequests: Int = 0
    var hybridSwitches: Int = 0
    var fallbackActivations: Int = 0
    
    var averageResponseTime: TimeInterval = 0.0
    var averageQualityScore: Double = 0.0
    var averageCostPerRequest: Double = 0.0
    
    var lastUpdated: Date = Date()
    
    var cloudUsagePercentage: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(cloudRequests) / Double(totalRequests) * 100.0
    }
}

// MARK: - Processing Mode Settings
struct ProcessingModeSettings: Codable {
    var preferredMode: ProcessingMode = .hybrid
    var privacyThreshold: Double = 0.5
    var costThreshold: Double = 0.1 // USD per request
    var timeThreshold: TimeInterval = 10.0 // seconds
    var qualityThreshold: Double = 0.8
    var autoSwitchEnabled: Bool = true
    var notificationsEnabled: Bool = true
    var analyticsEnabled: Bool = true
    
    var contentRules: [ContentRule] = []
    
    mutating func updateFromSettings(_ settings: ProcessingModeSettings) {
        self = settings
    }
}

// MARK: - Content Rule
struct ContentRule: Codable, Hashable {
    var name: String
    var pattern: String
    var requiredMode: ProcessingMode
    var priority: Int
    var isActive: Bool = true
    
    func matches(_ text: String) -> Bool {
        return text.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Performance Analytics
struct ProcessingAnalytics {
    var modeUsageStats: [ProcessingMode: Int] = [:]
    var providerSuccessRates: [KIProviderType: Double] = [:]
    var qualityScores: [ProcessingTaskType: [Double]] = [:]
    var costAnalysis: [KIProviderType: Double] = [:]
    var timeAnalysis: [KIProviderType: TimeInterval] = [:]
    
    var recommendations: [String] = []
    
    mutating func addMetric(mode: ProcessingMode, provider: KIProviderType, 
                          taskType: ProcessingTaskType, quality: Double, 
                          cost: Double, time: TimeInterval) {
        modeUsageStats[mode, default: 0] += 1
        
        providerSuccessRates[provider, default: 0.0] += 0.1 // Simple rolling average
        qualityScores[taskType, default: []].append(quality)
        costAnalysis[provider, default: 0.0] += cost
        timeAnalysis[provider, default: 0.0] += time
        
        updateRecommendations()
    }
    
    private mutating func updateRecommendations() {
        recommendations.removeAll()
        
        // Analyze usage patterns and provide recommendations
        if let mostUsedMode = modeUsageStats.max(by: { $0.value < $1.value })?.key,
           mostUsedMode != .hybrid {
            recommendations.append("Häufigster Modus: \(mostUsedMode.rawValue). Hybrid-Modus könnte bessere Ergebnisse liefern.")
        }
        
        // Cost optimization recommendations
        let avgCost = Array(costAnalysis.values).reduce(0, +) / Double(costAnalysis.count)
        if avgCost > 0.05 {
            recommendations.append("Hohe Kosten erkannt. Consider lokale Modelle für Routine-Tasks.")
        }
    }
}

// MARK: - Main Processing Mode Manager
final class ProcessingModeManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentMode: ProcessingMode = .hybrid
    @Published var currentProvider: KIProviderType = .openAI
    @Published var isProcessing: Bool = false
    @Published var lastDecision: ProcessingDecision?
    @Published var metrics: ProcessingMetrics = ProcessingMetrics()
    @Published var analytics: ProcessingAnalytics = ProcessingAnalytics()
    @Published var settings: ProcessingModeSettings = ProcessingModeSettings()
    @Published var notifications: [ProcessingNotification] = []
    
    // MARK: - Dependencies
    private let contentAnalyzer: ContentAnalyzer
    private let providerManager: KIProviderManager
    private let networkMonitor: NetworkMonitor
    private let costCalculator: CostCalculator
    private let qualityAssessor: ContentQualityAssessor
    private let piiDetector: PIIDetector
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaultsKey = "ProcessingModeSettings"
    
    // MARK: - Initialization
    init(contentAnalyzer: ContentAnalyzer = ContentAnalyzer(),
         providerManager: KIProviderManager = KIProviderManager(),
         networkMonitor: NetworkMonitor = NetworkMonitor.shared,
         costCalculator: CostCalculator = CostCalculator(),
         qualityAssessor: ContentQualityAssessor = ContentQualityAssessor(),
         piiDetector: PIIDetector = PIIDetector()) {
        
        self.contentAnalyzer = contentAnalyzer
        self.providerManager = providerManager
        self.networkMonitor = networkMonitor
        self.costCalculator = costCalculator
        self.qualityAssessor = qualityAssessor
        self.piiDetector = piiDetector
        
        loadSettings()
        setupMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Determines the optimal processing mode and provider for given content
    func determineOptimalProcessing(for text: String, 
                                  taskType: ProcessingTaskType,
                                  userPreferences: [String: Any] = [:]) async -> ProcessingDecision {
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        let startTime = Date()
        
        // Step 1: Analyze content sensitivity
        let sensitivityResult = await analyzeContentSensitivity(text)
        
        // Step 2: Check content length and complexity
        let lengthAnalysis = analyzeContentLength(text)
        
        // Step 3: Determine user preferences impact
        let preferenceWeight = calculatePreferenceWeight(userPreferences)
        
        // Step 4: Check provider availability
        let availableProviders = checkProviderAvailability()
        
        // Step 5: Apply processing mode logic
        let decision = await makeProcessingDecision(
            text: text,
            taskType: taskType,
            sensitivity: sensitivityResult,
            lengthAnalysis: lengthAnalysis,
            preferenceWeight: preferenceWeight,
            availableProviders: availableProviders,
            startTime: startTime
        )
        
        // Step 6: Update metrics and analytics
        updateMetrics(for: decision, duration: Date().timeIntervalSince(startTime))
        
        // Step 7: Trigger notifications if needed
        if settings.notificationsEnabled {
            await triggerModeSwitchNotification(decision)
        }
        
        return decision
    }
    
    /// Switches processing mode with fallback mechanisms
    func switchToMode(_ mode: ProcessingMode, withFallback fallback: Bool = true) async -> Bool {
        currentMode = mode
        
        // Try primary provider
        let provider = selectProvider(for: mode)
        let success = await testProvider(provider)
        
        if !success && fallback {
            // Try fallback providers
            let fallbackProvider = selectFallbackProvider(for: mode)
            if let fallback = fallbackProvider {
                currentProvider = fallback
                let fallbackSuccess = await testProvider(fallback)
                
                if fallbackSuccess {
                    await triggerFallbackNotification(from: provider, to: fallback)
                    return true
                }
            }
        }
        
        return success
    }
    
    /// Updates processing settings
    func updateSettings(_ newSettings: ProcessingModeSettings) {
        settings = newSettings
        saveSettings()
    }
    
    /// Gets processing recommendations based on usage patterns
    func getRecommendations() -> [String] {
        return analytics.recommendations
    }
    
    /// Resets metrics and analytics
    func resetMetrics() {
        metrics = ProcessingMetrics()
        analytics = ProcessingAnalytics()
    }
    
    // MARK: - Private Methods
    
    private func analyzeContentSensitivity(_ text: String) async -> (level: SensitivityLevel, confidence: Double, reasons: [String]) {
        let piiScore = await piiDetector.detectPII(text)
        let sensitiveKeywords = detectSensitiveKeywords(text)
        let contextAnalysis = await analyzeContext(text)
        
        var sensitivityLevel: SensitivityLevel = .public
        var confidence = 0.5
        var reasons: [String] = []
        
        // Determine sensitivity level based on multiple factors
        if piiScore > 0.8 || sensitiveKeywords.contains("streng vertraulich") {
            sensitivityLevel = .highlyConfidential
            confidence = 0.9
            reasons.append("Hochsensible Daten erkannt (PII/Sensibel-Keywords)")
        } else if piiScore > 0.5 || sensitiveKeywords.contains("vertraulich") {
            sensitivityLevel = .confidential
            confidence = 0.8
            reasons.append("Vertrauliche Daten erkannt")
        } else if piiScore > 0.2 || sensitiveKeywords.contains("intern") {
            sensitivityLevel = .internal
            confidence = 0.7
            reasons.append("Interne Daten erkannt")
        } else {
            confidence = 0.9
            reasons.append("Öffentliche Daten - keine Sensibilität erkannt")
        }
        
        return (sensitivityLevel, confidence, reasons)
    }
    
    private func analyzeContentLength(_ text: String) -> (length: Int, complexity: Double, suitableForLocal: Bool) {
        let length = text.count
        let words = text.components(separatedBy: .whitespacesAndNewlines).count
        let sentences = text.components(separatedBy: .punctuationCharacters).count
        
        // Calculate complexity score
        let avgWordsPerSentence = Double(words) / Double(max(sentences, 1))
        let complexity = min(avgWordsPerSentence / 20.0, 1.0) // Normalize to 0-1
        
        // Determine if suitable for local processing (length limits)
        let suitableForLocal = length < 5000 && complexity < 0.7
        
        return (length, complexity, suitableForLocal)
    }
    
    private func calculatePreferenceWeight(_ preferences: [String: Any]) -> Double {
        // Analyze user preferences to weight decision factors
        var weight = 1.0
        
        if let privacyPriority = preferences["privacy_priority"] as? Double {
            weight *= (1.0 + privacyPriority) // Increase weight for privacy-focused users
        }
        
        if let speedPriority = preferences["speed_priority"] as? Double {
            weight *= (1.0 + speedPriority) // Speed-focused users prefer cloud
        }
        
        if let costPriority = preferences["cost_priority"] as? Double {
            weight *= (1.0 + costPriority) // Cost-focused users prefer local
        }
        
        return weight
    }
    
    private func checkProviderAvailability() -> [KIProviderType: Bool] {
        var availability: [KIProviderType: Bool] = [:]
        
        // Check network connectivity
        let isOnline = networkMonitor.isConnected
        
        // Check each provider
        for providerType in KIProviderType.allCases {
            availability[providerType] = isOnline && providerManager.providerConfigs[providerType]?.apiKey != ""
        }
        
        return availability
    }
    
    private func makeProcessingDecision(text: String, 
                                      taskType: ProcessingTaskType,
                                      sensitivity: (level: SensitivityLevel, confidence: Double, reasons: [String]),
                                      lengthAnalysis: (length: Int, complexity: Double, suitableForLocal: Bool),
                                      preferenceWeight: Double,
                                      availableProviders: [KIProviderType: Bool],
                                      startTime: Date) async -> ProcessingDecision {
        
        var selectedProvider: KIProviderType = .openAI
        var selectedMode: ProcessingMode = settings.preferredMode
        var confidence: Double = 0.5
        var reasoning: [String] = []
        var fallbackProvider: KIProviderType? = nil
        var estimatedCost: Double = 0.0
        var estimatedTime: TimeInterval = 0.0
        var privacyCompliance: Bool = true
        
        // Apply mode-specific logic
        switch settings.preferredMode {
        case .cloudOnly:
            selectedProvider = selectBestCloudProvider(availableProviders)
            reasoning.append("Cloud-Modus: Immer Cloud-Provider verwenden")
            
        case .localOnly:
            if lengthAnalysis.suitableForLocal {
                selectedProvider = .ollama
                reasoning.append("Lokal-Modus: Lokale Verarbeitung bevorzugt")
            } else {
                selectedProvider = selectBestCloudProvider(availableProviders)
                reasoning.append("Lokal-Modus: Fallback zu Cloud wegen Content-Länge")
                fallbackProvider = .ollama
            }
            
        case .hybrid:
            (selectedProvider, selectedMode, confidence, reasoning, fallbackProvider) = 
                determineHybridMode(text: text, 
                                  sensitivity: sensitivity,
                                  lengthAnalysis: lengthAnalysis,
                                  availableProviders: availableProviders,
                                  preferenceWeight: preferenceWeight)
            
        case .costOptimized:
            selectedProvider = selectMostCostEffectiveProvider(availableProviders)
            reasoning.append("Kosten-optimiert: Günstigste verfügbare Option gewählt")
            
        case .privacyFirst:
            if sensitivity.level.privacyRisk > settings.privacyThreshold {
                selectedProvider = .ollama
                selectedMode = .privacyFirst
                reasoning.append("Privacy-First: Sensible Daten -> Lokale Verarbeitung")
            } else {
                selectedProvider = selectBestCloudProvider(availableProviders)
                reasoning.append("Privacy-First: Keine sensiblen Daten -> Cloud okay")
            }
        }
        
        // Calculate estimates
        estimatedCost = await costCalculator.estimateCost(for: selectedProvider, taskType: taskType)
        estimatedTime = await estimateProcessingTime(provider: selectedProvider, taskType: taskType)
        privacyCompliance = checkPrivacyCompliance(selectedProvider, sensitivityLevel: sensitivity.level)
        
        // Apply content rules
        if let matchingRule = settings.contentRules.first(where: { $0.isActive && $0.matches(text) }) {
            selectedProvider = convertProviderType(for: matchingRule.requiredMode)
            reasoning.append("Content-Regel '\(matchingRule.name)' angewendet")
        }
        
        let decision = ProcessingDecision(
            selectedProvider: selectedProvider,
            selectedMode: selectedMode,
            confidence: confidence,
            reasoning: reasoning.joined(separator: "; "),
            fallbackProvider: fallbackProvider,
            estimatedCost: estimatedCost,
            estimatedTime: estimatedTime,
            privacyCompliance: privacyCompliance
        )
        
        return decision
    }
    
    private func determineHybridMode(text: String,
                                   sensitivity: (level: SensitivityLevel, confidence: Double, reasons: [String]),
                                   lengthAnalysis: (length: Int, complexity: Double, suitableForLocal: Bool),
                                   availableProviders: [KIProviderType: Bool],
                                   preferenceWeight: Double) -> (KIProviderType, ProcessingMode, Double, [String], KIProviderType?) {
        
        var selectedProvider: KIProviderType = .openAI
        var selectedMode: ProcessingMode = .hybrid
        var confidence: Double = 0.7
        var reasoning: [String] = ["Hybrid-Modus: Intelligente Auswahl"]
        var fallbackProvider: KIProviderType? = nil
        
        // Decision factors
        let privacyWeight = 1.0 - sensitivity.level.privacyRisk
        let speedWeight = 0.8 // Cloud is generally faster
        let qualityWeight = 0.9 // Cloud models are generally more accurate
        let costWeight = 0.3 // Local is cheaper
        let lengthWeight = lengthAnalysis.suitableForLocal ? 0.8 : 0.2
        
        // Calculate weighted scores for each provider
        let localScore = privacyWeight * 1.0 + lengthWeight * 0.9 + costWeight * 1.0
        let cloudScore = speedWeight * 1.0 + qualityWeight * 1.0 + (1.0 - lengthWeight) * 0.8
        
        // Determine best provider
        if localScore > cloudScore && availableProviders[.ollama] == true {
            selectedProvider = .ollama
            selectedMode = .hybrid
            confidence = min(localScore, 1.0)
            reasoning.append("Lokale Verarbeitung bevorzugt (Score: \(localScore.formatted(.number.precision(.fractionLength(2))))")
        } else if availableProviders[.openAI] == true {
            selectedProvider = .openAI
            selectedMode = .hybrid
            confidence = min(cloudScore, 1.0)
            reasoning.append("Cloud-Verarbeitung bevorzugt (Score: \(cloudScore.formatted(.number.precision(.fractionLength(2))))")
            fallbackProvider = availableProviders[.openRouter] == true ? .openRouter : .ollama
        } else {
            selectedProvider = .ollama
            selectedMode = .hybrid
            confidence = 0.6
            reasoning.append("Fallback zu lokaler Verarbeitung")
        }
        
        // Special handling for high-sensitivity content
        if sensitivity.level.privacyRisk > settings.privacyThreshold {
            selectedProvider = .ollama
            selectedMode = .privacyFirst
            confidence = 0.9
            reasoning.append("Hochsensible Daten -> Lokale Verarbeitung erzwungen")
        }
        
        return (selectedProvider, selectedMode, confidence, reasoning, fallbackProvider)
    }
    
    private func selectBestCloudProvider(_ availability: [KIProviderType: Bool]) -> KIProviderType {
        // Prefer OpenRouter for cost optimization, fall back to OpenAI
        if availability[.openRouter] == true {
            return .openRouter
        } else if availability[.openAI] == true {
            return .openAI
        }
        return .openAI // Default fallback
    }
    
    private func selectMostCostEffectiveProvider(_ availability: [KIProviderType: Bool]) -> KIProviderType {
        // Cost hierarchy: Ollama < OpenRouter < OpenAI
        if availability[.ollama] == true {
            return .ollama
        } else if availability[.openRouter] == true {
            return .openRouter
        } else if availability[.openAI] == true {
            return .openAI
        }
        return .openAI // Default fallback
    }
    
    private func convertProviderType(for mode: ProcessingMode) -> KIProviderType {
        switch mode {
        case .localOnly, .privacyFirst:
            return .ollama
        case .cloudOnly, .costOptimized:
            return .openRouter
        case .hybrid:
            return .openAI
        }
    }
    
    private func checkPrivacyCompliance(_ provider: KIProviderType, sensitivityLevel: SensitivityLevel) -> Bool {
        let complianceMatrix: [KIProviderType: [SensitivityLevel: Bool]] = [
            .openAI: [
                .public: true,
                .internal: true,
                .confidential: false,
                .highlyConfidential: false
            ],
            .openRouter: [
                .public: true,
                .internal: true,
                .confidential: false,
                .highlyConfidential: false
            ],
            .ollama: [
                .public: true,
                .internal: true,
                .confidential: true,
                .highlyConfidential: true
            ]
        ]
        
        return complianceMatrix[provider]?[sensitivityLevel] ?? false
    }
    
    private func estimateProcessingTime(provider: KIProviderType, taskType: ProcessingTaskType) async -> TimeInterval {
        // Base times for different tasks and providers
        let baseTimes: [KIProviderType: [ProcessingTaskType: TimeInterval]] = [
            .openAI: [
                .summary: 2.0,
                .keywords: 1.5,
                .categorization: 1.0,
                .enhancement: 3.0,
                .questions: 2.5,
                .analysis: 4.0
            ],
            .openRouter: [
                .summary: 2.5,
                .keywords: 2.0,
                .categorization: 1.5,
                .enhancement: 3.5,
                .questions: 3.0,
                .analysis: 5.0
            ],
            .ollama: [
                .summary: 5.0,
                .keywords: 4.0,
                .categorization: 3.0,
                .enhancement: 7.0,
                .questions: 6.0,
                .analysis: 10.0
            ]
        ]
        
        return baseTimes[provider]?[taskType] ?? 3.0
    }
    
    private func detectSensitiveKeywords(_ text: String) -> [String] {
        let sensitivePatterns = [
            "streng vertraulich", "vertraulich", "intern", "geheim",
            "passwort", "passwörter", "bankdaten", "kreditkarte",
            "ssn", "social security", "personalausweis", "steuer"
        ]
        
        return sensitivePatterns.filter { text.lowercased().contains($0.lowercased()) }
    }
    
    private func analyzeContext(_ text: String) async -> [String: Double] {
        // Analyze context for additional privacy indicators
        var contextScore: [String: Double] = [:]
        
        // Business context
        if text.contains("Kunde") || text.contains("Vertrag") || text.contains("Rechnung") {
            contextScore["business"] = 0.8
        }
        
        // Personal context
        if text.contains("persönlich") || text.contains("privat") || text.contains("Familie") {
            contextScore["personal"] = 0.9
        }
        
        // Legal context
        if text.contains("rechtlich") || text.contains("anwalt") || text.contains("gericht") {
            contextScore["legal"] = 0.85
        }
        
        return contextScore
    }
    
    private func selectProvider(for mode: ProcessingMode) -> KIProviderType {
        switch mode {
        case .localOnly, .privacyFirst:
            return .ollama
        case .cloudOnly, .costOptimized:
            return .openRouter
        case .hybrid:
            return .openAI
        }
    }
    
    private func selectFallbackProvider(for mode: ProcessingMode) -> KIProviderType? {
        switch mode {
        case .localOnly, .privacyFirst:
            return nil // No fallback for privacy-first
        case .cloudOnly:
            return .openRouter
        case .costOptimized:
            return .openAI
        case .hybrid:
            return .ollama
        }
    }
    
    private func testProvider(_ provider: KIProviderType) async -> Bool {
        // Simple connectivity test
        return providerManager.providerConfigs[provider]?.apiKey != ""
    }
    
    private func updateMetrics(for decision: ProcessingDecision, duration: TimeInterval) {
        DispatchQueue.main.async {
            self.metrics.totalRequests += 1
            self.metrics.averageResponseTime = (self.metrics.averageResponseTime * Double(self.metrics.totalRequests - 1) + duration) / Double(self.metrics.totalRequests)
            self.metrics.averageCostPerRequest = (self.metrics.averageCostPerRequest * Double(self.metrics.totalRequests - 1) + decision.estimatedCost) / Double(self.metrics.totalRequests)
            
            if decision.selectedProvider != .ollama {
                self.metrics.cloudRequests += 1
            } else {
                self.metrics.localRequests += 1
            }
            
            if self.currentMode != decision.selectedMode {
                self.metrics.hybridSwitches += 1
            }
            
            if decision.fallbackProvider != nil {
                self.metrics.fallbackActivations += 1
            }
            
            self.metrics.lastUpdated = Date()
            self.lastDecision = decision
            
            // Update analytics
            self.analytics.addMetric(
                mode: decision.selectedMode,
                provider: decision.selectedProvider,
                taskType: .analysis, // Would be determined from context
                quality: decision.confidence,
                cost: decision.estimatedCost,
                time: duration
            )
        }
    }
    
    private func triggerModeSwitchNotification(_ decision: ProcessingDecision) async {
        let notification = ProcessingNotification(
            id: UUID(),
            type: .modeSwitch,
            title: "Verarbeitungsmodus gewechselt",
            message: "Wechsel zu \(decision.selectedMode.rawValue) (\(decision.selectedProvider.rawValue))",
            timestamp: Date(),
            severity: .info
        )
        
        DispatchQueue.main.async {
            self.notifications.append(notification)
            // Limit notification history
            if self.notifications.count > 50 {
                self.notifications.removeFirst()
            }
        }
    }
    
    private func triggerFallbackNotification(from: KIProviderType, to: KIProviderType) async {
        let notification = ProcessingNotification(
            id: UUID(),
            type: .fallback,
            title: "Fallback aktiviert",
            message: "Wechsel von \(from.rawValue) zu \(to.rawValue)",
            timestamp: Date(),
            severity: .warning
        )
        
        DispatchQueue.main.async {
            self.notifications.append(notification)
        }
    }
    
    private func setupMonitoring() {
        // Monitor network changes
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if !isConnected {
                    // Auto-switch to local mode when offline
                    self?.currentMode = .localOnly
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let settings = try? JSONDecoder().decode(ProcessingModeSettings.self, from: data) {
            self.settings = settings
        }
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}

// MARK: - Supporting Types

struct ProcessingNotification: Identifiable, Equatable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let severity: NotificationSeverity
    
    enum NotificationType {
        case modeSwitch
        case fallback
        case error
        case recommendation
    }
    
    enum NotificationSeverity {
        case info
        case warning
        case error
    }
}

final class CostCalculator {
    func estimateCost(for provider: KIProviderType, taskType: ProcessingTaskType) async -> Double {
        let costsPerToken: [KIProviderType: Double] = [
            .openAI: 0.00003, // $0.03 per 1K tokens
            .openRouter: 0.00002, // $0.02 per 1K tokens
            .ollama: 0.0 // Local processing
        ]
        
        let tokensPerTask: [ProcessingTaskType: Int] = [
            .summary: 200,
            .keywords: 100,
            .categorization: 50,
            .enhancement: 300,
            .questions: 250,
            .analysis: 400
        ]
        
        let costPerToken = costsPerToken[provider] ?? 0.0
        let estimatedTokens = tokensPerTask[taskType] ?? 200
        
        return costPerToken * Double(estimatedTokens)
    }
}

final class PIIDetector {
    func detectPII(_ text: String) async -> Double {
        let piiPatterns = [
            #"\b\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\b"#, // Credit card
            #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#, // Email
            #"\b\d{3}-\d{2}-\d{4}\b"#, // SSN
            #"\b\d{11,13}\b"#, // Phone numbers
            #"\b[A-Z]{2}\d{2}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{2}\b"# // IBAN
        ]
        
        let fullText = text.lowercased()
        var matchCount = 0
        
        for pattern in piiPatterns {
            if fullText.range(of: pattern, options: .regularExpression) != nil {
                matchCount += 1
            }
        }
        
        return min(Double(matchCount) / Double(piiPatterns.count), 1.0)
    }
}

// MARK: - Error Types
enum ProcessingModeError: Error, LocalizedError {
    case noProviderAvailable
    case providerSwitchFailed(KIProviderType)
    case invalidConfiguration
    case privacyViolation(SensitivityLevel)
    
    var errorDescription: String? {
        switch self {
        case .noProviderAvailable:
            return "Kein verfügbarer Provider gefunden"
        case .providerSwitchFailed(let provider):
            return "Wechsel zu Provider \(provider.rawValue) fehlgeschlagen"
        case .invalidConfiguration:
            return "Ungültige Konfiguration"
        case .privacyViolation(let level):
            return "Privacy-Verletzung bei \(level.rawValue) Daten"
        }
    }
}

// MARK: - Extensions
extension ProcessingModeManager {
    convenience init() {
        self.init(
            contentAnalyzer: ContentAnalyzer(),
            providerManager: KIProviderManager()
        )
    }
}