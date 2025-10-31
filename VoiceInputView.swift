//
//  VoiceInputView.swift
//  SwiftUI Voice Input Interface mit Glass-Effekten
//
//  Erstellt am 31.10.2025
//  Integriert mit VoiceInputManager für Real-time Speech Recognition
//

import SwiftUI
import AVFoundation

// MARK: - Voice Input View Model
class VoiceInputViewModel: ObservableObject {
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var transcribedText = ""
    @Published var currentLanguage = "en-US"
    @Published var confidence: Float = 0.0
    @Published var noiseLevel: Float = 0.0
    @Published var audioVisualizationData: [Float] = []
    @Published var voiceActivityDetected = false
    @Published var microphonePermissionsGranted = false
    @Published var speechRecognitionPermissionsGranted = false
    @Published var isPrivacyModeEnabled = false
    @Published var detectedLanguage: String?
    
    private let voiceInputManager = VoiceInputManager()
    
    init() {
        setupVoiceInputManager()
    }
    
    private func setupVoiceInputManager() {
        voiceInputManager.delegate = self
        
        // Bind to voice input manager properties
        voiceInputManager.$isListening
            .receive(on: DispatchQueue.main)
            .assign(to: \.isListening, on: self)
            .store(in: &CancellableSet())
        
        voiceInputManager.$isProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isProcessing, on: self)
            .store(in: &CancellableSet())
        
        voiceInputManager.$transcribedText
            .receive(on: DispatchQueue.main)
            .assign(to: \.transcribedText, on: self)
            .store(in: &CancellableSet())
        
        voiceInputManager.$currentLanguage
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentLanguage, on: self)
            .store(in: &CancellableSet())
        
        voiceInputManager.$confidence
            .receive(on: DispatchQueue.main)
            .assign(to: \.confidence, on: self)
            .store(in: &CancellableSet())
        
        voiceInputManager.$microphonePermissionsGranted
            .receive(on: DispatchQueue.main)
            .assign(to: \.microphonePermissionsGranted, on: self)
            .store(in: &CancellableSet())
        
        voiceInputManager.$speechRecognitionPermissionsGranted
            .receive(on: DispatchQueue.main)
            .assign(to: \.speechRecognitionPermissionsGranted, on: self)
            .store(to: &CancellableSet())
        
        isPrivacyModeEnabled = VoiceInputPrivacy.shared.isPrivacyModeEnabled()
    }
    
    func startListening() {
        voiceInputManager.startListening()
    }
    
    func stopListening() {
        voiceInputManager.stopListening()
    }
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    func setLanguage(_ languageCode: String) {
        voiceInputManager.setLanguage(languageCode)
    }
    
    func togglePrivacyMode() {
        isPrivacyModeEnabled.toggle()
        VoiceInputPrivacy.shared.enablePrivacyMode(isPrivacyModeEnabled)
    }
    
    func clearText() {
        transcribedText = ""
    }
    
    func getSupportedLanguages() -> [String: String] {
        return voiceInputManager.getSupportedLanguages()
    }
    
    func getConfidenceColor() -> Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        case 0.4..<0.6:
            return .orange
        default:
            return .red
        }
    }
    
    func getLanguageName() -> String {
        let languages = getSupportedLanguages()
        return languages[currentLanguage] ?? "Unbekannt"
    }
}

// MARK: - Cancellable Set for Combine
class CancellableSet {
    private var cancellables: Set<AnyCancellable> = []
    
    func store(in cancellables: inout Set<AnyCancellable>) {
        cancellables.formUnion(self.cancellables)
    }
    
    func cancel() {
        cancellables.removeAll()
    }
}

// MARK: - Voice Input View
struct VoiceInputView: View {
    @StateObject private var viewModel = VoiceInputViewModel()
    @State private var showLanguagePicker = false
    @State private var showPrivacySettings = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background mit Glass Effect
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Header
                        headerView
                        
                        // Permissions Status
                        permissionsView
                        
                        // Audio Visualization
                        audioVisualizationView
                        
                        // Main Voice Input Area
                        voiceInputAreaView
                        
                        // Transcription Display
                        transcriptionView
                        
                        // Confidence and Language Info
                        infoBarView
                        
                        // Action Buttons
                        actionButtonsView
                        
                        // Quick Actions
                        quickActionsView
                        
                        // Privacy Controls
                        privacyView
                        
                        Spacer()
                            .frame(height: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 30)
                }
            }
        }
        .navigationTitle("🎤 Voice Input")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Sprache ändern") { showLanguagePicker = true }
                    Button("Privacy Einstellungen") { showPrivacySettings = true }
                    Button("Einstellungen") { showSettings = true }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showLanguagePicker) {
            languagePickerView
        }
        .sheet(isPresented: $showPrivacySettings) {
            privacySettingsView
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Voice Input Manager")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            Text("Real-time Speech Recognition mit VAD & Noise Cancellation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var permissionsView: some View {
        HStack(spacing: 16) {
            PermissionIndicator(
                icon: "mic.fill",
                title: "Mikrofon",
                granted: viewModel.microphonePermissionsGranted
            )
            
            PermissionIndicator(
                icon: "waveform.circle.fill",
                title: "Speech Recognition",
                granted: viewModel.speechRecognitionPermissionsGranted
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var audioVisualizationView: some View {
        VStack(spacing: 12) {
            Text("Audio Visualization")
                .font(.headline)
                .foregroundStyle(.primary)
            
            AudioWaveformView(data: viewModel.audioVisualizationData, isRecording: viewModel.isListening)
                .frame(height: 60)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        }
    }
    
    private var voiceInputAreaView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: viewModel.isListening ? [.red, .pink] : [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                
                Image(systemName: viewModel.isListening ? "mic.fill" : "mic.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .scaleEffect(viewModel.isListening ? 1.1 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.isListening)
            }
            
            Text(viewModel.isListening ? "Aufnahme läuft..." : "Drücke zum Sprechen")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            // Noise Level Indicator
            if viewModel.isListening {
                HStack {
                    Text("Rauschlevel:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: viewModel.noiseLevel, total: 0.1)
                        .tint(viewModel.noiseLevel > 0.05 ? .red : .green)
                        .scaleEffect(y: 0.8)
                }
            }
        }
    }
    
    private var transcriptionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transkription")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if !viewModel.transcribedText.isEmpty {
                    Button {
                        viewModel.clearText()
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            
            ScrollView {
                Text(viewModel.transcribedText.isEmpty ? "Warte auf Spracheingabe..." : viewModel.transcribedText)
                    .font(.body)
                    .foregroundStyle(viewModel.transcribedText.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .animation(.easeInOut, value: viewModel.transcribedText)
            }
            .frame(minHeight: 100, maxHeight: 200)
        }
    }
    
    private var infoBarView: some View {
        HStack(spacing: 20) {
            // Confidence Indicator
            VStack(spacing: 4) {
                Text("Genauigkeit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Circle()
                        .fill(viewModel.getConfidenceColor())
                        .frame(width: 8, height: 8)
                    
                    Text("\(Int(viewModel.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
            }
            
            Spacer()
            
            // Language Indicator
            VStack(spacing: 4) {
                Text("Sprache")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "globe")
                        .font(.caption)
                    
                    Text(viewModel.getLanguageName())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
            }
            
            Spacer()
            
            // Voice Activity
            if viewModel.isListening {
                VStack(spacing: 4) {
                    Text("Stimme")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(viewModel.voiceActivityDetected ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(viewModel.voiceActivityDetected ? "Aktiv" : "Pause")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // Start/Stop Button
            Button(action: viewModel.toggleListening) {
                HStack {
                    Image(systemName: viewModel.isListening ? "stop.fill" : "mic.fill")
                    Text(viewModel.isListening ? "Stoppen" : "Aufnehmen")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: viewModel.isListening ? [.red, .pink] : [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            
            // Quick Actions
            Menu {
                Button("Text kopieren") {
                    UIPasteboard.general.string = viewModel.transcribedText
                }
                
                Button("Audio wiedergeben") {
                    // Audio playback implementation
                }
                
                Button("Whisper Integration vorbereiten") {
                    // Placeholder for future Whisper integration
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            }
        }
    }
    
    private var quickActionsView: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                QuickActionButton(
                    icon: "play.fill",
                    title: "Demo",
                    action: {
                        // Demo functionality
                    }
                )
                
                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "Neu starten",
                    action: {
                        viewModel.stopListening()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.startListening()
                        }
                    }
                )
                
                QuickActionButton(
                    icon: "waveform",
                    title: "Analytics",
                    action: {
                        // Show voice input statistics
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var privacyView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Privacy Mode")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Lokale Verarbeitung aktiviert")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $viewModel.isPrivacyModeEnabled)
                .onChange(of: viewModel.isPrivacyModeEnabled) { _, newValue in
                    viewModel.togglePrivacyMode()
                }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var languagePickerView: some View {
        NavigationView {
            List(Array(viewModel.getSupportedLanguages().keys), id: \.self) { languageCode in
                Button {
                    viewModel.setLanguage(languageCode)
                    showLanguagePicker = false
                } label: {
                    HStack {
                        Text(viewModel.getSupportedLanguages()[languageCode] ?? "")
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if languageCode == viewModel.currentLanguage {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Sprache wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        showLanguagePicker = false
                    }
                }
            }
        }
    }
    
    private var privacySettingsView: some View {
        NavigationView {
            List {
                Section("Privacy Einstellungen") {
                    Toggle("Privacy Mode", isOn: $viewModel.isPrivacyModeEnabled)
                        .onChange(of: viewModel.isPrivacyModeEnabled) { _, newValue in
                            viewModel.togglePrivacyMode()
                        }
                    
                    Button("Verlauf löschen") {
                        VoiceInputPrivacy.shared.clearRecordingHistory()
                    }
                    
                    Button("Privacy Report anzeigen") {
                        // Show privacy report
                    }
                }
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        showPrivacySettings = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PermissionIndicator: View {
    let icon: String
    let title: String
    let granted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(granted ? .green : .red)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
}

struct AudioWaveformView: View {
    let data: [Float]
    let isRecording: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                
                // Waveform
                if isRecording && !data.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(0..<data.count, id: \.self) { index in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(
                                    width: geometry.size.width / CGFloat(data.count * 2),
                                    height: CGFloat(data[safe: index] ?? 0) * 200
                                )
                                .cornerRadius(2)
                        }
                    }
                    .padding(.horizontal, 10)
                } else {
                    Text("Keine Audio-Daten")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.primary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - Extension for Safe Array Access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Voice Input Manager Delegate
extension VoiceInputViewModel: VoiceInputManagerDelegate {
    func speechRecognitionDidStart() {
        print("✅ Speech Recognition Started")
    }
    
    func speechRecognitionDidStop() {
        print("⏹️ Speech Recognition Stopped")
    }
    
    func speechRecognition(_ result: String, with confidence: Float) {
        print("✅ Speech Recognition Result: \(result)")
    }
    
    func speechRecognitionError(_ error: Error) {
        print("❌ Speech Recognition Error: \(error)")
    }
    
    func languageDetected(_ language: String) {
        detectedLanguage = language
        print("🌍 Language Detected: \(language)")
    }
    
    func audioVisualizationData(_ data: [Float]) {
        audioVisualizationData = data
    }
}

// MARK: - Preview
struct VoiceInputView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceInputView()
    }
}