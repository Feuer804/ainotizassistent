//
//  SummaryPreviewView.swift
//  Intelligente Notizen App - Visual Feedback für Zusammenfassungen
//

import SwiftUI
import Combine

struct SummaryPreviewView: View {
    @ObservedObject var summaryGenerator: SummaryGenerator
    @State private var selectedFormat: SummaryFormat = .medium
    @State private var selectedContentType: ContentType = .note
    @State private var showOptions = false
    @State private var inputText: String = ""
    @State private var isShowingPreview = false
    @State private var showShareSheet = false
    @State private var showHistory = false
    
    // Animation states
    @State private var animationOffset: CGFloat = 20
    @State private var animationOpacity: Double = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header mit Format-Auswahl
                formatSelectionHeader
                
                // Content-Type Auswahl
                contentTypeSelection
                
                // Input Bereich
                inputSection
                
                // Generieren Button
                generateButton
                
                // Aktuelle Zusammenfassung oder Loading
                if summaryGenerator.isGenerating {
                    loadingView
                } else if let summary = summaryGenerator.currentSummary {
                    summaryView(summary: summary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Zusammenfassung Generator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    menuButton
                }
            }
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .sheet(isPresented: $showHistory) {
                SummaryHistoryView(summaryGenerator: summaryGenerator)
            }
            .sheet(isPresented: $showShareSheet) {
                if let summary = summaryGenerator.currentSummary {
                    ShareSheetView(summary: summary)
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: summaryGenerator.currentSummary)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Format Selection Header
    private var formatSelectionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ausgabeformat")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Optionen") {
                    withAnimation(.spring()) {
                        showOptions.toggle()
                    }
                }
                .foregroundColor(.blue)
            }
            
            Picker("Format", selection: $selectedFormat) {
                ForEach(SummaryFormat.allCases, id: \.self) { format in
                    HStack {
                        Text(format.rawValue)
                        Text(format.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(format)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if showOptions {
                formatOptionsView
                    .transition(.slide.combined(with: .opacity))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Format Options
    private var formatOptionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Format-Einstellungen")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text("Wortanzahl:")
                Spacer()
                Text("\(selectedFormat.defaultLength.wordCount.lowerBound)-\(selectedFormat.defaultLength.wordCount.upperBound)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Bullet Points:")
                Spacer()
                Text("\(selectedFormat.bulletPointCount)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Themen:")
                Spacer()
                Text("\(selectedFormat.topicCount)")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Content Type Selection
    private var contentTypeSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content-Typ")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(ContentType.allCases, id: \.self) { type in
                    ContentTypeCard(
                        contentType: type,
                        isSelected: selectedContentType == type
                    ) {
                        withAnimation(.spring(response: 0.4)) {
                            selectedContentType = type
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var gridColumns: [GridItem] {
        return [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Text eingeben")
                .font(.headline)
                .fontWeight(.semibold)
            
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("Geben Sie hier den Text ein, der zusammengefasst werden soll...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                        .padding(.leading, 16)
                }
                
                TextEditor(text: $inputText)
                    .frame(minHeight: 120)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.blue.opacity(0.2), lineWidth: 1)
                    )
                    .font(.body)
            }
            
            // Character counter
            HStack {
                Spacer()
                Text("\(inputText.count) Zeichen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: generateSummary) {
            HStack {
                if summaryGenerator.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                }
                
                Text(summaryGenerator.isGenerating ? "Wird generiert..." : "Zusammenfassung generieren")
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
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(inputText.isEmpty || summaryGenerator.isGenerating)
        .opacity(inputText.isEmpty ? 0.5 : 1.0)
        .scaleEffect(inputText.isEmpty ? 0.95 : 1.0)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: summaryGenerator.generationProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(y: 2)
            
            Text(summaryGenerator.currentGenerationStep)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("\(Int(summaryGenerator.generationProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Summary View
    private func summaryView(summary: GeneratedSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary Header
                summaryHeader(summary: summary)
                
                // Main Summary Text
                summaryTextView(summary: summary)
                
                // Bullet Points
                if !summary.bulletPoints.isEmpty {
                    bulletPointsView(points: summary.bulletPoints)
                }
                
                // Key Phrases
                if !summary.keyPhrases.isEmpty {
                    keyPhrasesView(phrases: summary.keyPhrases)
                }
                
                // Highlights
                if !summary.highlights.isEmpty {
                    highlightsView(highlights: summary.highlights)
                }
                
                // Metadata
                if !summary.metadata.isEmpty {
                    metadataView(metadata: summary.metadata)
                }
                
                // Quality Indicators
                qualityIndicatorsView(summary: summary)
                
                // Action Buttons
                actionButtonsView
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .transition(.slide.combined(with: .opacity))
    }
    
    // MARK: - Summary Header
    private func summaryHeader(summary: GeneratedSummary) -> some View {
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
            
            // Quality Badge
            VStack {
                Text(summary.qualityLevel)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: qualityGradient(for: summary.confidence.overallScore),
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
    }
    
    private func qualityGradient(for score: Double) -> [Color] {
        switch score {
        case 0.8...1.0:
            return [.green, .blue]
        case 0.6..<0.8:
            return [.orange, .yellow]
        case 0.4..<0.6:
            return [.red, .orange]
        default:
            return [.red, .gray]
        }
    }
    
    // MARK: - Summary Text
    private func summaryTextView(summary: GeneratedSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zusammenfassung")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(summary.summaryText)
                .font(.body)
                .lineSpacing(4)
                .padding()
                .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            
            // Reading stats
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text("\(Int(summary.readingTime / 60)) min Lesezeit")
                Spacer()
                Text("\(summary.wordCount) Wörter")
                Image(systemName: "textformat")
                    .font(.caption)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Bullet Points
    private func bulletPointsView(points: [BulletPoint]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wichtige Punkte")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(points.indices, id: \.self) { index in
                let point = points[index]
                HStack {
                    priorityIcon(for: point.priority)
                        .foregroundColor(priorityColor(for: point.priority))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(point.text)
                            .font(.body)
                            .fontWeight(point.priority == .critical || point.priority == .high ? .semibold : .regular)
                        
                        HStack {
                            Text(point.category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if point.actionRequired {
                                Text("Aktion erforderlich")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
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
    
    private func priorityIcon(for priority: BulletPoint.Priority) -> some View {
        Group {
            switch priority {
            case .critical:
                Image(systemName: "exclamationmark.triangle.fill")
            case .high:
                Image(systemName: "exclamationmark.circle.fill")
            case .medium:
                Image(systemName: "info.circle.fill")
            case .low:
                Image(systemName: "circle")
            }
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
    
    // MARK: - Key Phrases
    private func keyPhrasesView(phrases: [KeyPhrase]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schlüsselphrasen")
                .font(.headline)
                .fontWeight(.semibold)
            
            FlowLayout(items: phrases) { phrase in
                PhraseChip(phrase: phrase)
            }
        }
    }
    
    // MARK: - Highlights
    private func highlightsView(highlights: [SummaryHighlight]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(highlights) { highlight in
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading) {
                        Text(highlight.text)
                            .font(.body)
                        Text(highlight.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(highlight.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Metadata
    private func metadataView(metadata: [String: AnyCodable]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadaten")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack {
                    Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(value)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
            }
        }
    }
    
    // MARK: - Quality Indicators
    private func qualityIndicatorsView(summary: GeneratedSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Qualitätsindikatoren")
                .font(.headline)
                .fontWeight(.semibold)
            
            qualityMetricRow(title: "Kohärenz", score: summary.confidence.coherenceScore)
            qualityMetricRow(title: "Vollständigkeit", score: summary.confidence.completenessScore)
            qualityMetricRow(title: "Genauigkeit", score: summary.confidence.accuracyScore)
            qualityMetricRow(title: "Sprachqualität", score: summary.confidence.languageQualityScore)
            
            if !summary.confidence.improvements.isEmpty {
                Text("Verbesserungsvorschläge")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 8)
                
                ForEach(summary.confidence.improvements, id: \.category) { improvement in
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading) {
                            Text(improvement.category)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(improvement.suggestion)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(improvement.impact * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    private func qualityMetricRow(title: String, score: Double) -> some View {
        HStack {
            Text(title)
                .font(.caption)
            Spacer()
            Text("\(Int(score * 100))%")
                .font(.caption)
                .fontWeight(.medium)
        }
        
        ProgressView(value: score)
            .progressViewStyle(LinearProgressViewStyle(tint: score > 0.7 ? .green : score > 0.4 ? .orange : .red))
            .scaleEffect(y: 2)
    }
    
    // MARK: - Action Buttons
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: copySummary) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Kopieren")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            
            Button(action: { showShareSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Teilen")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Menu Button
    private var menuButton: some View {
        Menu {
            Button("Verlauf") {
                showHistory = true
            }
            
            Button("Als Template speichern") {
                saveAsTemplate()
            }
            
            Divider()
            
            Button("Neue Zusammenfassung") {
                resetGenerator()
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
        }
    }
    
    // MARK: - Helper Methods
    private func generateSummary() {
        guard !inputText.isEmpty else { return }
        
        let options = SummaryOptions()
        summaryGenerator.generateSummary(
            from: inputText,
            format: selectedFormat,
            contentType: selectedContentType,
            options: options
        ) { summary in
            // Summary generation completed
        }
    }
    
    private func copySummary() {
        if let summary = summaryGenerator.currentSummary {
            UIPasteboard.general.string = summary.summaryText
            // Show feedback
        }
    }
    
    private func saveAsTemplate() {
        // Save current summary as template
    }
    
    private func resetGenerator() {
        inputText = ""
        summaryGenerator.currentSummary = nil
    }
    
    private func startAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animationOffset = 0
            animationOpacity = 1
        }
    }
}

// MARK: - Supporting Views
struct ContentTypeCard: View {
    let contentType: ContentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(contentType.icon)
                    .font(.title2)
                
                Text(contentType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                isSelected ?
                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(colors: [.white, .gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PhraseChip: View {
    let phrase: KeyPhrase
    
    var body: some View {
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
        .background(categoryColor.opacity(0.2), in: Capsule())
        .overlay(
            Capsule()
                .stroke(categoryColor.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var categoryColor: Color {
        switch phrase.category {
        case .topic: return .blue
        case .action: return .green
        case .entity: return .purple
        case .concept: return .orange
        case .technical: return .red
        case .emotional: return .pink
        }
    }
}

struct FlowLayout<Content: View>: View {
    let items: [KeyPhrase]
    let content: (KeyPhrase) -> Content
    
    init(items: [KeyPhrase], @ViewBuilder content: @escaping (KeyPhrase) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry.size)
        }
        .frame(minHeight: 10)
    }
    
    func generateContent(in size: CGSize) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.phrase) { item in
                content(item)
                    .padding(4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item.phrase == items.last?.phrase {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return -result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if item.phrase == items.last?.phrase {
                            height = 0
                        }
                        return -result
                    })
            }
        }
    }
}

struct SummaryHistoryView: View {
    @ObservedObject var summaryGenerator: SummaryGenerator
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Placeholder for history
                Section("Verlauf") {
                    Text("Keine Verläufe vorhanden")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Verlauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShareSheetView: View {
    let summary: GeneratedSummary
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Share content preview
                Text(summary.summaryText)
                    .font(.body)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Share options
                Button(action: shareText) {
                    HStack {
                        Image(systemName: "text.alignleft")
                        Text("Als Text teilen")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                
                Button(action: sharePDF) {
                    HStack {
                        Image(systemName: "doc.pdf")
                        Text("Als PDF teilen")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
            .padding()
            .navigationTitle("Teilen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareText() {
        UIPasteboard.general.string = summary.summaryText
        // Show feedback
    }
    
    private func sharePDF() {
        // Generate and share PDF
    }
}

// MARK: - Preview
struct SummaryPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let contentAnalyzer = ContentAnalyzer()
        let summaryGenerator = SummaryGenerator(contentAnalyzer: contentAnalyzer)
        
        SummaryPreviewView(summaryGenerator: summaryGenerator)
    }
}