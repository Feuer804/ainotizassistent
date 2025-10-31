import SwiftUI

// MARK: - Todo Generator Demo

struct TodoGeneratorDemo: View {
    @StateObject private var todoViewModel = TodoViewModel()
    @State private var demoText = """
    Hallo zusammen! 
    
    Bitte denken Sie daran:
    
    1. Wir müssen nächste Woche das Projekt XYZ fertigstellen
    2. Maria soll das Design-Protokoll überprüfen
    3. Dringend: Der Server muss heute晚 noch updated werden
    4. Johann bereitet die Präsentation für Freitag vor
    5. Wöchentliches Team-Meeting am Montag um 10 Uhr
    6. Einkaufen: Milch, Brot, Eier - das machen wir täglich
    7. Arzt-Termin am 15. November buchen
    8. Schulung für das neue System nächste Woche organisieren
    """
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("Intelligenter Todo-Generator")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("KI-gestützte Aufgaben-Generierung mit modernem Glass-Design")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Demo Content
                VStack(alignment: .leading, spacing: 16) {
                    Text("Demo-Text")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    TextEditor(text: $demoText)
                        .frame(minHeight: 200)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.blue.opacity(0.3), lineWidth: 2)
                        )
                        .foregroundStyle(.primary)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                
                // Generate Button
                Button(action: generateIntelligentTodos) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("🤖 Intelligente Todos generieren")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.bottom, 20)
                
                // Features Overview
                FeaturesOverview()
                    .padding(.horizontal)
            }
        }
        .background(
            LinearGradient(colors: [
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.1),
                Color.pink.opacity(0.1)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        )
    }
    
    private func generateIntelligentTodos() {
        Task {
            do {
                print("🚀 Starte KI-gestützte Todo-Generierung...")
                
                let todoGenerator = TodoGenerator()
                let analysis = try await todoGenerator.generateTodos(from: demoText)
                
                print("✅ Generierung abgeschlossen!")
                print("📊 Statistiken:")
                print("   - Extrahierte Tasks: \(analysis.extractedTasks.count)")
                print("   - Erkannte Teilnehmer: \(analysis.detectedParticipants.count)")
                print("   - Gefundene Deadlines: \(analysis.deadlines.count)")
                print("   - Urgency-Indikatoren: \(analysis.urgencyIndicators.count)")
                print("   - Zeit-Schätzungen: \(analysis.timeEstimates.count)")
                print("   - Erkannte Patterns: \(analysis.patterns.count)")
                
                // Füge generierte Todos zum ViewModel hinzu
                await MainActor.run {
                    todoViewModel.addTodos(analysis.extractedTasks)
                }
                
                // Zeige detaillierte Ergebnisse in der Konsole
                print("\n📋 Detaillierte Task-Übersicht:")
                for (index, task) in analysis.extractedTasks.enumerated() {
                    print("\n\(index + 1). \(task.title)")
                    print("   Kategorie: \(task.category.rawValue)")
                    print("   Priorität: \(task.priority.rawValue)")
                    print("   Urgency Score: \(String(format: "%.2f", task.urgencyScore))")
                    print("   Geschätzte Zeit: \(formatTime(task.estimatedTime))")
                    if let deadline = task.deadline {
                        print("   Deadline: \(deadline.formatted(date: .abbreviated, time: .shortened))")
                    }
                    if task.isRecurring {
                        print("   Wiederkehrend: \(task.recurrencePattern?.rawValue ?? "Unbekannt")")
                    }
                    print("   Completion Probability: \(Int(task.completionProbability * 100))%")
                    if !task.tags.isEmpty {
                        print("   Tags: \(task.tags.joined(separator: ", "))")
                    }
                    if !task.participants.isEmpty {
                        print("   Teilnehmer: \(task.participants.joined(separator: ", "))")
                    }
                }
                
                // Prüfe Abhängigkeiten
                let hasDependencies = analysis.extractedTasks.contains { !$0.dependencies.isEmpty }
                if hasDependencies {
                    print("\n🔗 Abhängigkeiten erkannt!")
                    for task in analysis.extractedTasks where !task.dependencies.isEmpty {
                        print("   '\(task.title)' wartet auf \(task.dependencies.count) andere Tasks")
                    }
                }
                
                // Prüfe wiederkehrende Tasks
                let recurringTasks = analysis.extractedTasks.filter { $0.isRecurring }
                if !recurringTasks.isEmpty {
                    print("\n🔄 Wiederkehrende Tasks:")
                    for task in recurringTasks {
                        print("   '\(task.title)' (\(task.recurrencePattern?.rawValue ?? "Unbekannt"))")
                    }
                }
                
            } catch {
                print("❌ Fehler bei der Todo-Generierung: \(error)")
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - Features Overview

struct FeaturesOverview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🚀 KI-Features")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                FeatureCard(
                    icon: "brain.head.profile",
                    title: "KI-Priorisierung",
                    description: "Automatische Urgency-Bewertung mit Natural Language Processing"
                )
                
                FeatureCard(
                    icon: "link",
                    title: "Abhängigkeiten",
                    description: "Intelligente Erkennung von Task-Dependencies und Workflows"
                )
                
                FeatureCard(
                    icon: "clock",
                    title: "Zeit-Schätzung",
                    description: "KI-basierte Schätzungen für Task-Dauer und Komplexität"
                )
                
                FeatureCard(
                    icon: "calendar",
                    title: "Deadline-Inference",
                    description: "Automatische Termin-Erkennung aus Text-Kontext"
                )
                
                FeatureCard(
                    icon: "repeat",
                    title: "Wiederkehrende Tasks",
                    description: "Pattern-Erkennung für regelmäßige Aufgaben"
                )
                
                FeatureCard(
                    icon: "person.3",
                    title: "Delegation",
                    description: "Erkennung von Teilnehmern und Zuweisungsvorschlägen"
                )
                
                FeatureCard(
                    icon: "chart.bar",
                    title: "Completion-Wahrscheinlichkeit",
                    description: "KI-Vorhersage der Erfolgschancen für Tasks"
                )
                
                FeatureCard(
                    icon: "rectangle.3.group",
                    title: "Smart Merging",
                    description: "Intelligente Zusammenfassung ähnlicher Aufgaben"
                )
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Demo Preview

struct TodoGeneratorDemo_Previews: PreviewProvider {
    static var previews: some View {
        TodoGeneratorDemo()
    }
}