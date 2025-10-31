//
//  WindowManager.swift
//  StatusBarApp
//
//  Hauptmanager für popup-ähnliche Fenster mit Animationen
//

import Cocoa
import CoreGraphics

@objc enum WindowAnimationType: Int {
    case scaleUp
    case slideUp
    case bounce
    case fade
    case slideFromRight
    case slideFromLeft
}

@objc enum WindowCloseBehavior: Int {
    case autoClose
    case manualClose
    case escClose
    case clickOutside
    case detached
}

protocol WindowManagerDelegate: AnyObject {
    func windowManager(_ manager: WindowManager, didOpenWindow window: NSWindow)
    func windowManager(_ manager: WindowManager, didCloseWindow window: NSWindow)
    func windowManager(_ manager: WindowManager, didReceiveEscKey window: NSWindow)
}

@objc class WindowManager: NSObject {
    
    // MARK: - Properties
    
    static let shared = WindowManager()
    
    weak var delegate: WindowManagerDelegate?
    
    private var openWindows: Set<NSWindow> = []
    private var windowControllers: [NSWindow: NSWindowController] = [:]
    private var zIndexCounter: Int = 1000
    
    private let animationQueue = OperationQueue()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        animationQueue.maxConcurrentOperationCount = 5
        setupKeyboardMonitoring()
    }
    
    // MARK: - Window Management
    
    /// Öffnet ein neues popup-Fenster mit Animation
    func openPopupWindow(
        with viewController: NSViewController,
        animation: WindowAnimationType = .scaleUp,
        size: CGSize = CGSize(width: 400, height: 300),
        style: NSWindow.StyleMask = [.titled, .closable, .resizable],
        shouldCloseOnEsc: Bool = true,
        closeBehavior: WindowCloseBehavior = .escClose,
        completion: ((NSWindow) -> Void)? = nil
    ) {
        
        // Neuen Window Controller erstellen
        let windowController = AnimatedWindowController()
        windowController.windowManager = self
        windowController.closeBehavior = closeBehavior
        windowController.shouldCloseOnEsc = shouldCloseOnEsc
        
        // Window konfigurieren
        windowController.setupWindow(
            with: viewController,
            style: style,
            animation: animation,
            size: size
        )
        
        guard let window = windowController.window else { return }
        
        // Window zur Liste hinzufügen
        openWindows.insert(window)
        windowControllers[window] = windowController
        
        // Position berechnen und setzen
        positionWindow(window)
        
        // Z-Index setzen
        window.level = NSWindow.Level(rawValue: zIndexCounter)
        zIndexCounter += 1
        
        // Window anzeigen
        windowController.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        
        // Animation starten
        windowController.animateWindowOpen(animation: animation) {
            completion?(window)
            self.delegate?.windowManager(self, didOpenWindow: window)
        }
        
        print("Popup-Fenster geöffnet mit Animation: \(animation.rawValue)")
    }
    
    /// Schließt ein Fenster mit Animation
    func closeWindow(_ window: NSWindow, animation: WindowAnimationType = .scaleUp) {
        guard let windowController = windowControllers[window] else { return }
        
        // Animation ausführen
        windowController.animateWindowClose(animation: animation) { [weak self] in
            // Fenster bereinigen
            windowController.close()
            self?.removeWindow(window)
        }
    }
    
    /// Schließt alle offenen Fenster
    func closeAllWindows(animation: WindowAnimationType = .scaleUp) {
        let windowsToClose = Array(openWindows)
        for window in windowsToClose {
            closeWindow(window, animation: animation)
        }
    }
    
    /// Zeigt ein detachable popup
    func showDetachablePopup(
        with viewController: NSViewController,
        size: CGSize = CGSize(width: 500, height: 400)
    ) {
        
        let windowController = DetachableWindowController()
        windowController.windowManager = self
        
        // Konfigurierbares Window für Detachable Mode
        windowController.setupDetachableWindow(
            with: viewController,
            size: size
        )
        
        guard let window = windowController.window else { return }
        
        // Window Management
        openWindows.insert(window)
        windowControllers[window] = windowController
        
        // Positionierung für Popup
        positionWindow(window)
        window.level = NSWindow.Level(rawValue: zIndexCounter)
        zIndexCounter += 1
        
        // Animation und Anzeige
        windowController.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        
        windowController.animateWindowOpen(animation: .slideUp) { [weak self] in
            self?.delegate?.windowManager(self!, didOpenWindow: window)
        }
    }
    
    // MARK: - Window Positioning
    
    private func positionWindow(_ window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main,
              let statusBarController = (NSApp.delegate as? AppDelegate)?.getStatusBarController(),
              let statusItem = statusBarController.statusItem,
              let button = statusItem.button else { return }
        
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = screen.convert(screen.frame, from: nil)
        let globalButtonFrame = button.convert(buttonFrame, to: screenFrame)
        
        // Position oberhalb des Status Items
        let windowSize = window.frame.size
        var windowOrigin = CGPoint(
            x: globalButtonFrame.midX - windowSize.width / 2,
            y: globalButtonFrame.minY - windowSize.height - 10
        )
        
        // Sicherstellen, dass das Window im sichtbaren Bereich ist
        let minX = screenFrame.minX + 20
        let maxX = screenFrame.maxX - windowSize.width - 20
        let minY = screenFrame.minY + 50
        let maxY = screenFrame.maxY - windowSize.height - 20
        
        windowOrigin.x = max(minX, min(maxX, windowOrigin.x))
        windowOrigin.y = max(minY, min(maxY, windowOrigin.y))
        
        window.setFrameOrigin(windowOrigin)
    }
    
    // MARK: - Event Handling
    
    @objc private func handleEscKey(_ sender: Any?) {
        guard let window = NSApplication.shared.keyWindow else { return }
        
        if let controller = windowControllers[window],
           controller.shouldCloseOnEsc {
            closeWindow(window)
            delegate?.windowManager(self, didReceiveEscKey: window)
        }
    }
    
    // MARK: - Internal Methods
    
    func removeWindow(_ window: NSWindow) {
        openWindows.remove(window)
        windowControllers.removeValue(forKey: window)
        print("Fenster aus WindowManager entfernt")
    }
    
    func bringWindowToFront(_ window: NSWindow) {
        window.level = NSWindow.Level(rawValue: zIndexCounter)
        zIndexCounter += 1
        window.makeKeyAndOrderFront(nil)
    }
    
    func isWindowOpen(_ window: NSWindow) -> Bool {
        return openWindows.contains(window)
    }
    
    func getOpenWindows() -> [NSWindow] {
        return Array(openWindows)
    }
    
    // MARK: - Keyboard Monitoring
    
    private func setupKeyboardMonitoring() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC Key
                self?.handleEscKey(event)
                return nil // Event konsumieren
            }
            return event
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        closeAllWindows(animation: .fade)
        animationQueue.cancelAllOperations()
    }
}