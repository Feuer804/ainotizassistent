//
//  ShortcutManager.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI
import Carbon
import Combine

// MARK: - App Shortcut Definition
struct AppShortcut: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let keyCombo: KeyCombo
    let category: ShortcutCategory
    let isEnabled: Bool
    let isGlobal: Bool
    let customTrigger: (() -> Void)?
    
    init(id: String, name: String, description: String, keyCombo: KeyCombo, category: ShortcutCategory, isEnabled: Bool = true, isGlobal: Bool = true, customTrigger: (() -> Void)? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.keyCombo = keyCombo
        self.category = category
        self.isEnabled = isEnabled
        self.isGlobal = isGlobal
        self.customTrigger = customTrigger
    }
}

// MARK: - Key Combination
struct KeyCombo: Equatable, Codable {
    let key: UInt16
    let modifiers: UInt32
    let displayString: String
    
    init(key: UInt16, modifiers: UInt32 = 0) {
        self.key = key
        self.modifiers = modifiers
        self.displayString = KeyCombo.formatDisplayString(key: key, modifiers: modifiers)
    }
    
    static func == (lhs: KeyCombo, rhs: KeyCombo) -> Bool {
        return lhs.key == rhs.key && lhs.modifiers == rhs.modifiers
    }
    
    private static func formatDisplayString(key: UInt16, modifiers: UInt32) -> String {
        var parts: [String] = []
        
        if modifiers & cmdKey != 0 { parts.append("⌘") }
        if modifiers & shiftKey != 0 { parts.append("⇧") }
        if modifiers & optionKey != 0 { parts.append("⌥") }
        if modifiers & controlKey != 0 { parts.append("⌃") }
        
        let keyString = keyToString(key)
        parts.append(keyString)
        
        return parts.joined()
    }
    
    private static func keyToString(_ key: UInt16) -> String {
        switch key {
        case kVK_Space: return "␣"
        case kVK_Return: return "⏎"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default:
            if key >= 0x00 && key <= 0x7F {
                let char = UTF8Char(key)
                return String(char)
            }
            return "Key_\(key)"
        }
    }
    
    static func fromDisplayString(_ string: String) -> KeyCombo? {
        var modifiers: UInt32 = 0
        var key: UInt16 = 0
        
        let components = string.components(separatedBy: "+")
        for component in components {
            switch component {
            case "⌘": modifiers |= cmdKey
            case "⇧": modifiers |= shiftKey
            case "⌥": modifiers |= optionKey
            case "⌃": modifiers |= controlKey
            default:
                // Key-Mapping
                switch component {
                case "␣": key = kVK_Space
                case "⏎": key = kVK_Return
                case "⇥": key = kVK_Tab
                case "⌫": key = kVK_Delete
                case "⎋": key = kVK_Escape
                case "↑": key = kVK_UpArrow
                case "↓": key = kVK_DownArrow
                case "←": key = kVK_LeftArrow
                case "→": key = kVK_RightArrow
                case "F1"..."F12":
                    if let keyNumber = Int(component.dropFirst()), keyNumber >= 1 && keyNumber <= 12 {
                        key = kVK_F1 + UInt16(keyNumber - 1)
                    }
                default:
                    if component.count == 1 {
                        let char = component.unicodeScalars.first!.value
                        if char >= 32 && char <= 126 {
                            key = UInt16(char)
                        }
                    }
                }
            }
        }
        
        return key != 0 ? KeyCombo(key: key, modifiers: modifiers) : nil
    }
}

// MARK: - Shortcut Categories
enum ShortcutCategory: String, CaseIterable, Codable {
    case primary = "Primär"
    case quick = "Quick Actions"
    case mode = "Modi"
    case settings = "Einstellungen"
    case navigation = "Navigation"
    case custom = "Benutzerdefiniert"
    
    var displayName: String { rawValue }
    var icon: String {
        switch self {
        case .primary: return "⚡"
        case .quick: return "⚡"
        case .mode: return "🎛️"
        case .settings: return "⚙️"
        case .navigation: return "🧭"
        case .custom: return "🎯"
        }
    }
}

// MARK: - System Shortcut Conflict Detection
struct SystemShortcutConflict {
    let appShortcut: AppShortcut
    let conflictingApps: [String]
    let conflictType: ConflictType
    let suggestion: String
}

enum ConflictType {
    case system
    case app
    case global
    case none
}

// MARK: - Gesture Shortcut
struct GestureShortcut: Identifiable, Codable {
    let id: String
    let name: String
    let gestureType: GestureType
    let description: String
    let isEnabled: Bool
    
    init(id: String, name: String, gestureType: GestureType, description: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.gestureType = gestureType
        self.description = description
        self.isEnabled = isEnabled
    }
}

enum GestureType: String, CaseIterable, Codable {
    case tapWithThreeFingers = "Tap mit drei Fingern"
    case pinchWithThreeFingers = "Kneifen mit drei Fingern"
    case rotateWithTwoFingers = "Drehen mit zwei Fingern"
    case swipeUpWithThreeFingers = "Nach oben wischen (drei Finger)"
    case swipeDownWithThreeFingers = "Nach unten wischen (drei Finger)"
    
    var description: String { rawValue }
}

// MARK: - Voice Command Shortcut
struct VoiceCommandShortcut: Identifiable, Codable {
    let id: String
    let trigger: String
    let action: String
    let description: String
    let isEnabled: Bool
    let confidence: Double
    
    init(id: String, trigger: String, action: String, description: String, isEnabled: Bool = true, confidence: Double = 0.8) {
        self.id = id
        self.trigger = trigger
        self.action = action
        self.description = description
        self.isEnabled = isEnabled
        self.confidence = confidence
    }
}

// MARK: - Shortcut Manager
@MainActor
class ShortcutManager: ObservableObject {
    @Published var shortcuts: [AppShortcut] = []
    @Published var gestureShortcuts: [GestureShortcut] = []
    @Published var voiceCommandShortcuts: [VoiceCommandShortcut] = []
    @Published var systemConflicts: [SystemShortcutConflict] = []
    @Published var isListening: Bool = false
    @Published var capturedKeyCombo: KeyCombo? = nil
    
    private let defaults = UserDefaults.standard
    private var eventTap: Any?
    private var cancellables = Set<AnyCancellable>()
    private var shortcutActions: [String: () -> Void] = [:]
    
    // App-specific popup shortcuts
    @Published var popupShortcuts: [AppShortcut] = []
    
    init() {
        setupDefaultShortcuts()
        loadShortcutSettings()
        setupEventTap()
        detectSystemConflicts()
    }
    
    deinit {
        if let eventTap = eventTap {
            removeEventTap(eventTap)
        }
    }
    
    // MARK: - Default Shortcut Setup
    private func setupDefaultShortcuts() {
        shortcuts = [
            // Primary Shortcuts (Standard: ⌘⇧N)
            AppShortcut(
                id: "primary_new_note",
                name: "Neue Notiz",
                description: "Öffnet die Hauptnote-Eingabe",
                keyCombo: KeyCombo(key: kVK_ANSI_N, modifiers: cmdKey | shiftKey),
                category: .primary
            ),
            
            // Quick Actions (Standard: ⌃N)
            AppShortcut(
                id: "quick_capture",
                name: "Quick Capture",
                description: "Schneller Notiz-Erfassungsmodus",
                keyCombo: KeyCombo(key: kVK_ANSI_N, modifiers: controlKey),
                category: .quick
            ),
            
            // Modes (Standard: ⌥N)
            AppShortcut(
                id: "summary_mode",
                name: "Summary Mode",
                description: "Zusammenfassungsmodus aktivieren",
                keyCombo: KeyCombo(key: kVK_ANSI_N, modifiers: optionKey),
                category: .mode
            ),
            AppShortcut(
                id: "meeting_mode",
                name: "Meeting Mode",
                description: "Meeting-Aufzeichnungsmodus aktivieren",
                keyCombo: KeyCombo(key: kVK_ANSI_N, modifiers: shiftKey),
                category: .mode
            ),
            
            // Settings (Standard: ⌘,)
            AppShortcut(
                id: "open_settings",
                name: "Einstellungen",
                description: "App-Einstellungen öffnen",
                keyCombo: KeyCombo(key: kVK_ANSI_Comma, modifiers: cmdKey),
                category: .settings
            ),
            
            // Navigation
            AppShortcut(
                id: "toggle_visibility",
                name: "App ein-/ausblenden",
                description: "Hauptfenster ein- oder ausblenden",
                keyCombo: KeyCombo(key: kVK_Space, modifiers: cmdKey | shiftKey),
                category: .navigation
            )
        ]
        
        // Popup-spezifische Shortcuts
        popupShortcuts = [
            AppShortcut(
                id: "popup_toggle",
                name: "Popup ein-/ausblenden",
                description: "Popup-Fenster ein- oder ausblenden",
                keyCombo: KeyCombo(key: kVK_Space, modifiers: 0),
                category: .navigation,
                isGlobal: false
            ),
            AppShortcut(
                id: "popup_accept",
                name: "Übernehmen",
                description: "Eingabe übernehmen und schließen",
                keyCombo: KeyCombo(key: kVK_Return, modifiers: 0),
                category: .navigation,
                isGlobal: false
            ),
            AppShortcut(
                id: "popup_cancel",
                name: "Abbrechen",
                description: "Eingabe abbrechen und schließen",
                keyCombo: KeyCombo(key: kVK_Escape, modifiers: 0),
                category: .navigation,
                isGlobal: false
            )
        ]
        
        // Gesture Shortcuts
        gestureShortcuts = [
            GestureShortcut(
                id: "gesture_quick_note",
                name: "Quick Note",
                gestureType: .tapWithThreeFingers,
                description: "Tap mit drei Fingern für schnelle Notiz"
            ),
            GestureShortcut(
                id: "gesture_meeting_mode",
                name: "Meeting Mode",
                gestureType: .pinchWithThreeFingers,
                description: "Kneifen mit drei Fingern für Meeting-Modus"
            )
        ]
        
        // Voice Command Shortcuts
        voiceCommandShortcuts = [
            VoiceCommandShortcut(
                id: "voice_new_note",
                trigger: "Neue Notiz",
                action: "primary_new_note",
                description: "Sprachbefehl für neue Notiz"
            ),
            VoiceCommandShortcut(
                id: "voice_meeting",
                trigger: "Meeting starten",
                action: "meeting_mode",
                description: "Sprachbefehl für Meeting-Modus"
            ),
            VoiceCommandShortcut(
                id: "voice_summary",
                trigger: "Zusammenfassung",
                action: "summary_mode",
                description: "Sprachbefehl für Summary-Modus"
            )
        ]
    }
    
    // MARK: - Event Tap Setup
    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { [weak self] _, eventType, event in
                guard let self = self else { return Unmanaged.passRetained(event) }
                
                if eventType == .keyDown {
                    self.handleKeyEvent(event)
                }
                
                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        ) else {
            print("Fehler beim Erstellen des Event Taps")
            return
        }
        
        self.eventTap = eventTap
        
        // Event Tap zum Run Loop hinzufügen
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CFRunLoopRun()
    }
    
    private func handleKeyEvent(_ event: CGEvent) {
        guard !isListening else { return }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let modifiers = event.getIntegerValueField(.keyboardEventModifierFlags)
        
        let currentCombo = KeyCombo(key: UInt16(keyCode), modifiers: UInt32(modifiers))
        
        // Prüfen ob aktueller KeyCombo einem definierten Shortcut entspricht
        let matchingShortcut = shortcuts.first { shortcut in
            shortcut.isEnabled &&
            shortcut.isGlobal &&
            shortcut.keyCombo == currentCombo
        }
        
        if let shortcut = matchingShortcut {
            triggerShortcut(shortcut)
            event.setIntegerValueField(.keyboardEventResult, value: kCGEventResultHandled)
        }
    }
    
    // MARK: - Shortcut Management
    func updateShortcut(_ shortcut: AppShortcut) {
        if let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            shortcuts[index] = shortcut
            saveShortcutSettings()
            detectSystemConflicts()
        }
    }
    
    func setShortcutEnabled(_ shortcutId: String, enabled: Bool) {
        if let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            shortcuts[index].isEnabled = enabled
            saveShortcutSettings()
        }
    }
    
    func remapShortcut(_ shortcutId: String, to newKeyCombo: KeyCombo) {
        guard !isKeyComboTaken(newKeyCombo, except: shortcutId) else { return }
        
        if let index = shortcuts.firstIndex(where: { $0.id == shortcutId }) {
            shortcuts[index].keyCombo = newKeyCombo
            saveShortcutSettings()
            detectSystemConflicts()
        }
    }
    
    func addCustomShortcut(_ name: String, description: String, keyCombo: KeyCombo, action: @escaping () -> Void) {
        let customShortcut = AppShortcut(
            id: "custom_\(UUID().uuidString)",
            name: name,
            description: description,
            keyCombo: keyCombo,
            category: .custom
        )
        
        shortcuts.append(customShortcut)
        shortcutActions[customShortcut.id] = action
        saveShortcutSettings()
        detectSystemConflicts()
    }
    
    func removeCustomShortcut(_ shortcutId: String) {
        shortcuts.removeAll { $0.id == shortcutId && $0.category == .custom }
        shortcutActions.removeValue(forKey: shortcutId)
        saveShortcutSettings()
        detectSystemConflicts()
    }
    
    func triggerShortcut(_ shortcut: AppShortcut) {
        shortcut.customTrigger?()
        NotificationCenter.default.post(name: .shortcutTriggered, object: shortcut)
    }
    
    func triggerShortcut(byId id: String) {
        guard let shortcut = shortcuts.first(where: { $0.id == id }) else { return }
        triggerShortcut(shortcut)
    }
    
    // MARK: - Conflict Detection
    func isKeyComboTaken(_ keyCombo: KeyCombo, except shortcutId: String? = nil) -> Bool {
        let otherShortcuts = shortcuts.filter { $0.id != shortcutId }
        return otherShortcuts.contains { $0.keyCombo == keyCombo && $0.isEnabled }
    }
    
    func detectSystemConflicts() {
        systemConflicts.removeAll()
        
        for shortcut in shortcuts where shortcut.isEnabled {
            let conflicts = detectConflicts(for: shortcut)
            if !conflicts.isEmpty {
                let conflict = SystemShortcutConflict(
                    appShortcut: shortcut,
                    conflictingApps: conflicts,
                    conflictType: .system,
                    suggestion: generateConflictSuggestion(shortcut)
                )
                systemConflicts.append(conflict)
            }
        }
    }
    
    private func detectConflicts(for shortcut: AppShortcut) -> [String] {
        var conflicts: [String] = []
        
        // System Shortcuts prüfen
        let systemShortcutConflicts = checkSystemShortcutConflicts(shortcut.keyCombo)
        conflicts.append(contentsOf: systemShortcutConflicts)
        
        // Andere Apps prüfen (vereinfacht)
        let appConflicts = checkAppShortcutConflicts(shortcut.keyCombo)
        conflicts.append(contentsOf: appConflicts)
        
        return conflicts
    }
    
    private func checkSystemShortcutConflicts(_ keyCombo: KeyCombo) -> [String] {
        var conflicts: [String] = []
        
        // macOS System Shortcuts die oft in Konflikt stehen
        let systemReserved = [
            (KeyCombo(key: kVK_Space, modifiers: controlKey), "Space + Ctrl"),
            (KeyCombo(key: kVK_Space, modifiers: optionKey), "Space + Option"),
            (KeyCombo(key: kVK_Q, modifiers: cmdKey), "Cmd + Q"),
            (KeyCombo(key: kVK_W, modifiers: cmdKey), "Cmd + W"),
            (KeyCombo(key: kVK_M, modifiers: cmdKey), "Cmd + M"),
            (KeyCombo(key: kVK_H, modifiers: cmdKey), "Cmd + H"),
            (KeyCombo(key: kVK_Tab, modifiers: cmdKey), "Cmd + Tab"),
            (KeyCombo(key: kVK_Tab, modifiers: cmdKey | shiftKey), "Cmd + Shift + Tab")
        ]
        
        for (reservedCombo, description) in systemReserved {
            if keyCombo == reservedCombo {
                conflicts.append("macOS System: \(description)")
            }
        }
        
        return conflicts
    }
    
    private func checkAppShortcutConflicts(_ keyCombo: KeyCombo) -> [String] {
        // Vereinfachte App-Konflikt-Erkennung
        // In einer echten Implementierung würde man die System-API verwenden
        
        let commonAppShortcuts = [
            (KeyCombo(key: kVK_ANSI_N, modifiers: cmdKey), "Viele Apps: Neue Datei"),
            (KeyCombo(key: kVK_ANSI_O, modifiers: cmdKey), "Viele Apps: Öffnen"),
            (KeyCombo(key: kVK_ANSI_S, modifiers: cmdKey), "Viele Apps: Speichern"),
            (KeyCombo(key: kVK_ANSI_P, modifiers: cmdKey), "Viele Apps: Drucken"),
            (KeyCombo(key: kVK_ANSI_F, modifiers: cmdKey), "Viele Apps: Suchen"),
            (KeyCombo(key: kVK_ANSI_A, modifiers: cmdKey), "Viele Apps: Alles auswählen")
        ]
        
        var conflicts: [String] = []
        for (conflictCombo, description) in commonAppShortcuts {
            if keyCombo == conflictCombo {
                conflicts.append(description)
            }
        }
        
        return conflicts
    }
    
    private func generateConflictSuggestion(_ shortcut: AppShortcut) -> String {
        // Alternative Key-Combinierungen vorschlagen
        let alternatives = suggestAlternativeCombinations(for: shortcut.category)
        return "Alternativen: \(alternatives.joined(separator: ", "))"
    }
    
    private func suggestAlternativeCombinations(for category: ShortcutCategory) -> [String] {
        switch category {
        case .primary:
            return ["⌘⌥N", "⌘⌃N", "⌘⇧⌥N"]
        case .quick:
            return ["⌃⇧N", "⌥⇧N", "⌃⌥N"]
        case .mode:
            return ["⌘M", "⌘R", "⌘T"]
        case .settings:
            return ["⌘;", "⌘'", "⌘." ]
        case .navigation:
            return ["⌘`", "⌘\\", "⌘/"]
        case .custom:
            return ["Benutzerdefinierte Alternative erforderlich"]
        }
    }
    
    // MARK: - Key Combo Capture for UI
    func startKeyComboCapture() {
        isListening = true
        capturedKeyCombo = nil
    }
    
    func stopKeyComboCapture() {
        isListening = false
    }
    
    func setCapturedKeyCombo(_ keyCombo: KeyCombo) {
        capturedKeyCombo = keyCombo
        stopKeyComboCapture()
    }
    
    // MARK: - Validation and Testing
    func validateKeyCombo(_ keyCombo: KeyCombo) -> (isValid: Bool, message: String) {
        // System Shortcuts ausschließen
        let systemReserved = [
            KeyCombo(key: kVK_Command, modifiers: 0),
            KeyCombo(key: kVK_Shift, modifiers: 0),
            KeyCombo(key: kVK_Control, modifiers: 0),
            KeyCombo(key: kVK_Option, modifiers: 0),
            KeyCombo(key: kVK_CapsLock, modifiers: 0)
        ]
        
        if systemReserved.contains(where: { $0 == keyCombo }) {
            return (false, "Ungültige Key-Kombination")
        }
        
        // Modifiers erforderlich für Custom Shortcuts
        if keyCombo.modifiers == 0 {
            return (false, "Mindestens ein Modifier erforderlich (⌘, ⌃, ⌥, ⇧)")
        }
        
        return (true, "Gültig")
    }
    
    func testKeyCombo(_ keyCombo: KeyCombo) {
        // Shortcut testen
        if isKeyComboTaken(keyCombo) {
            print("Key-Kombination bereits belegt")
            return
        }
        
        print("Key-Kombination \(keyCombo.displayString) ist verfügbar")
    }
    
    // MARK: - Import/Export
    func exportShortcuts() -> Data {
        let export = ShortcutSettingsExport(
            shortcuts: shortcuts,
            gestureShortcuts: gestureShortcuts,
            voiceCommandShortcuts: voiceCommandShortcuts
        )
        
        return try! JSONEncoder().encode(export)
    }
    
    func importShortcuts(from data: Data) throws {
        let importData = try JSONDecoder().decode(ShortcutSettingsExport.self, from: data)
        
        shortcuts = importData.shortcuts
        gestureShortcuts = importData.gestureShortcuts
        voiceCommandShortcuts = importData.voiceCommandShortcuts
        
        saveShortcutSettings()
        detectSystemConflicts()
    }
    
    func resetToDefaults() {
        setupDefaultShortcuts()
        saveShortcutSettings()
        detectSystemConflicts()
    }
    
    // MARK: - Settings Persistence
    private func loadShortcutSettings() {
        if let savedData = defaults.data(forKey: "shortcutSettings"),
           let savedSettings = try? JSONDecoder().decode([AppShortcut].self, from: savedData) {
            shortcuts = savedSettings
        }
        
        if let gestureData = defaults.data(forKey: "gestureShortcuts"),
           let savedGestures = try? JSONDecoder().decode([GestureShortcut].self, from: gestureData) {
            gestureShortcuts = savedGestures
        }
        
        if let voiceData = defaults.data(forKey: "voiceCommandShortcuts"),
           let savedVoice = try? JSONDecoder().decode([VoiceCommandShortcut].self, from: voiceData) {
            voiceCommandShortcuts = savedVoice
        }
    }
    
    private func saveShortcutSettings() {
        if let encoded = try? JSONEncoder().encode(shortcuts) {
            defaults.set(encoded, forKey: "shortcutSettings")
        }
        
        if let encoded = try? JSONEncoder().encode(gestureShortcuts) {
            defaults.set(encoded, forKey: "gestureShortcuts")
        }
        
        if let encoded = try? JSONEncoder().encode(voiceCommandShortcuts) {
            defaults.set(encoded, forKey: "voiceCommandShortcuts")
        }
    }
}

// MARK: - Shortcut Settings Export
struct ShortcutSettingsExport: Codable {
    let shortcuts: [AppShortcut]
    let gestureShortcuts: [GestureShortcut]
    let voiceCommandShortcuts: [VoiceCommandShortcut]
}

// MARK: - Keyboard Constants
extension UInt16 {
    // ANSI Keys
    static let kVK_ANSI_A: UInt16 = 0x00
    static let kVK_ANSI_B: UInt16 = 0x0B
    static let kVK_ANSI_C: UInt16 = 0x08
    static let kVK_ANSI_D: UInt16 = 0x02
    static let kVK_ANSI_E: UInt16 = 0x0E
    static let kVK_ANSI_F: UInt16 = 0x03
    static let kVK_ANSI_G: UInt16 = 0x05
    static let kVK_ANSI_H: UInt16 = 0x04
    static let kVK_ANSI_I: UInt16 = 0x22
    static let kVK_ANSI_J: UInt16 = 0x26
    static let kVK_ANSI_K: UInt16 = 0x28
    static let kVK_ANSI_L: UInt16 = 0x25
    static let kVK_ANSI_M: UInt16 = 0x2E
    static let kVK_ANSI_N: UInt16 = 0x2D
    static let kVK_ANSI_O: UInt16 = 0x1F
    static let kVK_ANSI_P: UInt16 = 0x23
    static let kVK_ANSI_Q: UInt16 = 0x0C
    static let kVK_ANSI_R: UInt16 = 0x0F
    static let kVK_ANSI_S: UInt16 = 0x01
    static let kVK_ANSI_T: UInt16 = 0x11
    static let kVK_ANSI_U: UInt16 = 0x20
    static let kVK_ANSI_V: UInt16 = 0x09
    static let kVK_ANSI_W: UInt16 = 0x0D
    static let kVK_ANSI_X: UInt16 = 0x07
    static let kVK_ANSI_Y: UInt16 = 0x10
    static let kVK_ANSI_Z: UInt16 = 0x06
    
    static let kVK_ANSI_0: UInt16 = 0x1D
    static let kVK_ANSI_1: UInt16 = 0x12
    static let kVK_ANSI_2: UInt16 = 0x13
    static let kVK_ANSI_3: UInt16 = 0x14
    static let kVK_ANSI_4: UInt16 = 0x15
    static let kVK_ANSI_5: UInt16 = 0x17
    static let kVK_ANSI_6: UInt16 = 0x16
    static let kVK_ANSI_7: UInt16 = 0x1A
    static let kVK_ANSI_8: UInt16 = 0x1C
    static let kVK_ANSI_9: UInt16 = 0x19
    
    static let kVK_ANSI_Grave: UInt16 = 0x32
    static let kVK_ANSI_Minus: UInt16 = 0x1B
    static let kVK_ANSI_Equal: UInt16 = 0x18
    static let kVK_ANSI_Backslash: UInt16 = 0x2A
    static let kVK_ANSI_Semicolon: UInt16 = 0x29
    static let kVK_ANSI_Quote: UInt16 = 0x27
    static let kVK_ANSI_Comma: UInt16 = 0x2B
    static let kVK_ANSI_Period: UInt16 = 0x2F
    static let kVK_ANSI_Slash: UInt16 = 0x2C
    
    // Special Keys
    static let kVK_Space: UInt16 = 0x31
    static let kVK_Return: UInt16 = 0x24
    static let kVK_Tab: UInt16 = 0x30
    static let kVK_Delete: UInt16 = 0x33
    static let kVK_Escape: UInt16 = 0x35
    static let kVK_ForwardDelete: UInt16 = 0x75
    
    static let kVK_UpArrow: UInt16 = 0x7E
    static let kVK_DownArrow: UInt16 = 0x7D
    static let kVK_LeftArrow: UInt16 = 0x7B
    static let kVK_RightArrow: UInt16 = 0x7C
    
    static let kVK_Command: UInt16 = 0x37
    static let kVK_Shift: UInt16 = 0x38
    static let kVK_Control: UInt16 = 0x3B
    static let kVK_Option: UInt16 = 0x3A
    static let kVK_CapsLock: UInt16 = 0x39
    
    // Function Keys
    static let kVK_F1: UInt16 = 0x7A
    static let kVK_F2: UInt16 = 0x78
    static let kVK_F3: UInt16 = 0x63
    static let kVK_F4: UInt16 = 0x76
    static let kVK_F5: UInt16 = 0x60
    static let kVK_F6: UInt16 = 0x61
    static let kVK_F7: UInt16 = 0x62
    static let kVK_F8: UInt16 = 0x64
    static let kVK_F9: UInt16 = 0x65
    static let kVK_F10: UInt16 = 0x67
    static let kVK_F11: UInt16 = 0x6F
    static let kVK_F12: UInt16 = 0x73
}

// MARK: - Modifier Flags
let cmdKey: UInt32 = UInt32(cocoaKey)
let shiftKey: UInt32 = UInt32(shiftKey)
let optionKey: UInt32 = UInt32(alternateKey)
let controlKey: UInt32 = UInt32(controlKey)

// MARK: - Notification Names
extension Notification.Name {
    static let shortcutTriggered = Notification.Name("ShortcutTriggered")
    static let keyComboCaptured = Notification.Name("KeyComboCaptured")
}

// MARK: - Custom Key Combo Capture View
struct KeyComboCaptureView: View {
    @Binding var keyCombo: KeyCombo?
    @State private var isCapturing = false
    @State private var capturedKeys: [String] = []
    
    var body: some View {
        HStack {
            Text(capturedKeys.isEmpty ? "Taste drücken..." : capturedKeys.joined(separator: "+"))
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
            
            Button("Zurücksetzen") {
                keyCombo = nil
                capturedKeys.removeAll()
            }
        }
        .onAppear {
            // Event Tap für Key Capture setup
        }
    }
    
    private func handleKeyDown(event: NSEvent) {
        guard isCapturing else { return }
        
        let key = event.keyCode
        let modifiers = event.modifierFlags
        
        var keyParts: [String] = []
        
        if modifiers.contains(.command) { keyParts.append("⌘") }
        if modifiers.contains(.shift) { keyParts.append("⇧") }
        if modifiers.contains(.option) { keyParts.append("⌥") }
        if modifiers.contains(.control) { keyParts.append("⌃") }
        
        let keyString = keyToString(key)
        keyParts.append(keyString)
        
        capturedKeys = keyParts
        keyCombo = KeyCombo(key: UInt16(key), modifiers: UInt32(modifiers.rawValue))
        isCapturing = false
    }
    
    private func keyToString(_ key: UInt16) -> String {
        switch key {
        case UInt16.kVK_Space: return "␣"
        case UInt16.kVK_Return: return "⏎"
        case UInt16.kVK_Tab: return "⇥"
        case UInt16.kVK_Delete: return "⌫"
        case UInt16.kVK_Escape: return "⎋"
        case UInt16.kVK_UpArrow: return "↑"
        case UInt16.kVK_DownArrow: return "↓"
        case UInt16.kVK_LeftArrow: return "←"
        case UInt16.kVK_RightArrow: return "→"
        default:
            return String(Character(UnicodeScalar(key)!))
        }
    }
}