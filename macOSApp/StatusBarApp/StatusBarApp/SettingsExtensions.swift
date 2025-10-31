//
//  SettingsExtensions.swift
//  StatusBarApp
//
//  Extensions für Settings-bezogene Funktionalität
//

import Foundation
import UserNotifications

// MARK: - Notification Names

extension Notification.Name {
    static let settingsChanged = Notification.Name("SettingsChanged")
    static let autoSaveTriggered = Notification.Name("AutoSaveTriggered")
    static let kiProviderChanged = Notification.Name("KIProviderChanged")
    static let storageProviderChanged = Notification.Name("StorageProviderChanged")
    static let shortcutTriggered = Notification.Name("ShortcutTriggered")
    static let notificationPermissionChanged = Notification.Name("NotificationPermissionChanged")
}

// MARK: - Permission Checker Classes

class InputMonitorPermission {
    static let shared = InputMonitorPermission()
    
    private init() {}
    
    var hasPermission: Bool {
        // Check for Input Monitoring permission
        // This would normally involve checking actual macOS permissions
        return true // Placeholder
    }
}

class ScreenCapturePermission {
    static let shared = ScreenCapturePermission()
    
    private init() {}
    
    var hasPermission: Bool {
        // Check for Screen Recording permission
        return CGPreflightApplicationsAllowedToCaptureScreenWithCursor() != 0 // Placeholder
    }
}

// MARK: - Settings Validation Extension

extension AppSettings {
    func validate() -> [String: String] {
        var errors: [String: String] = [:]
        
        // KI Provider validation
        if ki.enabledProviders.isEmpty {
            errors["ki"] = "Mindestens ein KI-Provider muss ausgewählt werden"
        }
        
        if ki.primaryProvider.isEmpty {
            errors["ki_primary"] = "Ein primärer KI-Provider muss ausgewählt werden"
        }
        
        // OpenAI validation
        if ki.enabledProviders.contains("openai") && !ki.openAI.apiKey.isEmpty && ki.openAI.apiKey != "***HIDDEN***" {
            if !isValidAPIKey(ki.openAI.apiKey, provider: "openai") {
                errors["openai_key"] = "Ungültiger OpenAI API Key"
            }
        }
        
        // Storage validation
        if storage.primaryProvider.isEmpty {
            errors["storage_primary"] = "Ein primärer Storage Provider muss ausgewählt werden"
        }
        
        // Auto-Save validation
        if autoSave.enabled && autoSave.interval < 60 {
            errors["autosave_interval"] = "Auto-Save Intervall muss mindestens 1 Minute betragen"
        }
        
        // Shortcuts validation
        if shortcuts.globalShortcut.isEmpty {
            errors["shortcuts_global"] = "Ein globaler Shortcut muss konfiguriert werden"
        }
        
        // Notification validation
        if notifications.enabled {
            checkNotificationPermissions { hasPermission in
                if !hasPermission {
                    errors["notifications"] = "Benachrichtigungs-Berechtigung fehlt"
                }
            }
        }
        
        return errors
    }
    
    private func isValidAPIKey(_ key: String, provider: String) -> Bool {
        // Basic API key validation
        switch provider {
        case "openai":
            return key.hasPrefix("sk-") && key.count > 20
        case "openrouter":
            return key.count > 20
        default:
            return true
        }
    }
    
    private func checkNotificationPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
}

// MARK: - Settings Migration

extension AppSettings {
    static func migrate(from oldVersion: String, to newVersion: String) -> AppSettings {
        var settings = AppSettings.default
        
        // Migration logic would go here
        print("Migrating settings from version \(oldVersion) to \(newVersion)")
        
        return settings
    }
    
    func backup() -> SettingsBackup {
        return SettingsBackup(
            settings: self,
            timestamp: Date(),
            version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        )
    }
}

// MARK: - Settings Backup Model

struct SettingsBackup: Codable {
    let settings: AppSettings
    let timestamp: Date
    let version: String
    
    init(settings: AppSettings, timestamp: Date, version: String) {
        self.settings = settings
        self.timestamp = timestamp
        self.version = version
    }
}

// MARK: - Settings Analytics

extension AppSettings {
    func getAnalyticsData() -> SettingsAnalytics {
        return SettingsAnalytics(
            kiProvidersCount: ki.enabledProviders.count,
            autoSaveEnabled: autoSave.enabled,
            notificationsEnabled: notifications.enabled,
            shortcutsConfigured: !shortcuts.customShortcuts.isEmpty,
            privacyLevel: notifications.privacyLevel.rawValue,
            encryptionEnabled: privacy.enableEncryption,
            biometricAuthEnabled: privacy.biometricAuth,
            theme: general.theme.rawValue
        )
    }
}

// MARK: - Settings Analytics Model

struct SettingsAnalytics: Codable {
    let kiProvidersCount: Int
    let autoSaveEnabled: Bool
    let notificationsEnabled: Bool
    let shortcutsConfigured: Bool
    let privacyLevel: String
    let encryptionEnabled: Bool
    let biometricAuthEnabled: Bool
    let theme: String
}

// MARK: - Settings Debug Info

extension AppSettings {
    func getDebugInfo() -> [String: Any] {
        return [
            "ki_enabled_providers": ki.enabledProviders,
            "ki_primary_provider": ki.primaryProvider,
            "storage_primary": storage.primaryProvider,
            "autosave_enabled": autoSave.enabled,
            "notifications_enabled": notifications.enabled,
            "shortcuts_count": shortcuts.customShortcuts.count,
            "privacy_encryption": privacy.enableEncryption,
            "general_theme": general.theme.rawValue
        ]
    }
}

// MARK: - Settings Observer

class SettingsObserver: ObservableObject {
    private var observers: [Any] = []
    
    func addObserver(_ block: @escaping (AppSettings) -> Void) {
        let observer = NotificationCenter.default.addObserver(
            forName: .settingsChanged,
            object: nil,
            queue: .main
        ) { notification in
            if let settings = notification.object as? AppSettings {
                block(settings)
            }
        }
        observers.append(observer)
    }
    
    func removeAllObservers() {
        observers.forEach { observer in
            if let anyObserver = observer as? Any {
                NotificationCenter.default.removeObserver(anyObserver)
            }
        }
        observers.removeAll()
    }
    
    deinit {
        removeAllObservers()
    }
}

// MARK: - Settings Factory

class SettingsFactory {
    static func createDefaultSettings() -> AppSettings {
        return AppSettings.default
    }
    
    static func createMinimalSettings() -> AppSettings {
        var settings = AppSettings.default
        settings.ki.enabledProviders = []
        settings.storage.primaryProvider = ""
        settings.autoSave.enabled = false
        settings.notifications.enabled = false
        return settings
    }
    
    static func createDeveloperSettings() -> AppSettings {
        var settings = AppSettings.default
        settings.ki.enableLogging = true
        settings.general.enableAnalytics = true
        settings.general.enableCrashReporting = true
        settings.privacy.auditLogging = true
        return settings
    }
    
    static func createProductionSettings() -> AppSettings {
        var settings = AppSettings.default
        settings.ki.enableLogging = false
        settings.general.enableAnalytics = false
        settings.privacy.enableEncryption = true
        settings.privacy.secureDelete = true
        return settings
    }
}

// MARK: - Settings Presets

extension AppSettings {
    static let developer = SettingsFactory.createDeveloperSettings()
    static let production = SettingsFactory.createProductionSettings()
    static let minimal = SettingsFactory.createMinimalSettings()
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let settingsTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    static let settingsISO8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()
}

// MARK: - Settings Constants

struct SettingsConstants {
    static let minimumAutoSaveInterval: TimeInterval = 60
    static let maximumAutoSaveInterval: TimeInterval = 3600
    static let defaultAutoSaveInterval: TimeInterval = 300
    static let maximumRetries = 10
    static let defaultTimeout: TimeInterval = 30
    static let minimumSessionTimeout: TimeInterval = 300
    static let maximumSessionTimeout: TimeInterval = 86400
    static let defaultSessionTimeout: TimeInterval = 3600
    static let settingsVersion = "1.0"
    static let settingsMigrationVersion = "1.0.0"
}

// MARK: - Settings URL Extensions

extension URL {
    var isValidSettingsFile: Bool {
        let validExtensions = ["json"]
        return validExtensions.contains(pathExtension.lowercased())
    }
    
    var settingsFileName: String {
        let timestamp = DateFormatter.settingsTimestamp.string(from: Date())
        return "StatusBarApp_Settings_\(timestamp).json"
    }
}