# OpenRouter API Integration - Implementierungshandbuch

## Übersicht

Diese Implementierung bietet eine umfassende OpenRouter API Integration mit erweiterten Features für intelligentes LLM-Management, Cost-Tracking, Performance-Monitoring und Load-Balancing.

## Hauptkomponenten

### 1. OpenRouterClient.swift

Die Hauptklasse für die OpenRouter API-Integration mit folgenden Features:

#### Model Management
- Dynamisches Laden verfügbarer Modelle von OpenRouter
- Modellfilterung nach Provider und Capabilities
- Intelligente Modellauswahl basierend auf Task-Anforderungen

#### Cost Tracking
- Detaillierte Kostenverfolgung pro Modell
- Automatische Kostenberechnung basierend auf Token-Verbrauch
- Usage-Analytics mit Zeiträumen
- Cost-Optimierungsvorschläge

#### Performance Monitoring
- Response-Time Tracking
- Success-Rate Monitoring
- Tokens-per-Second Messungen
- Quality-Score Berechnung

#### Failover & Load Balancing
- Multiple Failover-Strategien:
  - Round Robin
  - Least Latency
  - Most Reliable
  - Cost Optimized
  - Custom Strategies
- Intelligentes Load Balancing
- Automatische Provider-Wechsel bei Fehlern

#### Batch Processing
- Unterstützung für Batch-Requests
- Concurrent Processing mit Rate-Limiting
- Chunked Processing für große Anfragen
- Batch-Response-Aggregation

#### API Features
- Custom Headers und Authentication
- Rate-Limit-Management (100 Requests/Minute)
- Retry-Logic mit Exponential Backoff
- Streaming-Support (geplant)

### 2. LLMProvider.swift

Unified Interface für multiple LLM-Provider:

#### Provider Abstraktion
- Einheitliche API für OpenAI, OpenRouter, Anthropic
- Provider-spezifische Implementierungen
- Plugin-Architecture für neue Provider

#### Intelligente Model Selection
- Task-basierte Modellauswahl
- Multi-Kriterien Optimierung (Cost, Performance, Capabilities)
- Provider-Preference Handling

#### Unified Request/Response System
- Standardisierte Request/Response-Formate
- Capabilities-basierte Filterung
- Quality-Assessment

#### Analytics & Optimization
- Cross-Provider Usage Analytics
- Cost-Efficiency Tracking
- Performance-Vergleiche
- Optimierungsempfehlungen

## Verwendung

### Basis-Setup

```swift
import Foundation

// OpenRouter Client initialisieren
let openRouterClient = OpenRouterClient.shared

// Models laden
await openRouterClient.loadModels()

// Verfügbare Models anzeigen
let models = openRouterClient.availableModels
print("Verfügbare Models: \(models.count)")

// Modell auswählen
if let gpt4Model = models.first(where: { $0.id.contains("gpt-4") }) {
    openRouterClient.selectedModel = ModelConfig.from(gpt4Model)
}
```

### Chat Completion

```swift
// Einzelne Nachricht senden
let messages = [
    ["role": "system", "content": "Du bist ein hilfreicher Assistent."],
    ["role": "user", "content": "Erkläre mir Künstliche Intelligenz."]
]

do {
    let response = try await openRouterClient.sendChatMessage(
        messages: messages,
        temperature: 0.7,
        maxTokens: 1000
    )
    
    print("Antwort: \(response.choices.first?.message.content ?? "")")
    
} catch {
    print("Fehler: \(error)")
}
```

### Failover-Handling

```swift
// Mit Failover-Strategie
let preferredModels = [
    ModelConfig.from(gpt4Model),
    ModelConfig.from(claudeModel),
    ModelConfig.from(llamaModel)
]

do {
    let response = try await openRouterClient.sendWithFailover(
        messages: messages,
        preferredModels: preferredModels
    )
    print("Erfolgreich mit Failover")
} catch {
    print("Alle Modelle fehlgeschlagen: \(error)")
}
```

### Batch Processing

```swift
// Batch-Requests
let batchRequests = [
    BatchRequest(
        requests: [
            BatchRequest.ChatMessage(role: "user", content: "Frage 1"),
            BatchRequest.ChatMessage(role: "user", content: "Frage 2")
        ],
        model: selectedModel,
        temperature: 0.7,
        maxTokens: 500
    )
]

let batchResults = try await openRouterClient.processBatchRequests(batchRequests)

for result in batchResults {
    print("Batch \(result.id): \(result.responses.count) Antworten")
    print("Kosten: $\(result.totalCost)")
}
```

### Unified LLM Provider

```swift
// Unified Provider verwenden
let unifiedProvider = UnifiedLLMProvider.shared

// Task definieren
let analysisTask = LLMTask(
    type: .analysis,
    description: "Analyze customer feedback",
    requiredCapabilities: [.analysis, .reasoning],
    optimizationStrategy: .performance,
    maxCostThreshold: 0.002,
    maxResponseTime: 4.0
)

// Optimal Model auswählen
if let optimalModel = unifiedProvider.selectOptimalModel(for: analysisTask) {
    print("Ausgewähltes Modell: \(optimalModel.displayName)")
    
    // Request erstellen
    let request = LLMRequest(
        prompt: "Analysiere diese Kundenbewertung...",
        systemPrompt: "Du bist ein Experte für Kundenanalyse.",
        model: optimalModel,
        capabilities: [.analysis, .reasoning]
    )
    
    // Response generieren
    let response = try await unifiedProvider.generateResponse(for: request)
    print("Response: \(response.content)")
    print("Quality Score: \(response.qualityScore)")
    print("Cost Efficiency: \(response.costEfficiency)")
}
```

### Analytics & Monitoring

```swift
// Usage Analytics
let analytics = openRouterClient.getUsageAnalytics()
for (modelId, stats) in analytics {
    print("Model: \(modelId)")
    print("  Total Cost: $\(stats.totalCost)")
    print("  Total Tokens: \(stats.totalTokens)")
    print("  Cost per 1K tokens: $\(stats.avgCostPer1kTokens)")
}

// Performance Monitoring
let performance = openRouterClient.performanceMonitor.getAveragePerformance(for: "openai/gpt-4")
print("Avg Response Time: \(performance.avgResponseTime) seconds")
print("Success Rate: \(performance.successRate * 100)%")

// Cost-optimierte Models
let costOptimized = openRouterClient.getCostOptimizedModels()
print("Most cost-efficient models: \(costOptimized.map { $0.displayName })")
```

## Erweiterte Features

### Custom Headers

```swift
let customHeaders = [
    "X-Custom-Header": "custom-value",
    "X-Request-ID": UUID().uuidString
]

let response = try await openRouterClient.sendChatMessage(
    messages: messages,
    customHeaders: customHeaders
)
```

### Provider-spezifische Konfigurationen

```swift
// Provider Manager konfigurieren
let providerManager = ProviderManager()

// Provider aktivieren/deaktivieren
providerManager.refreshAvailableProviders()

// Modell-Filterung
let codingModels = openRouterClient.getModels(byCapability: "coding")
let fastModels = openRouterClient.getModels(byCapability: "fast")
let multimodalModels = openRouterClient.getModels(byCapability: "multimodal")
```

### Batch Analytics

```swift
// Cross-Provider Analytics
let providerAnalytics = unifiedProvider.getUsageAnalytics(provider: .openrouter)
for (model, stats) in providerAnalytics {
    print("Model: \(model.displayName)")
    print("  Total Cost: $\(stats.totalCost)")
    print("  Avg Response Time: \(stats.avgResponseTime)")
    print("  Success Rate: \(stats.successRate * 100)%")
}

// Cost Optimierung
let optimizedModels = unifiedProvider.optimizeCosts(threshold: 0.001)
print("Models under $0.001 per 1K tokens: \(optimizedModels.count)")

// Top Performer
let topPerformers = unifiedProvider.getTopPerformingModels(limit: 5)
print("Top 5 performing models: \(topPerformers.map { $0.displayName })")
```

## Konfiguration

### Environment Variables

```bash
# Erforderlich
OPENROUTER_API_KEY=your_openrouter_api_key_here
OPENAI_API_KEY=your_openai_api_key_here

# Optional
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

### Model Configuration

Modelle werden automatisch von OpenRouter geladen. Für statische Konfiguration:

```swift
let customModel = ModelConfig(
    id: "openai/gpt-4",
    name: "GPT-4",
    provider: "openai",
    contextLength: 8192,
    maxTokens: 4096,
    temperature: 0.7,
    topP: 0.9
)
```

## Best Practices

### 1. Rate Limiting
- Verwenden Sie die eingebaute Rate-Limit-Funktionalität
- Implementieren Sie Exponential Backoff für Retries
- Monitoring der API-Nutzung

### 2. Cost Management
- Nutzen Sie Cost-Tracking für Budget-Überwachung
- Wählen Sie Modelle basierend auf Cost-Efficiency
- Implementieren Sie Budget-Alerts

### 3. Performance Optimization
- Verwenden Sie Performance-Monitoring für Modell-Selektion
- Implementieren Sie Failover-Strategien
- Monitoring von Response-Times und Success-Rates

### 4. Error Handling
- Implementieren Sie umfassendes Error-Handling
- Nutzen Sie Failover-Mechanismen
- Logging und Monitoring von Fehlern

### 5. Security
- Sichere API-Key Verwaltung
- Custom Headers für Tracking
- Rate-Limit-Compliance

## Erweiterte Anwendungsfälle

### Content Processing Pipeline

```swift
func processContentPipeline(_ content: String) async throws -> ProcessedContent {
    let summarizationTask = LLMTask(
        type: .summarization,
        description: "Summarize content",
        requiredCapabilities: [.summarization, .textGeneration],
        optimizationStrategy: .cost
    )
    
    let analysisTask = LLMTask(
        type: .analysis,
        description: "Analyze content",
        requiredCapabilities: [.analysis, .reasoning],
        optimizationStrategy: .performance
    )
    
    let optimalSummarizer = unifiedProvider.selectOptimalModel(for: summarizationTask)
    let optimalAnalyzer = unifiedProvider.selectOptimalModel(for: analysisTask)
    
    let summaryRequest = LLMRequest(
        prompt: "Summarize: \(content)",
        model: optimalSummarizer!,
        capabilities: [.summarization]
    )
    
    let analysisRequest = LLMRequest(
        prompt: "Analyze: \(content)",
        model: optimalAnalyzer!,
        capabilities: [.analysis]
    )
    
    let batchRequests = [summaryRequest, analysisRequest]
    let responses = try await unifiedProvider.processBatch(requests: batchRequests)
    
    return ProcessedContent(
        summary: responses[0].content,
        analysis: responses[1].content,
        metadata: [
            "summaryModel": optimalSummarizer!.displayName,
            "analysisModel": optimalAnalyzer!.displayName,
            "totalCost": responses[0].usage.cost + responses[1].usage.cost
        ]
    )
}
```

### Multi-Provider Routing

```swift
func routeToOptimalProvider(task: LLMTask) async throws -> LLMResponse {
    // Teste verschiedene Provider
    let providers: [ProviderType] = [.openrouter, .openai, .anthropic]
    var bestResponse: LLMResponse?
    var bestScore = 0.0
    
    for provider in providers {
        let model = unifiedProvider.selectOptimalModel(
            for: task, 
            preferredProvider: provider
        )
        
        if let model = model {
            let request = LLMRequest(
                prompt: "Task: \(task.description)",
                model: model,
                capabilities: task.requiredCapabilities
            )
            
            do {
                let response = try await unifiedProvider.generateResponse(for: request)
                let score = response.qualityScore / response.usage.cost
                
                if score > bestScore {
                    bestScore = score
                    bestResponse = response
                }
            } catch {
                print("Provider \(provider) failed: \(error)")
                continue
            }
        }
    }
    
    guard let bestResponse = bestResponse else {
        throw LLMError.allModelsFailed(underlyingError: nil)
    }
    
    return bestResponse
}
```

## Monitoring und Debugging

### Performance Monitoring

```swift
// Model Performance Tracking
let modelId = "openai/gpt-4"
let performance = openRouterClient.performanceMonitor.getAveragePerformance(
    for: modelId, 
    lastNSamples: 50
)

print("Model Performance:")
print("  Average Response Time: \(performance.avgResponseTime) seconds")
print("  Success Rate: \(performance.successRate * 100)%")
print("  Average Tokens/Second: \(performance.avgTokensPerSecond)")
```

### Cost Monitoring

```swift
// Daily Cost Tracking
let today = Calendar.current.startOfDay(for: Date())
let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
let weekInterval = DateInterval(start: weekAgo, end: today)

let weeklyCosts = openRouterClient.getUsageAnalytics(period: weekInterval)
for (modelId, costs) in weeklyCosts {
    print("Model \(modelId) - This Week:")
    print("  Total Cost: $\(String(format: "%.4f", costs.totalCost))")
    print("  Total Tokens: \(costs.totalTokens)")
    print("  Average Cost per 1K tokens: $\(String(format: "%.4f", costs.avgCostPer1kTokens))")
}
```

## Fazit

Diese Implementierung bietet eine robuste, skalierbare Lösung für OpenRouter API-Integration mit erweiterten Features für Enterprise-Anwendungen. Die modulare Architektur ermöglicht einfache Erweiterungen und Anpassungen an spezifische Anforderungen.

### Hauptvorteile:
1. **Unified Interface** - Einfache Verwendung verschiedener LLM-Provider
2. **Intelligent Routing** - Automatische Modellauswahl basierend auf Task-Anforderungen
3. **Cost Optimization** - Detailliertes Cost-Tracking und Optimierung
4. **Performance Monitoring** - Umfassende Performance-Metriken
5. **Failover Mechanisms** - Robuste Fehlerbehandlung mit Failover
6. **Batch Processing** - Effiziente Batch-Verarbeitung
7. **Scalability** - Unterstützung für hohe Request-Volumen

Diese Lösung ist produktionsreif und kann als Basis für komplexe LLM-Anwendungen verwendet werden.