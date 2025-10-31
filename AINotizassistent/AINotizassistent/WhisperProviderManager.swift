//
//  WhisperProviderManager.swift
//  AINotizassistent
//
//  Spezialisierter Manager für Whisper Speech-to-Text API
//

import Foundation
import Network
import AVFoundation

/// Spezialisierter Manager für Whisper Speech-to-Text API
class WhisperProviderManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isInitialized = false
    @Published var isTranscribing = false
    @Published var transcriptions: [WhisperTranscription] = []
    @Published var currentTranscription: WhisperTranscription?
    @Published var progress: Double = 0.0
    @Published var lastTranscription: WhisperTranscription?
    @Published var supportedLanguages: [String] = []
    @Published var usageStats: WhisperUsageStats?
    @Published var audioQuality: AudioQuality = .auto
    
    // MARK: - Whisper Configuration
    
    struct WhisperConfig {
        static let baseURL = "https://api.openai.com/v1"
        static let apiVersion = "2023-12-01-preview"
        static let timeoutInterval: TimeInterval = 300 // 5 minutes for large audio files
        static let maxFileSize: Int64 = 25 * 1024 * 1024 // 25MB
        static let supportedFormats = ["mp3", "mp4", "mpeg", "mpga", "wav", "webm", "m4a"]
    }
    
    private let requestQueue = DispatchQueue(label: "whisper.requests", qos: .userInitiated)
    private var uploadProgressObserver: Any?
    
    // MARK: - Audio Processing
    
    enum AudioFormat: String, CaseIterable {
        case mp3 = "mp3"
        case wav = "wav"
        case m4a = "m4a"
        case mp4 = "mp4"
        case aac = "aac"
        
        var mimeType: String {
            switch self {
            case .mp3: return "audio/mpeg"
            case .wav: return "audio/wav"
            case .m4a: return "audio/m4a"
            case .mp4: return "audio/mp4"
            case .aac: return "audio/aac"
            }
        }
        
        var fileExtension: String {
            return rawValue
        }
    }
    
    enum AudioQuality: String, CaseIterable {
        case auto = "auto"
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var bitRate: Int {
            switch self {
            case .auto: return 128
            case .low: return 64
            case .medium: return 128
            case .high: return 256
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupSupportedLanguages()
        loadCachedTranscriptions()
    }
    
    private func setupSupportedLanguages() {
        supportedLanguages = [
            "Auto", "English", "German", "Spanish", "French", "Italian", "Portuguese",
            "Dutch", "Russian", "Chinese", "Japanese", "Korean", "Arabic", "Hindi",
            "Turkish", "Swedish", "Norwegian", "Danish", "Finnish", "Polish"
        ]
    }
    
    // MARK: - API Key Management
    
    var isAPIKeyValid: Bool {
        guard let key = APIKeyManager.shared.getDecryptedKey(for: .whisper) else { return false }
        return key.hasPrefix("sk-")
    }
    
    var currentAPIKey: String? {
        return APIKeyManager.shared.getDecryptedKey(for: .whisper)
    }
    
    // MARK: - Audio Processing
    
    func processAudioFile(at url: URL) async throws -> Data {
        // Prüfe Dateigröße
        guard let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              fileSize <= WhisperConfig.maxFileSize else {
            throw WhisperError.fileTooLarge
        }
        
        // Lade Audiodatei
        let audioData = try Data(contentsOf: url)
        
        // Konvertiere zu unterstützten Format falls nötig
        if !WhisperConfig.supportedFormats.contains(url.pathExtension.lowercased()) {
            return try await convertAudio(to: .mp3, data: audioData)
        }
        
        return audioData
    }
    
    func recordAudio(duration: TimeInterval) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    guard granted else {
                        continuation.resume(throwing: WhisperError.microphonePermissionDenied)
                        return
                    }
                    
                    // Hier würde die Audio-Aufnahme implementiert werden
                    // Für jetzt ein Placeholder
                    continuation.resume(returning: Data())
                }
            }
        }
    }
    
    private func convertAudio(to format: AudioFormat, data: Data) async throws -> Data {
        // Audio-Konvertierung würde hier implementiert werden
        // Verwende AVAudioEngine und AVAudioFile für Konvertierung
        return data // Placeholder
    }
    
    // MARK: - Speech-to-Text Transcription
    
    func transcribeAudio(data: Data, language: String? = nil, responseFormat: WhisperResponseFormat = .verbose_json) async throws -> WhisperTranscription {
        guard isAPIKeyValid else {
            throw WhisperError.invalidAPIKey
        }
        
        guard !isTranscribing else {
            throw WhisperError.transcriptionInProgress
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                self.isTranscribing = true
                self.progress = 0.0
                
                var request = self.createTranscriptionRequest(audioData: data, language: language, responseFormat: responseFormat)
                
                let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
                    defer {
                        self.isTranscribing = false
                        self.progress = 0.0
                    }
                    
                    if let error = error {
                        continuation.resume(throwing: WhisperError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: WhisperError.noData)
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        
                        let transcription = try decoder.decode(WhisperTranscription.self, from: data)
                        
                        // Track usage
                        self.trackUsage(transcription: transcription)
                        
                        DispatchQueue.main.async {
                            self.transcriptions.insert(transcription, at: 0)
                            self.lastTranscription = transcription
                            self.saveTranscriptions()
                        }
                        
                        continuation.resume(returning: transcription)
                    } catch {
                        continuation.resume(throwing: WhisperError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
                
                // Progress tracking (vereinfacht)
                self.trackUploadProgress(task: task)
            }
        }
    }
    
    func transcribeFile(at url: URL, language: String? = nil) async throws -> WhisperTranscription {
        let audioData = try await processAudioFile(at: url)
        return try await transcribeAudio(data: audioData, language: language)
    }
    
    func transcribeURL(_ audioURL: String, language: String? = nil) async throws -> WhisperTranscription {
        guard let url = URL(string: audioURL) else {
            throw WhisperError.invalidURL
        }
        
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        let audioData = try Data(contentsOf: tempURL)
        try FileManager.default.removeItem(at: tempURL)
        
        return try await transcribeAudio(data: audioData, language: language)
    }
    
    // MARK: - Request Creation
    
    private func createTranscriptionRequest(audioData: Data, language: String?, responseFormat: WhisperResponseFormat) -> URLRequest {
        let url = URL(string: "\(WhisperConfig.baseURL)/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(currentAPIKey!)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = WhisperConfig.timeoutInterval
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(responseFormat.rawValue)\r\n".data(using: .utf8)!)
        
        // Temperature
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("0\r\n".data(using: .utf8)!)
        
        // Language (if specified)
        if let language = language, language != "Auto" {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        // Audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        return request
    }
    
    // MARK: - Progress Tracking
    
    private func trackUploadProgress(task: URLSessionUploadTask) {
        // Vereinfachte Progress-Implementierung
        // In einer echten App würde hier ein ProgressObserver verwendet
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isTranscribing else {
                timer.invalidate()
                return
            }
            
            // Simuliere Upload-Progress
            if self.progress < 0.7 {
                self.progress += 0.1
            } else if self.progress < 0.9 {
                self.progress += 0.05
            }
        }
    }
    
    // MARK: - Translation
    
    func translateAudio(data: Data, responseFormat: WhisperResponseFormat = .verbose_json) async throws -> WhisperTranscription {
        guard isAPIKeyValid else {
            throw WhisperError.invalidAPIKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async { [weak self] in
                guard let self = self else { return }
                
                var request = self.createTranslationRequest(audioData: data, responseFormat: responseFormat)
                
                let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: WhisperError.networkError(error.localizedDescription))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: WhisperError.noData)
                        return
                    }
                    
                    do {
                        let transcription = try JSONDecoder().decode(WhisperTranscription.self, from: data)
                        
                        var translated = transcription
                        translated.isTranslation = true
                        
                        DispatchQueue.main.async {
                            self.transcriptions.insert(translated, at: 0)
                            self.saveTranscriptions()
                        }
                        
                        continuation.resume(returning: translated)
                    } catch {
                        continuation.resume(throwing: WhisperError.decodingError(error.localizedDescription))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    private func createTranslationRequest(audioData: Data, responseFormat: WhisperResponseFormat) -> URLRequest {
        let url = URL(string: "\(WhisperConfig.baseURL)/audio/translations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(currentAPIKey!)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = WhisperConfig.timeoutInterval
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(responseFormat.rawValue)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("0\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        return request
    }
    
    // MARK: - Batch Processing
    
    func batchTranscribe(files: [URL], language: String? = nil) async throws -> [WhisperTranscription] {
        var results: [WhisperTranscription] = []
        
        for (index, url) in files.enumerated() {
            progress = Double(index) / Double(files.count)
            
            do {
                let transcription = try await transcribeFile(at: url, language: language)
                results.append(transcription)
            } catch {
                print("Failed to transcribe \(url.lastPathComponent): \(error)")
                // Continue with other files
            }
        }
        
        progress = 1.0
        return results
    }
    
    // MARK: - Usage Tracking
    
    private func trackUsage(transcription: WhisperTranscription) {
        let currentStats = usageStats ?? WhisperUsageStats()
        currentStats.totalTranscriptions += 1
        currentStats.totalDuration += transcription.duration ?? 0
        currentStats.totalWords += transcription.segments?.reduce(0) { $0 + ($1.text.components(separatedBy: " ").count) } ?? 0
        currentStats.lastTranscription = Date()
        
        usageStats = currentStats
        saveUsageStats()
        
        // Track in main API Key Manager
        APIKeyManager.shared.trackUsage(for: .whisper, tokensUsed: transcription.segments?.count ?? 0)
    }
    
    // MARK: - Data Persistence
    
    private func saveTranscriptions() {
        if let data = try? JSONEncoder().encode(transcriptions.prefix(100)) { // Limit to 100 recent transcriptions
            UserDefaults.standard.set(data, forKey: "whisper_transcriptions")
        }
    }
    
    private func loadCachedTranscriptions() {
        if let data = UserDefaults.standard.data(forKey: "whisper_transcriptions"),
           let cached = try? JSONDecoder().decode([WhisperTranscription].self, from: data) {
            transcriptions = cached
        }
        
        if let data = UserDefaults.standard.data(forKey: "whisper_usage_stats"),
           let cached = try? JSONDecoder().decode(WhisperUsageStats.self, from: data) {
            usageStats = cached
        }
    }
    
    private func saveUsageStats() {
        if let data = try? JSONEncoder().encode(usageStats ?? WhisperUsageStats()) {
            UserDefaults.standard.set(data, forKey: "whisper_usage_stats")
        }
    }
    
    // MARK: - Utilities
    
    func getTranscriptionDuration(_ transcription: WhisperTranscription) -> TimeInterval {
        return transcription.duration ?? 0
    }
    
    func getWordCount(_ transcription: WhisperTranscription) -> Int {
        return transcription.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    func exportTranscription(_ transcription: WhisperTranscription, format: ExportFormat) throws -> Data {
        switch format {
        case .txt:
            return transcription.text.data(using: .utf8) ?? Data()
        case .srt:
            return transcription.segments?.enumerated().compactMap { index, segment in
                let start = formatTime(segment.start)
                let end = formatTime(segment.end)
                return "\(index + 1)\n\(start) --> \(end)\n\(segment.text)\n"
            }.joined().data(using: .utf8) ?? Data()
        case .vtt:
            let segments = transcription.segments?.compactMap { segment in
                let start = formatVTTTime(segment.start)
                let end = formatVTTTime(segment.end)
                return "\(start) --> \(end)\n\(segment.text)\n"
            }.joined() ?? ""
            return "WEBVTT\n\n".data(using: .utf8)! + segments.data(using: .utf8) ?? Data()
        case .json:
            return try JSONEncoder().encode(transcription)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func formatVTTTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let seconds = seconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%02d:%06.3f", hours, minutes, seconds)
    }
    
    func clearTranscriptions() {
        transcriptions.removeAll()
        saveTranscriptions()
    }
}

// MARK: - Supporting Types

enum WhisperError: Error, LocalizedError {
    case invalidAPIKey
    case transcriptionInProgress
    case networkError(String)
    case decodingError(String)
    case noData
    case fileTooLarge
    case microphonePermissionDenied
    case invalidURL
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Whisper API Key ist ungültig oder nicht konfiguriert"
        case .transcriptionInProgress:
            return "Eine Transkription läuft bereits"
        case .networkError(let message):
            return "Netzwerkfehler: \(message)"
        case .decodingError(let message):
            return "Dekodierungsfehler: \(message)"
        case .noData:
            return "Keine Daten erhalten"
        case .fileTooLarge:
            return "Audiodatei ist zu groß (max. 25MB)"
        case .microphonePermissionDenied:
            return "Mikrofon-Zugriff verweigert"
        case .invalidURL:
            return "Ungültige Audio-URL"
        case .unsupportedFormat:
            return "Audio-Format wird nicht unterstützt"
        }
    }
}

enum WhisperResponseFormat: String, CaseIterable {
    case json = "json"
    case text = "text"
    case srt = "srt"
    case verbose_json = "verbose_json"
    case vtt = "vtt"
}

enum ExportFormat: String, CaseIterable {
    case txt = "txt"
    case srt = "srt"
    case vtt = "vtt"
    case json = "json"
}

struct WhisperUsageStats: Codable {
    var totalTranscriptions: Int = 0
    var totalDuration: TimeInterval = 0
    var totalWords: Int = 0
    var averageAccuracy: Double = 0.0
    var lastTranscription: Date?
    var dailyTranscriptions: [String: Int] = [:]
    var monthlyTranscriptions: Int = 0
}

// MARK: - Transcription Models

struct WhisperTranscription: Codable, Identifiable {
    let id = UUID()
    let text: String
    let language: String?
    let duration: Double?
    let segments: [WhisperSegment]?
    let created_at: Date
    var isTranslation: Bool = false
    
    var wordCount: Int {
        return text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    var readingTime: TimeInterval {
        return Double(wordCount) / 200 * 60 // Assuming 200 words per minute
    }
}

struct WhisperSegment: Codable {
    let id: Int
    let seek: Int
    let start: Double
    let end: Double
    let text: String
    let tokens: [Int]
    let temperature: Double
    let avg_logprob: Double
    let compression_ratio: Double
    let no_speech_prob: Double
}

// MARK: - Data Extensions

extension Array where Element == UInt8 {
    var data: Data {
        return Data(self)
    }
}

extension Data {
    mutating func append(_ string: String) {
        append(string.data(using: .utf8)!)
    }
}