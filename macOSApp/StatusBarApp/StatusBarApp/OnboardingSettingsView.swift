//
//  OnboardingSettingsView.swift
//  StatusBarApp
//
//  Onboarding flow for new users
//

import SwiftUI

struct OnboardingSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @State private var currentStep = 0
    @State private var completedSteps: Set<Int> = []
    @State private var showingOnboarding = false
    @State private var onboardingProgress: Double = 0
    
    private let totalSteps = 5
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Onboarding Status
                GroupBox("Onboarding-Status") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label(
                                coordinator.settings.onboarding.completed ? "Abgeschlossen" : "In Bearbeitung",
                                systemImage: coordinator.settings.onboarding.completed ? "checkmark.circle.fill" : "clock.circle"
                            )
                            .font(.headline)
                            .foregroundColor(coordinator.settings.onboarding.completed ? .green : .orange)
                            
                            Spacer()
                            
                            Text("\(completedSteps.count)/\(totalSteps) Schritte")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Progress Bar
                        VStack(alignment: .leading) {
                            ProgressView(value: Double(completedSteps.count), total: Double(totalSteps))
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text("Fortschritt: \(Int(onboardingProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Button("Onboarding starten") {
                                startOnboarding()
                            }
                            .buttonStyle(StartButtonStyle())
                            .disabled(coordinator.settings.onboarding.completed)
                            
                            Button("Onboarding wiederholen") {
                                restartOnboarding()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            if !coordinator.settings.onboarding.completed {
                                Button("Onboarding überspringen") {
                                    skipOnboarding()
                                }
                                .buttonStyle(SkipButtonStyle())
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Quick Start Guide
                GroupBox("Schnellstart-Anleitung") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Willkommen bei StatusBarApp! Diese Anleitung hilft Ihnen beim Einstieg.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(0..<totalSteps, id: \.self) { index in
                                OnboardingStepRow(
                                    step: onboardingSteps[index],
                                    isCompleted: completedSteps.contains(index),
                                    onComplete: { completeStep(index) }
                                )
                            }
                        }
                    }
                }
                
                // Interactive Tutorials
                GroupBox("Interaktive Tutorials") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Lernen Sie die wichtigsten Funktionen kennen:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            ForEach(tutorials, id: \.id) { tutorial in
                                TutorialCard(tutorial: tutorial) {
                                    startTutorial(tutorial.id)
                                }
                            }
                        }
                    }
                }
                
                // Tooltips & Hints
                GroupBox("Tooltips & Hinweise") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Tooltips aktiviert", isOn: $coordinator.settings.onboarding.enableTooltips)
                        Toggle("Hinweise aktiviert", isOn: $coordinator.settings.onboarding.enableHints)
                        
                        if coordinator.settings.onboarding.enableTooltips {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tooltip-Einstellungen:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                VStack(spacing: 4) {
                                    TooltipOptionRow(title: "Erste Verwendung", enabled: true)
                                    TooltipOptionRow(title: "KI-Konfiguration", enabled: true)
                                    TooltipOptionRow(title: "Auto-Save", enabled: true)
                                    TooltipOptionRow(title: "Shortcuts", enabled: false)
                                }
                            }
                        }
                    }
                }
                
                // Welcome Tour
                GroupBox("Willkommens-Tour") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Interaktive Willkommens-Tour")
                                .font(.headline)
                            
                            Spacer()
                            
                            if showingOnboarding {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Folgen Sie einer geführten Tour durch die wichtigsten Funktionen:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 8) {
                                ForEach(tourStops, id: \.id) { stop in
                                    TourStopRow(stop: stop)
                                }
                            }
                        }
                        
                        HStack {
                            Button("Tour starten") {
                                startWelcomeTour()
                            }
                            .buttonStyle(TourButtonStyle())
                            .disabled(showingOnboarding)
                            
                            Button("Tour-Spotlight") {
                                startSpotlightTour()
                            }
                            .buttonStyle(SpotlightButtonStyle())
                            
                            Spacer()
                        }
                    }
                }
                
                // Help Resources
                GroupBox("Hilfe-Ressourcen") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weitere Hilfe und Ressourcen:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            HelpResourceRow(
                                icon: "book.fill",
                                title: "Benutzerhandbuch",
                                description: "Vollständige Dokumentation",
                                action: { openUserManual() }
                            )
                            
                            HelpResourceRow(
                                icon: "video.circle.fill",
                                title: "Video-Tutorials",
                                description: "Schritt-für-Schritt Anleitungen",
                                action: { openVideoTutorials() }
                            )
                            
                            HelpResourceRow(
                                icon: "questionmark.circle.fill",
                                title: "FAQ",
                                description: "Häufig gestellte Fragen",
                                action: { openFAQ() }
                            )
                            
                            HelpResourceRow(
                                icon: "person.circle.fill",
                                title: "Support-Kontakt",
                                description: "Direkter Kontakt zum Support",
                                action: { openSupport() }
                            )
                        }
                    }
                }
                
                // Next Steps
                if !coordinator.settings.onboarding.completed {
                    GroupBox("Nächste Schritte") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Empfohlene nächste Schritte:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 8) {
                                NextStepRow(
                                    title: "KI-Provider konfigurieren",
                                    description: "OpenAI oder lokale Modelle einrichten",
                                    priority: "Hoch",
                                    action: { openKISettings() }
                                )
                                
                                NextStepRow(
                                    title: "Auto-Save aktivieren",
                                    description: "Automatische Speicherung einrichten",
                                    priority: "Mittel",
                                    action: { openAutoSaveSettings() }
                                )
                                
                                NextStepRow(
                                    title: "Shortcuts anpassen",
                                    description: "Tastenkombinationen nach Wunsch ändern",
                                    priority: "Niedrig",
                                    action: { openShortcutsSettings() }
                                )
                            }
                        }
                    }
                }
                
                // Completion Celebration
                if coordinator.settings.onboarding.completed {
                    GroupBox("🎉 Onboarding abgeschlossen!") {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            
                            Text("Herzlichen Glückwunsch!")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Sie haben das Onboarding erfolgreich abgeschlossen. StatusBarApp ist bereit für die Nutzung!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            HStack {
                                Button("Einstellungen öffnen") {
                                    openSettings()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                
                                Button("Quick Start") {
                                    startQuickStart()
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                
                                Spacer()
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingOnboarding) {
            InteractiveOnboardingView(coordinator: coordinator) {
                showingOnboarding = false
            }
            .frame(width: 800, height: 600)
        }
        .onAppear {
            loadOnboardingProgress()
        }
        .onChange(of: coordinator.settings.onboarding) { _ in
            updateProgress()
        }
    }
    
    // MARK: - State Properties
    
    @State private var onboardingSteps: [OnboardingStep] = [
        OnboardingStep(id: 0, title: "Willkommen", description: "Kennenlernen der App", icon: "hand.wave"),
        OnboardingStep(id: 1, title: "KI-Setup", description: "KI-Provider konfigurieren", icon: "brain.head.profile"),
        OnboardingStep(id: 2, title: "Storage", description: "Speicherort einrichten", icon: "internaldrive"),
        OnboardingStep(id: 3, title: "Auto-Save", description: "Automatische Speicherung", icon: "doc.richtext"),
        OnboardingStep(id: 4, title: "Shortcuts", description: "Tastenkombinationen", icon: "keyboard")
    ]
    
    @State private var tutorials: [Tutorial] = [
        Tutorial(id: "1", title: "Erste Schritte", description: "Grundlagen der App-Nutzung", duration: "5 min"),
        Tutorial(id: "2", title: "KI-Integration", description: "KI-Provider einrichten", duration: "10 min"),
        Tutorial(id: "3", title: "Shortcuts", description: "Tastenkombinationen meistern", duration: "3 min")
    ]
    
    @State private var tourStops: [TourStop] = [
        TourStop(id: "1", title: "Menüleiste", description: "Schnellzugriff auf alle Funktionen"),
        TourStop(id: "2", title: "Einstellungen", description: "Umfassende Konfigurationsoptionen"),
        TourStop(id: "3", title: "KI-Panel", description: "Direkte KI-Interaktion"),
        TourStop(id: "4", title: "Auto-Save", description: "Automatische Speicherung")
    ]
    
    // MARK: - Methods
    
    private func startOnboarding() {
        showingOnboarding = true
        currentStep = coordinator.settings.onboarding.currentStep
        print("Onboarding gestartet")
    }
    
    private func restartOnboarding() {
        completedSteps.removeAll()
        coordinator.settings.onboarding.completed = false
        coordinator.settings.onboarding.currentStep = 0
        coordinator.settings.onboarding.completedSteps = []
        coordinator.settings.onboarding.tutorialSkipped = false
        
        startOnboarding()
    }
    
    private func skipOnboarding() {
        coordinator.settings.onboarding.completed = true
        coordinator.settings.onboarding.tutorialSkipped = true
        completedSteps = Set(0..<totalSteps)
        
        let alert = NSAlert()
        alert.messageText = "Onboarding übersprungen"
        alert.informativeText = "Sie können das Onboarding jederzeit über die Einstellungen neu starten."
        alert.runModal()
    }
    
    private func completeStep(_ step: Int) {
        completedSteps.insert(step)
        coordinator.settings.onboarding.completedSteps = Array(completedSteps)
        coordinator.settings.onboarding.currentStep = step + 1
        
        if completedSteps.count == totalSteps {
            coordinator.settings.onboarding.completed = true
        }
        
        updateProgress()
    }
    
    private func startTutorial(_ tutorialId: String) {
        print("Starte Tutorial: \(tutorialId)")
    }
    
    private func startWelcomeTour() {
        showingOnboarding = true
    }
    
    private func startSpotlightTour() {
        print("Starte Spotlight Tour")
    }
    
    private func loadOnboardingProgress() {
        completedSteps = Set(coordinator.settings.onboarding.completedSteps)
        updateProgress()
    }
    
    private func updateProgress() {
        onboardingProgress = Double(completedSteps.count) / Double(totalSteps)
    }
    
    // MARK: - Help Methods
    
    private func openUserManual() {
        if let url = URL(string: coordinator.settings.about.documentationURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openVideoTutorials() {
        NSWorkspace.shared.open(URL(string: "https://docs.statusbarapp.com/videos")!)
    }
    
    private func openFAQ() {
        NSWorkspace.shared.open(URL(string: "https://docs.statusbarapp.com/faq")!)
    }
    
    private func openSupport() {
        if let url = URL(string: coordinator.settings.about.supportURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openKISettings() {
        coordinator.showKISettings()
    }
    
    private func openAutoSaveSettings() {
        coordinator.showCompleteSettings()
        // Navigation to auto-save would be implemented here
    }
    
    private func openShortcutsSettings() {
        coordinator.showShortcutsSettings()
    }
    
    private func openSettings() {
        coordinator.showCompleteSettings()
    }
    
    private func startQuickStart() {
        // Start quick start sequence
        openKISettings()
    }
}

// MARK: - Supporting Views

struct OnboardingStepRow: View {
    let step: OnboardingStep
    let isCompleted: Bool
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                } else {
                    Text("\(step.id)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading) {
                Text(step.title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(step.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isCompleted {
                Button("Abschließen") {
                    onComplete()
                }
                .buttonStyle(CompleteButtonStyle())
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }
}

struct TutorialCard: View {
    let tutorial: Tutorial
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(tutorial.title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(tutorial.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(tutorial.duration)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button("Start") {
                action()
            }
            .buttonStyle(TutorialButtonStyle())
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.05))
        )
    }
}

struct TooltipOptionRow: View {
    let title: String
    let enabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption2)
            
            Spacer()
            
            Text(enabled ? "Aktiv" : "Inaktiv")
                .font(.caption2)
                .foregroundColor(enabled ? .green : .secondary)
        }
    }
}

struct TourStopRow: View {
    let stop: TourStop
    
    var body: some View {
        HStack {
            Image(systemName: "location.circle")
                .foregroundColor(.blue)
                .font(.caption)
            
            VStack(alignment: .leading) {
                Text(stop.title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(stop.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct HelpResourceRow: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Öffnen") {
                action()
            }
            .buttonStyle(TextButtonStyle())
        }
    }
}

struct NextStepRow: View {
    let title: String
    let description: String
    let priority: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(priority)
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(priorityColor)
                )
                .foregroundColor(.white)
            
            Button("Los") {
                action()
            }
            .buttonStyle(NextStepButtonStyle())
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case "Hoch": return .red
        case "Mittel": return .orange
        case "Niedrig": return .green
        default: return .gray
        }
    }
}

struct InteractiveOnboardingView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    let onComplete: () -> Void
    @State private var currentStep = 0
    
    var body: some View {
        VStack {
            Text("Onboarding")
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
            
            Text("Schritt \(currentStep + 1) von 5")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Fertig") {
                onComplete()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
}

// MARK: - Data Models

struct OnboardingStep: Identifiable {
    let id: Int
    let title: String
    let description: String
    let icon: String
}

struct Tutorial: Identifiable {
    let id: String
    let title: String
    let description: String
    let duration: String
}

struct TourStop: Identifiable {
    let id: String
    let title: String
    let description: String
}

// MARK: - Button Styles

struct StartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.green.opacity(0.3)
                        : Color.green.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
    }
}

struct SkipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .foregroundColor(.orange)
    }
}

struct CompleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        configuration.isPressed
                        ? Color.blue.opacity(0.3)
                        : Color.blue.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

struct TutorialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.blue.opacity(0.3)
                        : Color.blue.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

struct TourButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.purple.opacity(0.3)
                        : Color.purple.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
    }
}

struct SpotlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.orange.opacity(0.3)
                        : Color.orange.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        configuration.isPressed
                        ? Color.blue.opacity(0.8)
                        : Color.blue
                    )
            )
            .foregroundColor(.white)
    }
}

struct NextStepButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        configuration.isPressed
                        ? Color.green.opacity(0.3)
                        : Color.green.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Preview

struct OnboardingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingSettingsView(coordinator: SettingsCoordinator())
            .frame(width: 500, height: 700)
    }
}