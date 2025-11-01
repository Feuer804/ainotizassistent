import SwiftUI
import Charts
import OSLog

/// Performance-Dashboard für visuelle Überwachung
@available(iOS 16.0, *)
struct PerformanceDashboardView: View {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @StateObject private var benchmarker = PerformanceBenchmarker.shared
    
    @State private var selectedTimeRange: TimeRange = .lastHour
    @State private var selectedMetric: PerformanceMetric = .responseTime
    @State private var showBenchmarkResults = false
    @State private var showAlertDetails = false
    @State private var isMonitoringActive = false
    
    private let logger = os.Logger(subsystem: "com.minimax.AINotizassistent", category: "Dashboard")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header mit Status und Controls
                    headerView
                    
                    // Live Performance Overview
                    liveOverviewView
                    
                    // Performance Charts
                    performanceChartsView
                    
                    // Memory Monitor
                    memoryMonitorView
                    
                    // CPU Usage
                    cpuMonitorView
                    
                    // Battery & Network Status
                    systemStatusView
                    
                    // Recent Alerts
                    alertsView
                    
                    // Benchmark Controls
                    benchmarkControlsView
                    
                    // Action Buttons
                    actionButtonsView
                }
                .padding()
            }
            .navigationTitle("Performance Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isMonitoringActive ? "Stop" : "Start") {
                        toggleMonitoring()
                    }
                }
            }
        }
        .onAppear {
            performanceMonitor.performanceAlertHandler = handlePerformanceAlert
        }
        .alert(isPresented: $showAlertDetails) {
            Alert(
                title: Text("Performance Alert"),
                message: Text(currentAlertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Views
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Performance Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Live Monitoring & Analysis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Circle()
                    .fill(isMonitoringActive ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(isMonitoringActive ? "Live" : "Paused")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var liveOverviewView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
            MetricCard(
                title: "Response Time",
                value: formatTime(performanceMonitor.performanceMetrics.currentCPUUsage),
                subtitle: "ms",
                color: .blue,
                icon: "clock"
            )
            
            MetricCard(
                title: "Memory Usage",
                value: formatMemory(performanceMonitor.memoryMetrics.currentUsage),
                subtitle: "MB",
                color: .green,
                icon: "memorychip"
            )
            
            MetricCard(
                title: "CPU Usage",
                value: String(format: "%.1f", performanceMonitor.performanceMetrics.currentCPUUsage),
                subtitle: "%",
                color: .orange,
                icon: "cpu"
            )
            
            MetricCard(
                title: "Battery Level",
                value: String(format: "%.0f", performanceMonitor.batteryMetrics.currentLevel),
                subtitle: "%",
                color: performanceMonitor.batteryMetrics.currentLevel > 20 ? .green : .red,
                icon: "battery.100"
            )
        }
    }
    
    private var performanceChartsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Performance Trends")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            // Chart Selection
            Picker("Metric", selection: $selectedMetric) {
                ForEach(PerformanceMetric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            
            // Performance Chart
            performanceChartView
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var performanceChartView: some View {
        Chart(getChartData()) { item in
            LineMark(
                x: .value("Time", item.timestamp),
                y: .value("Value", item.value)
            )
            .foregroundStyle(.blue)
            
            AreaMark(
                x: .value("Time", item.timestamp),
                y: .value("Value", item.value)
            )
            .foregroundStyle(.blue.opacity(0.2))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks { axis in
                AxisValueLabel {
                    if let date = axis.as(Date.self) {
                        Text(date, style: .time)
                    }
                }
            }
        }
    }
    
    private var memoryMonitorView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Memory Monitor")
                    .font(.headline)
                
                Spacer()
                
                Button("Optimize") {
                    performanceMonitor.optimizeMemory()
                }
                .buttonStyle(.bordered)
            }
            
            // Memory Usage Progress Bar
            ProgressView(value: performanceMonitor.memoryMetrics.usagePercentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: memoryUsageColor))
            
            HStack {
                Text("Used: \(formatMemory(performanceMonitor.memoryMetrics.currentUsage))")
                    .font(.caption)
                
                Spacer()
                
                Text("Available: \(formatMemory(getAvailableMemory()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Memory Timeline
            if !performanceMonitor.memoryMetrics.usageMeasurements.isEmpty {
                Chart(performanceMonitor.memoryMetrics.usageMeasurements.suffix(50)) { measurement in
                    LineMark(
                        x: .value("Time", measurement.timestamp),
                        y: .value("Memory", measurement.value)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 100)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var cpuMonitorView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CPU Monitor")
                    .font(.headline)
                
                Spacer()
                
                Text("\(String(format: "%.1f", performanceMonitor.performanceMetrics.currentCPUUsage))%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(cpuUsageColor)
            }
            
            // CPU Usage Gauge
            Gauge(value: performanceMonitor.performanceMetrics.currentCPUUsage, in: 0...100) {
                Text("CPU")
            } currentValueLabel: {
                Text("\(String(format: "%.0f", performanceMonitor.performanceMetrics.currentCPUUsage))%")
                    .font(.caption)
            }
            .gaugeStyle(CircularGaugeStyle(tint: cpuUsageColor))
            .frame(height: 80)
            
            // CPU Timeline
            if !performanceMonitor.performanceMetrics.cpuUsageMeasurements.isEmpty {
                Chart(performanceMonitor.performanceMetrics.cpuUsageMeasurements.suffix(50)) { measurement in
                    LineMark(
                        x: .value("Time", measurement.timestamp),
                        y: .value("CPU", measurement.value)
                    )
                    .foregroundStyle(.orange)
                }
                .frame(height: 80)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var systemStatusView: some View {
        HStack(spacing: 20) {
            // Battery Status
            VStack {
                Image(systemName: batteryIcon)
                    .foregroundColor(batteryIconColor)
                    .font(.title2)
                
                Text("Battery")
                    .font(.caption)
                
                Text("\(String(format: "%.0f", performanceMonitor.batteryMetrics.currentLevel))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemBackground))
            )
            
            // Network Status
            VStack {
                Image(systemName: "wifi")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Network")
                    .font(.caption)
                
                Text("\(formatLatency(networkLatency))")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemBackground))
            )
            
            // FPS Monitor
            VStack {
                Image(systemName: "display")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("FPS")
                    .font(.caption)
                
                Text("\(averageFPS)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var alertsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Alerts")
                    .font(.headline)
                
                Spacer()
                
                if !recentAlerts.isEmpty {
                    Text("\(recentAlerts.count) alerts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if recentAlerts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    
                    Text("No recent alerts")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            } else {
                ForEach(recentAlerts, id: \.self) { alert in
                    AlertRowView(alert: alert)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var benchmarkControlsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Benchmark Suite")
                    .font(.headline)
                
                Spacer()
                
                if benchmarker.isRunning {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            HStack {
                Button("Run Single") {
                    runSingleBenchmark()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Run All") {
                    runAllBenchmarks()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Score")
                        .font(.caption)
                    Text("\(String(format: "%.1f", benchmarker.overallScore))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 10) {
            HStack {
                Button("Memory Test") {
                    runMemoryLeakTest()
                }
                .buttonStyle(.bordered)
                
                Button("Stress Test") {
                    runStressTest()
                }
                .buttonStyle(.bordered)
            }
            
            HStack {
                Button("Export Report") {
                    exportPerformanceReport()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Settings") {
                    // Navigate to settings
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func toggleMonitoring() {
        isMonitoringActive.toggle()
        if isMonitoringActive {
            performanceMonitor.startMonitoring()
            logger.info("Performance monitoring started")
        } else {
            performanceMonitor.stopMonitoring()
            logger.info("Performance monitoring stopped")
        }
    }
    
    private func getChartData() -> [ChartDataPoint] {
        let measurements = getMeasurementsForMetric(selectedMetric)
        return measurements.suffix(50).map { measurement in
            ChartDataPoint(value: measurement.value, timestamp: measurement.timestamp)
        }
    }
    
    private func getMeasurementsForMetric(_ metric: PerformanceMetric) -> [Measurement] {
        switch metric {
        case .responseTime:
            return performanceMonitor.performanceMetrics.responseTimeMeasurements
        case .memoryUsage:
            return performanceMonitor.memoryMetrics.usageMeasurements
        case .cpuUsage:
            return performanceMonitor.performanceMetrics.cpuUsageMeasurements
        case .batteryLevel:
            return performanceMonitor.batteryMetrics.levelMeasurements
        case .networkLatency:
            return performanceMonitor.networkMetrics.latencyMeasurements
        case .animationFPS:
            return performanceMonitor.uiMetrics.fpsMeasurements
        }
    }
    
    private func runSingleBenchmark() {
        Task {
            let result = await benchmarker.runSingleBenchmark(.responseTime)
            await MainActor.run {
                logger.info("Single benchmark completed: \(result.formattedScore)")
            }
        }
    }
    
    private func runAllBenchmarks() {
        Task {
            let results = await benchmarker.runComprehensiveBenchmark()
            await MainActor.run {
                logger.info("All benchmarks completed. Average score: \(String(format: "%.1f", benchmarker.overallScore))")
            }
        }
    }
    
    private func runMemoryLeakTest() {
        Task {
            let result = await benchmarker.runMemoryLeakTest()
            await MainActor.run {
                logger.info("Memory leak test completed. Leak detected: \(result.leakDetected)")
            }
        }
    }
    
    private func runStressTest() {
        Task {
            let result = await benchmarker.runStressTest(duration: 30.0)
            await MainActor.run {
                logger.info("Stress test completed. Success rate: \(result.formattedSuccessRate)")
            }
        }
    }
    
    private func exportPerformanceReport() {
        // Implement report export functionality
        logger.info("Exporting performance report")
    }
    
    private func handlePerformanceAlert(_ alert: PerformanceAlert) {
        showAlertDetails = true
        currentAlertMessage = alert.localizedDescription
        logger.warning("Performance alert: \(alert.localizedDescription)")
    }
    
    // Computed properties for UI
    private var networkLatency: Double {
        performanceMonitor.networkMetrics.averageLatency
    }
    
    private var averageFPS: String {
        let fpsMeasurements = performanceMonitor.uiMetrics.fpsMeasurements
        guard !fpsMeasurements.isEmpty else { return "--" }
        
        let average = fpsMeasurements.map { $0.value }.reduce(0, +) / Double(fpsMeasurements.count)
        return String(format: "%.0f", average)
    }
    
    private var memoryUsageColor: Color {
        let percentage = performanceMonitor.memoryMetrics.usagePercentage
        if percentage > 80 { return .red }
        else if percentage > 60 { return .orange }
        else { return .green }
    }
    
    private var cpuUsageColor: Color {
        let cpuUsage = performanceMonitor.performanceMetrics.currentCPUUsage
        if cpuUsage > 80 { return .red }
        else if cpuUsage > 60 { return .orange }
        else { return .green }
    }
    
    private var batteryIcon: String {
        let level = performanceMonitor.batteryMetrics.currentLevel
        if level > 80 { return "battery.100" }
        else if level > 60 { return "battery.75" }
        else if level > 40 { return "battery.50" }
        else if level > 20 { return "battery.25" }
        else { return "battery.0" }
    }
    
    private var batteryIconColor: Color {
        let level = performanceMonitor.batteryMetrics.currentLevel
        if level > 20 { return .green }
        else { return .red }
    }
    
    private var scoreColor: Color {
        let score = benchmarker.overallScore
        if score > 80 { return .green }
        else if score > 60 { return .orange }
        else { return .red }
    }
    
    private var recentAlerts: [String] {
        // In a real implementation, this would come from a stored alerts list
        return []
    }
    
    private var currentAlertMessage: String = ""
    
    // Formatting helpers
    private func formatTime(_ seconds: Double) -> String {
        if seconds < 1.0 {
            return String(format: "%.2fms", seconds * 1000)
        } else {
            return String(format: "%.2fs", seconds)
        }
    }
    
    private func formatMemory(_ mb: Double) -> String {
        if mb > 1024 {
            return String(format: "%.2f GB", mb / 1024)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }
    
    private func formatLatency(_ ms: Double) -> String {
        return String(format: "%.0fms", ms)
    }
    
    private func getAvailableMemory() -> Double {
        return getTotalMemory() - performanceMonitor.memoryMetrics.currentUsage
    }
    
    private func getTotalMemory() -> Double {
        return Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0
    }
}

// MARK: - Supporting Views
@available(iOS 16.0, *)
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
        )
    }
}

@available(iOS 16.0, *)
struct AlertRowView: View {
    let alert: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(alert)
                .font(.caption)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Types
@available(iOS 16.0, *)
enum TimeRange: String, CaseIterable {
    case lastHour = "1H"
    case last6Hours = "6H"
    case last24Hours = "24H"
    case lastWeek = "1W"
}

@available(iOS 16.0, *)
enum PerformanceMetric: String, CaseIterable {
    case responseTime = "Response Time"
    case memoryUsage = "Memory Usage"
    case cpuUsage = "CPU Usage"
    case batteryLevel = "Battery Level"
    case networkLatency = "Network Latency"
    case animationFPS = "FPS"
}

@available(iOS 16.0, *)
struct ChartDataPoint {
    let value: Double
    let timestamp: Date
}

// MARK: - Preview
@available(iOS 16.0, *)
struct PerformanceDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceDashboardView()
    }
}