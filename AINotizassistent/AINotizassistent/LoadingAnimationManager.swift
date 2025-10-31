//
//  LoadingAnimationManager.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI
import AppKit
import Combine

// MARK: - Loading Animation Types
enum LoadingAnimationType {
    case spinner
    case dots
    case pulse
    case wave
    case bars
    case orbit
    case spinnerWithText
    case progressBar
    case indeterminate
    case custom(String)
    
    var displayName: String {
        switch self {
        case .spinner: return "Spinner"
        case .dots: return "Dots"
        case .pulse: return "Pulse"
        case .wave: return "Wave"
        case .bars: return "Bars"
        case .orbit: return "Orbit"
        case .spinnerWithText: return "Spinner mit Text"
        case .progressBar: return "Fortschrittsbalken"
        case .indeterminate: return "Unbestimmt"
        case .custom(let name): return name
        }
    }
}

// MARK: - Loading State
struct LoadingState {
    var isLoading = false
    var progress: CGFloat = 0
    var message: String = ""
    var animationType: LoadingAnimationType = .spinner
    var duration: TimeInterval = 1.0
    var canBeCancelled = false
    var estimatedTimeRemaining: TimeInterval = 0
}

// MARK: - AI Processing State
enum AIProcessingStage {
    case analyzing
    case processing
    case generating
    case completing
    
    var displayName: String {
        switch self {
        case .analyzing: return "Analysiere Eingabe..."
        case .processing: return "Verarbeite Daten..."
        case .generating: return "Generiere Inhalt..."
        case .completing: return "Abschließen..."
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .analyzing: return 1.5
        case .processing: return 2.0
        case .generating: return 1.8
        case .completing: return 0.7
        }
    }
}

// MARK: - Loading Animation Manager
class LoadingAnimationManager: ObservableObject {
    @Published var loadingState = LoadingState()
    @Published var currentStage: AIProcessingStage = .analyzing
    @Published var stages: [AIProcessingStage] = [.analyzing, .processing, .generating, .completing]
    @Published var isAIProcessing = false
    
    private var cancellables = Set<AnyCancellable>()
    private let hapticManager = AnimationManager.shared.hapticManager
    
    // MARK: - Basic Loading Animations
    @ViewBuilder
    func createSpinner(color: Color = .blue, size: CGFloat = 30) -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: color))
            .scaleEffect(size / 20)
            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: UUID())
    }
    
    @ViewBuilder
    func createDotsAnimation(color: Color = .blue, size: CGFloat = 8) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .delay(Double(i) * 0.2)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )
            }
        }
    }
    
    @ViewBuilder
    func createPulseAnimation(color: Color = .blue, size: CGFloat = 40) -> some View {
        Circle()
            .fill(color.opacity(0.3))
            .frame(width: size, height: size)
            .scaleEffect(0.8)
            .animation(
                .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: UUID()
            )
    }
    
    @ViewBuilder
    func createWaveAnimation(color: Color = .blue, height: CGFloat = 20, barCount: Int = 5) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                Rectangle()
                    .fill(color)
                    .frame(width: 3, height: height)
                    .animation(
                        .easeInOut(duration: 0.8)
                            .delay(Double(i) * 0.1)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )
            }
        }
    }
    
    @ViewBuilder
    func createBarsAnimation(color: Color = .blue, count: Int = 5) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<count, id: \.self) { i in
                Rectangle()
                    .fill(color)
                    .frame(width: 4, height: 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(i) * 0.1)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )
            }
        }
    }
    
    @ViewBuilder
    func createOrbitAnimation(centerColor: Color = .blue, orbitColor: Color = .blue.opacity(0.3), radius: CGFloat = 20) -> some View {
        ZStack {
            Circle()
                .fill(orbitColor)
                .frame(width: radius * 2, height: radius * 2)
            
            Circle()
                .fill(centerColor)
                .frame(width: 6, height: 6)
                .offset(x: radius)
                .rotationEffect(.degrees(360))
                .animation(
                    .linear(duration: 2.0)
                        .repeatForever(autoreverses: false),
                    value: UUID()
                )
        }
    }
    
    @ViewBuilder
    func createSpinnerWithText(text: String, color: Color = .blue) -> some View {
        VStack(spacing: 16) {
            createSpinner(color: color)
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
                .animation(.easeInOut(duration: 0.3), value: text)
        }
    }
    
    // MARK: - Progress Indicators
    @ViewBuilder
    func createProgressBar(progress: CGFloat, color: Color = .blue, height: CGFloat = 8) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                    .cornerRadius(height / 2)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: height)
                    .cornerRadius(height / 2)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
    
    @ViewBuilder
    func createIndeterminateProgress(color: Color = .blue, height: CGFloat = 8) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                    .cornerRadius(height / 2)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * 0.3, height: height)
                    .cornerRadius(height / 2)
                    .offset(x: geometry.size.width * 0.7)
                    .animation(
                        .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
        }
        .frame(height: height)
    }
    
    // MARK: - AI Processing Animations
    @ViewBuilder
    func createAIProcessingAnimation(stage: AIProcessingStage, progress: CGFloat = 0) -> some View {
        switch stage {
        case .analyzing:
            VStack(spacing: 16) {
                createWaveAnimation(color: .blue)
                Text("Analysiere Eingabe...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        case .processing:
            VStack(spacing: 16) {
                createOrbitAnimation(centerColor: .orange, orbitColor: .orange.opacity(0.3))
                Text("Verarbeite Daten...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        case .generating:
            VStack(spacing: 16) {
                createPulseAnimation(color: .green)
                Text("Generiere Inhalt...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        case .completing:
            VStack(spacing: 16) {
                createBarsAnimation(color: .purple)
                Text("Abschließen...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    func createAIStagesProgress(stages: [AIProcessingStage], currentIndex: Int, progress: CGFloat) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(stages.indices, id: \.self) { index in
                    let stage = stages[index]
                    let isActive = index <= currentIndex
                    let isCurrent = index == currentIndex
                    
                    Circle()
                        .fill(isActive ? .blue : .gray.opacity(0.3))
                        .frame(width: isCurrent ? 12 : 8, height: isCurrent ? 12 : 8)
                        .scaleEffect(isCurrent ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: index)
                    
                    if index < stages.count - 1 {
                        Rectangle()
                            .fill(isActive ? .blue : .gray.opacity(0.3))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                            .animation(.easeInOut(duration: 0.3), value: index)
                    }
                }
            }
            
            Text(stages[currentIndex].displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .animation(.easeInOut(duration: 0.3), value: stages[currentIndex])
            
            createProgressBar(progress: progress, color: .blue, height: 6)
        }
        .frame(maxWidth: 300)
    }
    
    // MARK: - Smart Loading Animations
    @ViewBuilder
    func createSmartLoadingAnimation(type: LoadingAnimationType, message: String) -> some View {
        switch type {
        case .spinner:
            createSpinnerWithText(text: message)
        case .dots:
            VStack(spacing: 16) {
                createDotsAnimation()
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        case .pulse:
            VStack(spacing: 16) {
                createPulseAnimation()
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        case .wave:
            VStack(spacing: 16) {
                createWaveAnimation()
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        case .bars:
            VStack(spacing: 16) {
                createBarsAnimation()
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        case .orbit:
            VStack(spacing: 16) {
                createOrbitAnimation()
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        case .spinnerWithText:
            createSpinnerWithText(text: message)
        case .progressBar:
            VStack(spacing: 16) {
                createProgressBar(progress: loadingState.progress)
                Text("\(Int(loadingState.progress * 100))%")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        case .indeterminate:
            VStack(spacing: 16) {
                createIndeterminateProgress()
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        case .custom(let customType):
            createCustomAnimation(type: customType, message: message)
        }
    }
    
    // MARK: - Custom Animations
    @ViewBuilder
    private func createCustomAnimation(type: String, message: String) -> some View {
        switch type {
        case "brain":
            VStack(spacing: 16) {
                Image(systemName: "brain")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                    .scaleEffect(1.0)
                    .animation(
                        .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        case "sparkles":
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                        .scaleEffect(1.0)
                        .animation(
                            .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: UUID()
                        )
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .scaleEffect(0.8)
                        .animation(
                            .easeInOut(duration: 0.8)
                                .delay(0.2)
                                .repeatForever(autoreverses: true),
                            value: UUID()
                        )
                }
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        default:
            createSpinnerWithText(text: message)
        }
    }
    
    // MARK: - Full-Screen Loading Overlay
    @ViewBuilder
    func createFullScreenLoadingOverlay() -> some View {
        if loadingState.isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    createSmartLoadingAnimation(
                        type: loadingState.animationType,
                        message: loadingState.message
                    )
                    
                    if loadingState.canBeCancelled {
                        Button("Abbrechen") {
                            stopLoading()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                    }
                    
                    if loadingState.estimatedTimeRemaining > 0 {
                        Text("Geschätzte Restzeit: \(Int(loadingState.estimatedTimeRemaining))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(radius: 10)
                )
            }
            .transition(.opacity.combined(with: .scale))
            .zIndex(1000)
        }
    }
    
    // MARK: - Loading State Management
    func startLoading(
        type: LoadingAnimationType = .spinner,
        message: String = "Wird geladen...",
        duration: TimeInterval = 1.0,
        cancellable: Bool = false
    ) {
        withAnimation(.easeInOut(duration: 0.3)) {
            loadingState = LoadingState(
                isLoading: true,
                progress: 0,
                message: message,
                animationType: type,
                duration: duration,
                canBeCancelled: cancellable
            )
        }
        
        hapticManager.playTap()
    }
    
    func updateProgress(_ progress: CGFloat, message: String? = nil) {
        withAnimation(.easeInOut(duration: 0.1)) {
            loadingState.progress = min(max(progress, 0), 1)
            if let message = message {
                loadingState.message = message
            }
        }
    }
    
    func updateMessage(_ message: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            loadingState.message = message
        }
    }
    
    func stopLoading() {
        withAnimation(.easeOut(duration: 0.3)) {
            loadingState.isLoading = false
        }
        
        hapticManager.playSuccess()
    }
    
    // MARK: - AI Processing Management
    func startAIProcessing(stages: [AIProcessingStage] = [.analyzing, .processing, .generating, .completing]) {
        self.stages = stages
        isAIProcessing = true
        currentStage = stages.first!
        
        runNextStage(currentIndex: 0)
    }
    
    private func runNextStage(currentIndex: Int) {
        guard currentIndex < stages.count else {
            stopAIProcessing()
            return
        }
        
        currentStage = stages[currentIndex]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + stages[currentIndex].duration) {
            self.runNextStage(currentIndex: currentIndex + 1)
        }
    }
    
    func stopAIProcessing() {
        isAIProcessing = false
        loadingState.isLoading = false
    }
    
    func cancelLoading() {
        stopLoading()
        stopAIProcessing()
    }
    
    // MARK: - Utility Methods
    func simulateLoading(duration: TimeInterval = 3.0, completion: (() -> Void)? = nil) {
        startLoading(message: "Wird simuliert...", cancellable: true)
        
        let startTime = Date().timeIntervalSince1970
        let endTime = startTime + duration
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let now = Date().timeIntervalSince1970
            let progress = CGFloat((now - startTime) / duration)
            
            if now >= endTime {
                timer.invalidate()
                self.stopLoading()
                completion?()
            } else {
                self.updateProgress(progress)
            }
        }
    }
    
    func createLoadingButton<Content: View>(
        title: String,
        isLoading: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button(action: {
            if !isLoading {
                action()
            }
        }) {
            ZStack {
                if isLoading {
                    createSpinner(color: .white, size: 16)
                } else {
                    content()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - View Extensions
extension View {
    func withLoadingOverlay(_ isVisible: Bool) -> some View {
        overlay(
            Group {
                if isVisible {
                    LoadingAnimationManager.shared.createFullScreenLoadingOverlay()
                }
            }
        )
    }
    
    func withProgressBar(progress: CGFloat, color: Color = .blue, height: CGFloat = 8) -> some View {
        overlay(
            LoadingAnimationManager.shared.createProgressBar(
                progress: progress,
                color: color,
                height: height
            ),
            alignment: .bottom
        )
    }
    
    func withSmartLoadingAnimation(
        type: LoadingAnimationType = .spinner,
        isLoading: Bool,
        message: String = "Wird geladen..."
    ) -> some View {
        overlay(
            Group {
                if isLoading {
                    LoadingAnimationManager.shared.createSmartLoadingAnimation(
                        type: type,
                        message: message
                    )
                }
            }
        )
    }
}