//
//  DetachableWindowController.swift
//  StatusBarApp
//
//  Window Controller für detachable popup windows mit ESC closing
//

import Cocoa
import CoreGraphics

@objc class DetachableWindowController: AnimatedWindowController {
    
    // MARK: - Properties
    
    private var isDetached = false
    private var originalParentWindow: NSWindow?
    private var draggingOffset: CGPoint = .zero
    private var isDragging = false
    
    private let detachAnimationDuration: TimeInterval = 0.4
    private let detachDistance: CGFloat = 200
    
    // MARK: - Window Lifecycle
    
    override func setupDetachableWindow(with viewController: NSViewController, size: CGSize) {
        super.setupDetachableWindow(with: viewController, size: size)
        
        if let window = self.window {
            setupDetachableWindow(window)
        }
    }
    
    private func setupDetachableWindow(_ window: NSWindow) {
        // Window für Dragging konfigurieren
        setupWindowDragging()
        
        // Mouse Event Handling
        setupMouseEventHandling()
        
        // Keyboard Event Handling für ESC
        setupKeyboardEventHandling()
        
        // ESC-close konfigurieren
        shouldCloseOnEsc = true
        closeBehavior = .detached
        
        print("Detachable Window konfiguriert")
    }
    
    // MARK: - Window Dragging
    
    private func setupWindowDragging() {
        guard let window = self.window else { return }
        
        // Content View für Dragging aktivieren
        if let contentView = window.contentView {
            contentView.addCursorRect(contentView.bounds, cursor: .pointingHand)
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            
            // Titlebar area auch für Dragging aktivieren
            let titlebarFrame = window.frame
            let contentFrame = contentView.frame
            
            let titlebarHeight = titlebarFrame.height - contentFrame.height
            if titlebarHeight > 0 {
                let titlebarRect = NSRect(
                    x: 0,
                    y: contentFrame.height,
                    width: contentFrame.width,
                    height: titlebarHeight
                )
                
                let titlebarView = NSView(frame: titlebarRect)
                titlebarView.wantsLayer = true
                titlebarView.layer?.backgroundColor = NSColor.clear.cgColor
                titlebarView.addCursorRect(titlebarView.bounds, cursor: .pointingHand)
                contentView.addSubview(titlebarView, positioned: .below, relativeTo: nil)
                
                // Drag handlers für titlebar
                let titlebarDragArea = DragAreaView(frame: titlebarRect)
                titlebarDragArea.windowManager = self
                contentView.addSubview(titlebarDragArea, positioned: .above, relativeTo: titlebarView)
            }
        }
    }
    
    private func setupMouseEventHandling() {
        guard let window = self.window,
              let contentView = window.contentView else { return }
        
        // Mouse tracking für das gesamte Content View
        let mouseTracker = MouseTrackerView(frame: contentView.bounds)
        mouseTracker.windowManager = self
        contentView.addSubview(mouseTracker, positioned: .above, relativeTo: nil)
        
        // Content View click detection für Escape
        contentView.addGestureRecognizer(
            NSClickGestureRecognizer(target: self, action: #selector(handleContentViewClick(_:)))
        )
    }
    
    private func setupKeyboardEventHandling() {
        // Global keyboard monitor für ESC key
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                if self?.shouldCloseOnEsc == true {
                    self?.handleEscKeyPress()
                    return nil // Event konsumieren
                }
            }
            return event
        }
    }
    
    // MARK: - Detachment Logic
    
    /// Detacht das Window von der StatusBar-Position
    func detachWindow() {
        guard !isDetached, let window = self.window else { return }
        
        isDetached = true
        originalParentWindow = window
        
        // Animation für Detachment
        let currentFrame = window.frame
        let detachedFrame = NSRect(
            x: currentFrame.origin.x + detachDistance,
            y: currentFrame.origin.y - detachDistance / 2,
            width: currentFrame.width,
            height: currentFrame.height
        )
        
        // Disable ESC closing während der Animation
        shouldCloseOnEsc = false
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = detachAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            window.animator().setFrame(detachedFrame, display: true)
            
            // Window properties ändern
            window.level = NSWindow.Level(rawValue: 1000 + Int(detachDistance))
            
        }, completionHandler: {
            // ESC closing wieder aktivieren
            self.shouldCloseOnEsc = true
            
            print("Window detached")
        })
    }
    
    /// Re-attacht das Window an die ursprüngliche Position
    func reattachWindow() {
        guard isDetached, let window = self.window,
              let originalFrame = originalParentWindow?.frame else { return }
        
        isDetached = false
        
        // Animation für Re-attachment
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = detachAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            window.animator().setFrame(originalFrame, display: true)
            window.level = NSWindow.Level(rawValue: 1000)
            
        }, completionHandler: {
            print("Window reattached")
        })
    }
    
    /// Prüft ob das Window detached ist
    var isCurrentlyDetached: Bool {
        return isDetached
    }
    
    // MARK: - Event Handlers
    
    @objc private func handleEscKeyPress() {
        if isDetached {
            // Detached windows können nur durch Window-Close geschlossen werden
            closeWindow(withAnimation: .fade)
        } else {
            // Attached windows schließen mit ESC
            closeWindow(withAnimation: .scaleUp)
        }
    }
    
    @objc private func handleContentViewClick(_ sender: Any?) {
        if isDetached {
            // Bring window to front when clicked while detached
            bringToFront()
        }
    }
    
    // MARK: - Window Movement
    
    func startDragging(at point: CGPoint) {
        guard !isAnimating else { return }
        
        isDragging = true
        if let window = self.window {
            draggingOffset = CGPoint(
                x: point.x - window.frame.origin.x,
                y: point.y - window.frame.origin.y
            )
        }
        
        print("Window dragging started")
    }
    
    func dragTo(point: CGPoint) {
        guard isDragging, let window = self.window else { return }
        
        let newOrigin = CGPoint(
            x: point.x - draggingOffset.x,
            y: point.y - draggingOffset.y
        )
        
        let newFrame = NSRect(
            origin: newOrigin,
            size: window.frame.size
        )
        
        window.setFrame(newFrame, display: true, animate: false)
        
        // Check if we should trigger detachment
        let distanceFromOrigin = hypot(
            newOrigin.x - (originalParentWindow?.frame.origin.x ?? 0),
            newOrigin.y - (originalParentWindow?.frame.origin.y ?? 0)
        )
        
        if distanceFromOrigin > detachDistance * 0.8 && !isDetached {
            detachWindow()
        }
    }
    
    func endDragging() {
        isDragging = false
        draggingOffset = .zero
        
        print("Window dragging ended")
    }
    
    // MARK: - Window Management
    
    func bringToFront() {
        guard let window = self.window else { return }
        
        window.level = NSWindow.Level(rawValue: 2000)
        window.makeKeyAndOrderFront(nil)
        
        print("Window brought to front")
    }
    
    func closeWindow(withAnimation animation: WindowAnimationType = .scaleUp) {
        if let windowManager = windowManager {
            windowManager.closeWindow(self.window!, animation: animation)
        } else {
            super.windowShouldClose(self.window!)
        }
    }
    
    // MARK: - Window States
    
    func minimizeWindow() {
        self.window?.miniaturize(nil)
    }
    
    func zoomWindow() {
        self.window?.zoom(nil)
    }
    
    func closeWindow() {
        self.window?.close()
    }
}

// MARK: - Drag Area View für Titlebar Dragging

@objc class DragAreaView: NSView {
    
    weak var windowManager: DetachableWindowController?
    private var isMouseDown = false
    private var dragStartPoint: CGPoint = .zero
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // View für Dragging konfigurieren
        isOpaque = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        
        // Cursor setzen
        addCursorRect(bounds, cursor: .pointingHand)
    }
    
    override func mouseDown(with event: NSEvent) {
        isMouseDown = true
        dragStartPoint = event.locationInWindow ?? .zero
        windowManager?.startDragging(at: dragStartPoint)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isMouseDown, let window = windowManager?.window else { return }
        
        let currentPoint = event.locationInWindow ?? .zero
        windowManager?.dragTo(point: currentPoint)
    }
    
    override func mouseUp(with event: NSEvent) {
        isMouseDown = false
        windowManager?.endDragging()
    }
    
    override func cursorUpdate(with event: NSEvent) {
        if !isMouseDown {
            addCursorRect(bounds, cursor: .pointingHand)
        }
    }
}

// MARK: - Mouse Tracker View für Content Area

@objc class MouseTrackerView: NSView {
    
    weak var windowManager: DetachableWindowController?
    private var isDragging = false
    private var dragOffset: CGPoint = .zero
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Transparent view für Mouse Tracking
        isOpaque = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func mouseDown(with event: NSEvent) {
        // Nur bei detached Windows für Dragging verwenden
        guard windowManager?.isCurrentlyDetached == true else { return }
        
        isDragging = true
        let location = event.locationInWindow ?? .zero
        dragOffset = CGPoint(
            x: location.x,
            y: location.y
        )
        
        windowManager?.startDragging(at: location)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging, windowManager?.isCurrentlyDetached == true else { return }
        
        let currentLocation = event.locationInWindow ?? .zero
        windowManager?.dragTo(point: currentLocation)
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
        windowManager?.endDragging()
    }
}