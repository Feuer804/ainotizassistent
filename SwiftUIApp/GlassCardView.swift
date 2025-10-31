//
//  GlassCardView.swift
//  SwiftUIApp
//
//  Wiederverwendbare Card-Komponente mit Blur-Effekten
//

import SwiftUI

public struct GlassCardView<Content: View>: View {
    private let content: () -> Content
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let blurRadius: CGFloat
    private let shadowRadius: CGFloat
    private let borderOpacity: CGFloat
    private let backgroundOpacity: CGFloat
    private let isInteractive: Bool
    
    public init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        blurRadius: CGFloat = 40,
        shadowRadius: CGFloat = 20,
        borderOpacity: CGFloat = 0.3,
        backgroundOpacity: CGFloat = 0.1,
        isInteractive: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.blurRadius = blurRadius
        self.shadowRadius = shadowRadius
        self.borderOpacity = borderOpacity
        self.backgroundOpacity = backgroundOpacity
        self.isInteractive = isInteractive
    }
    
    public var body: some View {
        content()
            .padding(padding)
            .background(
                Group {
                    // Hintergrund mit Material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(backgroundOpacity))
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(borderOpacity),
                                            Color.white.opacity(borderOpacity * 0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(0.1),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: shadowRadius / 2,
                x: 0,
                y: shadowRadius / 4
            )
            .scaleEffect(isInteractive ? 1.0 : 0.98)
            .animation(.easeOut(duration: 0.2), value: isInteractive)
    }
}

// MARK: - Specialized Card Types
public struct GlassInfoCard<Content: View>: View {
    private let content: () -> Content
    private let accentColor: Color
    private let isDismissible: Bool
    @State private var isVisible = true
    
    public init(
        accentColor: Color = .blue,
        isDismissible: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.accentColor = accentColor
        self.isDismissible = isDismissible
    }
    
    public var body: some View {
        if isVisible {
            GlassCardView(cornerRadius: 16, shadowRadius: 15) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                    
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isDismissible {
                        Button {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isVisible = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

public struct GlassStatsCard<Content: View>: View {
    private let content: () -> Content
    private let title: String
    private let subtitle: String?
    private let accentColor: Color
    
    public init(
        title: String,
        subtitle: String? = nil,
        accentColor: Color = .blue,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
    }
    
    public var body: some View {
        GlassCardView(cornerRadius: 20, padding: 24, shadowRadius: 25) {
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
                    
                    // Accent indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor.opacity(0.6))
                        .frame(width: 4, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                content()
            }
        }
    }
}

public struct GlassChartCard<Content: View>: View {
    private let content: () -> Content
    private let title: String
    private let height: CGFloat
    
    public init(
        title: String,
        height: CGFloat = 200,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.title = title
        self.height = height
    }
    
    public var body: some View {
        GlassCardView(cornerRadius: 20, padding: 20, shadowRadius: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                content()
                    .frame(height: height)
            }
        }
    }
}

// MARK: - Glass Card Grid
public struct GlassCardGrid<Content: View>: View {
    private let columns: [GridItem]
    private let spacing: CGFloat
    private let content: () -> Content
    private let cornerRadius: CGFloat
    
    public init(
        columns: [GridItem] = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ],
        spacing: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.content = content
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            content()
                .glassCardStyle(cornerRadius: cornerRadius)
        }
    }
}

// MARK: - View Extension for Easy Usage
extension View {
    public func glassCardStyle(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        shadowRadius: CGFloat = 15
    ) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(0.1),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
    }
}

// MARK: - Preview
struct GlassCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    GlassCardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Basic Glass Card")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Eine wiederverwendbare Card-Komponente mit Blur-Effekten und Glass-Morphism-Design.")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Button("Aktion") {
                                print("Card Action tapped")
                            }
                            .buttonStyle(GlassButtonStyle())
                            .frame(height: 40)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    GlassInfoCard(accentColor: .green, isDismissible: true) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Erfolgreich!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Die Operation wurde erfolgreich abgeschlossen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    GlassStatsCard(
                        title: "Heutige Aktivität",
                        subtitle: "24. Oktober 2024",
                        accentColor: .blue
                    ) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("1,234")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Schritte")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("89%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Ziel erreicht")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    GlassCardGrid {
                        GlassCardView {
                            VStack {
                                Image(systemName: "star.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                
                                Text("Feature 1")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        GlassCardView {
                            VStack {
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                
                                Text("Feature 2")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}