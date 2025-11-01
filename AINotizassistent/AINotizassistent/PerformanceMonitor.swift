import Foundation
import os.log
import SystemConfiguration
import UIKit

/// Zentrale Performance-Überwachung für die App
@available(iOS 13.0, *)
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    // MARK: - Properties
    private var memoryMonitorTimer: Timer?
    private var cpuMonitorTimer: Timer?
    private var batteryMonitorTimer: Timer?
    private var networkMonitorTimer: Timer?
    
    private let performanceLog = os.Logger(subsystem: "com.minimax.AINotizassistent", category: "Performance")
    private let memoryLog = os.Logger(subsystem: "com.minimax.AINotizassistent", category: "Memory")
    private let networkLog = os.Logger(subsystem: "com.minimax.AINotizassistent", category: "Network")
    
    // Performance Metrics
    private(set) var performanceMetrics = PerformanceMetrics()
    private(set) var memoryMetrics = MemoryMetrics()
    private(set) var networkMetrics = NetworkMetrics()
    private(set) var batteryMetrics = BatteryMetrics()
    private(set) var uiMetrics = UIMetrics()
    
    // Observer
    var performanceAlertHandler: ((PerformanceAlert) -> Void)?
    
    // Cache für optimierte Datenverarbeitung
    private lazy var cachedMetrics = LRUCache<String, Any>(capacity: 100)
    private let dispatchQueue = DispatchQueue(label: "performance.monitor", qos: .utility)
    
    // MARK: - Initialization
    private init() {
        setupMonitoring()
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        dispatchQueue.async { [weak self] in
            self?.startMemoryMonitoring()
            self?.startCPUMonitoring()
            self?.startBatteryMonitoring()
            self?.startNetworkMonitoring()
        }
    }
    
    func stopMonitoring() {
        memoryMonitorTimer?.invalidate()
        cpuMonitorTimer?.invalidate()
        batteryMonitorTimer?.invalidate()
        networkMonitorTimer?.invalidate()
    }
    
    func recordMetric(_ metric: PerformanceMetricType, value: Double, context: String = "") {
        let timestamp = Date()
        
        switch metric {
        case .responseTime:
            performanceMetrics.responseTimeMeasurements.append(Measurement(value: value, timestamp: timestamp, context: context))
        case .memoryUsage:
            memoryMetrics.usageMeasurements.append(Measurement(value: value, timestamp: timestamp, context: context))
        case .cpuUsage:
            performanceMetrics.cpuUsageMeasurements.append(Measurement(value: value, timestamp: timestamp, context: context))
        case .batteryLevel:
            batteryMetrics.levelMeasurements.append(Measurement(value: value, timestamp: timestamp, context: context))
        case .networkLatency:
            networkMetrics.latencyMeasurements.append(Measurement(value: value, timestamp: timestamp, context: context))
        case .animationFPS:
            uiMetrics.fpsMeasurements.append(Measurement(value: value, timestamp: timestamp, context: context))
        }
        
        // Cache für optimierten Zugriff
        let cacheKey = "\(metric.rawValue)_\(context)"
        cachedMetrics.set(value, forKey: cacheKey)
        
        performanceLog.info("Performance Metric Recorded: \(metric.rawValue) = \(value) for context: \(context)")
        
        // Check for performance degradation
        checkPerformanceThresholds(metric, value: value, context: context)
    }
    
    func measureOperation<T>(_ operation: @escaping () async throws -> T, operationName: String = #function) async throws -> (T, PerformanceMeasurement) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        
        do {
            let result = try await operation()
            let endTime = CFAbsoluteTimeGetCurrent()
            let endMemory = getCurrentMemoryUsage()
            
            let measurement = PerformanceMeasurement(
                operationName: operationName,
                duration: endTime - startTime,
                memoryUsage: endMemory - startMemory,
                timestamp: Date()
            )
            
            recordMetric(.responseTime, value: measurement.duration, context: operationName)
            recordMetric(.memoryUsage, value: measurement.memoryUsage, context: operationName)
            
            return (result, measurement)
        } catch {
            let endTime = CFAbsoluteTimeGetCurrent()
            let endMemory = getCurrentMemoryUsage()
            
            let measurement = PerformanceMeasurement(
                operationName: operationName,
                duration: endTime - startTime,
                memoryUsage: endMemory - startMemory,
                timestamp: Date(),
                error: error
            )
            
            recordMetric(.responseTime, value: measurement.duration, context: operationName)
            recordMetric(.memoryUsage, value: measurement.memoryUsage, context: operationName)
            
            throw error
        }
    }
    
    // MARK: - Memory Optimization
    func optimizeMemory() {
        dispatchQueue.async { [weak self] in
            self?.performMemoryOptimization()
        }
    }
    
    func cacheWithMemoryLimit<T: Codable>(_ data: T, key: String, maxMemoryMB: Double = 50) {
        let sizeBytes = estimateMemorySize(of: data)
        let sizeMB = Double(sizeBytes) / 1024.0 / 1024.0
        
        if sizeMB <= maxMemoryMB {
            cachedMetrics.set(data, forKey: key)
            memoryLog.info("Cached \(key) with size \(sizeMB) MB")
        } else {
            memoryLog.warning("Data too large for cache: \(key) size \(sizeMB) MB > limit \(maxMemoryMB) MB")
        }
    }
    
    func getCached<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        return cachedMetrics.value(forKey: key) as? T
    }
    
    func clearCache() {
        cachedMetrics.clear()
        memoryLog.info("Cache cleared")
    }
    
    // MARK: - CPU Optimization
    func performInBackground<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    do {
                        let result = try await operation()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func batchOperations<T>(_ operations: [() async throws -> T], batchSize: Int = 10) async throws -> [T] {
        var results = [T]()
        
        for chunk in operations.chunked(into: batchSize) {
            let batchResults = try await withThrowingTaskGroup(of: T.self) { group in
                for operation in chunk {
                    group.addTask {
                        try await operation()
                    }
                }
                
                var batch = [T]()
                for try await result in group {
                    batch.append(result)
                }
                return batch
            }
            
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
    
    // MARK: - Network Optimization
    func optimizeNetworkRequests() {
        networkLog.info("Optimizing network requests")
        // Implement request batching, connection pooling, compression
    }
    
    func batchNetworkRequests(_ requests: [NetworkRequest], completion: @escaping ([NetworkResponse]) -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.processBatchedRequests(requests, completion: completion)
        }
    }
    
    // MARK: - UI Optimization
    func optimizeUI() {
        uiMetrics.frameTimeMeasurements = []
        uiMetrics.renderTimeMeasurements = []
    }
    
    func trackAnimationPerformance(_ animationName: String, frameTime: TimeInterval) {
        uiMetrics.frameTimeMeasurements.append(Measurement(value: frameTime, timestamp: Date(), context: animationName))
        
        // Check for 16ms frame rate (60 FPS)
        if frameTime > 0.016 { // 16.67ms for 60fps
            performanceLog.warning("Animation \(animationName) frame time exceeds 16ms: \(frameTime * 1000)ms")
            triggerAlert(.lowFPS(animationName: animationName, frameTime: frameTime))
        }
    }
    
    // MARK: - Private Methods
    private func setupMonitoring() {
        startMemoryMonitoring()
        startCPUMonitoring()
        startBatteryMonitoring()
        startNetworkMonitoring()
    }
    
    private func startMemoryMonitoring() {
        memoryMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateMemoryMetrics()
        }
    }
    
    private func startCPUMonitoring() {
        cpuMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCPUMetrics()
        }
    }
    
    private func startBatteryMonitoring() {
        batteryMonitorTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateBatteryMetrics()
        }
    }
    
    private func startNetworkMonitoring() {
        networkMonitorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateNetworkMetrics()
        }
    }
    
    private func updateMemoryMetrics() {
        let currentMemory = getCurrentMemoryUsage()
        memoryMetrics.currentUsage = currentMemory
        memoryMetrics.usagePercentage = (currentMemory / getTotalMemory()) * 100
        
        recordMetric(.memoryUsage, value: currentMemory)
        
        if currentMemory > getTotalMemory() * 0.8 { // 80% threshold
            triggerAlert(.highMemoryUsage(usage: currentMemory))
            performMemoryOptimization()
        }
    }
    
    private func updateCPUMetrics() {
        let cpuUsage = getCurrentCPUUsage()
        performanceMetrics.currentCPUUsage = cpuUsage
        
        recordMetric(.cpuUsage, value: cpuUsage)
        
        if cpuUsage > 80.0 { // 80% CPU threshold
            triggerAlert(.highCPUUsage(usage: cpuUsage))
        }
    }
    
    private func updateBatteryMetrics() {
        let batteryLevel = getBatteryLevel()
        let isCharging = isDeviceCharging()
        
        batteryMetrics.currentLevel = batteryLevel
        batteryMetrics.isCharging = isCharging
        batteryMetrics.timeSinceLastUpdate = Date()
        
        recordMetric(.batteryLevel, value: batteryLevel)
        
        if batteryLevel < 20 && !isCharging { // Low battery threshold
            triggerAlert(.lowBattery(level: batteryLevel))
        }
    }
    
    private func updateNetworkMetrics() {
        // Implement network monitoring logic
        let latency = measureNetworkLatency()
        networkMetrics.averageLatency = calculateAverageLatency(latency)
        networkMetrics.lastUpdateTime = Date()
        
        recordMetric(.networkLatency, value: latency)
    }
    
    private func performMemoryOptimization() {
        // Clear old cache entries
        cachedMetrics.clearExpired()
        
        // Force garbage collection if available
        #if DEBUG
        autoreleasepool {
            memoryLog.info("Performing memory optimization")
        }
        #endif
        
        // Clear large cached data
        clearLargeCacheEntries()
    }
    
    private func checkPerformanceThresholds(_ metric: PerformanceMetricType, value: Double, context: String) {
        switch metric {
        case .responseTime where value > 1.0: // 1 second threshold
            triggerAlert(.slowResponse(operation: context, time: value))
        case .memoryUsage where value > getTotalMemory() * 0.85:
            triggerAlert(.highMemoryUsage(usage: value))
        case .batteryLevel where value < 15.0:
            triggerAlert(.lowBattery(level: value))
        case .animationFPS where value < 50.0:
            triggerAlert(.lowFPS(animationName: context, frameTime: value > 0 ? 1.0 / value : 0))
        default:
            break
        }
    }
    
    private func triggerAlert(_ alert: PerformanceAlert) {
        performanceLog.warning("Performance Alert: \(alert.localizedDescription)")
        performanceAlertHandler?(alert)
    }
    
    // Helper methods
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // MB
        }
        
        return 0.0
    }
    
    private func getTotalMemory() -> Double {
        return Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0
    }
    
    private func getCurrentCPUUsage() -> Double {
        let cpuInfo = host_cpu_load_info()
        let totalUsage = cpuInfo.cpu_ticks.0 + cpuInfo.cpu_ticks.1 + cpuInfo.cpu_ticks.2
        return Double(totalUsage) / 100.0
    }
    
    private func getBatteryLevel() -> Double {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel * 100
    }
    
    private func isDeviceCharging() -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }
    
    private func measureNetworkLatency() -> Double {
        // Simplified network latency measurement
        let start = CFAbsoluteTimeGetCurrent()
        
        // Ping a known endpoint or measure response time
        let pingResult = CFHostCreateCurrentHost(kCFAllocatorDefault, "8.8.8.8" as CFString)
        defer { CFBridgingRelease(pingResult) }
        
        return (CFAbsoluteTimeGetCurrent() - start) * 1000 // ms
    }
    
    private func calculateAverageLatency(_ currentLatency: Double) -> Double {
        networkMetrics.latencyMeasurements.append(Measurement(value: currentLatency, timestamp: Date(), context: "average"))
        return networkMetrics.latencyMeasurements.last(10).map { $0.value }.reduce(0, +) / 10.0
    }
    
    private func clearLargeCacheEntries() {
        // Remove large cache entries to free memory
        // Implementation depends on cache structure
    }
    
    private func estimateMemorySize<T: Codable>(of data: T) -> Int {
        return withUnsafePointer(to: data) { pointer in
            withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) { bytes in
                MemoryLayout<T>.size
            }
        }
    }
}

// MARK: - Supporting Types
@available(iOS 13.0, *)
struct PerformanceMetrics {
    var responseTimeMeasurements: [Measurement] = []
    var cpuUsageMeasurements: [Measurement] = []
    var currentCPUUsage: Double = 0.0
    var lastUpdated: Date = Date()
}

@available(iOS 13.0, *)
struct MemoryMetrics {
    var currentUsage: Double = 0.0
    var usagePercentage: Double = 0.0
    var usageMeasurements: [Measurement] = []
    var lastOptimization: Date = Date()
}

@available(iOS 13.0, *)
struct NetworkMetrics {
    var averageLatency: Double = 0.0
    var latencyMeasurements: [Measurement] = []
    var lastUpdateTime: Date = Date()
    var connectionQuality: ConnectionQuality = .unknown
}

@available(iOS 13.0, *)
struct BatteryMetrics {
    var currentLevel: Double = 100.0
    var isCharging: Bool = false
    var levelMeasurements: [Measurement] = []
    var timeSinceLastUpdate: Date = Date()
}

@available(iOS 13.0, *)
struct UIMetrics {
    var frameTimeMeasurements: [Measurement] = []
    var renderTimeMeasurements: [Measurement] = []
    var fpsMeasurements: [Measurement] = []
    var lastUIUpdate: Date = Date()
}

@available(iOS 13.0, *)
struct Measurement {
    let value: Double
    let timestamp: Date
    let context: String
}

@available(iOS 13.0, *)
struct PerformanceMeasurement {
    let operationName: String
    let duration: TimeInterval
    let memoryUsage: Double
    let timestamp: Date
    let error: Error?
    
    init(operationName: String, duration: TimeInterval, memoryUsage: Double, timestamp: Date, error: Error? = nil) {
        self.operationName = operationName
        self.duration = duration
        self.memoryUsage = memoryUsage
        self.timestamp = timestamp
        self.error = error
    }
}

@available(iOS 13.0, *)
enum PerformanceMetricType: String {
    case responseTime = "response_time"
    case memoryUsage = "memory_usage"
    case cpuUsage = "cpu_usage"
    case batteryLevel = "battery_level"
    case networkLatency = "network_latency"
    case animationFPS = "animation_fps"
}

@available(iOS 13.0, *)
enum PerformanceAlert: LocalizedError {
    case highMemoryUsage(usage: Double)
    case highCPUUsage(usage: Double)
    case lowBattery(level: Double)
    case slowResponse(operation: String, time: TimeInterval)
    case lowFPS(animationName: String, frameTime: TimeInterval)
    
    var localizedDescription: String {
        switch self {
        case .highMemoryUsage(let usage):
            return "Hohe Speichernutzung: \(String(format: "%.2f", usage)) MB"
        case .highCPUUsage(let usage):
            return "Hohe CPU-Auslastung: \(String(format: "%.1f", usage))%"
        case .lowBattery(let level):
            return "Niedriger Batteriestand: \(String(format: "%.1f", level))%"
        case .slowResponse(let operation, let time):
            return "Langsame Antwort bei \(operation): \(String(format: "%.2f", time))s"
        case .lowFPS(let animationName, let frameTime):
            return "Niedrige FPS bei \(animationName): \(String(format: "%.1f", frameTime * 1000))ms"
        }
    }
}

@available(iOS 13.0, *)
enum ConnectionQuality {
    case excellent
    case good
    case fair
    case poor
    case unknown
    
    static func fromLatency(_ latency: Double) -> ConnectionQuality {
        switch latency {
        case 0...50:
            return .excellent
        case 50...100:
            return .good
        case 100...200:
            return .fair
        case 200...Double.infinity:
            return .poor
        default:
            return .unknown
        }
    }
}

// MARK: - Network Request Types
@available(iOS 13.0, *)
struct NetworkRequest {
    let id: UUID
    let url: URL
    let method: String
    let headers: [String: String]
    let body: Data?
}

@available(iOS 13.0, *)
struct NetworkResponse {
    let requestId: UUID
    let statusCode: Int
    let data: Data
    let responseTime: TimeInterval
    let error: Error?
}

// MARK: - Caching Implementation
@available(iOS 13.0, *)
class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var cache: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?
    
    private class Node {
        let key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func set(_ value: Value, forKey key: Key) {
        if let existingNode = cache[key] {
            existingNode.value = value
            moveToHead(existingNode)
        } else {
            let newNode = Node(key: key, value: value)
            addToHead(newNode)
            cache[key] = newNode
            
            if cache.count > capacity {
                removeTail()
            }
        }
    }
    
    func value(forKey key: Key) -> Value? {
        if let node = cache[key] {
            moveToHead(node)
            return node.value
        }
        return nil
    }
    
    func clear() {
        cache.removeAll()
        head = nil
        tail = nil
    }
    
    func clearExpired() {
        // Implement expiration logic based on timestamp
    }
    
    private func addToHead(_ node: Node) {
        if head == nil {
            head = node
            tail = node
        } else {
            node.next = head
            head?.prev = node
            head = node
        }
    }
    
    private func moveToHead(_ node: Node) {
        if node === head {
            return
        }
        
        if node === tail {
            tail = node.prev
            tail?.next = nil
        } else {
            node.prev?.next = node.next
            node.next?.prev = node.prev
        }
        
        addToHead(node)
    }
    
    private func removeTail() {
        if let tail = tail {
            cache.removeValue(forKey: tail.key)
            
            if tail === head {
                head = nil
                self.tail = nil
            } else {
                self.tail = tail.prev
                self.tail?.next = nil
            }
        }
    }
}

@available(iOS 13.0, *)
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// Helper function for CPU info
private func host_cpu_load_info() -> (UInt32, UInt32, UInt32, UInt32) {
    var cpuInfo = host_cpu_load_info()
    var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size)/4
    
    withUnsafeMutablePointer(to: &cpuInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
        }
    }
    
    return (cpuInfo.cpu_ticks.0, cpuInfo.cpu_ticks.1, cpuInfo.cpu_ticks.2, cpuInfo.cpu_ticks.3)
}