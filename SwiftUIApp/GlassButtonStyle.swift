//
//  GlassButtonStyle.swift
//  SwiftUIApp
//
//  Erweiterte Glass-Button-Komponente mit Glow-Effekten
//

import SwiftUI

public struct GlassButtonStyle: ButtonStyle {
    private let cornerRadius: CGFloat
    private let intensity: CGFloat
    private let glowColor: Color
    private let pressScale: CGFloat
    
    public init(
        cornerRadius: CGFloat = 16,
        intensity: CGFloat = 0.2,
        glowColor: Color = .blue,
        pressScale: CGFloat = 0.95
    ) {
        self.cornerRadius = cornerRadius
        self.intensity = intensity
        self.glowColor = glowColor
        self.pressScale = pressScale
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressScale : 1.0)
            .overlay(
                // Haupt-Glass-Hintergrund
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: configuration.isPressed ? .clear : glowColor.opacity(intensity),
                radius: configuration.isPressed ? 0 : 20,
                x: 0,
                y: configuration.isPressed ? 0 : 4
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 10,
                x: 0,
                y: 2
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Convenience Button-Styles
extension ButtonStyle where Self == GlassButtonStyle {
    public static var glass: GlassButtonStyle {
        GlassButtonStyle()
    }
    
    public static func glass(
        intensity: CGFloat,
        glowColor: Color
    ) -> GlassButtonStyle {
        GlassButtonStyle(intensity: intensity, glowColor: glowColor)
    }
}

// MARK: - Specialized Glass Button Styles
public struct PrimaryGlassButtonStyle: ButtonStyle {
    private let cornerRadius: CGFloat
    private let primaryColor: Color
    
    public init(cornerRadius: CGFloat = 16, primaryColor: Color = .blue) {
        self.cornerRadius = cornerRadius
        self.primaryColor = primaryColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                primaryColor.opacity(0.3),
                                primaryColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        primaryColor.opacity(0.6),
                                        primaryColor.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(
                color: configuration.isPressed ? .clear : primaryColor.opacity(0.4),
                radius: configuration.isPressed ? 0 : 25,
                x: 0,
                y: configuration.isPressed ? 0 : 6
            )
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 15,
                x: 0,
                y: 3
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Glass Button with Icon
public struct GlassIconButtonStyle: ButtonStyle {
    private let size: CGFloat
    private let iconScale: CGFloat
    
    public init(size: CGFloat = 44, iconScale: CGFloat = 0.6) {
        self.size = size
        self.iconScale = iconScale
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * iconScale, weight: .medium))
            .frame(width: size, height: size)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: configuration.isPressed ? .clear : Color.blue.opacity(0.2),
                radius: configuration.isPressed ? 0 : 15,
                x: 0,
                y: configuration.isPressed ? 0 : 4
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 2
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct GlassButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Button("Primary Glass") {
                    print("Primary tapped")
                }
                .buttonStyle(PrimaryGlassButtonStyle())
                .frame(width: 200, height: 50)
                
                Button {
                    print("Standard glass tapped")
                } label: {
                    Label("Standard Glass", systemImage: "star.fill")
                }
                .buttonStyle(GlassButtonStyle(glowColor: .purple))
                .frame(width: 200, height: 50)
                
                Button {
                    print("Icon glass tapped")
                } label: {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(GlassIconButtonStyle())
            }
        }
    }
}