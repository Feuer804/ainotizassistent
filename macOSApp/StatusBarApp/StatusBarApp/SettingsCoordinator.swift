//
//  SettingsCoordinator.swift
//  StatusBarApp
//
//  Hauptkoordinator für das Settings-Management mit modalem Popup
//

import Cocoa
import SwiftUI

class SettingsCoordinator: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isShowingSettings = false
    @Published var currentSettingsSection: SettingsSection = .general
    @Published var settings: AppSettings = AppSettings()
    @Published var validationErrors: [String: String] = [:]
    
    // MARK: - Window Management
    
    private var settingsWindowController: SettingsWindowController?
    private let windowManager = SettingsWindowManager.shared
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupSettings()
        print("SettingsCoordinator initialisiert")
    }
    
    // MARK: - Setup
    
    private func setupSettings() {
        // Settings laden
        loadSettings()
        
        // Observer für Settings-Änderungen
        setupSettingsObservers()
        
        print("Settings-Setup abgeschlossen")
    }
    
    private func setupSettingsObservers() {
        // Settings-Änderungen überwachen
        NotificationCenter.default.addObserver(
            forName: .settingsChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleSettingsChange(notification)
        }
    }
    
    // MARK: - Settings Sections
    
    enum SettingsSection: String, CaseIterable {
        case general = "Allgemein"
        case ki = "KI-Einstellungen"
        case storage = "Storage"
        case autosave = "Auto-Save"
        case shortcuts = "Shortcuts"
        case notifications = "Benachrichtigungen"
        case privacy = "Datenschutz"
        case about = "Über & Hilfe"
        case onboarding = "Onboarding"
    }
    
    // MARK: - Settings Management
    
    func showCompleteSettings() {
        currentSettingsSection = .general
        showSettingsWindow()
    }
    
    func showKISettings() {
        currentSettingsSection = .ki
        showSettingsWindow()
    }
    
    func showStorageSettings() {
        currentSettingsSection = .storage
        showSettingsWindow()
    }
    
    func showShortcutsSettings() {
        currentSettingsSection = .shortcuts
        showSettingsWindow()
    }
    
    func showNotificationSettings() {
        currentSettingsSection = .notifications
        showSettingsWindow()
    }
    
    func showHelp() {
        currentSettingsSection = .about
        showSettingsWindow()
    }
    
    func toggleAutoSave() {
        settings.autoSave.enabled.toggle()
        saveSettings()
        print("Auto-Save umgeschaltet: \(settings.autoSave.enabled)")
    }
    
    // MARK: - Window Management
    
    private func showSettingsWindow() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(coordinator: self)
        }
        
        settingsWindowController?.showWindow()
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        print("Settings-Fenster geöffnet")
    }
    
    private func hideSettingsWindow() {
        settingsWindowController?.close()
        print("Settings-Fenster geschlossen")
    }
    
    // MARK: - Settings Persistence
    
    private func saveSettings() {
        do {
            try SettingsPersistence.shared.save(settings)
            NotificationCenter.default.post(name: .settingsChanged, object: settings)
            print("Settings erfolgreich gespeichert")
        } catch {
            print("Fehler beim Speichern der Settings: \(error)")
            showErrorAlert("Speicherfehler", "Settings konnten nicht gespeichert werden: \(error.localizedDescription)")
        }
    }
    
    private func loadSettings() {
        do {
            settings = try SettingsPersistence.shared.load()
            print("Settings erfolgreich geladen")
        } catch {
            print("Fehler beim Laden der Settings: \(error)")
            // Verwende Standard-Settings bei Fehler
            settings = AppSettings()
            showErrorAlert("Ladefehler", "Standard-Settings werden verwendet: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Export/Import
    
    func exportSettings() -> Bool {
        do {
            let exportURL = try SettingsExportImport.shared.export(settings)
            print("Settings exportiert nach: \(exportURL.path)")
            
            // Export-URL öffnen
            NSWorkspace.shared.selectFile(exportURL.path, inFileViewerRootedAtPath: exportURL.deletingLastPathComponent().path)
            
            return true
        } catch {
            print("Fehler beim Export: \(error)")
            showErrorAlert("Exportfehler", "Settings konnten nicht exportiert werden: \(error.localizedDescription)")
            return false
        }
    }
    
    func importSettings(from url: URL) -> Bool {
        do {
            let importedSettings = try SettingsExportImport.shared.import(from: url)
            settings = importedSettings
            saveSettings()
            
            print("Settings erfolgreich importiert")
            return true
        } catch {
            print("Fehler beim Import: \(error)")
            showErrorAlert("Importfehler", "Settings konnten nicht importiert werden: \(error.localizedDescription)")
            return false
        }
    }
    
    func resetSettings() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Settings zurücksetzen?"
        alert.informativeText = "Alle Einstellungen werden auf die Standardwerte zurückgesetzt. Diese Aktion kann nicht rückgängig gemacht werden."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Zurücksetzen")
        alert.addButton(withTitle: "Abbrechen")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            settings = AppSettings()
            saveSettings()
            print("Settings zurückgesetzt")
            return true
        }
        return false
    }
    
    // MARK: - Validation
    
    func validateSettings() -> Bool {
        validationErrors.removeAll()
        var isValid = true
        
        // KI-Provider validieren
        if settings.ki.enabledProviders.isEmpty {
            validationErrors["ki"] = "Mindestens ein KI-Provider muss ausgewählt werden"
            isValid = false
        }
        
        // Storage validieren
        if settings.storage.primaryProvider.isEmpty {
            validationErrors["storage"] = "Ein Primary Storage Provider muss ausgewählt werden"
            isValid = false
        }
        
        // Auto-Save validieren
        if settings.autoSave.enabled && settings.autoSave.interval < 1 {
            validationErrors["autosave"] = "Auto-Save Intervall muss mindestens 1 Minute betragen"
            isValid = false
        }
        
        // Shortcuts validieren
        if settings.shortcuts.globalShortcut.isEmpty {
            validationErrors["shortcuts"] = "Ein globaler Shortcut muss konfiguriert werden"
            isValid = false
        }
        
        if !isValid {
            print("Settings-Validation fehlgeschlagen: \(validationErrors)")
        }
        
        return isValid
    }
    
    // MARK: - Security & Permissions
    
    func checkPermissions() -> [String: Bool] {
        var permissions: [String: Bool] = [:]
        
        // macOS Berechtigungen prüfen
        permissions["accessibility"] = checkAccessibilityPermission()
        permissions["inputMonitoring"] = checkInputMonitoringPermission()
        permissions["screenCapture"] = checkScreenCapturePermission()
        permissions["notifications"] = checkNotificationPermission()
        
        return permissions
    }
    
    private func checkAccessibilityPermission() -> Bool {
        // Prüfe macOS Accessibility Berechtigung
        return AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
    }
    
    private func checkInputMonitoringPermission() -> Bool {
        // Prüfe Input Monitoring Berechtigung
        return InputMonitorPermission.shared.hasPermission
    }
    
    private func checkScreenCapturePermission() -> Bool {
        // Prüfe Screen Capture Berechtigung
        return ScreenCapturePermission.shared.hasPermission
    }
    
    private func checkNotificationPermission() -> Bool {
        // Prüfe Notification Berechtigung
        return NSUserNotificationCenter.default.deliveredNotifications.isEmpty ? false : true
    }
    
    func requestPermissions() -> [String: Bool] {
        let permissions = checkPermissions()
        
        for (permission, hasPermission) in permissions {
            if !hasPermission {
                requestPermission(for: permission)
            }
        }
        
        return checkPermissions()
    }
    
    private func requestPermission(for permission: String) {
        switch permission {
        case "accessibility":
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        case "inputMonitoring":
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                NSWorkspace.shared.open(url)
            }
        case "screenCapture":
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        case "notifications":
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        default:
            break
        }
    }
    
    // MARK: - Event Handling
    
    private func handleSettingsChange(_ notification: Notification) {
        print("Settings-Änderung erkannt")
        // Additional settings change handling
    }
    
    private func showErrorAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        settingsWindowController?.close()
        NotificationCenter.default.removeObserver(self)
        print("SettingsCoordinator bereinigt")
    }
}

// MARK: - Settings Window Controller

class SettingsWindowController: NSWindowController {
    private let coordinator: SettingsCoordinator
    private var settingsView: SettingsView?
    
    init(coordinator: SettingsCoordinator) {
        self.coordinator = coordinator
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .docModalWindow],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        window.title = "StatusBarApp - Einstellungen"
        window.delegate = self
        window.isMovableByWindowBackground = true
        window.center()
        
        // Content View Setup
        settingsView = SettingsView(coordinator: coordinator)
        let hostingView = NSHostingView(rootView: settingsView!)
        window.contentView = hostingView
        
        print("SettingsWindowController initialisiert")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        window?.center()
        window?.level = .floating
    }
}

extension SettingsWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        coordinator.isShowingSettings = false
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        coordinator.isShowingSettings = true
    }
    
    func windowDidResignKey(_ notification: Notification) {
        coordinator.isShowingSettings = false
    }
}

// MARK: - Window Manager

class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    
    private init() {}
    
    func showSettings(section: SettingsCoordinator.SettingsSection) {
        // Settings Manager integration
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let statusBarController = appDelegate.getStatusBarController() {
            statusBarController.settingsCoordinator?.showCompleteSettings()
        }
    }
}