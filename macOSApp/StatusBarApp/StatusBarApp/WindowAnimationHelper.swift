//
//  WindowAnimationHelper.swift
//  StatusBarApp
//
//  Hilfsklasse für erweiterte Window-Animationen und Effekte
//

import Cocoa
import QuartzCore

@objc enum WindowEffectType: Int {
    case blur
    case shadow
    case glow
    case bounce
    case shake
    case pulse
    case rotate
    case scale
}

@objc class WindowAnimationHelper: NSObject {
    
    // MARK: - Properties
    
    private var animationLayers: [String: CALayer] = [:]
    private var animationTimers: [String: Timer] = [:]
    
    // MARK: - Singleton
    
    static let shared = WindowAnimationHelper()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Effect Animations
    
    /// Wendet einen Blur-Effekt auf das Window an
    func applyBlurEffect(
        to window: NSWindow,
        intensity: CGFloat = 0.8,
        duration: TimeInterval = 0.3
    ) {
        guard let contentView = window.contentView else { return }
        
        // Blur Layer erstellen
        let blurLayer = CALayer()
        blurLayer.frame = contentView.bounds
        blurLayer.backgroundColor = NSColor.white.withAlphaComponent(intensity).cgColor
        
        // Blur Filter
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(intensity * 10, forKey: "inputRadius")
        
        blurLayer.filters = [blurFilter].compactMap { $0 }
        
        // Animation hinzufügen
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        
        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = 0.0
        fadeIn.toValue = 1.0
        blurLayer.add(fadeIn, forKey: "fadeIn")
        
        contentView.layer?.addSublayer(blurLayer)
        
        CATransaction.commit()
        
        animationLayers["blurEffect"] = blurLayer
        
        print("Blur-Effekt angewendet: Intensität \(intensity)")
    }
    
    /// Entfernt den Blur-Effekt
    func removeBlurEffect(from window: NSWindow, duration: TimeInterval = 0.3) {
        guard let blurLayer = animationLayers["blurEffect"] else { return }
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1.0
        fadeOut.toValue = 0.0
        fadeOut.delegate = AnimationDelegate {
            blurLayer.removeFromSuperlayer()
            self.animationLayers.removeValue(forKey: "blurEffect")
        }
        
        blurLayer.add(fadeOut, forKey: "fadeOut")
        
        CATransaction.commit()
        
        print("Blur-Effekt entfernt")
    }
    
    /// Fügt einen Glow-Effekt hinzu
    func applyGlowEffect(
        to window: NSWindow,
        color: NSColor = .systemBlue,
        radius: CGFloat = 20.0,
        duration: TimeInterval = 0.5
    ) {
        guard let contentView = window.contentView else { return }
        
        // Glow Layer erstellen
        let glowLayer = CALayer()
        glowLayer.frame = contentView.bounds
        glowLayer.backgroundColor = NSColor.clear.cgColor
        
        // Glow Shadow
        glowLayer.shadowColor = color.cgColor
        glowLayer.shadowRadius = radius
        glowLayer.shadowOffset = .zero
        glowLayer.shadowOpacity = 0.8
        
        // Animation
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.8
        scaleAnimation.toValue = 1.0
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let opacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        opacityAnimation.fromValue = 0.0
        opacityAnimation.toValue = 0.8
        
        glowLayer.add(scaleAnimation, forKey: "scale")
        glowLayer.add(opacityAnimation, forKey: "opacity")
        
        contentView.layer?.addSublayer(glowLayer)
        
        CATransaction.commit()
        
        animationLayers["glowEffect"] = glowLayer
        
        print("Glow-Effekt angewendet: \(color)")
    }
    
    /// Animiert einen Shake-Effekt
    func shakeWindow(_ window: NSWindow, intensity: CGFloat = 10.0, duration: TimeInterval = 0.5) {
        let originalFrame = window.frame
        
        let shakeKey = "shakeAnimation"
        window.animator().setFrame(originalFrame, display: true) // Reset
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
            
            // Mehrere Shake-Positionen
            let positions: [CGPoint] = [
                CGPoint(x: intensity, y: 0),
                CGPoint(x: -intensity, y: 0),
                CGPoint(x: intensity * 0.5, y: 0),
                CGPoint(x: -intensity * 0.5, y: 0),
                CGPoint(x: 0, y: 0)
            ]
            
            for (index, position) in positions.enumerated() {
                let frame = NSRect(
                    x: originalFrame.origin.x + position.x,
                    y: originalFrame.origin.y + position.y,
                    width: originalFrame.width,
                    height: originalFrame.height
                )
                
                let delay = duration * Double(index) / Double(positions.count)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    window.animator().setFrame(frame, display: true)
                }
            }
            
        }, completionHandler: {
            window.animator().setFrame(originalFrame, display: true)
            print("Shake-Animation beendet")
        })
    }
    
    /// Animiert einen Bounce-Effekt
    func bounceWindow(_ window: NSWindow, intensity: CGFloat = 0.2, duration: TimeInterval = 0.8) {
        let originalFrame = window.frame
        let bounceHeight = originalFrame.height * intensity
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.3, 1.0)
            
            // Bounce up
            let upFrame = NSRect(
                x: originalFrame.origin.x,
                y: originalFrame.origin.y + bounceHeight,
                width: originalFrame.width,
                height: originalFrame.height
            )
            
            window.animator().setFrame(upFrame, display: true)
            
        }, completionHandler: {
            // Bounce back
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = duration * 0.6
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                
                window.animator().setFrame(originalFrame, display: true)
            })
        })
        
        print("Bounce-Animation angewendet")
    }
    
    /// Animiert einen Pulse-Effekt (kontinuierlich)
    func pulseWindow(_ window: NSWindow, scale: CGFloat = 1.05, duration: TimeInterval = 1.0) {
        let pulseKey = "pulseAnimation"
        
        // Bestehende Pulse-Animation entfernen
        stopPulseAnimation(for: window)
        
        // Timer für kontinuierliche Pulse-Animation
        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { [weak window] _ in
            guard let window = window else { return }
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = duration * 0.5
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                // Scale up
                let scaleTransform = CATransform3DScale(window.layer!.transform, scale, scale, 1.0)
                window.layer?.transform = scaleTransform
            }, completionHandler: {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = duration * 0.5
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    
                    // Scale down
                    let identityTransform = CATransform3DIdentity
                    window.layer?.transform = identityTransform
                })
            })
        }
        
        animationTimers[pulseKey] = timer
        
        print("Pulse-Animation gestartet")
    }
    
    /// Stoppt die Pulse-Animation
    func stopPulseAnimation(for window: NSWindow) {
        let pulseKey = "pulseAnimation"
        
        if let timer = animationTimers[pulseKey] {
            timer.invalidate()
            animationTimers.removeValue(forKey: pulseKey)
        }
        
        // Transform zurücksetzen
        window.layer?.transform = CATransform3DIdentity
        
        print("Pulse-Animation gestoppt")
    }
    
    /// Animiert eine Rotation
    func rotateWindow(
        _ window: NSWindow,
        angle: CGFloat,
        duration: TimeInterval = 0.5,
        direction: Int = 1 // 1 = forward, -1 = backward
    ) {
        let rotationAngle = angle * CGFloat(direction) * .pi / 180
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        
        let rotation = CATransform3DMakeRotation(rotationAngle, 0, 0, 1)
        window.layer?.transform = rotation
        
        CATransaction.commit()
        
        print("Rotation-Animation angewendet: \(angle)°")
    }
    
    // MARK: - Transition Effects
    
    /// Slide-Transition zwischen zwei Windows
    func slideTransition(
        from oldWindow: NSWindow,
        to newWindow: NSWindow,
        direction: WindowAnimationType,
        duration: TimeInterval = 0.4
    ) {
        guard let oldFrame = oldWindow.frame,
              let newFrame = newWindow.frame else { return }
        
        // Neue Window vorbereiten
        newWindow.setFrame(offscreenFrame(for: newFrame, direction: direction), display: false, animate: false)
        newWindow.makeKeyAndOrderFront(nil)
        
        // Slide-Animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            // Altes Window
            oldWindow.animator().alphaValue = 0.0
            
            // Neues Window
            newWindow.animator().setFrame(newFrame, display: true)
            newWindow.animator().alphaValue = 1.0
            
        }, completionHandler: {
            oldWindow.alphaValue = 1.0
            print("Slide-Transition beendet")
        })
    }
    
    /// Crossfade zwischen zwei Windows
    func crossfadeTransition(
        from oldWindow: NSWindow,
        to newWindow: NSWindow,
        duration: TimeInterval = 0.3
    ) {
        newWindow.alphaValue = 0.0
        newWindow.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            oldWindow.animator().alphaValue = 0.0
            newWindow.animator().alphaValue = 1.0
            
        }, completionHandler: {
            oldWindow.alphaValue = 1.0
            print("Crossfade-Transition beendet")
        })
    }
    
    // MARK: - Utility Methods
    
    private func offscreenFrame(for frame: NSRect, direction: WindowAnimationType) -> NSRect {
        let screenFrame = NSScreen.main?.frame ?? .zero
        
        switch direction {
        case .slideFromLeft:
            return NSRect(
                x: screenFrame.origin.x - frame.width,
                y: frame.origin.y,
                width: frame.width,
                height: frame.height
            )
        case .slideFromRight:
            return NSRect(
                x: screenFrame.origin.x + screenFrame.width,
                y: frame.origin.y,
                width: frame.width,
                height: frame.height
            )
        case .slideUp:
            return NSRect(
                x: frame.origin.x,
                y: screenFrame.origin.y - frame.height,
                width: frame.width,
                height: frame.height
            )
        default:
            return frame
        }
    }
    
    /// Animiert eine Property mit Core Animation
    func animate(
        keyPath: String,
        from value: Any?,
        to value: Any?,
        duration: TimeInterval = 0.3,
        timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut),
        completion: (() -> Void)? = nil
    ) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = value
        animation.toValue = value
        animation.timingFunction = timingFunction
        animation.duration = duration
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(timingFunction)
        
        if let completion = completion {
            animation.delegate = AnimationDelegate(completion)
        }
        
        // Animation würde auf einem Layer ausgeführt werden
        CATransaction.commit()
    }
    
    /// Bereinigt alle Animationen
    func cleanup() {
        // Timer invalidieren
        for timer in animationTimers.values {
            timer.invalidate()
        }
        animationTimers.removeAll()
        
        // Layers entfernen
        for (_, layer) in animationLayers {
            layer.removeFromSuperlayer()
        }
        animationLayers.removeAll()
        
        print("WindowAnimationHelper bereinigt")
    }
}

// MARK: - Animation Delegate

@objc class AnimationDelegate: NSObject, CAAnimationDelegate {
    
    private let completion: () -> Void
    
    init(_ completion: @escaping () -> Void) {
        self.completion = completion
        super.init()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            completion()
        }
    }
}