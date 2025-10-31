//
//  PreviewViews.swift
//  AINotizassistent
//
//  Erstellt am 31.10.2025.
//  Copyright © 2025 AI Notizassistent. Alle Rechte vorbehalten.
//

import SwiftUI

// MARK: - Main Preview Container
struct PreviewContainer: View {
    @ObservedObject var previewManager: PreviewManager
    @ObservedObject var exportManager: ExportManager
    @State private var selectedFormat: FormatOption = .markdown
    @State private var showExportOptions = false
    @State private var showFormatPicker = false
    @State private var showTemplatePicker = false
    @State private var isEditingTitle = false
    @State private var tempTitle = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            previewHeader
            
            // Preview Content
            if let preview = previewManager.currentPreview {
                ScrollView {
                    switch preview.type {
                    case .summary:
                        SummaryPreviewView(preview: preview, selectedFormat: $selectedFormat)
                    case .todo:
                        TodoListPreviewView(preview: preview, selectedFormat: $selectedFormat)
                    case .meeting:
                        MeetingRecapPreviewView(preview: preview, selectedFormat: $selectedFormat)
                    case .note:
                        NotePreviewView(preview: preview, selectedFormat: $selectedFormat)
                    }
                }
            } else {
                emptyState
            }
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(exportManager: exportManager, preview: previewManager.currentPreview)
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerView(previewManager: previewManager) { template in
                applyTemplate(template)
            }
        }
    }
    
    // MARK: - Header Components
    private var previewHeader: some View {
        HStack {
            // Title Section
            HStack {
                if isEditingTitle {
                    TextField("Titel eingeben", text: $tempTitle, onCommit: {
                        updateTitle()
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 300)
                } else {
                    Text(previewManager.currentPreview?.title ?? "Kein Dokument")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .onTapGesture {
                            startTitleEdit()
                        }
                }
                
                // Type Badge
                if let type = previewManager.currentPreview?.type {
                    Text(type.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            // Control Buttons
            HStack(spacing: 8) {
                // Template Button
                Button(action: { showTemplatePicker = true }) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Vorlagen")
                
                // Format Picker
                Button(action: { showFormatPicker = true }) {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Format ändern")
                
                // Export Button
                Button(action: { showExportOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Exportieren")
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Kein Vorschau-Dokument")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Wählen Sie eine Vorlage oder erstellen Sie ein neues Dokument")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Neue Vorlage erstellen") {
                showTemplatePicker = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Actions
    private func startTitleEdit() {
        tempTitle = previewManager.currentPreview?.title ?? ""
        isEditingTitle = true
    }
    
    private func updateTitle() {
        guard let preview = previewManager.currentPreview, !tempTitle.isEmpty else {
            isEditingTitle = false
            return
        }
        
        var updatedPreview = preview
        updatedPreview.title = tempTitle
        previewManager.updatePreview(updatedPreview)
        isEditingTitle = false
    }
    
    private func applyTemplate(_ template: PreviewTemplate) {
        let newPreview = previewManager.applyTemplate(template)
        previewManager.currentPreview = newPreview
        selectedFormat = newPreview.format
    }
}

// MARK: - Summary Preview View
struct SummaryPreviewView: View {
    let preview: PreviewData
    @Binding var selectedFormat: FormatOption
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary Header
            summaryHeader
            
            // Key Points Section
            keyPointsSection
            
            // Insights Section
            insightsSection
            
            // Next Steps Section
            nextStepsSection
            
            // Metadata Footer
            metadataFooter
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(preview.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                Text(DateFormatter.localizedString(from: preview.createdAt, dateStyle: .long, timeStyle: .short))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Format Badge
                formatBadge
            }
        }
    }
    
    private var keyPointsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.blue)
                Text("Kernpunkte")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(extractPoints(), id: \.self) { point in
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        
                        Text(point)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.orange)
                Text("Wichtige Erkenntnisse")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(extractInsights(), id: \.self) { insight in
                    HStack {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text(insight)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.right")
                    .foregroundColor(.green)
                Text("Nächste Schritte")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(extractNextSteps(), id: \.self) { step in
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(step)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var metadataFooter: some View {
        HStack {
            Text("Wörter: \(preview.wordCount)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Lesezeit: \(preview.readingTime) Min")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            formatBadge
        }
        .padding(.top, 8)
    }
    
    private var formatBadge: some View {
        Text(selectedFormat.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.gray)
            .clipShape(Capsule())
    }
    
    // MARK: - Content Extraction
    private func extractPoints() -> [String] {
        // Extract bullet points from content
        return preview.content.components(separatedBy: .newlines)
            .filter { $0.hasPrefix("•") || $0.hasPrefix("-") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private func extractInsights() -> [String] {
        // Extract insights from content
        return preview.content.components(separatedBy: .newlines)
            .filter { $0.localizedCaseInsensitiveContains("erkenntnis") || $0.localizedCaseInsensitiveContains("observation") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private func extractNextSteps() -> [String] {
        // Extract next steps from content
        return preview.content.components(separatedBy: .newlines)
            .filter { $0.localizedCaseInsensitiveContains("schritt") || $0.localizedCaseInsensitiveContains("todo") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

// MARK: - Todo List Preview View
struct TodoListPreviewView: View {
    let preview: PreviewData
    @Binding var selectedFormat: FormatOption
    @State private var completedTasks: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Todo Header
            todoHeader
            
            // Priority Sections
            prioritySections
            
            // Progress Indicator
            progressIndicator
            
            // Metadata Footer
            metadataFooter
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var todoHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(preview.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.blue)
            }
            
            Text("Aufgabenliste")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var prioritySections: some View {
        VStack(alignment: .leading, spacing: 20) {
            // High Priority
            prioritySection(
                title: "🔴 Hohe Priorität",
                color: .red,
                tasks: extractHighPriorityTasks()
            )
            
            // Medium Priority
            prioritySection(
                title: "🟡 Mittlere Priorität",
                color: .orange,
                tasks: extractMediumPriorityTasks()
            )
            
            // Low Priority
            prioritySection(
                title: "🟢 Niedrige Priorität",
                color: .green,
                tasks: extractLowPriorityTasks()
            )
            
            // General Tasks
            prioritySection(
                title: "📋 Generelle Aufgaben",
                color: .blue,
                tasks: extractGeneralTasks()
            )
        }
    }
    
    private func prioritySection(title: String, color: Color, tasks: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            if tasks.isEmpty {
                Text("Keine Aufgaben")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(tasks, id: \.self) { task in
                    taskRow(task: task, color: color)
                }
            }
        }
    }
    
    private func taskRow(task: String, color: Color) -> some View {
        let taskId = "\(task)-\(color.hashValue)"
        let isCompleted = completedTasks.contains(taskId)
        
        return HStack {
            Button(action: {
                toggleTask(taskId)
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : color)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(task)
                .strikethrough(isCompleted)
                .foregroundColor(isCompleted ? .secondary : .primary)
                .font(.body)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    private var progressIndicator: some View {
        let totalTasks = extractAllTasks().count
        let completedCount = completedTasks.count
        let progress = totalTasks > 0 ? Double(completedCount) / Double(totalTasks) : 0
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Fortschritt")
                    .font(.headline)
                
                Spacer()
                
                Text("\(completedCount)/\(totalTasks)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            Text("\(Int(progress * 100))% abgeschlossen")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var metadataFooter: some View {
        HStack {
            Text("Gesamt: \(preview.wordCount) Wörter")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            formatBadge
        }
        .padding(.top, 8)
    }
    
    private var formatBadge: some View {
        Text(selectedFormat.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.gray)
            .clipShape(Capsule())
    }
    
    // MARK: - Task Extraction
    private func extractHighPriorityTasks() -> [String] {
        return extractAllTasks().filter { $0.localizedCaseInsensitiveContains("hoch") || $0.localizedCaseInsensitiveContains("kritisch") }
    }
    
    private func extractMediumPriorityTasks() -> [String] {
        return extractAllTasks().filter { $0.localizedCaseInsensitiveContains("mittel") || $0.localizedCaseInsensitiveContains("normal") }
    }
    
    private func extractLowPriorityTasks() -> [String] {
        return extractAllTasks().filter { $0.localizedCaseInsensitiveContains("niedrig") || $0.localizedCaseInsensitiveContains("später") }
    }
    
    private func extractGeneralTasks() -> [String] {
        let allTasks = extractAllTasks()
        return allTasks.filter { task in
            !extractHighPriorityTasks().contains(task) &&
            !extractMediumPriorityTasks().contains(task) &&
            !extractLowPriorityTasks().contains(task)
        }
    }
    
    private func extractAllTasks() -> [String] {
        return preview.content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty && ($0.hasPrefix("-") || $0.hasPrefix("•") || $0.hasPrefix("*")) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private func toggleTask(_ taskId: String) {
        if completedTasks.contains(taskId) {
            completedTasks.remove(taskId)
        } else {
            completedTasks.insert(taskId)
        }
    }
}

// MARK: - Meeting Recap Preview View
struct MeetingRecapPreviewView: View {
    let preview: PreviewData
    @Binding var selectedFormat: FormatOption
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Meeting Header
            meetingHeader
            
            // Meeting Timeline
            meetingTimeline
            
            // Action Items Section
            actionItemsSection
            
            // Next Meeting Section
            nextMeetingSection
            
            // Metadata Footer
            metadataFooter
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var meetingHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(preview.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "person.2")
                    .foregroundColor(.blue)
            }
            
            // Meeting metadata
            meetingMetadata
        }
    }
    
    private var meetingMetadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Extract metadata from content
            let metadata = extractMeetingMetadata()
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                Text("Datum: \(metadata["date"] ?? "Nicht angegeben")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "person.3")
                    .font(.caption)
                Text("Teilnehmer: \(metadata["participants"] ?? "Nicht angegeben")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text("Dauer: \(metadata["duration"] ?? "Nicht angegeben")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var meetingTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "timeline")
                    .foregroundColor(.blue)
                Text("Meeting-Timeline")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(extractAgendaItems(), id: \.self) { item in
                    timelineRow(time: extractTime(from: item), content: item)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func timelineRow(time: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 30)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(time)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
    
    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                Text("Aktionspunkte")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(extractActionItems(), id: \.self) { item in
                    HStack {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(item)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var nextMeetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.orange)
                Text("Nächstes Meeting")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            Text(extractNextMeeting())
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var metadataFooter: some View {
        HStack {
            Text("Protokoll: \(preview.wordCount) Wörter")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            formatBadge
        }
        .padding(.top, 8)
    }
    
    private var formatBadge: some View {
        Text(selectedFormat.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.gray)
            .clipShape(Capsule())
    }
    
    // MARK: - Content Extraction
    private func extractMeetingMetadata() -> [String: String] {
        var metadata: [String: String] = [:]
        let lines = preview.content.components(separatedBy: .newlines)
        
        for line in lines {
            if line.localizedCaseInsensitiveContains("datum") {
                metadata["date"] = extractValue(from: line)
            } else if line.localizedCaseInsensitiveContains("teilnehmer") {
                metadata["participants"] = extractValue(from: line)
            } else if line.localizedCaseInsensitiveContains("dauer") {
                metadata["duration"] = extractValue(from: line)
            }
        }
        
        return metadata
    }
    
    private func extractAgendaItems() -> [String] {
        return preview.content.components(separatedBy: .newlines)
            .filter { $0.localizedCaseInsensitiveContains("agenda") || $0.localizedCaseInsensitiveContains("tagesordnung") }
    }
    
    private func extractActionItems() -> [String] {
        return preview.content.components(separatedBy: .newlines)
            .filter { $0.localizedCaseInsensitiveContains("aktion") || $0.localizedCaseInsensitiveContains("action") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private func extractNextMeeting() -> String {
        let lines = preview.content.components(separatedBy: .newlines)
        for line in lines {
            if line.localizedCaseInsensitiveContains("nächst") || line.localizedCaseInsensitiveContains("next meeting") {
                return extractValue(from: line)
            }
        }
        return "Noch nicht geplant"
    }
    
    private func extractTime(from item: String) -> String {
        // Extract time from agenda item
        let timePattern = "\\d{1,2}:\\d{2}"
        if let range = item.range(of: timePattern, options: .regularExpression) {
            return String(item[range])
        }
        return "N/A"
    }
    
    private func extractValue(from line: String) -> String {
        // Extract value after colon or dash
        let components = line.components(separatedBy: ":")
        if components.count > 1 {
            return components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let dashComponents = line.components(separatedBy: "-")
        if dashComponents.count > 1 {
            return dashComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return line
    }
}

// MARK: - Note Preview View
struct NotePreviewView: View {
    let preview: PreviewData
    @Binding var selectedFormat: FormatOption
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Note Header
            noteHeader
            
            // Note Content
            noteContent
            
            // Tags Section
            tagsSection
            
            // Metadata Footer
            metadataFooter
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var noteHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(preview.title)
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: "note.text")
                    .font(.caption)
                Text("Notiz")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                formatBadge
            }
        }
    }
    
    private var noteContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inhalt")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(preview.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.purple)
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(.purple)
            }
            
            if preview.tags.isEmpty {
                Text("Keine Tags")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(preview.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    private var metadataFooter: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Erstellt: \(DateFormatter.localizedString(from: preview.createdAt, dateStyle: .medium, timeStyle: .short))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Geändert: \(DateFormatter.localizedString(from: preview.modifiedAt, dateStyle: .medium, timeStyle: .short))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(preview.wordCount) Wörter")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(preview.readingTime) Min Lesezeit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }
    
    private var formatBadge: some View {
        Text(selectedFormat.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.gray)
            .clipShape(Capsule())
    }
}

// MARK: - Export Options View
struct ExportOptionsView: View {
    @ObservedObject var exportManager: ExportManager
    let preview: PreviewData?
    
    @State private var selectedExportType: ExportType = .pdf
    @State private var exportConfig = ExportConfiguration()
    @State private var showProgress = false
    @State private var exportResult: ExportResult?
    
    var body: some View {
        NavigationView {
            VStack {
                if showProgress {
                    exportProgressView
                } else {
                    exportOptionsList
                }
            }
            .navigationTitle("Export-Optionen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        // Dismiss
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        performExport()
                    }
                    .disabled(preview == nil || showProgress)
                }
            }
        }
    }
    
    private var exportOptionsList: some View {
        List {
            Section("Export-Format") {
                ForEach(ExportType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: exportIcon(for: type))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(type.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text(exportDescription(for: type))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedExportType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedExportType = type
                    }
                }
            }
            
            Section("Export-Konfiguration") {
                Toggle("Metadaten einschließen", isOn: $exportConfig.includeMetadata)
                Toggle("Zeitstempel einschließen", isOn: $exportConfig.includeTimestamp)
                Toggle("Tags einschließen", isOn: $exportConfig.includeTags)
                Toggle("Inhaltsverzeichnis", isOn: $exportConfig.includeTableOfContents)
                
                HStack {
                    Text("Schriftgröße")
                    Spacer()
                    Text("\(Int(exportConfig.fontSize))pt")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $exportConfig.fontSize, in: 8...20, step: 1)
                
                if !exportConfig.customFooter.isEmpty {
                    HStack {
                        Text("Footer:")
                        TextField("Benutzerdefinierter Footer", text: $exportConfig.customFooter)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var exportProgressView: some View {
        VStack(spacing: 20) {
            if exportManager.isExporting {
                ProgressView(value: exportManager.exportProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(1.5)
                
                Text("Export läuft...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else if let result = exportResult {
                VStack(spacing: 16) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(result.success ? .green : .red)
                    
                    Text(result.message)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    if result.success, let url = result.url {
                        Button("Datei öffnen") {
                            openFile(at: url)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func performExport() {
        guard let preview = preview else { return }
        
        showProgress = true
        exportManager.isExporting = true
        
        Task {
            let result: ExportResult
            
            switch selectedExportType {
            case .pdf:
                result = await exportManager.exportToPDF(preview: preview, config: exportConfig)
            case .word:
                result = await exportManager.exportToWord(preview: preview)
            case .notes:
                result = await exportManager.exportToNotes(preview: preview)
            case .email:
                let success = exportManager.createEmailDraft(preview: preview)
                result = ExportResult(success: success, message: success ? "E-Mail Entwurf erstellt" : "Fehler beim Erstellen des E-Mail Entwurfs")
            case .calendar:
                let defaultDate = Date().addingTimeInterval(3600)
                result = await exportManager.exportToCalendar(preview: preview, date: defaultDate)
            case .taskManagement:
                result = await exportManager.exportToTaskManager(preview: preview, service: .reminders)
            case .airdrop:
                let success = exportManager.shareViaAirdrop(preview: preview)
                result = ExportResult(success: success, message: success ? "AirDrop gestartet" : "AirDrop fehlgeschlagen")
            case .messages:
                let success = exportManager.shareViaMessages(preview: preview)
                result = ExportResult(success: success, message: success ? "Nachricht geöffnet" : "Fehler beim Öffnen der Nachricht")
            case .file:
                result = await exportManager.exportMarkdown(preview)
            }
            
            await MainActor.run {
                exportResult = result
                exportManager.isExporting = false
            }
        }
    }
    
    private func exportIcon(for type: ExportType) -> String {
        switch type {
        case .pdf: return "doc.richtext"
        case .word: return "doc.text"
        case .notes: return "note.text"
        case .email: return "envelope"
        case .calendar: return "calendar"
        case .taskManagement: return "checkmark.circle"
        case .airdrop: return "airplane"
        case .messages: return "message"
        case .file: return "square.and.arrow.up"
        }
    }
    
    private func exportDescription(for type: ExportType) -> String {
        return exportManager.getAccessibilityDescription(for: type)
    }
    
    private func openFile(at url: URL) {
        // Open file in appropriate app
        print("Opening file: \(url)")
    }
}

// MARK: - Template Picker View
struct TemplatePickerView: View {
    @ObservedObject var previewManager: PreviewManager
    var onTemplateSelected: (PreviewTemplate) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: PreviewTemplate?
    
    var body: some View {
        NavigationView {
            List {
                Section("Verfügbare Vorlagen") {
                    ForEach(previewManager.templates) { template in
                        templateRow(template)
                    }
                }
                
                Section("Benutzerdefinierte Vorlagen") {
                    if let customTemplates = getCustomTemplates(), !customTemplates.isEmpty {
                        ForEach(customTemplates) { template in
                            templateRow(template)
                        }
                    } else {
                        Text("Keine benutzerdefinierten Vorlagen")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Vorlage wählen")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Verwenden") {
                        if let template = selectedTemplate {
                            onTemplateSelected(template)
                            dismiss()
                        }
                    }
                    .disabled(selectedTemplate == nil)
                }
            }
        }
    }
    
    private func templateRow(_ template: PreviewTemplate) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(template.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if template.isDefault {
                        Text("Standard")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
                
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(template.type.rawValue) • \(template.format.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if selectedTemplate?.id == template.id {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTemplate = template
        }
    }
    
    private func getCustomTemplates() -> [PreviewTemplate]? {
        // Return custom templates (this would be from a separate storage)
        return previewManager.templates.filter { !$0.isDefault }
    }
}

// MARK: - FlowLayout Helper
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    init(spacing: CGFloat, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
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
            ForEach(Array(data), id: \.self) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading) { d in
                        if width + d.width > size.width {
                            width = 0
                            height -= d.height + spacing
                        }
                        let result = width
                        width += d.width + spacing
                        return -result
                    }
                    .alignmentGuide(.top) { d in
                        let result = height
                        if let lastItem = data.last, lastItem == item {
                            height = 0
                        }
                        return -result
                    }
            }
        }
    }
}