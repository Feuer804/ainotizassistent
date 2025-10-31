//
//  ContentAnalyzerExtensions.swift
//  Additional Components und Extensions für Content Analysis
//

import SwiftUI

// MARK: - Analysis Tabs
enum AnalysisTab: String, CaseIterable {
    case overview = "overview"
    case sentiment = "sentiment"
    case topics = "topics"
    case quality = "quality"
    case suggestions = "suggestions"
    case structure = "structure"
    
    var title: String {
        switch self {
        case .overview: return "Übersicht"
        case .sentiment: return "Sentiment"
        case .topics: return "Themen"
        case .quality: return "Qualität"
        case .suggestions: return "Vorschläge"
        case .structure: return "Struktur"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "doc.text"
        case .sentiment: return "heart"
        case .topics: return "tag"
        case .quality: return "star"
        case .suggestions: return "lightbulb"
        case .structure: return "list.bullet"
        }
    }
}

// MARK: - Topics Card Components
struct TopicsOverviewCard: View {
    let topics: [Topic]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Erkannte Themen")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(topics.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            if topics.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tag.slash")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("Keine Themen erkannt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Der Text könnte zu kurz oder unklar sein")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(topics.prefix(5), id: \.name) { topic in
                        TopicRow(topic: topic)
                    }
                    
                    if topics.count > 5 {
                        Text("+\(topics.count - 5) weitere Themen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TopicRow: View {
    let topic: Topic
    
    var body: some View {
        HStack {
            Circle()
                .fill(topicColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(topic.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(topic.category.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(topic.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                ProgressView(value: topic.confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: topicColor))
                    .frame(width: 40)
            }
        }
    }
    
    private var topicColor: Color {
        switch topic.category {
        case .business: return .blue
        case .technology: return .green
        case .health: return .red
        case .education: return .purple
        case .entertainment: return .pink
        case .sports: return .orange
        case .politics: return .indigo
        case .science: return .teal
        case .other: return .gray
        }
    }
}

struct KeywordsCard: View {
    let keywords: [Keyword]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Schlüsselwörter")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(keywords.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            if keywords.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "key.horizontal")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("Keine Schlüsselwörter")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(keywords.prefix(8), id: \.term) { keyword in
                        KeywordTag(keyword: keyword)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KeywordTag: View {
    let keyword: Keyword
    
    var body: some View {
        VStack(spacing: 4) {
            Text(keyword.term)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            HStack {
                Text(keyword.category.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(keyword.frequency)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: keyword.relevance)
                .progressViewStyle(LinearProgressViewStyle(tint: keywordColor))
                .frame(height: 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var keywordColor: Color {
        switch keyword.category {
        case .technical: return .blue
        case .business: return .green
        case .emotional: return .pink
        case .action: return .orange
        case .location: return .purple
        case .person: return .indigo
        case .organization: return .teal
        case .other: return .gray
        }
    }
}

struct TopicCategoriesCard: View {
    let topics: [Topic]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Themen-Kategorien")
                .font(.headline)
                .fontWeight(.semibold)
            
            if topics.isEmpty {
                Text("Keine Kategorien verfügbar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                let categoryDistribution = calculateCategoryDistribution(topics: topics)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(categoryDistribution, id: \.category) { item in
                        CategoryItem(category: item.category, count: item.count, percentage: item.percentage)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func calculateCategoryDistribution(topics: [Topic]) -> [CategoryItem] {
        let categoryCounts = topics.reduce(into: [Topic.TopicCategory: Int]()) { dict, topic in
            dict[topic.category, default: 0] += 1
        }
        
        let total = topics.count
        
        return categoryCounts.map { category, count in
            CategoryItem(
                category: category,
                count: count,
                percentage: Double(count) / Double(total)
            )
        }.sorted { $0.count > $1.count }
    }
}

struct CategoryItem: View {
    let category: Topic.TopicCategory
    let count: Int
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 6) {
            Text(categoryIcon)
                .font(.title2)
            Text(categoryTitle)
                .font(.caption)
                .fontWeight(.medium)
            Text("\(count) Themen")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: categoryColor))
                .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var categoryIcon: String {
        switch category {
        case .business: return "briefcase"
        case .technology: return "laptopcomputer"
        case .health: return "heart.text.square"
        case .education: return "graduationcap"
        case .entertainment: return "popcorn"
        case .sports: return "figure.run"
        case .politics: return "building.columns"
        case .science: return "flask"
        case .other: return "ellipsis.circle"
        }
    }
    
    private var categoryTitle: String {
        switch category {
        case .business: return "Business"
        case .technology: return "Technologie"
        case .health: return "Gesundheit"
        case .education: return "Bildung"
        case .entertainment: return "Unterhaltung"
        case .sports: return "Sport"
        case .politics: return "Politik"
        case .science: return "Wissenschaft"
        case .other: return "Sonstiges"
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .business: return .blue
        case .technology: return .green
        case .health: return .red
        case .education: return .purple
        case .entertainment: return .pink
        case .sports: return .orange
        case .politics: return .indigo
        case .science: return .teal
        case .other: return .gray
        }
    }
}

struct CategoryItem {
    let category: Topic.TopicCategory
    let count: Int
    let percentage: Double
}

// MARK: - Quality Card Components
struct QualityOverviewCard: View {
    let quality: ContentQuality
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Qualitäts-Bewertung")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(overallScore * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(qualityColor)
            }
            
            // Overall Score Ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: overallScore)
                    .stroke(qualityColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(overallScore * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Gesamt")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Quality Breakdown
            QualityBreakdownView(quality: quality)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var overallScore: Double {
        (quality.readabilityScore + quality.completenessScore + quality.engagementScore) / 3.0
    }
    
    private var qualityColor: Color {
        switch overallScore {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        case 0.4..<0.6: return .yellow
        default: return .red
        }
    }
}

struct QualityBreakdownView: View {
    let quality: ContentQuality
    
    var body: some View {
        VStack(spacing: 8) {
            QualityMetricRow(
                title: "Lesbarkeit",
                score: quality.readabilityScore,
                icon: "doc.text"
            )
            QualityMetricRow(
                title: "Vollständigkeit",
                score: quality.completenessScore,
                icon: "checkmark.circle"
            )
            QualityMetricRow(
                title: "Engagement",
                score: quality.engagementScore,
                icon: "hand.thumbsup"
            )
            QualityMetricRow(
                title: "Grammatik",
                score: quality.grammarScore,
                icon: "checkmark.shield"
            )
            QualityMetricRow(
                title: "Struktur",
                score: quality.structureScore,
                icon: "list.bullet"
            )
        }
    }
}

struct QualityMetricRow: View {
    let title: String
    let score: Double
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(Int(score * 100))%")
                .font(.caption)
                .fontWeight(.medium)
            
            ProgressView(value: score)
                .progressViewStyle(LinearProgressViewStyle(tint: scoreColor))
                .frame(width: 60)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        case 0.4..<0.6: return .yellow
        default: return .red
        }
    }
}

struct QualityMetricsCard: View {
    let quality: ContentQuality
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Detail-Metriken")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Flesch-Kincaid ähnliche Score Visualisierung
            VStack(spacing: 8) {
                MetricBar(
                    title: "Satzlängen-Optimierung",
                    score: calculateSentenceScore(),
                    description: "Optimale Satzlänge für bessere Lesbarkeit"
                )
                
                MetricBar(
                    title: "Wortschatz-Komplexität",
                    score: calculateVocabularyScore(),
                    description: "Ausgewogene Nutzung einfacher und komplexer Wörter"
                )
                
                MetricBar(
                    title: "Struktur-Klarheit",
                    score: quality.structureScore,
                    description: "Logischer Aufbau und Gliederung"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func calculateSentenceScore() -> Double {
        // Vereinfachte Berechnung basierend auf Grammatik-Score
        return quality.readabilityScore
    }
    
    private func calculateVocabularyScore() -> Double {
        // Vereinfachte Berechnung basierend auf verschiedenen Scores
        return (quality.grammarScore + quality.engagementScore) / 2.0
    }
}

struct MetricBar: View {
    let title: String
    let score: Double
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }
            
            ProgressView(value: score)
                .progressViewStyle(LinearProgressViewStyle(tint: scoreColor))
                .frame(height: 6)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        case 0.4..<0.6: return .yellow
        default: return .red
        }
    }
}

struct QualitySuggestionsCard: View {
    let suggestions: [ContentQuality.QualitySuggestion]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Qualitäts-Verbesserungen")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(suggestions.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(suggestions, id: \.message) { suggestion in
                    QualitySuggestionRow(suggestion: suggestion)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QualitySuggestionRow: View {
    let suggestion: ContentQuality.QualitySuggestion
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: severityIcon)
                .font(.caption)
                .foregroundColor(severityColor)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.message)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(suggestion.suggestion)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var severityIcon: String {
        switch suggestion.severity {
        case .error: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private var severityColor: Color {
        switch suggestion.severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

// MARK: - Suggestion Card Components
struct SuggestionCard: View {
    let suggestion: SmartSuggestion
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: suggestionIcon)
                        .font(.caption)
                        .foregroundColor(priorityColor)
                    
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(priorityText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(priorityColor)
                    
                    Button(action: onTap) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Kategorie:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(suggestion.category)
                            .font(.caption2)
                            .fontWeight(.medium)
                        Spacer()
                        Text(suggestion.type.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let action = suggestion.action {
                        HStack {
                            Text("Aktion:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(action)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(priorityColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var suggestionIcon: String {
        switch suggestion.type {
        case .improvement: return "lightbulb.fill"
        case .action: return "checkmark.circle.fill"
        case .format: return "textformat"
        case .content: return "doc.text"
        case .structure: return "list.bullet"
        }
    }
    
    private var priorityColor: Color {
        switch suggestion.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    private var priorityText: String {
        switch suggestion.priority {
        case .critical: return "Kritisch"
        case .high: return "Hoch"
        case .medium: return "Mittel"
        case .low: return "Niedrig"
        }
    }
}

struct ActionButtonsCard: View {
    let result: ExtendedAnalysisResult
    let analyzer: ContentAnalyzer
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Aktionen")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ActionButton(
                    title: "Exportieren",
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    exportAnalysis()
                }
                
                ActionButton(
                    title: "Neu analysieren",
                    icon: "arrow.clockwise",
                    color: .green
                ) {
                    reAnalyze()
                }
                
                ActionButton(
                    title: "Text bearbeiten",
                    icon: "pencil",
                    color: .orange
                ) {
                    editText()
                }
                
                ActionButton(
                    title: "Teilen",
                    icon: "square.and.arrow.up",
                    color: .purple
                ) {
                    shareAnalysis()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func exportAnalysis() {
        // Implement export functionality
        print("Exporting analysis...")
    }
    
    private func reAnalyze() {
        analyzer.analyzeContent(result.originalText) { newResult in
            print("Re-analyzed content")
        }
    }
    
    private func editText() {
        // Implement text editing functionality
        print("Opening text editor...")
    }
    
    private func shareAnalysis() {
        // Implement sharing functionality
        print("Sharing analysis...")
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
        }
    }
}

// MARK: - Structure Card Components
struct StructureOverviewCard: View {
    let structure: ContentStructure
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Struktur-Übersicht")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(calculateStructureScore())%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(structureColor)
            }
            
            // Visual Structure Map
            HStack(spacing: 8) {
                StructureElement(icon: "header", active: structure.hasHeaders, label: "Header")
                StructureElement(icon: "list.bullet", active: structure.hasLists, label: "Listen")
                StructureElement(icon: "link", active: structure.hasLinks, label: "Links")
                StructureElement(icon: "photo", active: structure.hasImages, label: "Bilder")
                StructureElement(icon: "curlybraces", active: structure.hasCode, label: "Code")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func calculateStructureScore() -> Int {
        var score = 0
        if structure.hasHeaders { score += 20 }
        if structure.hasLists { score += 20 }
        if structure.hasLinks { score += 20 }
        if structure.hasImages { score += 20 }
        if structure.hasCode { score += 20 }
        return score
    }
    
    private var structureColor: Color {
        let score = calculateStructureScore()
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        case 40..<60: return .yellow
        default: return .red
        }
    }
}

struct StructureElement: View {
    let icon: String
    let active: Bool
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(active ? .blue : .gray)
            Text(label)
                .font(.caption2)
                .foregroundColor(active ? .blue : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(active ? Color.blue.opacity(0.1) : Color(.systemGray5))
        .cornerRadius(8)
    }
}

struct ContentStatsCard: View {
    let structure: ContentStructure
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Inhalt-Statistiken")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(title: "Absätze", value: "\(structure.paragraphCount)", icon: "paragraphsymbol")
                StatCard(title: "Sätze", value: "\(structure.sentenceCount)", icon: "quotationmarks")
                StatCard(title: "Wörter", value: "\(structure.wordCount)", icon: "textformat")
                StatCard(title: "Header", value: "\(structure.headerHierarchy.count)", icon: "header")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StructureQualityCard: View {
    let structure: ContentStructure
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Struktur-Qualität")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                QualityRow(title: "Header-Hierarchie", score: headerScore())
                QualityRow(title: "Listen-Struktur", score: listScore())
                QualityRow(title: "Formatierung", score: formattingScore())
                QualityRow(title: "Konsistenz", score: consistencyScore())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func headerScore() -> Double {
        structure.hasHeaders ? (structure.headerHierarchy.count > 0 ? 1.0 : 0.5) : 0.0
    }
    
    private func listScore() -> Double {
        structure.hasLists ? 1.0 : 0.0
    }
    
    private func formattingScore() -> Double {
        var score = 0.0
        if structure.hasHeaders { score += 0.3 }
        if structure.hasLists { score += 0.3 }
        if structure.hasCode { score += 0.2 }
        if structure.hasLinks { score += 0.2 }
        return score
    }
    
    private func consistencyScore() -> Double {
        // Vereinfachte Konsistenz-Bewertung
        let elements = [structure.hasHeaders, structure.hasLists, structure.hasCode].filter { $0 }.count
        return Double(elements) / 3.0
    }
}

struct QualityRow: View {
    let title: String
    let score: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            Text("\(Int(score * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(scoreColor)
            ProgressView(value: score)
                .progressViewStyle(LinearProgressViewStyle(tint: scoreColor))
                .frame(width: 60)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        case 0.4..<0.6: return .yellow
        default: return .red
        }
    }
}

// MARK: - Utility Extensions
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4) * 17, int * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension String {
    var localizedCapitalized: String {
        return self.capitalized
    }
}