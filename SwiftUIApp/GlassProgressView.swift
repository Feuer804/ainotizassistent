//
//  GlassProgressView.swift
//  SwiftUIApp
//
//  Ladebalken mit Glass-Hintergrund
//

import SwiftUI

// MARK: - Progress Configuration
public struct GlassProgressConfiguration {
    let cornerRadius: CGFloat
    let height: CGFloat
    let backgroundOpacity: CGFloat
    let progressOpacity: CGFloat
    let glowIntensity: CGFloat
    let animationDuration: Double
    
    public init(
        cornerRadius: CGFloat = 10,
        height: CGFloat = 8,
        backgroundOpacity: CGFloat = 0.1,
        progressOpacity: CGFloat = 0.8,
        glowIntensity: CGFloat = 0.5,
        animationDuration: Double = 0.3
    ) {
        self.cornerRadius = cornerRadius
        self.height = height
        self.backgroundOpacity = backgroundOpacity
        self.progressOpacity = progressOpacity
        self.glowIntensity = glowIntensity
        self.animationDuration = animationDuration
    }
}

// MARK: - Basic Glass Progress View
public struct GlassProgressView: View {
    @State private var animatedProgress: CGFloat = 0
    private let progress: CGFloat
    private let configuration: GlassProgressConfiguration
    private let accentColor: Color
    private let showPercentage: Bool
    
    public init(
        progress: CGFloat,
        accentColor: Color = .blue,
        configuration: GlassProgressConfiguration = GlassProgressConfiguration(),
        showPercentage: Bool = false
    ) {
        self.progress = progress
        self.accentColor = accentColor
        self.configuration = configuration
        self.showPercentage = showPercentage
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Progress Track
            ZStack {
                // Background Track
                RoundedRectangle(cornerRadius: configuration.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(configuration.backgroundOpacity),
                                Color.white.opacity(configuration.backgroundOpacity * 0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .background(.ultraThinMaterial)
                    .frame(height: configuration.height)
                
                // Progress Fill
                RoundedRectangle(cornerRadius: configuration.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(configuration.progressOpacity),
                                accentColor.opacity(configuration.progressOpacity * 0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(configuration.height, animatedProgress), height: configuration.height)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: configuration.cornerRadius)
                            .stroke(
                                accentColor.opacity(configuration.glowIntensity),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: accentColor.opacity(configuration.glowIntensity),
                        radius: configuration.cornerRadius,
                        x: 0,
                        y: 0
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
            
            // Percentage Label
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: configuration.animationDuration)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeInOut(duration: configuration.animationDuration)) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Circular Glass Progress View
public struct GlassCircularProgressView: View {
    @State private var animatedProgress: CGFloat = 0
    @State private var rotationAngle: Angle = .degrees(-90)
    
    private let progress: CGFloat
    private let size: CGFloat
    private let lineWidth: CGFloat
    private let accentColor: Color
    private let configuration: GlassProgressConfiguration
    private let showPercentage: Bool
    private let centerContent: AnyView?
    
    public init(
        progress: CGFloat,
        size: CGFloat = 120,
        lineWidth: CGFloat = 12,
        accentColor: Color = .blue,
        configuration: GlassProgressConfiguration = GlassProgressConfiguration(),
        showPercentage: Bool = true,
        @ViewBuilder centerContent: () -> some View = { EmptyView() }
    ) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.accentColor = accentColor
        self.configuration = configuration
        self.showPercentage = showPercentage
        self.centerContent = AnyView(centerContent())
    }
    
    public var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(configuration.backgroundOpacity),
                            Color.white.opacity(configuration.backgroundOpacity * 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: lineWidth
                )
                .background(.ultraThinMaterial)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(configuration.progressOpacity),
                            accentColor.opacity(configuration.progressOpacity * 0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(rotationAngle)
                .overlay(
                    Circle()
                        .stroke(
                            accentColor.opacity(configuration.glowIntensity),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: accentColor.opacity(configuration.glowIntensity),
                    radius: lineWidth,
                    x: 0,
                    y: 0
                )
            
            // Center Content
            if let centerContent = centerContent {
                centerContent
            } else if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: configuration.animationDuration)) {
                animatedProgress = progress
                rotationAngle = .degrees(270)
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeInOut(duration: configuration.animationDuration)) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Multi-step Glass Progress
public struct GlassMultiStepProgress: View {
    private let steps: [String]
    private let currentStep: Int
    private let accentColor: Color
    
    public init(
        steps: [String],
        currentStep: Int,
        accentColor: Color = .blue
    ) {
        self.steps = steps
        self.currentStep = currentStep
        self.accentColor = accentColor
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                ForEach(Array(steps.enumerated()), id: \.0) { index, step in
                    let isCompleted = index < currentStep
                    let isCurrent = index == currentStep
                    
                    VStack(spacing: 8) {
                        // Step Circle
                        ZStack {
                            Circle()
                                .fill(
                                    isCompleted || isCurrent
                                        ? accentColor.opacity(0.3)
                                        : Color.white.opacity(0.1)
                                )
                                .background(.ultraThinMaterial)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            isCompleted || isCurrent
                                                ? accentColor.opacity(0.6)
                                                : Color.white.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(
                                        isCurrent ? accentColor : .secondary
                                    )
                            }
                        }
                        
                        // Step Label
                        Text(step)
                            .font(.caption)
                            .fontWeight(isCurrent ? .semibold : .medium)
                            .foregroundColor(isCurrent ? accentColor : .secondary)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                    }
                    
                    // Connector Line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        index < currentStep ? accentColor.opacity(0.6) : Color.white.opacity(0.2),
                                        index < currentStep - 1 ? accentColor.opacity(0.3) : Color.white.opacity(0.1)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                    }
                }
            }
            
            // Progress Percentage
            Text("Schritt \(currentStep + 1) von \(steps.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Animated Loading Indicator
public struct GlassLoadingIndicator: View {
    @State private var rotationAnimation = 0.0
    
    private let size: CGFloat
    private let accentColor: Color
    private let lineWidth: CGFloat
    
    public init(
        size: CGFloat = 40,
        accentColor: Color = .blue,
        lineWidth: CGFloat = 4
    ) {
        self.size = size
        self.accentColor = accentColor
        self.lineWidth = lineWidth
    }
    
    public var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: lineWidth
                )
                .background(.ultraThinMaterial)
                .frame(width: size, height: size)
            
            // Rotating Arc
            Circle()
                .trim(from: 0.1, to: 0.3)
                .stroke(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.8),
                            accentColor.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotationAnimation))
                .shadow(
                    color: accentColor.opacity(0.5),
                    radius: lineWidth,
                    x: 0,
                    y: 0
                )
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotationAnimation = 360
            }
        }
    }
}

// MARK: - Progress View with Status
public struct GlassProgressWithStatus: View {
    @State private var animatedProgress: CGFloat = 0
    
    private let title: String
    private let subtitle: String?
    private let progress: CGFloat
    private let accentColor: Color
    private let configuration: GlassProgressConfiguration
    
    public init(
        title: String,
        subtitle: String? = nil,
        progress: CGFloat,
        accentColor: Color = .blue,
        configuration: GlassProgressConfiguration = GlassProgressConfiguration()
    ) {
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.accentColor = accentColor
        self.configuration = configuration
    }
    
    public var body: some View {
        GlassCardView(cornerRadius: 16, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status Icon
                    Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "hourglass.bottomhalf.filled")
                        .font(.title2)
                        .foregroundColor(progress >= 1.0 ? .green : accentColor)
                }
                
                // Progress Bar
                GlassProgressView(
                    progress: progress,
                    accentColor: accentColor,
                    configuration: configuration,
                    showPercentage: true
                )
                
                // Status Text
                Text(progress >= 1.0 ? "Abgeschlossen" : "In Bearbeitung...")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(progress >= 1.0 ? .green : accentColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: configuration.animationDuration)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeInOut(duration: configuration.animationDuration)) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Preview
struct GlassProgressView_Previews: PreviewProvider {
    @State private var progress: CGFloat = 0.3
    
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Basic Progress
                    GlassCardView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Linearer Fortschritt")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            GlassProgressView(
                                progress: 0.7,
                                accentColor: .blue,
                                showPercentage: true
                            )
                        }
                    }
                    
                    // Circular Progress
                    HStack {
                        GlassCircularProgressView(progress: 0.7)
                        
                        GlassCircularProgressView(
                            progress: 0.3,
                            size: 100,
                            lineWidth: 8,
                            accentColor: .purple
                        ) {
                            VStack {
                                GlassLoadingIndicator(size: 20, accentColor: .orange)
                                Text("Laden")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Multi-step Progress
                    GlassCardView {
                        GlassMultiStepProgress(
                            steps: ["Start", "Daten", "Bestätigung", "Abgeschlossen"],
                            currentStep: 2,
                            accentColor: .green
                        )
                    }
                    
                    // Progress with Status
                    GlassProgressWithStatus(
                        title: "Datei-Upload",
                        subtitle: "Wird hochgeladen...",
                        progress: 0.6,
                        accentColor: .blue
                    )
                    
                    // Loading Indicators
                    HStack(spacing: 20) {
                        GlassLoadingIndicator(accentColor: .blue)
                        GlassLoadingIndicator(size: 30, accentColor: .green)
                        GlassLoadingIndicator(size: 20, accentColor: .purple)
                    }
                    
                    // Interactive Progress
                    GlassCardView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Interaktiver Fortschritt")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            GlassProgressView(
                                progress: progress,
                                accentColor: .orange,
                                showPercentage: true
                            )
                            
                            HStack(spacing: 10) {
                                Button("25%") {
                                    progress = 0.25
                                }
                                .buttonStyle(GlassButtonStyle())
                                
                                Button("50%") {
                                    progress = 0.5
                                }
                                .buttonStyle(GlassButtonStyle())
                                
                                Button("75%") {
                                    progress = 0.75
                                }
                                .buttonStyle(GlassButtonStyle())
                                
                                Button("100%") {
                                    progress = 1.0
                                }
                                .buttonStyle(GlassButtonStyle())
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}