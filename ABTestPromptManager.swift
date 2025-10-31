//
//  ABTestPromptManager.swift
//  Intelligente Notizen App
//

import Foundation

// MARK: - A/B Test Prompt Manager Protocol
protocol ABTestManaging: AnyObject {
    func getPrompts(for contentType: ContentType) async -> [ABTestPrompt]
    func selectVariant(for contentType: ContentType) async -> String
    func createTest(for contentType: ContentType, variants: [ABTestPromptVariant]) async -> ABTest
    func trackTestResult(testId: String, variantId: String, success: Bool, metrics: TestMetrics) async
    func getTestResults(testId: String) async -> ABTestResults
    func stopTest(testId: String) async
    func getActiveTests() async -> [ABTest]
}

// MARK: - A/B Test Prompt Manager
final class ABTestPromptManager: ABTestManaging {
    
    private var activeTests: [String: ABTest] = [:]
    private var testResults: [String: ABTestResults] = [:]
    private let testStorage = ABTestStorage()
    private let assignmentStrategy = TestAssignmentStrategy()
    
    func getPrompts(for contentType: ContentType) async -> [ABTestPrompt] {
        // Get active A/B tests for this content type
        let activeTests = activeTests.values.filter { $0.contentType == contentType && $0.isActive }
        
        var prompts: [ABTestPrompt] = []
        
        for test in activeTests {
            let selectedVariant = await assignmentStrategy.selectVariant(for: test)
            
            guard let variant = test.variants.first(where: { $0.id == selectedVariant }) else { continue }
            
            prompts.append(ABTestPrompt(
                id: variant.id,
                prompt: variant.prompt,
                templateName: test.name,
                testId: test.id,
                variant: selectedVariant,
                metadata: variant.metadata
            ))
        }
        
        return prompts
    }
    
    func selectVariant(for contentType: ContentType) async -> String {
        let activeTests = activeTests.values.filter { $0.contentType == contentType && $0.isActive }
        
        guard let activeTest = activeTests.first else {
            return "control" // Default variant
        }
        
        return await assignmentStrategy.selectVariant(for: activeTest)
    }
    
    func createTest(for contentType: ContentType, variants: [ABTestPromptVariant]) async -> ABTest {
        let testId = UUID().uuidString
        let test = ABTest(
            id: testId,
            name: "\(contentType.displayName) Prompt Test",
            contentType: contentType,
            variants: variants,
            createdAt: Date(),
            isActive: true,
            assignmentStrategy: .random
        )
        
        activeTests[testId] = test
        await testStorage.storeTest(test)
        
        return test
    }
    
    func trackTestResult(testId: String, variantId: String, success: Bool, metrics: TestMetrics) async {
        let result = TestResult(
            timestamp: Date(),
            variantId: variantId,
            success: success,
            metrics: metrics
        )
        
        if var test = activeTests[testId] {
            test.results.append(result)
            activeTests[testId] = test
        }
        
        // Store result for persistence
        await testStorage.storeTestResult(testId, result: result)
        
        // Check if test should be stopped (statistical significance reached)
        await evaluateTestSignificance(testId)
    }
    
    func getTestResults(testId: String) async -> ABTestResults {
        // Combine stored results with in-memory results
        let storedResults = await testStorage.getTestResults(testId)
        
        guard let test = activeTests[testId] else {
            return ABTestResults.empty
        }
        
        let allResults = storedResults + test.results
        
        // Calculate statistics
        let variantStats = calculateVariantStatistics(allResults, variants: test.variants)
        
        return ABTestResults(
            testId: testId,
            totalParticipants: allResults.count,
            variantResults: variantStats,
            statisticalSignificance: calculateSignificance(variantStats),
            recommendations: generateRecommendations(variantStats)
        )
    }
    
    func stopTest(testId: String) async {
        if var test = activeTests[testId] {
            test.isActive = false
            test.stoppedAt = Date()
            activeTests[testId] = test
            
            await testStorage.updateTest(test)
        }
    }
    
    func getActiveTests() async -> [ABTest] {
        return activeTests.values.filter { $0.isActive }.map { $0 }
    }
    
    // MARK: - Private Methods
    private func evaluateTestSignificance(_ testId: String) async {
        let results = await getTestResults(testId)
        
        // Simple significance check (in real implementation, use proper statistical tests)
        let totalParticipants = results.totalParticipants
        let hasWinner = results.variantResults.values.allSatisfy { $0.participantCount > 50 } &&
                       results.statisticalSignificance > 0.95
        
        if totalParticipants > 100 && hasWinner {
            await stopTest(testId)
        }
    }
    
    private func calculateVariantStatistics(_ results: [TestResult], variants: [ABTestPromptVariant]) -> [String: VariantStatistics] {
        var stats: [String: VariantStatistics] = [:]
        
        for variant in variants {
            let variantResults = results.filter { $0.variantId == variant.id }
            let successes = variantResults.filter { $0.success }.count
            
            stats[variant.id] = VariantStatistics(
                variantId: variant.id,
                participantCount: variantResults.count,
                successCount: successes,
                successRate: variantResults.isEmpty ? 0.0 : Double(successes) / Double(variantResults.count),
                averageResponseTime: variantResults.reduce(0.0) { $0 + $1.metrics.responseTime } / Double(max(variantResults.count, 1)),
                averageTokens: variantResults.reduce(0.0) { $0 + $1.metrics.tokensUsed } / Double(max(variantResults.count, 1))
            )
        }
        
        return stats
    }
    
    private func calculateSignificance(_ variantStats: [String: VariantStatistics]) -> Double {
        // Simplified statistical significance calculation
        // In real implementation, use proper statistical tests like chi-square or t-test
        
        guard variantStats.count >= 2 else { return 0.0 }
        
        let successRates = variantStats.values.map { $0.successRate }
        let maxSuccessRate = successRates.max() ?? 0.0
        let minSuccessRate = successRates.min() ?? 0.0
        let difference = maxSuccessRate - minSuccessRate
        
        // Simple heuristic: higher difference = higher significance
        return min(difference * 10, 1.0) // Cap at 1.0
    }
    
    private func generateRecommendations(_ variantStats: [String: VariantStatistics]) -> [TestRecommendation] {
        var recommendations: [TestRecommendation] = []
        
        let sortedVariants = variantStats.values.sorted { $0.successRate > $1.successRate }
        
        if let bestVariant = sortedVariants.first, let worstVariant = sortedVariants.last {
            let improvement = bestVariant.successRate - worstVariant.successRate
            
            if improvement > 0.1 { // 10% improvement
                recommendations.append(TestRecommendation(
                    type: .useWinner,
                    message: "Variante \(bestVariant.variantId) zeigt \(String(format: "%.1f", improvement * 100))% bessere Erfolgsrate",
                    priority: .high,
                    action: "Deploy winning variant"
                ))
            }
        }
        
        // Check for performance issues
        let slowVariants = variantStats.values.filter { $0.averageResponseTime > 5.0 }
        if !slowVariants.isEmpty {
            recommendations.append(TestRecommendation(
                type: .performance,
                message: "\(slowVariants.count) Varianten haben langsame Antwortzeiten",
                priority: .medium,
                action: "Optimize slow variants"
            ))
        }
        
        return recommendations
    }
}

// MARK: - Test Assignment Strategy
class TestAssignmentStrategy {
    private var userAssignments: [String: String] = [:]
    
    func selectVariant(for test: ABTest) async -> String {
        // User-based assignment for consistency
        if let assignedVariant = userAssignments[test.id] {
            return assignedVariant
        }
        
        // Random assignment based on test strategy
        let selectedVariant: String
        
        switch test.assignmentStrategy {
        case .random:
            selectedVariant = test.variants.randomElement()?.id ?? test.variants.first?.id ?? "control"
            
        case .roundRobin:
            selectedVariant = await selectRoundRobinVariant(test)
            
        case .weighted:
            selectedVariant = selectWeightedVariant(test.variants)
        }
        
        // Store assignment for consistent user experience
        userAssignments[test.id] = selectedVariant
        
        return selectedVariant
    }
    
    private func selectRoundRobinVariant(_ test: ABTest) -> String {
        let assignments = userAssignments.filter { $0.key == test.id }
        let variantCounts = Dictionary(grouping: assignments.values, by: { $0 })
            .mapValues { $0.count }
        
        // Find variant with least assignments
        let sortedByCount = test.variants.sorted { lhs, rhs in
            let lhsCount = variantCounts[lhs.id] ?? 0
            let rhsCount = variantCounts[rhs.id] ?? 0
            return lhsCount < rhsCount
        }
        
        return sortedByCount.first?.id ?? test.variants.first?.id ?? "control"
    }
    
    private func selectWeightedVariant(_ variants: [ABTestPromptVariant]) -> String {
        let totalWeight = variants.reduce(0) { $0 + $1.weight }
        let randomValue = Double.random(in: 0...totalWeight)
        
        var accumulatedWeight = 0.0
        for variant in variants {
            accumulatedWeight += variant.weight
            if randomValue <= accumulatedWeight {
                return variant.id
            }
        }
        
        return variants.first?.id ?? "control"
    }
}

// MARK: - A/B Test Storage
final class ABTestStorage {
    private let userDefaults = UserDefaults.standard
    private let testsKey = "ABTests"
    private let resultsKey = "ABTestResults"
    
    func storeTest(_ test: ABTest) async {
        var tests = getStoredTests()
        tests[test.id] = test
        
        let data = try? JSONEncoder().encode(tests)
        userDefaults.set(data, forKey: testsKey)
    }
    
    func updateTest(_ test: ABTest) async {
        await storeTest(test)
    }
    
    func getStoredTests() -> [String: ABTest] {
        guard let data = userDefaults.data(forKey: testsKey),
              let tests = try? JSONDecoder().decode([String: ABTest].self, from: data) else {
            return [:]
        }
        return tests
    }
    
    func storeTestResult(_ testId: String, result: TestResult) async {
        var results = getStoredResults()
        if results[testId] == nil {
            results[testId] = []
        }
        results[testId]?.append(result)
        
        let data = try? JSONEncoder().encode(results)
        userDefaults.set(data, forKey: resultsKey)
    }
    
    func getTestResults(_ testId: String) async -> [TestResult] {
        let results = getStoredResults()
        return results[testId] ?? []
    }
    
    private func getStoredResults() -> [String: [TestResult]] {
        guard let data = userDefaults.data(forKey: resultsKey),
              let results = try? JSONDecoder().decode([String: [TestResult]].self, from: data) else {
            return [:]
        }
        return results
    }
}

// MARK: - Supporting Data Types
struct ABTestPrompt {
    let id: String
    let prompt: String
    let templateName: String
    let testId: String
    let variant: String
    let metadata: [String: String]
}

struct ABTestPromptVariant {
    let id: String
    let prompt: String
    let description: String
    let weight: Double
    let metadata: [String: String]
}

struct ABTest {
    let id: String
    let name: String
    let contentType: ContentType
    let variants: [ABTestPromptVariant]
    let createdAt: Date
    var isActive: Bool
    var stoppedAt: Date?
    var results: [TestResult] = []
    let assignmentStrategy: AssignmentStrategy
    
    enum AssignmentStrategy {
        case random, roundRobin, weighted
    }
}

struct ABTestResults {
    let testId: String
    let totalParticipants: Int
    let variantResults: [String: VariantStatistics]
    let statisticalSignificance: Double
    let recommendations: [TestRecommendation]
    
    static let empty = ABTestResults(
        testId: "",
        totalParticipants: 0,
        variantResults: [:],
        statisticalSignificance: 0.0,
        recommendations: []
    )
}

struct VariantStatistics {
    let variantId: String
    let participantCount: Int
    let successCount: Int
    let successRate: Double
    let averageResponseTime: Double
    let averageTokens: Double
}

struct TestResult {
    let timestamp: Date
    let variantId: String
    let success: Bool
    let metrics: TestMetrics
}

struct TestMetrics {
    let responseTime: TimeInterval
    let tokensUsed: Int
    let qualityScore: Double?
    let userSatisfaction: Double?
}

struct TestRecommendation {
    let type: RecommendationType
    let message: String
    let priority: Priority
    let action: String
    
    enum RecommendationType {
        case useWinner, performance, dataCollection, continuation
    }
    
    enum Priority {
        case low, medium, high, critical
    }
}

enum Priority: String, CaseIterable {
    case low = "Niedrig"
    case medium = "Mittel" 
    case high = "Hoch"
    case critical = "Kritisch"
}