//
//  WindowPositionManager.swift
//  StatusBarApp
//
//  Manager für Window-Positionierung, Z-Index Management und Multi-Window Support
//

import Cocoa
import CoreGraphics

@objc enum WindowPosition: Int {
    case topCenter
    case bottomCenter
    case leftCenter
    case rightCenter
    case topRight
    case topLeft
    case bottomRight
    case bottomLeft
    case center
    case relativeToStatusItem
}

@objc enum WindowAnchor: Int {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
    case statusBar
}

@objc class WindowPositionManager: NSObject {
    
    // MARK: - Properties
    
    static let shared = WindowPositionManager()
    
    private var windowPositions: [NSWindow: WindowPosition] = [:]
    private var windowAnchors: [NSWindow: WindowAnchor] = [:]
    private var zIndexRegistry: [NSWindow: Int] = [:]
    private var reservedAreas: [CGRect] = []
    
    // Spacing Konstanten
    private let windowPadding: CGFloat = 20.0
    private let statusBarOffset: CGFloat = 10.0
    private let screenPadding: CGFloat = 50.0
    
    // MARK: - Window Positioning
    
    /// Positioniert ein Window an der angegebenen Position
    func positionWindow(
        _ window: NSWindow,
        at position: WindowPosition,
        relativeTo referenceWindow: NSWindow? = nil
    ) {
        windowPositions[window] = position
        
        guard let screen = getAvailableScreen(for: window) else { return }
        let screenRect = screen.frame
        let windowSize = window.frame.size
        
        var targetRect = calculateTargetRect(
            for: windowSize,
            at: position,
            screenRect: screenRect,
            relativeTo: referenceWindow
        )
        
        // Überlappungen mit reservierten Bereichen vermeiden
        targetRect = avoidReservedAreas(targetRect)
        
        // Window positionieren
        window.setFrame(targetRect, display: true, animate: false)
        
        print("Window positioniert: \(position.rawValue) auf Bildschirm \(screen)")
    }
    
    /// Verankert ein Window an einer bestimmten Stelle
    func anchorWindow(
        _ window: NSWindow,
        to anchor: WindowAnchor,
        withOffset offset: CGPoint = .zero
    ) {
        windowAnchors[window] = anchor
        
        let screenRect = getAvailableScreen(for: window)?.frame ?? NSScreen.main?.frame ?? .zero
        let windowSize = window.frame.size
        
        let anchoredRect = calculateAnchoredRect(
            for: windowSize,
            anchor: anchor,
            screenRect: screenRect,
            offset: offset
        )
        
        window.setFrame(anchoredRect, display: true, animate: false)
        
        print("Window verankert: \(anchor.rawValue)")
    }
    
    // MARK: - Z-Index Management
    
    /// Bringt ein Window nach vorne
    func bringToFront(_ window: NSWindow) {
        setZIndex(window, level: getNextHighestZIndex())
    }
    
    /// Sendet ein Window nach hinten
    func sendToBack(_ window: NSWindow) {
        setZIndex(window, level: 0)
    }
    
    /// Setzt das Z-Index Level für ein Window
    func setZIndex(_ window: NSWindow, level: Int) {
        zIndexRegistry[window] = level
        window.level = NSWindow.Level(rawValue: level)
        
        print("Z-Index für Window gesetzt: \(level)")
    }
    
    /// Gibt das nächste verfügbare Z-Index zurück
    private func getNextHighestZIndex() -> Int {
        return (zIndexRegistry.values.max() ?? 999) + 1
    }
    
    // MARK: - Multi-Window Management
    
    /// Organisiert mehrere Windows in einem Grid-Layout
    func organizeWindowsInGrid(_ windows: [NSWindow], columns: Int = 3) {
        guard !windows.isEmpty else { return }
        
        let rows = Int(ceil(Double(windows.count) / Double(columns)))
        let screenRect = getAvailableScreen(for: windows.first!)?.frame ?? NSScreen.main?.frame ?? .zero
        
        let spacing: CGFloat = 20
        let totalWidth = (screenRect.width - CGFloat(columns + 1) * spacing) / CGFloat(columns)
        let totalHeight = (screenRect.height - CGFloat(rows + 1) * spacing) / CGFloat(rows)
        
        for (index, window) in windows.enumerated() {
            let column = index % columns
            let row = index / columns
            
            let x = screenRect.origin.x + spacing + CGFloat(column) * (totalWidth + spacing)
            let y = screenRect.origin.y + screenRect.height - spacing - CGFloat(row + 1) * (totalHeight + spacing)
            
            let rect = NSRect(
                x: x,
                y: y,
                width: totalWidth,
                height: totalHeight
            )
            
            window.setFrame(rect, display: true, animate: true)
            setZIndex(window, level: getNextHighestZIndex())
        }
        
        print("Windows in Grid organisiert: \(rows)x\(columns)")
    }
    
    /// Stapelt Windows vertikal mit Offsets
    func stackWindowsVertically(_ windows: [NSWindow], offset: CGFloat = 30) {
        guard let primaryScreen = getAvailableScreen(for: windows.first ?? NSApplication.shared.windows.first!) else { return }
        
        let screenRect = primaryScreen.frame
        var currentY = screenRect.origin.y + screenRect.height - screenPadding
        
        for window in windows {
            let windowRect = window.frame
            let newRect = NSRect(
                x: screenRect.origin.x + (screenRect.width - windowRect.width) / 2,
                y: currentY - windowRect.height,
                width: windowRect.width,
                height: windowRect.height
            )
            
            window.setFrame(newRect, display: true, animate: true)
            setZIndex(window, level: getNextHighestZIndex())
            
            currentY -= windowRect.height + offset
        }
        
        print("Windows vertikal gestapelt")
    }
    
    /// Arrangeiert Windows in einer Kaskade
    func cascadeWindows(_ windows: [NSWindow], offset: CGPoint = CGPoint(x: 30, y: -30)) {
        guard let primaryScreen = getAvailableScreen(for: windows.first ?? NSApplication.shared.windows.first!) else { return }
        
        let screenRect = primaryScreen.frame
        var currentOrigin = CGPoint(
            x: screenRect.origin.x + screenPadding,
            y: screenRect.origin.y + screenRect.height - screenPadding
        )
        
        for window in windows {
            let windowRect = window.frame
            let newRect = NSRect(
                origin: currentOrigin,
                size: windowRect.size
            )
            
            window.setFrame(newRect, display: true, animate: true)
            setZIndex(window, level: getNextHighestZIndex())
            
            currentOrigin.x += offset.x
            currentOrigin.y += offset.y
        }
        
        print("Windows in Kaskade organisiert")
    }
    
    // MARK: - Screen Management
    
    /// Gibt den besten verfügbaren Bildschirm für ein Window zurück
    func getAvailableScreen(for window: NSWindow) -> NSScreen? {
        if let currentScreen = window.screen {
            return currentScreen
        }
        
        // Fallback auf den Bildschirm mit der besten verfügbaren Auflösung
        return NSScreen.screens.max { screen1, screen2 in
            screen1.frame.size.width * screen1.frame.size.height <
            screen2.frame.size.width * screen2.frame.size.height
        }
    }
    
    /// Prüft ob ein Window auf dem Bildschirm sichtbar ist
    func isWindowVisible(on screen: NSScreen, window: NSWindow) -> Bool {
        let screenRect = screen.frame
        let windowRect = window.frame
        
        return windowRect.intersects(screenRect)
    }
    
    // MARK: - Reserved Area Management
    
    /// Markiert einen Bereich als reserviert (für andere Windows)
    func reserveArea(_ area: CGRect) {
        reservedAreas.append(area)
        print("Bereich reserviert: \(area)")
    }
    
    /// Entfernt eine reservierte Area
    func unreserveArea(_ area: CGRect) {
        reservedAreas.removeAll { $0 == area }
        print("Reservierung entfernt: \(area)")
    }
    
    /// Leert alle reservierten Areas
    func clearReservedAreas() {
        reservedAreas.removeAll()
        print("Alle reservierten Areas geleert")
    }
    
    // MARK: - Internal Calculation Methods
    
    private func calculateTargetRect(
        for windowSize: CGSize,
        at position: WindowPosition,
        screenRect: CGRect,
        relativeTo referenceWindow: NSWindow?
    ) -> NSRect {
        
        var targetRect = NSRect.zero
        
        switch position {
        case .center:
            targetRect = NSRect(
                x: screenRect.origin.x + (screenRect.width - windowSize.width) / 2,
                y: screenRect.origin.y + (screenRect.height - windowSize.height) / 2,
                width: windowSize.width,
                height: windowSize.height
            )
            
        case .topCenter:
            targetRect = NSRect(
                x: screenRect.origin.x + (screenRect.width - windowSize.width) / 2,
                y: screenRect.origin.y + screenRect.height - windowSize.height - screenPadding,
                width: windowSize.width,
                height: windowSize.height
            )
            
        case .bottomCenter:
            targetRect = NSRect(
                x: screenRect.origin.x + (screenRect.width - windowSize.width) / 2,
                y: screenRect.origin.y + screenPadding,
                width: windowSize.width,
                height: windowSize.height
            )
            
        case .leftCenter:
            targetRect = NSRect(
                x: screenRect.origin.x + screenPadding,
                y: screenRect.origin.y + (screenRect.height - windowSize.height) / 2,
                width: windowSize.width,
                height: windowSize.height
            )
            
        case .rightCenter:
            targetRect = NSRect(
                x: screenRect.origin.x + screenRect.width - windowSize.width - screenPadding,
                y: screenRect.origin.y + (screenRect.height - windowSize.height) / 2,
                width: windowSize.width,
                height: windowSize.height
            )
            
        case .relativeToStatusItem:
            targetRect = calculatePositionRelativeToStatusItem(windowSize: windowSize, screenRect: screenRect)
            
        default:
            // Alle Ecken
            let padding: CGFloat = windowPadding
            switch position {
            case .topLeft:
                targetRect.origin = CGPoint(x: screenRect.origin.x + padding,
                                          y: screenRect.origin.y + screenRect.height - windowSize.height - padding)
            case .topRight:
                targetRect.origin = CGPoint(x: screenRect.origin.x + screenRect.width - windowSize.width - padding,
                                          y: screenRect.origin.y + screenRect.height - windowSize.height - padding)
            case .bottomLeft:
                targetRect.origin = CGPoint(x: screenRect.origin.x + padding,
                                          y: screenRect.origin.y + padding)
            case .bottomRight:
                targetRect.origin = CGPoint(x: screenRect.origin.x + screenRect.width - windowSize.width - padding,
                                          y: screenRect.origin.y + padding)
            default:
                break
            }
            targetRect.size = windowSize
        }
        
        // Bounds prüfen
        targetRect = fitRectWithinBounds(targetRect, bounds: screenRect)
        
        return targetRect
    }
    
    private func calculatePositionRelativeToStatusItem(windowSize: CGSize, screenRect: CGRect) -> NSRect {
        guard let statusBarController = (NSApp.delegate as? AppDelegate)?.getStatusBarController(),
              let statusItem = statusBarController.statusItem,
              let button = statusItem.button else {
            // Fallback auf center
            return calculateTargetRect(for: windowSize, at: .center, screenRect: screenRect, relativeTo: nil)
        }
        
        let buttonFrame = button.convert(button.bounds, to: nil)
        let globalButtonFrame = button.convert(buttonFrame, to: screenRect)
        
        var targetRect = NSRect(
            x: globalButtonFrame.midX - windowSize.width / 2,
            y: globalButtonFrame.minY - windowSize.height - statusBarOffset,
            width: windowSize.width,
            height: windowSize.height
        )
        
        // Bounds prüfen
        targetRect = fitRectWithinBounds(targetRect, bounds: screenRect)
        
        return targetRect
    }
    
    private func calculateAnchoredRect(
        for windowSize: CGSize,
        anchor: WindowAnchor,
        screenRect: CGRect,
        offset: CGPoint
    ) -> NSRect {
        
        var rect = NSRect(size: windowSize)
        
        switch anchor {
        case .topLeft:
            rect.origin = CGPoint(
                x: screenRect.origin.x + offset.x,
                y: screenRect.origin.y + screenRect.height - windowSize.height + offset.y
            )
            
        case .topRight:
            rect.origin = CGPoint(
                x: screenRect.origin.x + screenRect.width - windowSize.width + offset.x,
                y: screenRect.origin.y + screenRect.height - windowSize.height + offset.y
            )
            
        case .bottomLeft:
            rect.origin = CGPoint(
                x: screenRect.origin.x + offset.x,
                y: screenRect.origin.y + offset.y
            )
            
        case .bottomRight:
            rect.origin = CGPoint(
                x: screenRect.origin.x + screenRect.width - windowSize.width + offset.x,
                y: screenRect.origin.y + offset.y
            )
            
        case .center:
            rect.origin = CGPoint(
                x: screenRect.origin.x + (screenRect.width - windowSize.width) / 2 + offset.x,
                y: screenRect.origin.y + (screenRect.height - windowSize.height) / 2 + offset.y
            )
            
        case .statusBar:
            rect.origin = calculatePositionRelativeToStatusItem(
                windowSize: windowSize,
                screenRect: screenRect
            ).origin + offset
        }
        
        return fitRectWithinBounds(rect, bounds: screenRect)
    }
    
    private func fitRectWithinBounds(_ rect: NSRect, bounds: CGRect) -> NSRect {
        var fittedRect = rect
        
        // X-Position anpassen
        if fittedRect.minX < bounds.minX {
            fittedRect.origin.x = bounds.minX
        }
        if fittedRect.maxX > bounds.maxX {
            fittedRect.origin.x = bounds.maxX - fittedRect.width
        }
        
        // Y-Position anpassen
        if fittedRect.minY < bounds.minY {
            fittedRect.origin.y = bounds.minY
        }
        if fittedRect.maxY > bounds.maxY {
            fittedRect.origin.y = bounds.maxY - fittedRect.height
        }
        
        return fittedRect
    }
    
    private func avoidReservedAreas(_ rect: NSRect) -> NSRect {
        var adjustedRect = rect
        
        for reservedArea in reservedAreas {
            if rect.intersects(reservedArea) {
                // Adjust position to avoid overlap
                if rect.origin.y < reservedArea.maxY && rect.maxY > reservedArea.origin.y {
                    adjustedRect.origin.y = reservedArea.maxY + windowPadding
                }
            }
        }
        
        return adjustedRect
    }
    
    // MARK: - Utility Methods
    
    func getCurrentWindowPositions() -> [NSWindow: WindowPosition] {
        return windowPositions
    }
    
    func getCurrentZIndexes() -> [NSWindow: Int] {
        return zIndexRegistry
    }
    
    func cleanup() {
        windowPositions.removeAll()
        windowAnchors.removeAll()
        zIndexRegistry.removeAll()
        reservedAreas.removeAll()
        
        print("WindowPositionManager bereinigt")
    }
}