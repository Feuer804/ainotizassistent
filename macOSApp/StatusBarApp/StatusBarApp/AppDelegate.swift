//
//  AppDelegate.swift
//  StatusBarApp
//
//  App Delegate für die Menüleisten-App mit NSStatusItem-Integration
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate, WindowManagerDelegate {

    var statusBarController: StatusBarController?
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Hauptmenü für die App verbergen (für reine Statusleisten-Apps)
        NSApp.setActivationPolicy(.accessory)
        
        // StatusBarController initialisieren
        statusBarController = StatusBarController()
        statusBarController?.setupStatusBarItem()
        
        // WindowManager initialisieren
        WindowManager.shared.delegate = self
        
        print("StatusBarApp gestartet - Window-Management System aktiv")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Settings bereinigen
        if let statusBarController = statusBarController {
            statusBarController.settingsCoordinator?.cleanup()
        }
        
        // WindowManager bereinigen
        WindowManager.shared.cleanup()
        WindowAnimationHelper.shared.cleanup()
        WindowPositionManager.shared.cleanup()
        
        // StatusBarController bereinigen
        statusBarController?.cleanup()
        
        // GlobalShortcutManager bereinigen
        GlobalShortcutManager.shared.cleanup()
    }
    // MARK: - WindowManagerDelegate
    
    func windowManager(_ manager: WindowManager, didOpenWindow window: NSWindow) {
        print("Fenster geöffnet: \(window.title)")
        
        // Optional: StatusBarController informieren
        statusBarController?.updateStatus()
    }
    
    func windowManager(_ manager: WindowManager, didCloseWindow window: NSWindow) {
        print("Fenster geschlossen: \(window.title)")
        
        // Optional: StatusBarController informieren
        statusBarController?.updateStatus()
    }
    
    func windowManager(_ manager: WindowManager, didReceiveEscKey window: NSWindow) {
        print("ESC-Taste empfangen für Window: \(window.title)")
        
        // Optional: Feedback zur UI hinzufügen
        WindowAnimationHelper.shared.shakeWindow(window, intensity: 5.0, duration: 0.2)
    }
    
    // MARK: - Window-Management Actions
    
    func showDemoPopup() {
        let demoVC = DemoPopupViewController()
        WindowManager.shared.openPopupWindow(
            with: demoVC,
            animation: .bounce,
            size: CGSize(width: 400, height: 300),
            shouldCloseOnEsc: true
        )
    }
    
    func showDetachableDemo() {
        let demoVC = DemoPopupViewController()
        WindowManager.shared.showDetachablePopup(
            with: demoVC,
            size: CGSize(width: 500, height: 400)
        )
    }
    
    func showMultiWindowDemo() {
        // Mehrere Windows öffnen für Multi-Window Demo
        for i in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                let demoVC = DemoPopupViewController(title: "Window \(i)")
                let animations: [WindowAnimationType] = [.scaleUp, .slideUp, .bounce]
                
                WindowManager.shared.openPopupWindow(
                    with: demoVC,
                    animation: animations[i % animations.count],
                    size: CGSize(width: 350, height: 250),
                    shouldCloseOnEsc: true
                )
            }
        }
    }
    
    func closeAllWindows() {
        WindowManager.shared.closeAllWindows(animation: .fade)
    }
    
    // MARK: - Settings Management
    
    func showSettings() {
        if let statusBarController = statusBarController {
            statusBarController.settingsCoordinator?.showCompleteSettings()
        }
    }
    
    func exportSettings() -> Bool {
        if let statusBarController = statusBarController {
            return statusBarController.settingsCoordinator?.exportSettings() ?? false
        }
        return false
    }
    
    func importSettings(from url: URL) -> Bool {
        if let statusBarController = statusBarController {
            return statusBarController.settingsCoordinator?.importSettings(from: url) ?? false
        }
        return false
    }
    
    func resetSettings() -> Bool {
        if let statusBarController = statusBarController {
            return statusBarController.settingsCoordinator?.resetSettings() ?? false
        }
        return false
    }

}

// MARK: - StatusBarController Extension
extension AppDelegate {
    func getStatusBarController() -> StatusBarController? {
        return statusBarController
    }
}