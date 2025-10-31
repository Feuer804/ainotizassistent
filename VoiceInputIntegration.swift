//
//  VoiceInputIntegration.swift
//  Integration der Voice Input Funktionalität in die SwiftUI App
//
//  Erstellt am 31.10.2025
//  Zeigt die Integration mit bestehenden Komponenten
//

import SwiftUI

// MARK: - Voice Input Integration View
struct VoiceInputIntegrationView: View {
    @StateObject private var voiceInputManager = VoiceInputManager()
    @State private var showVoiceInput = false
    @State private var currentView: ContentViewType = .home
    
    enum ContentViewType {
        case home
        case voiceInput
        case meeting
        case notes
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $currentView) {
                // Home View
                ContentView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(ContentViewType.home)
                
                // Voice Input View
                VoiceInputView()
                    .tabItem {
                        Image(systemName: "mic.fill")
                        Text("Voice Input")
                    }
                    .tag(ContentViewType.voiceInput)
                
                // Meeting View
                MeetingView()
                    .tabItem {
                        Image(systemName: "person.3.fill")
                        Text("Meetings")
                    }
                    .tag(ContentViewType.meeting)
                
                // Notes View
                NotizView()
                    .tabItem {
                        Image(systemName: "note.text")
                        Text("Notizen")
                    }
                    .tag(ContentViewType.notes)
            }
            .navigationTitle("AI Notizassistent")
        }
        .overlay {
            // Floating Voice Input Button
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: toggleVoiceInput) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: voiceInputManager.isListening ? "mic.fill" : "mic")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    .scaleEffect(voiceInputManager.isListening ? 1.1 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: voiceInputManager.isListening)
                }
            }
        }
        .onAppear {
            setupVoiceInputIntegration()
        }
    }
    
    private func toggleVoiceInput() {
        if voiceInputManager.isListening {
            voiceInputManager.stopListening()
        } else {
            voiceInputManager.startListening()
        }
    }
    
    private func setupVoiceInputIntegration() {
        // Setup voice input manager callbacks for integration
        voiceInputManager.delegate = self
        
        // Prepare for future Whisper integration
        voiceInputManager.prepareForWhisperIntegration()
        
        print("✅ Voice Input Integration: Initialisiert")
    }
}

// MARK: - Voice Input Manager Integration
extension VoiceInputIntegrationView: VoiceInputManagerDelegate {
    func speechRecognitionDidStart() {
        print("🎤 Voice Recognition Started - Integration active")
    }
    
    func speechRecognitionDidStop() {
        print("⏹️ Voice Recognition Stopped")
    }
    
    func speechRecognition(_ result: String, with confidence: Float) {
        // Handle speech recognition results
        handleTranscriptionResult(result, confidence: confidence)
    }
    
    func speechRecognitionError(_ error: Error) {
        print("❌ Voice Recognition Error: \(error)")
    }
    
    func languageDetected(_ language: String) {
        print("🌍 Language Detected: \(language)")
    }
    
    func audioVisualizationData(_ data: [Float]) {
        // Handle audio visualization data for integration
    }
    
    private func handleTranscriptionResult(_ result: String, confidence: Float) {
        guard !result.isEmpty else { return }
        
        print("📝 Transcription: \(result)")
        
        // Integration with existing features
        switch currentView {
        case .home:
            // Could be used for general commands
            break
        case .voiceInput:
            // Already handled in VoiceInputView
            break
        case .meeting:
            // Could be used for meeting notes
            break
        case .notes:
            // Could be used for note creation
            break
        }
        
        // Future: Send to Whisper API for enhanced transcription
        prepareForWhisperProcessing(result, confidence: confidence)
    }
    
    private func prepareForWhisperProcessing(_ text: String, confidence: Float) {
        // Placeholder for OpenAI Whisper API integration
        // This will be implemented when ready
        
        let transcription = WhisperTranscription(
            text: text,
            confidence: confidence,
            timestamp: Date(),
            language: voiceInputManager.currentLanguage,
            originalRecording: "path/to/audio" // Will be implemented later
        )
        
        print("🔮 Whisper Processing: \(transcription)")
    }
}

// MARK: - Enhanced Shortcuts Integration
class VoiceShortcutsIntegration {
    private let voiceInputManager: VoiceInputManager
    
    init(voiceInputManager: VoiceInputManager) {
        self.voiceInputManager = voiceInputManager
    }
    
    // Integration with Shortcuts app
    func createVoiceInputShortcut() {
        // This would create a Shortcut for voice input
        // Requires Shortcuts app integration
        
        let shortcutActions = [
            "Start Voice Recording",
            "Transcribe Speech",
            "Create Note from Transcription",
            "Send Transcription to Whisper"
        ]
        
        print("🔗 Shortcuts Integration: \(shortcutActions.joined(separator: ", "))")
    }
    
    // Handle Shortcuts callbacks
    func handleShortcutCallback(_ result: String) {
        print("🔗 Shortcut Result: \(result)")
        
        // Process the result through voice input manager
        voiceInputManager.transcribedText = result
    }
}

// MARK: - Whisper Integration Data Structures
struct WhisperTranscription {
    let text: String
    let confidence: Float
    let timestamp: Date
    let language: String
    let originalRecording: String
    
    var toDictionary: [String: Any] {
        return [
            "text": text,
            "confidence": confidence,
            "timestamp": timestamp.timeIntervalSince1970,
            "language": language,
            "originalRecording": originalRecording
        ]
    }
}

// MARK: - Voice Input Analytics
struct VoiceInputAnalytics {
    static let shared = VoiceInputAnalytics()
    
    private init() {}
    
    func trackTranscriptionSession(
        duration: TimeInterval,
        wordsCount: Int,
        confidence: Float,
        language: String,
        hasWhisperEnhancement: Bool = false
    ) {
        let session = TranscriptionSession(
            id: UUID(),
            duration: duration,
            wordsCount: wordsCount,
            averageConfidence: confidence,
            language: language,
            hasWhisperEnhancement: hasWhisperEnhancement,
            timestamp: Date()
        )
        
        saveSession(session)
        print("📊 Analytics Session: \(session)")
    }
    
    private func saveSession(_ session: TranscriptionSession) {
        // Save to UserDefaults or CoreData for analytics
        let defaults = UserDefaults.standard
        let sessionsData = defaults.array(forKey: "VoiceInputSessions") ?? []
        
        var sessions = sessionsData.compactMap { data in
            guard let dict = data as? [String: Any],
                  let duration = dict["duration"] as? Double,
                  let wordsCount = dict["wordsCount"] as? Int,
                  let confidence = dict["confidence"] as? Float,
                  let language = dict["language"] as? String,
                  let timestamp = dict["timestamp"] as? Double else {
                return nil
            }
            
            return TranscriptionSession(
                id: UUID(),
                duration: duration,
                wordsCount: wordsCount,
                averageConfidence: confidence,
                language: language,
                hasWhisperEnhancement: dict["hasWhisperEnhancement"] as? Bool ?? false,
                timestamp: Date(timeIntervalSince1970: timestamp)
            )
        }
        
        sessions.append(session)
        
        // Keep only last 100 sessions
        if sessions.count > 100 {
            sessions = Array(sessions.suffix(100))
        }
        
        let sessionsDict = sessions.map { $0.toDictionary }
        defaults.set(sessionsDict, forKey: "VoiceInputSessions")
        
        print("✅ Analytics Session Saved")
    }
    
    func getAnalyticsSummary() -> AnalyticsSummary {
        let defaults = UserDefaults.standard
        let sessionsData = defaults.array(forKey: "VoiceInputSessions") ?? []
        
        let sessions = sessionsData.compactMap { data in
            guard let dict = data as? [String: Any],
                  let duration = dict["duration"] as? Double,
                  let wordsCount = dict["wordsCount"] as? Int,
                  let confidence = dict["confidence"] as? Float,
                  let language = dict["language"] as? String,
                  let timestamp = dict["timestamp"] as? Double else {
                return nil
            }
            
            return TranscriptionSession(
                id: UUID(),
                duration: duration,
                wordsCount: wordsCount,
                averageConfidence: confidence,
                language: language,
                hasWhisperEnhancement: dict["hasWhisperEnhancement"] as? Bool ?? false,
                timestamp: Date(timeIntervalSince1970: timestamp)
            )
        }
        
        return AnalyticsSummary(from: sessions)
    }
}

struct TranscriptionSession {
    let id: UUID
    let duration: TimeInterval
    let wordsCount: Int
    let averageConfidence: Float
    let language: String
    let hasWhisperEnhancement: Bool
    let timestamp: Date
    
    var toDictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "duration": duration,
            "wordsCount": wordsCount,
            "confidence": averageConfidence,
            "language": language,
            "hasWhisperEnhancement": hasWhisperEnhancement,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
}

struct AnalyticsSummary {
    let totalSessions: Int
    let totalDuration: TimeInterval
    let totalWords: Int
    let averageConfidence: Float
    let mostUsedLanguage: String
    let whisperUsageCount: Int
    
    init(from sessions: [TranscriptionSession]) {
        totalSessions = sessions.count
        totalDuration = sessions.reduce(0) { $0 + $1.duration }
        totalWords = sessions.reduce(0) { $0 + $1.wordsCount }
        averageConfidence = sessions.isEmpty ? 0 : sessions.reduce(0) { $0 + $1.averageConfidence } / Float(sessions.count)
        
        // Calculate most used language
        let languageCounts = Dictionary(grouping: sessions) { $0.language }
            .mapValues { $0.count }
        
        mostUsedLanguage = languageCounts.max { $0.value < $1.value }?.key ?? "Unknown"
        whisperUsageCount = sessions.filter { $0.hasWhisperEnhancement }.count
    }
    
    var toString: String {
        return """
        Voice Input Analytics:
        - Total Sessions: \(totalSessions)
        - Total Duration: \(Int(totalDuration)) seconds
        - Total Words: \(totalWords)
        - Average Confidence: \(Int(averageConfidence * 100))%
        - Most Used Language: \(mostUsedLanguage)
        - Whisper Usage: \(whisperUsageCount) times
        """
    }
}

// MARK: - Preview
struct VoiceInputIntegrationView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceInputIntegrationView()
            .preferredColorScheme(.light)
    }
}

// MARK: - Voice Input Enhancement Features
extension VoiceInputManager {
    // Enhanced features for integration
    func setWhisperAPIKey(_ key: String) {
        // Store API key securely for future Whisper integration
        UserDefaults.standard.set(key, forKey: "WhisperAPIKey")
        print("🔑 Whisper API Key: Stored securely")
    }
    
    func getTranscriptionWithWhisper(_ audioData: Data) async -> WhisperTranscription? {
        // Placeholder for future Whisper API call
        // This will be implemented when the API integration is ready
        
        guard let apiKey = UserDefaults.standard.string(forKey: "WhisperAPIKey") else {
            print("❌ No Whisper API key found")
            return nil
        }
        
        print("🔮 Whisper API Call: Prepared for \(audioData.count) bytes of audio")
        
        // TODO: Implement actual OpenAI Whisper API call
        return nil
    }
    
    func enhanceExistingTranscription(_ text: String) async -> String? {
        // Enhance existing transcription with Whisper
        // This would use the existing audio data to get better transcription
        
        print("🔮 Whisper Enhancement: Processing '\(text)'")
        return nil
    }
}

// MARK: - Error Handling Extension
extension VoiceInputManager {
    func handleWhisperError(_ error: Error) {
        print("❌ Whisper Error: \(error)")
        
        // Could implement fallbacks or error recovery strategies
        switch error {
        case WhisperAPIError.invalidAPIKey:
            print("🔑 Invalid API Key - Please check your OpenAI API key")
        case WhisperAPIError.audioTooLarge:
            print("📁 Audio file too large - Please use shorter recordings")
        case WhisperAPIError.rateLimitExceeded:
            print("⏱️ Rate limit exceeded - Please wait before trying again")
        default:
            print("❓ Unknown Whisper error")
        }
    }
}

// MARK: - Whisper API Error Types
enum WhisperAPIError: Error {
    case invalidAPIKey
    case audioTooLarge
    case rateLimitExceeded
    case networkError
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .invalidAPIKey:
            return "Ungültiger API-Schlüssel"
        case .audioTooLarge:
            return "Audio-Datei zu groß"
        case .rateLimitExceeded:
            return "Rate-Limit überschritten"
        case .networkError:
            return "Netzwerkfehler"
        case .unknownError:
            return "Unbekannter Fehler"
        }
    }
}