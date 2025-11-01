//
//  ActiveAppMonitor.swift
//  AINotizassistent
//
//  Überwacht die aktive App kontinuierlich via NSWorkspace
//

import Foundation
import AppKit
import Combine

// MARK: - App Change Event
struct AppChangeEvent {
    let timestamp: Date
    let oldApp: ContentSource?
    let newApp: ContentSource
    let changeType: AppChangeType
    let metadata: [String: Any]?
}

// MARK: - App Change Types
enum AppChangeType {
    case appSwitched
    case appActivated
    case appDeactivated
    case appWindowChanged
    case appClosed
    case unknown
    
    var description: String {
        switch self {
        case .appSwitched: return "App gewechselt"
        case .appActivated: return "App aktiviert"
        case .appDeactivated: return "App deaktiviert"
        case .appWindowChanged: return "Fenster geändert"
        case .appClosed: return "App geschlossen"
        case .unknown: return "Unbekannte Änderung"
        }
    }
}

// MARK: - Monitor Configuration
struct MonitorConfiguration {
    var detectionInterval: TimeInterval
    var enableContinuousMonitoring: Bool
    var enableWindowChangeDetection: Bool
    var enableProcessMonitoring: Bool
    var debounceInterval: TimeInterval
    var maximumRetries: Int
    var privacyMode: Bool
    
    init() {
        self.detectionInterval = 1.0 // 1 Sekunde
        self.enableContinuousMonitoring = true
        self.enableWindowChangeDetection = true
        self.enableProcessMonitoring = true
        self.debounceInterval = 0.5 // 500ms Debounce
        self.maximumRetries = 3
        self.privacyMode = false
    }
    
    mutating func setHighPrivacyMode() {
        self.privacyMode = true
        self.enableWindowChangeDetection = false
        self.enableProcessMonitoring = false
    }
    
    mutating func setLowLatencyMode() {
        self.detectionInterval = 0.5 // 500ms für niedrige Latenz
        self.debounceInterval = 0.2 // 200ms Debounce
    }
}

// MARK: - Monitor Statistics
struct MonitorStatistics {
    var totalDetections: Int
    var successfulDetections: Int
    var failedDetections: Int
    var averageDetectionTime: TimeInterval
    var lastDetectionTime: Date?
    var uptime: TimeInterval
    var memoryUsage: Int64
    var cpuUsage: Double
    
    init() {
        self.totalDetections = 0
        self.successfulDetections = 0
        self.failedDetections = 0
        self.averageDetectionTime = 0.0
        self.lastDetectionTime = nil
        self.uptime = 0.0
        self.memoryUsage = 0
        self.cpuUsage = 0.0
    }
    
    var successRate: Double {
        guard totalDetections > 0 else { return 0.0 }
        return Double(successfulDetections) / Double(totalDetections) * 100.0
    }
    
    var performanceScore: Double {
        let successWeight = 0.4
        let speedWeight = 0.3
        let resourceWeight = 0.3
        
        let successScore = successRate / 100.0
        let speedScore = max(0, 1.0 - (averageDetectionTime / 2.0)) // Normalisiert auf 2s
        let resourceScore = max(0, 1.0 - (Double(memoryUsage) / 100000000.0)) // Max 100MB
        
        return (successScore * successWeight) + (speedScore * speedWeight) + (resourceScore * resourceWeight)
    }
}

// MARK: - Active App Monitor
class ActiveAppMonitor: ObservableObject {
    
    // MARK: - Properties
    private let workspace = NSWorkspace.shared
    private var detector: SourceAppDetector
    private var configuration: MonitorConfiguration
    private var statistics: MonitorStatistics
    
    // Monitoring State
    @Published private(set) var isMonitoring: Bool = false
    @Published private(set) var currentApp: ContentSource?
    @Published private(set) var appChangeHistory: [AppChangeEvent] = []
    @Published private(set) var monitorStatistics: MonitorStatistics
    @Published private(set) var lastDetectionError: DetectionError?
    
    // Private Properties
    private var monitoringTimer: Timer?
    private var appChangeObserver: Any?
    private var windowChangeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var lastDetectionResult: AppDetectionResult?
    private var lastDetectionTime: Date?
    private var startTime: Date?
    
    // Event Publishers
    @Published private(set) var appChangePublisher = PassthroughSubject<AppChangeEvent, Never>()
    @Published private(set) var errorPublisher = PassthroughSubject<DetectionError, Never>()
    
    // MARK: - Initialization
    
    init(detector: SourceAppDetector) {
        self.detector = detector
        self.configuration = MonitorConfiguration()
        self.statistics = MonitorStatistics()
        self.monitorStatistics = statistics
        setupObservers()
    }
    
    convenience init() {
        let detector = SourceAppDetector()
        self.init(detector: detector)
    }
    
    deinit {
        stopMonitoring()
        removeObservers()
    }
    
    // MARK: - Public Interface
    
    /// Startet die kontinuierliche Überwachung
    func startMonitoring() throws {
        guard !isMonitoring else {
            print("⚠️ Monitoring läuft bereits")
            return
        }
        
        guard detector.isTrackingEnabled else {
            throw DetectionError.accessibilityNotEnabled
        }
        
        isMonitoring = true
        startTime = Date()
        statistics = MonitorStatistics() // Reset Statistics
        
        setupPeriodicDetection()
        setupAppChangeNotifications()
        
        print("✅ App-Monitoring gestartet")
    }
    
    /// Stoppt die Überwachung
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        removeObservers()
        
        if let startTime = startTime {
            statistics.uptime = Date().timeIntervalSince(startTime)
        }
        
        print("⏹️ App-Monitoring gestoppt")
    }
    
    /// Führt eine einmalige Erkennung durch
    func performSingleDetection() -> AppDetectionResult {
        let startTime = Date()
        let result = detector.detectCurrentAppDetailed()
        let detectionTime = Date().timeIntervalSince(startTime)
        
        updateStatistics(for: result, detectionTime: detectionTime)
        
        if result.isSuccessful, let source = result.source {
            handleDetectionResult(source)
        }
        
        return result
    }
    
    /// Ändert die Überwachungskonfiguration
    func updateConfiguration(_ newConfig: MonitorConfiguration) {
        let wasMonitoring = isMonitoring
        
        if wasMonitoring {
            stopMonitoring()
        }
        
        configuration = newConfig
        
        if wasMonitoring {
            try? startMonitoring()
        }
    }
    
    /// Ruft die aktuelle Konfiguration ab
    func getConfiguration() -> MonitorConfiguration {
        return configuration
    }
    
    /// Erfasst einen manuellen App-Wechsel
    func recordManualAppChange(to newApp: ContentSource) {
        let event = AppChangeEvent(
            timestamp: Date(),
            oldApp: currentApp,
            newApp: newApp,
            changeType: .appSwitched,
            metadata: ["manual": true]
        )
        
        addToHistory(event)
        currentApp = newApp
        appChangePublisher.send(event)
        
        print("📱 Manuelle App-Änderung erfasst: \(newApp.displayName)")
    }
    
    // MARK: - Private Detection Methods
    
    private func setupPeriodicDetection() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: configuration.detectionInterval, repeats: true) { [weak self] _ in
            self?.performPeriodicDetection()
        }
    }
    
    private func performPeriodicDetection() {
        guard isMonitoring else { return }
        
        // Debounce Check
        if let lastTime = lastDetectionTime,
           Date().timeIntervalSince(lastTime) < configuration.debounceInterval {
            return
        }
        
        let startTime = Date()
        let result = detector.detectCurrentApp()
        let detectionTime = Date().timeIntervalSince(startTime)
        
        updateStatistics(for: result, detectionTime: detectionTime)
        
        if result.isSuccessful, let source = result.source {
            handleDetectionResult(source)
        } else if let error = result.error {
            handleDetectionError(error)
        }
        
        lastDetectionTime = Date()
    }
    
    private func handleDetectionResult(_ newApp: ContentSource) {
        if let oldApp = currentApp, oldApp.appId != newApp.appId {
            // App-Wechsel erkannt
            let changeType: AppChangeType = oldApp.isActive ? .appSwitched : .appActivated
            let event = AppChangeEvent(
                timestamp: Date(),
                oldApp: oldApp,
                newApp: newApp,
                changeType: changeType,
                metadata: configuration.enableProcessMonitoring ? getProcessMetadata(for: newApp) : nil
            )
            
            addToHistory(event)
            appChangePublisher.send(event)
            
            print("🔄 App-Wechsel: \(oldApp.displayName) → \(newApp.displayName)")
        }
        
        currentApp = newApp
    }
    
    private func handleDetectionError(_ error: DetectionError) {
        lastDetectionError = error
        errorPublisher.send(error)
        
        // Nur gelegentliche Fehler protokollieren
        if statistics.failedDetections % 10 == 0 {
            print("⚠️ Detection Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Observer Setup
    
    private func setupObservers() {
        setupAppChangeNotifications()
        setupWindowChangeNotifications()
    }
    
    private func setupAppChangeNotifications() {
        // NSWorkspace Notification Center für App-Änderungen
        let notificationCenter = NSWorkspace.shared.notificationCenter
        
        // App switching
        appChangeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppLaunchNotification(notification)
        }
        
        appChangeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppTerminationNotification(notification)
        }
    }
    
    private func setupWindowChangeNotifications() {
        guard configuration.enableWindowChangeDetection else { return }
        
        // Window change notifications via Accessibility API
        // In einer vollständigen Implementierung würde hier Accessibility verwendet
        print("🔍 Window Change Detection aktiviert")
    }
    
    private func removeObservers() {
        if let observer = appChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appChangeObserver = nil
        }
        
        if let observer = windowChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            windowChangeObserver = nil
        }
    }
    
    // MARK: - Notification Handlers
    
    private func handleAppLaunchNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let app = userInfo[NSWorkspace.ApplicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let appName = app.localizedName ?? "Unbekannte App"
        print("🚀 App gestartet: \(appName)")
        
        // Falls die neue App die aktive App ist, Update triggern
        if app.isActive {
            performSingleDetection()
        }
    }
    
    private func handleAppTerminationNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let app = userInfo[NSWorkspace.ApplicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let appName = app.localizedName ?? "Unbekannte App"
        print("🛑 App beendet: \(appName)")
        
        // Falls die beendete App die aktuelle App war, Update triggern
        if currentApp?.appId == app.bundleIdentifier {
            performSingleDetection()
        }
    }
    
    // MARK: - Statistics and History
    
    private func updateStatistics(for result: AppDetectionResult, detectionTime: TimeInterval) {
        statistics.totalDetections += 1
        
        if result.isSuccessful {
            statistics.successfulDetections += 1
        } else {
            statistics.failedDetections += 1
        }
        
        // Gleitender Durchschnitt für Detection Time
        let currentAvg = statistics.averageDetectionTime
        let newAvg = ((currentAvg * Double(statistics.successfulDetections - 1)) + detectionTime) / Double(statistics.successfulDetections)
        statistics.averageDetectionTime = newAvg
        
        statistics.lastDetectionTime = Date()
        monitorStatistics = statistics
    }
    
    private func addToHistory(_ event: AppChangeEvent) {
        appChangeHistory.append(event)
        
        // Historie auf maximal 100 Events begrenzen
        if appChangeHistory.count > 100 {
            appChangeHistory.removeFirst()
        }
    }
    
    private func getProcessMetadata(for app: ContentSource) -> [String: Any] {
        return [
            "timestamp": Date(),
            "bundleId": app.appId,
            "category": app.category.rawValue,
            "isSystemApp": app.isSystemApp,
            "accessibilityEnabled": app.accessibilityEnabled
        ]
    }
    
    // MARK: - Public Statistics Access
    
    func getStatistics() -> MonitorStatistics {
        return monitorStatistics
    }
    
    func getAppChangeHistory(limit: Int = 50) -> [AppChangeEvent] {
        return Array(appChangeHistory.suffix(limit))
    }
    
    func getCurrentAppInfo() -> [String: Any]? {
        guard let app = currentApp else { return nil }
        
        return [
            "appId": app.appId,
            "displayName": app.displayName,
            "category": app.category.rawValue,
            "windowTitle": app.windowTitle ?? "",
            "isActive": app.isActive,
            "accessibilityEnabled": app.accessibilityEnabled,
            "extractedMetadata": app.extractedMetadata ?? [:],
            "relevance": app.contentRelevance.score,
            "attributionSummary": app.attributionSummary
        ]
    }
    
    // MARK: - Performance Optimization
    
    func setHighPerformanceMode() {
        configuration.setLowLatencyMode()
        if isMonitoring {
            stopMonitoring()
            try? startMonitoring()
        }
    }
    
    func setBatterySavingMode() {
        configuration.detectionInterval = 3.0 // 3 Sekunden
        configuration.debounceInterval = 1.0 // 1 Sekunde
        if isMonitoring {
            stopMonitoring()
            try? startMonitoring()
        }
    }
    
    func setPrivacyMode() {
        configuration.setHighPrivacyMode()
        if isMonitoring {
            stopMonitoring()
            try? startMonitoring()
        }
    }
    
    // MARK: - Memory Management
    
    func clearHistory() {
        appChangeHistory.removeAll()
        print("🧹 App-Change-Historie gelöscht")
    }
    
    func optimizeMemoryUsage() {
        // Statistiken zurücksetzen falls sie zu groß werden
        if statistics.totalDetections > 10000 {
            statistics = MonitorStatistics()
            monitorStatistics = statistics
        }
        
        // Historie komprimieren wenn nötig
        if appChangeHistory.count > 200 {
            let recentHistory = Array(appChangeHistory.suffix(50))
            appChangeHistory = recentHistory
        }
    }
}

// MARK: - App Change Event Extension
extension AppChangeEvent {
    var isSignificant: Bool {
        switch changeType {
        case .appSwitched, .appActivated:
            return true
        case .appWindowChanged:
            return oldApp?.appId == newApp.appId // Nur wenn App gleich ist
        default:
            return false
        }
    }
    
    var duration: TimeInterval? {
        guard let oldTimestamp = oldApp?.timestamp else { return nil }
        return timestamp.timeIntervalSince(oldTimestamp)
    }
}

// MARK: - Monitor Event Types
extension AppChangeEvent {
    enum EventType {
        case switch
        case launch
        case terminate
        case windowChange
        case activation
        case deactivation
    }
    
    var eventType: EventType {
        switch changeType {
        case .appSwitched: return .switch
        case .appActivated: return .activation
        case .appDeactivated: return .deactivation
        case .appWindowChanged: return .windowChange
        case .appClosed: return .terminate
        case .unknown: return .switch
        }
    }
}
