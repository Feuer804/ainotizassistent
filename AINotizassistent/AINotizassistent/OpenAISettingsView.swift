//
//  OpenAISettingsView.swift
//  AINotizassistent
//
//  Created by Claude on 2025-10-31.
//  SwiftUI Settings View für OpenAI Konfiguration
//

import SwiftUI

struct OpenAISettingsView: View {
    @StateObject private var apiKeyViewModel = APIKeyViewModel()
    @StateObject private var usageStatsViewModel = UsageStatisticsViewModel()
    @State private var showingDeleteConfirmation = false
    @State private var showingAPIKeyAlert = false
    @State private var tempAPIKey = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OpenAI API Konfiguration")) {
                    APIKeyRow(viewModel: apiKeyViewModel, tempAPIKey: $tempAPIKey)
                }
                
                Section(header: Text("Modell Einstellungen")) {
                    ModelSettingsSection()
                }
                
                Section(header: Text("Usage Statistiken")) {
                    UsageStatisticsSection(viewModel: usageStatsViewModel)
                }
                
                Section(header: Text("Rate Limiting")) {
                    RateLimitingSection()
                }
                
                Section(header: Text("Aktionen")) {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Alle Daten löschen", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("OpenAI Einstellungen")
            .onAppear {
                usageStatsViewModel.refreshData()
            }
            .alert("API Key Eingabe", isPresented: $showingAPIKeyAlert) {
                TextField("OpenAI API Key", text: $tempAPIKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Abbrechen") {
                    tempAPIKey = ""
                }
                Button("Speichern") {
                    if !tempAPIKey.isEmpty {
                        apiKeyViewModel.setAPIKey(tempAPIKey)
                        tempAPIKey = ""
                    }
                }
            }
            .alert("Bestätigung löschen", isPresented: $showingDeleteConfirmation) {
                Button("Löschen", role: .destructive) {
                    // Implement data clearing
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Sind Sie sicher, dass Sie alle Daten löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
    }
}

// MARK: - API Key Row

struct APIKeyRow: View {
    @ObservedObject var viewModel: APIKeyViewModel
    @Binding var tempAPIKey: String
    @State private var showingAPIKeyInput = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("API Key Status")
                Spacer()
                if viewModel.hasAPIKey {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            
            if let validationResult = viewModel.validationResult {
                Text(validationResult)
                    .font(.caption)
                    .foregroundColor(viewModel.hasAPIKey ? .green : .red)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack {
                if viewModel.hasAPIKey {
                    Button("Aktualisieren") {
                        showingAPIKeyInput = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Entfernen") {
                        viewModel.removeAPIKey()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button("API Key eingeben") {
                        showingAPIKeyInput = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if viewModel.isValidating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .sheet(isPresented: $showingAPIKeyInput) {
                APIKeyInputView(tempAPIKey: $tempAPIKey, onSave: {
                    if !tempAPIKey.isEmpty {
                        viewModel.setAPIKey(tempAPIKey)
                        tempAPIKey = ""
                        showingAPIKeyInput = false
                    }
                })
            }
        }
    }
}

// MARK: - API Key Input View

struct APIKeyInputView: View {
    @Binding var tempAPIKey: String
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("OpenAI API Key")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Geben Sie Ihren OpenAI API Key ein. Sie können einen Key von https://platform.openai.com/api-keys erhalten.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                SecureField("sk-...", text: $tempAPIKey)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                HStack {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Speichern") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(tempAPIKey.isEmpty)
                }
            }
            .padding()
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Model Settings Section

struct ModelSettingsSection: View {
    @AppStorage("preferredModel") private var preferredModel = "gpt-4"
    @AppStorage("temperature") private var temperature = 0.7
    @AppStorage("maxTokens") private var maxTokens = 1000
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Bevorzugtes Modell")
                Spacer()
                Picker("Modell", selection: $preferredModel) {
                    Text("GPT-4").tag("gpt-4")
                    Text("GPT-4 Turbo").tag("gpt-4-turbo")
                    Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                }
                .pickerStyle(.menu)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Temperature: \(String(format: "%.1f", temperature))")
                    Spacer()
                }
                Slider(value: $temperature, in: 0.0...2.0, step: 0.1) {
                    Text("Temperature")
                }
                Text("Höhere Werte machen die Antworten kreativer, niedrigere Werte deterministischer.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Max Tokens: \(maxTokens)")
                    Spacer()
                }
                Slider(value: $maxTokens, in: 100...4000, step: 100) {
                    Text("Max Tokens")
                }
                Text("Maximale Länge der generierten Antwort.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Usage Statistics Section

struct UsageStatisticsSection: View {
    @ObservedObject var viewModel: UsageStatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Heute")
                Spacer()
                Text("\(viewModel.currentUsage?.requestCount ?? 0) Requests")
                    .fontWeight(.semibold)
            }
            
            if let usage = viewModel.currentUsage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tokens verbraucht: \(usage.totalTokens)")
                    Text("Geschätzte Kosten: $\(String(format: "%.4f", usage.totalCost))")
                    Text("Requests heute: \(usage.requestCount)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            if !viewModel.usageHistory.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monat (30 Tage):")
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Gesamtkosten:")
                        Spacer()
                        Text("$\(String(format: "%.2f", viewModel.totalCostThisMonth))")
                    }
                    
                    HStack {
                        Text("Gesamt Tokens:")
                        Spacer()
                        Text("\(viewModel.totalTokensThisMonth.formatted())")
                    }
                    
                    HStack {
                        Text("Durchschnittliche tägliche Kosten:")
                        Spacer()
                        Text("$\(String(format: "%.2f", viewModel.averageDailyCost))")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Button("Aktualisieren") {
                viewModel.refreshData()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onAppear {
            viewModel.refreshData()
        }
    }
}

// MARK: - Rate Limiting Section

struct RateLimitingSection: View {
    @ObservedObject private var rateLimiter = RateLimiter()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rate Limit Status")
                Spacer()
                Circle()
                    .fill(rateLimiter.canMakeRequest() ? .green : .red)
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Limit pro Minute: 60 Requests")
                Text("Limit pro Tag: 1000 Requests")
                if !rateLimiter.canMakeRequest() {
                    Text("Nächster Request in: \(Int(rateLimiter.timeUntilNextRequest))s")
                        .foregroundColor(.orange)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text("Rate Limiting verhindert API Limits und Kostenüberschreitungen.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Content Type Selection Views

struct EmailTypeSelectionView: View {
    @Binding var selectedType: EmailType
    let types = EmailType.allCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("E-Mail-Typ wählen")
                .font(.headline)
            
            ForEach(types, id: \.self) { type in
                Button(action: {
                    selectedType = type
                }) {
                    HStack {
                        Text(emailTypeDisplayName(type))
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func emailTypeDisplayName(_ type: EmailType) -> String {
        switch type {
        case .general: return "Allgemein"
        case .business: return "Geschäftlich"
        case .support: return "Support"
        case .marketing: return "Marketing"
        case .followUp: return "Nachfrage"
        case .thankYou: return "Danksagung"
        }
    }
}

struct MeetingTypeSelectionView: View {
    @Binding var selectedType: MeetingType
    let types = MeetingType.allCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meeting-Typ wählen")
                .font(.headline)
            
            ForEach(types, id: \.self) { type in
                Button(action: {
                    selectedType = type
                }) {
                    HStack {
                        Text(meetingTypeDisplayName(type))
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func meetingTypeDisplayName(_ type: MeetingType) -> String {
        switch type {
        case .general: return "Allgemein"
        case .project: return "Projekt"
        case .planning: return "Planung"
        case .review: return "Review"
        case .brainstorming: return "Brainstorming"
        }
    }
}

struct ArticleTypeSelectionView: View {
    @Binding var selectedType: ArticleType
    let types = ArticleType.allCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Artikel-Typ wählen")
                .font(.headline)
            
            ForEach(types, id: \.self) { type in
                Button(action: {
                    selectedType = type
                }) {
                    HStack {
                        Text(articleTypeDisplayName(type))
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func articleTypeDisplayName(_ type: ArticleType) -> String {
        switch type {
        case .general: return "Allgemein"
        case .technical: return "Technisch"
        case .blog: return "Blog"
        case .news: return "News"
        case .tutorial: return "Tutorial"
        }
    }
}

// MARK: - SwiftUI Preview

struct OpenAISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAISettingsView()
    }
}

// MARK: - Extension für Enum Cases

extension EmailType: CaseIterable {
    static var allCases: [EmailType] {
        return [.general, .business, .support, .marketing, .followUp, .thankYou]
    }
}

extension MeetingType: CaseIterable {
    static var allCases: [MeetingType] {
        return [.general, .project, .planning, .review, .brainstorming]
    }
}

extension ArticleType: CaseIterable {
    static var allCases: [ArticleType] {
        return [.general, .technical, .blog, .news, .tutorial]
    }
}