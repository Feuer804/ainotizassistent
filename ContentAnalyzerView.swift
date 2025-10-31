//
//  ContentAnalyzerView.swift
//  Visual Feedback für Content Analysis
//

import SwiftUI

// MARK: - Content Analyzer View
struct ContentAnalyzerView: View {
    @StateObject private var contentAnalyzer = ContentAnalyzer()
    @State private var inputText: String = ""
    @State private var analysisResult: ExtendedAnalysisResult?
    @State private var showingAnalysis: Bool = false
    
    // Visual States
    @State private var selectedTab: AnalysisTab = .overview
    
    var body: some View {
        NavigationView {
            VStack {
                if !showingAnalysis {
                    inputSection
                } else {
                    analysisSection
                }
            }
            .navigationTitle("Content Analyzer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            showingAnalysis.toggle()
                            if !showingAnalysis {
                                analysisResult = nil
                                inputText = ""
                            }
                        }
                    }) {
                        Image(systemName: showingAnalysis ? "arrow.left" : "plus")
                    }
                }
            }
        }
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(spacing: 20) {
            Text("Content Analysis")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Analysieren Sie Text auf Inhalt, Struktur und Qualität")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextEditor(text: $inputText)
                .frame(minHeight: 200)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(inputText.isEmpty ? Color.gray.opacity(0.3) : Color.blue.opacity(0.5), lineWidth: 2)
                )
            
            if !inputText.isEmpty {
                CharacterCounterView(text: inputText)
                    .padding(.horizontal)
            }
            
            Button(action: startAnalysis) {
                HStack {
                    if contentAnalyzer.isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(contentAnalyzer.isAnalyzing ? "Analysiere..." : "Analyse starten")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(inputText.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(inputText.isEmpty || contentAnalyzer.isAnalyzing)
            .padding(.horizontal)
            
            if contentAnalyzer.isAnalyzing {
                ProgressView("Analysiere Inhalt...")
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    // MARK: - Analysis Section
    private var analysisSection: some View {
        VStack {
            if let result = analysisResult {
                // Tab Selection
                Picker("Ansicht", selection: $selectedTab) {
                    ForEach(AnalysisTab.allCases, id: \.self) { tab in
                        Image(systemName: tab.icon).tag(tab)
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Analysis Content
                ScrollView {
                    switch selectedTab {
                    case .overview:
                        OverviewView(result: result)
                    case .sentiment:
                        SentimentView(result: result)
                    case .topics:
                        TopicsView(result: result)
                    case .quality:
                        QualityView(result: result)
                    case .suggestions:
                        SuggestionsView(result: result, analyzer: contentAnalyzer)
                    case .structure:
                        StructureView(result: result)
                    }
                }
            } else {
                ProgressView("Lade Analyse...")
                    .padding()
            }
        }
    }
    
    // MARK: - Analysis Functions
    private func startAnalysis() {
        guard !inputText.isEmpty else { return }
        
        contentAnalyzer.analyzeContent(inputText) { result in
            withAnimation(.easeInOut) {
                self.analysisResult = result
                self.showingAnalysis = true
            }
        }
    }
}

// MARK: - Supporting Views
struct CharacterCounterView: View {
    let text: String
    
    var body: some View {
        HStack {
            Text("\(text.count) Zeichen")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if text.count > 500 {
                Text("Längerer Text")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if text.count < 50 {
                Text("Sehr kurzer Text")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Text("Optimale Länge")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Analysis Tab Views
struct OverviewView: View {
    let result: ExtendedAnalysisResult
    
    var body: some View {
        VStack(spacing: 16) {
            // Header Card
            HeaderAnalysisCard(result: result)
            
            // Quick Stats
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(title: "Content Typ", value: result.contentType.rawValue, icon: result.contentType.icon, color: Color(hex: result.contentType.color))
                StatCard(title: "Dringlichkeit", value: result.urgency.level.rawValue, icon: urgencyIcon, color: urgencyColor)
                StatCard(title: "Sprache", value: result.language.displayName, icon: "globe", color: .blue)
                StatCard(title: "Qualität", value: "\(Int(result.overallQualityScore * 100))%", icon: "star.fill", color: qualityColor)
            }
            .padding(.horizontal)
            
            // Summary
            SummaryCard(result: result)
        }
        .padding(.vertical)
    }
    
    private var urgencyIcon: String {
        switch result.urgency.level {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "checkmark.circle.fill"
        }
    }
    
    private var urgencyColor: Color {
        switch result.urgency.level {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    private var qualityColor: Color {
        switch result.overallQualityScore {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct SentimentView: View {
    let result: ExtendedAnalysisResult
    
    var body: some View {
        VStack(spacing: 16) {
            SentimentCard(result: result)
            
            // Emotion Breakdown
            if !result.sentiment.emotions.isEmpty {
                EmotionCard(emotions: result.sentiment.emotions)
            }
            
            // Polarity Details
            PolarityCard(result: result)
        }
        .padding()
    }
}

struct TopicsView: View {
    let result: ExtendedAnalysisResult
    
    var body: some View {
        VStack(spacing: 16) {
            // Topics Overview
            TopicsOverviewCard(topics: result.topics)
            
            // Keywords
            KeywordsCard(keywords: result.keywords)
            
            // Topic Categories
            TopicCategoriesCard(topics: result.topics)
        }
        .padding()
    }
}

struct QualityView: View {
    let result: ExtendedAnalysisResult
    
    var body: some View {
        VStack(spacing: 16) {
            // Overall Quality Score
            QualityOverviewCard(quality: result.quality)
            
            // Detailed Metrics
            QualityMetricsCard(quality: result.quality)
            
            // Suggestions
            if !result.quality.suggestions.isEmpty {
                QualitySuggestionsCard(suggestions: result.quality.suggestions)
            }
        }
        .padding()
    }
}

struct SuggestionsView: View {
    let result: ExtendedAnalysisResult
    let analyzer: ContentAnalyzer
    
    @State private var selectedSuggestion: SmartSuggestion?
    
    var body: some View {
        VStack(spacing: 16) {
            // Smart Suggestions
            LazyVStack(spacing: 12) {
                ForEach(result.suggestions, id: \.title) { suggestion in
                    SuggestionCard(
                        suggestion: suggestion,
                        isExpanded: selectedSuggestion?.title == suggestion.title
                    ) {
                        withAnimation(.spring()) {
                            if selectedSuggestion?.title == suggestion.title {
                                selectedSuggestion = nil
                            } else {
                                selectedSuggestion = suggestion
                            }
                        }
                    }
                }
            }
            
            // Action Buttons
            ActionButtonsCard(result: result, analyzer: analyzer)
        }
        .padding()
    }
}

struct StructureView: View {
    let result: ExtendedAnalysisResult
    
    var body: some View {
        VStack(spacing: 16) {
            // Structure Overview
            StructureOverviewCard(structure: result.structure)
            
            // Content Statistics
            ContentStatsCard(structure: result.structure)
            
            // Structure Quality
            StructureQualityCard(structure: result.structure)
        }
        .padding()
    }
}

// MARK: - Card Components
struct HeaderAnalysisCard: View {
    let result: ExtendedAnalysisResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(result.contentType.icon)
                    .font(.title)
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.contentType.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Confidence: \(Int(result.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(result.overallQualityScore * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(qualityColor)
                    Text("Qualität")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Confidence Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Erkennungs-Sicherheit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(result.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                ProgressView(value: result.confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var qualityColor: Color {
        switch result.overallQualityScore {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SummaryCard: View {
    let result: ExtendedAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zusammenfassung")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                SummaryRow(label: "Sprache", value: result.language.displayName)
                SummaryRow(label: "Hauptthema", value: result.topics.first?.name ?? "Nicht erkannt")
                SummaryRow(label: "Sentiment", value: result.sentiment.polarity.rawValue)
                SummaryRow(label: "Dringlichkeit", value: result.urgency.level.rawValue)
                
                if let estimatedTime = result.urgency.estimatedTimeToComplete {
                    SummaryRow(
                        label: "Bearbeitungszeit",
                        value: formatDuration(estimatedTime)
                    )
                }
            }
            
            // Progress Indicators
            VStack(spacing: 8) {
                ProgressRow(label: "Lesbarkeit", value: result.quality.readabilityScore)
                ProgressRow(label: "Vollständigkeit", value: result.quality.completenessScore)
                ProgressRow(label: "Engagement", value: result.quality.engagementScore)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct ProgressRow: View {
    let label: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: value > 0.7 ? .green : value > 0.4 ? .orange : .red))
                .frame(maxWidth: .infinity)
            Text("\(Int(value * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .frame(width: 35, alignment: .trailing)
        }
    }
}

struct SentimentCard: View {
    let result: ExtendedAnalysisResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Sentiment")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(result.sentiment.polarity.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(sentimentColor)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(result.sentiment.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: result.sentiment.confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: sentimentColor))
                
                HStack {
                    Text("Intensität")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(result.sentiment.intensity * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: result.sentiment.intensity)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var sentimentColor: Color {
        switch result.sentiment.polarity {
        case .veryPositive: return .green
        case .positive: return .blue
        case .neutral: return .gray
        case .negative: return .orange
        case .veryNegative: return .red
        }
    }
}

struct EmotionCard: View {
    let emotions: [Emotion]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Emotionen")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(emotions, id: \.type) { emotion in
                    EmotionItem(emotion: emotion)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmotionItem: View {
    let emotion: Emotion
    
    var body: some View {
        VStack(spacing: 4) {
            Text(emotionIcon)
                .font(.title2)
            Text(emotionTitle)
                .font(.caption)
                .fontWeight(.medium)
            Text("\(Int(emotion.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var emotionIcon: String {
        switch emotion.type {
        case .joy: return "😊"
        case .sadness: return "😢"
        case .anger: return "😠"
        case .fear: return "😰"
        case .surprise: return "😲"
        case .disgust: return "🤢"
        case .trust: return "🤝"
        case .anticipation: return "🤔"
        }
    }
    
    private var emotionTitle: String {
        switch emotion.type {
        case .joy: return "Freude"
        case .sadness: return "Traurigkeit"
        case .anger: return "Wut"
        case .fear: return "Angst"
        case .surprise: return "Überraschung"
        case .disgust: return "Ekel"
        case .trust: return "Vertrauen"
        case .anticipation: return "Erwartung"
        }
    }
}

struct PolarityCard: View {
    let result: ExtendedAnalysisResult
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Sentiment-Verteilung")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Simplified sentiment visualization
            HStack(spacing: 2) {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: CGFloat((1.0 - result.sentiment.polarity.score) * 50))
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 20)
                Rectangle()
                    .fill(Color.green)
                    .frame(width: CGFloat((1.0 + result.sentiment.polarity.score) * 50))
            }
            .frame(height: 8)
            .cornerRadius(4)
            
            HStack {
                Text("Negativ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Neutral")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Positiv")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct ContentAnalyzerView_Previews: PreviewProvider {
    static var previews: some View {
        ContentAnalyzerView()
    }
}