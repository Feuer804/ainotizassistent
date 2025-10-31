//
//  ProcessingModeSettingsView.swift
//  Intelligente Notizen App
//  Benutzeroberfläche für Processing-Mode Konfiguration
//

import SwiftUI
import Charts

// MARK: - Main Settings View
struct ProcessingModeSettingsView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    @State private var selectedTab: SettingsTab = .general
    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    @State private var showingAnalyticsDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Navigation
                TabBarView(selectedTab: $selectedTab)
                
                // Content based on selected tab
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .privacy:
                    PrivacySettingsView()
                case .analytics:
                    AnalyticsSettingsView()
                case .rules:
                    ContentRulesView()
                case .providers:
                    ProviderSettingsView()
                }
            }
            .navigationTitle("KI-Verarbeitungs-Modi")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Analytics exportieren") {
                            showingExportSheet = true
                        }
                        Button("Zurücksetzen") {
                            showingResetAlert = true
                        }
                        Divider()
                        Button("Hilfe") {
                            showingHelpSheet()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportAnalyticsView(analytics: processingManager.analytics)
        }
        .alert("Einstellungen zurücksetzen?", isPresented: $showingResetAlert) {
            Button("Zurücksetzen", role: .destructive) {
                resetSettings()
            }
            Button("Abbrechen", role: .cancel) { }
        }
    }
    
    private func resetSettings() {
        processingManager.resetMetrics()
        processingManager.updateSettings(ProcessingModeSettings())
    }
    
    private func showingHelpSheet() {
        // Implement help sheet
    }
}

// MARK: - Tab Bar
struct TabBarView: View {
    @Binding var selectedTab: SettingsTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.title,
                        icon: tab.icon,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .overlay(
            Divider().offset(y: 35),
            alignment: .bottom
        )
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .blue : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
    }
}

enum SettingsTab: String, CaseIterable {
    case general = "general"
    case privacy = "privacy"
    case analytics = "analytics"
    case rules = "rules"
    case providers = "providers"
    
    var title: String {
        switch self {
        case .general: return "Allgemein"
        case .privacy: return "Privacy"
        case .analytics: return "Analytics"
        case .rules: return "Regeln"
        case .providers: return "Provider"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .privacy: return "lock.shield"
        case .analytics: return "chart.bar"
        case .rules: return "list.bullet.clipboard"
        case .providers: return "server.rack"
        }
    }
}

// MARK: - General Settings View
struct GeneralSettingsView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    @State private var tempSettings = ProcessingModeSettings()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Status Card
                StatusCardView()
                
                // Preferred Mode Selection
                ModeSelectionCard(settings: $tempSettings)
                
                // Thresholds
                ThresholdsCard(settings: $tempSettings)
                
                // Feature Toggles
                FeaturesCard(settings: $tempSettings)
                
                // Save Button
                Button("Einstellungen speichern") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasChanges)
                .padding(.top, 20)
            }
            .padding()
        }
        .onAppear {
            tempSettings = processingManager.settings
        }
    }
    
    private var hasChanges: Bool {
        tempSettings != processingManager.settings
    }
    
    private func saveSettings() {
        processingManager.updateSettings(tempSettings)
    }
}

struct StatusCardView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Aktueller Status")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    StatusRow(label: "Modus", value: processingManager.currentMode.rawValue, 
                             icon: processingManager.currentMode.icon)
                    StatusRow(label: "Provider", value: processingManager.currentProvider.rawValue, 
                             icon: "server")
                    StatusRow(label: "Letzte Entscheidung", 
                             value: processingManager.lastDecision?.reasoning ?? "Keine", 
                             icon: "brain")
                }
                
                if !processingManager.notifications.isEmpty {
                    Divider()
                    Text("Letzte Benachrichtigungen")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(processingManager.notifications.prefix(3)) { notification in
                        NotificationRow(notification: notification)
                    }
                }
            }
        }
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct NotificationRow: View {
    let notification: ProcessingNotification
    
    var body: some View {
        HStack {
            Image(systemName: notificationIcon)
                .foregroundColor(notificationSeverityColor)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(notification.message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(notification.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
            Spacer()
        }
    }
    
    private var notificationIcon: String {
        switch notification.type {
        case .modeSwitch: return "arrow.right.arrow.left"
        case .fallback: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .recommendation: return "lightbulb"
        }
    }
    
    private var notificationSeverityColor: Color {
        switch notification.severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Mode Selection Card
struct ModeSelectionCard: View {
    @Binding var settings: ProcessingModeSettings
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.green)
                    Text("Bevorzugter Modus")
                        .font(.headline)
                    Spacer()
                }
                
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(ProcessingMode.allCases, id: \.self) { mode in
                        ModeSelectionCard(
                            mode: mode,
                            isSelected: settings.preferredMode == mode
                        ) {
                            settings.preferredMode = mode
                        }
                    }
                }
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }
}

struct ModeSelectionCard: View {
    let mode: ProcessingMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mode.icon)
                    .font(.title2)
                Text(mode.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                Text(mode.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Thresholds Card
struct ThresholdsCard: View {
    @Binding var settings: ProcessingModeSettings
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(.orange)
                    Text("Schwellenwerte")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    ThresholdRow(
                        title: "Privacy-Schwelle",
                        subtitle: "Ab wann sensible Daten lokal verarbeitet werden",
                        value: $settings.privacyThreshold,
                        minValue: 0.0,
                        maxValue: 1.0,
                        format: "%.2f"
                    )
                    
                    ThresholdRow(
                        title: "Kosten-Schwelle",
                        subtitle: "Maximale Kosten pro Anfrage (USD)",
                        value: $settings.costThreshold,
                        minValue: 0.0,
                        maxValue: 0.5,
                        format: "$%.3f"
                    )
                    
                    ThresholdRow(
                        title: "Zeit-Schwelle",
                        subtitle: "Maximale Verarbeitungszeit (Sekunden)",
                        value: .constant(TimeInterval(settings.timeThreshold)),
                        minValue: 1.0,
                        maxValue: 30.0,
                        format: "%.1fs",
                        isTimeInterval: true
                    )
                    
                    ThresholdRow(
                        title: "Qualitäts-Schwelle",
                        subtitle: "Minimale akzeptable Qualität",
                        value: $settings.qualityThreshold,
                        minValue: 0.0,
                        maxValue: 1.0,
                        format: "%.2f"
                    )
                }
            }
        }
    }
}

struct ThresholdRow: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    @State private var tempValue: Double
    let minValue: Double
    let maxValue: Double
    let format: String
    let isTimeInterval: Bool
    
    init(title: String, subtitle: String, value: Binding<Double>, minValue: Double, maxValue: Double, format: String, isTimeInterval: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.format = format
        self.isTimeInterval = isTimeInterval
        
        _tempValue = State(initialValue: value.wrappedValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(displayValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            
            Slider(
                value: $tempValue,
                in: minValue...maxValue
            )
            .onChange(of: tempValue) { newValue in
                if isTimeInterval {
                    value.wrappedValue = TimeInterval(newValue)
                } else {
                    value.wrappedValue = newValue
                }
            }
        }
    }
    
    private var displayValue: String {
        let actualValue = isTimeInterval ? TimeInterval(value) : value
        return String(format: format, actualValue)
    }
}

// MARK: - Features Card
struct FeaturesCard: View {
    @Binding var settings: ProcessingModeSettings
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "togglepower")
                        .foregroundColor(.purple)
                    Text("Funktionen")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    FeatureToggle(
                        title: "Automatischer Modus-Wechsel",
                        subtitle: "Automatische Anpassung basierend auf Content",
                        isOn: $settings.autoSwitchEnabled
                    )
                    
                    FeatureToggle(
                        title: "Benachrichtigungen",
                        subtitle: "Benachrichtigung bei Modus-Wechseln",
                        isOn: $settings.notificationsEnabled
                    )
                    
                    FeatureToggle(
                        title: "Analytics aktivieren",
                        subtitle: "Sammle Nutzungsstatistiken für Verbesserungen",
                        isOn: $settings.analyticsEnabled
                    )
                }
            }
        }
    }
}

struct FeatureToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    @State private var selectedPrivacyLevel: SensitivityLevel = .internal
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Privacy Overview
                PrivacyOverviewCard()
                
                // Sensitivity Configuration
                SensitivityConfigCard()
                
                // Data Protection Rules
                DataProtectionCard()
                
                // Compliance Status
                ComplianceStatusCard()
            }
            .padding()
        }
    }
}

struct PrivacyOverviewCard: View {
    @StateObject private var processingManager = ProcessingModeManager()
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.blue)
                    Text("Privacy-Übersicht")
                        .font(.headline)
                    Spacer()
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    PrivacyStatCard(title: "Cloud-Nutzung", 
                                  value: "\(Int(processingManager.metrics.cloudUsagePercentage))%", 
                                  color: .blue)
                    PrivacyStatCard(title: "Lokale Verarbeitung", 
                                  value: "\(100 - Int(processingManager.metrics.cloudUsagePercentage))%", 
                                  color: .green)
                }
                
                Text("Ihre Daten werden basierend auf Sensibilität automatisch verarbeitet. Sensitive Daten verbleiben lokal.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
    }
}

struct PrivacyStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct SensitivityConfigCard: View {
    @State private var selectedLevel: SensitivityLevel = .internal
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Standard Privacy-Level")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    ForEach(SensitivityLevel.allCases, id: \.self) { level in
                        SensitivityLevelRow(
                            level: level,
                            isSelected: selectedLevel == level
                        ) {
                            selectedLevel = level
                        }
                    }
                }
            }
        }
    }
}

struct SensitivityLevelRow: View {
    let level: SensitivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(level.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(Int(level.privacyRisk * 100))% Risiko")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(privacyDescription(for: level))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func privacyDescription(for level: SensitivityLevel) -> String {
        switch level {
        case .public: return "Normale öffentliche Informationen"
        case .internal: return "Interne Unternehmensdaten"
        case .confidential: return "Vertrauliche Geschäftsdaten"
        case .highlyConfidential: return "Streng vertrauliche Informationen"
        }
    }
}

// MARK: - Analytics Settings View
struct AnalyticsSettingsView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time Range Selector
                TimeRangeSelector(selectedRange: $selectedTimeRange)
                
                // Usage Statistics
                UsageStatsView()
                
                // Performance Charts
                PerformanceChartsView()
                
                // Recommendations
                RecommendationsView()
                
                // Export Options
                ExportOptionsView()
            }
            .padding()
        }
    }
}

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        HStack {
            Text("Zeitraum")
                .font(.headline)
            Spacer()
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(range.rawValue) {
                    selectedRange = range
                }
                .buttonStyle(.bordered)
                .tint(selectedRange == range ? .blue : .gray)
            }
        }
    }
}

enum TimeRange: String, CaseIterable {
    case day = "24h"
    case week = "7T"
    case month = "30T"
    case year = "1J"
}

struct UsageStatsView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar")
                        .foregroundColor(.green)
                    Text("Nutzungsstatistiken")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    StatRow(label: "Gesamte Anfragen", value: "\(processingManager.metrics.totalRequests)")
                    StatRow(label: "Cloud-Anfragen", value: "\(processingManager.metrics.cloudRequests)")
                    StatRow(label: "Lokale Anfragen", value: "\(processingManager.metrics.localRequests)")
                    StatRow(label: "Automatische Wechsel", value: "\(processingManager.metrics.hybridSwitches)")
                    StatRow(label: "Fallback-Aktivierungen", value: "\(processingManager.metrics.fallbackActivations)")
                }
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct PerformanceChartsView: View {
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.orange)
                    Text("Performance-Diagramme")
                        .font(.headline)
                    Spacer()
                }
                
                // Placeholder for charts
                VStack(spacing: 16) {
                    Text("Verfügbare Diagramme:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ChartRow(title: "Antwortzeiten", description: "Durchschnittliche Antwortzeiten nach Provider")
                        ChartRow(title: "Qualitäts-Scores", description: "Qualitätsbewertungen nach Task-Typ")
                        ChartRow(title: "Kosten-Analyse", description: "Kosten pro Anfrage und Provider")
                        ChartRow(title: "Verfügbarkeit", description: "Provider-Verfügbarkeit über Zeit")
                    }
                }
            }
        }
    }
}

struct ChartRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct RecommendationsView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                    Text("Empfehlungen")
                        .font(.headline)
                    Spacer()
                }
                
                if processingManager.getRecommendations().isEmpty {
                    Text("Keine aktuellen Empfehlungen verfügbar.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(processingManager.getRecommendations(), id: \.self) { recommendation in
                            RecommendationRow(recommendation: recommendation)
                        }
                    }
                }
            }
        }
    }
}

struct RecommendationRow: View {
    let recommendation: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .frame(width: 20)
            Text(recommendation)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }
}

struct ExportOptionsView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.purple)
                    Text("Export & Teilen")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    ExportButton(
                        title: "Analytics als JSON exportieren",
                        icon: "doc.text",
                        action: { exportAnalyticsJSON() }
                    )
                    
                    ExportButton(
                        title: "Einstellungen teilen",
                        icon: "share",
                        action: { shareSettings() }
                    )
                    
                    ExportButton(
                        title: "Backup erstellen",
                        icon: "externaldrive",
                        action: { createBackup() }
                    )
                }
            }
        }
    }
    
    private func exportAnalyticsJSON() {
        // Implement JSON export
    }
    
    private func shareSettings() {
        // Implement settings sharing
    }
    
    private func createBackup() {
        // Implement backup creation
    }
}

struct ExportButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "arrow.up.circle")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
    }
}

// MARK: - Content Rules View
struct ContentRulesView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    @State private var showingRuleEditor = false
    @State private var selectedRule: ContentRule?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if processingManager.settings.contentRules.isEmpty {
                    emptyStateView
                } else {
                    rulesListView
                }
            }
            .navigationTitle("Content-Regeln")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedRule = nil
                        showingRuleEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingRuleEditor) {
                RuleEditorView(rule: $selectedRule) { newRule in
                    if let rule = newRule {
                        addOrUpdateRule(rule)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("Keine Content-Regeln")
                .font(.title2)
                .fontWeight(.medium)
            Text("Erstellen Sie Regeln für automatische Modus-Auswahl basierend auf Content-Patterns.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingRuleEditor = true
            } label: {
                Label("Erste Regel erstellen", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
    }
    
    private var rulesListView: some View {
        List {
            ForEach(processingManager.settings.contentRules, id: \.self) { rule in
                RuleRowView(rule: rule) {
                    selectedRule = rule
                    showingRuleEditor = true
                } onToggle: { isActive in
                    toggleRule(rule, isActive: isActive)
                } onDelete: {
                    deleteRule(rule)
                }
            }
        }
    }
    
    private func addOrUpdateRule(_ rule: ContentRule) {
        var updatedRules = processingManager.settings.contentRules
        
        if let index = updatedRules.firstIndex(where: { $0.name == rule.name }) {
            updatedRules[index] = rule
        } else {
            updatedRules.append(rule)
        }
        
        var updatedSettings = processingManager.settings
        updatedSettings.contentRules = updatedRules
        processingManager.updateSettings(updatedSettings)
    }
    
    private func toggleRule(_ rule: ContentRule, isActive: Bool) {
        let updatedRule = ContentRule(
            name: rule.name,
            pattern: rule.pattern,
            requiredMode: rule.requiredMode,
            priority: rule.priority,
            isActive: isActive
        )
        addOrUpdateRule(updatedRule)
    }
    
    private func deleteRule(_ rule: ContentRule) {
        let updatedRules = processingManager.settings.contentRules.filter { $0 != rule }
        var updatedSettings = processingManager.settings
        updatedSettings.contentRules = updatedRules
        processingManager.updateSettings(updatedSettings)
    }
}

struct RuleRowView: View {
    let rule: ContentRule
    let onEdit: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(rule.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("P\(rule.priority)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray4))
                            .cornerRadius(4)
                        Text(rule.requiredMode.icon)
                        Text(rule.requiredMode.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Pattern: \(rule.pattern)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Toggle("", isOn: .constant(rule.isActive))
                    .labelsHidden()
                    .onTapGesture {
                        onToggle(!rule.isActive)
                    }
            }
            
            HStack {
                Button("Bearbeiten") {
                    onEdit()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Button("Löschen") {
                    showingDeleteAlert = true
                }
                .font(.caption)
                .foregroundColor(.red)
                
                Spacer()
            }
        }
        .alert("Regel löschen?", isPresented: $showingDeleteAlert) {
            Button("Löschen", role: .destructive) {
                onDelete()
            }
            Button("Abbrechen", role: .cancel) { }
        }
    }
}

// MARK: - Rule Editor View
struct RuleEditorView: View {
    @Binding var rule: ContentRule?
    @State private var ruleName = ""
    @State private var rulePattern = ""
    @State private var selectedMode: ProcessingMode = .privacyFirst
    @State private var rulePriority = 1
    @State private var isActive = true
    let onSave: (ContentRule?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Regel Details") {
                    TextField("Regel-Name", text: $ruleName)
                    TextField("Regulärer Ausdruck", text: $rulePattern)
                        .font(.system(.body, design: .monospaced))
                    Picker("Erforderlicher Modus", selection: $selectedMode) {
                        ForEach(ProcessingMode.allCases, id: \.self) { mode in
                            Text("\(mode.icon) \(mode.rawValue)").tag(mode)
                        }
                    }
                    Stepper("Priorität: \(rulePriority)", value: $rulePriority, in: 1...10)
                    Toggle("Aktiv", isOn: $isActive)
                }
                
                Section("Vorschau") {
                    if !rulePattern.isEmpty {
                        Text("Diese Regel wird angewendet, wenn der Content dem Pattern entspricht:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(rulePattern)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle(rule?.name ?? "Neue Regel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        onSave(nil)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        saveRule()
                        dismiss()
                    }
                    .disabled(ruleName.isEmpty || rulePattern.isEmpty)
                }
            }
            .onAppear {
                if let existingRule = rule {
                    ruleName = existingRule.name
                    rulePattern = existingRule.pattern
                    selectedMode = existingRule.requiredMode
                    rulePriority = existingRule.priority
                    isActive = existingRule.isActive
                }
            }
        }
    }
    
    private func saveRule() {
        let newRule = ContentRule(
            name: ruleName,
            pattern: rulePattern,
            requiredMode: selectedMode,
            priority: rulePriority,
            isActive: isActive
        )
        onSave(newRule)
    }
}

// MARK: - Provider Settings View
struct ProviderSettingsView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(KIProviderType.allCases, id: \.self) { provider in
                    ProviderCardView(provider: provider, processingManager: processingManager)
                }
            }
            .padding()
        }
    }
}

struct ProviderCardView: View {
    let provider: KIProviderType
    @ObservedObject var processingManager: ProcessingModeManager
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider.rawValue)
                            .font(.headline)
                        Text(providerDescription(for: provider))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    StatusIndicator(isAvailable: isProviderAvailable(provider))
                }
                
                VStack(spacing: 12) {
                    if provider == .openAI {
                        ProviderDetailRow(label: "Modell", value: "GPT-3.5 Turbo")
                        ProviderDetailRow(label: "Kosten", value: "$0.03/1K Tokens")
                    } else if provider == .openRouter {
                        ProviderDetailRow(label: "Modell", value: "Multi-Provider")
                        ProviderDetailRow(label: "Kosten", value: "Variabel")
                    } else {
                        ProviderDetailRow(label: "Modell", value: "Llama 2")
                        ProviderDetailRow(label: "Kosten", value: "Lokal (Kostenfrei)")
                        ProviderDetailRow(label: "Setup", value: "Ollama erforderlich")
                    }
                    
                    ProviderDetailRow(
                        label: "Verfügbarkeit", 
                        value: isProviderAvailable(provider) ? "Verfügbar" : "Nicht verfügbar"
                    )
                }
                
                HStack {
                    Button(provider == .ollama ? "Ollama Setup" : "Konfigurieren") {
                        configureProvider(provider)
                    }
                    .buttonStyle(.bordered)
                    
                    if provider != .ollama {
                        Button("Test") {
                            testProvider(provider)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private func providerDescription(for provider: KIProviderType) -> String {
        switch provider {
        case .openAI:
            return "OpenAI GPT-3.5 Turbo - Hohe Qualität, zuverlässig"
        case .openRouter:
            return "OpenRouter - Kostenoptimiert, mehrere Modelle"
        case .ollama:
            return "Lokale Verarbeitung - Maximale Privatsphäre"
        }
    }
    
    private func isProviderAvailable(_ provider: KIProviderType) -> Bool {
        // Simple availability check
        return processingManager.providerManager.providerConfigs[provider]?.apiKey != ""
    }
    
    private func configureProvider(_ provider: KIProviderType) {
        // Open provider configuration
    }
    
    private func testProvider(_ provider: KIProviderType) {
        // Test provider functionality
    }
}

struct ProviderDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct StatusIndicator: View {
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isAvailable ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isAvailable ? "Online" : "Offline")
                .font(.caption)
                .foregroundColor(isAvailable ? .green : .red)
        }
    }
}

// MARK: - Export Analytics View
struct ExportAnalyticsView: View {
    let analytics: ProcessingAnalytics
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Analytics exportieren")
                    .font(.title)
                    .padding()
                
                Text("Export-Funktionalität wird implementiert.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Preview
struct ProcessingModeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingModeSettingsView()
    }
}