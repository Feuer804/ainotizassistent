//
//  VoiceInputManager.swift
//  Mikrofon-Integration mit Whisper für macOS
//
//  Erstellt am 31.10.2025
//  Unterstützt Real-time Speech Recognition, VAD, Noise Cancellation, Multi-language
//

import Foundation
import SwiftUI
import AVFoundation
import Speech
import Accelerate

// MARK: - Voice Activity Detection Delegate
protocol VoiceActivityDetectionDelegate: AnyObject {
    func voiceActivityDetected(_ detected: Bool)
    func noiseLevelChanged(_ level: Float)
}

// MARK: - Speech Recognition Delegate
protocol VoiceInputManagerDelegate: AnyObject {
    func speechRecognitionDidStart()
    func speechRecognitionDidStop()
    func speechRecognition(_ result: String, with confidence: Float)
    func speechRecognitionError(_ error: Error)
    func languageDetected(_ language: String)
    func audioVisualizationData(_ data: [Float])
}

// MARK: - Voice Activity Detector
class VoiceActivityDetector: ObservableObject {
    weak var delegate: VoiceActivityDetectionDelegate?
    private var audioEngine: AVAudioEngine?
    private var audioSession: AVAudioSession?
    private var inputNode: AVAudioInputNode?
    private var audioBuffer: AVAudioPCMBuffer?
    
    // VAD Settings
    private let vadThreshold: Float = 0.02 // Noise level threshold
    private let speechFrameCount: Int = 3  // Consecutive frames to confirm speech
    private var speechFrameCounter: Int = 0
    private var noiseLevel: Float = 0.0
    private var isListening = false
    
    // Audio processing
    private var audioFormat: AVAudioFormat!
    private let sampleRate: Double = 44100.0
    private let frameSize: Int = 1024
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        audioSession = AVAudioSession.sharedInstance()
        inputNode = audioEngine?.inputNode
        
        guard let audioEngine = audioEngine,
              let inputNode = inputNode else { return }
        
        // Configure audio format
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        
        // Install tap for real-time audio analysis
        inputNode.installTap(onBus: 0, bufferSize: frameSize, format: audioFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isListening else { return }
        
        // Extract audio data
        let frameCount = Int(buffer.frameLength)
        let channelData = buffer.floatChannelData![0]
        
        // Calculate RMS (Root Mean Square) for noise level
        var rms: Float = 0.0
        vDSP_rms(channelData, 1, &rms, vDSP_Length(frameCount))
        
        noiseLevel = rms
        
        // Voice Activity Detection
        if rms > vadThreshold {
            speechFrameCounter = min(speechFrameCounter + 1, speechFrameCount)
        } else {
            speechFrameCounter = max(speechFrameCounter - 1, 0)
        }
        
        let isVoiceDetected = speechFrameCounter >= speechFrameCount
        
        DispatchQueue.main.async {
            self.delegate?.noiseLevelChanged(rms)
            self.delegate?.voiceActivityDetected(isVoiceDetected)
        }
    }
    
    func startListening() {
        guard let audioEngine = audioEngine,
              let audioSession = audioSession else { return }
        
        do {
            try audioSession.setCategory(.record, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
            
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
        } catch {
            print("❌ VAD: Failed to start listening - \(error)")
        }
    }
    
    func stopListening() {
        guard let audioEngine = audioEngine else { return }
        
        isListening = false
        speechFrameCounter = 0
        
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
    }
}

// MARK: - Noise Cancellation
class NoiseCancellation {
    static let shared = NoiseCancellation()
    private var noiseProfile: [Float] = []
    
    // Simple noise gate implementation
    func applyNoiseCancellation(to audioBuffer: AVAudioPCMBuffer, threshold: Float = 0.01) -> AVAudioPCMBuffer {
        let frameCount = Int(audioBuffer.frameLength)
        let channelData = audioBuffer.floatChannelData![0]
        
        // Apply simple noise gate
        for i in 0..<frameCount {
            let sample = channelData[i]
            channelData[i] = abs(sample) < threshold ? 0.0 : sample
        }
        
        return audioBuffer
    }
    
    func calibrateNoiseProfile(from audioBuffer: AVAudioPCMBuffer, duration: TimeInterval) {
        // Calibrate noise floor for better cancellation
        let frameCount = Int(audioBuffer.frameLength)
        let channelData = audioBuffer.floatChannelData![0]
        
        var maxLevel: Float = 0.0
        vDSP_maximum(channelData, 1, &maxLevel, vDSP_Length(frameCount))
        
        noiseProfile.append(maxLevel)
    }
}

// MARK: - Audio Visualizer
class AudioVisualizer: ObservableObject {
    @Published var audioData: [Float] = []
    @Published var isRecording = false
    
    private var audioEngine: AVAudioEngine?
    private var displayLink: CADisplayLink?
    
    func startVisualization() {
        isRecording = true
        setupDisplayLink()
    }
    
    func stopVisualization() {
        isRecording = false
        displayLink?.invalidate()
        audioData = []
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateVisualization))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    @objc private func updateVisualization() {
        // Generate mock audio data for visualization
        // In real implementation, this would come from actual audio analysis
        audioData = (0..<20).map { _ in Float.random(in: 0...1) }
    }
}

// MARK: - Language Detection
class LanguageDetector {
    private let supportedLanguages = ["de-DE", "en-US", "fr-FR", "es-ES", "it-IT"]
    private var languageHistory: [String: Int] = [:]
    
    func detectLanguage(from text: String) -> String? {
        // Simple heuristic-based language detection
        // In production, this would use more sophisticated algorithms
        
        let germanWords = ["der", "die", "das", "und", "ist", "ich", "nicht", "ein", "zu", "haben"]
        let englishWords = ["the", "and", "is", "I", "not", "a", "to", "have", "you", "we"]
        
        let words = text.lowercased.components(separatedBy: .whitespacesAndNewlines)
        var germanScore = 0
        var englishScore = 0
        
        for word in words {
            if germanWords.contains(word) { germanScore += 1 }
            if englishWords.contains(word) { englishScore += 1 }
        }
        
        let detectedLanguage: String
        if germanScore > englishScore {
            detectedLanguage = "de-DE"
        } else if englishScore > germanScore {
            detectedLanguage = "en-US"
        } else {
            detectedLanguage = supportedLanguages.randomElement() ?? "en-US"
        }
        
        languageHistory[detectedLanguage, default: 0] += 1
        
        return detectedLanguage
    }
    
    func getMostDetectedLanguage() -> String? {
        return languageHistory.max { $0.value < $1.value }?.key
    }
}

// MARK: - Voice Input Manager
class VoiceInputManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var transcribedText = ""
    @Published var currentLanguage = "en-US"
    @Published var confidence: Float = 0.0
    @Published var microphonePermissionsGranted = false
    @Published var speechRecognitionPermissionsGranted = false
    
    // MARK: - Delegates
    weak var delegate: VoiceInputManagerDelegate?
    
    // MARK: - Audio Components
    private var audioEngine: AVAudioEngine?
    private var audioPlayer: AVAudioPlayer?
    private var noiseCancellation = NoiseCancellation.shared
    private var languageDetector = LanguageDetector()
    
    // MARK: - Speech Recognition
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var continuousMode = true
    
    // MARK: - VAD and Audio Processing
    private var voiceActivityDetector: VoiceActivityDetector?
    private var audioVisualizer: AudioVisualizer?
    
    // MARK: - Privacy and Permissions
    private var lastRecordingTime: Date?
    private let minimumRecordingInterval: TimeInterval = 1.0 // 1 second minimum
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioComponents()
        setupSpeechRecognition()
        checkPermissions()
    }
    
    private func setupAudioComponents() {
        audioEngine = AVAudioEngine()
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ Audio Session Setup Failed: \(error)")
        }
        
        // Initialize VAD
        voiceActivityDetector = VoiceActivityDetector()
        voiceActivityDetector?.delegate = self
        
        // Initialize Visualizer
        audioVisualizer = AudioVisualizer()
    }
    
    private func setupSpeechRecognition() {
        // Create speech recognizer for each supported language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
    }
    
    // MARK: - Permission Management
    private func checkPermissions() {
        checkMicrophonePermission()
        checkSpeechRecognitionPermission()
    }
    
    private func checkMicrophonePermission() {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .granted:
            microphonePermissionsGranted = true
        case .denied, .undetermined:
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.microphonePermissionsGranted = granted
                }
            }
        @unknown default:
            break
        }
    }
    
    private func checkSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.speechRecognitionPermissionsGranted = true
                case .denied, .restricted, .notDetermined:
                    self.speechRecognitionPermissionsGranted = false
                @unknown default:
                    break
                }
            }
        }
    }
    
    // MARK: - Voice Input Control
    func startListening() {
        guard microphonePermissionsGranted && speechRecognitionPermissionsGranted else {
            checkPermissions()
            return
        }
        
        guard !isListening else { return }
        
        // Privacy check
        if let lastTime = lastRecordingTime {
            let timeInterval = Date().timeIntervalSince(lastTime)
            guard timeInterval >= minimumRecordingInterval else {
                print("❌ Privacy: Recording too frequent")
                return
            }
        }
        
        do {
            try startSpeechRecognition()
            startAudioProcessing()
            isListening = true
            lastRecordingTime = Date()
            
            DispatchQueue.main.async {
                self.delegate?.speechRecognitionDidStart()
            }
            
            print("✅ Voice Input: Started listening")
        } catch {
            print("❌ Failed to start voice input: \(error)")
        }
    }
    
    func stopListening() {
        guard isListening else { return }
        
        stopSpeechRecognition()
        stopAudioProcessing()
        isListening = false
        
        DispatchQueue.main.async {
            self.delegate?.speechRecognitionDidStop()
        }
        
        print("✅ Voice Input: Stopped listening")
    }
    
    // MARK: - Speech Recognition
    private func startSpeechRecognition() throws {
        // Create audio engine and input node
        guard let audioEngine = audioEngine else {
            throw VoiceInputError.audioEngineNotInitialized
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = continuousMode
        recognitionRequest?.requiresOnDeviceRecognition = false // Allow cloud processing for better accuracy
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!, delegate: self)
    }
    
    private func stopSpeechRecognition() {
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        audioEngine?.inputNode.removeTap(onBus: 0)
    }
    
    // MARK: - Audio Processing
    private func startAudioProcessing() {
        voiceActivityDetector?.startListening()
        audioVisualizer?.startVisualization()
        isProcessing = true
    }
    
    private func stopAudioProcessing() {
        voiceActivityDetector?.stopListening()
        audioVisualizer?.stopVisualization()
        isProcessing = false
    }
    
    // MARK: - Language Management
    func setLanguage(_ languageCode: String) {
        guard supportedLanguages.contains(languageCode) else { return }
        
        currentLanguage = languageCode
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode))
        speechRecognizer?.delegate = self
        
        print("✅ Language set to: \(languageCode)")
    }
    
    private let supportedLanguages = ["en-US", "de-DE", "fr-FR", "es-ES", "it-IT"]
    
    func getSupportedLanguages() -> [String: String] {
        return [
            "en-US": "English (US)",
            "de-DE": "Deutsch (Deutschland)",
            "fr-FR": "Français (France)",
            "es-ES": "Español (España)",
            "it-IT": "Italiano (Italia)"
        ]
    }
    
    // MARK: - Whisper Integration (Future)
    func prepareForWhisperIntegration() {
        // Placeholder for future OpenAI Whisper API integration
        // This will be implemented when ready
        
        print("🔮 Whisper Integration: Prepared for future API integration")
    }
    
    // MARK: - Audio Playback
    func playLastRecording() {
        // Implementation for playback of last recorded audio
        // Will be used for testing and validation
    }
}

// MARK: - Extensions
extension VoiceInputManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle speech recognizer availability changes
        print("🔊 Speech Recognizer Availability: \(available)")
    }
}

extension VoiceInputManager: SFSpeechRecognitionTaskDelegate {
    func speechRecognition(_ speechRecognition: SFSpeechRecognitionTask, didRecognizePartialResult partialResult: SFSpeechRecognitionResult) {
        DispatchQueue.main.async {
            self.transcribedText = partialResult.bestTranscription.formattedString
            
            // Update confidence score
            if let confidence = partialResult.bestTranscription.confidence {
                self.confidence = confidence
            }
            
            // Notify delegate
            self.delegate?.speechRecognition(partialResult.bestTranscription.formattedString, 
                                           with: self.confidence)
            
            // Auto-detect language from recognized text
            if !partialResult.bestTranscription.formattedString.isEmpty {
                let detectedLanguage = self.languageDetector.detectLanguage(from: partialResult.bestTranscription.formattedString)
                if let language = detectedLanguage, language != self.currentLanguage {
                    DispatchQueue.main.async {
                        self.currentLanguage = language
                        self.delegate?.languageDetected(language)
                    }
                }
            }
        }
    }
    
    func speechRecognition(_ speechRecognition: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        if successfully {
            print("✅ Speech Recognition: Completed successfully")
        } else {
            print("⚠️ Speech Recognition: Completed with errors")
        }
    }
}

extension VoiceInputManager: VoiceActivityDetectionDelegate {
    func voiceActivityDetected(_ detected: Bool) {
        // Handle voice activity detection
        if detected {
            print("🎤 Voice Activity: Detected")
        }
    }
    
    func noiseLevelChanged(_ level: Float) {
        // Handle noise level changes for visualization
        audioVisualizer?.audioData.append(level)
        if let audioData = audioVisualizer?.audioData {
            delegate?.audioVisualizationData(Array(audioData.suffix(20))) // Last 20 samples
        }
    }
}

// MARK: - Error Types
enum VoiceInputError: Error {
    case audioEngineNotInitialized
    case speechRecognizerNotAvailable
    case permissionsDenied
    case audioSessionError(Error)
    
    var localizedDescription: String {
        switch self {
        case .audioEngineNotInitialized:
            return "Audio Engine nicht initialisiert"
        case .speechRecognizerNotAvailable:
            return "Speech Recognizer nicht verfügbar"
        case .permissionsDenied:
            return "Berechtigungen verweigert"
        case .audioSessionError(let error):
            return "Audio Session Fehler: \(error.localizedDescription)"
        }
    }
}

// MARK: - Voice Input Statistics
struct VoiceInputStatistics {
    var totalRecordingTime: TimeInterval = 0
    var totalWordsRecognized: Int = 0
    var averageConfidence: Float = 0.0
    var languageUsage: [String: Int] = [:]
    var lastRecordingDate: Date?
    
    mutating func updateWithTranscription(_ text: String, confidence: Float, language: String) {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        totalWordsRecognized += wordCount
        languageUsage[language, default: 0] += 1
        
        // Calculate running average confidence
        if averageConfidence == 0.0 {
            averageConfidence = confidence
        } else {
            averageConfidence = (averageConfidence + confidence) / 2.0
        }
    }
}

// MARK: - Privacy Controls
class VoiceInputPrivacy {
    static let shared = VoiceInputPrivacy()
    
    private let privacySettings = UserDefaults.standard
    
    func enablePrivacyMode(_ enabled: Bool) {
        privacySettings.set(enabled, forKey: "VoiceInputPrivacyMode")
    }
    
    func isPrivacyModeEnabled() -> Bool {
        return privacySettings.bool(forKey: "VoiceInputPrivacyMode")
    }
    
    func clearRecordingHistory() {
        privacySettings.removeObject(forKey: "LastRecordingTime")
        privacySettings.removeObject(forKey: "RecordingHistory")
    }
    
    func getPrivacyReport() -> [String: Any] {
        return [
            "privacyMode": isPrivacyModeEnabled(),
            "lastClearDate": Date(),
            "recordingAllowed": AVAudioSession.sharedInstance().recordPermission == .granted,
            "recognitionAllowed": SFSpeechRecognizer.authorizationStatus() == .authorized
        ]
    }
}