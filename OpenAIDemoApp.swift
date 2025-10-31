//
//  OpenAIDemoApp.swift
//  AINotizassistent
//
//  Created by Claude on 2025-10-31.
//  Demo App für OpenAI API Integration
//

import SwiftUI

@main
struct OpenAIDemoApp: App {
    var body: some Scene {
        WindowGroup {
            OpenAIDemoView()
        }
    }
}

// MARK: - Main Demo View

struct OpenAIDemoView: View {
    @StateObject private var apiKeyViewModel = APIKeyViewModel()
    @StateObject private var usageStatsViewModel = UsageStatisticsViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var emailViewModel = EmailGenerationViewModel()
    @StateObject private var meetingViewModel = MeetingGenerationViewModel()
    @StateObject private var articleViewModel = ArticleGenerationViewModel()
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Overview Tab
            OverviewTabView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Übersicht")
                }
                .tag(0)
            
            // Chat Tab
            ChatTabView()
                .tabItem {
                    Image(systemName: "chat.bubble")
                    Text("Chat")
                }
                .tag(1)
            
            // Content Generation Tab
            ContentGenerationTabView()
                .tabItem {
                    Image(systemName: "wand.and.rays")
                    Text("Generator")
                }
                .tag(2)
            
            // Usage Tab
            UsageTabView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Usage")
                }
                .tag(3)
            
            // Settings Tab
            SettingsTabView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Einstellungen")
                }
                .tag(4)
        }
    }
}

// MARK: - Overview Tab

struct OverviewTabView: View {
    @StateObject private var openAIClient = OpenAIClient.shared
    @StateObject private var usageViewModel = UsageStatisticsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // API Status Card
                    APIStatusCard()
                    
                    // Quick Actions
                    QuickActionsCard()
                    
                    // Usage Summary
                    UsageSummaryCard(viewModel: usageViewModel)
                    
                    // Recent Activity
                    RecentActivityCard()
                }
                .padding()
            }
            .navigationTitle("OpenAI Integration")
        }
    }
}

struct APIStatusCard: View {
    @StateObject private var openAIClient = OpenAIClient.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("API Status")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(openAIClient.hasValidAPIKey() ? .green : .red)
                    .frame(width: 12, height: 12)
            }
            
            if openAIClient.hasValidAPIKey() {
                Text("✅ OpenAI API ist konfiguriert und bereit zur Verwendung")
                    .foregroundColor(.green)
            } else {
                Text("❌ OpenAI API Key muss konfiguriert werden")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
            
            Button("Einstellungen öffnen") {
                // Navigate to settings
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct QuickActionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schnellaktionen")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "E-Mail schreiben",
                    icon: "envelope",
                    color: .blue
                )
                
                QuickActionButton(
                    title: "Meeting Notizen",
                    icon: "person.3",
                    color: .green
                )
                
                QuickActionButton(
                    title: "Artikel erstellen",
                    icon: "doc.text",
                    color: .orange
                )
                
                QuickActionButton(
                    title: "Chat starten",
                    icon: "chat.bubble",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(color)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct UsageSummaryCard: View {
    @ObservedObject var viewModel: UsageStatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Übersicht")
                .font(.headline)
            
            if let usage = viewModel.currentUsage {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Heutige Requests:")
                        Spacer()
                        Text("\(usage.requestCount)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Verbrauchte Tokens:")
                        Spacer()
                        Text("\(usage.totalTokens.formatted())")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Geschätzte Kosten:")
                        Spacer()
                        Text("$\(String(format: "%.4f", usage.totalCost))")
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("Keine Usage-Daten verfügbar")
                    .foregroundColor(.secondary)
            }
            
            Button("Detaillierte Statistiken") {
                // Navigate to usage view
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct RecentActivityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Letzte Aktivität")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ActivityRow(
                    icon: "envelope",
                    title: "E-Mail generiert",
                    time: "vor 5 Minuten"
                )
                
                ActivityRow(
                    icon: "person.3",
                    title: "Meeting Notizen erstellt",
                    time: "vor 15 Minuten"
                )
                
                ActivityRow(
                    icon: "chat.bubble",
                    title: "Chat Nachricht gesendet",
                    time: "vor 23 Minuten"
                )
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let time: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Chat Tab

struct ChatTabView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Denkt nach...")
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                
                // Input Section
                HStack(spacing: 12) {
                    TextEditor(text: $viewModel.inputText)
                        .frame(minHeight: 40, maxHeight: 100)
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                    
                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading ? .gray : .blue)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("Chat mit GPT")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Löschen") {
                            viewModel.clearChat()
                        }
                        Button("Einstellungen") {
                            showingSettings = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            OpenAISettingsView()
        }
        .onAppear {
            checkAPIKey()
        }
    }
    
    private func checkAPIKey() {
        if !OpenAIClient.shared.hasValidAPIKey() {
            let errorMessage = ChatMessage(role: "system", content: "⚠️ Bitte konfigurieren Sie Ihren OpenAI API Key in den Einstellungen.")
            viewModel.messages.append(errorMessage)
        }
    }
}

// MARK: - Content Generation Tab

struct ContentGenerationTabView: View {
    @State private var selectedContentType = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Content Type", selection: $selectedContentType) {
                    Text("E-Mail").tag(0)
                    Text("Meeting").tag(1)
                    Text("Artikel").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                switch selectedContentType {
                case 0:
                    EmailGenerationPreviewView()
                case 1:
                    MeetingGenerationPreviewView()
                case 2:
                    ArticleGenerationPreviewView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Content Generator")
        }
    }
}

struct EmailGenerationPreviewView: View {
    @StateObject private var viewModel = EmailGenerationViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Type Selection
                Picker("E-Mail Typ", selection: $viewModel.emailType) {
                    Text("Allgemein").tag(EmailType.general)
                    Text("Geschäftlich").tag(EmailType.business)
                    Text("Support").tag(EmailType.support)
                    Text("Marketing").tag(EmailType.marketing)
                    Text("Nachfrage").tag(EmailType.followUp)
                    Text("Danksagung").tag(EmailType.thankYou)
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                
                // Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beschreiben Sie die E-Mail:")
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Generate Button
                Button("Generieren") {
                    viewModel.generateEmail()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                
                // Output
                if !viewModel.generatedEmail.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generierte E-Mail:")
                            .font(.headline)
                        
                        TextEditor(text: .constant(viewModel.generatedEmail))
                            .frame(height: 200)
                            .padding(8)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
    }
}

struct MeetingGenerationPreviewView: View {
    @StateObject private var viewModel = MeetingGenerationViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Type Selection
                Picker("Meeting Typ", selection: $viewModel.meetingType) {
                    Text("Allgemein").tag(MeetingType.general)
                    Text("Projekt").tag(MeetingType.project)
                    Text("Planung").tag(MeetingType.planning)
                    Text("Review").tag(MeetingType.review)
                    Text("Brainstorming").tag(MeetingType.brainstorming)
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                
                // Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beschreiben Sie das Meeting:")
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Generate Button
                Button("Generieren") {
                    viewModel.generateMeeting()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                
                // Output
                if !viewModel.generatedMeeting.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meeting Notizen:")
                            .font(.headline)
                        
                        TextEditor(text: .constant(viewModel.generatedMeeting))
                            .frame(height: 200)
                            .padding(8)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
    }
}

struct ArticleGenerationPreviewView: View {
    @StateObject private var viewModel = ArticleGenerationViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Type Selection
                Picker("Artikel Typ", selection: $viewModel.articleType) {
                    Text("Allgemein").tag(ArticleType.general)
                    Text("Technisch").tag(ArticleType.technical)
                    Text("Blog").tag(ArticleType.blog)
                    Text("News").tag(ArticleType.news)
                    Text("Tutorial").tag(ArticleType.tutorial)
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                
                // Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beschreiben Sie den Artikel:")
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Generate Button
                Button("Generieren") {
                    viewModel.generateArticle()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                
                // Output
                if !viewModel.generatedArticle.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generierter Artikel:")
                            .font(.headline)
                        
                        TextEditor(text: .constant(viewModel.generatedArticle))
                            .frame(height: 300)
                            .padding(8)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
    }
}

// MARK: - Usage Tab

struct UsageTabView: View {
    @StateObject private var viewModel = UsageStatisticsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Usage
                    CurrentUsageCard(viewModel: viewModel)
                    
                    // Usage History Chart
                    UsageHistoryChart(viewModel: viewModel)
                    
                    // Cost Analysis
                    CostAnalysisCard(viewModel: viewModel)
                }
                .padding()
            }
            .navigationTitle("Usage Statistiken")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aktualisieren") {
                        viewModel.refreshData()
                    }
                }
            }
        }
    }
}

struct CurrentUsageCard: View {
    @ObservedObject var viewModel: UsageStatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heutige Nutzung")
                .font(.headline)
            
            if let usage = viewModel.currentUsage {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Requests")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(usage.requestCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tokens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(usage.totalTokens.formatted())")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kosten")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.4f", usage.totalCost))")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            } else {
                Text("Keine Daten verfügbar")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct UsageHistoryChart: View {
    @ObservedObject var viewModel: UsageStatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Verlauf (30 Tage)")
                .font(.headline)
            
            if !viewModel.usageHistory.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.usageHistory, id: \.date) { usage in
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: 20, height: CGFloat(usage.requestCount * 5 + 20))
                                
                                Text("\(Calendar.current.component(.day, from: usage.date))")
                                    .font(.caption2)
                            }
                        }
                    }
                    .frame(height: 100)
                }
                
                Text("Balkendiagramm zeigt tägliche Request-Anzahl")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Keine History-Daten verfügbar")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct CostAnalysisCard: View {
    @ObservedObject var viewModel: UsageStatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kostenanalyse")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Monatliche Gesamtkosten:")
                    Spacer()
                    Text("$\(String(format: "%.2f", viewModel.totalCostThisMonth))")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Durchschnitt pro Tag:")
                    Spacer()
                    Text("$\(String(format: "%.2f", viewModel.averageDailyCost))")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Gesamte Tokens:")
                    Spacer()
                    Text("\(viewModel.totalTokensThisMonth.formatted())")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Gesamte Requests:")
                    Spacer()
                    Text("\(viewModel.totalRequestsThisMonth)")
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    var body: some View {
        OpenAISettingsView()
    }
}

// MARK: - SwiftUI Preview

struct OpenAIDemoView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAIDemoView()
    }
}