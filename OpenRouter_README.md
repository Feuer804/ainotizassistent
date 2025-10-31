# OpenRouter API Integration - Quick Start

## Übersicht

Umfassende OpenRouter API Integration für Swift-basierte LLM-Anwendungen mit erweiterten Features für Enterprise-Anwendungen.

## Dateien

### 1. OpenRouterClient.swift
- **Hauptklasse für OpenRouter API**
- Model Management und dynamisches Laden
- Cost Tracking pro Modell
- Performance Monitoring
- Failover-Strategien
- Load Balancing
- Batch Processing

### 2. LLMProvider.swift
- **Unified Interface für alle LLM-Provider**
- OpenAI, OpenRouter, Anthropic Unterstützung
- Intelligente Model Selection
- Provider-Abstraktion
- Cross-Provider Analytics

## Schnellstart

```swift
import Foundation

// OpenRouter Client initialisieren
let client = OpenRouterClient.shared

// Models laden
await client.loadModels()

// Chat Message senden
let messages = [["role": "user", "content": "Hallo!"]]
let response = try await client.sendChatMessage(messages: messages)
print(response.choices.first?.message.content ?? "")

// Mit Unified Provider
let unifiedProvider = UnifiedLLMProvider.shared
let task = LLMTask.analysis
let model = unifiedProvider.selectOptimalModel(for: task)
let request = LLMRequest(prompt: "Analysiere...", model: model!)
let response = try await unifiedProvider.generateResponse(for: request)
```

## Hauptfeatures

### ✅ Model Selection
- Dynamisches Laden von OpenRouter Models
- Filterung nach Provider und Capabilities
- Intelligente Modellauswahl

### ✅ Cost Tracking
- Detaillierte Kostenverfolgung pro Modell
- Usage Analytics mit Zeiträumen
- Cost-Optimierungsvorschläge

### ✅ Failover Mechanisms
- Round Robin, Least Latency, Most Reliable, Cost Optimized
- Custom Failover-Strategien
- Automatische Provider-Wechsel

### ✅ Load Balancing
- Intelligentes Load Balancing zwischen Providers
- Request-Count Tracking
- Performance-basierte Auswahl

### ✅ Performance Monitoring
- Response Time Tracking
- Success Rate Monitoring
- Quality Score Berechnung
- Tokens-per-Second Messungen

### ✅ Custom Headers & Authentication
- API Key Management
- Custom Headers Support
- HTTP-Referer und X-Title
- Rate Limiting (100 Requests/Minute)

### ✅ Batch Processing
- Batch-Requests Support
- Concurrent Processing
- Chunked Processing
- Batch-Response-Aggregation

### ✅ Usage Analytics
- Cross-Provider Analytics
- Cost-Efficiency Tracking
- Performance-Vergleiche
- Optimierungsempfehlungen

## API-Key Setup

```bash
# In Environment Variables setzen:
OPENROUTER_API_KEY=your_api_key_here
OPENAI_API_KEY=your_openai_key_here
ANTHROPIC_API_KEY=your_anthropic_key_here
```

## Erweiterte Beispiele

### Failover mit mehreren Modellen
```swift
let preferredModels = [gpt4Model, claudeModel, llamaModel]
let response = try await client.sendWithFailover(
    messages: messages,
    preferredModels: preferredModels
)
```

### Batch Processing
```swift
let batchRequests = [
    BatchRequest(requests: batchMessages, model: selectedModel)
]
let results = try await client.processBatchRequests(batchRequests)
```

### Analytics
```swift
let analytics = client.getUsageAnalytics()
for (modelId, stats) in analytics {
    print("Cost: $\(stats.totalCost), Tokens: \(stats.totalTokens)")
}
```

## Dokumentation

Vollständige Dokumentation in `OpenRouter_Implementierungshandbuch.md`

## Unterstützte Provider

- ✅ **OpenRouter** (Vollständig implementiert)
- ✅ **OpenAI** (Grundlegende Integration)
- 🔄 **Anthropic** (Vorbereitet)
- 🔄 **Hugging Face** (Geplant)
- 🔄 **Cohere** (Geplant)

## Lizenz

MIT License - Frei für kommerzielle und private Nutzung.

---

**Status:** ✅ Produktionsreif  
**Letzte Aktualisierung:** 2025-10-31  
**Version:** 1.0.0