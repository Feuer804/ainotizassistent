//
//  GlassNavigationStack.swift
//  SwiftUIApp
//
//  Navigation mit Glass-Transitions
//

import SwiftUI

// MARK: - Navigation Configuration
public struct GlassNavigationConfiguration {
    let cornerRadius: CGFloat
    let backgroundOpacity: CGFloat
    let borderOpacity: CGFloat
    let shadowRadius: CGFloat
    let transitionDuration: Double
    let showBackButton: Bool
    let showTitle: Bool
    
    public init(
        cornerRadius: CGFloat = 20,
        backgroundOpacity: CGFloat = 0.1,
        borderOpacity: CGFloat = 0.3,
        shadowRadius: CGFloat = 15,
        transitionDuration: Double = 0.3,
        showBackButton: Bool = true,
        showTitle: Bool = true
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundOpacity = backgroundOpacity
        self.borderOpacity = borderOpacity
        self.shadowRadius = shadowRadius
        self.transitionDuration = transitionDuration
        self.showBackButton = showBackButton
        self.showTitle = showTitle
    }
}

// MARK: - Navigation Item Model
public struct GlassNavigationItem: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let systemImage: String?
    public let accessoryImage: String?
    public let tintColor: Color
    public let badge: Int?
    
    public init(
        title: String,
        systemImage: String? = nil,
        accessoryImage: String? = nil,
        tintColor: Color = .blue,
        badge: Int? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accessoryImage = accessoryImage
        self.tintColor = tintColor
        self.badge = badge
    }
    
    public static func == (lhs: GlassNavigationItem, rhs: GlassNavigationItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Glass Navigation Bar
public struct GlassNavigationBar: View {
    private let title: String
    private let configuration: GlassNavigationConfiguration
    private let leftAction: (() -> Void)?
    private let rightAction: (() -> Void)?
    private let leftImage: String?
    private let rightImage: String?
    private let tintColor: Color
    
    public init(
        title: String,
        configuration: GlassNavigationConfiguration = GlassNavigationConfiguration(),
        leftAction: (() -> Void)? = nil,
        rightAction: (() -> Void)? = nil,
        leftImage: String? = nil,
        rightImage: String? = nil,
        tintColor: Color = .blue
    ) {
        self.title = title
        self.configuration = configuration
        self.leftAction = leftAction
        self.rightAction = rightAction
        self.leftImage = leftImage
        self.rightImage = rightImage
        self.tintColor = tintColor
    }
    
    public var body: some View {
        HStack {
            // Left Button
            if let leftAction = leftAction, let leftImage = leftImage {
                Button(action: leftAction) {
                    Image(systemName: leftImage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(tintColor)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .background(.ultraThinMaterial)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.white.opacity(0.4),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: 8,
                            x: 0,
                            y: 2
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(0.95)
            }
            
            Spacer()
            
            // Title
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .transition(.opacity.combined(with: .scale))
            }
            
            Spacer()
            
            // Right Button
            if let rightAction = rightAction, let rightImage = rightImage {
                Button(action: rightAction) {
                    Image(systemName: rightImage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(tintColor)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .background(.ultraThinMaterial)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.white.opacity(0.4),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: 8,
                            x: 0,
                            y: 2
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(0.95)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: configuration.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(configuration.backgroundOpacity),
                            Color.white.opacity(configuration.backgroundOpacity * 0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: configuration.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(configuration.borderOpacity),
                            Color.white.opacity(configuration.borderOpacity * 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
        .shadow(
            color: Color.black.opacity(0.1),
            radius: configuration.shadowRadius,
            x: 0,
            y: configuration.shadowRadius / 4
        )
        .padding(.horizontal, 16)
        .animation(.easeOut(duration: configuration.transitionDuration), value: title)
    }
}

// MARK: - Glass Navigation Stack
public struct GlassNavigationStack<Content: View>: View {
    private let configuration: GlassNavigationConfiguration
    private let content: () -> Content
    @State private var navigationTitle: String = ""
    @State private var navigationTint: Color = .blue
    @State private var showNavigationBar: Bool = true
    
    public init(
        configuration: GlassNavigationConfiguration = GlassNavigationConfiguration(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.configuration = configuration
        self.content = content
    }
    
    public var body: some View {
        NavigationStack {
            content()
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
                .onPreferenceChange(GlassNavigationTitlePreferenceKey.self) { value in
                    navigationTitle = value ?? ""
                }
                .onPreferenceChange(GlassNavigationTintPreferenceKey.self) { value in
                    navigationTint = value ?? .blue
                }
                .onPreferenceChange(GlassNavigationVisibilityPreferenceKey.self) { value in
                    showNavigationBar = value ?? true
                }
        }
        .overlay(alignment: .top) {
            if showNavigationBar && !navigationTitle.isEmpty {
                GlassNavigationBar(
                    title: navigationTitle,
                    configuration: configuration,
                    tintColor: navigationTint
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Navigation Title Preference Keys
struct GlassNavigationTitlePreferenceKey: PreferenceKey {
    static var defaultValue: String? = nil
    
    static func reduce(value: inout String?, nextValue: () -> String?) {
        value = nextValue() ?? value
    }
}

struct GlassNavigationTintPreferenceKey: PreferenceKey {
    static var defaultValue: Color? = nil
    
    static func reduce(value: inout Color?, nextValue: () -> Color?) {
        value = nextValue() ?? value
    }
}

struct GlassNavigationVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: Bool? = nil
    
    static func reduce(value: inout Bool?, nextValue: () -> Bool?) {
        value = nextValue() ?? value
    }
}

// MARK: - View Modifiers for Navigation
extension View {
    public func glassNavigationTitle(_ title: String) -> some View {
        self.preference(key: GlassNavigationTitlePreferenceKey.self, value: title)
    }
    
    public func glassNavigationTint(_ color: Color) -> some View {
        self.preference(key: GlassNavigationTintPreferenceKey.self, value: color)
    }
    
    public func glassNavigationBar(_ visible: Bool) -> some View {
        self.preference(key: GlassNavigationVisibilityPreferenceKey.self, value: visible)
    }
}

// MARK: - Glass Detail View (with Back Navigation)
public struct GlassDetailView<Content: View>: View {
    private let title: String
    private let configuration: GlassNavigationConfiguration
    private let tintColor: Color
    private let content: () -> Content
    @Environment(\.dismiss) private var dismiss
    
    public init(
        title: String,
        tintColor: Color = .blue,
        configuration: GlassNavigationConfiguration = GlassNavigationConfiguration(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.tintColor = tintColor
        self.configuration = configuration
        self.content = content
    }
    
    public var body: some View {
        ScrollView {
            content()
                .padding()
                .glassNavigationTitle(title)
                .glassNavigationTint(tintColor)
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.02), Color.purple.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Glass List View with Navigation
public struct GlassListView<Content: View>: View {
    private let title: String
    private let items: [GlassNavigationItem]
    private let tintColor: Color
    private let configuration: GlassNavigationConfiguration
    private let content: (GlassNavigationItem) -> Content
    @State private var searchText = ""
    
    public init(
        title: String,
        items: [GlassNavigationItem],
        tintColor: Color = .blue,
        configuration: GlassNavigationConfiguration = GlassNavigationConfiguration(),
        @ViewBuilder content: @escaping (GlassNavigationItem) -> Content
    ) {
        self.title = title
        self.items = items
        self.tintColor = tintColor
        self.configuration = configuration
        self.content = content
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items.filter { item in
                    searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)
                }) { item in
                    GlassListItem(item: item) {
                        content(item)
                    }
                }
            }
            .padding()
            .glassNavigationTitle(title)
            .glassNavigationTint(tintColor)
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.02), Color.purple.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
}

// MARK: - Glass List Item
private struct GlassListItem<Content: View>: View {
    let item: GlassNavigationItem
    let content: () -> Content
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            if let systemImage = item.systemImage {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(item.tintColor)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        item.tintColor.opacity(0.2),
                                        item.tintColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                item.tintColor.opacity(0.4),
                                lineWidth: 1
                            )
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                content()
                
                // Accessory Image and Badge
                HStack {
                    if let accessoryImage = item.accessoryImage {
                        Image(systemName: accessoryImage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let badge = item.badge, badge > 0 {
                        Text(badge > 99 ? "99+" : "\(badge)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red))
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
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
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: isHovered ? 10 : 5,
            x: 0,
            y: isHovered ? 4 : 2
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .animation(.easeOut(duration: 0.2), value: isHovered)
    }
}

// MARK: - Glass Tab Navigation
public struct GlassTabNavigation: View {
    private let tabs: [GlassNavigationItem]
    @Binding private var selectedTab: Int
    @State private var animationOffset: CGFloat = 0
    
    public init(
        tabs: [GlassNavigationItem],
        selectedTab: Binding<Int>
    ) {
        self.tabs = tabs
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.0) { index, tab in
                TabButton(
                    tab: tab,
                    isSelected: index == selectedTab
                ) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        selectedTab = index
                        animationOffset = CGFloat(index) * 60
                    }
                }
                .frame(width: 60)
            }
        }
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
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
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    tabs[safe: selectedTab]?.tintColor.opacity(0.3) ?? .clear
                )
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            tabs[safe: selectedTab]?.tintColor.opacity(0.5) ?? .clear,
                            lineWidth: 1
                        )
                )
                .offset(x: animationOffset)
                .frame(width: 52, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

// MARK: - Tab Button
private struct TabButton: View {
    let tab: GlassNavigationItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let systemImage = tab.systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? tab.tintColor : .secondary)
                }
                
                // Badge
                if let badge = tab.badge, badge > 0 {
                    Text(badge > 99 ? "99+" : "\(badge)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.red))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
struct GlassNavigationStack_Previews: PreviewProvider {
    @State private var selectedTab = 0
    @State private var showDetail = false
    
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GlassNavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Navigation Tab Example
                        GlassTabNavigation(
                            tabs: [
                                GlassNavigationItem(title: "Home", systemImage: "house", tintColor: .blue, badge: 2),
                                GlassNavigationItem(title: "Search", systemImage: "magnifyingglass", tintColor: .green),
                                GlassNavigationItem(title: "Settings", systemImage: "gear", tintColor: .orange),
                                GlassNavigationItem(title: "Profile", systemImage: "person.circle", tintColor: .purple)
                            ],
                            selectedTab: $selectedTab
                        )
                        
                        // List Navigation Example
                        GlassListView(
                            title: "Kategorien",
                            items: [
                                GlassNavigationItem(
                                    title: "Design",
                                    systemImage: "palette",
                                    tintColor: .pink,
                                    accessoryImage: "chevron.right",
                                    badge: 5
                                ),
                                GlassNavigationItem(
                                    title: "Entwicklung",
                                    systemImage: "hammer",
                                    tintColor: .blue,
                                    accessoryImage: "chevron.right"
                                ),
                                GlassNavigationItem(
                                    title: "Marketing",
                                    systemImage: "megaphone",
                                    tintColor: .orange,
                                    accessoryImage: "chevron.right"
                                ),
                                GlassNavigationItem(
                                    title: "Verkauf",
                                    systemImage: "cart",
                                    tintColor: .green,
                                    accessoryImage: "chevron.right",
                                    badge: 3
                                )
                            ]
                        ) { item in
                            Text(item.title)
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .navigationDestination(isPresented: $showDetail) {
                            GlassDetailView(
                                title: item.title,
                                tintColor: .blue
                            ) {
                                VStack(spacing: 20) {
                                    Text("Detailansicht für \(item.title)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("Dies ist eine detaillierte Ansicht mit Glass-Design-Elementen.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button("Zurück") {
                                        showDetail = false
                                    }
                                    .buttonStyle(GlassButtonStyle())
                                }
                            }
                        }
                        
                        Button("Detailansicht öffnen") {
                            showDetail = true
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    .padding()
                }
                .glassNavigationTitle("Glass Navigation")
                .glassNavigationTint(.blue)
            }
        }
    }
}