// SimpleTypes.swift
// Erstellt: 2025-11-02 19:30:00
// Ersetzt fehlende Typdefinitionen für AINotizassistent

import Foundation
import SwiftUI
import AVFoundation

// MARK: - Animation Management
class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    let hapticManager = HapticManager()
    
    private init() {}
    
    func playTap() {
        // Placeholder für Tap-Haptic-Feedback
        print("Haptic: Tap")
    }
    
    func playSuccess() {
        // Placeholder für Success-Haptic-Feedback  
        print("Haptic: Success")
    }
}

class HapticManager {
    func playTap() {
        // Placeholder für Tap-Haptic-Feedback
        print("Haptic: Tap")
    }
    
    func playSuccess() {
        // Placeholder für Success-Haptic-Feedback
        print("Haptic: Success")
    }
}

// MARK: - Micro Interactions
class MicroInteractionManager {
    init() {}
    
    func handleTap() {
        // Placeholder für Tap-Interaktion
        print("MicroInteraction: Tap")
    }
    
    func handleSwipe() {
        // Placeholder für Swipe-Interaktion
        print("MicroInteraction: Swipe")
    }
}

// MARK: - Screen Transitions
class ScreenTransitionManager {
    init() {}
    
    func navigateToMain() {
        // Placeholder für Navigation
        print("ScreenTransition: Navigate to Main")
    }
    
    func navigateToSettings() {
        // Placeholder für Settings-Navigation
        print("ScreenTransition: Navigate to Settings")
    }
}

// MARK: - Loading Animations
class LoadingAnimationManager: ObservableObject {
    @Published var isLoading: Bool = false
    
    init() {}
    
    func startLoading() {
        DispatchQueue.main.async {
            self.isLoading = true
        }
    }
    
    func stopLoading() {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}

// MARK: - Note Model and Views
struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var timestamp: Date
    
    init(id: UUID = UUID(), title: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.timestamp = timestamp
    }
}

struct NoteCardView: View {
    let note: Note
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.headline)
            Text(note.content)
                .font(.body)
            Text(note.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: onDelete) {
                Text("Löschen")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Einstellungen")
                .font(.largeTitle)
                .padding(.bottom)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Hinweise:")
                Text("• Wählen Sie Ihre bevorzugte KI-Anbieter")
                Text("• Passen Sie die Benachrichtigungseinstellungen an")
                Text("• Konfigurieren Sie die Speicheroptionen")
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Animation Demo View
struct AnimationDemoView: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack {
            Text("Animation Demo")
                .font(.title)
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 1.0), value: scale)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        scale = scale == 1.0 ? 1.2 : 1.0
                    }
                }
        }
        .padding()
    }
}

// MARK: - View Extensions
extension View {
    func hoverEffect() -> some View {
        self.hoverEffect()
    }
    
    func springAnimation() -> some View {
        self.animation(.spring(), value: UUID())
    }
    
    func buttonPress() -> some View {
        self.scaleEffect(0.95)
            .onTapGesture {
                // Button press logic
            }
    }
    
    func glowEffect() -> some View {
        self.shadow(color: Color.blue.opacity(0.3), radius: 10)
    }
}