//
//  GlassEffectManager.swift
//  Erweiterte macOS Glass-Effekte mit NSVisualEffectView Integration
//  Erstellt am: 31.10.2025
//

import SwiftUI
import AppKit

// MARK: - GlassEffect Protokoll
/// Ein通用 protokol für wiederverwendbare Glass-Effekt-Komponenten
@objc protocol GlassEffect {
    var blurRadius: CGFloat { get set }
    var tintColor: Color? { get set }
    var material: NSVisualEffectView.Material { get set }
    
    func applyGlassEffect(to view: NSView)
    func removeGlassEffect(from view: NSView)
}

// MARK: - NSView Extension für Glass-Effekte
extension NSView {
    /// Wendet einen Glass-Effekt auf eine NSView an
    @objc func addGlassEffect(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        tintMode: NSVisualEffectView.TintMode = .default,
        blurRadius: CGFloat = 20,
        tintColor: Color? = nil
    ) {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.tintMode = tintMode
        visualEffectView.blurRadius = blurRadius
        visualEffectView.state = .active
        
        if let tintColor = tintColor {
            visualEffectView.tintColor = NSColor(tintColor)
        }
        
        // Setze das Material für spezielle Effekte
        setupMaterialAppearance(visualEffectView, material: material)
        
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualEffectView, positioned: .below, relativeTo: nil)
        
        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupMaterialAppearance(_ view: NSVisualEffectView, material: NSVisualEffectView.Material) {
        switch material {
        case .hudWindow:
            view.appearance = NSAppearance(named: .vibrantDark)
        case .selection:
            view.appearance = NSAppearance(named: .vibrantLight)
        case .popover:
            view.appearance = NSAppearance(named: .vibrantDark)
        case .sidebar:
            view.appearance = NSAppearance(named: .vibrantLight)
        case .mediumLight:
            view.appearance = NSAppearance(named: .aqua)
        case .ultraDark:
            view.appearance = NSAppearance(named: .vibrantDark)
        default:
            view.appearance = NSAppearance(named: .vibrantDark)
        }
    }
    
    /// Entfernt alle Glass-Effekte von der View
    @objc func removeGlassEffects() {
        subviews.forEach { subview in
            if let glassView = subview as? NSVisualEffectView {
                glassView.removeFromSuperview()
            }
        }
    }
}

// MARK: - GlassEffectManager Klasse
/// Verwaltet erweiterte macOS Glass-Effekte mit Vision Glass-Look
@objc class GlassEffectManager: NSObject, ObservableObject {
    @Published var isGlassEffectEnabled: Bool = true
    @Published var currentMaterial: NSVisualEffectView.Material = .hudWindow
    @Published var blurIntensity: CGFloat = 20.0
    @Published var tintColorValue: Color = .clear
    
    /// Verschiedene Glass-Material-Typen für verschiedene Anwendungsfälle
    enum GlassType {
        case hudWindow       // Für HUD-Fenster
        case sidebar         // Für Sidebar-Navigation
        case selection       // Für Auswahlelemente
        case popover         // Für Popover-Menüs
        case mediumLight     // Für mittlere Transparenz
        case ultraDark       // Für dunkle Themen
        case visionGlass     // Für Vision Glass-Look
        
        var material: NSVisualEffectView.Material {
            switch self {
            case .hudWindow: return .hudWindow
            case .sidebar: return .sidebar
            case .selection: return .selection
            case .popover: return .popover
            case .mediumLight: return .mediumLight
            case .ultraDark: return .ultraDark
            case .visionGlass: return .hudWindow
            }
        }
        
        var recommendedBlurRadius: CGFloat {
            switch self {
            case .hudWindow: return 25
            case .sidebar: return 15
            case .selection: return 30
            case .popover: return 20
            case .mediumLight: return 18
            case .ultraDark: return 35
            case .visionGlass: return 40
            }
        }
    }
    
    // MARK: - Singleton Instance
    static let shared = GlassEffectManager()
    private override init() {
        super.init()
        setupVisionGlassAppearance()
    }
    
    // MARK: - Vision Glass Setup
    private func setupVisionGlassAppearance() {
        // Konfiguriere das moderne Vision Glass-System
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeOcclusionStateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateGlassEffectsForOcclusionState()
        }
    }
    
    /// Aktualisiert Glass-Effekte basierend auf Fenster-Sichtbarkeit
    private func updateGlassEffectsForOcclusionState() {
        guard let app = NSApplication.shared,
              let window = app.keyWindow else { return }
        
        window.subviews.forEach { view in
            if let glassView = view as? NSVisualEffectView {
                glassView.isHidden = app.isHidden
            }
        }
    }
    
    // MARK: - Public API
    /// Wendet einen Glass-Effekt mit erweiterten Optionen an
    func applyEnhancedGlassEffect(
        to view: NSView,
        type: GlassType = .hudWindow,
        customBlur: CGFloat? = nil,
        customTint: Color? = nil,
        animationDuration: TimeInterval = 0.3
    ) {
        guard isGlassEffectEnabled else { return }
        
        let blurRadius = customBlur ?? type.recommendedBlurRadius
        let tintColor = customTint ?? getSystemTintColor(for: type)
        
        // Animierte Anwendung des Glass-Effekts
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            view.addGlassEffect(
                material: type.material,
                blurRadius: blurRadius,
                tintColor: tintColor
            )
        }, completionHandler: nil)
        
        // System-reflektierende Animation für Vision Glass
        if type == .visionGlass {
            applyVisionGlassAnimation(to: view)
        }
    }
    
    /// Wendet Vision Glass Animation mit system-reflektierenden Effekten an
    private func applyVisionGlassAnimation(to view: NSView) {
        guard let glassView = view.subviews.first(where: { $0 is NSVisualEffectView }) as? NSVisualEffectView else { return }
        
        // Subtile Schimmer-Animation für Vision Glass Look
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.8
        animation.toValue = 1.0
        animation.duration = 2.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        
        glassView.layer?.add(animation, forKey: "visionGlassShimmer")
        
        // Responsive Blur-Update basierend auf Cursor-Position
        addMouseTracking(for: glassView)
    }
    
    /// Fügt Mouse-Tracking für responsive Glass-Effekte hinzu
    private func addMouseTracking(for view: NSView) {
        let trackingArea = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: ["view": view]
        )
        view.addTrackingArea(trackingArea)
    }
    
    /// Erweiterte Mouse-Tracking Funktionalität
    override func mouseMoved(with event: NSEvent) {
        guard let trackingArea = event.trackingArea,
              let userInfo = trackingArea.userInfo as? [String: Any],
              let view = userInfo["view"] as? NSVisualEffectView,
              let window = view.window else { return }
        
        let mousePoint = window.convertPoint(fromScreen: event.locationInWindow)
        let distanceFromCenter = hypot(
            mousePoint.x - view.frame.midX,
            mousePoint.y - view.frame.midY
        )
        
        // Responsive Blur-Intensität basierend auf Cursor-Nähe
        let normalizedDistance = min(distanceFromCenter / 200, 1.0)
        let adaptiveBlur = 30.0 - (normalizedDistance * 15.0)
        
        view.blurRadius = adaptiveBlur
        
        // Real-time Material-Anpassung für Vision Glass
        if view.material == .hudWindow {
            updateMaterialForVisionGlass(view, mousePoint: mousePoint)
        }
    }
    
    /// Aktualisiert Material für Vision Glass basierend auf Cursor-Position
    private func updateMaterialForVisionGlass(_ view: NSVisualEffectView, mousePoint: NSPoint) {
        let isInTopRegion = mousePoint.y > view.frame.height * 0.7
        
        if isInTopRegion {
            view.tintMode = .prominent
            view.appearance = NSAppearance(named: .vibrantLight)
        } else {
            view.tintMode = .default
            view.appearance = NSAppearance(named: .vibrantDark)
        }
    }
    
    /// Entfernt Glass-Effekt mit Animation
    func removeGlassEffect(
        from view: NSView,
        animationDuration: TimeInterval = 0.2
    ) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            view.removeGlassEffects()
        }, completionHandler: nil)
    }
    
    /// Bestimmt das System-Tint für verschiedene Glass-Typen
    private func getSystemTintColor(for type: GlassType) -> Color {
        switch type {
        case .hudWindow:
            return Color.clear
        case .sidebar:
            return Color.clear
        case .selection:
            return Color.blue.opacity(0.3)
        case .popover:
            return Color.clear
        case .mediumLight:
            return Color.white.opacity(0.2)
        case .ultraDark:
            return Color.black.opacity(0.1)
        case .visionGlass:
            return Color.clear
        }
    }
    
    /// Aktualisiert alle Glass-Effekte bei Appearance-Änderungen
    func updateForAppearanceChange() {
        let isDark = NSAppearance.current.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
        
        NSApplication.shared.windows.forEach { window in
            window.contentView?.subviews.forEach { view in
                if let glassView = view as? NSVisualEffectView {
                    updateGlassViewAppearance(glassView, isDark: isDark)
                }
            }
        }
    }
    
    private func updateGlassViewAppearance(_ view: NSVisualEffectView, isDark: Bool) {
        if isDark {
            view.appearance = NSAppearance(named: .vibrantDark)
        } else {
            view.appearance = NSAppearance(named: .vibrantLight)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - SwiftUI View Modifiers
/// SwiftUI View Modifiers für einfache Integration von Glass-Effekten
extension View {
    /// Wendet einen macOS Glass-Effekt mit NSVisualEffectView an
    func macOSGlassEffect(
        material: NSVisualEffectView.Material = .hudWindow,
        tintMode: NSVisualEffectView.TintMode = .default,
        blurRadius: CGFloat = 20
    ) -> some View {
        self.modifier(MacOSGlassEffectModifier(
            material: material,
            tintMode: tintMode,
            blurRadius: blurRadius
        ))
    }
    
    /// Vision Glass-Effekt mit system-reflektierenden Animationen
    func visionGlassEffect() -> some View {
        self.modifier(VisionGlassEffectModifier())
    }
    
    /// Glass-Effekt mit Container-Relative-Effects für moderne UI
    func glassContainerEffect() -> some View {
        self
            .background(.ultraThinMaterial)
            .backgroundStyle(.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - MacOSGlassEffectModifier
struct MacOSGlassEffectModifier: ViewModifier {
    let material: NSVisualEffectView.Material
    let tintMode: NSVisualEffectView.TintMode
    let blurRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                NSVisualEffectViewRepresentable(
                    material: material,
                    tintMode: tintMode,
                    blurRadius: blurRadius
                )
            )
    }
}

// MARK: - VisionGlassEffectModifier
struct VisionGlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                NSVisualEffectViewRepresentable(
                    material: .hudWindow,
                    tintMode: .default,
                    blurRadius: 40
                )
            )
            .animation(.easeInOut(duration: 2), value: UUID())
    }
}

// MARK: - NSVisualEffectView Representable für SwiftUI
struct NSVisualEffectViewRepresentable: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let tintMode: NSVisualEffectView.TintMode
    let blurRadius: CGFloat
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.tintMode = tintMode
        view.blurRadius = blurRadius
        view.state = .active
        
        // Appearance für Catalyst/macOS Kompatibilität
        if #available(macOS 11.0, *) {
            view.appearance = NSAppearance(named: .vibrantDark)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.tintMode = tintMode
        nsView.blurRadius = blurRadius
        nsView.state = .active
    }
}

// MARK: - GlassCardView für Submarine-Cards
/// Eine SwiftUI View für submarine Cards mit Blur-Background
struct GlassCardView<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let glassType: GlassEffectManager.GlassType
    let showShadow: Bool
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 12,
        glassType: GlassEffectManager.GlassType = .mediumLight,
        showShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.glassType = glassType
        self.showShadow = showShadow
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .macOSGlassEffect(
                material: glassType.material,
                blurRadius: glassType.recommendedBlurRadius
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        .white.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .if(showShadow) { view in
                view.shadow(
                    color: .black.opacity(0.1),
                    radius: cornerRadius,
                    x: 0,
                    y: 4
                )
            }
    }
}

// MARK: - NSAppearance Kompatibilität für Catalyst
/// Erweiterte NSAppearance Kompatibilität
class GlassEffectAppearanceManager: ObservableObject {
    @Published var currentAppearance: NSAppearance.Name = .aqua
    
    static let shared = GlassEffectAppearanceManager()
    
    private override init() {
        super.init()
        setupAppearanceObserver()
    }
    
    private func setupAppearanceObserver() {
        // Beobachte System-Appearance Änderungen
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(appearanceDidChange),
            name: .init("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }
    
    @objc private func appearanceDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateCurrentAppearance()
            GlassEffectManager.shared.updateForAppearanceChange()
        }
    }
    
    private func updateCurrentAppearance() {
        let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        currentAppearance = isDark ? .darkAqua : .aqua
    }
    
    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Utility Extensions
extension View {
    /// Conditional View Modifier
    func `if`<T>(_ condition: Bool, transform: (Self) -> T) -> some View where T: View {
        if condition {
            return transform(self)
        } else {
            return self
        }
    }
}

// MARK: - Performance Optimierungen
extension GlassEffectManager {
    /// Optimiert Glass-Effekte für bessere Performance
    func optimizePerformance() {
        // Deaktiviere Glass-Effekte bei niedriger System-Last
        let processInfo = ProcessInfo.processInfo
        let systemLoad = processInfo.systemUptime
        
        if systemLoad > 300 { // 5 Minuten ohne Neustart
            blurIntensity = max(15, blurIntensity - 5)
        }
    }
    
    /// Aktiviert Hardware-Beschleunigung für Glass-Effekte
    func enableHardwareAcceleration() {
        NSApplication.shared.windows.forEach { window in
            window.contentView?.subviews.forEach { view in
                view.wantsLayer = true
                view.layer?.setValue(1, forKey: "allowsHardwareAcceleration")
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let glassEffectDidChange = Notification.Name("GlassEffectDidChange")
    static let visionGlassAnimationDidStart = Notification.Name("VisionGlassAnimationDidStart")
}

// MARK: - Glass Effect Manager Delegate
@objc protocol GlassEffectManagerDelegate: AnyObject {
    @objc optional func glassEffectManager(_ manager: GlassEffectManager, didApplyEffectTo view: NSView)
    @objc optional func glassEffectManager(_ manager: GlassEffectManager, didRemoveEffectFrom view: NSView)
    @objc optional func glassEffectManager(_ manager: GlassEffectManager, visionGlassAnimationStartedFor view: NSView)
}