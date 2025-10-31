//
//  AppSettings.swift
//  StatusBarApp
//
//  Haupt-Settings Datenmodell
//

import Foundation

// MARK: - Main Settings Model

struct AppSettings: Codable, Equatable {
    var general: GeneralSettings = GeneralSettings()
    var ki: KISettings = KISettings()
    var storage: StorageSettings = StorageSettings()
    var autoSave: AutoSaveSettings = AutoSaveSettings()
    var shortcuts: ShortcutsSettings = ShortcutsSettings()
    var notifications: NotificationSettings = NotificationSettings()
    var privacy: PrivacySettings = PrivacySettings()
    var about: AboutSettings = AboutSettings()
    var onboarding: OnboardingSettings = OnboardingSettings()
}

// MARK: - General Settings

struct GeneralSettings: Codable, Equatable {
    var autoStart = true
    var showInDock = false
    var theme: Theme = .auto
    var language = "de"
    var showWelcomeOnStartup = true
    var enableAnalytics = false
    var enableCrashReporting = true
}

enum Theme: String, CaseIterable, Codable {
    case light = "hell"
    case dark = "dunkel"
    case auto = "auto"
}

// MARK: - KI Settings

struct KISettings: Codable, Equatable {
    var enabledProviders: [String] = ["openai"]
    var primaryProvider = "openai"
    var openAI: OpenAISettings = OpenAISettings()
    var openRouter: OpenRouterSettings = OpenRouterSettings()
    var localModels: LocalModelsSettings = LocalModelsSettings()
    var fallbackProvider: String? = "openrouter"
    var retryAttempts = 3
    var timeout: TimeInterval = 30.0
    var enableLogging = true
}

struct OpenAISettings: Codable, Equatable {
    var apiKey = ""
    var model = "gpt-4"
    var maxTokens = 4000
    var temperature = 0.7
    var topP = 1.0
    var frequencyPenalty = 0.0
    var presencePenalty = 0.0
    var stream = false
}

struct OpenRouterSettings: Codable, Equatable {
    var apiKey = ""
    var baseURL = "https://openrouter.ai/api/v1"
    var defaultModel = "meta-llama/llama-2-70b-chat"
    var maxTokens = 4000
    var temperature = 0.7
    var stream = false
}

struct LocalModelsSettings: Codable, Equatable {
    var enabled = false
    var modelPath = ""
    var contextLength = 2048
    var gpuLayers = 0
    var threads = 4
    var temperature = 0.7
    var threadsPerCore = 1
}

// MARK: - Storage Settings

struct StorageSettings: Codable, Equatable {
    var primaryProvider: String = "icloud"
    var secondaryProvider: String? = nil
    var enableEncryption = true
    var compressionEnabled = true
    var retentionDays = 365
    var autoCleanup = true
    var maxStorageSize: Int64 = 1024 * 1024 * 1024 // 1GB
    var syncInterval: TimeInterval = 300 // 5 minutes
    
    var icloud: ICloudSettings = ICloudSettings()
    var local: LocalStorageSettings = LocalStorageSettings()
    var dropbox: DropboxSettings = DropboxSettings()
}

struct ICloudSettings: Codable, Equatable {
    var enabled = true
    var containerId = "iCloud.com.statusbarapp"
    var syncEnabled = true
    var encryptionEnabled = true
}

struct LocalStorageSettings: Codable, Equatable {
    var path = ""
    var autoBackup = true
    var backupInterval: TimeInterval = 86400 // 24 hours
    var maxBackupCount = 10
}

struct DropboxSettings: Codable, Equatable {
    var accessToken = ""
    var appKey = ""
    var rootFolder = "/StatusBarApp"
    var syncEnabled = false
}

// MARK: - Auto-Save Settings

struct AutoSaveSettings: Codable, Equatable {
    var enabled = true
    var interval: TimeInterval = 300 // 5 minutes
    var onFocusLoss = true
    var onQuit = true
    var askBeforeSaving = false
    var maxRetries = 3
    var compressionEnabled = true
    var encryptSensitive = false
}

// MARK: - Shortcuts Settings

struct ShortcutsSettings: Codable, Equatable {
    var globalShortcut = "⌘⇧N"
    var showWindowShortcut = "⌘⇧W"
    var hideWindowShortcut = "⌘⇧H"
    var quitShortcut = "⌘⇥"
    var settingsShortcut = "⌘,"
    var enableGlobalShortcuts = true
    var enableSystemShortcuts = true
    var conflictDetection = true
    var customShortcuts: [String: String] = [:]
}

// MARK: - Notification Settings

struct NotificationSettings: Codable, Equatable {
    var enabled = true
    var soundEnabled = true
    var errorNotifications = true
    var successNotifications = true
    var autoSaveNotifications = false
    var syncNotifications = true
    var privacyLevel: PrivacyLevel = .minimal
    var showToast = true
    var showBadge = false
    var vibrate = false // for future iOS integration
}

enum PrivacyLevel: String, CaseIterable, Codable {
    case minimal = "minimal"
    case balanced = "ausgewogen"
    case detailed = "detailliert"
}

// MARK: - Privacy Settings

struct PrivacySettings: Codable, Equatable {
    var dataCollection = false
    var analyticsEnabled = false
    var crashReportingEnabled = true
    var enableEncryption = true
    var biometricAuth = false
    var sessionTimeout: TimeInterval = 3600 // 1 hour
    var autoLock = false
    var secureDelete = true
    var auditLogging = false
}

// MARK: - About Settings

struct AboutSettings: Codable, Equatable {
    var version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    var buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    var supportURL = "https://github.com/statusbarapp/support"
    var documentationURL = "https://docs.statusbarapp.com"
    var privacyPolicyURL = "https://statusbarapp.com/privacy"
    var termsOfServiceURL = "https://statusbarapp.com/terms"
    var showInMenubar = true
    var checkForUpdates = true
    var updateChannel: UpdateChannel = .stable
}

enum UpdateChannel: String, CaseIterable, Codable {
    case stable = "stabil"
    case beta = "beta"
    case nightly = "nightly"
}

// MARK: - Onboarding Settings

struct OnboardingSettings: Codable, Equatable {
    var completed = false
    var currentStep = 0
    var totalSteps = 5
    var enableTooltips = true
    var enableHints = true
    var skipIntro = false
    var completedSteps: [Int] = []
    var showQuickStart = true
    var tutorialSkipped = false
}

// MARK: - Settings Extensions

extension AppSettings {
    static let `default`: AppSettings = {
        var settings = AppSettings()
        settings.general.theme = .auto
        settings.ki.enabledProviders = ["openai"]
        settings.ki.primaryProvider = "openai"
        settings.storage.primaryProvider = "icloud"
        settings.autoSave.enabled = true
        settings.autoSave.interval = 300
        settings.shortcuts.globalShortcut = "⌘⇧N"
        settings.notifications.enabled = true
        settings.notifications.privacyLevel = .minimal
        return settings
    }()
}