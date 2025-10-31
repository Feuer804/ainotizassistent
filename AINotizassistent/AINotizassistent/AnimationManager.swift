//
//  AnimationManager.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI
import AppKit
import CoreAnimation
import CoreHaptics
import Combine

// MARK: - Animation Types
enum AnimationType {
    case spring
    case easeInOut
    case easeIn
    case easeOut
    case bounce
    case elastic
    case fade
    case slide
    case scale
    case rotate
}

// MARK: - Spring Configuration
struct SpringAnimationConfig {
    let stiffness: CGFloat
    let damping: CGFloat
    let mass: CGFloat
    
    static let gentle = SpringAnimationConfig(stiffness: 180, damping: 12, mass: 1)
    static let bouncy = SpringAnimationConfig(stiffness: 300, damping: 20, mass: 1.2)
    static let responsive = SpringAnimationConfig(stiffness: 250, damping: 25, mass: 1)
    static let slow = SpringAnimationConfig(stiffness: 120, damping: 8, mass: 1.5)
    static let snappy = SpringAnimationConfig(stiffness: 400, damping: 30, mass: 0.8)
}

// MARK: - Haptic Manager
class HapticManager: NSObject, ObservableObject {
    private var hapticEngine: CHHapticEngine?
    private var supportsHaptics = false
    
    override init() {
        super.init()
        setupHapticEngine()
    }
    
    private func setupHapticEngine() {
        do {
            hapticEngine = try CHHapticEngine()
            supportsHaptics = true
            try hapticEngine?.start()
        } catch {
            print("Haptic engine setup failed: \(error)")
            supportsHaptics = false
        }
    }
    
    func playSuccess() {
        guard supportsHaptics else { return }
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play success haptic: \(error)")
        }
    }
    
    func playTap() {
        guard supportsHaptics else { return }
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play tap haptic: \(error)")
        }
    }
    
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard supportsHaptics else { return }
        
        let intensity: Float
        let sharpness: Float
        
        switch type {
        case .success:
            intensity = 0.8
            sharpness = 0.2
        case .warning:
            intensity = 0.6
            sharpness = 0.7
        case .error:
            intensity = 1.0
            sharpness = 0.8
        @unknown default:
            intensity = 0.5
            sharpness = 0.5
        }
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play notification haptic: \(error)")
        }
    }
}

// MARK: - Tween Manager
class TweenManager: ObservableObject {
    @Published var progress: CGFloat = 0
    
    private var animationLayers: [CALayer] = []
    private var displayLink: CADisplayLink?
    
    func tween(from: CGFloat, to: CGFloat, duration: TimeInterval, easing: @escaping (CGFloat) -> CGFloat, completion: @escaping (CGFloat) -> Void) {
        let startTime = Date().timeIntervalSince1970
        let endTime = startTime + duration
        
        stopTweening()
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateTween))
        displayLink?.add(to: .main, forMode: .default)
        
        func updateTween() {
            let now = Date().timeIntervalSince1970
            let elapsed = now - startTime
            let total = endTime - startTime
            
            if elapsed >= total {
                progress = to
                completion(to)
                stopTweening()
                return
            }
            
            let normalizedProgress = CGFloat(elapsed / total)
            let easedProgress = easing(normalizedProgress)
            let currentValue = from + (to - from) * easedProgress
            
            progress = currentValue
            completion(currentValue)
        }
        
        displayLink?.add(to: .main, forMode: .default)
    }
    
    @objc private func updateTween() {
        // Implementierung des Tween-Updates
    }
    
    private func stopTweening() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // Easing Functions
    static func easeInOut(progress: CGFloat) -> CGFloat {
        return progress < 0.5 ? 2 * progress * progress : -1 + (4 - 2 * progress) * progress
    }
    
    static func easeOutBounce(progress: CGFloat) -> CGFloat {
        if progress < 4/11 {
            return (121 * progress * progress) / 16
        } else if progress < 8/11 {
            return (363/40.0 * progress * progress) - (99/10.0 * progress) + 17/5.0
        } else if progress < 9/10 {
            return (4356/361.0 * progress * progress) - (35442/1805.0 * progress) + 16061/1805.0
        } else {
            return (54/5.0 * progress * progress) - (513/25.0 * progress) + 268/25.0
        }
    }
    
    static func easeOutElastic(progress: CGFloat) -> CGFloat {
        let c4 = (2 * CGFloat.pi) / 3
        return progress == 0 ? 0 : progress == 1 ? 1 : pow(2, -10 * progress) * sin((progress * 10 - 0.75) * c4) + 1
    }
}

// MARK: - Main Animation Manager
class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    
    private override init() {}
    
    let hapticManager = HapticManager()
    let tweenManager = TweenManager()
    
    // MARK: - Spring Animations
    func springAnimate<Content: View>(
        _ content: Content,
        to: some View,
        duration: TimeInterval,
        delay: TimeInterval = 0,
        springConfig: SpringAnimationConfig = .responsive
    ) -> some View {
        content
            .animation(
                .interpolatingSpring(
                    stiffness: springConfig.stiffness,
                    damping: springConfig.damping,
                    mass: springConfig.mass
                ).delay(delay),
                value: UUID()
            )
    }
    
    // MARK: - Staggered Animations
    func staggeredAnimation<Content: View>(
        _ content: Content,
        items: [Any],
        itemDelay: TimeInterval = 0.1,
        animationType: AnimationType = .spring
    ) -> some View {
        content
            .transaction { transaction in
                transaction.animation = .easeInOut(duration: 0.5).delay(0.1)
            }
    }
    
    // MARK: - Micro Interactions
    @ViewBuilder
    func applyHoverEffect<Content: View>(_ content: Content, scale: CGFloat = 1.05, opacity: Double = 0.8) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.2), value: scale)
            .animation(.easeInOut(duration: 0.2), value: opacity)
    }
    
    @ViewBuilder
    func applyButtonPressEffect<Content: View>(_ content: Content, scale: CGFloat = 0.95) -> some View {
        content
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.1), value: scale)
    }
    
    @ViewBuilder
    func applyTextInputEffect<Content: View>(_ content: Content, focused: Bool) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(focused ? Color.blue : Color.gray.opacity(0.3), lineWidth: focused ? 2 : 1)
                    .animation(.easeInOut(duration: 0.3), value: focused)
            )
    }
    
    // MARK: - Page Transitions
    @ViewBuilder
    func pageTransition<Content: View, Destination: View>(
        from content: Content,
        to destination: Destination,
        transition: AnyTransition = .opacity.combined(with: .move(edge: .trailing))
    ) -> some View {
        content.transition(transition)
    }
    
    // MARK: - Loading Animations
    @ViewBuilder
    func loadingAnimation(spinner: Bool = true, dots: Bool = false, pulse: Bool = false) -> some View {
        if spinner {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
        } else if dots {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(.blue)
                        .animation(
                            .easeInOut(duration: 0.6).delay(Double(i) * 0.2).repeatForever(autoreverses: true),
                            value: UUID()
                        )
                }
            }
        } else if pulse {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(0.8)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
        }
    }
    
    // MARK: - Parallax Scrolling
    @ViewBuilder
    func parallaxScroll<Content: View>(_ content: Content, offset: CGFloat, magnitude: CGFloat = 0.5) -> some View {
        content
            .offset(y: offset * magnitude)
    }
    
    // MARK: - Core Animation with CAKeyframeAnimation
    func addSpringAnimation(to layer: CALayer, keyPath: String, fromValue: Any, toValue: Any, duration: TimeInterval) {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        
        // Calculate spring path
        let values = [fromValue, toValue]
        animation.values = values
        animation.keyTimes = [0, 1]
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        layer.add(animation, forKey: "springAnimation")
    }
    
    func addBounceAnimation(to layer: CALayer, keyPath: String, fromValue: CGFloat, toValue: CGFloat) {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        let bounceValues = [
            fromValue,
            fromValue * 1.3,
            toValue * 0.8,
            toValue
        ]
        animation.values = bounceValues
        animation.keyTimes = [0, 0.3, 0.6, 1]
        animation.duration = 0.6
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeIn),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .linear)
        ]
        
        layer.add(animation, forKey: "bounceAnimation")
    }
    
    func addElasticAnimation(to layer: CALayer, keyPath: String, fromValue: CGFloat, toValue: CGFloat) {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        let elasticValues = [
            fromValue,
            toValue * 1.4,
            toValue * 0.9,
            toValue * 1.1,
            toValue
        ]
        animation.values = elasticValues
        animation.keyTimes = [0, 0.4, 0.6, 0.8, 1]
        animation.duration = 0.8
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeIn),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeIn),
            CAMediaTimingFunction(name: .easeOut)
        ]
        
        layer.add(animation, forKey: "elasticAnimation")
    }
    
    // MARK: - Utility Functions
    func withSpringAnimation<Content: View>(
        _ content: Content,
        config: SpringAnimationConfig = .responsive
    ) -> some View {
        content
            .animation(
                .interpolatingSpring(
                    stiffness: config.stiffness,
                    damping: config.damping,
                    mass: config.mass
                ),
                value: UUID()
            )
    }
    
    func withEaseAnimation<Content: View>(
        _ content: Content,
        type: AnimationType = .easeInOut,
        duration: TimeInterval = 0.3
    ) -> some View {
        switch type {
        case .easeInOut:
            return content.animation(.easeInOut(duration: duration), value: UUID())
        case .easeIn:
            return content.animation(.easeIn(duration: duration), value: UUID())
        case .easeOut:
            return content.animation(.easeOut(duration: duration), value: UUID())
        case .spring:
            return content.animation(.spring(response: duration, dampingFraction: 0.8), value: UUID())
        default:
            return content.animation(.default, value: UUID())
        }
    }
}

// MARK: - View Extensions
extension View {
    func withSpringAnimation(
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        config: SpringAnimationConfig = .responsive
    ) -> some View {
        self
            .animation(
                .interpolatingSpring(
                    stiffness: config.stiffness,
                    damping: config.damping,
                    mass: config.mass
                ).delay(delay),
                value: UUID()
            )
    }
    
    func withEaseAnimation(
        type: AnimationType = .easeInOut,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0
    ) -> some View {
        let animation: Animation
        switch type {
        case .spring:
            animation = .spring(response: duration, dampingFraction: 0.8).delay(delay)
        case .easeInOut:
            animation = .easeInOut(duration: duration).delay(delay)
        case .easeIn:
            animation = .easeIn(duration: duration).delay(delay)
        case .easeOut:
            animation = .easeOut(duration: duration).delay(delay)
        default:
            animation = .default.delay(delay)
        }
        
        return self.animation(animation, value: UUID())
    }
    
    func withHoverEffect(scale: CGFloat = 1.05, opacity: Double = 0.8) -> some View {
        self
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.2), value: scale)
            .animation(.easeInOut(duration: 0.2), value: opacity)
    }
    
    func withButtonPressEffect(scale: CGFloat = 0.95) -> some View {
        self
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.1), value: scale)
    }
    
    func withTextInputEffect(focused: Bool) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(focused ? Color.blue : Color.gray.opacity(0.3), lineWidth: focused ? 2 : 1)
                    .animation(.easeInOut(duration: 0.3), value: focused)
            )
    }
    
    func withParallaxEffect(offset: CGFloat, magnitude: CGFloat = 0.5) -> some View {
        self
            .offset(y: offset * magnitude)
    }
    
    func withLoadingAnimation(type: AnimationManager.LoadingType = .spinner) -> some View {
        AnimationManager.shared.loadingAnimation(
            spinner: type == .spinner,
            dots: type == .dots,
            pulse: type == .pulse
        )
    }
}

// MARK: - Animation Types Enum Extension
extension AnimationManager {
    enum LoadingType {
        case spinner
        case dots
        case pulse
    }
}

// MARK: - Screen Transition Manager
class ScreenTransitionManager: ObservableObject {
    @Published var currentTransition: AnyTransition = .identity
    @Published var isTransitioning = false
    
    func transition(to transition: AnyTransition) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentTransition = transition
            isTransitioning = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.currentTransition = .identity
                self.isTransitioning = false
            }
        }
    }
    
    static let slideLeft = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    static let slideUp = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity)
    )
    
    static let fade = AnyTransition.opacity.combined(with: .scale(scale: 0.8))
}