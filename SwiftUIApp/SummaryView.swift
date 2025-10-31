import SwiftUI

struct SummaryView: View {
    @State private var sourceText = ""
    @State private var summaryLength: SummaryLength = .kurz
    @State private var showingSummary = false
    @State private var generatedSummary = ""
    @State private var isGenerating = false
    
    let summaryLengths: [SummaryLength] = [.kurz, .mittel, .ausführlich]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Zusammenfassung")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Erstelle automatische Zusammenfassungen aus deinem Text")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top)
                
                // Eingabe Bereich
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Quelltext")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(sourceText.count) Zeichen")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    ZStack {
                        if sourceText.isEmpty {
                            PlaceholderTextEditor(
                                placeholder: "Füge hier den Text ein, den du zusammenfassen möchtest. Du kannst Artikel, Notizen, Dokumente oder andere längere Texte hier einfügen..."
                            )
                            .disabled(true)
                            .overlay {
                                PlaceholderText("Gib den zu zusammenfassenden Text ein...")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        TextEditor(text: $sourceText)
                            .frame(minHeight: 200)
                            .opacity(sourceText.isEmpty ? 0 : 1)
                            .scrollContentBackground(.hidden)
                            .font(.body)
                            .foregroundColor(.white)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.sentences)
                }
                
                // Zusammenfassungseinstellungen
                VStack(alignment: .leading, spacing: 12) {
                    Text("Zusammenfassungslänge")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(summaryLengths, id: \.self) { length in
                            LengthOptionCard(
                                length: length,
                                isSelected: summaryLength == length
                            ) {
                                withAnimation(.spring()) {
                                    summaryLength = length
                                }
                            }
                        }
                    }
                }
                
                // Action Button
                Button(action: generateSummary) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        
                        Text(isGenerating ? "Erstelle Zusammenfassung..." : "Zusammenfassung erstellen")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 4)
                    .disabled(sourceText.isEmpty || isGenerating)
                }
                .disabled(sourceText.isEmpty || isGenerating)
                
                // Zusammenfassung Anzeige
                if showingSummary {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Deine Zusammenfassung")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: copySummary) {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        ScrollView {
                            Text(generatedSummary)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(4)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .frame(minHeight: 150)
                        
                        // Action Buttons für Zusammenfassung
                        HStack(spacing: 12) {
                            Button(action: {
                                withAnimation(.spring()) {
                                    showingSummary = false
                                }
                            }) {
                                Text("Neu erstellen")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.white.opacity(0.15))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: saveSummary) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                    Text("Speichern")
                                }
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.8), Color.pink.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .background(.clear)
    }
    
    func generateSummary() {
        isGenerating = true
        
        // Simuliere API-Aufruf
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let wordCount = sourceText.split(separator: " ").count
            let targetWords: Int
            
            switch summaryLength {
            case .kurz: targetWords = 50
            case .mittel: targetWords = 100
            case .ausführlich: targetWords = 200
            }
            
            let preview = sourceText.prefix(targetWords * 5)
            generatedSummary = """
            \(summaryLength.title) Zusammenfassung:
            
            \(preview.description)
            
            Diese Zusammenfassung fasst die wichtigsten Punkte aus dem eingegebenen Text in \(summaryLength.title.lowercased()) Form zusammen.
            """
            
            isGenerating = false
            showingSummary = true
        }
    }
    
    func copySummary() {
        // Copy to clipboard functionality
        UIPasteboard.general.string = generatedSummary
    }
    
    func saveSummary() {
        // Save to local storage or cloud
    }
}

// Summary Length Enum
enum SummaryLength: String, CaseIterable {
    case kurz = "Kurz"
    case mittel = "Mittel"
    case ausführlich = "Ausführlich"
    
    var title: String {
        switch self {
        case .kurz: return "Kurze"
        case .mittel: return "Mittlere"
        case .ausführlich: return "Ausführliche"
        }
    }
}

// Length Option Card Komponente
struct LengthOptionCard: View {
    let length: SummaryLength
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: lengthIcon(length))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Text(length.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Text(lengthDescription(length))
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                .white.opacity(0.1)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .white.opacity(0.4) : .white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? .white.opacity(0.1) : .clear, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func lengthIcon(_ length: SummaryLength) -> String {
        switch length {
        case .kurz: return "rectangle.inset.filled.badge.record"
        case .mittel: return "rectangle.split.2x1"
        case .ausführlich: return "rectangle.split.3x1"
        }
    }
    
    func lengthDescription(_ length: SummaryLength) -> String {
        switch length {
        case .kurz: return "50-100 Wörter"
        case .mittel: return "100-200 Wörter"
        case .ausführlich: return "200-400 Wörter"
        }
    }
}

// Placeholder TextEditor für leeren Zustand
struct PlaceholderTextEditor: UIViewRepresentable {
    let placeholder: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = UIColor.clear
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.textColor = UIColor.white.withAlphaComponent(0.3)
        textView.text = placeholder
        textView.isEditable = false
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = placeholder
    }
}

struct PlaceholderText: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.body)
            .foregroundColor(.white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SummaryView()
        .preferredColorScheme(.dark)
}