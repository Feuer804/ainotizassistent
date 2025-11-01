//
//  AutoSaveStatusView.swift
//  AINotizassistent
//
//  UI Component für Auto-Save Status Anzeige und Controls
//

import SwiftUI
import os.log

struct AutoSaveStatusView: View {
    @StateObject private var autoSaveManager = AutoSaveManager.shared
    @StateObject private var storageManager = StorageManager.shared
    @StateObject private var preferences = StoragePreferences.shared
    @State private var showDetailedStatus = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Status Header
            statusHeader
            
            // Queue Status
            if !autoSaveManager.queue.isEmpty {
                queueStatusView
            }
            
            // Performance Metrics
            if let metrics = getPerformanceMetrics() {
                performanceMetricsView(metrics)
            }
            
            // Quick Actions
            quickActionsView
            
            // Detailed Status (expandable)
            if showDetailedStatus {
                detailedStatusView
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .onAppear {
            observeStatusChanges()
        }
    }
    
    // MARK: - Status Header
    
    private var statusHeader: some View {
        HStack {
            // Auto-Save Status
            HStack(spacing: 8) {
                Image(systemName: autoSaveManager.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(autoSaveManager.isEnabled ? .green : .red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Save")
                        .font(.headline)
                    Text(autoSaveManager.isEnabled ? "Aktiviert" : "Deaktiviert")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Sync Status
            if storageManager.isSyncing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Sync läuft...")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            } else if let lastSync = storageManager.lastSyncDate {
                Text("Zuletzt: \(formatTime(lastSync))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Expand/Collapse Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetailedStatus.toggle()
                }
            }) {
                Image(systemName: showDetailedStatus ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(showDetailedStatus ? 180 : 0))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Queue Status
    
    private var queueStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(.orange)
                Text("Ausstehende Speicherungen")
                Spacer()
                Text("\(autoSaveManager.queue.count)")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            // Priority Breakdown
            HStack(spacing: 12) {
                priorityIndicator(title: "Kritisch", count: getQueueCount(for: .critical), color: .red)
                priorityIndicator(title: "Hoch", count: getQueueCount(for: .high), color: .orange)
                priorityIndicator(title: "Normal", count: getQueueCount(for: .normal), color: .yellow)
                priorityIndicator(title: "Niedrig", count: getQueueCount(for: .low), color: .green)
            }
            
            // Progress Bar
            if autoSaveManager.isProcessingQueue {
                ProgressView("Verarbeite Queue...")
                    .scaleEffect(0.9)
                    .foregroundColor(.blue)
            } else {
                Button(action: {
                    Task {
                        await autoSaveManager.processQueue()
                    }
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Jetzt verarbeiten")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func priorityIndicator(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Performance Metrics
    
    private func performanceMetricsView(_ metrics: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Performance", icon: "speedometer")
            
            HStack {
                MetricView(
                    title: "Avg. Save Time",
                    value: formatDuration(metrics["averageSaveTime"] as? TimeInterval ?? 0),
                    icon: "clock"
                )
                Spacer()
                MetricView(
                    title: "Drafts",
                    value: "\(metrics["draftsCount"] as? Int ?? 0)",
                    icon: "doc.text"
                )
            }
            
            if let lastSaveTime = metrics["lastSaveTime"] as? TimeInterval, lastSaveTime > 0 {
                HStack {
                    Text("Letzte Speicherung")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDuration(lastSaveTime))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private func getPerformanceMetrics() -> [String: Any]? {
        return autoSaveManager.getSaveMetrics()
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Aktionen", icon: "bolt")
            
            HStack(spacing: 8) {
                // Toggle Auto-Save
                Button(action: toggleAutoSave) {
                    Image(systemName: autoSaveManager.isEnabled ? "pause.circle.fill" : "play.circle.fill")
                        .foregroundColor(autoSaveManager.isEnabled ? .orange : .green)
                }
                .buttonStyle(GlassButtonStyle())
                
                // Manual Save All
                Button(action: {
                    Task {
                        await autoSaveManager.forceSaveAll()
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(autoSaveManager.isProcessingQueue)
                
                // Clear Queue
                Button(action: {
                    autoSaveManager.clearQueue()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(autoSaveManager.queue.isEmpty)
                
                // Clear Drafts
                Button(action: {
                    autoSaveManager.clearAllDrafts()
                }) {
                    Image(systemName: "doc.richtext")
                        .foregroundColor(.orange)
                }
                .buttonStyle(GlassButtonStyle())
                
                Spacer()
            }
        }
    }
    
    // MARK: - Detailed Status
    
    private var detailedStatusView: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Detaillierter Status", icon: "info.circle")
            
            // Configuration
            VStack(alignment: .leading, spacing: 6) {
                Text("Konfiguration")
                    .font(.headline)
                
                detailRow(title: "Intervall", value: "\(Int(autoSaveManager.configuration.interval))s")
                detailRow(title: "Idle-Schwelle", value: "\(Int(autoSaveManager.configuration.idleThreshold))s")
                detailRow(title: "Batch-Größe", value: "\(autoSaveManager.configuration.maxItemsPerBatch)")
                detailRow(title: "Retry-Versuche", value: "\(autoSaveManager.configuration.retryAttempts)")
                detailRow(title: "Backoff aktiviert", value: autoSaveManager.configuration.exponentialBackoff ? "Ja" : "Nein")
                detailRow(title: "Drafts erhalten", value: autoSaveManager.configuration.preserveDrafts ? "Ja" : "Nein")
            }
            
            // Queue Details
            if !autoSaveManager.queue.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Queue-Details")
                        .font(.headline)
                    
                    ForEach(autoSaveManager.queue.prefix(5), id: \.id) { item in
                        queueItemDetailView(item)
                    }
                    
                    if autoSaveManager.queue.count > 5 {
                        Text("... und \(autoSaveManager.queue.count - 5) weitere")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Statistics
            if let stats = autoSaveManager.statistics {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Statistiken")
                        .font(.headline)
                    
                    detailRow(title: "Gesamt Speicherungen", value: "\(stats.totalSaves)")
                    detailRow(title: "Erfolgreich", value: "\(stats.successfulSaves)")
                    detailRow(title: "Fehlgeschlagen", value: "\(stats.failedSaves)")
                    detailRow(title: "Durchschnittszeit", value: formatDuration(stats.averageSaveTime))
                    detailRow(title: "Längste Wartezeit", value: formatDuration(stats.longestPendingTime))
                }
            }
        }
        .padding(.top)
        .overlay(
            Divider()
                .background(Color.gray.opacity(0.3))
            , alignment: .top
        )
    }
    
    private func queueItemDetailView(_ item: SaveQueueItem) -> some View {
        HStack {
            priorityIndicator(title: item.priority.displayName, count: 1, color: item.priority.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Item \(item.item.id.uuidString.prefix(8))...")
                    .font(.caption)
                Text("Status: \(item.status.description)")
                    .font(.caption2)
                    .foregroundColor(item.status.color)
                if item.retryCount > 0 {
                    Text("Versuche: \(item.retryCount)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if item.age > 300 { // 5 Minuten
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(.orange)
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }
    
    // MARK: - Helper Methods
    
    private func toggleAutoSave() {
        if autoSaveManager.isEnabled {
            autoSaveManager.pauseAutoSave()
        } else {
            autoSaveManager.resumeAutoSave()
        }
    }
    
    private func getQueueCount(for priority: SavePriority) -> Int {
        autoSaveManager.queue.filter { $0.priority == priority }.count
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1.0 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.1fs", duration)
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private func observeStatusChanges() {
        // Setup observers für Status-Änderungen
        // Implementation würde je nach Bedarf erweitert werden
    }
}

// MARK: - Supporting Types

extension SavePriority {
    var displayName: String {
        switch self {
        case .low: return "Niedrig"
        case .normal: return "Normal"
        case .high: return "Hoch"
        case .critical: return "Kritisch"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .normal: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

extension SaveOperationStatus {
    var color: Color {
        switch self {
        case .pending: return .blue
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Status View

struct AutoSaveCompactStatusView: View {
    @StateObject private var autoSaveManager = AutoSaveManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            // Status Indicator
            Image(systemName: autoSaveManager.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(autoSaveManager.isEnabled ? .green : .red)
                .font(.caption)
            
            // Queue Count
            if !autoSaveManager.queue.isEmpty {
                Text("\(autoSaveManager.queue.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // Processing Indicator
            if autoSaveManager.isProcessingQueue {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)
            }
        }
    }
}

// MARK: - Preview

struct AutoSaveStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AutoSaveStatusView()
                .padding()
        }
    }
}

// MARK: - Integration Example

struct ContentViewWithAutoSave: View {
    @State private var noteTitle = ""
    @State private var noteContent = ""
    
    var body: some View {
        VStack {
            // Note Input
            VStack(alignment: .leading, spacing: 8) {
                TextField("Titel", text: $noteTitle)
                    .textFieldStyle(GlassTextFieldStyle())
                
                TextEditor(text: $noteContent)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding()
            
            // Auto-Save Status
            AutoSaveCompactStatusView()
                .padding(.horizontal)
            
            Spacer()
        }
        .onChange(of: noteTitle) { newValue in
            // Auto-Save logic would be triggered here
        }
        .onChange(of: noteContent) { newValue in
            // Auto-Save logic would be triggered here
        }
    }
}

#Preview {
    ContentViewWithAutoSave()
}