//
//  StatusBarController.swift
//  StatusBarApp
//
//  Controller für das Menüleisten-Verhalten und Dropdown-Menü
//

import Cocoa

class StatusBarController: NSObject, NSMenuDelegate {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private(set) var statusMenu: NSMenu?
    
    // Status-Tracking
    private(set) var isRunning = false
    private(set) var lastUpdateTime: Date?
    
    // Globaler Shortcut Manager
    private var shortcutManager: GlobalShortcutManager?
    private var notificationObserver: NSObjectProtocol?
    
    // Menü-Items
    private var statusItemMenuItem: NSMenuItem?
    private var settingsItem: NSMenuItem?
    private var separatorItem: NSMenuItem?
    private var aboutItem: NSMenuItem?
    private var quitItem: NSMenuItem?
    
    // Settings Manager
    private(set) var settingsCoordinator: SettingsCoordinator?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupGlobalShortcutObserver()
        print("StatusBarController initialisiert")
    }
    
    // MARK: - Setup
    
    func setupStatusBarItem() {
        // StatusItem erstellen
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else {
            print("Fehler: StatusItem konnte nicht erstellt werden")
            return
        }
        
        // Settings Coordinator initialisieren
        settingsCoordinator = SettingsCoordinator()
        
        // Menüleisten-Icon setzen
        setupStatusItemIcon()
        
        // Globalen Shortcut Manager initialisieren
        shortcutManager = GlobalShortcutManager.shared
        
        // Menü erstellen und konfigurieren
        setupStatusMenu()
        
        // StatusItem mit Menü verknüpfen
        statusItem.menu = statusMenu
        
        print("StatusItem erfolgreich konfiguriert")
    }
    
    private func setupStatusItemIcon() {
        guard let statusItem = statusItem else { return }
        
        // Symbol-Icon für die Menüleiste erstellen
        if let button = statusItem.button {
            // Symbol-Icon mit SF Symbols
            button.image = NSImage(systemSymbolName: "app.dashed", accessibilityDescription: "StatusBarApp")
            button.image?.isTemplate = true // Für automatische Farb-Anpassung
            
            // Button-Action für Klicks
            button.action = #selector(statusItemClicked(_:))
            button.target = self
        }
    }
    
    private func setupStatusMenu() {
        // Neues Menü erstellen
        statusMenu = NSMenu()
        statusMenu?.delegate = self
        statusMenu?.autoenablesItems = false
        
        // Menü-Items erstellen
        createMenuItems()
        
        print("Status-Menü konfiguriert")
    }
    
    private func createMenuItems() {
        // Status-Anzeige
        statusItemMenuItem = NSMenuItem(
            title: "Status: Bereit",
            action: #selector(statusItemAction(_:)),
            keyEquivalent: ""
        )
        statusItemMenuItem?.target = self
        statusItemMenuItem?.isEnabled = false
        statusMenu?.addItem(statusItemMenuItem!)
        
        // Separator
        separatorItem = NSMenuItem.separator()
        statusMenu?.addItem(separatorItem!)
        
        // Window-Management Section
        let windowMgmtHeader = NSMenuItem(
            title: "Window-Management",
            action: nil,
            keyEquivalent: ""
        )
        windowMgmtHeader.isEnabled = false
        statusMenu?.addItem(windowMgmtHeader)
        
        // Demo Popup
        let demoPopupItem = NSMenuItem(
            title: "Demo Popup öffnen",
            action: #selector(showDemoPopup(_:)),
            keyEquivalent: "1"
        )
        demoPopupItem.target = self
        statusMenu?.addItem(demoPopupItem)
        
        // Detachable Window
        let detachableItem = NSMenuItem(
            title: "Detachable Window",
            action: #selector(showDetachableWindow(_:)),
            keyEquivalent: "2"
        )
        detachableItem.target = self
        statusMenu?.addItem(detachableItem)
        
        // Multi-Window Demo
        let multiWindowItem = NSMenuItem(
            title: "Multi-Window Demo",
            action: #selector(showMultiWindowDemo(_:)),
            keyEquivalent: "3"
        )
        multiWindowItem.target = self
        statusMenu?.addItem(multiWindowItem)
        
        // Alle Windows schließen
        let closeAllItem = NSMenuItem(
            title: "Alle Windows schließen",
            action: #selector(closeAllWindows(_:)),
            keyEquivalent: "w"
        )
        closeAllItem.target = self
        statusMenu?.addItem(closeAllItem)
        
        // Separator
        statusMenu?.addItem(NSMenuItem.separator())
        
        // Quick Access Section
        let quickAccessHeader = NSMenuItem(
            title: "Schnellzugriff",
            action: nil,
            keyEquivalent: ""
        )
        quickAccessHeader.isEnabled = false
        statusMenu?.addItem(quickAccessHeader)
        
        // KI Provider Quick Settings
        let kiProviderItem = NSMenuItem(
            title: "KI-Anbieter",
            action: #selector(openKIProviderSettings(_:)),
            keyEquivalent: "k"
        )
        kiProviderItem.target = self
        statusMenu?.addItem(kiProviderItem)
        
        // Auto-Save Quick Settings
        let autoSaveItem = NSMenuItem(
            title: "Auto-Save",
            action: #selector(toggleAutoSave(_:)),
            keyEquivalent: "s"
        )
        autoSaveItem.target = self
        statusMenu?.addItem(autoSaveItem)
        
        // Storage Quick Settings
        let storageItem = NSMenuItem(
            title: "Storage Provider",
            action: #selector(openStorageSettings(_:)),
            keyEquivalent: "p"
        )
        storageItem.target = self
        statusMenu?.addItem(storageItem)
        
        // Separator
        statusMenu?.addItem(NSMenuItem.separator())
        
        // Vollständige Einstellungen
        settingsItem = NSMenuItem(
            title: "Alle Einstellungen...",
            action: #selector(openSettings(_:)),
            keyEquivalent: ","
        )
        settingsItem?.target = self
        statusMenu?.addItem(settingsItem!)
        
        // Separator
        statusMenu?.addItem(NSMenuItem.separator())
        
        // Info-Anzeige
        let infoItem = NSMenuItem(
            title: "Aktualisiert: --",
            action: nil,
            keyEquivalent: ""
        )
        infoItem.isEnabled = false
        statusMenu?.addItem(infoItem)
        
        // Separator
        statusMenu?.addItem(NSMenuItem.separator())
        
        // Über die App
        aboutItem = NSMenuItem(
            title: "Über StatusBarApp",
            action: #selector(showAbout(_:)),
            keyEquivalent: ""
        )
        aboutItem?.target = self
        statusMenu?.addItem(aboutItem!)
        
        // App beenden
        quitItem = NSMenuItem(
            title: "StatusBarApp beenden",
            action: #selector(quitApplication(_:)),
            keyEquivalent: "q"
        )
        quitItem?.target = self
        statusMenu?.addItem(quitItem!)
    }
    
    // MARK: - Actions
    
    @objc private func statusItemClicked(_ sender: Any?) {
        toggleStatusMenu()
    }
    
    @objc private func statusItemAction(_ sender: Any?) {
        // Status-Aktion - weitere Funktionalität kann hier hinzugefügt werden
        updateStatus()
    }
    
    @objc private func openSettings(_ sender: Any?) {
        // Vollständige Einstellungen öffnen
        showSettingsDialog()
    }
    
    @objc private func openKIProviderSettings(_ sender: Any?) {
        // KI-Provider Einstellungen öffnen
        settingsCoordinator?.showKISettings()
    }
    
    @objc private func toggleAutoSave(_ sender: Any?) {
        // Auto-Save umschalten
        settingsCoordinator?.toggleAutoSave()
    }
    
    @objc private func openStorageSettings(_ sender: Any?) {
        // Storage-Einstellungen öffnen
        settingsCoordinator?.showStorageSettings()
    }
    
    @objc private func showAbout(_ sender: Any?) {
        // Über-Dialog anzeigen
        showAboutDialog()
    }
    
    @objc private func quitApplication(_ sender: Any?) {
        // App beenden
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Window-Management Actions
    
    @objc private func showDemoPopup(_ sender: Any?) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showDemoPopup()
        }
    }
    
    @objc private func showDetachableWindow(_ sender: Any?) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showDetachableDemo()
        }
    }
    
    @objc private func showMultiWindowDemo(_ sender: Any?) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showMultiWindowDemo()
        }
    }
    
    @objc private func closeAllWindows(_ sender: Any?) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.closeAllWindows()
        }
    }
    
    // MARK: - Menu Management
    
    func toggleStatusMenu() {
        guard let statusItem = statusItem, let button = statusItem.button else { return }
        
        if let menu = statusMenu, menu.isVisible {
            menu.popUpPositioning(nil, at: .zero, in: button)
        } else {
            menu?.popUpPositioning(nil, at: .zero, in: button)
        }
    }
    
    func updateStatus() {
        isRunning = !isRunning
        lastUpdateTime = Date()
        
        // Status-Label aktualisieren
        let statusText = isRunning ? "Status: Aktiv" : "Status: Bereit"
        statusItemMenuItem?.title = statusText
        
        // Info-Anzeige aktualisieren
        if let timeString = formatDate(lastUpdateTime) {
            updateMenuItem(title: "Aktualisiert: \(timeString)", at: 3)
        }
        
        // Icon-Änderung basierend auf Status
        updateStatusItemIcon()
        
        print("Status aktualisiert: \(statusText)")
    }
    
    private func updateStatusItemIcon() {
        guard let statusItem = statusItem, let button = statusItem.button else { return }
        
        // Symbol-Icon basierend auf Status ändern
        let symbolName = isRunning ? "checkmark.circle.fill" : "checkmark.circle"
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "StatusBarApp Status")
        button.image?.isTemplate = true
    }
    
    private func updateMenuItem(title: String, at index: Int) {
        guard let menu = statusMenu, index < menu.items.count else { return }
        
        let item = menu.items[index]
        item.title = title
    }
    
    private func formatDate(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Dialogs
    
    private func showSettingsDialog() {
        // Vollständiges Settings-Fenster öffnen
        settingsCoordinator?.showCompleteSettings()
        print("Vollständige Einstellungen angezeigt")
    }
    
    private func showAboutDialog() {
        let alert = NSAlert()
        alert.messageText = "Über StatusBarApp"
        alert.informativeText = """
        StatusBarApp v1.0
        
        Eine moderne macOS Menüleisten-Anwendung
        mit globaler Tastenkombination ⌘⇧N
        
        Entwickelt mit Swift und modernen macOS APIs.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        alert.runModal()
        print("Über-Dialog angezeigt")
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        // Menü wird geöffnet - Status aktualisieren
        if let timeString = formatDate(lastUpdateTime) {
            updateMenuItem(title: "Aktualisiert: \(timeString)", at: 3)
        }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // Menü wurde geschlossen
        print("Status-Menü geschlossen")
    }
    
    // MARK: - Cleanup
    
    // MARK: - Global Shortcut Observer
    
    private func setupGlobalShortcutObserver() {
        // Observer für globale Tastenkombination-Events
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .globalShortcutActivated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleGlobalShortcutNotification(notification)
        }
    }
    
    private func handleGlobalShortcutNotification(_ notification: Notification) {
        toggleStatusMenu()
        print("Globale Tastenkombination erkannt - Menü getoggelt")
    }
    
    func cleanup() {
        // Settings Coordinator bereinigen
        settingsCoordinator?.cleanup()
        
        // Observer entfernen
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // StatusItem entfernen
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        
        print("StatusBarController bereinigt")
    }
}