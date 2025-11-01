//
//  UserPromptPreferences.swift
//  Intelligente Notizen App
//

import Foundation

// MARK: - User Prompt Preferences Protocol
protocol UserPromptPreferencesManaging: AnyObject {
    func getPreferences() async -> UserPromptPreferences
    func updatePreferences(_ preferences: UserPromptPreferences) async
    func resetToDefaults() async
    func exportPreferences() async -> Data
    func importPreferences(from data: Data) async throws
    func getLanguagePreferences() async -> LanguagePreferences
    func getContentTypePreferences() async -> ContentTypePreferences
}

// MARK: - User Prompt Preferences
struct UserPromptPreferences: Codable {
    var preferredLanguage: PromptLanguage = .german
    var autoDetectLanguage: Bool = true
    var defaultPromptLength: PromptLength = .medium
    var enableAutoOptimization: Bool = true
    var enableCaching: Bool = true
    var cacheRetentionDays: Int = 7
    var enableABTesting: Bool = false
    var privacyMode: Bool = false
    var modelPreference: ModelPreference = .gpt4
    var responseFormat: ResponseFormat = .structured
    var tone: PromptTone = .professional
    var detailLevel: DetailLevel = .medium
    var includeExamples: Bool = true
    var includeContext: Bool = true
    var enableRealTimeOptimization: Bool = true
    var maxResponseTime: TimeInterval = 30.0
    var contentFiltering: ContentFiltering = .standard
    var accessibilitySettings: AccessibilitySettings = AccessibilitySettings()
    var customPrompts: [String: CustomPromptConfig] = [:]
    var createdAt: Date = Date()
    var lastModified: Date = Date()
    var version: String = "1.0"
    
    // MARK: - Computed Properties
    var isGermanPreferred: Bool {
        return preferredLanguage == .german
    }
    
    var shouldUseCache: Bool {
        return enableCaching && !privacyMode
    }
    
    var maxTokens: Int {
        switch defaultPromptLength {
        case .short: return 1000
        case .medium: return 2500
        case .long: return 4000
        case .unlimited: return 8000
        }
    }
    
    var recommendedResponseTime: TimeInterval {
        return maxResponseTime
    }
}

// MARK: - Supporting Enums
enum PromptLength: String, CaseIterable, Codable {
    case short = "Kurz"
    case medium = "Mittel"
    case long = "Lang"
    case unlimited = "Unbegrenzt"
    
    var tokenLimit: Int {
        switch self {
        case .short: return 1000
        case .medium: return 2500
        case .long: return 4000
        case .unlimited: return 8000
        }
    }
    
    var displayName: String {
        return rawValue
    }
}

enum ModelPreference: String, CaseIterable, Codable {
    case gpt4 = "GPT-4"
    case gpt35 = "GPT-3.5"
    case claude = "Claude"
    case gemini = "Gemini"
    case auto = "Automatisch"
    
    var displayName: String {
        return rawValue
    }
    
    var isPremium: Bool {
        return self == .gpt4 || self == .claude
    }
}

enum ResponseFormat: String, CaseIterable, Codable {
    case structured = "Strukturiert"
    case narrative = "Erzählend"
    case bullet = "Stichpunkte"
    case concise = "Kompakt"
    
    var displayName: String {
        return rawValue
    }
}

enum PromptTone: String, CaseIterable, Codable {
    case professional = "Professionell"
    case casual = "Locker"
    case formal = "Formell"
    case friendly = "Freundlich"
    case technical = "Technisch"
    
    var displayName: String {
        return rawValue
    }
}

enum DetailLevel: String, CaseIterable, Codable {
    case brief = "Kurz"
    case medium = "Mittel"
    case comprehensive = "Umfassend"
    case exhaustive = "Detailliert"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .brief: return "Kurze, fokussierte Antworten"
        case .medium: return "Ausgewogene Detailtiefe"
        case .comprehensive: return "Umfassende Analyse"
        case .exhaustive: return "Maximale Detailtiefe"
        }
    }
}

enum ContentFiltering: String, CaseIterable, Codable {
    case none = "Keine"
    case standard = "Standard"
    case strict = "Strikt"
    case custom = "Benutzerdefiniert"
    
    var displayName: String {
        return rawValue
    }
}

struct AccessibilitySettings: Codable {
    var highContrast: Bool = false
    var largeText: Bool = false
    var voiceOutput: Bool = false
    var keyboardNavigation: Bool = true
    var screenReaderOptimized: Bool = false
    var colorBlindFriendly: Bool = false
}

struct CustomPromptConfig: Codable {
    let contentType: ContentType
    let template: String
    let parameters: [String: String]
    let language: PromptLanguage
    var usageCount: Int = 0
    let createdAt: Date
}

// MARK: - Language Preferences
struct LanguagePreferences: Codable {
    var primaryLanguage: PromptLanguage = .german
    var secondaryLanguages: [PromptLanguage] = [.english]
    var autoDetect: Bool = true
    var fallbackLanguage: PromptLanguage = .english
    var showTranslations: Bool = false
    var nativeTerms: Bool = true
    var formalTone: Bool = false
    
    var supportedLanguages: [PromptLanguage] {
        var languages = [primaryLanguage] + secondaryLanguages
        languages.append(fallbackLanguage)
        return Array(Set(languages))
    }
    
    func getOptimalLanguage(for content: String) -> PromptLanguage {
        if autoDetect {
            // Simple language detection based on character patterns
            let germanIndicators = ["der", "die", "das", "und", "ist", "mit", "auf"]
            let englishIndicators = ["the", "and", "is", "with", "for", "this", "that"]
            
            let lowercaseContent = content.lowercased()
            let germanScore = germanIndicators.reduce(0) { $0 + (lowercaseContent.contains($1) ? 1 : 0) }
            let englishScore = englishIndicators.reduce(0) { $0 + (lowercaseContent.contains($1) ? 1 : 0) }
            
            return germanScore > englishScore ? .german : .english
        }
        
        return primaryLanguage
    }
}

// MARK: - Content Type Preferences
struct ContentTypePreferences: Codable {
    var defaultPrompts: [ContentType: ContentTypePrompt] = [:]
    var customTemplates: [ContentType: [CustomPromptTemplate]] = [:]
    var autoClassification: Bool = true
    var confidenceThreshold: Double = 0.7
    var manualOverride: Bool = true
    
    init() {
        // Initialize with default preferences
        self.defaultPrompts = [
            .email: ContentTypePrompt(
                summaryPrompt: "Erstelle eine strukturierte E-Mail-Zusammenfassung",
                actionPrompt: "Extrahiere alle Action Items",
                priorityPrompt: "Bewerte die Priorität"
            ),
            .meeting: ContentTypePrompt(
                summaryPrompt: "Strukturiere das Meeting-Protokoll",
                actionPrompt: "Extrahiere Beschlüsse und Action Items",
                priorityPrompt: "Bewerte die Dringlichkeit"
            ),
            .article: ContentTypePrompt(
                summaryPrompt: "Erstelle eine prägnante Zusammenfassung",
                actionPrompt: "Identifiziere wichtige Erkenntnisse",
                priorityPrompt: "Bewerte die Relevanz"
            ),
            .code: ContentTypePrompt(
                summaryPrompt: "Dokumentiere die Code-Funktionalität",
                actionPrompt: "Identifiziere Verbesserungsvorschläge",
                priorityPrompt: "Bewerte die Code-Qualität"
            )
        ]
    }
}

struct ContentTypePrompt: Codable {
    let summaryPrompt: String
    let actionPrompt: String
    let priorityPrompt: String
}

// MARK: - User Preferences Manager
final class UserPromptPreferencesManager: ObservableObject, UserPromptPreferencesManaging {
    
    @Published var currentPreferences: UserPromptPreferences = UserPromptPreferences()
    @Published var isLoading: Bool = false
    
    private let storage = UserPreferencesStorage()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadPreferences()
        setupAutoSave()
    }
    
    func getPreferences() async -> UserPromptPreferences {
        return currentPreferences
    }
    
    func updatePreferences(_ preferences: UserPromptPreferences) async {
        var updatedPreferences = preferences
        updatedPreferences.lastModified = Date()
        
        await MainActor.run {
            currentPreferences = updatedPreferences
            isLoading = true
        }
        
        do {
            try await storage.savePreferences(updatedPreferences)
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
            // Handle error (could show user notification)
            print("Failed to save preferences: \(error)")
        }
    }
    
    func resetToDefaults() async {
        let defaultPreferences = UserPromptPreferences()
        await updatePreferences(defaultPreferences)
    }
    
    func exportPreferences() async -> Data {
        return try! JSONEncoder().encode(currentPreferences)
    }
    
    func importPreferences(from data: Data) async throws {
        let importedPreferences = try JSONDecoder().decode(UserPromptPreferences.self, from: data)
        await updatePreferences(importedPreferences)
    }
    
    func getLanguagePreferences() async -> LanguagePreferences {
        // Extract language-specific preferences
        return LanguagePreferences(
            primaryLanguage: currentPreferences.preferredLanguage,
            autoDetect: currentPreferences.autoDetectLanguage,
            fallbackLanguage: currentPreferences.preferredLanguage == .german ? .english : .german
        )
    }
    
    func getContentTypePreferences() async -> ContentTypePreferences {
        return await storage.getContentTypePreferences()
    }
    
    // MARK: - Convenience Methods
    func updateLanguagePreference(_ language: PromptLanguage) async {
        var preferences = currentPreferences
        preferences.preferredLanguage = language
        await updatePreferences(preferences)
    }
    
    func toggleAutoOptimization() async {
        var preferences = currentPreferences
        preferences.enableAutoOptimization.toggle()
        await updatePreferences(preferences)
    }
    
    func updateDetailLevel(_ level: DetailLevel) async {
        var preferences = currentPreferences
        preferences.detailLevel = level
        await updatePreferences(preferences)
    }
    
    func updateTone(_ tone: PromptTone) async {
        var preferences = currentPreferences
        preferences.tone = tone
        await updatePreferences(preferences)
    }
    
    // MARK: - Private Methods
    private func loadPreferences() {
        Task {
            let savedPreferences = await storage.loadPreferences()
            await MainActor.run {
                currentPreferences = savedPreferences
            }
        }
    }
    
    private func setupAutoSave() {
        // Set up automatic saving when preferences change
        $currentPreferences
            .debounce(for: .milliseconds(1000), scheduler: DispatchQueue.main)
            .sink { [weak self] preferences in
                Task {
                    await self?.updatePreferences(preferences)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - User Preferences Storage
final class UserPreferencesStorage {
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "UserPromptPreferences"
    private let languagePrefsKey = "LanguagePreferences"
    private let contentTypePrefsKey = "ContentTypePreferences"
    
    func savePreferences(_ preferences: UserPromptPreferences) async throws {
        let data = try JSONEncoder().encode(preferences)
        userDefaults.set(data, forKey: preferencesKey)
    }
    
    func loadPreferences() async -> UserPromptPreferences {
        guard let data = userDefaults.data(forKey: preferencesKey),
              let preferences = try? JSONDecoder().decode(UserPromptPreferences.self, from: data) else {
            return UserPromptPreferences()
        }
        return preferences
    }
    
    func getContentTypePreferences() async -> ContentTypePreferences {
        guard let data = userDefaults.data(forKey: contentTypePrefsKey),
              let prefs = try? JSONDecoder().decode(ContentTypePreferences.self, from: data) else {
            return ContentTypePreferences()
        }
        return prefs
    }
    
    func saveLanguagePreferences(_ preferences: LanguagePreferences) async {
        let data = try! JSONEncoder().encode(preferences)
        userDefaults.set(data, forKey: languagePrefsKey)
    }
    
    func loadLanguagePreferences() async -> LanguagePreferences {
        guard let data = userDefaults.data(forKey: languagePrefsKey),
              let preferences = try? JSONDecoder().decode(LanguagePreferences.self, from: data) else {
            return LanguagePreferences()
        }
        return preferences
    }
}