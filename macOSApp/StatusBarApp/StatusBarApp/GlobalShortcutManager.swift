//
//  GlobalShortcutManager.swift
//  StatusBarApp
//
//  Erweiterte globale Tastenkombination-Verwaltung
//

import Cocoa

class GlobalShortcutManager {
    
    // MARK: - Properties
    
    private var globalShortcutMonitor: Any?
    private var shortcutKey: String = "n" // Standard-Taste für N
    private var modifierFlags: NSEvent.ModifierFlags = [.command, .shift] // ⌘⇧
    
    // MARK: - Singleton
    
    static let shared = GlobalShortcutManager()
    
    private init() {
        print("GlobalShortcutManager initialisiert")
    }
    
    // MARK: - Setup
    
    func setupGlobalShortcut(shortcutKey: String = "n", 
                           modifierFlags: NSEvent.ModifierFlags = [.command, .shift]) {
        self.shortcutKey = shortcutKey
        self.modifierFlags = modifierFlags
        
        // Event-Listener für globale Tastenkombination
        globalShortcutMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .keyDown
        ) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }
        
        print("Globale Tastenkombination registriert: \(modifierFlags.symbols) + \(shortcutKey.uppercased())")
    }
    
    private func handleGlobalKeyEvent(_ event: NSEvent) {
        // Prüfen ob die korrekten Modifier-Keys gedrückt sind
        guard event.modifierFlags.contains(modifierFlags) else { return }
        
        // Tastencode für die gewünschte Taste prüfen
        let keyCode = keyCodeForCharacter(shortcutKey)
        if event.keyCode == keyCode {
            DispatchQueue.main.async {
                self.handleShortcutActivated()
            }
        }
    }
    
    private func keyCodeForCharacter(_ character: String) -> UInt16 {
        // Mapping für häufig verwendete Tasten
        switch character.lowercased() {
        case "a": return 0
        case "s": return 1
        case "d": return 2
        case "f": return 3
        case "h": return 4
        case "g": return 5
        case "z": return 6
        case "x": return 7
        case "c": return 8
        case "v": return 9
        case "b": return 11
        case "q": return 12
        case "w": return 13
        case "e": return 14
        case "r": return 15
        case "y": return 16
        case "t": return 17
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "5": return 23
        case "6": return 22
        case "7": return 26
        case "8": return 28
        case "9": return 25
        case "0": return 29
        case "o": return 31
        case "u": return 32
        case "i": return 34
        case "l": return 37
        case "j": return 38
        case "k": return 40
        case ";": return 41
        case "n": return 45
        case "m": return 46
        case ",": return 43
        case ".": return 47
        case "/": return 44
        case "`": return 50
        case "-": return 27
        case "=": return 24
        case " ": return 49
        case "return": return 36
        case "tab": return 48
        case "escape": return 53
        case "delete": return 51
        default:
            // Für unbekannte Tasten - Fallback auf None
            print("Unbekannte Taste: \(character)")
            return 0
        }
    }
    
    private func handleShortcutActivated() {
        print("Globale Tastenkombination aktiviert: ⌘⇧+\(shortcutKey.uppercased())")
        
        // Benachrichtigung für andere Komponenten senden
        NotificationCenter.default.post(
            name: .globalShortcutActivated,
            object: nil,
            userInfo: [
                "shortcutKey": shortcutKey,
                "modifierFlags": modifierFlags.rawValue
            ]
        )
        
        // Akustisches Feedback (optional)
        NSSound.systemSoundID(.systemTadaSound).play()
    }
    
    // MARK: - Configuration
    
    func updateShortcut(shortcutKey: String, 
                       modifierFlags: NSEvent.ModifierFlags) {
        cleanup() // Alte Registrierung entfernen
        setupGlobalShortcut(shortcutKey: shortcutKey, modifierFlags: modifierFlags)
    }
    
    func getCurrentShortcut() -> (key: String, modifiers: String) {
        let keyName = shortcutKey.uppercased()
        let modifierNames = modifierFlags.map { modifier in
            switch modifier {
            case .command: return "⌘"
            case .shift: return "⇧"
            case .option: return "⌥"
            case .control: return "⌃"
            case .capsLock: return "⇪"
            case .numericPad: return "🔢"
            case .function: return "fn"
            default: return modifier.description
            }
        }.joined()
        
        return (key: keyName, modifiers: modifierNames)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        if let monitor = globalShortcutMonitor {
            NSEvent.removeMonitor(monitor)
            globalShortcutMonitor = nil
        }
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let globalShortcutActivated = Notification.Name("GlobalShortcutActivated")
}

// MARK: - NSEvent.ModifierFlags Extension

extension NSEvent.ModifierFlags {
    var symbols: String {
        var symbols = ""
        
        if contains(.command) { symbols += "⌘" }
        if contains(.shift) { symbols += "⇧" }
        if contains(.option) { symbols += "⌥" }
        if contains(.control) { symbols += "⌃" }
        if contains(.capsLock) { symbols += "⇪" }
        
        return symbols.isEmpty ? "" : symbols
    }
}