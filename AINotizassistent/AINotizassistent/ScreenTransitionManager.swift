//
//  ScreenTransitionManager.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI
import AppKit
import Combine

// MARK: - Transition Styles
enum TransitionStyle {
    case slideLeft
    case slideRight
    case slideUp
    case slideDown
    case fade
    case scale
    case rotate
    case flip
    case zoom
    case bounce
    case elastic
    case wave
    case spiral
    case custom(AnyTransition)
}

// MARK: - Tab Transition Config
struct TabTransitionConfig {
    let duration: TimeInterval
    let delay: TimeInterval
    let animationStyle: Animation
    let transitionStyle: TransitionStyle
    
    static let standard = TabTransitionConfig(
        duration: 0.5,
        delay: 0,
        animationStyle: .easeInOut(duration: 0.5),
        transitionStyle: .slideLeft
    )
    
    static let smooth = TabTransitionConfig(
        duration: 0.3,
        delay: 0,
        animationStyle: .spring(response: 0.5, dampingFraction: 0.8),
        transitionStyle: .fade
    )
    
    static let dramatic = TabTransitionConfig(
        duration: 0.8,
        delay: 0.1,
        animationStyle: .interpolatingSpring(stiffness: 200, damping: 15),
        transitionStyle: .scale
    )
    
    static let bounce = TabTransitionConfig(
        duration: 0.6,
        delay: 0,
        animationStyle: .spring(response: 0.4, dampingFraction: 0.6),
        transitionStyle: .bounce
    )
}

// MARK: - Screen Transition State
struct ScreenTransitionState {
    var isTransitioning = false
    var currentTransition: TransitionStyle = .fade
    var animationProgress: CGFloat = 0
    var targetView: AnyView?
    var sourceView: AnyView?
}

// MARK: - Screen Transition Manager
class ScreenTransitionManager: ObservableObject {
    @Published var transitionState = ScreenTransitionState()
    @Published var currentTab: String = "main"
    @Published var isTransitioning = false
    
    private var cancellables = Set<AnyCancellable>()
    private let hapticManager = AnimationManager.shared.hapticManager
    
    // MARK: - Tab Transitions
    func transitionToTab(
        tabId: String,
        config: TabTransitionConfig = .standard,
        completion: (() -> Void)? = nil
    ) {
        guard !isTransitioning && tabId != currentTab else { return }
        
        // Haptic feedback for tab change
        hapticManager.playTap()
        
        withAnimation(config.animationStyle.delay(config.delay)) {
            transitionState.isTransitioning = true
            isTransitioning = true
            transitionState.currentTransition = config.transitionStyle
            transitionState.animationProgress = 0
        }
        
        // Complete transition after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
            withAnimation(config.animationStyle) {
                self.transitionState.isTransitioning = false
                self.isTransitioning = false
                self.currentTab = tabId
                self.transitionState.animationProgress = 1
            }
            
            completion?()
        }
    }
    
    func animateTabChange(from oldTab: String, to newTab: String, direction: Int = 1) {
        hapticManager.playTap()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            transitionState.animationProgress = CGFloat(direction)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentTab = newTab
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.transitionState.animationProgress = 0
            }
        }
    }
    
    // MARK: - Custom Transitions
    @ViewBuilder
    func applyTransition<Content: View>(
        style: TransitionStyle,
        content: Content
    ) -> some View {
        switch style {
        case .slideLeft:
            content
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .slideRight:
            content
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
        case .slideUp:
            content
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
        case .slideDown:
            content
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
        case .fade:
            content.transition(.opacity)
        case .scale:
            content.transition(.scale(scale: 0.8).combined(with: .opacity))
        case .rotate:
            content
                .rotationEffect(.degrees(transitionState.animationProgress * 360))
                .transition(.opacity)
        case .zoom:
            content
                .scaleEffect(transitionState.animationProgress == 0 ? 1 : 0.8)
                .transition(.opacity)
        case .bounce:
            content
                .offset(y: sin(transitionState.animationProgress * .pi) * 20)
                .transition(.opacity)
        case .elastic:
            content
                .scaleEffect(1 + (sin(transitionState.animationProgress * .pi * 2) * 0.1))
                .transition(.opacity)
        case .wave:
            content
                .offset(y: transitionState.animationProgress * -50)
                .transition(.opacity)
        case .spiral:
            content
                .rotationEffect(.degrees(transitionState.animationProgress * 90))
                .scaleEffect(1 - (transitionState.animationProgress * 0.2))
                .transition(.opacity)
        case .custom(let transition):
            content.transition(transition)
        }
    }
    
    // MARK: - Stack Transitions
    @ViewBuilder
    func createNavigationStack<Content: View>(
        currentView: Content,
        isVisible: Bool,
        transitionStyle: TransitionStyle = .slideLeft
    ) -> some View {
        if isVisible {
            currentView
                .applyTransition(style: transitionStyle)
        }
    }
    
    // MARK: - Modal Transitions
    @ViewBuilder
    func createModalTransition<Content: View>(
        isPresented: Bool,
        content: () -> Content
    ) -> some View {
        if isPresented {
            content()
                .transition(
                    .asymmetric(
                        insertion: AnyTransition.opacity.combined(with: .move(edge: .bottom)),
                        removal: AnyTransition.opacity.combined(with: .move(edge: .top))
                    )
                )
        }
    }
    
    // MARK: - Sheet Transitions
    @ViewBuilder
    func createSheetTransition<Content: View>(
        isPresented: Bool,
        detents: [UISheetPresentationController.Detent]? = nil,
        content: () -> Content
    ) -> some View {
        if isPresented {
            content()
                .transition(
                    .move(edge: .bottom).combined(with: .opacity)
                )
                .presentationDetents(detents ?? [.medium, .large])
        }
    }
    
    // MARK: - Popover Transitions
    @ViewBuilder
    func createPopoverTransition<Content: View>(
        isPresented: Bool,
        arrowEdge: Edge = .top,
        content: () -> Content
    ) -> some View {
        if isPresented {
            content()
                .transition(.scale.combined(with: .opacity))
                .popover(isPresented: .constant(isPresented)) {
                    content()
                        .transition(.scale.combined(with: .opacity))
                }
        }
    }
    
    // MARK: - Advanced Tab Animation
    @ViewBuilder
    func createAdvancedTabView<SelectionType: Hashable, Content: View>(
        selection: Binding<SelectionType>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let selectionValue = selection.wrappedValue
        
        TabView(selection: selection) {
            content()
                .tag(selectionValue)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
        }
        .tabViewStyle(.page)
        .animation(.easeInOut(duration: 0.5), value: selectionValue)
    }
    
    // MARK: - Gesture-Based Transitions
    @ViewBuilder
    func createSwipeableContent<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            // Handle swipe gesture
                        }
                    }
                    .onEnded { value in
                        if value.translation.width > 100 {
                            // Swipe right - next view
                            hapticManager.playTap()
                        } else if value.translation.width < -100 {
                            // Swipe left - previous view
                            hapticManager.playTap()
                        }
                    }
            )
    }
    
    // MARK: - Parallax Tab Transition
    @ViewBuilder
    func createParallaxTabTransition<Content: View>(
        offset: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .offset(x: offset * 0.5)
            .scaleEffect(1 - abs(offset) * 0.001)
            .rotationEffect(.degrees(offset * 0.1))
    }
    
    // MARK: - Morphing Transition
    @ViewBuilder
    func createMorphingTransition<Content: View>(
        progress: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .offset(y: progress * -100)
            .scaleEffect(1 - (progress * 0.2))
            .rotationEffect(.degrees(progress * 45))
    }
    
    // MARK: - Transition Utilities
    func createTabBarTransition(
        selectedTab: String,
        availableTabs: [String]
    ) -> AnyTransition {
        let index = availableTabs.firstIndex(of: selectedTab) ?? 0
        let direction = index > 0 ? 1 : -1
        
        return .asymmetric(
            insertion: .move(edge: direction > 0 ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: direction > 0 ? .leading : .trailing).combined(with: .opacity)
        )
    }
    
    func createCardFlipTransition() -> AnyTransition {
        return .asymmetric(
            insertion: AnyTransition.scale(scale: 0.8).combined(with: .opacity),
            removal: AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        )
    }
    
    func createSlideCardsTransition() -> AnyTransition {
        return .move(edge: .bottom).combined(with: .opacity)
    }
    
    func createZoomInTransition() -> AnyTransition {
        return AnyTransition.scale(scale: 0.5).combined(with: .opacity)
    }
    
    func createZoomOutTransition() -> AnyTransition {
        return AnyTransition.scale(scale: 1.5).combined(with: .opacity)
    }
    
    // MARK: - Predefined Transitions
    static let slideLeft = ScreenTransitionManager.createTabBarTransition(
        selectedTab: "",
        availableTabs: [""]
    )
    
    static let slideRight = AnyTransition.asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
    )
    
    static let slideUp = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity)
    )
    
    static let fade = AnyTransition.opacity.combined(with: .scale(scale: 0.9))
    
    static let scale = AnyTransition.scale.combined(with: .opacity)
    
    static let rotate = AnyTransition.modifier(
        identity: {},
        body: { content in
            content.rotationEffect(.degrees(0))
        }
    )
    
    static let flip = AnyTransition.modifier(
        identity: {},
        body: { content in
            content.rotation3DEffect(.degrees(0), axis: (x: 1, y: 0, z: 0))
        }
    )
    
    static let bounce = AnyTransition.modifier(
        identity: {},
        body: { content in
            content.offset(y: 0)
        }
    )
    
    static let elastic = AnyTransition.modifier(
        identity: {},
        body: { content in
            content.scaleEffect(1)
        }
    )
    
    // MARK: - Cleanup
    func reset() {
        withAnimation(.easeInOut(duration: 0.3)) {
            transitionState = ScreenTransitionState()
            isTransitioning = false
            currentTab = "main"
        }
    }
    
    func cleanup() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

// MARK: - View Extensions for Screen Transitions
extension View {
    func withScreenTransition(
        style: TransitionStyle,
        isVisible: Bool
    ) -> some View {
        let manager = ScreenTransitionManager.shared
        
        if isVisible {
            return manager.applyTransition(style: style, content: self)
        } else {
            return self
        }
    }
    
    func withTabTransition(
        isSelected: Bool,
        animationDuration: TimeInterval = 0.3
    ) -> some View {
        self
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .opacity(isSelected ? 1.0 : 0.6)
            .animation(.spring(response: animationDuration, dampingFraction: 0.8), value: isSelected)
    }
    
    func withSwipeTransition(direction: DragGesture.Value) -> some View {
        let translation = direction.translation.width
        
        return self
            .offset(x: translation * 0.5)
            .scaleEffect(1 - abs(translation) * 0.001)
            .opacity(1 - abs(translation) * 0.002)
    }
    
    func withParallaxTransition(offset: CGFloat) -> some View {
        self
            .offset(x: offset * 0.5)
            .scaleEffect(1 - abs(offset) * 0.0005)
    }
    
    func withMorphingTransition(progress: CGFloat) -> some View {
        self
            .offset(y: progress * -50)
            .scaleEffect(1 - (progress * 0.1))
    }
}

// MARK: - Transition Coordinator
class TransitionCoordinator: ObservableObject {
    @Published var isAnimating = false
    @Published var animationPhase: String = ""
    @Published var progress: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    func startTransition(phases: [String], duration: TimeInterval) {
        isAnimating = true
        let phaseDuration = duration / Double(phases.count)
        
        for (index, phase) in phases.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration * Double(index)) {
                withAnimation(.easeInOut(duration: phaseDuration)) {
                    self.animationPhase = phase
                    self.progress = CGFloat(index + 1) / CGFloat(phases.count)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.isAnimating = false
                self.animationPhase = ""
                self.progress = 0
            }
        }
    }
    
    func cancelTransition() {
        withAnimation(.easeOut(duration: 0.3)) {
            isAnimating = false
            animationPhase = ""
            progress = 0
        }
    }
}