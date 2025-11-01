//
//  VoiceInputGlassComponents.swift
//  Erweiterte Glass-Effekt Komponenten für Voice Input
//
//  Erstellt am 31.10.2025
//  Speziell optimiert für Speech Recognition UI
//

import SwiftUI

// MARK: - Voice Input Glass Cards
struct VoiceInputGlassCard<Content: View>: View {
    let content: Content
    let isActive: Bool
    let intensity: CGFloat
    
    init(isActive: Bool = false, intensity: CGFloat = 0.3, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.intensity = intensity
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isActive ? Color.blue.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                            .shadow(color: isActive ? .blue.opacity(0.3) : .clear, radius: 10)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
            .scaleEffect(isActive ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
    }
}

// MARK: - Voice Recognition Status Indicator
struct VoiceRecognitionStatusIndicator: View {
    let status: RecognitionStatus
    let pulseAnimation: Bool
    
    enum RecognitionStatus {
        case listening
        case processing
        case idle
        case error
        
        var color: Color {
            switch self {
            case .listening:
                return .green
            case .processing:
                return .blue
            case .idle:
                return .gray
            case .error:
                return .red
            }
        }
        
        var icon: String {
            switch self {
            case .listening:
                return "mic.fill"
            case .processing:
                return "cpu.fill"
            case .idle:
                return "mic.circle"
            case .error:
                return "exclamationmark.triangle.fill"
            }
        }
    }
    
    init(status: RecognitionStatus, pulseAnimation: Bool = false) {
        self.status = status
        self.pulseAnimation = pulseAnimation
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                if pulseAnimation && status == .listening {
                    Circle()
                        .stroke(status.color, lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .opacity(pulseOpacity)
                        .scaleEffect(pulseScale)
                }
                
                Image(systemName: status.icon)
                    .font(.title2)
                    .foregroundStyle(status.color)
                    .scaleEffect(status == .listening && pulseAnimation ? 1.1 : 1.0)
            }
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: status == .listening && pulseAnimation)
            
            Text(statusLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var pulseOpacity: Double {
        pulseAnimation ? 0.0 : 1.0
    }
    
    private var pulseScale: CGFloat {
        pulseAnimation ? 1.4 : 1.0
    }
    
    private var statusLabel: String {
        switch status {
        case .listening:
            return "Hört zu"
        case .processing:
            return "Verarbeitung..."
        case .idle:
            return "Bereit"
        case .error:
            return "Fehler"
        }
    }
}

// MARK: - Confidence Meter
struct ConfidenceMeter: View {
    let confidence: Float
    let showPercentage: Bool
    
    init(confidence: Float, showPercentage: Bool = true) {
        self.confidence = confidence
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Erkennungsgenauigkeit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    if showPercentage {
                        Text("\(Int(confidence * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(confidenceColor)
                    }
                    
                    ConfidenceBar(confidence: confidence)
                }
            }
            
            Spacer()
        }
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        case 0.4..<0.6:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Confidence Bar Component
struct ConfidenceBar: View {
    let confidence: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(confidenceGradient)
                    .frame(width: max(geometry.size.width * CGFloat(confidence), 2), height: 6)
                    .shadow(color: confidenceColor.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .frame(height: 6)
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        case 0.4..<0.6:
            return .orange
        default:
            return .red
        }
    }
    
    private var confidenceGradient: LinearGradient {
        LinearGradient(
            colors: [confidenceColor.opacity(0.7), confidenceColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Language Selector Card
struct LanguageSelectorCard: View {
    let currentLanguage: String
    let supportedLanguages: [String: String]
    let onLanguageSelect: (String) -> Void
    
    var body: some View {
        VoiceInputGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)
                    
                    Text("Sprache")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    LanguageBadge(languageCode: currentLanguage, languageName: supportedLanguages[currentLanguage] ?? "")
                }
                
                HStack {
                    ForEach(Array(supportedLanguages.keys.prefix(3)), id: \.self) { langCode in
                        LanguageChip(
                            languageCode: langCode,
                            languageName: supportedLanguages[langCode] ?? "",
                            isSelected: langCode == currentLanguage,
                            action: { onLanguageSelect(langCode) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Language Badge
struct LanguageBadge: View {
    let languageCode: String
    let languageName: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(flag(for: languageCode))
                .font(.caption)
            
            Text(languageName)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    private func flag(for languageCode: String) -> String {
        let base = languageCode.prefix(2).unicodeScalars
        let indicatorScalar = UnicodeScalar(0x1F1E6)!
        let regionalIndicatorScalar = UnicodeScalar(0x1F1E7)!
        
        let flag = base.map { scalar in
            indicatorScalar + UnicodeScalar(scalar.value - 65 + 0x41)!
        }
        return String(flag)
    }
}

// MARK: - Language Chip
struct LanguageChip: View {
    let languageCode: String
    let languageName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(flag(for: languageCode))
                    .font(.caption)
                
                Text(languageName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func flag(for languageCode: String) -> String {
        let base = languageCode.prefix(2).unicodeScalars
        let indicatorScalar = UnicodeScalar(0x1F1E6)!
        let regionalIndicatorScalar = UnicodeScalar(0x1F1E7)!
        
        let flag = base.map { scalar in
            indicatorScalar + UnicodeScalar(scalar.value - 65 + 0x41)!
        }
        return String(flag)
    }
}

// MARK: - Privacy Control Card
struct PrivacyControlCard: View {
    let isPrivacyModeEnabled: Bool
    let onPrivacyToggle: (Bool) -> Void
    let onClearHistory: () -> Void
    
    var body: some View {
        VoiceInputGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: isPrivacyModeEnabled ? "lock.fill" : "lock.open")
                        .foregroundStyle(isPrivacyModeEnabled ? .green : .orange)
                    
                    Text("Privacy Kontrollen")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Privacy Mode")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        Text("Lokale Verarbeitung aktiviert")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { isPrivacyModeEnabled },
                        set: { onPrivacyToggle($0) }
                    ))
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                Button(action: onClearHistory) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                        
                        Text("Verlauf löschen")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Audio Level Indicator
struct AudioLevelIndicator: View {
    let level: Float
    let isActive: Bool
    
    init(level: Float, isActive: Bool = false) {
        self.level = level
        self.isActive = isActive
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Audio Level")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 4) {
                ForEach(0..<10) { index in
                    Rectangle()
                        .fill(level >= Float(index) * 0.1 ? audioLevelColor : Color.gray.opacity(0.3))
                        .frame(width: 4, height: CGFloat.random(in: 10...30))
                        .cornerRadius(2)
                        .scaleEffect(isActive ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.1).delay(Double(index) * 0.05),
                            value: isActive && level >= Float(index) * 0.1
                        )
                }
            }
            .frame(maxWidth: 100)
        }
    }
    
    private var audioLevelColor: Color {
        switch level {
        case 0..<0.3:
            return .green
        case 0.3..<0.6:
            return .yellow
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Transcription Card
struct TranscriptionCard: View {
    let text: String
    let isEmpty: Bool
    let onClear: () -> Void
    
    var body: some View {
        VoiceInputGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "text.bubble.fill")
                        .foregroundStyle(.blue)
                    
                    Text("Transkription")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if !isEmpty {
                        Button(action: onClear) {
                            Image(systemName: "trash.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                ScrollView {
                    Text(isEmpty ? "Warte auf Spracheingabe..." : text)
                        .font(.body)
                        .foregroundStyle(isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .animation(.easeInOut, value: text)
                }
                .frame(minHeight: 80, maxHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.05))
                )
            }
        }
    }
}

// MARK: - Voice Activity Card
struct VoiceActivityCard: View {
    let isDetected: Bool
    let confidence: Float
    let language: String
    
    var body: some View {
        VoiceInputGlassCard(isActive: isDetected) {
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(isDetected ? .green : .gray)
                        .frame(width: 8, height: 8)
                    
                    Text("Sprachaktivität")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(isDetected ? "Aktiv" : "Inaktiv")
                        .font(.caption)
                        .foregroundStyle(isDetected ? .green : .gray)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(confidence * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Sprache")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(language)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Actions Grid
struct QuickActionsGrid: View {
    let actions: [QuickAction]
    
    struct QuickAction {
        let icon: String
        let title: String
        let action: () -> Void
        let color: Color
    }
    
    var body: some View {
        VoiceInputGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(actions.indices, id: \.self) { index in
                        let action = actions[index]
                        QuickActionButton(
                            icon: action.icon,
                            title: action.title,
                            color: action.color,
                            action: action.action
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct VoiceInputGlassComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                VoiceInputGlassCard {
                    Text("Voice Input Card")
                }
                
                VoiceRecognitionStatusIndicator(status: .listening, pulseAnimation: true)
                
                ConfidenceMeter(confidence: 0.85)
                
                LanguageSelectorCard(
                    currentLanguage: "de-DE",
                    supportedLanguages: [
                        "de-DE": "Deutsch",
                        "en-US": "English",
                        "fr-FR": "Français"
                    ]
                ) { _ in }
                
                PrivacyControlCard(isPrivacyModeEnabled: true) { _ in } onClearHistory: { }
                
                AudioLevelIndicator(level: 0.4, isActive: true)
                
                TranscriptionCard(text: "Dies ist ein Test der Transkriptionsfunktion.", isEmpty: false) { }
                
                VoiceActivityCard(isDetected: true, confidence: 0.9, language: "Deutsch")
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
    }
}