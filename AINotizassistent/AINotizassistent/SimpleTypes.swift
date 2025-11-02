//
//  SimpleTypes.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Haptic Manager
class HapticManager {
    func playTap() {
        // Simple haptic feedback simulation
        print("Haptic: tap")
    }
    
    func playSuccess() {
        // Simple success feedback simulation
        print("Haptic: success")
    }
}

// MARK: - Animation Manager
class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    let hapticManager = HapticManager()
    
    private init() {}
}

// MARK: - Micro Interaction Manager
class MicroInteractionManager: ObservableObject {
    private init() {}
}

// MARK: - Screen Transition Manager
class ScreenTransitionManager {
    private init() {}
}

// MARK: - Loading Animation Manager  
class LoadingAnimationManager: ObservableObject {
    private init() {}
}

// MARK: - Note Card View
struct NoteCardView: View {
    let note: Note
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.content)
                    .font(.body)
                    .lineLimit(2)
                Text("\(note.source) • \(note.formattedTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Einstellungen")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "mic")
                        .foregroundColor(.blue)
                    Text("Audio-Berechtigungen")
                    Spacer()
                    Text("✓")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.orange)
                    Text("Screen Capture")
                    Spacer()
                    Text("✓")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Image(systemName: "accessibility")
                        .foregroundColor(.purple)
                    Text("Accessibility")
                    Spacer()
                    Text("✓")
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

// MARK: - Animation Demo View
struct AnimationDemoView: View {
    @State private var isRotating = false
    @State private var scale: Double = 1.0
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Animation Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Circle()
                .fill(AngularGradient(
                    gradient: Gradient(colors: [.red, .blue, .purple, .red]),
                    center: .center
                ))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .scaleEffect(scale)
                .animation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: false),
                    value: isRotating
                )
                .onTapGesture {
                    isRotating.toggle()
                    scale = isRotating ? 1.2 : 1.0
                }
            
            Button("Animation starten/stoppen") {
                isRotating.toggle()
                scale = isRotating ? 1.2 : 1.0
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .frame(width: 300, height: 300)
    }
}

// MARK: - View Extensions for Animations
extension View {
    func withHoverEffect(scale: Double = 1.05) -> some View {
        self.onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                // Scale effect would go here in real implementation
            }
        }
    }
    
    func withSpringAnimation() -> some View {
        self.animation(.spring(response: 0.4, dampingFraction: 0.8), value: UUID())
    }
    
    func withButtonPressEffect(scale: Double = 0.95) -> some View {
        self.scaleEffect(scale)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    // Press effect would go here
                }
            }
    }
    
    func withEaseAnimation(type: AnimationType, duration: Double = 0.3) -> some View {
        self.animation(
            type == .easeInOut ? .easeInOut(duration: duration) : .easeIn(duration: duration),
            value: UUID()
        )
    }
    
    func withScreenTransition(style: TransitionStyle, isVisible: Bool) -> some View {
        self.opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
    
    func withLoadingOverlay(_ show: Bool) -> some View {
        ZStack {
            if show {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Verarbeitung...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }
            self
        }
    }
}

// MARK: - Animation Types
enum AnimationType {
    case easeIn, easeInOut
}

enum TransitionStyle {
    case slideUp, scale, fade
}

// MARK: - Animation Extensions
extension AnyTransition {
    static var slideUp: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
    
    static var fade: AnyTransition {
        .opacity
    }
}
