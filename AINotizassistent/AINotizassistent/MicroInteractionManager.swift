//
//  MicroInteractionManager.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI
import AppKit
import Combine

// MARK: - Interaction Types
enum InteractionType {
    case hover
    case tap
    case longPress
    case drag
    case swipe
    case textInput
    case buttonPress
    case toggle
    case scroll
}

// MARK: - Interaction State
struct InteractionState {
    var isHovered = false
    var isPressed = false
    var isFocused = false
    var isDragging = false
    var dragOffset: CGSize = .zero
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    var rotation: Double = 0.0
    var shadowRadius: CGFloat = 0.0
}

// MARK: - Button Animation Config
struct ButtonAnimationConfig {
    let pressScale: CGFloat
    let pressDuration: TimeInterval
    let releaseDuration: TimeInterval
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    
    static let standard = ButtonAnimationConfig(
        pressScale: 0.95,
        pressDuration: 0.1,
        releaseDuration: 0.2,
        shadowOpacity: 0.3,
        shadowRadius: 4
    )
    
    static let subtle = ButtonAnimationConfig(
        pressScale: 0.98,
        pressDuration: 0.05,
        releaseDuration: 0.15,
        shadowOpacity: 0.1,
        shadowRadius: 2
    )
    
    static let dramatic = ButtonAnimationConfig(
        pressScale: 0.9,
        pressDuration: 0.15,
        releaseDuration: 0.3,
        shadowOpacity: 0.5,
        shadowRadius: 8
    )
}

// MARK: - MicroInteraction Manager
class MicroInteractionManager: ObservableObject {
    @Published var states: [String: InteractionState] = [:]
    private var animations: [String: AnyCancellable] = [:]
    
    // MARK: - Button Interactions
    @ViewBuilder
    func createAnimatedButton<Content: View>(
        id: String,
        _ content: Content,
        config: ButtonAnimationConfig = .standard,
        action: @escaping () -> Void
    ) -> some View {
        let state = getState(for: id)
        
        content
            .scaleEffect(state.scale)
            .opacity(state.opacity)
            .shadow(
                color: Color.black.opacity(state.shadowOpacity),
                radius: state.shadowRadius,
                x: 0,
                y: state.isPressed ? 2 : 1
            )
            .offset(y: state.isPressed ? 1 : 0)
            .onTapGesture {
                handleButtonPress(id: id, config: config)
                action()
            }
            .onLongPressGesture(minimumDuration: 0.1) {
                // Long press handling if needed
            }
    }
    
    private func handleButtonPress(id: String, config: ButtonAnimationConfig) {
        // Press animation
        withAnimation(.easeInOut(duration: config.pressDuration)) {
            updateState(id: id) { state in
                state.isPressed = true
                state.scale = config.pressScale
                state.shadowOpacity = config.shadowOpacity
                state.shadowRadius = config.shadowRadius
            }
        }
        
        // Release animation
        DispatchQueue.main.asyncAfter(deadline: .now() + config.pressDuration) {
            withAnimation(.easeOut(duration: config.releaseDuration)) {
                self.updateState(id: id) { state in
                    state.isPressed = false
                    state.scale = 1.0
                    state.shadowOpacity = 0.0
                    state.shadowRadius = 0.0
                }
            }
        }
        
        // Haptic feedback
        AnimationManager.shared.hapticManager.playTap()
    }
    
    // MARK: - Hover Interactions
    @ViewBuilder
    func createHoverableElement<Content: View>(
        id: String,
        hoverScale: CGFloat = 1.05,
        hoverOpacity: Double = 0.8,
        _ content: Content
    ) -> some View {
        let state = getState(for: id)
        
        content
            .scaleEffect(state.isHovered ? hoverScale : 1.0)
            .opacity(state.isHovered ? hoverOpacity : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    updateState(id: id) { state in
                        state.isHovered = hovering
                    }
                }
            }
    }
    
    // MARK: - Text Input Interactions
    @ViewBuilder
    func createAnimatedTextField<Content: View>(
        id: String,
        isFocused: Bool,
        focusColor: Color = .blue,
        _ content: Content
    ) -> some View {
        let state = getState(for: id)
        let borderOpacity = isFocused ? 1.0 : 0.3
        let borderWidth: CGFloat = isFocused ? 2.0 : 1.0
        
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(focusColor.opacity(borderOpacity), lineWidth: borderWidth)
            )
            .scaleEffect(state.isFocused ? 1.02 : 1.0)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    updateState(id: id) { state in
                        state.isFocused = true
                    }
                }
            }
    }
    
    // MARK: - Drag Interactions
    @ViewBuilder
    func createDraggableElement<Content: View>(
        id: String,
        _ content: Content,
        onDrag: @escaping (CGPoint) -> Void
    ) -> some View {
        let state = getState(for: id)
        
        content
            .offset(state.dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            updateState(id: id) { state in
                                state.isDragging = true
                                state.dragOffset = value.translation
                                state.scale = 0.95
                            }
                        }
                        onDrag(value.location)
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                            updateState(id: id) { state in
                                state.isDragging = false
                                state.dragOffset = .zero
                                state.scale = 1.0
                            }
                        }
                    }
            )
    }
    
    // MARK: - Toggle Interactions
    @ViewBuilder
    func createAnimatedToggle<Content: View>(
        id: String,
        isOn: Bool,
        thumbColor: Color = .white,
        trackColor: Color = .gray,
        _ content: Content
    ) -> some View {
        let state = getState(for: id)
        let thumbOffset = isOn ? 20 : 0
        
        content
            .overlay(
                RoundedRectangle(coreRadius: 15)
                    .fill(trackColor)
                    .frame(width: 50, height: 30)
            )
            .overlay(
                Circle()
                    .fill(thumbColor)
                    .frame(width: 26, height: 26)
                    .offset(x: CGFloat(thumbOffset))
            )
            .onTapGesture {
                // Toggle handling would be done externally
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                    AnimationManager.shared.hapticManager.playTap()
                }
            }
    }
    
    // MARK: - Scroll Interactions
    @ViewBuilder
    func createParallaxScroll<Content: View>(
        id: String,
        offset: CGFloat,
        magnitude: CGFloat = 0.5,
        _ content: Content
    ) -> some View {
        content
            .offset(y: offset * magnitude)
            .scaleEffect(1 + (abs(offset) * 0.001))
    }
    
    // MARK: - Ripple Effect
    @ViewBuilder
    func createRippleEffect<Content: View>(
        id: String,
        center: CGPoint,
        color: Color = Color.blue.opacity(0.3),
        _ content: Content
    ) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Circle()
                        .fill(color)
                        .scaleEffect(0)
                        .position(center)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.6)) {
                                // Ripple animation would be triggered here
                            }
                        }
                }
            )
    }
    
    // MARK: - Pulse Effect
    @ViewBuilder
    func createPulseEffect<Content: View>(
        id: String,
        scale: CGFloat = 1.1,
        duration: TimeInterval = 1.0,
        _ content: Content
    ) -> some View {
        let state = getState(for: id)
        
        content
            .scaleEffect(state.isPressed ? scale : 1.0)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: UUID())
    }
    
    // MARK: - Shake Animation
    func shakeView(id: String, intensity: CGFloat = 10) {
        updateState(id: id) { state in
            state.rotation = -Double(intensity)
        }
        
        withAnimation(.easeInOut(duration: 0.1)) {
            updateState(id: id) { state in
                state.rotation = Double(intensity)
            }
        }
        
        withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
            updateState(id: id) { state in
                state.rotation = -Double(intensity / 2)
            }
        }
        
        withAnimation(.easeInOut(duration: 0.1).delay(0.2)) {
            updateState(id: id) { state in
                state.rotation = Double(intensity / 2)
            }
        }
        
        withAnimation(.easeOut(duration: 0.1).delay(0.3)) {
            updateState(id: id) { state in
                state.rotation = 0.0
            }
        }
    }
    
    // MARK: - Success Animation
    func playSuccessAnimation(id: String) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            updateState(id: id) { state in
                state.scale = 1.2
                state.opacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.updateState(id: id) { state in
                    state.scale = 1.0
                    state.opacity = 1.0
                }
            }
        }
        
        // Success haptic
        AnimationManager.shared.hapticManager.playSuccess()
    }
    
    // MARK: - Error Animation
    func playErrorAnimation(id: String) {
        withAnimation(.easeInOut(duration: 0.1)) {
            updateState(id: id) { state in
                state.scale = 0.95
                state.rotation = -5
            }
        }
        
        withAnimation(.easeOut(duration: 0.2)) {
            updateState(id: id) { state in
                state.scale = 1.0
                state.rotation = 0
            }
        }
        
        // Error haptic
        AnimationManager.shared.hapticManager.playNotification(type: .error)
    }
    
    // MARK: - State Management
    private func getState(for id: String) -> InteractionState {
        return states[id] ?? InteractionState()
    }
    
    private func updateState(id: String, _ update: (inout InteractionState) -> Void) {
        var state = states[id] ?? InteractionState()
        update(&state)
        states[id] = state
        objectWillChange.send()
    }
    
    // MARK: - Cleanup
    func resetState(id: String) {
        states[id] = InteractionState()
        animations[id]?.cancel()
        animations[id] = nil
    }
    
    func cleanupAll() {
        states.removeAll()
        animations.values.forEach { $0.cancel() }
        animations.removeAll()
    }
}

// MARK: - View Extensions for MicroInteractions
extension View {
    func withMicroInteraction(id: String, interactionType: InteractionType) -> some View {
        let manager = MicroInteractionManager.shared
        
        switch interactionType {
        case .hover:
            return AnyView(manager.createHoverableElement(id: id) { self })
        case .buttonPress:
            return AnyView(manager.createAnimatedButton(id: id) { self } action: {})
        case .textInput:
            return AnyView(manager.createAnimatedTextField(id: id, isFocused: false) { self })
        case .drag:
            return AnyView(manager.createDraggableElement(id: id) { _ in })
        default:
            return AnyView(self)
        }
    }
    
    func withRippleEffect(center: CGPoint, color: Color = .blue.opacity(0.3)) -> some View {
        let manager = MicroInteractionManager.shared
        return AnyView(manager.createRippleEffect(id: UUID().uuidString, center: center, color: color) { self })
    }
    
    func withPulseEffect(scale: CGFloat = 1.1, duration: TimeInterval = 1.0) -> some View {
        let manager = MicroInteractionManager.shared
        return AnyView(manager.createPulseEffect(id: UUID().uuidString, scale: scale, duration: duration) { self })
    }
    
    func withShakeAnimation(intensity: CGFloat = 10) -> some View {
        let manager = MicroInteractionManager.shared
        manager.shakeView(id: UUID().uuidString, intensity: intensity)
        return self
    }
    
    func withSuccessAnimation() -> some View {
        let manager = MicroInteractionManager.shared
        manager.playSuccessAnimation(id: UUID().uuidString)
        return self
    }
    
    func withErrorAnimation() -> some View {
        let manager = MicroInteractionManager.shared
        manager.playErrorAnimation(id: UUID().uuidString)
        return self
    }
}

// MARK: - Gesture Manager
class GestureManager: ObservableObject {
    @Published var activeGestures: [String: Any] = [:]
    
    func addTapGesture(to view: some View, action: @escaping () -> Void) -> some View {
        return view.onTapGesture(count: 1) {
            AnimationManager.shared.hapticManager.playTap()
            action()
        }
    }
    
    func addLongPressGesture(to view: some View, action: @escaping () -> Void) -> some View {
        return view.onLongPressGesture(minimumDuration: 0.5) {
            AnimationManager.shared.hapticManager.playTap()
            action()
        }
    }
    
    func addDoubleTapGesture(to view: some View, action: @escaping () -> Void) -> some View {
        return view.onTapGesture(count: 2) {
            AnimationManager.shared.hapticManager.playSuccess()
            action()
        }
    }
}