//
//  SourceAppDetector.swift
//  AINotizassistent
//
//  Hauptklassen für automatische Quell-App-Erkennung
//

import Foundation
import AppKit
import Accessibility

// MARK: - App Detection Result
struct AppDetectionResult {
    let isSuccessful: Bool
    let source: ContentSource?
    let error: DetectionError?
    let timestamp: Date
    
    init(success: Bool, source: ContentSource? = nil, error: DetectionError? = nil) {
        self.isSuccessful = success
        self.source = source
        self.error = error
        self.timestamp = Date()
    }
}

// MARK: - Detection Errors
enum DetectionError: Error, LocalizedError {
    case noFrontmostApplication
    case accessibilityNotEnabled
    case processNotAccessible
    case windowInformationUnavailable
    case appNotInMapping
    case parsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noFrontmostApplication:
            return "Keine aktive Anwendung gefunden"
        case .accessibilityNotEnabled:
            return "Accessibility APIs nicht verfügbar"
        case .processNotAccessible:
            return "Prozess-Informationen nicht zugänglich"
        case .windowInformationUnavailable:
            return "Fenster-Informationen nicht verfügbar"
        case .appNotInMapping:
            return "App nicht in der bekannten App-Liste"
        case .parsingFailed(let details):
            return "Content-Parsing fehlgeschlagen: \(details)"
        }
    }
}

// MARK: - Privacy Settings
struct PrivacySettings {
    var isTrackingEnabled: Bool
    var allowedCategories: Set<AppCategory>
    var systemAppTracking: Bool
    var contentExtraction: Bool
    var processNameCollection: Bool
    var windowTitleAnalysis: Bool
    
    init() {
        self.isTrackingEnabled = false
        self.allowedCategories = Set(AppCategory.allCases)
        self.systemAppTracking = true
        self.contentExtraction = true
        self.processNameCollection = true
        self.windowTitleAnalysis = true
    }
    
    mutating func enableTracking() {
        self.isTrackingEnabled = true
    }
    
    mutating func disableTracking() {
        self.isTrackingEnabled = false
    }
    
    mutating func setAllowedCategories(_ categories: [AppCategory]) {
        self.allowedCategories = Set(categories)
    }
    
    func isCategoryAllowed(_ category: AppCategory) -> Bool {
        return allowedCategories.contains(category)
    }
    
    mutating func toggleSystemAppTracking() {
        self.systemAppTracking.toggle()
    }
}

// MARK: - Main Source App Detector
class SourceAppDetector: ObservableObject {
    
    // MARK: - Properties
    private let workspace = NSWorkspace.shared
    private var privacySettings: PrivacySettings
    private var contentParsers: [AppCategory: AppContentParser]
    
    // Detection State
    @Published private(set) var lastDetectionResult: AppDetectionResult?
    @Published private(set) var isDetecting: Bool = false
    @Published private(set) var currentFrontmostApp: ContentSource?
    
    // MARK: - Initialization
    init() {
        self.privacySettings = PrivacySettings()
        self.contentParsers = [:]
        setupContentParsers()
    }
    
    // MARK: - Setup
    private func setupContentParsers() {
        contentParsers[.email] = MailContentParser()
        contentParsers[.browser] = BrowserContentParser()
        contentParsers[.editor] = EditorContentParser()
    }
    
    // MARK: - Public Methods
    
    /// Aktiviert das Tracking (Opt-in)
    func enableTracking() {
        privacySettings.enableTracking()
        print("✅ Quell-App-Erkennung aktiviert")
    }
    
    /// Deaktiviert das Tracking
    func disableTracking() {
        privacySettings.disableTracking()
        print("⏹️ Quell-App-Erkennung deaktiviert")
    }
    
    /// Überprüft, ob Tracking aktiviert ist
    var isTrackingEnabled: Bool {
        return privacySettings.isTrackingEnabled
    }
    
    /// Erfasst die aktuelle Frontmost App
    func detectCurrentApp() -> AppDetectionResult {
        guard privacySettings.isTrackingEnabled else {
            return AppDetectionResult(success: false, error: .noFrontmostApplication)
        }
        
        isDetecting = true
        defer { isDetecting = false }
        
        do {
            let source = try detectFrontmostApplication()
            let result = AppDetectionResult(success: true, source: source)
            
            DispatchQueue.main.async {
                self.lastDetectionResult = result
                self.currentFrontmostApp = source
            }
            
            return result
            
        } catch let error as DetectionError {
            let result = AppDetectionResult(success: false, error: error)
            DispatchQueue.main.async {
                self.lastDetectionResult = result
                self.currentFrontmostApp = nil
            }
            return result
        } catch {
            let result = AppDetectionResult(success: false, error: .processNotAccessible)
            DispatchQueue.main.async {
                self.lastDetectionResult = result
                self.currentFrontmostApp = nil
            }
            return result
        }
    }
    
    /// Erfasst App-Informationen mit erweiterten Details
    func detectCurrentAppDetailed() -> AppDetectionResult {
        guard privacySettings.isTrackingEnabled else {
            return AppDetectionResult(success: false, error: .noFrontmostApplication)
        }
        
        do {
            let source = try detectFrontmostApplicationDetailed()
            let result = AppDetectionResult(success: true, source: source)
            
            DispatchQueue.main.async {
                self.lastDetectionResult = result
                self.currentFrontmostApp = source
            }
            
            return result
            
        } catch let error as DetectionError {
            return AppDetectionResult(success: false, error: error)
        } catch {
            return AppDetectionResult(success: false, error: .processNotAccessible)
        }
    }
    
    // MARK: - Core Detection Methods
    
    private func detectFrontmostApplication() throws -> ContentSource {
        guard let frontmostApp = workspace.frontmostApplication else {
            throw DetectionError.noFrontmostApplication
        }
        
        let appName = frontmostApp.localizedName ?? "Unbekannte App"
        let processName = frontmostApp.bundleIdentifier ?? frontmostApp.processIdentifier.description
        
        // App-Type Definition finden
        let appDefinition = SourceAppMapping.findApp(by: processName) ?? SourceAppMapping.createDynamicDefinition(for: processName, displayName: appName)
        
        // Kategorie-Prüfung
        guard privacySettings.isCategoryAllowed(appDefinition.category) else {
            throw DetectionError.appNotInMapping
        }
        
        // Window Title erfassen
        let windowTitle = privacySettings.windowTitleAnalysis ? getWindowTitle(for: frontmostApp) : nil
        
        // Accessibility Check
        let accessibilityEnabled = checkAccessibilityPermission(for: appDefinition)
        
        return ContentSource(
            appId: processName,
            displayName: appDefinition.displayName,
            category: appDefinition.category,
            windowTitle: windowTitle,
            processName: processName,
            isActive: true,
            accessibilityEnabled: accessibilityEnabled,
            extractedMetadata: nil
        )
    }
    
    private func detectFrontmostApplicationDetailed() throws -> ContentSource {
        let basicSource = try detectFrontmostApplication()
        
        // Content-spezifisches Parsing
        let metadata = extractMetadata(for: basicSource)
        
        return ContentSource(
            appId: basicSource.appId,
            displayName: basicSource.displayName,
            category: basicSource.category,
            windowTitle: basicSource.windowTitle,
            processName: basicSource.processName,
            isActive: true,
            accessibilityEnabled: basicSource.accessibilityEnabled,
            extractedMetadata: metadata
        )
    }
    
    // MARK: - Window Analysis
    
    private func getWindowTitle(for app: NSRunningApplication) -> String? {
        guard privacySettings.windowTitleAnalysis else { return nil }
        
        // Versuche Accessibility API zu nutzen
        if let windowTitle = getWindowTitleViaAccessibility(for: app) {
            return windowTitle
        }
        
        // Fallback: App-spezifische Methoden
        return getWindowTitleViaAppSpecificMethods(for: app)
    }
    
    private func getWindowTitleViaAccessibility(for app: NSRunningApplication) -> String? {
        // Hier würde Accessibility API verwendet
        // Für die Demo implementieren wir eine vereinfachte Version
        
        let appName = app.localizedName ?? ""
        let appId = app.bundleIdentifier ?? ""
        
        // Safari-spezifische Erkennung
        if appName.lowercased().contains("safari") {
            return "Safari Window - Accessibility"
        }
        
        // Mail-spezifische Erkennung
        if appId == "com.apple.Mail" {
            return "Neue Nachrichten - Mail"
        }
        
        return appName + " - Window"
    }
    
    private func getWindowTitleViaAppSpecificMethods(for app: NSRunningApplication) -> String? {
        let appId = app.bundleIdentifier ?? ""
        
        // Office Apps - Document Title
        if appId.hasPrefix("com.microsoft.") || appId.hasPrefix("com.apple.iWork.") {
            return "Untitled - \(app.localizedName ?? "App")"
        }
        
        // Browser - Website Title (vereinfacht)
        if appId.contains("chrome") || appId.contains("safari") || appId.contains("firefox") {
            return "Loading... - \(app.localizedName ?? "Browser")"
        }
        
        return nil
    }
    
    // MARK: - Content Metadata Extraction
    
    private func extractMetadata(for source: ContentSource) -> [String: String]? {
        guard privacySettings.contentExtraction, let windowTitle = source.windowTitle else {
            return nil
        }
        
        // App-spezifischen Parser finden
        let parser = contentParsers[source.category]
        
        // App Definition für Parser
        let appDefinition = SourceAppMapping.findApp(by: source.appId) ?? 
                           SourceAppMapping.createDynamicDefinition(for: source.appId, displayName: source.displayName)
        
        return parser?.parseContent(from: windowTitle, appType: appDefinition)
    }
    
    // MARK: - Accessibility Checks
    
    private func checkAccessibilityPermission(for appDefinition: AppTypeDefinition) -> Bool {
        guard appDefinition.accessibilityEnabled else { return false }
        
        // Hier würde die tatsächliche Accessibility Permission geprüft
        // Für die Demo simulieren wir die Verfügbarkeit
        return true
    }
    
    // MARK: - Process Information
    
    private func getProcessInfo(for app: NSRunningApplication) -> [String: Any] {
        var info: [String: Any] = [
            "processID": app.processIdentifier,
            "bundleIdentifier": app.bundleIdentifier ?? "",
            "localizedName": app.localizedName ?? "",
            "isActive": app.isActive,
            "launchDate": app.launchDate ?? Date(),
            "bundleURL": app.bundleURL?.path ?? ""
        ]
        
        if privacySettings.processNameCollection {
            info["executableURL"] = app.executableURL?.lastPathComponent ?? ""
        }
        
        return info
    }
    
    // MARK: - Settings Management
    
    func updatePrivacySettings(_ newSettings: PrivacySettings) {
        self.privacySettings = newSettings
    }
    
    func getPrivacySettings() -> PrivacySettings {
        return privacySettings
    }
    
    // MARK: - Statistics
    
    var detectionStatistics: [String: Any] {
        let categories = SourceAppMapping.appsByCategory
        let totalApps = SourceAppMapping.totalKnownApps
        
        return [
            "totalKnownApps": totalApps,
            "appsByCategory": categories,
            "trackingEnabled": privacySettings.isTrackingEnabled,
            "lastDetection": lastDetectionResult?.timestamp ?? Date(),
            "currentApp": currentFrontmostApp?.attributionSummary ?? "Keine App"
        ]
    }
    
    // MARK: - App Category Preferences
    
    func setPreferredCategories(_ categories: [AppCategory]) {
        privacySettings.setAllowedCategories(categories)
    }
    
    func getPreferredCategories() -> [AppCategory] {
        return Array(privacySettings.allowedCategories)
    }
    
    func toggleSystemAppTracking() {
        privacySettings.toggleSystemAppTracking()
    }
    
    var isSystemAppTrackingEnabled: Bool {
        return privacySettings.systemAppTracking
    }
}

// MARK: - Content Source Extension
extension ContentSource {
    var isEligibleForTracking: Bool {
        return isActive && accessibilityEnabled
    }
    
    var canExtractContent: Bool {
        return windowTitle != nil && !windowTitle!.isEmpty
    }
    
    var contentRelevance: ContentRelevance {
        switch category {
        case .email, .browser, .editor, .ide, .office:
            return .high
        case .design, .communication:
            return .medium
        case .productivity, .development:
            return .medium
        case .other:
            return .low
        }
    }
}

// MARK: - Content Relevance
enum ContentRelevance {
    case high
    case medium
    case low
    
    var score: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
