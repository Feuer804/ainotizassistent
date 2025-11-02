//
//  AppDelegate.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        requestInitialPermissions()
    }
    
    private func setupStatusItem() {
        // Status-Item in der Menüleiste erstellen
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "AI Notizassistent")
            button.image?.isTemplate = true
            
            // Action für Klick auf Status-Item
            button.action = #selector(statusItemClicked(_:))
            button.target = self
        }
    }
    
    private func setupPopover() {
        // Popover für die App-Ansicht erstellen
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: ContentView())
        popover?.behavior = .transient
        popover?.isDetached = false
    }
    
    private func requestInitialPermissions() {
        // Screen Recording Berechtigung anfordern
        requestScreenRecordingPermission()
        
        // Accessibility Berechtigung anfordern
        requestAccessibilityPermission()
    }
    
    private func requestScreenRecordingPermission() {
        if #available(macOS 10.15, *) {
            let status = CGDisplayStream.requestScreenCaptureAccess()
            if !status {
                showPermissionAlert(title: "Screen Recording Zugriff benötigt",
                                  message: "Diese App benötigt Screen Recording Zugriff, um Bildschirminhalte zu erfassen.")
            }
        }
    }
    
    private func requestAccessibilityPermission() {
        let status = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt.takeValue": true] as CFDictionary)
        if !status {
            showPermissionAlert(title: "Accessibility Zugriff benötigt",
                              message: "Diese App benötigt Accessibility Zugriff, um mit anderen Anwendungen zu interagieren.")
        }
    }
    
    private func showPermissionAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusItem) {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                showPopover()
            }
        }
    }
    
    private func showPopover() {
        if let popover = popover, let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func hidePopover() {
        popover?.performClose(nil)
    }
    
    // MARK: - Menü-Handler
    @objc func togglePopover(_ sender: Any?) {
        if let popover = popover {
            if popover.isShown {
                hidePopover()
            } else {
                showPopover()
            }
        }
    }
    
    @objc func quitApp(_ sender: Any?) {
        NSApplication.shared.terminate(self)
    }
    
    @objc func showAbout(_ sender: Any?) {
        NSApplication.shared.orderFrontStandardAboutPanel(self)
    }
}

// MARK: - Audio Recorder Helper
class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var isRecording = false
    
    weak var delegate: AudioRecorderDelegate?
    
    func startRecording() {
        guard !isRecording else { return }
        
        // AVAudioSession ist auf macOS nicht verfügbar - Audio-Funktionalität deaktiviert
        // Für macOS würde eine andere Implementierung benötigt werden
        do {
            // try audioSession.setCategory(.record, mode: .default, options: [.defaultToSpeaker])
            // try audioSession.setActive(true)
            
            // Temporäre Datei für Aufnahme erstellen
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128000,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            
            DispatchQueue.main.async {
                self.delegate?.audioRecorderDidStartRecording()
            }
            
        } catch {
            print("Fehler beim Starten der Aufnahme: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        
        DispatchQueue.main.async {
            self.delegate?.audioRecorderDidStopRecording()
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            // Hier würde normalerweise die Speech-to-Text Verarbeitung stattfinden
            // Für die Demo simulieren wir eine Transkription
            let mockTranscripts = [
                "Dies ist eine Beispiel-Transkription der gesprochenen Wörter.",
                "Die App kann Sprache in Text umwandeln.",
                "Notizen werden automatisch erstellt und gespeichert.",
                "AI-Assistent ist bereit für weitere Aufgaben."
            ]
            
            let randomTranscript = mockTranscripts.randomElement() ?? "Transkription empfangen."
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.delegate?.audioRecorderDidReceiveTranscript(randomTranscript)
            }
        }
    }
}

// MARK: - Audio Recorder Delegate Protocol
protocol AudioRecorderDelegate: AnyObject {
    func audioRecorderDidStartRecording()
    func audioRecorderDidStopRecording()
    func audioRecorderDidReceiveTranscript(_ transcript: String)
}