//
//  AnimatedWindowController.swift
//  StatusBarApp
//
//  NSWindowController mit erweiterten Animationen für popup-Fenster
//

import Cocoa
import QuartzCore

@objc class AnimatedWindowController: NSWindowController {
    
    // MARK: - Properties
    
    weak var windowManager: WindowManager?
    
    var shouldCloseOnEsc: Bool = true
    var closeBehavior: WindowCloseBehavior = .escClose
    
    private let animationDuration: TimeInterval = 0.3
    private var isAnimating = false
    private var originalFrame: NSRect?
    
    // MARK: - Window Setup
    
    /// Konfiguriert das Window mit ViewController und Animation
    func setupWindow(
        with viewController: NSViewController,
        style: NSWindow.StyleMask,
        animation: WindowAnimationType,
        size: CGSize
    ) {
        
        // Window erstellen
        let windowRect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        let popupWindow = PopupWindow(
            contentRect: windowRect,
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        
        // Window konfigurieren
        popupWindow.contentViewController = viewController
        popupWindow.windowController = self
        popupWindow.animationBehavior = .alertPanel
        
        // Content View konfigurieren
        setupContentView(viewController: viewController)
        
        // Window als ours setzen
        self.window = popupWindow
        
        print("Window konfiguriert mit Größe: \(size)")
    }
    
    private func setupContentView(viewController: NSViewController) {
        guard let contentView = window?.contentView else { return }
        
        // Content View Styling
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Content View rounded corners
        contentView.layer?.cornerRadius = 12
        contentView.layer?.masksToBounds = true
    }
    
    // MARK: - Window Animationen
    
    /// Animiert das Öffnen des Fensters
    func animateWindowOpen(animation: WindowAnimationType, completion: (() -> Void)? = nil) {
        guard let window = self.window, !isAnimating else {
            completion?()
            return
        }
        
        isAnimating = true
        originalFrame = window.frame
        
        // Start-Frame für Animation
        switch animation {
        case .scaleUp:
            animateScaleUp(opening: true, completion: completion)
        case .slideUp:
            animateSlideUp(opening: true, completion: completion)
        case .bounce:
            animateBounce(opening: true, completion: completion)
        case .fade:
            animateFade(opening: true, completion: completion)
        case .slideFromRight:
            animateSlideFromRight(opening: true, completion: completion)
        case .slideFromLeft:
            animateSlideFromLeft(opening: true, completion: completion)
        }
    }
    
    /// Animiert das Schließen des Fensters
    func animateWindowClose(animation: WindowAnimationType, completion: (() -> Void)? = nil) {
        guard let window = self.window, !isAnimating else {
            completion?()
            return
        }
        
        isAnimating = true
        
        switch animation {
        case .scaleUp:
            animateScaleUp(opening: false, completion: completion)
        case .slideUp:
            animateSlideUp(opening: false, completion: completion)
        case .bounce:
            animateBounce(opening: false, completion: completion)
        case .fade:
            animateFade(opening: false, completion: completion)
        case .slideFromRight:
            animateSlideFromRight(opening: false, completion: completion)
        case .slideFromLeft:
            animateSlideFromLeft(opening: false, completion: completion)
        }
    }
    
    // MARK: - Individual Animationen
    
    private func animateScaleUp(opening: Bool, completion: (() -> Void)?) {
        guard let window = self.window else { return }
        
        let finalFrame = window.frame
        var startFrame = finalFrame
        
        if opening {
            // Skalierung von 0.3 auf 1.0
            let scale: CGFloat = 0.3
            startFrame.size = NSSize(
                width: finalFrame.width * scale,
                height: finalFrame.height * scale
            )
            startFrame.origin.x += (finalFrame.width - startFrame.width) / 2
            startFrame.origin.y += (finalFrame.height - startFrame.height) / 2
        } else {
            // Skalierung von 1.0 auf 0.0
            let scale: CGFloat = 0.0
            startFrame.size = NSSize(
                width: finalFrame.width * scale,
                height: finalFrame.height * scale
            )
            startFrame.origin.x += (finalFrame.width - startFrame.width) / 2
            startFrame.origin.y += (finalFrame.height - startFrame.height) / 2
        }
        
        // Start-Frame setzen
        window.setFrame(startFrame, display: false, animate: false)
        
        // Animation durchführen
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: opening ? .easeOut : .easeIn)
            
            window.animator().setFrame(finalFrame, display: true)
        }, completionHandler: {
            self.isAnimating = false
            completion?()
        })
    }
    
    private func animateSlideUp(opening: Bool, completion: (() -> Void)?) {
        guard let window = self.window else { return }
        
        let finalFrame = window.frame
        var startFrame = finalFrame
        
        if opening {
            // Von unten nach oben
            startFrame.origin.y -= finalFrame.height + 50
        } else {
            // Nach unten
            startFrame.origin.y += finalFrame.height + 50
        }
        
        // Start-Frame setzen
        window.setFrame(startFrame, display: false, animate: false)
        
        // Animation durchführen
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = opening ? CAMediaTimingFunction(name: .easeOut) : CAMediaTimingFunction(name: .easeIn)
            
            window.animator().setFrame(finalFrame, display: true)
        }, completionHandler: {
            self.isAnimating = false
            completion?()
        })
    }
    
    private func animateBounce(opening: Bool, completion: (() -> Void)?) {
        guard let window = self.window else { return }
        
        let finalFrame = window.frame
        var startFrame = finalFrame
        
        if opening {
            // Bounce-down Animation
            startFrame.origin.y += 30
            window.setFrame(startFrame, display: false, animate: false)
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = animationDuration
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.3, 0.1, 0.3, 1.0)
                
                // Erste Phase: Nach oben
                window.animator().setFrame(finalFrame, display: true)
            }, completionHandler: {
                // Zweite Phase: Kleiner bounce
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.15
                    let bounceFrame = NSRect(
                        x: finalFrame.origin.x,
                        y: finalFrame.origin.y + 10,
                        width: finalFrame.width,
                        height: finalFrame.height
                    )
                    window.animator().setFrame(bounceFrame, display: true)
                }, completionHandler: {
                    // Zurück zur finalen Position
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.1
                        window.animator().setFrame(finalFrame, display: true)
                    }, completionHandler: {
                        self.isAnimating = false
                        completion?()
                    })
                })
            })
        } else {
            // Reverse bounce für Closing
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                startFrame.origin.y += 20
                window.animator().setFrame(startFrame, display: true)
            }, completionHandler: {
                self.isAnimating = false
                completion?()
            })
        }
    }
    
    private func animateFade(opening: Bool, completion: (() -> Void)?) {
        guard let window = self.window else { return }
        
        if opening {
            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = opening ? CAMediaTimingFunction(name: .easeOut) : CAMediaTimingFunction(name: .easeIn)
            
            window.animator().alphaValue = opening ? 1.0 : 0.0
        }, completionHandler: {
            self.isAnimating = false
            completion?()
        })
    }
    
    private func animateSlideFromRight(opening: Bool, completion: (() -> Void)?) {
        guard let window = self.window else { return }
        
        let finalFrame = window.frame
        var startFrame = finalFrame
        
        if opening {
            // Von rechts nach links
            startFrame.origin.x += finalFrame.width + 50
        } else {
            // Nach rechts
            startFrame.origin.x -= finalFrame.width + 50
        }
        
        window.setFrame(startFrame, display: false, animate: false)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = opening ? CAMediaTimingFunction(name: .easeOut) : CAMediaTimingFunction(name: .easeIn)
            
            window.animator().setFrame(finalFrame, display: true)
        }, completionHandler: {
            self.isAnimating = false
            completion?()
        })
    }
    
    private func animateSlideFromLeft(opening: Bool, completion: (() -> Void)?) {
        guard let window = self.window else { return }
        
        let finalFrame = window.frame
        var startFrame = finalFrame
        
        if opening {
            // Von links nach rechts
            startFrame.origin.x -= finalFrame.width + 50
        } else {
            // Nach links
            startFrame.origin.x += finalFrame.width + 50
        }
        
        window.setFrame(startFrame, display: false, animate: false)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = opening ? CAMediaTimingFunction(name: .easeOut) : CAMediaTimingFunction(name: .easeIn)
            
            window.animator().setFrame(finalFrame, display: true)
        }, completionHandler: {
            self.isAnimating = false
            completion?()
        })
    }
    
    // MARK: - Window Event Handling
    
    override func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard !isAnimating else { return false }
        
        if let windowManager = windowManager {
            // Animation vor dem Schließen
            windowManager.closeWindow(self.window!)
            return false // Wir schließen manuell
        }
        
        return true
    }
    
    // MARK: - Detachable Window Support
    
    func setupDetachableWindow(with viewController: NSViewController, size: CGSize) {
        setupWindow(
            with: viewController,
            style: [.titled, .closable, .resizable, .miniaturizable],
            animation: .slideUp,
            size: size
        )
        
        // Window für Detachable Mode konfigurieren
        if let popupWindow = window as? PopupWindow {
            popupWindow.setBlurEnabled(true)
            popupWindow.applyModernMacOSStyle()
        }
    }
}