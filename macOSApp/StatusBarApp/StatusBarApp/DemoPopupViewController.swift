//
//  DemoPopupViewController.swift
//  StatusBarApp
//
//  Demo View Controller zur Demonstration der Window-Management Funktionen
//

import Cocoa
import AppKit

@objc class DemoPopupViewController: NSViewController {
    
    // MARK: - Properties
    
    private var titleLabel: NSTextField!
    private var infoLabel: NSTextField!
    private var animationButtons: [NSButton] = []
    private var effectButtons: [NSButton] = []
    private var closeButton: NSButton!
    
    private let buttonSize = NSSize(width: 120, height: 30)
    private let spacing: CGFloat = 10
    
    // MARK: - Initialization
    
    init(title: String = "Demo Popup") {
        super.init(nibName: nil, bundle: nil)
        
        // View Controller Titel setzen
        self.title = title
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func loadView() {
        // Main View erstellen
        let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = NSColor.clear.cgColor
        
        self.view = mainView
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View Styling
        view.layer?.cornerRadius = 12
        view.layer?.masksToBounds = true
        
        print("Demo Popup View geladen: \(self.title ?? "")")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        guard let mainView = self.view else { return }
        
        // Title Label
        titleLabel = NSTextField(labelWithString: title ?? "Demo Popup")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 20, y: 260, width: 360, height: 25)
        mainView.addSubview(titleLabel)
        
        // Info Label
        infoLabel = NSTextField(labelWithString: "Demonstriert Window-Management mit Animationen")
        infoLabel.font = NSFont.systemFont(ofSize: 12)
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.alignment = .center
        infoLabel.frame = NSRect(x: 20, y: 235, width: 360, height: 20)
        mainView.addSubview(infoLabel)
        
        // Animation Section
        createAnimationSection(in: mainView)
        
        // Effects Section
        createEffectsSection(in: mainView)
        
        // Close Button
        createCloseButton(in: mainView)
        
        // Separator Lines
        createSeparators(in: mainView)
    }
    
    private func createAnimationSection(in view: NSView) {
        // Section Label
        let sectionLabel = NSTextField(labelWithString: "Animationen testen:")
        sectionLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        sectionLabel.textColor = .labelColor
        sectionLabel.frame = NSRect(x: 20, y: 200, width: 200, height: 20)
        view.addSubview(sectionLabel)
        
        // Animation Buttons
        let animations: [(String, String)] = [
            ("Scale Up", "scale"),
            ("Slide Up", "slide"),
            ("Bounce", "bounce"),
            ("Fade", "fade"),
            ("Slide Right", "right"),
            ("Slide Left", "left")
        ]
        
        let columns = 3
        let rows = Int(ceil(Double(animations.count) / Double(columns)))
        
        for (index, (title, action)) in animations.enumerated() {
            let row = index / columns
            let column = index % columns
            
            let button = NSButton(title: title, target: self, action: #selector(testAnimation(_:)))
            button.identifier = NSUserInterfaceItemIdentifier(rawValue: action)
            button.bezelStyle = .rounded
            button.frame = NSRect(
                x: 20 + CGFloat(column) * (buttonSize.width + spacing),
                y: 160 - CGFloat(row) * (buttonSize.height + spacing),
                width: buttonSize.width,
                height: buttonSize.height
            )
            
            button.tag = index
            view.addSubview(button)
            animationButtons.append(button)
        }
    }
    
    private func createEffectsSection(in view: NSView) {
        // Section Label
        let sectionLabel = NSTextField(labelWithString: "Effekte testen:")
        sectionLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        sectionLabel.textColor = .labelColor
        sectionLabel.frame = NSRect(x: 20, y: 80, width: 200, height: 20)
        view.addSubview(sectionLabel)
        
        // Effect Buttons
        let effects: [(String, String)] = [
            ("Blur", "blur"),
            ("Glow", "glow"),
            ("Shake", "shake"),
            ("Pulse", "pulse"),
            ("Rotate", "rotate")
        ]
        
        for (index, (title, action)) in effects.enumerated() {
            let button = NSButton(title: title, target: self, action: #selector(testEffect(_:)))
            button.identifier = NSUserInterfaceItemIdentifier(rawValue: action)
            button.bezelStyle = .rounded
            button.frame = NSRect(
                x: 20 + CGFloat(index % 3) * (buttonSize.width + spacing),
                y: 50 - CGFloat(index / 3) * (buttonSize.height + spacing),
                width: buttonSize.width,
                height: buttonSize.height
            )
            
            button.tag = index + 100
            view.addSubview(button)
            effectButtons.append(button)
        }
    }
    
    private func createCloseButton(in view: NSView) {
        closeButton = NSButton(title: "Schließen", target: self, action: #selector(closeWindow))
        closeButton.bezelStyle = .rounded
        closeButton.keyEquivalent = "\r" // Enter key
        closeButton.frame = NSRect(x: 140, y: 10, width: 120, height: 30)
        view.addSubview(closeButton)
        
        // Schließen Button prominenter machen
        closeButton.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
    }
    
    private func createSeparators(in view: NSView) {
        // Separator 1
        let separator1 = NSBox(frame: NSRect(x: 10, y: 210, width: 380, height: 1))
        separator1.boxType = .separator
        view.addSubview(separator1)
        
        // Separator 2
        let separator2 = NSBox(frame: NSRect(x: 10, y: 90, width: 380, height: 1))
        separator2.boxType = .separator
        view.addSubview(separator2)
    }
    
    // MARK: - Actions
    
    @objc private func testAnimation(_ sender: NSButton) {
        guard let window = self.view.window else { return }
        
        guard let animationType = sender.identifier?.rawValue else { return }
        
        // Button feedback
        sender.isHighlighted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sender.isHighlighted = false
        }
        
        // Animationen testen
        switch animationType {
        case "scale":
            WindowAnimationHelper.shared.bounceWindow(window, intensity: 0.3, duration: 0.6)
            
        case "slide":
            WindowAnimationHelper.shared.bounceWindow(window, intensity: 0.2, duration: 0.5)
            
        case "bounce":
            WindowAnimationHelper.shared.bounceWindow(window)
            
        case "fade":
            WindowAnimationHelper.shared.crossfadeTransition(from: window, to: window, duration: 0.5)
            
        case "right":
            WindowAnimationHelper.shared.rotateWindow(window, angle: 5, duration: 0.3)
            
        case "left":
            WindowAnimationHelper.shared.rotateWindow(window, angle: -5, duration: 0.3)
            
        default:
            break
        }
        
        print("Animation getestet: \(animationType)")
    }
    
    @objc private func testEffect(_ sender: NSButton) {
        guard let window = self.view.window else { return }
        
        guard let effectType = sender.identifier?.rawValue else { return }
        
        // Button feedback
        sender.isHighlighted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sender.isHighlighted = false
        }
        
        // Effekte testen
        switch effectType {
        case "blur":
            WindowAnimationHelper.shared.applyBlurEffect(to: window, intensity: 0.8)
            // Blur nach 2 Sekunden entfernen
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                WindowAnimationHelper.shared.removeBlurEffect(from: window)
            }
            
        case "glow":
            WindowAnimationHelper.shared.applyGlowEffect(to: window, color: .systemBlue)
            // Glow nach 2 Sekunden entfernen (einfach durch neues Animieren)
            
        case "shake":
            WindowAnimationHelper.shared.shakeWindow(window, intensity: 10, duration: 0.5)
            
        case "pulse":
            WindowAnimationHelper.shared.pulseWindow(window, scale: 1.1, duration: 1.0)
            // Pulse nach 3 Sekunden stoppen
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                WindowAnimationHelper.shared.stopPulseAnimation(for: window)
            }
            
        case "rotate":
            WindowAnimationHelper.shared.rotateWindow(window, angle: 360, duration: 1.0)
            
        default:
            break
        }
        
        print("Effekt getestet: \(effectType)")
    }
    
    @objc private func closeWindow() {
        if let window = self.view.window {
            WindowManager.shared.closeWindow(window, animation: .scaleUp)
        }
    }
    
    // MARK: - Keyboard Shortcuts
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        
        switch event.keyCode {
        case 53: // ESC key
            closeWindow()
            
        case 49: // Space key
            // Space für Pulse-Effekt
            if let window = self.view.window {
                WindowAnimationHelper.shared.pulseWindow(window)
            }
            
        case 36: // Return key
            closeWindow()
            
        default:
            break
        }
    }
}