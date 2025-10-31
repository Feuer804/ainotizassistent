//
//  SettingsView.swift
//  StatusBarApp
//
//  Vollständiges Settings Interface mit Glassmorphism Design
//

import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @State private var selectedSection: SettingsCoordinator.SettingsSection = .general
    @State private var searchText = ""
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingResetAlert = false
    
    var body: some View {
        HSplitView {
            // Left Sidebar - Navigation
            navigationSidebar
            
            // Main Content Area
            mainContentArea
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showingExportSheet) {
            ExportImportView(type: .export, coordinator: coordinator)
                .frame(width: 500, height: 300)
        }
        .sheet(isPresented: $showingImportSheet) {
            ExportImportView(type: .import, coordinator: coordinator)
                .frame(width: 500, height: 300)
        }
        .alert("Settings zurücksetzen?", isPresented: $showingResetAlert) {
            Button("Zurücksetzen", role: .destructive) {
                coordinator.resetSettings()
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Alle Einstellungen werden auf die Standardwerte zurückgesetzt. Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }
    
    // MARK: - Navigation Sidebar
    
    private var navigationSidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("Einstellungen")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 8)
                .padding(.horizontal, 16)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                TextField("Einstellungen suchen...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Navigation Sections
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(SettingsCoordinator.SettingsSection.allCases, id: \.self) { section in
                        NavigationButton(
                            section: section,
                            isSelected: selectedSection == section,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSection = section
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Bottom Actions
            VStack(spacing: 8) {
                Divider()
                    .padding(.horizontal, 16)
                
                // Export/Import Buttons
                HStack(spacing: 8) {
                    Button("Export") {
                        showingExportSheet = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .font(.caption)
                    
                    Button("Import") {
                        showingImportSheet = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .font(.caption)
                }
                .padding(.horizontal, 16)
                
                Button("Reset") {
                    showingResetAlert = true
                }
                .buttonStyle(DestructiveButtonStyle())
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 200)
        .background(
            Color.white.opacity(0.1)
                .blur(radius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Main Content Area
    
    private var mainContentArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section Header
                sectionHeader
                
                // Dynamic Content based on selected section
                Group {
                    switch selectedSection {
                    case .general:
                        GeneralSettingsView(coordinator: coordinator)
                    case .ki:
                        KISettingsView(coordinator: coordinator)
                    case .storage:
                        StorageSettingsView(coordinator: coordinator)
                    case .autosave:
                        AutoSaveSettingsView(coordinator: coordinator)
                    case .shortcuts:
                        ShortcutsSettingsView(coordinator: coordinator)
                    case .notifications:
                        NotificationSettingsView(coordinator: coordinator)
                    case .privacy:
                        PrivacySettingsView(coordinator: coordinator)
                    case .about:
                        AboutSettingsView(coordinator: coordinator)
                    case .onboarding:
                        OnboardingSettingsView(coordinator: coordinator)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(selectedSection.rawValue)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(sectionDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Validation Status
            if !coordinator.validationErrors.isEmpty {
                Label("Validation Fehler", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            } else {
                Label("OK", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var sectionDescription: String {
        switch selectedSection {
        case .general:
            return "Grundlegende Anwendungseinstellungen"
        case .ki:
            return "KI-Provider Konfiguration (OpenAI, OpenRouter, lokale Modelle)"
        case .storage:
            return "Storage Provider (Primary/Secondary) Konfiguration"
        case .autosave:
            return "Auto-Save Konfiguration und Zeitintervalle"
        case .shortcuts:
            return "Globale Tastenkombinationen und Hotkeys"
        case .notifications:
            return "Benachrichtigungseinstellungen und Alerts"
        case .privacy:
            return "Datenschutz und Sicherheitseinstellungen"
        case .about:
            return "App-Informationen und Hilfe-Ressourcen"
        case .onboarding:
            return "Onboarding für neue Benutzer"
        }
    }
}

// MARK: - Navigation Button Component

struct NavigationButton: View {
    let section: SettingsCoordinator.SettingsSection
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: sectionIcon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(section.rawValue)
                    .font(.caption)
                    .lineLimit(1)
                
                Spacer()
                
                if section == .ki || section == .storage {
                    Text("•")
                        .foregroundColor(.orange)
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                        ? Color.blue.opacity(0.2)
                        : isHovered
                        ? Color.white.opacity(0.1)
                        : Color.clear
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.blue.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
    
    private var sectionIcon: String {
        switch section {
        case .general: return "gearshape"
        case .ki: return "brain.head.profile"
        case .storage: return "internaldrive"
        case .autosave: return "doc.richtext"
        case .shortcuts: return "keyboard"
        case .notifications: return "bell"
        case .privacy: return "lock"
        case .about: return "questionmark.circle"
        case .onboarding: return "person.circle.badge.plus"
        }
    }
}

// MARK: - Button Styles

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.gray.opacity(0.2)
                        : Color.white.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.red.opacity(0.2)
                        : Color.red.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(coordinator: SettingsCoordinator())
    }
}