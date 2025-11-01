//
//  macOSVersionChecker.swift
//  Runtime macOS Version Detection and Validation
//

import Foundation
import AppKit
import SystemConfiguration
import IOKit

// MARK: - Version Information
public struct macOSVersionInfo {
    public let version: macOSVersion
    public let buildNumber: String
    public let fullVersionString: String
    public let isBeta: Bool
    public let isDeveloperPreview: Bool
    public let daysSinceRelease: Int
    public let endOfSupportDate: Date?
    public let securityUpdatesAvailable: Bool
    
    public init() {
        let currentVersion = ProcessInfo.processInfo.operatingSystemVersion
        let fullVersion = ProcessInfo.processInfo.operatingSystemVersionString
        
        // Determine macOS version
        self.version = macOSVersion(
            major: currentVersion.majorVersion,
            minor: currentVersion.minorVersion,
            patch: currentVersion.patchVersion
        ) ?? .catalina
        
        // Extract build number
        self.buildNumber = VersionChecker.extractBuildNumber()
        
        // Full version string
        self.fullVersionString = fullVersion
        
        // Check if beta/developer preview
        self.isBeta = VersionChecker.checkIfBeta()
        self.isDeveloperPreview = VersionChecker.checkIfDeveloperPreview()
        
        // Days since release
        self.daysSinceRelease = VersionChecker.calculateDaysSinceRelease(for: version)
        
        // End of support
        self.endOfSupportDate = VersionChecker.getEndOfSupportDate(for: version)
        
        // Security updates
        self.securityUpdatesAvailable = VersionChecker.checkSecurityUpdates()
    }
}

// MARK: - Version Checker Core
public class macOSVersionChecker {
    
    // MARK: - Singleton
    public static let shared = macOSVersionChecker()
    
    private var cachedVersionInfo: macOSVersionInfo?
    private var lastCheck: Date?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get current macOS version info with caching
    public func getVersionInfo(forceRefresh: Bool = false) -> macOSVersionInfo {
        let now = Date()
        
        // Return cached version if recent (within 1 hour)
        if !forceRefresh,
           let cached = cachedVersionInfo,
           let lastCheck = lastCheck,
           now.timeIntervalSince(lastCheck) < 3600 {
            return cached
        }
        
        let versionInfo = macOSVersionInfo()
        cachedVersionInfo = versionInfo
        lastCheck = now
        
        return versionInfo
    }
    
    /// Quick version check without full info
    public func getQuickVersion() -> macOSVersion {
        return getVersionInfo().version
    }
    
    /// Check if version meets minimum requirement
    public func isVersionSupported(_ requiredVersion: macOSVersion) -> Bool {
        return getQuickVersion() >= requiredVersion
    }
    
    /// Get version difference in days
    public func getDaysSinceRelease() -> Int {
        return getVersionInfo().daysSinceRelease
    }
    
    /// Check if system is up to date
    public func isSystemUpToDate() -> Bool {
        let versionInfo = getVersionInfo()
        let daysSinceRelease = versionInfo.daysSinceRelease
        
        // Consider system outdated if > 180 days since release
        // (rough heuristic for security update availability)
        return daysSinceRelease < 180
    }
    
    /// Check security update status
    public func getSecurityStatus() -> SecurityStatus {
        let versionInfo = getVersionInfo()
        
        if versionInfo.securityUpdatesAvailable {
            return .updatesAvailable
        }
        
        if versionInfo.endOfSupportDate != nil && Date() > versionInfo.endOfSupportDate! {
            return .endOfSupport
        }
        
        return .upToDate
    }
    
    // MARK: - Advanced Detection Methods
    
    /// Detect specific system capabilities
    public func detectSystemCapabilities() -> SystemCapabilities {
        let version = getQuickVersion()
        var capabilities = SystemCapabilities()
        
        // Set basic capabilities based on version
        switch version {
        case .catalina:
            capabilities.hasBasicShortcuts = false
            capabilities.hasAdvancedSecurity = false
            capabilities.hasGlassEffects = false
            capabilities.hasModernNotesIntegration = false
            
        case .bigSur:
            capabilities.hasBasicShortcuts = true
            capabilities.hasAdvancedSecurity = true
            capabilities.hasGlassEffects = false
            capabilities.hasModernNotesIntegration = true
            
        case .monterey:
            capabilities.hasBasicShortcuts = true
            capabilities.hasAdvancedSecurity = true
            capabilities.hasGlassEffects = false
            capabilities.hasModernNotesIntegration = true
            capabilities.hasLiveText = true
            capabilities.hasFocusModes = true
            
        case .ventura:
            capabilities.hasBasicShortcuts = true
            capabilities.hasAdvancedSecurity = true
            capabilities.hasGlassEffects = false
            capabilities.hasModernNotesIntegration = true
            capabilities.hasLiveText = true
            capabilities.hasFocusModes = true
            capabilities.hasAdvancedShortcuts = true
            capabilities.hasStageManager = true
            capabilities.hasEnhancedNotes = true
            
        case .sonoma, .sequoia:
            capabilities.hasBasicShortcuts = true
            capabilities.hasAdvancedSecurity = true
            capabilities.hasGlassEffects = true
            capabilities.hasModernNotesIntegration = true
            capabilities.hasLiveText = true
            capabilities.hasFocusModes = true
            capabilities.hasAdvancedShortcuts = true
            capabilities.hasStageManager = true
            capabilities.hasEnhancedNotes = true
            capabilities.hasInteractiveWidgets = true
            capabilities.hasEnhancedSharing = true
        }
        
        // Runtime detection for additional capabilities
        capabilities.runtimeDetected = detectRuntimeCapabilities()
        
        return capabilities
    }
    
    /// Performance characteristics of the system
    public func getPerformanceProfile() -> PerformanceProfile {
        let isLowPowerMode = ProcessInfo.processInfo.thermalState == .critical
        let memoryPressure = getMemoryPressureLevel()
        let cpuCount = ProcessInfo.processInfo.processorCount
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        
        let performanceLevel: PerformanceLevel
        
        if isLowPowerMode || memoryPressure > 0.8 {
            performanceLevel = .limited
        } else if cpuCount < 4 || totalMemory < 8 * 1024 * 1024 * 1024 { // 8GB
            performanceLevel = .standard
        } else {
            performanceLevel = .high
        }
        
        return PerformanceProfile(
            level: performanceLevel,
            cpuCores: cpuCount,
            totalMemoryGB: totalMemory / (1024 * 1024 * 1024),
            isLowPowerMode: isLowPowerMode,
            memoryPressure: memoryPressure
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func detectRuntimeCapabilities() -> RuntimeCapabilities {
        return RuntimeCapabilities(
            hasShortcutsApp: checkShortcutsAppAvailability(),
            hasNotesApp: checkNotesAppAvailability(),
            hasSpeechRecognition: checkSpeechRecognition(),
            hasNSVisualEffectView: checkVisualEffectView(),
            hasModernKeychain: checkKeychainSupport(),
            hasSystemEvents: checkSystemEvents(),
            hasAutomation: checkAutomationSupport()
        )
    }
    
    private func checkShortcutsAppAvailability() -> Bool {
        // Check if Shortcuts app bundle exists
        let shortcutsPath = "/System/Library/CoreServices/Shortcuts.app"
        return FileManager.default.fileExists(atPath: shortcutsPath)
    }
    
    private func checkNotesAppAvailability() -> Bool {
        // Check if Notes app exists
        let notesPath = "/System/Library/CoreServices/Notes.app"
        return FileManager.default.fileExists(atPath: notesPath)
    }
    
    private func checkSpeechRecognition() -> Bool {
        return NSSpeechRecognizer.isSpeechRecognitionAvailable()
    }
    
    private func checkVisualEffectView() -> Bool {
        return NSClassFromString("NSVisualEffectView") != nil
    }
    
    private func checkKeychainSupport() -> Bool {
        // Check for modern Keychain API support
        return SecItemCopyMatching != nil
    }
    
    private func checkSystemEvents() -> Bool {
        // Check if System Events is available
        return NSWorkspace.shared.fullPath(forApplication: "System Events") != nil
    }
    
    private func checkAutomationSupport() -> Bool {
        // Check AppleScript/Automation support
        guard let appleScriptManagerClass = NSClassFromString("NSAppleScript") else {
            return false
        }
        
        // Try to create a simple AppleScript instance
        let testScript = "tell application \"System Events\" to get name of processes"
        let appleScript = NSAppleScript(source: testScript)
        
        var error: NSDictionary?
        appleScript?.compileAndReturnError(&error)
        
        return error == nil
    }
    
    private func getMemoryPressureLevel() -> Double {
        // Simplified memory pressure calculation
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        
        // Estimate used memory (this is a rough approximation)
        let estimatedUsedMemory = totalMemory * 0.6 // Assume ~60% used
        let pressureLevel = Double(estimatedUsedMemory) / Double(totalMemory)
        
        return min(pressureLevel, 1.0)
    }
}

// MARK: - Version Checker Extensions
private extension VersionChecker {
    
    private static func extractBuildNumber() -> String {
        // Extract build number from system version
        let task = Process()
        task.launchPath = "/usr/bin/sw_vers"
        task.arguments = ["-buildVersion"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let buildNumber = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return buildNumber
            }
        } catch {
            print("Error getting build number: \(error)")
        }
        
        return "Unknown"
    }
    
    private static func checkIfBeta() -> Bool {
        // Check if system is in beta
        let versionString = ProcessInfo.processInfo.operatingSystemVersionString.lowercased()
        return versionString.contains("beta") || versionString.contains("rc") || versionString.contains("developer preview")
    }
    
    private static func checkIfDeveloperPreview() -> Bool {
        let versionString = ProcessInfo.processInfo.operatingSystemVersionString.lowercased()
        return versionString.contains("developer preview") || versionString.contains("dp")
    }
    
    private static func calculateDaysSinceRelease(for version: macOSVersion) -> Int {
        let releaseDates: [macOSVersion: Date] = [
            .catalina: DateComponents(calendar: .current, year: 2019, month: 10, day: 7).date!,
            .bigSur: DateComponents(calendar: .current, year: 2020, month: 11, day: 12).date!,
            .monterey: DateComponents(calendar: .current, year: 2021, month: 10, day: 25).date!,
            .ventura: DateComponents(calendar: .current, year: 2022, month: 10, day: 24).date!,
            .sonoma: DateComponents(calendar: .current, year: 2023, month: 9, day: 26).date!,
            .sequoia: DateComponents(calendar: .current, year: 2024, month: 9, day: 16).date!
        ]
        
        guard let releaseDate = releaseDates[version] else {
            return 0
        }
        
        let calendar = Calendar.current
        let now = Date()
        return calendar.dateComponents([.day], from: releaseDate, to: now).day ?? 0
    }
    
    private static func getEndOfSupportDate(for version: macOSVersion) -> Date? {
        // Approximate end of support dates (typically 3 years after release)
        let releaseDates: [macOSVersion: Date] = [
            .catalina: DateComponents(calendar: .current, year: 2022, month: 10, day: 1).date!,
            .bigSur: DateComponents(calendar: .current, year: 2023, month: 12, day: 1).date!,
            .monterey: DateComponents(calendar: .current, year: 2024, month: 12, day: 1).date!,
            .ventura: DateComponents(calendar: .current, year: 2025, month: 12, day: 1).date!,
            .sonoma: DateComponents(calendar: .current, year: 2026, month: 12, day: 1).date!,
            .sequoia: DateComponents(calendar: .current, year: 2027, month: 12, day: 1).date!
        ]
        
        return releaseDates[version]
    }
    
    private static func checkSecurityUpdates() -> Bool {
        // Check if security updates are available
        // This would typically query software update system
        // For now, return a heuristic based on version age
        let version = macOSVersion(
            major: ProcessInfo.processInfo.operatingSystemVersion.majorVersion,
            minor: ProcessInfo.processInfo.operatingSystemVersion.minorVersion,
            patch: ProcessInfo.processInfo.operatingSystemVersion.patchVersion
        ) ?? .catalina
        
        let daysSinceRelease = calculateDaysSinceRelease(for: version)
        return daysSinceRelease < 365 // Within first year typically has frequent updates
    }
}

// MARK: - Supporting Types
public struct SystemCapabilities {
    var hasBasicShortcuts: Bool = false
    var hasAdvancedShortcuts: Bool = false
    var hasAdvancedSecurity: Bool = false
    var hasGlassEffects: Bool = false
    var hasModernNotesIntegration: Bool = false
    var hasLiveText: Bool = false
    var hasFocusModes: Bool = false
    var hasStageManager: Bool = false
    var hasEnhancedNotes: Bool = false
    var hasInteractiveWidgets: Bool = false
    var hasEnhancedSharing: Bool = false
    var runtimeDetected: RuntimeCapabilities = RuntimeCapabilities()
}

public struct RuntimeCapabilities {
    var hasShortcutsApp: Bool = false
    var hasNotesApp: Bool = false
    var hasSpeechRecognition: Bool = false
    var hasNSVisualEffectView: Bool = false
    var hasModernKeychain: Bool = false
    var hasSystemEvents: Bool = false
    var hasAutomation: Bool = false
}

public struct PerformanceProfile {
    public let level: PerformanceLevel
    public let cpuCores: Int
    public let totalMemoryGB: Int
    public let isLowPowerMode: Bool
    public let memoryPressure: Double
}

public enum PerformanceLevel {
    case limited
    case standard
    case high
}

public enum SecurityStatus {
    case upToDate
    case updatesAvailable
    case endOfSupport
}

// MARK: - Usage Examples and Testing
extension macOSVersionChecker {
    
    /// Create diagnostic report for support
    public func createDiagnosticReport() -> String {
        let versionInfo = getVersionInfo()
        let capabilities = detectSystemCapabilities()
        let performance = getPerformanceProfile()
        let securityStatus = getSecurityStatus()
        
        var report = """
        
        === macOS Kompatibilitäts-Diagnose ===
        Systemversion: \(versionInfo.fullVersionString)
        Build-Nummer: \(versionInfo.buildNumber)
        macOS Version: \(versionInfo.version.name) (\(versionInfo.version.rawValue))
        Tage seit Veröffentlichung: \(versionInfo.daysSinceRelease)
        
        System-Fähigkeiten:
        - Shortcuts Integration: \(capabilities.hasBasicShortcuts)
        - Erweiterte Shortcuts: \(capabilities.hasAdvancedShortcuts)
        - Glaseffekte: \(capabilities.hasGlassEffects)
        - Live Text: \(capabilities.hasLiveText)
        - Stage Manager: \(capabilities.hasStageManager)
        
        Leistungsprofil:
        - Performance Level: \(performance.level)
        - CPU Kerne: \(performance.cpuCores)
        - Speicher: \(performance.totalMemoryGB)GB
        - Low Power Mode: \(performance.isLowPowerMode)
        - Speicherdruck: \(Int(performance.memoryPressure * 100))%
        
        Sicherheitsstatus: \(securityStatus)
        
        Runtime-Erkennung:
        - Shortcuts App: \(capabilities.runtimeDetected.hasShortcutsApp)
        - Notes App: \(capabilities.runtimeDetected.hasNotesApp)
        - Spracherkennung: \(capabilities.runtimeDetected.hasSpeechRecognition)
        - Automatisierung: \(capabilities.runtimeDetected.hasAutomation)
        
        """
        
        if versionInfo.isBeta {
            report += "\n⚠️  Warnung: Beta-Version erkannt!"
        }
        
        if versionInfo.isDeveloperPreview {
            report += "\n⚠️  Warnung: Developer Preview erkannt!"
        }
        
        if securityStatus == .endOfSupport {
            report += "\n🔒 Kritisch: End of Support erreicht!"
        }
        
        return report
    }
}

// MARK: - Export for Testing
#if DEBUG
extension macOSVersionChecker {
    public func simulateVersion(_ version: macOSVersion) {
        // For testing purposes
        let mockVersionInfo = macOSVersionInfo()
        // This would be replaced with actual mock implementation for testing
    }
}
#endif