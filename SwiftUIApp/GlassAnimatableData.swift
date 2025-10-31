//
//  GlassAnimatableData.swift
//  SwiftUIApp
//
//  Für animierte Arrays und Collections
//

import SwiftUI

// MARK: - Animatable Data Protocol
public protocol GlassAnimatableData: Equatable {
    associatedtype AnimatableType: VectorArithmetic
    var animatableData: AnimatableType { get set }
}

// MARK: - Glass Animatable Array
public struct GlassAnimatableArray<T: GlassAnimatableData & Identifiable>: MutableCollection, RandomAccessCollection {
    private var items: [T]
    
    public init(_ items: [T] = []) {
        self.items = items
    }
    
    public subscript(index: Int) -> T {
        get { items[index] }
        set { items[index] = newValue }
    }
    
    public var startIndex: Int { items.startIndex }
    public var endIndex: Int { items.endIndex }
    public func index(after i: Int) -> Int { items.index(after: i) }
    public func index(before i: Int) -> Int { items.index(before: i) }
    public func index(_ i: Int, offsetBy distance: Int) -> Int { items.index(i, offsetBy: distance) }
    public func distance(from start: Int, to end: Int) -> Int { items.distance(from: start, to: end) }
    
    // MARK: - Array Operations with Animation
    public mutating func append(_ item: T) {
        items.append(item)
    }
    
    public mutating func insert(_ item: T, at index: Int) {
        items.insert(item, at: index)
    }
    
    public mutating func remove(at index: Int) -> T {
        return items.remove(at: index)
    }
    
    public mutating func removeAll() {
        items.removeAll()
    }
    
    public mutating func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
    
    public mutating func appendWithAnimation(_ item: T, animationDuration: Double = 0.3) {
        var animatedItem = item
        animatedItem.animatableData = 0
        
        items.append(animatedItem)
        
        // Trigger animation after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: animationDuration)) {
                animatedItem.animatableData = 1
            }
        }
    }
    
    public mutating func removeWithAnimation(at index: Int, animationDuration: Double = 0.3) {
        guard items.indices.contains(index) else { return }
        
        var item = items[index]
        withAnimation(.easeIn(duration: animationDuration)) {
            item.animatableData = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            items.remove(at: index)
        }
    }
}

// MARK: - Glass Animatable Item Base
public struct GlassAnimatableItem: Identifiable, GlassAnimatableData {
    public let id: UUID
    public var animatableData: Double
    
    public init(id: UUID = UUID(), animatableData: Double = 1.0) {
        self.id = id
        self.animatableData = animatableData
    }
}

// MARK: - Glass Card Animatable Item
public struct GlassCardAnimatableItem: GlassAnimatableItem, Equatable {
    let title: String
    let subtitle: String?
    let icon: String?
    let color: Color
    let badge: Int?
    let opacity: Double
    let scale: Double
    let offset: CGSize
    
    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        color: Color = .blue,
        badge: Int? = nil,
        animatableData: Double = 1.0
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.badge = badge
        self.opacity = animatableData
        self.scale = 0.8 + (animatableData * 0.2)
        self.offset = CGSize(
            width: (1 - animatableData) * 50,
            height: (1 - animatableData) * 20
        )
        super.init(id: id, animatableData: animatableData)
    }
    
    public static func == (lhs: GlassCardAnimatableItem, rhs: GlassCardAnimatableItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Glass Grid Animatable Collection
public struct GlassGridAnimatableCollection<T: GlassAnimatableItem & Identifiable>: MutableCollection, RandomAccessCollection {
    private var items: [T]
    private let columns: Int
    
    public init(_ items: [T] = [], columns: Int = 2) {
        self.items = items
        self.columns = columns
    }
    
    public subscript(index: Int) -> T {
        get { items[index] }
        set { items[index] = newValue }
    }
    
    public var startIndex: Int { items.startIndex }
    public var endIndex: Int { items.endIndex }
    public func index(after i: Int) -> Int { items.index(after: i) }
    public func index(before i: Int) -> Int { items.index(before: i) }
    
    public var rowCount: Int {
        (items.count + columns - 1) / columns
    }
    
    public func itemForRow(_ row: Int, column: Int) -> T? {
        let index = row * columns + column
        return items.indices.contains(index) ? items[index] : nil
    }
    
    // MARK: - Grid Operations with Animation
    public mutating func insertWithGridAnimation(_ item: T, at index: Int, animationDuration: Double = 0.4) {
        var animatedItem = item
        animatedItem.animatableData = 0
        
        items.insert(animatedItem, at: index)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animatedItem.animatableData = 1
            }
        }
    }
    
    public mutating func removeWithGridAnimation(at index: Int, animationDuration: Double = 0.3) {
        guard items.indices.contains(index) else { return }
        
        var item = items[index]
        withAnimation(.easeInOut(duration: animationDuration)) {
            item.animatableData = 0
            item.scale = 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            items.remove(at: index)
        }
    }
}

// MARK: - Glass List with Animated Items
public struct GlassAnimatableList<T: GlassAnimatableItem & Identifiable>: View {
    @State private var items: GlassAnimatableArray<T> = []
    private let spacing: CGFloat
    private let animationDuration: Double
    private let itemView: (T) -> AnyView
    
    public init(
        spacing: CGFloat = 16,
        animationDuration: Double = 0.3,
        @ViewBuilder itemView: @escaping (T) -> some View
    ) {
        self.spacing = spacing
        self.animationDuration = animationDuration
        self.itemView = { AnyView(itemView($0)) }
    }
    
    public var body: some View {
        LazyVStack(spacing: spacing) {
            ForEach(Array(items.enumerated()), id: \.0) { index, item in
                GlassAnimatedItemView(
                    item: item,
                    itemView: itemView(item),
                    animationDuration: animationDuration
                )
                .onAppear {
                    // Animate item entrance
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                        var updatedItem = item
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            updatedItem.animatableData = 1
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Public Methods
    public mutating func addItem(_ item: T) {
        items.appendWithAnimation(item, animationDuration: animationDuration)
    }
    
    public mutating func removeItem(at index: Int) {
        items.removeWithAnimation(at: index, animationDuration: animationDuration)
    }
    
    public mutating func updateItems(_ newItems: [T]) {
        withAnimation(.easeInOut(duration: animationDuration)) {
            items = GlassAnimatableArray(newItems)
        }
    }
}

// MARK: - Individual Animated Item View
private struct GlassAnimatedItemView<Content: View>: View {
    let item: any GlassAnimatableItem & Identifiable
    let itemView: AnyView
    let animationDuration: Double
    @State private var isVisible = false
    
    var body: some View {
        itemView
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .offset(x: isVisible ? 0 : 50)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                    isVisible = true
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
    }
}

// MARK: - Glass Grid with Animated Items
public struct GlassAnimatableGrid<T: GlassCardAnimatableItem & Identifiable>: View {
    @State private var items: GlassGridAnimatableCollection<T> = []
    private let columns: Int
    private let spacing: CGFloat
    private let animationDuration: Double
    private let cardView: (T) -> AnyView
    
    public init(
        columns: Int = 2,
        spacing: CGFloat = 16,
        animationDuration: Double = 0.4,
        @ViewBuilder cardView: @escaping (T) -> some View
    ) {
        self.columns = columns
        self.spacing = spacing
        self.animationDuration = animationDuration
        self.cardView = { AnyView(cardView($0)) }
    }
    
    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(Array(items.enumerated()), id: \.0) { index, item in
                GlassAnimatedGridItemView(
                    item: item,
                    cardView: cardView(item),
                    animationDuration: animationDuration
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                        var updatedItem = item
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                            updatedItem.animatableData = 1
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Public Methods
    public mutating func addItem(_ item: T) {
        items.insertWithGridAnimation(item, at: items.endIndex, animationDuration: animationDuration)
    }
    
    public mutating func removeItem(at index: Int) {
        items.removeWithGridAnimation(at: index, animationDuration: animationDuration)
    }
    
    public mutating func updateItems(_ newItems: [T]) {
        withAnimation(.easeInOut(duration: animationDuration)) {
            items = GlassGridAnimatableCollection(newItems, columns: columns)
        }
    }
}

// MARK: - Individual Grid Item View
private struct GlassAnimatedGridItemView<Content: View>: View {
    let item: any GlassCardAnimatableItem & Identifiable
    let cardView: AnyView
    let animationDuration: Double
    @State private var animationScale: CGFloat = 0.8
    @State private var animationOpacity: Double = 0
    @State private var animationOffset: CGFloat = 20
    
    var body: some View {
        cardView
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
            .offset(y: animationOffset)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                    animationScale = 1.0
                    animationOpacity = 1.0
                    animationOffset = 0.0
                }
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .move(edge: .top)),
                removal: .scale.combined(with: .move(edge: .bottom))
            ))
    }
}

// MARK: - Glass Staggered Animation Collection
public struct GlassStaggeredCollection<T: GlassAnimatableItem & Identifiable>: View {
    @State private var items: [T] = []
    private let columns: Int
    private let spacing: CGFloat
    private let staggerDelay: Double
    private let itemView: (T) -> AnyView
    
    public init(
        columns: Int = 3,
        spacing: CGFloat = 12,
        staggerDelay: Double = 0.1,
        @ViewBuilder itemView: @escaping (T) -> some View
    ) {
        self.columns = columns
        self.spacing = spacing
        self.staggerDelay = staggerDelay
        self.itemView = { AnyView(itemView($0)) }
    }
    
    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(Array(items.enumerated()), id: \.0) { index, item in
                GlassStaggeredItemView(
                    item: item,
                    itemView: itemView(item),
                    delay: Double(index) * staggerDelay
                )
            }
        }
        .padding()
    }
    
    // MARK: - Public Methods
    public mutating func updateItems(_ newItems: [T]) {
        withAnimation(.easeInOut(duration: 0.5)) {
            items = newItems
        }
    }
}

// MARK: - Staggered Item View
private struct GlassStaggeredItemView<Content: View>: View {
    let item: any GlassAnimatableItem & Identifiable
    let itemView: AnyView
    let delay: Double
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var rotation: Double = -5
    
    var body: some View {
        itemView
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    scale = 1.0
                    opacity = 1.0
                    rotation = 0.0
                }
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity).combined(with: .slide),
                removal: .scale.combined(with: .opacity)
            ))
    }
}

// MARK: - Glass Animated Counter
public struct GlassAnimatedCounter: View {
    @State private var currentValue: Double = 0
    private let targetValue: Double
    private let duration: Double
    private let formatter: (Double) -> String
    
    public init(
        targetValue: Double,
        duration: Double = 1.0,
        formatter: @escaping (Double) -> String = { "\(Int($0))" }
    ) {
        self.targetValue = targetValue
        self.duration = duration
        self.formatter = formatter
    }
    
    public var body: some View {
        Text(formatter(currentValue))
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    currentValue = targetValue
                }
            }
    }
}

// MARK: - Glass Loading Animation Collection
public struct GlassLoadingAnimation: View {
    private let count: Int
    private let size: CGFloat
    private let color: Color
    private let spacing: CGFloat
    
    @State private var animationPhases: [Double] = []
    
    public init(
        count: Int = 5,
        size: CGFloat = 12,
        color: Color = .blue,
        spacing: CGFloat = 4
    ) {
        self.count = count
        self.size = size
        self.color = color
        self.spacing = spacing
        _animationPhases = State(initialValue: Array(repeating: 0.3, count: count))
    }
    
    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(animationPhases[index]),
                                color.opacity(animationPhases[index] * 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(
                        color: color.opacity(0.5 * animationPhases[index]),
                        radius: animationPhases[index] * 10,
                        x: 0,
                        y: 0
                    )
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                animationPhases = animationPhases.map { phase in
                    if phase > 0.8 {
                        return 0.3
                    } else {
                        return min(phase + 0.3, 1.0)
                    }
                }
            }
        }
    }
}

// MARK: - Glass Fade Transition Modifier
extension View {
    public func glassFadeTransition(duration: Double = 0.3) -> some View {
        self
            .opacity(0)
            .offset(y: 20)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    self.opacity = 1
                    self.offset = CGSize.zero
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    public func glassSlideTransition(edge: Edge = .trailing, duration: Double = 0.3) -> some View {
        self
            .offset(x: edge == .leading ? -50 : edge == .trailing ? 50 : 0)
            .opacity(0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.offset = CGSize.zero
                    self.opacity = 1
                }
            }
            .transition(.move(edge: edge).combined(with: .opacity))
    }
}

// MARK: - Preview
struct GlassAnimatableData_Previews: PreviewProvider {
    @State private var listItems = GlassAnimatableArray<GlassCardAnimatableItem>()
    @State private var gridItems = GlassGridAnimatableCollection<GlassCardAnimatableItem>()
    
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
                    // Animatable List
                    Text("Animierte Liste")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    var listPreview = GlassAnimatableList { item in
                        GlassCardView {
                            HStack {
                                if let icon = item.icon {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(item.color)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    if let subtitle = item.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if let badge = item.badge, badge > 0 {
                                    Text("\(badge)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.red))
                                }
                            }
                        }
                    }
                    
                    // Animatable Grid
                    Text("Animiertes Grid")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    var gridPreview = GlassAnimatableGrid { item in
                        GlassCardView {
                            VStack(spacing: 12) {
                                if let icon = item.icon {
                                    Image(systemName: icon)
                                        .font(.title)
                                        .foregroundColor(item.color)
                                }
                                
                                Text(item.title)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                if let subtitle = item.subtitle {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Loading Animation
                    Text("Lade-Animation")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    GlassLoadingAnimation(count: 5, color: .blue)
                    
                    // Animated Counter
                    Text("Animierter Zähler")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    GlassAnimatedCounter(targetValue: 1234)
                    
                    // Staggered Collection
                    Text("Gestaffelte Animation")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    var staggeredPreview = GlassStaggeredCollection { item in
                        GlassCardView {
                            VStack {
                                if let icon = item.icon {
                                    Image(systemName: icon)
                                        .font(.title)
                                        .foregroundColor(item.color)
                                }
                                
                                Text(item.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    // Demo Controls
                    HStack(spacing: 16) {
                        Button("Artikel hinzufügen") {
                            let newItem = GlassCardAnimatableItem(
                                title: "Neuer Artikel",
                                subtitle: "Hinzugefügt: \(Date().formatted(.dateTime.hour().minute()))",
                                icon: "plus.circle.fill",
                                color: .green
                            )
                            listPreview.addItem(newItem)
                            gridPreview.addItem(newItem)
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button("Artikel entfernen") {
                            if !listPreview.items.isEmpty {
                                listPreview.removeItem(at: 0)
                                gridPreview.removeItem(at: 0)
                            }
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
}