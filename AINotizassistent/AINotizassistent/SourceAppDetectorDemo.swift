//
//  SourceAppDetectorDemo.swift
//  AINotizassistent
//
//  Demo und Usage-Beispiele für die Quell-App-Erkennung
//

import Foundation
import SwiftUI

// MARK: - Demo Usage
class SourceAppDetectorDemo {
    
    private var detector: SourceAppDetector
    private var monitor: ActiveAppMonitor
    
    init() {
        self.detector = SourceAppDetector()
        self.monitor = ActiveAppMonitor(detector: detector)
    }
    
    // MARK: - Basic Usage Examples
    
    func basicAppDetectionExample() {
        print("=== Grundlegende App-Erkennung ===")
        
        // 1. Tracking aktivieren
        detector.enableTracking()
        
        // 2. Aktuelle App erfassen
        let result = detector.detectCurrentApp()
        
        if result.isSuccessful, let source = result.source {
            print("✅ Aktive App: \(source.displayName)")
            print("📱 Kategorie: \(source.category.displayName)")
            print("🏷️ Bundle ID: \(source.appId)")
            print("🪟 Fenster: \(source.windowTitle ?? "Keine Info")")
        } else if let error = result.error {
            print("❌ Fehler: \(error.localizedDescription)")
        }
    }
    
    func detailedAppDetectionExample() {
        print("=== Erweiterte App-Erkennung ===")
        
        let result = detector.detectCurrentAppDetailed()
        
        if result.isSuccessful, let source = result.source {
            print("✅ Aktive App: \(source.displayName)")
            print("📊 Metadata:")
            
            if let metadata = source.extractedMetadata {
                for (key, value) in metadata {
                    print("   \(key): \(value)")
                }
            }
            
            print("🎯 Relevanz: \(source.contentRelevance.score)")
        }
    }
    
    func appMonitoringExample() {
        print("=== App-Überwachung Demo ===")
        
        do {
            // 1. Monitoring starten
            try monitor.startMonitoring()
            
            // 2. App-Änderungen abonnieren
            monitor.$appChangeHistory
                .receive(on: DispatchQueue.main)
                .sink { [weak self] history in
                    if let lastEvent = history.last {
                        print("📱 App gewechselt: \(lastEvent.newApp.displayName)")
                    }
                }
                .store(in: &Set<AnyCancellable>())
            
            // 3. Periodische Prüfung
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                self.monitor.stopMonitoring()
                print("🛑 Monitoring beendet")
            }
            
        } catch {
            print("❌ Monitoring-Fehler: \(error.localizedDescription)")
        }
    }
    
    func privacySettingsExample() {
        print("=== Privacy-Einstellungen Demo ===")
        
        // Privacy Settings abrufen
        var settings = detector.getPrivacySettings()
        print("🔒 Tracking aktiviert: \(settings.isTrackingEnabled)")
        
        // Nur bestimmte Kategorien erlauben
        settings.setAllowedCategories([.browser, .email, .editor])
        detector.updatePrivacySettings(settings)
        
        // System App Tracking deaktivieren
        settings.toggleSystemAppTracking()
        detector.updatePrivacySettings(settings)
        
        print("🔒 Erlaubte Kategorien: \(detector.getPreferredCategories().map { $0.displayName })")
    }
    
    func appMappingExample() {
        print("=== App-Mapping Demo ===")
        
        // Bekannte Apps anzeigen
        print("📚 Bekannte Apps: \(SourceAppMapping.totalKnownApps)")
        
        // Apps nach Kategorie finden
        let browsers = SourceAppMapping.findApps(by: .browser)
        print("🌐 Browser: \(browsers.map { $0.displayName })")
        
        let emailApps = SourceAppMapping.findApps(by: .email)
        print("📧 E-Mail Apps: \(emailApps.map { $0.displayName })")
        
        // Kategorie-Verteilung
        let categoryStats = SourceAppMapping.appsByCategory
        print("📊 Kategorie-Verteilung:")
        for (category, count) in categoryStats {
            let percentage = SourceAppMapping.categoryPercentage(for: category)
            print("   \(category.displayName): \(count) Apps (\(String(format: "%.1f", percentage))%)")
        }
    }
    
    func performanceMonitoringExample() {
        print("=== Performance-Monitoring Demo ===")
        
        // Performance-Modi
        monitor.setHighPerformanceMode()
        print("🚀 Performance-Modus aktiviert")
        
        // App-Statistiken anzeigen
        let stats = monitor.getStatistics()
        print("📈 Detections: \(stats.successfulDetections)/\(stats.totalDetections)")
        print("⏱️ Durchschnittliche Erkennungszeit: \(String(format: "%.3f", stats.averageDetectionTime))s")
        print("🎯 Erfolgsrate: \(String(format: "%.1f", stats.successRate))%")
        print("⭐ Performance-Score: \(String(format: "%.2f", stats.performanceScore))")
    }
    
    func contentParsingExample() {
        print("=== Content-Parsing Demo ===")
        
        // Mail Content Parsing
        let mailParser = MailContentParser()
        let mailDefinition = SourceAppMapping.findApp(by: "com.apple.Mail")!
        let mailMetadata = mailParser.parseContent(from: "Wichtige Nachricht - user@example.com (5 Nachrichten) - Mail", appType: mailDefinition)
        print("📧 Mail-Metadata: \(mailMetadata ?? [:])")
        
        // Browser Content Parsing
        let browserParser = BrowserContentParser()
        let browserDefinition = SourceAppMapping.findApp(by: "com.apple.Safari")!
        let browserMetadata = browserParser.parseContent(from: "GitHub - Apple Safari", appType: browserDefinition)
        print("🌐 Browser-Metadata: \(browserMetadata ?? [:])")
        
        // Editor Content Parsing
        let editorParser = EditorContentParser()
        let editorDefinition = SourceAppMapping.findApp(by: "com.microsoft.VSCode")!
        let editorMetadata = editorParser.parseContent(from: "main.swift - Visual Studio Code", appType: editorDefinition)
        print("📝 Editor-Metadata: \(editorMetadata ?? [:])")
    }
}

// MARK: - SwiftUI Integration Demo
struct SourceAppDetectorView: View {
    @StateObject private var detector = SourceAppDetector()
    @StateObject private var monitor = ActiveAppMonitor()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Quell-App-Erkennung")
                .font(.title)
                .fontWeight(.bold)
            
            // Status
            VStack(spacing: 10) {
                Text("Status")
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(monitor.isMonitoring ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                    Text(monitor.isMonitoring ? "Überwachung aktiv" : "Überwachung inaktiv")
                }
                
                if let currentApp = monitor.currentApp {
                    VStack(spacing: 5) {
                        Text("Aktuelle App")
                            .font(.subheadline)
                        Text(currentApp.displayName)
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(currentApp.category.displayName)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // Controls
            VStack(spacing: 10) {
                if monitor.isMonitoring {
                    Button("Überwachung stoppen") {
                        monitor.stopMonitoring()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Überwachung starten") {
                        do {
                            try monitor.startMonitoring()
                        } catch {
                            print("Fehler: \(error)")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                HStack {
                    Button("App erkennen") {
                        detector.detectCurrentApp()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Statistiken") {
                        printStatistics()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // App-Änderungen
            if !monitor.appChangeHistory.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Letzte Änderungen")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 5) {
                            ForEach(monitor.getAppChangeHistory(limit: 5).indices, id: \.self) { index in
                                let event = monitor.getAppChangeHistory(limit: 5)[index]
                                HStack {
                                    Text(event.changeType.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(event.newApp.displayName)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                }
            }
        }
        .padding()
    }
    
    private func printStatistics() {
        let stats = monitor.getStatistics()
        print("📊 Statistiken:")
        print("   Erfolgreich: \(stats.successfulDetections)")
        print("   Fehlgeschlagen: \(stats.failedDetections)")
        print("   Erfolgsrate: \(String(format: "%.1f", stats.successRate))%")
        print("   Performance: \(String(format: "%.2f", stats.performanceScore))")
    }
}

// MARK: - Usage Instructions
/*
 
 ## Verwendung der Quell-App-Erkennung

### 1. Grundlegende Einrichtung
```swift
// App-Detektor initialisieren
let detector = SourceAppDetector()

// Tracking aktivieren (Opt-in erforderlich)
detector.enableTracking()
```

### 2. App-Erkennung
```swift
// Einfache Erkennung
let result = detector.detectCurrentApp()

if result.isSuccessful, let source = result.source {
    print("App: \(source.displayName)")
    print("Kategorie: \(source.category.displayName)")
}

// Erweiterte Erkennung mit Metadata
let detailedResult = detector.detectCurrentAppDetailed()

if detailedResult.isSuccessful, let source = detailedResult.source {
    if let metadata = source.extractedMetadata {
        print("Metadata: \(metadata)")
    }
}
```

### 3. Kontinuierliche Überwachung
```swift
// Monitor initialisieren
let monitor = ActiveAppMonitor(detector: detector)

// Monitoring starten
do {
    try monitor.startMonitoring()
} catch {
    print("Fehler: \(error)")
}

// App-Änderungen abonnieren
monitor.$appChangeHistory
    .sink { history in
        if let latestChange = history.last {
            print("App gewechselt zu: \(latestChange.newApp.displayName)")
        }
    }
    .store(in: &cancellables)
```

### 4. Privacy-Einstellungen
```swift
// Privacy Settings anpassen
var settings = detector.getPrivacySettings()

// Nur bestimmte Kategorien erlauben
settings.setAllowedCategories([.browser, .email])

// System-Apps ausschließen
settings.toggleSystemAppTracking()

detector.updatePrivacySettings(settings)
```

### 5. Performance-Optimierung
```swift
// Performance-Modi
monitor.setHighPerformanceMode()      // Niedrige Latenz
monitor.setBatterySavingMode()        // Akkuschonend
monitor.setPrivacyMode()              // Maximale Privacy

// Eigene Konfiguration
var config = monitor.getConfiguration()
config.detectionInterval = 2.0  // 2 Sekunden
config.enableWindowChangeDetection = false
monitor.updateConfiguration(config)
```

### 6. App-Mapping erweitern
```swift
// Neue App zum Mapping hinzufügen
let customApp = AppTypeDefinition(
    bundleIdentifier: "com.company.customapp",
    displayName: "Custom App",
    category: .productivity
)

// Dynamische App-Definition erstellen
let dynamicApp = SourceAppMapping.createDynamicDefinition(
    for: "com.unknown.app",
    displayName: "Unknown App"
)
```

### 7. Content Parsing
```swift
// App-spezifische Content-Parser verwenden
let browserParser = BrowserContentParser()
let metadata = browserParser.parseContent(
    from: "GitHub - Safari",
    appType: safariDefinition
)
```

### SwiftUI Integration
```swift
struct ContentView: View {
    @StateObject private var detector = SourceAppDetector()
    
    var body: some View {
        SourceAppDetectorView()
            .environmentObject(detector)
    }
}
```

## Wichtige Hinweise

- **Privacy**: Tracking muss explizit aktiviert werden (Opt-in)
- **Accessibility**: Benötigt macOS Accessibility-Berechtigung
- **Performance**: Monitoring verbraucht Ressourcen - Modus anpassen
- **Memory**: Automatische Memory-Optimierung durch History-Limits
- **Error Handling**: Graceful degradation bei fehlenden Berechtigungen

*/
