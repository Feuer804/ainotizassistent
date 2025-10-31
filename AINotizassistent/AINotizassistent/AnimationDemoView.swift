//
//  AnimationDemoView.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI
import AppKit

struct AnimationDemoView: View {
    @State private var currentDemo = 0
    @State private var showDemo = false
    @State private var progress: CGFloat = 0
    @State private var isLoading = false
    @State private var selectedTab = 0
    @State private var rippleCenter = CGPoint(x: 100, y: 100)
    
    private let demoTitles = [
        "Spring Animationen",
        "Micro-Interactions",
        "Tab-Transitions",
        "Loading-Animationen",
        "Haptic Feedback",
        "Parallax Scrolling",
        "Custom Animationen"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Animation Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .withSpringAnimation()
                Spacer()
            }
            .padding(.horizontal)
            
            // Demo Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<demoTitles.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentDemo = index
                            }
                        }) {
                            Text(demoTitles[index])
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(currentDemo == index ? Color.blue : Color.gray.opacity(0.2))
                                )
                                .foregroundColor(currentDemo == index ? .white : .primary)
                                .scaleEffect(currentDemo == index ? 1.05 : 1.0)
                        }
                        .withButtonPressEffect()
                        .withHoverEffect()
                    }
                }
                .padding(.horizontal)
            }
            
            // Demo Content
            TabView(selection: $currentDemo) {
                SpringAnimationDemo()
                    .tag(0)
                    .padding()
                
                MicroInteractionDemo()
                    .tag(1)
                    .padding()
                
                TabTransitionDemo()
                    .tag(2)
                    .padding()
                
                LoadingAnimationDemo()
                    .tag(3)
                    .padding()
                
                HapticFeedbackDemo()
                    .tag(4)
                    .padding()
                
                ParallaxScrollDemo()
                    .tag(5)
                    .padding()
                
                CustomAnimationDemo()
                    .tag(6)
                    .padding()
            }
            .tabViewStyle(.page)
            .animation(.easeInOut(duration: 0.5), value: currentDemo)
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.controlBackgroundColor))
        .withLoadingOverlay(isLoading)
    }
}

// MARK: - Spring Animation Demo
struct SpringAnimationDemo: View {
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Spring Animationen")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                // Scale Spring
                Button("Scale Spring") {
                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                        scale = scale == 1.0 ? 1.5 : 1.0
                    }
                }
                .frame(width: 100, height: 100)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
                .scaleEffect(scale)
                .withButtonPressEffect()
                
                // Rotation Spring
                Button("Rotation Spring") {
                    withAnimation(.interpolatingSpring(stiffness: 200, damping: 15)) {
                        rotation += 90
                    }
                }
                .frame(width: 100, height: 100)
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(Circle())
                .rotationEffect(.degrees(rotation))
                .withButtonPressEffect()
                
                // Offset Spring
                Button("Offset Spring") {
                    withAnimation(.interpolatingSpring(stiffness: 250, damping: 18)) {
                        offset = offset == .zero ? CGSize(width: 50, height: -50) : .zero
                    }
                }
                .frame(width: 100, height: 100)
                .background(Color.orange)
                .foregroundColor(.white)
                .clipShape(Circle())
                .offset(offset)
                .withButtonPressEffect()
            }
            
            // Multiple Spring Elements
            HStack(spacing: 15) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 40, height: 40)
                        .scaleEffect(scale)
                        .animation(
                            .interpolatingSpring(stiffness: 180, damping: 12).delay(Double(index) * 0.1),
                            value: scale
                        )
                }
            }
        }
    }
}

// MARK: - Micro Interaction Demo
struct MicroInteractionDemo: View {
    @State private var isToggled = false
    @State private var hoveredButton = -1
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Micro-Interactions")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                // Hover Effect Demo
                HStack(spacing: 15) {
                    ForEach(0..<3) { index in
                        Button("Button \(index + 1)") {
                            AnimationManager.shared.hapticManager.playTap()
                        }
                        .frame(width: 100, height: 40)
                        .background(hoveredButton == index ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onHover { hovering in
                            hoveredButton = hovering ? index : -1
                        }
                        .scaleEffect(hoveredButton == index ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: hoveredButton)
                    }
                }
                
                // Toggle Demo
                HStack {
                    Text("Toggle Demo:")
                    Spacer()
                    Toggle("", isOn: $isToggled)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .scaleEffect(isToggled ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isToggled)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Button Press Demo
                Button("Drücke mich!") {
                    AnimationManager.shared.hapticManager.playSuccess()
                }
                .frame(width: 150, height: 50)
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .withButtonPressEffect(scale: 0.9)
            }
        }
    }
}

// MARK: - Tab Transition Demo
struct TabTransitionDemo: View {
    @State private var selectedTab = 0
    @State private var transitionStyle: TransitionStyle = .slideLeft
    
    private let tabs = ["Home", "Profile", "Settings", "About"]
    private let transitions: [(String, TransitionStyle)] = [
        ("Slide Left", .slideLeft),
        ("Slide Right", .slideRight),
        ("Slide Up", .slideUp),
        ("Fade", .fade),
        ("Scale", .scale),
        ("Bounce", .bounce)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tab-Transitions")
                .font(.title)
                .fontWeight(.bold)
            
            // Tab Selector
            HStack(spacing: 10) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(tabs[index]) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            selectedTab = index
                        }
                        AnimationManager.shared.hapticManager.playTap()
                    }
                    .frame(height: 35)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 17.5)
                            .fill(selectedTab == index ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(selectedTab == index ? .white : .primary)
                    .withTabTransition(isSelected: selectedTab == index)
                }
            }
            
            // Transition Style Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(transitions, id: \.0) { name, style in
                        Button(name) {
                            // Just for demo, not changing actual transition
                            AnimationManager.shared.hapticManager.playTap()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .withButtonPressEffect()
                    }
                }
                .padding(.horizontal)
            }
            
            // Tab Content
            ZStack {
                ForEach(0..<tabs.count, id: \.self) { index in
                    if index == selectedTab {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                VStack {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.blue)
                                    Text("Tab Content: \(tabs[index])")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
            }
            .frame(height: 200)
            .withSpringAnimation()
        }
    }
}

// MARK: - Loading Animation Demo
struct LoadingAnimationDemo: View {
    @State private var isLoading = false
    @State private var progress: CGFloat = 0
    @State private var loadingType: LoadingAnimationType = .spinner
    
    private let loadingTypes: [(String, LoadingAnimationType)] = [
        ("Spinner", .spinner),
        ("Dots", .dots),
        ("Pulse", .pulse),
        ("Wave", .wave),
        ("Bars", .bars),
        ("Orbit", .orbit)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Loading-Animationen")
                .font(.title)
                .fontWeight(.bold)
            
            if isLoading {
                LoadingAnimationManager.shared.createSmartLoadingAnimation(
                    type: loadingType,
                    message: "Lade..."
                )
                .transition(.scale.combined(with: .opacity))
                
                if loadingType == .progressBar {
                    LoadingAnimationManager.shared.createProgressBar(
                        progress: progress,
                        color: .blue,
                        height: 8
                    )
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button("Abbrechen") {
                    stopLoading()
                }
                .foregroundColor(.red)
                .withButtonPressEffect()
            } else {
                // Loading Type Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(loadingTypes, id: \.0) { name, type in
                            Button(name) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    loadingType = type
                                }
                                AnimationManager.shared.hapticManager.playTap()
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(loadingType == type ? Color.blue : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(loadingType == type ? .white : .primary)
                            .withTabTransition(isSelected: loadingType == type)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button("Start Loading") {
                    startLoading()
                }
                .frame(width: 150, height: 50)
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .withButtonPressEffect()
            }
        }
    }
    
    private func startLoading() {
        isLoading = true
        progress = 0
        
        if loadingType == .progressBar {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                progress += 0.02
                if progress >= 1.0 {
                    timer.invalidate()
                    stopLoading()
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                stopLoading()
            }
        }
    }
    
    private func stopLoading() {
        withAnimation(.easeOut(duration: 0.3)) {
            isLoading = false
        }
    }
}

// MARK: - Haptic Feedback Demo
struct HapticFeedbackDemo: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Haptic Feedback")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                Button("Tap Feedback") {
                    AnimationManager.shared.hapticManager.playTap()
                }
                .frame(width: 150, height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .withButtonPressEffect()
                
                Button("Success Feedback") {
                    AnimationManager.shared.hapticManager.playSuccess()
                }
                .frame(width: 150, height: 50)
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .withButtonPressEffect()
                
                Button("Error Feedback") {
                    AnimationManager.shared.hapticManager.playNotification(type: .error)
                }
                .frame(width: 150, height: 50)
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .withButtonPressEffect()
                
                Button("Warning Feedback") {
                    AnimationManager.shared.hapticManager.playNotification(type: .warning)
                }
                .frame(width: 150, height: 50)
                .background(Color.orange)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .withButtonPressEffect()
            }
            
            Text("Verschiedene Haptic-Feedbacks für verschiedene Interaktionstypen")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top)
        }
    }
}

// MARK: - Parallax Scroll Demo
struct ParallaxScrollDemo: View {
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Parallax Scrolling")
                .font(.title)
                .fontWeight(.bold)
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<10) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 100)
                            .overlay(
                                Text("Element \(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            )
                            .offset(y: scrollOffset * 0.3)
                            .scaleEffect(1 + abs(scrollOffset) * 0.0005)
                    }
                }
                .padding()
            }
            .frame(height: 250)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            Text("Scroll nach unten für Parallax-Effekt")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Custom Animation Demo
struct CustomAnimationDemo: View {
    @State private var animationPhase = 0
    @State private var showCustomAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Custom Animationen")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                // Bounce Animation
                Button("Bounce Animation") {
                    withAnimation(.interpolatingSpring(stiffness: 400, damping: 10)) {
                        // This creates a bounce effect
                    }
                }
                .frame(width: 150, height: 50)
                .background(Color.pink)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .withButtonPressEffect()
                
                // Elastic Animation
                Button("Elastic Animation") {
                    withAnimation(.interpolatingSpring(stiffness: 200, damping: 8)) {
                        animationPhase += 1
                    }
                }
                .frame(width: 150, height: 50)
                .background(Color.teal)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .withButtonPressEffect()
                .scaleEffect(CGFloat(1.0 + Double(animationPhase % 2) * 0.1))
                
                // Wave Animation
                Button("Wave Effect") {
                    showCustomAnimation.toggle()
                }
                .frame(width: 150, height: 50)
                .background(Color.indigo)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .withButtonPressEffect()
                
                if showCustomAnimation {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Rectangle()
                                .fill(Color.indigo)
                                .frame(width: 6, height: 30)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                        .delay(Double(index) * 0.1)
                                        .repeatForever(autoreverses: true),
                                    value: showCustomAnimation
                                )
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            Text("Experimentelle und benutzerdefinierte Animationseffekte")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct AnimationDemoView_Previews: PreviewProvider {
    static var previews: some View {
        AnimationDemoView()
    }
}