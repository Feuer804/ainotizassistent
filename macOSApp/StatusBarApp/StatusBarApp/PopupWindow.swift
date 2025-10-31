//
//  PopupWindow.swift
//  StatusBarApp
//
//  Custom NSWindow mit Glass-Effekt für popup-ähnliche Fenster
//

import Cocoa
import CoreGraphics

@objc class PopupWindow: NSWindow {
    
    // MARK: - Properties
    
    private var blurEffectView: NSVisualEffectView?
    private var isBlurred = true
    
    // MARK: - Initialization
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWindow()
    }
    
    private func setupWindow() {
        // Window-Grundeinstellungen
        isOpaque = false
        backgroundColor = .clear
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        styleMask.insert(.fullSizeContentView)
        
        // Animation aktivieren
        animationBehavior = .alertPanel
        
        // Visual Effects Setup
        setupVisualEffect()
        
        // Corner Radius für modernen Look
        standardWindowButton(.closeButton)?.isHidden = false
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        
        // Window shadow konfigurieren
        setupShadow()
        
        print("PopupWindow mit Blur-Effekt initialisiert")
    }
    
    // MARK: - Visual Effects
    
    private func setupVisualEffect() {
        guard isBlurred else { return }
        
        let visualEffectView = NSVisualEffectView(frame: contentView?.bounds ?? .zero)
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.isEmphasized = true
        visualEffectView.wantsLayer = true
        
        // Corner Radius für das Visual Effect View
        visualEffectView.layer?.cornerRadius = 12
        visualEffectView.layer?.masksToBounds = true
        
        // Mask erstellen für abgerundete Ecken
        visualEffectView.maskImage = createRoundedRectMask(cornerRadius: 12)
        
        blurEffectView = visualEffectView
        contentView?.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
        
        // Auto Layout Constraints
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: visualEffectView.superview!.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: visualEffectView.superview!.trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: visualEffectView.superview!.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: visualEffectView.superview!.bottomAnchor)
        ])
    }
    
    // MARK: - Custom Mask für abgerundete Ecken
    
    private func createRoundedRectMask(cornerRadius: CGFloat) -> NSImage? {
        let size = CGSize(width: 100, height: 100) // Große Maske für Skalierung
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size),
                               xRadius: cornerRadius,
                               yRadius: cornerRadius)
        NSColor.white.setFill()
        path.fill()
        
        image.unlockFocus()
        
        return image
    }
    
    // MARK: - Shadow Setup
    
    private func setupShadow() {
        self.hasShadow = true
        self.shadow = NSShadow()
        self.shadow?.shadowColor = NSColor.black.withAlphaComponent(0.3)
        self.shadow?.shadowBlurRadius = 20
        self.shadow?.shadowOffset = NSSize(width: 0, height: -8)
    }
    
    // MARK: - Theme Support
    
    /// Aktiviert/deaktiviert den Blur-Effekt
    func setBlurEnabled(_ enabled: Bool) {
        isBlurred = enabled
        
        if enabled {
            setupVisualEffect()
        } else {
            blurEffectView?.removeFromSuperview()
            blurEffectView = nil
        }
    }
    
    /// Ändert das Material für den Blur-Effekt
    func setMaterial(_ material: NSVisualEffectView.Material) {
        blurEffectView?.material = material
    }
    
    // MARK: - Overrides
    
    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        super.setFrame(frameRect, display: displayFlag, animate: animateFlag)
        
        // Blur Effect View an neue Größe anpassen
        if let blurEffectView = blurEffectView {
            blurEffectView.frame = contentView?.bounds ?? .zero
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    // MARK: - Modern Window Styling
    
    /// Wendet ein modernes macOS Design an
    func applyModernMacOSStyle() {
        // Material für modernen Look
        if let blurView = blurEffectView {
            blurView.material = .underWindowBackground
            blurView.blendingMode = .behindWindow
            blurView.state = .followsWindowActiveState
        }
        
        // Schatten optimieren
        if let shadow = self.shadow {
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.2)
            shadow.shadowBlurRadius = 15
            shadow.shadowOffset = NSSize(width: 0, height: -4)
        }
        
        // Content View Styling
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    /// Aktiviert das Dark Mode Material
    func applyDarkModeMaterial() {
        if let blurView = blurEffectView {
            blurView.material = .dark
            blurView.state = .active
            blurView.isEmphasized = true
        }
    }
    
    /// Aktiviert das Light Mode Material
    func applyLightModeMaterial() {
        if let blurView = blurEffectView {
            blurView.material = .light
            blurView.state = .active
            blurView.isEmphasized = false
        }
    }
}