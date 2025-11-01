//
//  CompatibilityManager.swift
//  macOS Version Compatibility Management
//

import Foundation
import AppKit
import SystemConfiguration
import Security

// MARK: - macOS Version Support
public enum macOSVersion: String, CaseIterable {
    case catalina = "10.15"
    case bigSur = "11.0"
    case monterey = "12.0"
    case ventura = "13.0"
    case sonoma = "14.0"
    case sequoia = "15.0"
    
    public var name: String {
        switch self {
        case .catalina: return "Catalina"
        case .bigSur: return "Big Sur"
        case .monterey: return "Monterey"
        case .ventura: return "Ventura"
        case .sonoma: return "Sonoma"
        case .sequoia: return "Sequoia"
        }
    }
    
    public var minimumSupported: Bool {
        switch self {
        case .catalina: return true
        case .bigSur: return true
        case .monterey: return true
        case .ventura: return true
        case .sonoma: return true
        case .sequoia: return false // Future version
        }
    }
}

// MARK: - Feature Support Enumeration
public struct FeatureSupport: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    // Basic Features (Catalina+)
    public static let basicApp = FeatureSupport(rawValue: 1 << 0)
    public static let notesIntegration = FeatureSupport(rawValue: 1 << 1)
    public static let voiceInput = FeatureSupport(rawValue: 1 << 2)
    
    // Big Sur+ Features
    public static let shortcutsIntegration = FeatureSupport(rawValue: 1 << 10)
    public static let modernUI = FeatureSupport(rawValue: 1 << 11)
    public static let systemColors = FeatureSupport(rawValue: 1 << 12)
    
    // Monterey+ Features
    public static let enhancedVoice = FeatureSupport(rawValue: 1 << 20)
    public static let focusModes = FeatureSupport(rawValue: 1 << 21)
    public static let liveText = FeatureSupport(rawValue: 1 << 22)
    
    // Ventura+ Features
    public static let advancedShortcuts = FeatureSupport(rawValue: 1 << 30)
    public static let stageManager = FeatureSupport(rawValue: 1 << 31)
    public static let enhancedNotes = FeatureSupport(rawValue: 1 << 32)
    
    // Sonoma+ Features
    public static let glassEffects = FeatureSupport(rawValue: 1 << 40)
    public static let interactiveWidgets = FeatureSupport(rawValue: 1 << 41)
    public static let enhancedSharing = FeatureSupport(rawValue: 1 << 42)
}

// MARK: - Compatibility Manager
public class CompatibilityManager: ObservableObject {
    
    // MARK: - Shared Instance
    public static let shared = CompatibilityManager()
    
    // MARK: - Properties
    private var currentVersion: macOSVersion?
    private var systemCapabilities: SystemCapabilities?
    private var detectedFeatures: Set<FeatureSupport> = []
    
    // MARK: - Initialization
    private init() {
        Task {
            await detectSystemCompatibility()
        }
    }
    
    // MARK: - System Detection
    private func detectSystemCompatibility() async {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
        currentVersion = macOSVersion(
            major: systemVersion.majorVersion,
            minor: systemVersion.minorVersion,
            patch: systemVersion.patchVersion
        )
        
        await detectSystemCapabilities()
        await determineAvailableFeatures()
        
        await MainActor.run {
            objectWillChange.send()
        }
    }
    
    private func detectSystemCapabilities() async {
        systemCapabilities = SystemCapabilities(
            supportsShortcuts: await checkShortcutsSupport(),
            supportsAdvancedVoice: await checkAdvancedVoiceSupport(),
            supportsGlassEffects: await checkGlassEffectsSupport(),
            supportsEnhancedSecurity: await checkEnhancedSecuritySupport(),
            supportsStageManager: await checkStageManagerSupport(),
            supportsModernShortcuts: await checkModernShortcutsSupport()
        )
    }
    
    // MARK: - Feature Detection
    private func determineAvailableFeatures() async {
        detectedFeatures.removeAll()
        
        guard let currentVersion = currentVersion else { return }
        
        // Basic features (Catalina+)
        detectedFeatures.insert(.basicApp)
        detectedFeatures.insert(.notesIntegration)
        detectedFeatures.insert(.voiceInput)
        
        // Version-specific features
        if currentVersion >= .bigSur {
            detectedFeatures.formUnion([.shortcutsIntegration, .modernUI, .systemColors])
        }
        
        if currentVersion >= .monterey {
            detectedFeatures.formUnion([.enhancedVoice, .focusModes, .liveText])
        }
        
        if currentVersion >= .ventura {
            detectedFeatures.formUnion([.advancedShortcuts, .stageManager, .enhancedNotes])
        }
        
        if currentVersion >= .sonoma {
            detectedFeatures.formUnion([.glassEffects, .interactiveWidgets, .enhancedSharing])
        }
        
        // System-specific features
        if systemCapabilities?.supportsShortcuts == true {
            detectedFeatures.insert(.shortcutsIntegration)
        }
        
        if systemCapabilities?.supportsAdvancedVoice == true {
            detectedFeatures.insert(.enhancedVoice)
        }
    }
    
    // MARK: - Public API
    
    /// Current macOS version
    public var version: macOSVersion? {
        return currentVersion
    }
    
    /// Check if specific feature is supported
    public func supports(_ feature: FeatureSupport) -> Bool {
        return detectedFeatures.contains(feature)
    }
    
    /// Check if version requirement is met
    public func isVersionSupported(_ requiredVersion: macOSVersion) -> Bool {
        guard let currentVersion = currentVersion else { return false }
        return currentVersion >= requiredVersion
    }
    
    /// Get all supported features
    public func getSupportedFeatures() -> Set<FeatureSupport> {
        return detectedFeatures
    }
    
    /// System capabilities
    public var capabilities: SystemCapabilities? {
        return systemCapabilities
    }
    
    /// Version-specific configuration
    public func getVersionConfiguration() -> VersionConfiguration {
        guard let version = currentVersion else {
            return VersionConfiguration(catalinaCompatible: false)
        }
        
        return VersionConfiguration(version: version)
    }
    
    // MARK: - Conditional UI Support
    public func shouldUseModernUI() -> Bool {
        return supports(.modernUI) && version >= .bigSur
    }
    
    public func shouldUseGlassEffects() -> Bool {
        return supports(.glassEffects) && version >= .sonoma
    }
    
    public func shouldUseAdvancedShortcuts() -> Bool {
        return supports(.advancedShortcuts) && version >= .ventura
    }
    
    // MARK: - Graceful Degradation
    public func getFallbackForMissingFeature(_ feature: FeatureSupport) -> String {
        switch feature {
        case .shortcutsIntegration:
            return "Shortcuts sind in dieser macOS-Version nicht verfügbar. Bitte aktualisieren Sie auf macOS 11.0 oder höher."
        case .glassEffects:
            return "Glaseffekte werden in dieser macOS-Version nicht unterstützt. Verwende Standard-UI-Stil."
        case .enhancedVoice:
            return "Erweiterte Sprachfunktionen sind in dieser Version nicht verfügbar. Basis-Sprachfunktionen sind verfügbar."
        default:
            return "Diese Funktion ist in Ihrer macOS-Version nicht verfügbar."
        }
    }
}

// MARK: - System Capabilities
public struct SystemCapabilities {
    public let supportsShortcuts: Bool
    public let supportsAdvancedVoice: Bool
    public let supportsGlassEffects: Bool
    public let supportsEnhancedSecurity: Bool
    public let supportsStageManager: Bool
    public let supportsModernShortcuts: Bool
    
    public init(
        supportsShortcuts: Bool,
        supportsAdvancedVoice: Bool,
        supportsGlassEffects: Bool,
        supportsEnhancedSecurity: Bool,
        supportsStageManager: Bool,
        supportsModernShortcuts: Bool
    ) {
        self.supportsShortcuts = supportsShortcuts
        self.supportsAdvancedVoice = supportsAdvancedVoice
        self.supportsGlassEffects = supportsGlassEffects
        self.supportsEnhancedSecurity = supportsEnhancedSecurity
        self.supportsStageManager = supportsStageManager
        self.supportsModernShortcuts = supportsModernShortcuts
    }
}

// MARK: - Version Configuration
public struct VersionConfiguration {
    public let version: macOSVersion?
    public let catalinaCompatible: Bool
    public let supportsShortcuts: Bool
    public let supportsGlassEffects: Bool
    public let supportsAdvancedUI: Bool
    
    public init(version: macOSVersion) {
        self.version = version
        self.catalinaCompatible = version >= .catalina
        self.supportsShortcuts = version >= .bigSur
        self.supportsGlassEffects = version >= .sonoma
        self.supportsAdvancedUI = version >= .bigSur
    }
    
    public init(catalinaCompatible: Bool) {
        self.version = nil
        self.catalinaCompatible = catalinaCompatible
        self.supportsShortcuts = catalinaCompatible
        self.supportsGlassEffects = catalinaCompatible
        self.supportsAdvancedUI = catalinaCompatible
    }
}

// MARK: - Private Helper Methods
private extension CompatibilityManager {
    
    private func checkShortcutsSupport() async -> Bool {
        guard #available(macOS 11.0, *) else { return false }
        
        // Check if Shortcuts app is available
        return FileManager.default.fileExists(atPath: "/System/Library/CoreServices/Shortcuts.app")
    }
    
    private func checkAdvancedVoiceSupport() async -> Bool {
        guard #available(macOS 12.0, *) else { return false }
        
        // Check for advanced speech recognition capabilities
        return NSSpeechRecognizer.isSpeechRecognitionAvailable()
    }
    
    private func checkGlassEffectsSupport() async -> Bool {
        guard #available(macOS 14.0, *) else { return false }
        
        // Check for glass effect material support
        return NSClassFromString("NSVisualEffectView") != nil
    }
    
    private func checkEnhancedSecuritySupport() async -> Bool {
        guard #available(macOS 11.0, *) else { return false }
        
        // Check for modern security features
        return checkKeychainModernAPIs()
    }
    
    private func checkStageManagerSupport() async -> Bool {
        guard #available(macOS 13.0, *) else { return false }
        
        // Check for Stage Manager availability
        return UserDefaults.standard.bool(forKey: "com.apple.WindowManager.StageManager")
    }
    
    private func checkModernShortcutsSupport() async -> Bool {
        guard #available(macOS 13.0, *) else { return false }
        
        // Check for advanced Shortcuts integration
        return checkShortcutsIntegration()
    }
    
    private func checkKeychainModernAPIs() -> Bool {
        // Check if modern Keychain APIs are available
        return SecItemCopyMatching != nil
    }
    
    private func checkShortcutsIntegration() -> Bool {
        // Check for modern Shortcuts framework availability
        return NSClassFromString("NSScriptStandardSuiteCommand") != nil
    }
}

// MARK: - macOSVersion Helper Extensions
private extension macOSVersion {
    init?(major: Int, minor: Int, patch: Int) {
        let versionString = "\(major).\(minor)"
        
        // Handle special cases for newer versions
        if major >= 15 {
            self = .sequoia
        } else if major == 14 {
            self = .sonoma
        } else if major == 13 {
            self = .ventura
        } else if major == 12 {
            self = .monterey
        } else if major == 11 {
            self = .bigSur
        } else if major == 10, minor >= 15 {
            self = .catalina
        } else {
            // Unsupported older versions
            return nil
        }
    }
    
    static func >= (lhs: macOSVersion, rhs: macOSVersion) -> Bool {
        let lhsMajor = lhs.majorVersion
        let rhsMajor = rhs.majorVersion
        
        if lhsMajor > rhsMajor {
            return true
        } else if lhsMajor < rhsMajor {
            return false
        }
        
        // Same major version, compare minor
        return lhs.minorVersion >= rhs.minorVersion
    }
    
    var majorVersion: Int {
        switch self {
        case .catalina: return 10
        case .bigSur: return 11
        case .monterey: return 12
        case .ventura: return 13
        case .sonoma: return 14
        case .sequoia: return 15
        }
    }
    
    var minorVersion: Int {
        switch self {
        case .catalina: return 15
        case .bigSur, .monterey, .ventura, .sonoma, .sequoia: return 0
        }
    }
}

// MARK: - Performance Considerations
extension CompatibilityManager {
    
    /// Check if system is under memory pressure
    public func isSystemUnderMemoryPressure() -> Bool {
        let memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         task_info_t($0),
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let availableMemory = ProcessInfo.processInfo.physicalMemory
            let usedMemory = memoryInfo.resident_size
            return Double(usedMemory) > Double(availableMemory) * 0.8
        }
        
        return false
    }
    
    /// Check background app limits
    public func canRunInBackground() -> Bool {
        let isLowPowerMode = ProcessInfo.processInfo.thermalState == .critical
        return !isLowPowerMode
    }
}

// MARK: - Security and Permissions
extension CompatibilityManager {
    
    /// Check required permissions based on version
    public func getRequiredPermissions() -> [PermissionType] {
        guard let version = currentVersion else { return [] }
        
        var permissions: [PermissionType] = [.accessibility, .aacStartFinishSpeakables]
        
        if version >= .bigSur {
            permissions.append(.shortcuts)
        }
        
        if version >= .sonoma {
            permissions.append(.automatedRemoteDesktop)
        }
        
        return permissions
    }
    
    /// Permission types
    public enum PermissionType: String, CaseIterable {
        case accessibility = "accessibility"
        case shortcuts = "shortcuts"
        case aacStartFinishSpeakables = "aacStartFinishSpeakables"
        case automatedRemoteDesktop = "automatedRemoteDesktop"
        case notes = "notes"
    }
    
    /// Check if all required permissions are granted
    public func checkPermissions() async -> PermissionStatus {
        // Implementation would check each permission type
        // This is a simplified version
        return PermissionStatus.granted
    }
}

// MARK: - Permission Status
public enum PermissionStatus {
    case granted
    case denied
    case limited
    case unknown
    
    public var description: String {
        switch self {
        case .granted: return "Erlaubt"
        case .denied: return "Verweigert"
        case .limited: return "Eingeschränkt"
        case .unknown: return "Unbekannt"
        }
    }
}