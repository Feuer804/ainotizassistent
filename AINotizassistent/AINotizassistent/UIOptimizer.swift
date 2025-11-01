import SwiftUI
import UIKit
import os.log
import Combine

/// UI-Performance-Optimierung für smooth rendering und effiziente UI-Updates
@available(iOS 13.0, *)
class UIOptimizer: ObservableObject {
    static let shared = UIOptimizer()
    
    private let logger = os.Logger(subsystem: "com.minimax.AINotizassistent", category: "UI")
    
    // UI Performance Metrics
    @Published private(set) var uiMetrics = UIPerformanceMetrics()
    @Published private(set) var frameRate: Double = 60.0
    @Published private(set) var isLowPerformanceMode = false
    
    // Animation Management
    private lazy var animationManager = AnimationManager()
    private lazy var listOptimizer = ListOptimizer()
    private lazy var imageLoader = AsyncImageLoader()
    
    // View Caching
    private let viewCache = LRUCache<String, Any>(capacity: 50)
    private var renderingQueue = DispatchQueue(label: "ui.rendering", qos: .userInitiated)
    
    // Combine Publishers for reactive updates
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    func optimizeForLowEndDevice() {
        isLowPerformanceMode = true
        applyLowPerformanceSettings()
        logger.info("Applied low-end device optimizations")
    }
    
    func optimizeForHighEndDevice() {
        isLowPerformanceMode = false
        applyHighPerformanceSettings()
        logger.info("Applied high-end device optimizations")
    }
    
    func optimizeListView<Content: View>(
        _ content: Content,
        estimatedRowHeight: CGFloat = 100,
        maxVisibleRows: Int = 20
    ) -> some View {
        return listOptimizer.optimizeList(content, estimatedRowHeight: estimatedRowHeight, maxVisibleRows: maxVisibleRows)
    }
    
    func preloadImages(_ urls: [URL]) async {
        await imageLoader.preloadImages(urls)
    }
    
    func cancelImagePreloading() {
        imageLoader.cancelAllPreloading()
    }
    
    func optimizeView<C: View>(_ view: C) -> some View {
        let viewID = "\(type(of: view))"
        
        // Check cache first
        if let cachedView = viewCache.value(forKey: viewID) as? C {
            return cachedView
        }
        
        // Cache the view if it's not too large
        let estimatedSize = estimateViewSize(view)
        if estimatedSize < 10000 { // Less than 10KB
            viewCache.set(view, forKey: viewID)
        }
        
        return view
    }
    
    func trackAnimationPerformance(_ animationName: String, duration: TimeInterval) {
        let fps = 1.0 / duration
        uiMetrics.frameTimeMeasurements.append(AnimationMeasurement(
            name: animationName,
            duration: duration,
            fps: fps,
            timestamp: Date()
        ))
        
        // Update average FPS
        updateAverageFrameRate()
        
        // Log performance warnings
        if fps < 55 {
            logger.warning("Low animation FPS for \(animationName): \(String(format: "%.1f", fps))")
        }
    }
    
    func enableSmoothScrolling() {
        // Enable smooth scrolling optimizations
        listOptimizer.enableSmoothScrolling()
        logger.info("Smooth scrolling enabled")
    }
    
    func disableComplexAnimations() {
        // Disable complex animations for better performance
        animationManager.disableComplexAnimations()
        logger.info("Complex animations disabled")
    }
    
    func optimizeForMemory() {
        // Clear view cache periodically
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.viewCache.clear()
        }
    }
    
    func getMemoryEfficientImage(url: String, completion: @escaping (UIImage?) -> Void) {
        imageLoader.loadImage(url: URL(string: url)!, completion: completion)
    }
    
    // MARK: - Private Methods
    private func applyLowPerformanceSettings() {
        // Reduce animation quality
        animationManager.setAnimationQuality(.low)
        
        // Enable aggressive caching
        listOptimizer.setCacheSize(100)
        
        // Reduce image quality
        imageLoader.setMaxConcurrentDownloads(2)
        
        // Disable expensive visual effects
        disableExpensiveEffects()
        
        uiMetrics.lowPerformanceMode = true
    }
    
    private func applyHighPerformanceSettings() {
        // Enable full animation quality
        animationManager.setAnimationQuality(.high)
        
        // Standard caching
        listOptimizer.setCacheSize(50)
        
        // Standard image loading
        imageLoader.setMaxConcurrentDownloads(5)
        
        // Enable all visual effects
        enableAllEffects()
        
        uiMetrics.lowPerformanceMode = false
    }
    
    private func updateAverageFrameRate() {
        let recentMeasurements = uiMetrics.frameTimeMeasurements.suffix(30)
        let totalFPS = recentMeasurements.map { $0.fps }.reduce(0, +)
        frameRate = totalFPS / Double(recentMeasurements.count)
        
        uiMetrics.averageFrameRate = frameRate
    }
    
    private func estimateViewSize<C: View>(_ view: C) -> Int {
        // Rough estimation of view complexity
        // This would need more sophisticated analysis in production
        return MemoryLayout.size(ofValue: view)
    }
    
    private func disableExpensiveEffects() {
        // Disable expensive visual effects like blur, shadows, etc.
        logger.debug("Disabled expensive visual effects")
    }
    
    private func enableAllEffects() {
        // Enable all visual effects
        logger.debug("Enabled all visual effects")
    }
}

// MARK: - Animation Management
@available(iOS 13.0, *)
class AnimationManager {
    private var animationQuality: AnimationQuality = .medium
    private var disabledAnimations: Set<String> = []
    
    func setAnimationQuality(_ quality: AnimationQuality) {
        animationQuality = quality
    }
    
    func disableComplexAnimations() {
        disabledAnimations.insert("complex-transitions")
        disabledAnimations.insert("heavy-animations")
    }
    
    func isAnimationEnabled(_ animationName: String) -> Bool {
        return !disabledAnimations.contains(animationName) && animationQuality != .disabled
    }
    
    func getOptimalAnimationDuration(for effect: AnimationEffect) -> TimeInterval {
        let baseDuration: TimeInterval = {
            switch effect {
            case .fade: return 0.2
            case .slide: return 0.3
            case .scale: return 0.25
            case .rotation: return 0.4
            case .complex: return 0.5
            }
        }()
        
        switch animationQuality {
        case .high:
            return baseDuration
        case .medium:
            return baseDuration * 0.8
        case .low:
            return baseDuration * 0.6
        case .disabled:
            return 0.1
        }
    }
    
    func optimizeAnimation<C: View>(
        _ view: C,
        animation: AnimationEffect,
        duration: TimeInterval? = nil
    ) -> some View {
        let optimalDuration = duration ?? getOptimalAnimationDuration(for: animation)
        
        if isAnimationEnabled(animation.rawValue) {
            return view
                .animation(.easeInOut(duration: optimalDuration), value: true)
        } else {
            return view.animation(nil, value: true)
        }
    }
}

@available(iOS 13.0, *)
enum AnimationQuality {
    case high
    case medium
    case low
    case disabled
}

@available(iOS 13.0, *)
enum AnimationEffect: String {
    case fade = "fade"
    case slide = "slide"
    case scale = "scale"
    case rotation = "rotation"
    case complex = "complex"
}

// MARK: - List Optimization
@available(iOS 13.0, *)
class ListOptimizer {
    private var cacheSize = 50
    private var isSmoothScrollingEnabled = false
    
    func optimizeList<Content: View>(
        _ content: Content,
        estimatedRowHeight: CGFloat,
        maxVisibleRows: Int
    ) -> some View {
        return content
            .frame(height: estimatedRowHeight)
            .id(UUID()) // Force view recycling
    }
    
    func enableSmoothScrolling() {
        isSmoothScrollingEnabled = true
    }
    
    func setCacheSize(_ size: Int) {
        cacheSize = size
    }
    
    func getCachedCell<Content: View>(
        for key: String,
        content: Content
    ) -> Content? {
        // Simplified caching logic
        // In production, this would use a more sophisticated caching mechanism
        return content
    }
}

// MARK: - Async Image Loading
@available(iOS 13.0, *)
class AsyncImageLoader {
    private let cache = NSCache<NSString, UIImage>()
    private var maxConcurrentDownloads = 5
    private var activeDownloads = Set<URL>()
    
    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func loadImage(url: URL, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedImage = cache.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage)
            return
        }
        
        // Prevent duplicate downloads
        guard !activeDownloads.contains(url) else {
            completion(nil)
            return
        }
        
        activeDownloads.insert(url)
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            self.activeDownloads.remove(url)
            
            if let error = error {
                print("Image download error: \(error)")
                completion(nil)
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                self.cache.setObject(image, forKey: url.absoluteString as NSString)
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    func preloadImages(_ urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    await self.preloadImage(url)
                }
            }
        }
    }
    
    private func preloadImage(_ url: URL) async {
        await withCheckedContinuation { continuation in
            loadImage(url: url) { _ in
                continuation.resume()
            }
        }
    }
    
    func cancelAllPreloading() {
        activeDownloads.removeAll()
    }
    
    func setMaxConcurrentDownloads(_ count: Int) {
        maxConcurrentDownloads = count
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - View Optimization
@available(iOS 13.0, *)
struct OptimizedImage<Placeholder: View>: View {
    private let url: URL
    private let placeholder: Placeholder
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(url: URL, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder()
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                placeholder
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        isLoading = true
        UIOptimizer.shared.getMemoryEfficientImage(url: url.absoluteString) { loadedImage in
            DispatchQueue.main.async {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}

@available(iOS 13.0, *)
struct OptimizedList<Item: Identifiable, Content: View>: View {
    private let items: [Item]
    private let content: (Item) -> Content
    @State private var visibleItems: [Item] = []
    private let maxVisibleRows: Int
    
    init(
        items: [Item],
        maxVisibleRows: Int = 20,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.content = content
        self.maxVisibleRows = maxVisibleRows
        _visibleItems = State(initialValue: Array(items.prefix(maxVisibleRows)))
    }
    
    var body: some View {
        List {
            ForEach(visibleItems) { item in
                content(item)
                    .onAppear {
                        if item == visibleItems.last {
                            loadMoreItems()
                        }
                    }
            }
        }
        .onAppear {
            UIOptimizer.shared.enableSmoothScrolling()
        }
    }
    
    private func loadMoreItems() {
        let currentCount = visibleItems.count
        let nextItems = Array(items.dropFirst(currentCount).prefix(10))
        
        if !nextItems.isEmpty {
            visibleItems.append(contentsOf: nextItems)
        }
    }
}

@available(iOS 13.0, *)
struct MemoryEfficientText: View {
    private let text: String
    private let fontSize: CGFloat
    @State private var isTruncated = false
    
    init(_ text: String, fontSize: CGFloat = 14) {
        self.text = text
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .lineLimit(isTruncated ? 3 : nil)
            .truncationMode(.tail)
            .onAppear {
                checkIfTruncationNeeded()
            }
    }
    
    private func checkIfTruncationNeeded() {
        // Simplified logic to determine if text should be truncated
        // In production, this would use more sophisticated text measurement
        isTruncated = text.count > 200
    }
}

// MARK: - Supporting Types
@available(iOS 13.0, *)
struct UIPerformanceMetrics {
    var frameTimeMeasurements: [AnimationMeasurement] = []
    var averageFrameRate: Double = 60.0
    var lastUpdate: Date = Date()
    var lowPerformanceMode: Bool = false
    var renderTimes: [TimeInterval] = []
    var cacheHitRate: Double = 0.0
}

@available(iOS 13.0, *)
struct AnimationMeasurement {
    let name: String
    let duration: TimeInterval
    let fps: Double
    let timestamp: Date
}

@available(iOS 13.0, *)
class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var cache: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?
    
    private class Node {
        let key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func set(_ value: Value, forKey key: Key) {
        if let existingNode = cache[key] {
            existingNode.value = value
            moveToHead(existingNode)
        } else {
            let newNode = Node(key: key, value: value)
            addToHead(newNode)
            cache[key] = newNode
            
            if cache.count > capacity {
                removeTail()
            }
        }
    }
    
    func value(forKey key: Key) -> Value? {
        if let node = cache[key] {
            moveToHead(node)
            return node.value
        }
        return nil
    }
    
    func clear() {
        cache.removeAll()
        head = nil
        tail = nil
    }
    
    private func addToHead(_ node: Node) {
        if head == nil {
            head = node
            tail = node
        } else {
            node.next = head
            head?.prev = node
            head = node
        }
    }
    
    private func moveToHead(_ node: Node) {
        if node === head {
            return
        }
        
        if node === tail {
            tail = node.prev
            tail?.next = nil
        } else {
            node.prev?.next = node.next
            node.next?.prev = node.prev
        }
        
        addToHead(node)
    }
    
    private func removeTail() {
        if let tail = tail {
            cache.removeValue(forKey: tail.key)
            
            if tail === head {
                head = nil
                self.tail = nil
            } else {
                self.tail = tail.prev
                self.tail?.next = nil
            }
        }
    }
}

// MARK: - View Modifiers
@available(iOS 13.0, *)
struct PerformanceOptimizedView: ViewModifier {
    let animation: AnimationEffect
    let duration: TimeInterval?
    
    func body(content: Content) -> some View {
        content
            .modifier(OptimizedAnimationModifier(animation: animation, duration: duration))
    }
}

@available(iOS 13.0, *)
struct OptimizedAnimationModifier: ViewModifier {
    let animation: AnimationEffect
    let duration: TimeInterval?
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .onAppear {
                if UIOptimizer.shared.isLowPerformanceMode {
                    return
                }
                
                withAnimation(.easeInOut(duration: duration ?? 0.3)) {
                    isAnimating = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: duration ?? 0.3)) {
                        isAnimating = false
                    }
                }
            }
    }
}

@available(iOS 13.0, *)
extension View {
    func optimizedForLowPerformance() -> some View {
        self.modifier(PerformanceOptimizedView(animation: .fade, duration: 0.2))
    }
    
    func optimizedForHighPerformance() -> some View {
        self.modifier(PerformanceOptimizedView(animation: .complex, duration: 0.5))
    }
}