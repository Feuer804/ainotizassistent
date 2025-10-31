//
//  ContentView.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var isPresentingSettings = false
    @State private var isShowingDemo = false
    @State private var isAnimatingButtons = false
    @State private var currentTab = "main"
    @State private var showLoadingOverlay = false
    @State private var isListeningAnimated = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header mit Animation
            HStack {
                Image(systemName: "brain")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .withHoverEffect()
                    .withSpringAnimation()
                Text("AI Notizassistent")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .withSpringAnimation()
                Spacer()
            }
            .padding(.horizontal)
            
            // Status Anzeige mit Animation
            VStack(spacing: 10) {
                HStack {
                    Circle()
                        .fill(viewModel.isListening ? .green : .gray)
                        .frame(width: 12, height: 12)
                        .scaleEffect(viewModel.isListening ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: viewModel.isListening), value: viewModel.isListening)
                    Text(viewModel.isListening ? "Aktiv" : "Inaktiv")
                        .fontWeight(.medium)
                        .withSpringAnimation()
                    Spacer()
                }
                .withEaseAnimation(type: .easeInOut, duration: 0.3)
                
                if !viewModel.currentTranscript.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Letzte Transkription:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .withEaseAnimation(type: .easeIn, duration: 0.3)
                        Text(viewModel.currentTranscript)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .withHoverEffect()
                    }
                    .transition(.slideUp.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.currentTranscript)
                }
            }
            .padding()
            
            // Aktions-Buttons mit Micro-Interactions
            VStack(spacing: 12) {
                // Demo Button
                Button(action: {
                    isShowingDemo = true
                    AnimationManager.shared.hapticManager.playTap()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title2)
                        Text("Animation Demo")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple)
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .foregroundColor(.white)
                }
                .withButtonPressEffect(scale: 0.95)
                .withHoverEffect(scale: 1.02)
                .withSpringAnimation()
                Button(action: {
                    showLoadingOverlay = true
                    // Simulate AI processing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showLoadingOverlay = false
                        if viewModel.isListening {
                            viewModel.stopListening()
                        } else {
                            viewModel.startListening()
                        }
                    }
                    AnimationManager.shared.hapticManager.playTap()
                }) {
                    HStack {
                        Image(systemName: viewModel.isListening ? "stop.circle.fill" : "mic.circle")
                            .font(.title2)
                        Text(viewModel.isListening ? "Aufnahme stoppen" : "Aufnahme starten")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.isListening ? Color.red : Color.blue)
                            .shadow(color: viewModel.isListening ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .foregroundColor(.white)
                }
                .disabled(!viewModel.microphonePermissionGranted)
                .withButtonPressEffect(scale: 0.95)
                .withHoverEffect(scale: 1.02)
                .withSpringAnimation()
                .scaleEffect(showLoadingOverlay ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: showLoadingOverlay)
                
                Button(action: {
                    isPresentingSettings = true
                    AnimationManager.shared.hapticManager.playTap()
                }) {
                    HStack {
                        Image(systemName: "gearshape")
                            .font(.title2)
                        Text("Einstellungen")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.8))
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                    .foregroundColor(.white)
                }
                .withButtonPressEffect(scale: 0.95)
                .withHoverEffect(scale: 1.02)
                .withSpringAnimation()
            }
            .padding(.horizontal)
            
            // Notizen Liste mit Staggered Animations
            if !viewModel.notes.isEmpty {
                Divider()
                    .padding(.vertical)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notizen (\(viewModel.notes.count))")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .withSpringAnimation()
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(viewModel.notes.enumerated()), id: \.element.id) { index, note in
                                NoteCardView(note: note, onDelete: {
                                    viewModel.deleteNote(id: note.id)
                                    AnimationManager.shared.hapticManager.playSuccess()
                                })
                                .transition(.slideUp.combined(with: .opacity))
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.1),
                                    value: viewModel.notes.count
                                )
                                .withHoverEffect(scale: 1.02)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                .padding(.horizontal)
                .transition(.fade.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(width: 500, height: 600)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView()
                .withScreenTransition(style: .slideUp, isVisible: true)
        }
        .sheet(isPresented: $isShowingDemo) {
            AnimationDemoView()
                .withScreenTransition(style: .scale, isVisible: true)
        }
        .withLoadingOverlay(showLoadingOverlay)
        .onAppear {
            viewModel.checkPermissions()
            // Initial animation
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimatingButtons = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - ViewModel
class ContentViewModel: ObservableObject {
    @Published var isListening = false
    @Published var currentTranscript = ""
    @Published var notes: [Note] = []
    @Published var microphonePermissionGranted = false
    
    private let audioRecorder = AudioRecorder()
    
    init() {
        setupAudioRecorder()
    }
    
    private func setupAudioRecorder() {
        audioRecorder.delegate = self
    }
    
    func checkPermissions() {
        // Mikrofon Berechtigung prüfen
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        microphonePermissionGranted = status == .authorized
        
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    self.microphonePermissionGranted = granted
                }
            }
        }
    }
    
    func startListening() {
        audioRecorder.startRecording()
    }
    
    func stopListening() {
        audioRecorder.stopRecording()
    }
    
    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
    }
}

extension ContentViewModel: AudioRecorderDelegate {
    func audioRecorderDidStartRecording() {
        DispatchQueue.main.async {
            self.isListening = true
            self.currentTranscript = "Höre zu..."
        }
    }
    
    func audioRecorderDidStopRecording() {
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
    
    func audioRecorderDidReceiveTranscript(_ transcript: String) {
        DispatchQueue.main.async {
            self.currentTranscript = transcript
            
            // Automatisch eine Notiz erstellen
            let note = Note(
                content: transcript,
                timestamp: Date(),
                source: "Transkription"
            )
            self.notes.insert(note, at: 0)
            
            // Transkription nach kurzer Zeit leeren
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.currentTranscript == transcript {
                    self.currentTranscript = ""
                }
            }
        }
    }
}