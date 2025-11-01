//
//  PromptAnalyticsTracker.swift
//  Intelligente Notizen App
//

import Foundation

// MARK: - Analytics Tracker Protocol
protocol PromptAnalyticsTracking: AnyObject {
    func trackUsage(promptId: String, success: Bool, responseTime: TimeInterval) async
    func getAnalytics() async -> PromptAnalytics
    func optimizePrompts() async
    func getCurrentStats() async -> PromptUsageStats
}

// MARK: - Prompt Analytics Tracker
final class PromptAnalyticsTracker: PromptAnalyticsTracking {
    
    private var usageData: [String: PromptUsageRecord] = [:]
    private var performanceMetrics: PromptPerformanceMetrics = PromptPerformanceMetrics()
    private let storage = AnalyticsStorage()
    
    // Real-time tracking
    private var realTimeTrackers: [String: RealTimeTracker] = [:]
    private let maxRealTimeEntries = 1000
    
    init() {
        loadHistoricalData()
    }
    
    func trackUsage(promptId: String, success: Bool, responseTime: TimeInterval) async {
        let record = PromptUsageRecord(
            timestamp: Date(),
            promptId: promptId,
            success: success,
            responseTime: responseTime
        )
        
        // Update in-memory data
        updateUsageRecord(record)
        
        // Store persistently
        await storage.storeUsageRecord(record)
        
        // Update real-time metrics
        updateRealTimeMetrics(record)
    }
    
    func getAnalytics() async -> PromptAnalytics {
        let allRecords = await storage.getAllUsageRecords()
        
        let totalPrompts = allRecords.count
        let successfulPrompts = allRecords.filter { $0.success }.count
        let totalResponseTime = allRecords.reduce(0.0) { $0 + $1.responseTime }
        let averageResponseTime = totalPrompts > 0 ? totalResponseTime / Double(totalPrompts) : 0.0
        let successRate = totalPrompts > 0 ? Double(successfulPrompts) / Double(totalPrompts) : 0.0
        
        // Calculate most used templates
        let templateUsage = Dictionary(grouping: allRecords) { $0.promptId }
            .mapValues { records in
                TemplateUsage(
                    templateId: $0.key,
                    usageCount: $0.value.count,
                    successRate: Double($0.value.filter { $0.success }.count) / Double($0.value.count),
                    averageResponseTime: $0.value.reduce(0.0) { $0 + $1.responseTime } / Double($0.value.count)
                )
            }
            .sorted { $0.value.usageCount > $1.value.usageCount }
        
        // Generate optimization suggestions
        let optimizationSuggestions = generateOptimizationSuggestions(from: allRecords)
        
        return PromptAnalytics(
            totalPromptsGenerated: totalPrompts,
            averageResponseTime: averageResponseTime,
            successRate: successRate,
            mostUsedTemplates: templateUsage.prefix(5).map { $0.value },
            optimizationSuggestions: optimizationSuggestions
        )
    }
    
    func optimizePrompts() async {
        let allRecords = await storage.getAllUsageRecords()
        
        // Analyze patterns for optimization
        let slowPrompts = allRecords.filter { $0.responseTime > 5.0 } // Slower than 5 seconds
        let failedPrompts = allRecords.filter { !$0.success }
        
        // Generate optimization actions
        if !slowPrompts.isEmpty {
            await optimizeSlowPrompts(slowPrompts)
        }
        
        if !failedPrompts.isEmpty {
            await optimizeFailedPrompts(failedPrompts)
        }
        
        // Update performance metrics
        updatePerformanceMetrics(allRecords)
    }
    
    func getCurrentStats() async -> PromptUsageStats {
        let allRecords = await storage.getAllUsageRecords()
        
        // Today's stats
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayRecords = allRecords.filter { $0.timestamp >= today }
        
        let totalTokens = allRecords.reduce(0) { $0 + $1.estimatedTokens }
        let averageTokens = allRecords.isEmpty ? 0.0 : Double(totalTokens) / Double(allRecords.count)
        
        // Calculate cache hit rate (simplified)
        let cacheHitRate = calculateCacheHitRate(allRecords)
        
        return PromptUsageStats(
            totalPrompts: allRecords.count,
            todayPrompts: todayRecords.count,
            averageTokens: averageTokens,
            cacheHitRate: cacheHitRate
        )
    }
    
    // MARK: - Private Methods
    private func updateUsageRecord(_ record: PromptUsageRecord) {
        if let existing = usageData[record.promptId] {
            existing.addRecord(record)
        } else {
            let tracker = PromptUsageRecord()
            tracker.addRecord(record)
            usageData[record.promptId] = tracker
        }
    }
    
    private func loadHistoricalData() {
        Task {
            let historicalRecords = await storage.getAllUsageRecords()
            for record in historicalRecords {
                updateUsageRecord(record)
            }
        }
    }
    
    private func updateRealTimeMetrics(_ record: PromptUsageRecord) {
        // Keep only recent entries for real-time tracking
        let recentCutoff = Date().addingTimeInterval(-3600) // Last hour
        
        if realTimeTrackers[record.promptId] == nil {
            realTimeTrackers[record.promptId] = RealTimeTracker()
        }
        
        realTimeTrackers[record.promptId]?.addRecord(record)
        
        // Clean up old entries
        for (key, tracker) in realTimeTrackers {
            tracker.removeOldEntries(before: recentCutoff)
            if tracker.recordCount == 0 {
                realTimeTrackers.removeValue(forKey: key)
            }
        }
    }
    
    private func generateOptimizationSuggestions(from records: [PromptUsageRecord]) -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []
        
        // Analyze response times
        let slowPrompts = records.filter { $0.responseTime > 3.0 }
        if !slowPrompts.isEmpty {
            suggestions.append(OptimizationSuggestion(
                type: .performance,
                description: "\(slowPrompts.count) Prompts haben eine hohe Antwortzeit",
                impact: 0.8,
                implementation: "Optimieren Sie lange Prompts und implementieren Sie besseres Caching"
            ))
        }
        
        // Analyze failure patterns
        let failedPrompts = records.filter { !$0.success }
        if !failedPrompts.isEmpty {
            suggestions.append(OptimizationSuggestion(
                type: .reliability,
                description: "\(failedPrompts.count) Prompts sind fehlgeschlagen",
                impact: 0.9,
                implementation: "Überprüfen Sie Prompt-Templates auf Syntaxfehler"
            ))
        }
        
        // Analyze token usage
        let longPrompts = records.filter { $0.estimatedTokens > 2000 }
        if !longPrompts.isEmpty {
            suggestions.append(OptimizationSuggestion(
                type: .efficiency,
                description: "\(longPrompts.count) Prompts überschreiten Token-Limits",
                impact: 0.7,
                implementation: "Implementieren Sie Context-Window-Management"
            ))
        }
        
        return suggestions
    }
    
    private func optimizeSlowPrompts(_ slowPrompts: [PromptUsageRecord]) async {
        // Implementation for optimizing slow prompts
        // This could involve reducing prompt length, improving caching, etc.
    }
    
    private func optimizeFailedPrompts(_ failedPrompts: [PromptUsageRecord]) async {
        // Implementation for optimizing failed prompts
        // This could involve error handling improvements, prompt validation, etc.
    }
    
    private func updatePerformanceMetrics(_ records: [PromptUsageRecord]) {
        performanceMetrics.totalRequests = records.count
        performanceMetrics.successfulRequests = records.filter { $0.success }.count
        performanceMetrics.averageResponseTime = records.reduce(0.0) { $0 + $1.responseTime } / Double(max(records.count, 1))
        performanceMetrics.cacheHitRate = calculateCacheHitRate(records)
    }
    
    private func calculateCacheHitRate(_ records: [PromptUsageRecord]) -> Double {
        // Simplified cache hit rate calculation
        // In a real implementation, this would track actual cache hits
        return 0.75 // Placeholder
    }
}

// MARK: - Usage Record Models
class PromptUsageRecord {
    private var records: [PromptUsageRecordEntry] = []
    
    var recordCount: Int { return records.count }
    var averageResponseTime: Double {
        return records.isEmpty ? 0.0 : records.reduce(0.0) { $0 + $1.responseTime } / Double(records.count)
    }
    var successRate: Double {
        return records.isEmpty ? 0.0 : Double(records.filter { $0.success }.count) / Double(records.count)
    }
    
    func addRecord(_ record: PromptUsageRecordEntry) {
        records.append(record)
        
        // Keep only last 100 records per prompt for memory efficiency
        if records.count > 100 {
            records = Array(records.suffix(100))
        }
    }
}

struct PromptUsageRecordEntry {
    let timestamp: Date
    let promptId: String
    let success: Bool
    let responseTime: TimeInterval
    let estimatedTokens: Int
}

struct PromptUsageRecord {
    let timestamp: Date
    let promptId: String
    let success: Bool
    let responseTime: TimeInterval
    let estimatedTokens: Int
}

// MARK: - Analytics Storage
final class AnalyticsStorage {
    private let userDefaults = UserDefaults.standard
    private let storageKey = "PromptUsageRecords"
    
    func storeUsageRecord(_ record: PromptUsageRecord) async {
        var existingRecords = getStoredRecords()
        existingRecords.append(record)
        
        // Keep only last 10000 records to prevent storage bloat
        if existingRecords.count > 10000 {
            existingRecords = Array(existingRecords.suffix(10000))
        }
        
        let data = try? JSONEncoder().encode(existingRecords)
        userDefaults.set(data, forKey: storageKey)
    }
    
    func getAllUsageRecords() async -> [PromptUsageRecord] {
        return getStoredRecords()
    }
    
    private func getStoredRecords() -> [PromptUsageRecord] {
        guard let data = userDefaults.data(forKey: storageKey),
              let records = try? JSONDecoder().decode([PromptUsageRecord].self, from: data) else {
            return []
        }
        return records
    }
}

// MARK: - Performance Metrics
struct PromptPerformanceMetrics {
    var totalRequests: Int = 0
    var successfulRequests: Int = 0
    var averageResponseTime: Double = 0.0
    var cacheHitRate: Double = 0.0
    
    var successRate: Double {
        return totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) : 0.0
    }
}

// MARK: - Template Usage
struct TemplateUsage {
    let templateId: String
    let usageCount: Int
    let successRate: Double
    let averageResponseTime: Double
}

// MARK: - Real-time Tracker
class RealTimeTracker {
    private var entries: [PromptUsageRecordEntry] = []
    
    var recordCount: Int { return entries.count }
    
    func addRecord(_ record: PromptUsageRecordEntry) {
        entries.append(record)
        
        // Keep only last 100 entries
        if entries.count > 100 {
            entries = Array(entries.suffix(100))
        }
    }
    
    func removeOldEntries(before cutoff: Date) {
        entries.removeAll { $0.timestamp < cutoff }
    }
    
    func getAverageResponseTime() -> Double {
        return entries.isEmpty ? 0.0 : entries.reduce(0.0) { $0 + $1.responseTime } / Double(entries.count)
    }
    
    func getSuccessRate() -> Double {
        return entries.isEmpty ? 0.0 : Double(entries.filter { $0.success }.count) / Double(entries.count)
    }
}