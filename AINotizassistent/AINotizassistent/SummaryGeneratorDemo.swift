//
//  SummaryGeneratorDemo.swift
//  Intelligente Notizen App - Demo Implementation
//

import SwiftUI
import Combine

struct SummaryGeneratorDemo: View {
    @StateObject private var contentAnalyzer = ContentAnalyzer()
    @StateObject private var summaryGenerator: SummaryGenerator
    @State private var inputText: String = ""
    @State private var selectedFormat: SummaryFormat = .medium
    @State private var selectedContentType: ContentType = .note
    @State private var showingComparison = false
    @State private var showingExportOptions = false
    
    // Demo data
    private let demoTexts = [
        "E-Mail: Hallo Team,\n\nwir haben gestern das Projekt Meeting besprochen und folgende Entscheidungen getroffen:\n\n1. Der Launch wird um zwei Wochen verschoben\n2. Neue UI Design Reviews sind erforderlich\n3. Developer Documentation muss aktualisiert werden\n\nAction Items:\n- Maria: UI Mockups bis Freitag\n- John: API Documentation überarbeiten\n- Team: Bug Testing am Montag\n\nBitte bestätigen Sie die neuen Deadlines.\n\nVielen Dank,\nSarah",
        
        "Meeting Notes: Projekt Alpha Status Meeting\nDatum: 31.10.2025\nTeilnehmer: 5 Personen\n\nAgenda:\n1. Sprint Review\n2. Planung Q4\n3. Ressourcen-Allocation\n\nEntscheidungen:\n- Budget um 15% erhöht für Marketing\n- Neue Developer werden im November eingestellt\n- Beta Launch verschoben auf Dezember\n\nNächste Schritte:\n- Marketing Team präsentiert neue Strategie\n- HR startet Recruiting Prozess\n- Tech Lead erstellt detaillierten Projektplan",
        
        "Artikel: Die Zukunft der Künstlichen Intelligenz\nAutor: Dr. Max Mueller\nQuelle: Tech Magazine\n\nDie Entwicklung der künstlichen Intelligenz hat in den letzten Jahren exponentiell zugenommen. Maschinelles Lernen, neuronale Netzwerke und Deep Learning sind die Schlüsseltechnologien dieser Revolution.\n\nHauptthemen:\n1. Automatisierung in der Industrie\n2. Verbesserung der Spracherkennung\n3. Computer Vision Durchbrüche\n4. Ethik in der AI Entwicklung\n\nDie Gesellschaft steht vor großen Veränderungen durch AI. Arbeitsplätze werden sich wandeln, aber neue Möglichkeiten entstehen. Wichtig ist eine verantwortungsvolle Entwicklung und Implementierung.\n\nFazit: AI wird unser Leben grundlegend verändern, aber mit richtiger Planung können wir diese Technologie zum Wohl aller nutzen."
    ]
    
    private let contentTypes: [(String, ContentType)] = [
        ("E-Mail", .email),
        ("Meeting", .meeting),
        ("Artikel", .article)
    ]
    
    init() {
        _summaryGenerator = StateObject(wrappedValue: SummaryGenerator(contentAnalyzer: contentAnalyzer))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Demo Header
                    demoHeader
                    
                    // Input Section
                    inputSection
                    
                    // Format Selection
                    formatSelection
                    
                    // Content Type Selection
                    contentTypeSelection
                    
                    // Demo Buttons
                    demoButtons
                    
                    // Results
                    if let summary = summaryGenerator.currentSummary {
                        summaryResultView(summary: summary)
                    } else if summaryGenerator.isGenerating {
                        loadingIndicator
                    }
                }
                .padding()
            }
            .navigationTitle("Summary Generator Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Optionen") {
                        Button("Vergleiche Formate") {
                            showingComparison = true
                        }
                        Button("Export") {
                            showingExportOptions = true
                        }
                        Button("Neue Demo") {
                            loadRandomDemo()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingComparison) {
                formatComparisonView
            }
            .sheet(isPresented: $showingExportOptions) {
                exportOptionsView
            }
        }
        .onAppear {
            loadRandomDemo()
        }
    }
    
    // MARK: - Demo Header
    private var demoHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Summary Generator Demo")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Testen Sie die intelligente Zusammenfassungs-Generation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("""
            Diese Demo zeigt die Funktionen des Summary Generators:
            • Content-Type-spezifische Verarbeitung
            • Verschiedene Ausgabeformate
            • Multi-level Summarization
            • Confidence Scoring
            • Export-Optionen
            """)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Demo Text")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Zufällige Demo") {
                    loadRandomDemo()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("Wählen Sie eine Demo aus oder geben Sie eigenen Text ein...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                        .padding(.leading, 16)
                }
                
                TextEditor(text: $inputText)
                    .frame(minHeight: 200)
                    .font(.body)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Format Selection
    private var formatSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ausgabeformat")
                .font(.headline)
                .fontWeight(.semibold)
            
            Picker("Format", selection: $selectedFormat) {
                ForEach(SummaryFormat.allCases, id: \.self) { format in
                    VStack(alignment: .leading) {
                        Text(format.rawValue)
                            .font(.body)
                            .fontWeight(.medium)
                        Text(format.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(format)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Content Type Selection
    private var contentTypeSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content-Typ")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ForEach(contentTypes, id: \.1) { name, type in
                    Button(action: { selectedContentType = type }) {
                        HStack {
                            Text(type.icon)
                                .font(.title3)
                            VStack(alignment: .leading) {
                                Text(name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(type.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(
                            selectedContentType == type ?
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.white, .gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundColor(selectedContentType == type ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedContentType == type ? .blue : .gray.opacity(0.3), lineWidth: selectedContentType == type ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Demo Buttons
    private var demoButtons: some View {
        VStack(spacing: 12) {
            Button(action: generateSummary) {
                HStack {
                    if summaryGenerator.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "brain.head.profile")
                    }
                    Text(summaryGenerator.isGenerating ? "Generiere..." : "Zusammenfassung generieren")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .disabled(inputText.isEmpty || summaryGenerator.isGenerating)
            .opacity(inputText.isEmpty ? 0.5 : 1.0)
            
            HStack(spacing: 12) {
                Button("Kurze Demo") {
                    generateQuickDemo()
                }
                .padding()
                .background(.orange.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(Capsule())
                
                Button("Vollständige Analyse") {
                    generateDetailedDemo()
                }
                .padding()
                .background(.green.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Loading Indicator
    private var loadingIndicator: some View {
        VStack(spacing: 20) {
            ProgressView(value: summaryGenerator.generationProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(y: 3)
            
            Text(summaryGenerator.currentGenerationStep)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(Int(summaryGenerator.generationProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Summary Result View
    private func summaryResultView(summary: GeneratedSummary) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with quality indicator
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(summary.format.rawValue)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                        
                        Text(summary.contentType.rawValue)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Text("Generierte Zusammenfassung")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack {
                    Text(summary.qualityLevel)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: summary.confidence.overallScore > 0.7 ? [.green, .blue] : [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    
                    Text("\(Int(summary.confidence.overallScore * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Summary Text
            VStack(alignment: .leading, spacing: 8) {
                Text("Zusammenfassung")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(summary.summaryText)
                    .font(.body)
                    .lineSpacing(4)
                    .padding()
                    .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                
                // Statistics
                HStack {
                    Label("\(summary.wordCount) Wörter", systemImage: "textformat")
                    Spacer()
                    Label("\(Int(summary.readingTime / 60)) min", systemImage: "clock")
                    Spacer()
                    Label("\(summary.bulletPoints.count) Punkte", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Bullet Points
            if !summary.bulletPoints.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Wichtige Punkte")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(summary.bulletPoints.prefix(5), id: \.text) { point in
                        HStack {
                            Image(systemName: priorityIcon(for: point.priority))
                                .foregroundColor(priorityColor(for: point.priority))
                            
                            VStack(alignment: .leading) {
                                Text(point.text)
                                    .font(.body)
                                HStack {
                                    Text(point.category)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if point.actionRequired {
                                        Text("Aktion")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(.orange.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(Int(point.confidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(priorityColor(for: point.priority).opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            
            // Key Phrases
            if !summary.keyPhrases.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Schlüsselphrasen")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    FlowLayout(items: Array(summary.keyPhrases.prefix(8))) { phrase in
                        HStack(spacing: 4) {
                            Text(phrase.phrase)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("\(Int(phrase.confidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor(for: phrase.category).opacity(0.2), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(categoryColor(for: phrase.category).opacity(0.5), lineWidth: 1)
                        )
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Als Text kopieren") {
                    copyToClipboard(summary.summaryText)
                }
                .padding()
                .background(.blue.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(Capsule())
                
                Button("Als Markdown") {
                    exportAsMarkdown(summary)
                }
                .padding()
                .background(.green.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .transition(.slide.combined(with: .opacity))
    }
    
    // MARK: - Comparison View
    private var formatComparisonView: some View {
        NavigationView {
            if let summary = summaryGenerator.currentSummary {
                VStack {
                    Text("Format-Vergleich")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(SummaryFormat.allCases, id: \.self) { format in
                                FormatComparisonCard(
                                    format: format,
                                    summary: summary,
                                    summaryGenerator: summaryGenerator
                                )
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Format-Vergleich")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fertig") {
                            showingComparison = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Export Options View
    private var exportOptionsView: some View {
        NavigationView {
            if let summary = summaryGenerator.currentSummary {
                List {
                    Section("Text-Export") {
                        Button("Als Text kopieren") {
                            copyToClipboard(summary.summaryText)
                        }
                        
                        Button("Als Markdown exportieren") {
                            exportAsMarkdown(summary)
                        }
                        
                        Button("Als JSON exportieren") {
                            exportAsJSON(summary)
                        }
                    }
                    
                    Section("Analyse-Export") {
                        Button("Qualitätsbericht") {
                            exportQualityReport(summary)
                        }
                        
                        Button("Vollständige Statistiken") {
                            exportStatistics(summary)
                        }
                    }
                }
                .navigationTitle("Export-Optionen")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Schließen") {
                            showingExportOptions = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadRandomDemo() {
        let randomIndex = Int.random(in: 0..<demoTexts.count)
        inputText = demoTexts[randomIndex]
        
        // Set content type based on demo
        selectedContentType = contentTypes[randomIndex].1
        selectedFormat = .medium
    }
    
    private func generateSummary() {
        summaryGenerator.generateSummary(
            from: inputText,
            format: selectedFormat,
            contentType: selectedContentType
        ) { summary in
            // Summary generated
        }
    }
    
    private func generateQuickDemo() {
        summaryGenerator.generateQuickSummary(from: inputText) { quickSummary in
            inputText = quickSummary
        }
    }
    
    private func generateDetailedDemo() {
        let preferences = UserSummaryPreferences.academic
        summaryGenerator.generateSmartSummary(
            from: inputText,
            preferences: preferences
        ) { summary in
            // Detailed summary generated
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        // Show feedback
    }
    
    private func exportAsMarkdown(_ summary: GeneratedSummary) {
        let markdown = summary.markdownExport
        copyToClipboard(markdown)
    }
    
    private func exportAsJSON(_ summary: GeneratedSummary) {
        let json = try? JSONSerialization.data(withJSONObject: summary.jsonExport, options: .prettyPrinted)
        if let jsonData = json, let jsonString = String(data: jsonData, encoding: .utf8) {
            copyToClipboard(jsonString)
        }
    }
    
    private func exportQualityReport(_ summary: GeneratedSummary) {
        let report = """
        Qualitätsbericht - \(summary.format.rawValue)
        
        Gesamtqualität: \(summary.qualityLevel) (\(Int(summary.confidence.overallScore * 100))%)
        Kohärenz: \(Int(summary.confidence.coherenceScore * 100))%
        Vollständigkeit: \(Int(summary.confidence.completenessScore * 100))%
        Genauigkeit: \(Int(summary.confidence.accuracyScore * 100))%
        Sprachqualität: \(Int(summary.confidence.languageQualityScore * 100))%
        
        Statistiken:
        - Wortanzahl: \(summary.wordCount)
        - Lesezeit: \(Int(summary.readingTime / 60)) Minuten
        - Bullet Points: \(summary.bulletPoints.count)
        - Schlüsselphrasen: \(summary.keyPhrases.count)
        
        Verarbeitungszeit: \(String(format: "%.2f", summary.processingTime)) Sekunden
        """
        copyToClipboard(report)
    }
    
    private func exportStatistics(_ summary: GeneratedSummary) {
        let stats = summary.summaryStatistics
        let report = """
        Vollständige Statistiken
        
        Komplexität: \(String(format: "%.2f", stats.complexityScore))
        Informationsdichte: \(String(format: "%.2f", stats.informationDensity))
        Keyword-Abdeckung: \(String(format: "%.2f", stats.keywordCoverage))
        Lesbarkeit: \(stats.readabilityLevel)
        AI-Tauglichkeit: \(String(format: "%.2f", stats.suitabilityForAI))
        Gesamt-Score: \(String(format: "%.2f", stats.overallScore))
        """
        copyToClipboard(report)
    }
    
    private func priorityIcon(for priority: BulletPoint.Priority) -> String {
        switch priority {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "circle"
        }
    }
    
    private func priorityColor(for priority: BulletPoint.Priority) -> Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
    
    private func categoryColor(for category: KeyPhrase.KeyPhraseCategory) -> Color {
        switch category {
        case .topic: return .blue
        case .action: return .green
        case .entity: return .purple
        case .concept: return .orange
        case .technical: return .red
        case .emotional: return .pink
        }
    }
}

// MARK: - Format Comparison Card
struct FormatComparisonCard: View {
    let format: SummaryFormat
    let summary: GeneratedSummary
    @ObservedObject var summaryGenerator: SummaryGenerator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(format.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(format.bulletPointCount) Punkte")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(format.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Generieren") {
                summaryGenerator.generateSummary(
                    from: summary.originalText,
                    format: format,
                    contentType: summary.contentType
                ) { newSummary in
                    // Update with new format
                }
            }
            .font(.caption)
            .padding()
            .background(.blue.opacity(0.1))
            .foregroundColor(.blue)
            .clipShape(Capsule())
        }
        .padding()
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Demo Preview
struct SummaryGeneratorDemo_Previews: PreviewProvider {
    static var previews: some View {
        SummaryGeneratorDemo()
    }
}