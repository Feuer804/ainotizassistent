//
//  AINotizassistentApp.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI
import AppKit

@main
struct AINotizassistentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Animation-System initialisieren
        _ = AnimationManager.shared
        _ = MicroInteractionManager()
        _ = ScreenTransitionManager()
        _ = LoadingAnimationManager()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}