//
//  ProcessingModeDemo.swift
//  Intelligente Notizen App
//  Demonstration der Processing-Mode-Funktionalität
//

import SwiftUI

// MARK: - Demo View
struct ProcessingModeDemoView: View {
    @StateObject private var processingManager = ProcessingModeManager()
    @State private var demoText = ""
    @State private var selectedTask: ProcessingTaskType = .summary
    @State private var results: String = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("🤖 KI-Verarbeitungs-Modi Demo")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Teste flexible KI-Verarbeitung mit verschiedenen Modi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Current Status
                StatusOverviewView(processingManager: processingManager)
                
                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Demo-Text eingeben")
                        .font(.headline)
                    
                    TextEditor(text: $demoText)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Picker("Task-Typ", selection: $selectedTask) {
                        ForEach(ProcessingTaskType.allCases, id: \.self) { task in
                            Text(task.rawValue).tag(task)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Process Button
                Button(action: processText) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isProcessing ? "Verarbeite..." : "KI-Verarbeitung starten")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isProcessing || demoText.isEmpty)
                .padding(.horizontal)
                
                // Results
                if !results.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ergebnis")
                            .font(.headline)
                        
                        ScrollView {
                            Text(results)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Processing-Mode Demo")
    }
    
    private func processText() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let decision = await processingManager.determineOptimalProcessing(
                    for: demoText,
                    taskType: selectedTask
                )
                
                // Simulate processing result based on decision
                let result = generateDemoResult(decision: decision, task: selectedTask)
                
                await MainActor.run {
                    results = result
                }
            } catch {
                await MainActor.run {
                    results = "Fehler: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func generateDemoResult(decision: ProcessingDecision, task: ProcessingTaskType) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        
        var result = "🎯 Verarbeitungs-Entscheidung:\n"
        result += "━━━━━━━━━━━━━━━━━━━━━━━━\n"
        result += "Provider: \(decision.selectedProvider.rawValue)\n"
        result += "Modus: \(decision.selectedMode.rawValue)\n"
        result += "Confidence: \(String(format: "%.1f%%", decision.confidence * 100))\n"
        result += "Geschätzte Kosten: $\(String(format: "%.4f", decision.estimatedCost))\n"
        result += "Geschätzte Zeit: \(String(format: "%.1f", decision.estimatedTime))s\n"
        result += "Privacy-konform: \(decision.privacyCompliance ? "✅" : "❌")\n\n"
        
        result += "📋 Entscheidungsgrund:\n"
        result += "\(decision.reasoning)\n\n"
        
        if let fallback = decision.fallbackProvider {
            result += "🔄 Fallback-Provider: \(fallback.rawValue)\n\n"
        }
        
        // Generate mock result based on task type
        result += "🔍 Mock-Ergebnis (\(task.rawValue)):\n"
        result += "━━━━━━━━━━━━━━━━━━━━━━━━\n"
        
        switch task {
        case .summary:
            result += "Demo-Zusammenfassung: \(demoText.prefix(100))... (wurde von \(decision.selectedProvider.rawValue) generiert)"
        case .keywords:
            result += "Demo-Keywords: Demo, Beispiel, Test, Processing, Mode"
        case .categorization:
            result += "Demo-Kategorie: Note (Best guess based on content pattern)"
        case .enhancement:
            result += "Demo-Verbesserung: [Verbesserter Text würde hier stehen...]"
        case .questions:
            result += "Demo-Fragen:\n• Was ist das Hauptthema?\n• Wie kann dies verbessert werden?\n• Welche nächsten Schritte gibt es?"
        case .analysis:
            result += "Demo-Analyse: Komplexität: Mittel, Sentiment: Neutral, Empfehlung: Hybrid-Modus optimal"
        }
        
        result += "\n\n⏰ Generiert um: \(formatter.string(from: Date()))"
        
        return result
    }
}

// MARK: - Status Overview View
struct StatusOverviewView: View {
    @ObservedObject var processingManager: ProcessingModeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aktueller Status")
                        .font(.headline)
                    Text("Modus: \(processingManager.currentMode.rawValue)")
                        .font(.subheadline)
                    Text("Provider: \(processingManager.currentProvider.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                StatusIndicator(isOnline: processingManager.metrics.totalRequests > 0)
            }
            
            // Metrics Overview
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                MetricCard(title: "Anfragen", value: "\(processingManager.metrics.totalRequests)", icon: "arrow.clockwise")
                MetricCard(title: "Cloud %", value: "\(Int(processingManager.metrics.cloudUsagePercentage))%", icon: "cloud")
                MetricCard(title: "Qualität", value: "\(String(format: "%.1f", processingManager.metrics.averageQualityScore * 100))%", icon: "star.fill")
            }
            
            // Recent Notifications
            if !processingManager.notifications.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Letzte Aktivität")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(processingManager.notifications.prefix(3)) { notification in
                        HStack {
                            Image(systemName: notificationIcon(for: notification.type))
                                .foregroundColor(notificationSeverityColor(for: notification.severity))
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(notification.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(notification.message)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(notification.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.tertiary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func notificationIcon(for type: ProcessingNotification.NotificationType) -> String {
        switch type {
        case .modeSwitch: return "arrow.right.arrow.left"
        case .fallback: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .recommendation: return "lightbulb"
        }
    }
    
    private func notificationSeverityColor(for severity: ProcessingNotification.NotificationSeverity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Supporting Views
struct StatusIndicator: View {
    let isOnline: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isOnline ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isOnline ? "Online" : "Offline")
                .font(.caption)
                .foregroundColor(isOnline ? .green : .red)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Demo Data
struct DemoTexts {
    static let sensitive = """
    Vertrauliche Geschäftsinformation:
    
    Unser Quartalsbericht zeigt starke Umsatzzahlen. 
    Die neuen Verträge mit wichtigen Kunden enthalten sensible Preisinformationen.
    Bitte behandeln Sie diese Informationen als streng vertraulich.
    """
    
    static let technical = """
    Code-Review für neue Feature-Implementierung:
    
    func processData(_ input: [String: Any]) async throws -> DataProcessorResult {
        // Implementation details...
        // Performance optimization needed
        // Consider memory management
    }
    """
    
    static let casual = """
    Heute war ein schöner Tag. Ich habe einen Spaziergang im Park gemacht 
    und dabei über verschiedene Ideen nachgedacht. Vielleicht sollte ich 
    mehr Zeit draußen verbringen, das tut der Gesundheit gut.
    """
    
    static let business = """
    Meeting-Notizen vom Projektabschluss:
    
    - Alle Meilensteine erreicht ✅
    - Budget eingehalten
    - Team-Performance exzellent
    - Nächste Schritte: Dokumentation vervollständigen
    - Feedback-Session geplant
    """
}

// MARK: - Previews
struct ProcessingModeDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingModeDemoView()
    }
}