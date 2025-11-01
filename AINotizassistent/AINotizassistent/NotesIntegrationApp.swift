//
//  NotesIntegrationApp.swift
//  Integration der Apple Notes Features in die bestehende App
//

import SwiftUI

@available(iOS 15.0, *)
class NotesIntegrationManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = NotesIntegrationManager()
    
    // MARK: - Published Properties
    @Published var notesViewModel = NotesIntegration()
    @Published var isEnabled = false
    @Published var integrationStatus = IntegrationStatus.disconnected
    
    // MARK: - Initialization
    private init() {
        checkIntegrationAvailability()
    }
    
    // MARK: - Integration Status
    func checkIntegrationAvailability() {
        #if os(iOS)
        // Prüfe iOS Version
        if #available(iOS 15.0, *) {
            isEnabled = true
            integrationStatus = .available
        } else {
            isEnabled = false
            integrationStatus = .unsupportedVersion
        }
        #elseif os(macOS)
        // Prüfe macOS Version
        if #available(macOS 12.0, *) {
            isEnabled = true
            integrationStatus = .available
        } else {
            isEnabled = false
            integrationStatus = .unsupportedVersion
        }
        #else
        isEnabled = false
        integrationStatus = .unsupported
        #endif
    }
    
    // MARK: - Integration in ContentView
    
    func integrateWithMainApp() {
        // Diese Methode kann von der Haupt-App aufgerufen werden
        // um die Apple Notes Integration zu aktivieren
        print("Apple Notes Integration wird aktiviert...")
    }
    
    // MARK: - Status Enum
    
    enum IntegrationStatus {
        case available
        case disconnected
        case permissionDenied
        case unsupportedVersion
        case unsupported
        
        var description: String {
            switch self {
            case .available:
                return "Verfügbar"
            case .disconnected:
                return "Nicht verbunden"
            case .permissionDenied:
                return "Berechtigung verweigert"
            case .unsupportedVersion:
                return "iOS/macOS Version nicht unterstützt"
            case .unsupported:
                return "Plattform nicht unterstützt"
            }
        }
        
        var color: Color {
            switch self {
            case .available:
                return .green
            case .disconnected:
                return .orange
            case .permissionDenied, .unsupportedVersion, .unsupported:
                return .red
            }
        }
    }
}

// MARK: - App State Extensions

extension AppState {
    
    // Erweitert die bestehende AppState um Apple Notes Integration
    
    @Published var appleNotesEnabled = false
    @Published var appleNotesStatus = NotesIntegrationManager.IntegrationStatus.disconnected
    
    func enableAppleNotesIntegration() {
        if #available(iOS 15.0, *) {
            appleNotesEnabled = true
            appleNotesStatus = .available
        } else {
            appleNotesEnabled = false
            appleNotesStatus = .unsupportedVersion
        }
    }
}

// MARK: - ContentView Integration Helper

@available(iOS 15.0, *)
struct AppleNotesIntegrationView: View {
    
    @StateObject private var integrationManager = NotesIntegrationManager.shared
    @State private var showingNotesView = false
    
    var body: some View {
        VStack {
            if integrationManager.isEnabled {
                // Zeige Apple Notes Integration Button in der Haupt-App
                Button(action: { showingNotesView = true }) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.title2)
                        Text("Apple Notes")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Zeige Info über nicht unterstützte Plattform
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    Text("Apple Notes Integration")
                        .font(.headline)
                    
                    Text(integrationManager.integrationStatus.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(isPresented: $showingNotesView) {
            NotesView()
        }
    }
}

// MARK: - Settings Integration

@available(iOS 15.0, *)
struct AppleNotesSettingsView: View {
    
    @StateObject private var integrationManager = NotesIntegrationManager.shared
    @State private var showingShortcutsInstructions = false
    
    var body: some View {
        Form {
            Section(header: Text("Apple Notes Integration")) {
                if integrationManager.isEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        // Status Anzeige
                        HStack {
                            Circle()
                                .fill(integrationManager.integrationStatus.color)
                                .frame(width: 8, height: 8)
                            
                            Text("Status")
                            Spacer()
                            Text(integrationManager.integrationStatus.description)
                                .foregroundColor(.secondary)
                        }
                        
                        // Quick Actions
                        VStack(spacing: 8) {
                            Button("Shortcuts Setup Anleitung") {
                                showingShortcutsInstructions = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Integration testen") {
                                Task {
                                    await testIntegration()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    Text("Apple Notes Integration ist auf dieser Plattform nicht verfügbar")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Funktionen")) {
                if integrationManager.isEnabled {
                    featureList
                } else {
                    Text("Für die Integration werden folgende Features benötigt:")
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• iOS 15.0+ oder macOS 12.0+")
                        Text("• Notes App")
                        Text("• Shortcuts App (optional)")
                        Text("• AppleScript (macOS)")
                    }
                    .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showingShortcutsInstructions) {
            ShortcutsSetupInstructions()
        }
    }
    
    private var featureList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verfügbare Funktionen:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                FeatureRow(icon: "plus.circle", text: "Neue Notizen erstellen")
                FeatureRow(icon: "arrow.clockwise", text: "Synchronisation mit Apple Notes")
                FeatureRow(icon: "magnifyingglass", text: "Spotlight Integration")
                FeatureRow(icon: "textformat", text: "Rich Text Support (Markdown)")
                FeatureRow(icon: "photo", text: "Bilder und Anhänge")
                FeatureRow(icon: "square.and.arrow.up", text: "Notiz teilen")
                FeatureRow(icon: "folder", text: "Kategorien-Management")
            }
        }
    }
    
    private func testIntegration() async {
        // Teste die Apple Notes Integration
        print("Teste Apple Notes Integration...")
        
        if #available(iOS 15.0, *) {
            let integration = NotesIntegration()
            
            do {
                let result = try await integration.syncWithAppleNotes()
                print("Test erfolgreich: \(result.notesCount) Notizen gefunden")
            } catch {
                print("Test fehlgeschlagen: \(error.localizedDescription)")
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            
            Text(text)
                .font(.caption)
            
            Spacer()
        }
    }
}

// MARK: - Shortcuts Setup Instructions

@available(iOS 15.0, *)
struct ShortcutsSetupInstructions: View {
    
    @State private var currentStep = 0
    
    let steps = [
        ShortcutSetupStep(
            title: "Shortcuts App öffnen",
            description: "Öffne die Shortcuts App auf deinem iPhone/iPad",
            icon: "shortcuts"
        ),
        ShortcutSetupStep(
            title: "Neuen Shortcut erstellen",
            description: "Tippe auf das '+' Symbol um einen neuen Shortcut zu erstellen",
            icon: "plus.circle"
        ),
        ShortcutSetupStep(
            title: "Actions hinzufügen",
            description: "Füge die benötigten AppleScript Actions hinzu für Notes-Operationen",
            icon: "plus.rectangle"
        ),
        ShortcutSetupStep(
            title: "Shortcuts testen",
            description: "Teste die Shortcuts um sicherzustellen, dass sie funktionieren",
            icon: "checkmark.circle"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress Indicator
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Current Step
                if currentStep < steps.count {
                    let step = steps[currentStep]
                    
                    VStack(spacing: 16) {
                        Image(systemName: step.icon)
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text(step.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Navigation Buttons
                    HStack {
                        if currentStep > 0 {
                            Button("Zurück") {
                                currentStep -= 1
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        Button(currentStep < steps.count - 1 ? "Weiter" : "Fertig") {
                            if currentStep < steps.count - 1 {
                                currentStep += 1
                            } else {
                                // Navigation zu /Dismiss
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
            .navigationTitle("Shortcuts Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ShortcutSetupStep {
    let title: String
    let description: String
    let icon: String
}

// MARK: - Deep Link Integration

@available(iOS 15.0, *)
struct AppleNotesDeepLinkHandler {
    
    static func handleDeepLink(_ url: URL) -> Bool {
        guard url.scheme == "ainotizassistent" else { return false }
        
        switch url.host {
        case "notes":
            handleNotesDeepLink(url)
            return true
        case "sync":
            handleSyncDeepLink()
            return true
        default:
            return false
        }
    }
    
    private static func handleNotesDeepLink(_ url: URL) {
        // Parse URL Parameter
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let action = components?.queryItems?.first { $0.name == "action" }?.value
        
        switch action {
        case "new":
            // Öffne neue Notiz Erstellung
            NotificationCenter.default.post(name: .showNewNote, object: nil)
        case "sync":
            // Starte Synchronisation
            NotificationCenter.default.post(name: .syncNotes, object: nil)
        default:
            break
        }
    }
    
    private static func handleSyncDeepLink() {
        // Starte direkte Synchronisation
        NotificationCenter.default.post(name: .syncNotes, object: nil)
    }
}

extension Notification.Name {
    static let showNewNote = Notification.Name("ShowNewNote")
    static let syncNotes = Notification.Name("SyncNotes")
}