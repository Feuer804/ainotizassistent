//
//  GlassTabView.swift
//  SwiftUIApp
//
//  Animierte Tab Bar mit Glass-Effekt
//

import SwiftUI

// MARK: - Tab Configuration Model
public struct GlassTabItem: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let systemImage: String
    public let activeSystemImage: String
    public let color: Color
    public let badge: Int?
    
    public init(
        title: String,
        systemImage: String,
        activeSystemImage: String? = nil,
        color: Color = .blue,
        badge: Int? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.activeSystemImage = activeSystemImage ?? systemImage
        self.color = color
        self.badge = badge
    }
    
    public static func == (lhs: GlassTabItem, rhs: GlassTabItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Main Glass Tab View
public struct GlassTabView<Content: View>: View {
    private let tabs: [GlassTabItem]
    private let selectedTab: Int
    private let content: (Int) -> Content
    private let tabHeight: CGFloat
    private let cornerRadius: CGFloat
    private let backgroundOpacity: CGFloat
    private let showLabels: Bool
    
    @State private var animationOffset: CGFloat = 0
    @State private var scaleAnimation: CGFloat = 1.0
    
    public init(
        tabs: [GlassTabItem],
        selectedTab: Int,
        tabHeight: CGFloat = 60,
        cornerRadius: CGFloat = 20,
        backgroundOpacity: CGFloat = 0.1,
        showLabels: Bool = true,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.tabs = tabs
        self.selectedTab = selectedTab
        self.content = content
        self.tabHeight = tabHeight
        self.cornerRadius = cornerRadius
        self.backgroundOpacity = backgroundOpacity
        self.showLabels = showLabels
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main Content
                content(selectedTab)
                    .ignoresSafeArea(edges: [.bottom])
                
                // Glass Tab Bar
                VStack {
                    Spacer()
                    
                    GlassTabBar(
                        tabs: tabs,
                        selectedTab: selectedTab,
                        tabHeight: tabHeight,
                        cornerRadius: cornerRadius,
                        backgroundOpacity: backgroundOpacity,
                        showLabels: showLabels,
                        animationOffset: $animationOffset,
                        scaleAnimation: $scaleAnimation,
                        tabWidth: geometry.size.width / CGFloat(tabs.count)
                    )
                }
            }
        }
    }
}

// MARK: - Glass Tab Bar Component
private struct GlassTabBar: View {
    let tabs: [GlassTabItem]
    let selectedTab: Int
    let tabHeight: CGFloat
    let cornerRadius: CGFloat
    let backgroundOpacity: CGFloat
    let showLabels: Bool
    @Binding var animationOffset: CGFloat
    @Binding var scaleAnimation: CGFloat
    let tabWidth: CGFloat
    
    @State private var tabPositions: [CGFloat] = []
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.0) { index, tab in
                let isSelected = index == selectedTab
                
                TabButton(
                    tab: tab,
                    isSelected: isSelected,
                    showLabels: showLabels,
                    tabWidth: tabWidth
                ) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        animationOffset = tabWidth * CGFloat(index)
                        scaleAnimation = isSelected ? 1.1 : 1.0
                    }
                }
                .frame(width: tabWidth)
                .onAppear {
                    let position = tabWidth * CGFloat(index)
                    tabPositions.append(position)
                }
            }
        }
        .frame(height: tabHeight)
        .background(
            // Glass Background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(backgroundOpacity))
                .background(.ultraThinMaterial)
                .overlay(
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(
                    // Selection Indicator
                    RoundedRectangle(cornerRadius: cornerRadius / 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tabs[safe: selectedTab]?.color.opacity(0.3) ?? .clear,
                                    tabs[safe: selectedTab]?.color.opacity(0.1) ?? .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius / 2)
                                .stroke(
                                    tabs[safe: selectedTab]?.color.opacity(0.5) ?? .clear,
                                    lineWidth: 1
                                )
                        )
                        .offset(x: animationOffset)
                        .frame(width: tabWidth - 8, height: tabHeight - 8)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius / 2))
                        .animation(.easeOut(duration: 0.3), value: selectedTab)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .shadow(
            color: Color.black.opacity(0.15),
            radius: 20,
            x: 0,
            y: -5
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: -2
        )
    }
}

// MARK: - Individual Tab Button
private struct TabButton: View {
    let tab: GlassTabItem
    let isSelected: Bool
    let showLabels: Bool
    let tabWidth: CGFloat
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var scale = 1.0
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon with animated scaling
                Image(systemName: isSelected ? tab.activeSystemImage : tab.systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? tab.color : .secondary)
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                
                // Label (optional)
                if showLabels {
                    Text(tab.title)
                        .font(.caption2)
                        .fontWeight(isSelected ? .semibold : .medium)
                        .foregroundColor(isSelected ? tab.color : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                // Badge
                if let badge = tab.badge, badge > 0 {
                    Text(badge > 99 ? "99+" : "\(badge)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                        .offset(y: -8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: badge)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onChange(of: isSelected) { selected in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                scale = selected ? 1.1 : 1.0
            }
        }
    }
}

// MARK: - Compact Glass Tab View (for iPhone)
public struct CompactGlassTabView<Content: View>: View {
    private let tabs: [GlassTabItem]
    private let selectedTab: Int
    private let content: (Int) -> Content
    
    public init(
        tabs: [GlassTabItem],
        selectedTab: Int,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.tabs = tabs
        self.selectedTab = selectedTab
        self.content = content
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                content(selectedTab)
                    .ignoresSafeArea(edges: [.bottom])
                
                // Compact tab bar (bottom)
                VStack {
                    Spacer()
                    
                    HStack(spacing: 0) {
                        ForEach(Array(tabs.enumerated()), id: \.0) { index, tab in
                            let isSelected = index == selectedTab
                            
                            CompactTabButton(
                                tab: tab,
                                isSelected: isSelected
                            ) {
                                // Handle tab selection
                            }
                            .frame(width: geometry.size.width / CGFloat(tabs.count))
                        }
                    }
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 5)
                    .shadow(
                        color: Color.black.opacity(0.2),
                        radius: 15,
                        x: 0,
                        y: -3
                    )
                }
            }
        }
    }
}

// MARK: - Compact Tab Button
private struct CompactTabButton: View {
    let tab: GlassTabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? tab.activeSystemImage : tab.systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? tab.color : .secondary)
                
                // Small indicator dot
                Circle()
                    .fill(isSelected ? tab.color : .clear)
                    .frame(width: 3, height: 3)
                    .animation(.easeOut(duration: 0.2), value: isSelected)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Preview
struct GlassTabView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTabs = [
            GlassTabItem(title: "Start", systemImage: "house", activeSystemImage: "house.fill", color: .blue),
            GlassTabItem(title: "Suche", systemImage: "magnifyingglass", color: .green),
            GlassTabItem(title: "Favoriten", systemImage: "heart", activeSystemImage: "heart.fill", color: .red, badge: 3),
            GlassTabItem(title: "Einstellungen", systemImage: "gear", color: .orange)
        ]
        
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GlassTabView(
                tabs: sampleTabs,
                selectedTab: 0,
                tabHeight: 70,
                showLabels: true
            ) { selectedIndex in
                VStack(spacing: 20) {
                    Text("Aktueller Tab: \(sampleTabs[selectedIndex].title)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Button("Nächster Tab") {
                        // Implement tab switching logic
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
        }
    }
}