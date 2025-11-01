import SwiftUI
import AppKit

struct SmartTextInputView: View {
    @StateObject private var coordinator = TextInputCoordinator()
    @State private var text: String = ""
    @State private var isMarkdownPreview = false
    @State private var showingToolbar = true
    
    var body: some View {
        VStack(spacing: 0) {
            if showingToolbar {
                toolbarView
            }
            
            ZStack {
                if isMarkdownPreview {
                    markdownPreviewView
                } else {
                    textEditorView
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .dropDestination(for: String.self) { items, _ in
                coordinator.handleDrop(items: items)
                return true
            }
            
            statusBarView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            coordinator.setup(text: $text)
        }
    }
    
    private var toolbarView: some View {
        HStack(spacing: 12) {
            // Formatierungs-Tools
            Button(action: { coordinator.toggleBold() }) {
                Image(systemName: "bold")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .help("Fett (⌘+B)")
            
            Button(action: { coordinator.toggleItalic() }) {
                Image(systemName: "italic")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .help("Kursiv (⌘+I)")
            
            Divider()
            
            Button(action: { coordinator.insertList() }) {
                Image(systemName: "list.bullet")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .help("Liste erstellen")
            
            Divider()
            
            Button(action: { coordinator.insertLink() }) {
                Image(systemName: "link")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .help("Link einfügen")
            
            Spacer()
            
            // Auto-save Status
            if coordinator.isSaving {
                ProgressView()
                    .scaleEffect(0.7)
                    .help("Speichern...")
            } else if coordinator.lastSaved != nil {
                Text("Gespeichert \(coordinator.timeSinceLastSaved)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            Toggle("Markdown Preview", isOn: $isMarkdownPreview)
                .toggleStyle(.switch)
                .controlSize(.small)
            
            Button(action: { showingToolbar.toggle() }) {
                Image(systemName: "chevron.down.circle")
                    .rotationEffect(.degrees(showingToolbar ? 0 : 180))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private var textEditorView: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .serif))
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled(false)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onChange(of: text) { oldValue, newValue in
                coordinator.handleTextChange(newValue)
            }
            .onDrop(of: [.text, .string], isTargeted: nil) { providers in
                coordinator.handleDrop(providers: providers)
            }
    }
    
    private var markdownPreviewView: some View {
        ScrollView {
            Text(formatMarkdown(text))
                .font(.system(.body, design: .serif))
                .multilineTextAlignment(.leading)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
    
    private var statusBarView: some View {
        HStack {
            // Wortanzahl und Lesedauer
            let stats = coordinator.calculateStats(text)
            Text("\(stats.wordCount) Wörter • \(stats.readingTime) Min. gelesen")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Paste-Erkennung Anzeige
            if coordinator.hasNewPasteContent {
                Label("Neue Inhalte eingefügt", systemImage: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1))
                    .clipShape(Capsule())
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            coordinator.hasNewPasteContent = false
                        }
                    }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private func formatMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        
        // Basis Markdown-Styling
        let regex = try! NSRegularExpression(pattern: "(.*?)([\\*\\*]{1,2})(.*?)\\2(.*?)")
        var attributedText = result
        
        // Hier würde eine vollständige Markdown-Parser-Implementierung stehen
        // Für das Beispiel ein vereinfachter Ansatz
        return attributedText
    }
}

#Preview {
    SmartTextInputView()
        .frame(width: 800, height: 600)
}