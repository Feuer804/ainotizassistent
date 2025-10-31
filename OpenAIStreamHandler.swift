//
//  OpenAIStreamHandler.swift
//  AINotizassistent
//
//  Created by Claude on 2025-10-31.
//  Streaming Response Handler für OpenAI API
//

import Foundation
import SwiftUI
import Combine

// MARK: - Streaming Response Handler

class OpenAIStreamHandler: ObservableObject {
    @Published var currentResponse: String = ""
    @Published var isStreaming: Bool = false
    @Published var errorMessage: String?
    @Published var progress: Double = 0.0
    
    private var streamTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    func startStreaming(
        client: OpenAIClient,
        messages: [OpenAIMessage],
        model: String = "gpt-4"
    ) {
        cancelCurrentStream()
        
        isStreaming = true
        errorMessage = nil
        currentResponse = ""
        progress = 0.0
        
        streamTask = Task { [weak self] in
            do {
                let stream = try await client.sendMessageStream(
                    messages: messages,
                    model: model
                )
                
                for try await content in stream {
                    if Task.isCancelled { break }
                    
                    await MainActor.run {
                        self?.appendContent(content)
                    }
                }
                
                await MainActor.run {
                    self?.isStreaming = false
                    self?.progress = 1.0
                }
            } catch {
                await MainActor.run {
                    self?.handleError(error)
                }
            }
        }
    }
    
    func cancelCurrentStream() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }
    
    private func appendContent(_ content: String) {
        currentResponse += content
        // Fortschritt basierend auf Response-Länge schätzen
        let estimatedTotalLength = max(currentResponse.count * 2, 100)
        progress = min(Double(currentResponse.count) / Double(estimatedTotalLength), 0.9)
    }
    
    private func handleError(_ error: Error) {
        isStreaming = false
        progress = 0.0
        
        if let openAIError = error as? OpenAIError {
            switch openAIError {
            case .rateLimited(let waitTime):
                errorMessage = "Rate Limit erreicht. Versuchen Sie es in \(Int(waitTime)) Sekunden erneut."
            case .dailyLimitExceeded:
                errorMessage = "Tägliches Limit erreicht. Bitte versuchen Sie es morgen erneut."
            case .noAPIKey:
                errorMessage = "Kein API Key konfiguriert. Bitte konfigurieren Sie Ihren OpenAI API Key."
            default:
                errorMessage = openAIError.localizedDescription
            }
        } else {
            errorMessage = "Unbekannter Fehler: \(error.localizedDescription)"
        }
    }
    
    deinit {
        cancelCurrentStream()
    }
}

// MARK: - SwiftUI View Models

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let openAIClient: OpenAIClient
    private var cancellables = Set<AnyCancellable>()
    
    init(openAIClient: OpenAIClient = OpenAIClient.shared) {
        self.openAIClient = openAIClient
        setupBindings()
    }
    
    private func setupBindings() {
        // Observer für API Key Changes
        NotificationCenter.default.publisher(for: .apiKeyChanged, object: nil)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkAPIKeyStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isLoading else { return }
        
        let userMessage = ChatMessage(role: "user", content: inputText)
        messages.append(userMessage)
        
        let messageToSend = inputText
        inputText = ""
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await openAIClient.sendMessage(
                    messages: messages.map { OpenAIMessage(role: $0.role, content: $0.content) },
                    model: "gpt-4",
                    temperature: 0.7
                )
                
                await MainActor.run {
                    if let choice = response.choices.first {
                        let assistantMessage = ChatMessage(role: choice.message?.role ?? "assistant", content: choice.message?.content ?? "Keine Antwort erhalten")
                        self.messages.append(assistantMessage)
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    func clearChat() {
        messages.removeAll()
        inputText = ""
        errorMessage = nil
    }
    
    private func checkAPIKeyStatus() {
        if !openAIClient.hasValidAPIKey() {
            errorMessage = "Kein gültiger OpenAI API Key konfiguriert. Bitte konfigurieren Sie ihn in den Einstellungen."
        }
    }
    
    private func handleError(_ error: Error) {
        isLoading = false
        
        if let openAIError = error as? OpenAIError {
            switch openAIError {
            case .rateLimited(let waitTime):
                errorMessage = "Rate Limit erreicht. Versuchen Sie es in \(Int(waitTime)) Sekunden erneut."
            case .dailyLimitExceeded:
                errorMessage = "Tägliches Limit erreicht. Bitte versuchen Sie es morgen erneut."
            case .noAPIKey:
                errorMessage = "Kein API Key konfiguriert. Bitte konfigurieren Sie Ihren OpenAI API Key."
            default:
                errorMessage = openAIError.localizedDescription
            }
        } else {
            errorMessage = "Unbekannter Fehler: \(error.localizedDescription)"
        }
    }
}

// MARK: - Message Models

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: String
    let content: String
    let timestamp: Date
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
    
    var isUser: Bool {
        role == "user"
    }
    
    var isAssistant: Bool {
        role == "assistant"
    }
}

// MARK: - Content Generation View Models

class EmailGenerationViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var emailType: EmailType = .general
    @Published var generatedEmail: String = ""
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    private let openAIClient: OpenAIClient
    
    init(openAIClient: OpenAIClient = OpenAIClient.shared) {
        self.openAIClient = openAIClient
    }
    
    func generateEmail() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isGenerating else { return }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await openAIClient.generateEmail(
                    content: inputText,
                    model: "gpt-4",
                    emailType: emailType
                )
                
                await MainActor.run {
                    if let choice = response.choices.first {
                        self.generatedEmail = choice.message?.content ?? "Keine Antwort erhalten"
                    }
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    func clearAll() {
        inputText = ""
        generatedEmail = ""
        errorMessage = nil
    }
    
    private func handleError(_ error: Error) {
        isGenerating = false
        
        if let openAIError = error as? OpenAIError {
            switch openAIError {
            case .rateLimited(let waitTime):
                errorMessage = "Rate Limit erreicht. Versuchen Sie es in \(Int(waitTime)) Sekunden erneut."
            case .dailyLimitExceeded:
                errorMessage = "Tägliches Limit erreicht."
            case .noAPIKey:
                errorMessage = "Kein API Key konfiguriert."
            default:
                errorMessage = openAIError.localizedDescription
            }
        } else {
            errorMessage = "Unbekannter Fehler: \(error.localizedDescription)"
        }
    }
}

class MeetingGenerationViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var meetingType: MeetingType = .general
    @Published var generatedMeeting: String = ""
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    private let openAIClient: OpenAIClient
    
    init(openAIClient: OpenAIClient = OpenAIClient.shared) {
        self.openAIClient = openAIClient
    }
    
    func generateMeeting() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isGenerating else { return }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await openAIClient.generateMeeting(
                    content: inputText,
                    model: "gpt-4",
                    meetingType: meetingType
                )
                
                await MainActor.run {
                    if let choice = response.choices.first {
                        self.generatedMeeting = choice.message?.content ?? "Keine Antwort erhalten"
                    }
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    func clearAll() {
        inputText = ""
        generatedMeeting = ""
        errorMessage = nil
    }
    
    private func handleError(_ error: Error) {
        isGenerating = false
        
        if let openAIError = error as? OpenAIError {
            switch openAIError {
            case .rateLimited(let waitTime):
                errorMessage = "Rate Limit erreicht. Versuchen Sie es in \(Int(waitTime)) Sekunden erneut."
            case .dailyLimitExceeded:
                errorMessage = "Tägliches Limit erreicht."
            case .noAPIKey:
                errorMessage = "Kein API Key konfiguriert."
            default:
                errorMessage = openAIError.localizedDescription
            }
        } else {
            errorMessage = "Unbekannter Fehler: \(error.localizedDescription)"
        }
    }
}

class ArticleGenerationViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var articleType: ArticleType = .general
    @Published var generatedArticle: String = ""
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    private let openAIClient: OpenAIClient
    
    init(openAIClient: OpenAIClient = OpenAIClient.shared) {
        self.openAIClient = openAIClient
    }
    
    func generateArticle() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isGenerating else { return }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await openAIClient.generateArticle(
                    content: inputText,
                    model: "gpt-4",
                    articleType: articleType
                )
                
                await MainActor.run {
                    if let choice = response.choices.first {
                        self.generatedArticle = choice.message?.content ?? "Keine Antwort erhalten"
                    }
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    func clearAll() {
        inputText = ""
        generatedArticle = ""
        errorMessage = nil
    }
    
    private func handleError(_ error: Error) {
        isGenerating = false
        
        if let openAIError = error as? OpenAIError {
            switch openAIError {
            case .rateLimited(let waitTime):
                errorMessage = "Rate Limit erreicht. Versuchen Sie es in \(Int(waitTime)) Sekunden erneut."
            case .dailyLimitExceeded:
                errorMessage = "Tägliches Limit erreicht."
            case .noAPIKey:
                errorMessage = "Kein API Key konfiguriert."
            default:
                errorMessage = openAIError.localizedDescription
            }
        } else {
            errorMessage = "Unbekannter Fehler: \(error.localizedDescription)"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let apiKeyChanged = Notification.Name("APIKeyChanged")
}

// MARK: - Usage Statistics View Model

class UsageStatisticsViewModel: ObservableObject {
    @Published var currentUsage: UsageTracker.DailyUsage?
    @Published var usageHistory: [UsageTracker.DailyUsage] = []
    @Published var isLoading: Bool = false
    
    private let openAIClient: OpenAIClient
    
    init(openAIClient: OpenAIClient = OpenAIClient.shared) {
        self.openAIClient = openAIClient
        loadUsageData()
    }
    
    func loadUsageData() {
        currentUsage = openAIClient.getCurrentUsage()
        usageHistory = openAIClient.getUsageHistory(days: 30)
    }
    
    func refreshData() {
        loadUsageData()
    }
    
    var totalCostThisMonth: Double {
        usageHistory.reduce(0.0) { $0 + $1.totalCost }
    }
    
    var totalRequestsThisMonth: Int {
        usageHistory.reduce(0) { $0 + $1.requestCount }
    }
    
    var totalTokensThisMonth: Int {
        usageHistory.reduce(0) { $0 + $1.totalTokens }
    }
    
    var averageDailyCost: Double {
        guard !usageHistory.isEmpty else { return 0 }
        return totalCostThisMonth / Double(usageHistory.count)
    }
}

// MARK: - API Key Management View Model

class APIKeyViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var hasAPIKey: Bool = false
    @Published var isValidating: Bool = false
    @Published var validationResult: String?
    @Published var errorMessage: String?
    
    private let openAIClient: OpenAIClient
    
    init(openAIClient: OpenAIClient = OpenAIClient.shared) {
        self.openAIClient = openAIClient
        checkAPIKeyStatus()
    }
    
    func checkAPIKeyStatus() {
        hasAPIKey = openAIClient.hasValidAPIKey()
        if hasAPIKey {
            validationResult = "API Key ist konfiguriert"
        } else {
            validationResult = nil
        }
    }
    
    func setAPIKey(_ key: String) {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Bitte geben Sie einen gültigen API Key ein."
            return
        }
        
        isValidating = true
        errorMessage = nil
        
        Task {
            do {
                try openAIClient.setAPIKey(key.trimmingCharacters(in: .whitespacesAndNewlines))
                
                await MainActor.run {
                    self.hasAPIKey = true
                    self.validationResult = "API Key erfolgreich gespeichert"
                    self.isValidating = false
                }
                
                NotificationCenter.default.post(name: .apiKeyChanged, object: nil)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Fehler beim Speichern des API Keys: \(error.localizedDescription)"
                    self.isValidating = false
                }
            }
        }
    }
    
    func removeAPIKey() {
        Task {
            do {
                try openAIClient.clearAPIKey()
                
                await MainActor.run {
                    self.hasAPIKey = false
                    self.apiKey = ""
                    self.validationResult = nil
                    self.errorMessage = nil
                }
                
                NotificationCenter.default.post(name: .apiKeyChanged, object: nil)
            } catch {
                await MainActor {
                    self.errorMessage = "Fehler beim Entfernen des API Keys: \(error.localizedDescription)"
                }
            }
        }
    }
}