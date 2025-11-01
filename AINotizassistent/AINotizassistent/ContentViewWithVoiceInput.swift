//
//  ContentViewWithVoiceInput.swift
//  Integration der Voice Input Funktionalität in die bestehende SwiftUI App
//
//  Erstellt am 31.10.2025
//  Erweitert die ContentView um Voice Input Features
//

import SwiftUI

struct ContentViewWithVoiceInput: View {
    @State private var selectedTab = 0
    @StateObject private var voiceInputManager = VoiceInputManager()
    @State private var showVoiceInputSheet = false
    @State private var floatingButtonScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Hintergrund mit Gradient (wie Original)
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.pink.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Hauptinhalt mit TabView
                TabView(selection: $selectedTab) {
                    NotizView()
                        .tabItem {
                            Image(systemName: "note.text")
                            Text("Notizen")
                        }
                        .tag(0)
                    
                    SummaryView()
                        .tabItem {
                            Image(systemName: "doc.text")
                            Text("Zusammenfassung")
                        }
                        .tag(1)
                    
                    TodoView()
                        .tabItem {
                            Image(systemName: "checklist")
                            Text("To-Do")
                        }
                        .tag(2)
                    
                    MeetingView()
                        .tabItem {
                            Image(systemName: "person.3")
                            Text("Meeting")
                        }
                        .tag(3)
                    
                    VoiceInputView()
                        .tabItem {
                            Image(systemName: "mic.fill")
                            Text("Voice Input")
                        }
                        .tag(4)
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text("Einstellungen")
                        }
                        .tag(5)
                }
                .tint(.white)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Glassmorphism Tab Bar (erweitert um Voice Input)
                VStack(spacing: 0) {
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    HStack {
                        TabBarButton(
                            icon: "note.text",
                            title: "Notizen",
                            isSelected: selectedTab == 0
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 0
                            }
                        }
                        
                        TabBarButton(
                            icon: "doc.text",
                            title: "Summary",
                            isSelected: selectedTab == 1
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 1
                            }
                        }
                        
                        TabBarButton(
                            icon: "checklist",
                            title: "To-Do",
                            isSelected: selectedTab == 2
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 2
                            }
                        }
                        
                        TabBarButton(
                            icon: "person.3",
                            title: "Meeting",
                            isSelected: selectedTab == 3
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 3
                            }
                        }
                        
                        TabBarButton(
                            icon: "mic.fill",
                            title: "Voice",
                            isSelected: selectedTab == 4
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 4
                            }
                        }
                        
                        TabBarButton(
                            icon: "gearshape",
                            title: "Settings",
                            isSelected: selectedTab == 5
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 5
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.bottom)
            }
            
            // Floating Voice Input Button (nur in ausgewählten Tabs)
            if [0, 2, 3].contains(selectedTab) {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // Voice Input Button
                        Button(action: toggleVoiceInputQuick) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: voiceInputManager.isListening ? [.red, .pink] : [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                    .scaleEffect(floatingButtonScale)
                                
                                Image(systemName: voiceInputManager.isListening ? "stop.fill" : "mic.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .rotationEffect(.degrees(voiceInputManager.isListening ? 180 : 0))
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100) // Above tab bar
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: voiceInputManager.isListening)
                        .onAppear {
                            pulseAnimation()
                        }
                    }
                }
            }
        }
        .onAppear {
            setupVoiceInputIntegration()
        }
        .onChange(of: selectedTab) { _, newValue in
            // Stop voice input when switching away from compatible tabs
            if ![0, 2, 3, 4].contains(newValue) && voiceInputManager.isListening {
                voiceInputManager.stopListening()
            }
        }
        .onChange(of: voiceInputManager.transcribedText) { _, newText in
            handleTranscriptionResult(newText)
        }
        .sheet(isPresented: $showVoiceInputSheet) {
            VoiceInputSheetView()
        }
    }
    
    private func toggleVoiceInputQuick() {
        if voiceInputManager.isListening {
            voiceInputManager.stopListening()
            floatingButtonScale = 1.0
        } else {
            voiceInputManager.startListening()
            floatingButtonScale = 0.9
        }
    }
    
    private func pulseAnimation() {
        if voiceInputManager.isListening {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                floatingButtonScale = 1.1
            }
        }
    }
    
    private func setupVoiceInputIntegration() {
        voiceInputManager.delegate = self
        voiceInputManager.prepareForWhisperIntegration()
    }
    
    private func handleTranscriptionResult(_ text: String) {
        guard !text.isEmpty else { return }
        
        print("🎤 Transcription Result: \(text)")
        
        // Handle different tabs
        switch selectedTab {
        case 0: // Notes
            handleNoteTranscription(text)
        case 2: // Todo
            handleTodoTranscription(text)
        case 3: // Meeting
            handleMeetingTranscription(text)
        default:
            break
        }
    }
    
    private func handleNoteTranscription(_ text: String) {
        // Send transcription to NotizView
        // This would require a shared view model or state management
        print("📝 Creating note from transcription: \(text)")
    }
    
    private func handleTodoTranscription(_ text: String) {
        // Send transcription to TodoView
        print("✅ Creating todo from transcription: \(text)")
    }
    
    private func handleMeetingTranscription(_ text: String) {
        // Send transcription to MeetingView
        print("🤝 Meeting transcription: \(text)")
    }
}

// MARK: - Voice Input Sheet View
struct VoiceInputSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var voiceInputManager = VoiceInputManager()
    
    var body: some View {
        NavigationView {
            VoiceInputView()
                .navigationTitle("Voice Input")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fertig") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Voice Input Status Banner
struct VoiceInputStatusBanner: View {
    let isListening: Bool
    let confidence: Float
    let language: String
    
    var body: some View {
        if isListening {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Voice Input Aktiv")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        Text("Genauigkeit: \(Int(confidence * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(language)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isListening ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isListening)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.red.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Extension for Voice Input Manager
extension ContentViewWithVoiceInput: VoiceInputManagerDelegate {
    func speechRecognitionDidStart() {
        print("🎤 Voice Recognition Started")
        floatingButtonScale = 0.9
    }
    
    func speechRecognitionDidStop() {
        print("⏹️ Voice Recognition Stopped")
        floatingButtonScale = 1.0
    }
    
    func speechRecognition(_ result: String, with confidence: Float) {
        print("✅ Transcription: \(result)")
        
        // Show feedback based on confidence
        if confidence > 0.8 {
            // High confidence - auto process
            handleTranscriptionResult(result)
        } else {
            // Lower confidence - show in status banner
            print("⚠️ Lower confidence: \(confidence)")
        }
    }
    
    func speechRecognitionError(_ error: Error) {
        print("❌ Voice Recognition Error: \(error)")
        // Handle error gracefully
        floatingButtonScale = 1.0
    }
    
    func languageDetected(_ language: String) {
        print("🌍 Language Detected: \(language)")
    }
    
    func audioVisualizationData(_ data: [Float]) {
        // Handle audio visualization if needed
    }
}

// MARK: - Voice Input Quick Actions
struct VoiceInputQuickActions: View {
    let voiceInputManager: VoiceInputManager
    let selectedTab: Int
    
    var body: some View {
        HStack(spacing: 12) {
            if voiceInputManager.isListening {
                Button(action: { voiceInputManager.stopListening() }) {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.white)
                        .padding()
                        .background(.red)
                        .clipShape(Circle())
                }
                
                Button(action: { /* Toggle language */ }) {
                    Image(systemName: "globe")
                        .foregroundStyle(.white)
                        .padding()
                        .background(.blue)
                        .clipShape(Circle())
                }
                
                Button(action: { /* Show transcription sheet */ }) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.white)
                        .padding()
                        .background(.green)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
struct ContentViewWithVoiceInput_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewWithVoiceInput()
            .preferredColorScheme(.dark)
    }
}