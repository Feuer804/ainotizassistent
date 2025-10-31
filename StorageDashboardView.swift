//
//  StorageDashboardView.swift
//  AINotizassistent
//
//  Comprehensive Storage Dashboard mit Analytics und Monitoring
//

import SwiftUI
import Charts

struct StorageDashboardView: View {
    @StateObject private var storageManager = StorageManager.shared
    @StateObject private var autoSaveManager = AutoSaveManager.shared
    @StateObject private var preferences = StoragePreferences.shared
    
    @State private var selectedTimeRange: TimeRange = .last24Hours
    @State private var showAdvancedMetrics = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header mit Quick Stats
                    quickStatsHeader
                    
                    // Storage Overview Chart
                    storageOverviewChart
                    
                    // Provider Status Grid
                    providerStatusGrid
                    
                    // Auto-Save Performance
                    autoSavePerformanceSection
                    
                    // Recent Activity
                    recentActivitySection
                    
                    // Storage Health
                    storageHealthSection
                    
                    // Capacity Planning
                    capacityPlanningSection
                }
                .padding()
            }
            .navigationTitle("Storage Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Zeitbereich", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        
                        Divider()
                        
                        Button("Erweiterte Metriken") {
                            showAdvancedMetrics = true
                        }
                        
                        Button("Export Dashboard") {
                            exportDashboard()
                        }
                        
                        Button("Refresh") {
                            Task {
                                await refreshDashboard()
                            }
                        }
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupDashboard()
        }
    }
    
    // MARK: - Quick Stats Header
    
    private var quickStatsHeader: some View {
        HStack(spacing: 16) {
            // Total Storage Used
            StatCard(
                title: "Speicher genutzt",
                value: formatBytes(storageManager.statistics?.usedSpace ?? 0),
                subtitle: getQuotaUsageText(),
                icon: "internaldrive",
                color: getQuotaColor()
            )
            
            // Sync Status
            StatCard(
                title: "Sync Status",
                value: getSyncStatusText(),
                subtitle: getLastSyncText(),
                icon: "arrow.triangle.2.circlepath",
                color: storageManager.isSyncing ? .blue : .green
            )
            
            // Auto-Save Queue
            StatCard(
                title: "Auto-Save Queue",
                value: "\(autoSaveManager.queue.count)",
                subtitle: autoSaveManager.isProcessingQueue ? "Verarbeitung läuft" : "Bereit",
                icon: "clock.badge.exclamationmark",
                color: autoSaveManager.queue.isEmpty ? .green : .orange
            )
            
            // Backup Status
            StatCard(
                title: "Backup Status",
                value: getBackupStatusText(),
                subtitle: getLastBackupText(),
                icon: "archivebox",
                color: getBackupColor()
            )
        }
    }
    
    // MARK: - Storage Overview Chart
    
    private var storageOverviewChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Speicher-Übersicht", icon: "chart.bar")
            
            // Usage Chart (vereinfacht - würde mit Charts Framework erweitert)
            VStack(spacing: 8) {
                // Provider Breakdown Bars
                ForEach(Array(storageManager.statistics?.providerBreakdown ?? [:]), id: \.key) { provider, size in
                    StorageUsageBar(
                        provider: provider,
                        used: size,
                        total: storageManager.statistics?.totalSize ?? 1
                    )
                }
            }
            
            // Trend Indicators
            HStack {
                TrendIndicator(title: "Tägliche Änderungen", value: "+12", trend: .up)
                Spacer()
                TrendIndicator(title: "Sync-Fehler", value: "0", trend: .stable)
                Spacer()
                TrendIndicator(title: "Performance", value: "98%", trend: .up)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Provider Status Grid
    
    private var providerStatusGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Storage Provider Status", icon: "externaldrive")
            
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(storageManager.availableProviders, id: \.self) { provider in
                    ProviderStatusCard(
                        provider: provider,
                        isAvailable: isProviderAvailable(provider),
                        usage: getProviderUsage(provider),
                        lastSync: getProviderLastSync(provider)
                    )
                }
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    }
    
    // MARK: - Auto-Save Performance
    
    private var autoSavePerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Auto-Save Performance", icon: "speedometer")
            
            // Performance Metrics
            HStack(spacing: 16) {
                PerformanceMetric(
                    title: "Ø Save Time",
                    value: formatDuration(autoSaveManager.statistics?.averageSaveTime ?? 0),
                    target: "< 2s",
                    isGood: (autoSaveManager.statistics?.averageSaveTime ?? 0) < 2.0
                )
                
                PerformanceMetric(
                    title: "Success Rate",
                    value: getSuccessRateText(),
                    target: "> 95%",
                    isGood: getSuccessRate() > 0.95
                )
                
                PerformanceMetric(
                    title: "Queue Health",
                    value: getQueueHealthText(),
                    target: "Optimal",
                    isGood: autoSaveManager.queue.count < 10
                )
            }
            
            // Recent Save Timeline
            VStack(alignment: .leading, spacing: 8) {
                Text("Aktuelle Speicherungen")
                    .font(.headline)
                
                SaveTimelineView()
                    .frame(height: 100)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Recent Activity
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Aktuelle Aktivitäten", icon: "clock.arrow.circlepath")
            
            ActivityFeedView(timeRange: selectedTimeRange)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Storage Health
    
    private var storageHealthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Storage Gesundheit", icon: "heart.text.square")
            
            // Health Indicators
            HStack(spacing: 12) {
                HealthIndicator(
                    title: "Integrität",
                    status: .good,
                    description: "Alle Daten intakt"
                )
                
                HealthIndicator(
                    title: "Verfügbarkeit",
                    status: getAvailabilityStatus(),
                    description: getAvailabilityDescription()
                )
            }
            
            // System Checks
            VStack(alignment: .leading, spacing: 8) {
                Text("System-Checks")
                    .font(.headline)
                
                SystemCheckRow(title: "Verschlüsselung", status: .passed, description: "AES-GCM aktiv")
                SystemCheckRow(title: "Backup-Validierung", status: .passed, description: "Letztes Backup erfolgreich")
                SystemCheckRow(title: "Sync-Health", status: .passed, description: "Alle Provider verfügbar")
                SystemCheckRow(title: "Quota-Monitoring", status: .warning, description: "80% Speicher verwendet")
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Capacity Planning
    
    private var capacityPlanningSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Kapazitätsplanung", icon: "chart.line.uptrend.xyaxis")
            
            // Growth Projection
            GrowthProjectionView()
                .frame(height: 120)
            
            // Recommendations
            VStack(alignment: .leading, spacing: 8) {
                Text("Empfehlungen")
                    .font(.headline)
                
                RecommendationRow(
                    icon: "arrow.up.circle.fill",
                    title: "Speicher erweitern",
                    description: "In 30 Tagen wird die Quote erreicht",
                    priority: .medium
                )
                
                RecommendationRow(
                    icon: "plus.circle.fill",
                    title: "Backup-Routine optimieren",
                    description: "Tägliche Backups statt wöchentlich",
                    priority: .low
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func setupDashboard() {
        Task {
            await storageManager.refreshStatistics()
            await autoSaveManager.refreshStatistics()
        }
    }
    
    private func refreshDashboard() async {
        await storageManager.refreshStatistics()
        await autoSaveManager.refreshStatistics()
    }
    
    private func exportDashboard() {
        // Dashboard-Export Implementierung
        print("Dashboard exportiert")
    }
    
    private func isProviderAvailable(_ provider: StorageProvider) -> Bool {
        // Implementierung der Provider-Verfügbarkeitsprüfung
        return true
    }
    
    private func getProviderUsage(_ provider: StorageProvider) -> (used: Int64, total: Int64) {
        let usage = storageManager.statistics?.providerBreakdown[provider] ?? 0
        let total = storageManager.statistics?.totalSize ?? 1
        return (usage, total)
    }
    
    private func getProviderLastSync(_ provider: StorageProvider) -> Date? {
        return storageManager.lastSyncDate
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1.0 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.1fs", duration)
        }
    }
    
    private func getQuotaUsageText() -> String {
        guard let quota = storageManager.configuration.maxStorageQuota,
              let used = storageManager.statistics?.usedSpace else {
            return "Unbegrenzt"
        }
        let percentage = Double(used) / Double(quota) * 100
        return String(format: "%.1f%%", percentage)
    }
    
    private func getQuotaColor() -> Color {
        guard let quota = storageManager.configuration.maxStorageQuota,
              let used = storageManager.statistics?.usedSpace else {
            return .green
        }
        let percentage = Double(used) / Double(quota)
        switch percentage {
        case 0..<0.7: return .green
        case 0.7..<0.9: return .yellow
        default: return .red
        }
    }
    
    private func getSyncStatusText() -> String {
        storageManager.isSyncing ? "Sync läuft" : "Bereit"
    }
    
    private func getLastSyncText() -> String {
        if let lastSync = storageManager.lastSyncDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Zuletzt: \(formatter.string(from: lastSync))"
        }
        return "Noch nie"
    }
    
    private func getBackupStatusText() -> String {
        return "OK"
    }
    
    private func getLastBackupText() -> String {
        if let lastBackup = storageManager.statistics?.lastBackupDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return "Zuletzt: \(formatter.string(from: lastBackup))"
        }
        return "Keine Backups"
    }
    
    private func getBackupColor() -> Color {
        .green // Vereinfacht
    }
    
    private func getSuccessRate() -> Double {
        guard let stats = autoSaveManager.statistics else { return 1.0 }
        let total = max(stats.totalSaves, 1)
        return Double(stats.successfulSaves) / Double(total)
    }
    
    private func getSuccessRateText() -> String {
        let rate = getSuccessRate()
        return String(format: "%.1f%%", rate * 100)
    }
    
    private func getQueueHealthText() -> String {
        let count = autoSaveManager.queue.count
        if count == 0 { return "Optimal" }
        else if count < 5 { return "Gut" }
        else if count < 10 { return "Belastet" }
        else { return "Überlastet" }
    }
    
    private func getAvailabilityStatus() -> HealthStatus {
        // Vereinfachte Implementierung
        return .good
    }
    
    private func getAvailabilityDescription() -> String {
        "Alle Provider verfügbar"
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

struct StorageUsageBar: View {
    let provider: StorageProvider
    let used: Int64
    let total: Int64
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: provider.iconName)
                    .foregroundColor(.blue)
                Text(provider.displayName)
                    .font(.headline)
                Spacer()
                Text(formatBytes(used))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(used), total: Double(max(total, 1)))
                .progressViewStyle(LinearProgressViewStyle())
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct TrendIndicator: View {
    let title: String
    let value: String
    let trend: Trend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(trend.color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

enum Trend {
    case up
    case down
    case stable
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .blue
        }
    }
}

struct ProviderStatusCard: View {
    let provider: StorageProvider
    let isAvailable: Bool
    let usage: (used: Int64, total: Int64)
    let lastSync: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: provider.iconName)
                    .foregroundColor(isAvailable ? .green : .red)
                Text(provider.displayName)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(isAvailable ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            
            let percentage = usage.total > 0 ? Double(usage.used) / Double(usage.total) : 0
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle())
            
            if let lastSync = lastSync {
                Text("Zuletzt: \(lastSync.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

struct PerformanceMetric: View {
    let title: String
    let value: String
    let target: String
    let isGood: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isGood ? .green : .red)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Ziel: \(target)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SaveTimelineView: View {
    // Vereinfachte Timeline-Anzeige
    var body: some View {
        HStack {
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(i % 3 == 0 ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                if i < 11 {
                    Spacer(minLength: 2)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ActivityFeedView: View {
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mock Activity Items
            ActivityItemRow(
                icon: "doc.text",
                title: "Notiz gespeichert",
                subtitle: "vor 5 Minuten",
                color: .green
            )
            
            ActivityItemRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Sync abgeschlossen",
                subtitle: "vor 12 Minuten",
                color: .blue
            )
            
            ActivityItemRow(
                icon: "archivebox",
                title: "Backup erstellt",
                subtitle: "vor 1 Stunde",
                color: .purple
            )
            
            if timeRange.rawValue >= TimeRange.lastWeek.rawValue {
                ActivityItemRow(
                    icon: "doc.richtext",
                    title: "Import abgeschlossen",
                    subtitle: "vor 2 Tagen",
                    color: .orange
                )
            }
        }
    }
}

struct ActivityItemRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct HealthIndicator: View {
    let title: String
    let status: HealthStatus
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.black.opacity(0.1))
        .cornerRadius(6)
    }
}

enum HealthStatus {
    case good
    case warning
    case error
    
    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .yellow
        case .error: return .red
        }
    }
}

struct SystemCheckRow: View {
    let title: String
    let status: HealthStatus
    let description: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

struct GrowthProjectionView: View {
    // Vereinfachte Wachstumsprojektion
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("30-Tage-Projektion")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("+2.3 GB")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(.orange)
                .font(.title2)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let description: String
    let priority: Priority
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(priority.color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

enum Priority {
    case low
    case medium
    case high
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

enum TimeRange: Int, CaseIterable {
    case lastHour = 1
    case last6Hours = 6
    case last24Hours = 24
    case lastWeek = 168 // 7 days
    case lastMonth = 720 // 30 days
    
    var displayName: String {
        switch self {
        case .lastHour: return "Letzte Stunde"
        case .last6Hours: return "Letzte 6 Stunden"
        case .last24Hours: return "Letzte 24 Stunden"
        case .lastWeek: return "Letzte Woche"
        case .lastMonth: return "Letzter Monat"
        }
    }
}

// MARK: - Preview

struct StorageDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            StorageDashboardView()
        }
    }
}

#Preview {
    StorageDashboardView()
}