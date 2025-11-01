//
//  ContentGenerationViews.swift
//  AINotizassistent
//
//  Created by Claude on 2025-10-31.
//  SwiftUI Views für OpenAI Content Generation
//

import SwiftUI

// MARK: - Main Content Generation Tab View

struct ContentGenerationView: View {
    var body: some View {
        TabView {
            EmailGenerationView()
                .tabItem {
                    Image(systemName: "envelope")
                    Text("E-Mail")
                }
            
            MeetingGenerationView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Meeting")
                }
            
            ArticleGenerationView()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Artikel")
                }
            
            ChatView()
                .tabItem {
                    Image(systemName: "chat.bubble")
                    Text("Chat")
                }
        }
    }
}

// MARK: - Email Generation View

struct EmailGenerationView: View {
    @StateObject private var viewModel = EmailGenerationViewModel()
    @State private var showingTypeSelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Input Section
                ScrollView {
                    VStack(spacing: 16) {
                        // Email Type Selection
                        Button(action: {
                            showingTypeSelection = true
                        }) {
                            HStack {
                                Text("E-Mail Typ: \(emailTypeDisplayName(viewModel.emailType))")
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding()
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .sheet(isPresented: $showingTypeSelection) {
                            EmailTypeSelectionView(selectedType: $viewModel.emailType)
                                .presentationDetents([.medium])
                        }
                        
                        // Input Text Area
                        VStack(alignment: .leading, spacing: 8) {
                            Text("E-Mail Inhalt beschreiben")
                                .font(.headline)
                            
                            TextEditor(text: $viewModel.inputText)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                        }
                        
                        // Generate Button
                        Button(action: {
                            viewModel.generateEmail()
                        }) {
                            HStack {
                                if viewModel.isGenerating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(viewModel.isGenerating ? "Wird generiert..." : "E-Mail generieren")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Output Section
                if !viewModel.generatedEmail.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Generierte E-Mail")
                                    .font(.headline)
                                Spacer()
                                Button("Kopieren") {
                                    UIPasteboard.general.string = viewModel.generatedEmail
                                }
                            }
                            
                            TextEditor(text: .constant(viewModel.generatedEmail))
                                .frame(minHeight: 200)
                                .padding(8)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                            
                            HStack {
                                Button("Neu generieren") {
                                    viewModel.generateEmail()
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Alles löschen") {
                                    viewModel.clearAll()
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                
                                Spacer()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("E-Mail Generator")
        }
    }
    
    private func emailTypeDisplayName(_ type: EmailType) -> String {
        switch type {
        case .general: return "Allgemein"
        case .business: return "Geschäftlich"
        case .support: return "Support"
        case .marketing: return "Marketing"
        case .followUp: return "Nachfrage"
        case .thankYou: return "Danksagung"
        }
    }
}

// MARK: - Meeting Generation View

struct MeetingGenerationView: View {
    @StateObject private var viewModel = MeetingGenerationViewModel()
    @State private var showingTypeSelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Input Section
                ScrollView {
                    VStack(spacing: 16) {
                        // Meeting Type Selection
                        Button(action: {
                            showingTypeSelection = true
                        }) {
                            HStack {
                                Text("Meeting Typ: \(meetingTypeDisplayName(viewModel.meetingType))")
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding()
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .sheet(isPresented: $showingTypeSelection) {
                            MeetingTypeSelectionView(selectedType: $viewModel.meetingType)
                                .presentationDetents([.medium])
                        }
                        
                        // Input Text Area
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meeting Details beschreiben")
                                .font(.headline)
                            
                            TextEditor(text: $viewModel.inputText)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                        }
                        
                        // Generate Button
                        Button(action: {
                            viewModel.generateMeeting()
                        }) {
                            HStack {
                                if viewModel.isGenerating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "person.3")
                                }
                                Text(viewModel.isGenerating ? "Wird generiert..." : "Meeting Notizen generieren")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Output Section
                if !viewModel.generatedMeeting.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Meeting Notizen")
                                    .font(.headline)
                                Spacer()
                                Button("Kopieren") {
                                    UIPasteboard.general.string = viewModel.generatedMeeting
                                }
                            }
                            
                            TextEditor(text: .constant(viewModel.generatedMeeting))
                                .frame(minHeight: 200)
                                .padding(8)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                            
                            HStack {
                                Button("Neu generieren") {
                                    viewModel.generateMeeting()
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Alles löschen") {
                                    viewModel.clearAll()
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                
                                Spacer()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Meeting Generator")
        }
    }
    
    private func meetingTypeDisplayName(_ type: MeetingType) -> String {
        switch type {
        case .general: return "Allgemein"
        case .project: return "Projekt"
        case .planning: return "Planung"
        case .review: return "Review"
        case .brainstorming: return "Brainstorming"
        }
    }
}

// MARK: - Article Generation View

struct ArticleGenerationView: View {
    @StateObject private var viewModel = ArticleGenerationViewModel()
    @State private var showingTypeSelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Input Section
                ScrollView {
                    VStack(spacing: 16) {
                        // Article Type Selection
                        Button(action: {
                            showingTypeSelection = true
                        }) {
                            HStack {
                                Text("Artikel Typ: \(articleTypeDisplayName(viewModel.articleType))")
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding()
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .sheet(isPresented: $showingTypeSelection) {
                            ArticleTypeSelectionView(selectedType: $viewModel.articleType)
                                .presentationDetents([.medium])
                        }
                        
                        // Input Text Area
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Artikel Thema beschreiben")
                                .font(.headline)
                            
                            TextEditor(text: $viewModel.inputText)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                        }
                        
                        // Generate Button
                        Button(action: {
                            viewModel.generateArticle()
                        }) {
                            HStack {
                                if viewModel.isGenerating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "doc.text")
                                }
                                Text(viewModel.isGenerating ? "Wird generiert..." : "Artikel generieren")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Output Section
                if !viewModel.generatedArticle.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Generierter Artikel")
                                    .font(.headline)
                                Spacer()
                                Button("Kopieren") {
                                    UIPasteboard.general.string = viewModel.generatedArticle
                                }
                            }
                            
                            TextEditor(text: .constant(viewModel.generatedArticle))
                                .frame(minHeight: 300)
                                .padding(8)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                            
                            HStack {
                                Button("Neu generieren") {
                                    viewModel.generateArticle()
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Alles löschen") {
                                    viewModel.clearAll()
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                
                                Spacer()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Artikel Generator")
        }
    }
    
    private func articleTypeDisplayName(_ type: ArticleType) -> String {
        switch type {
        case .general: return "Allgemein"
        case .technical: return "Technisch"
        case .blog: return "Blog"
        case .news: return "News"
        case .tutorial: return "Tutorial"
        }
    }
}

// MARK: - Chat View

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                Text("Denkt nach...")
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 8)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Input Section
                HStack(spacing: 12) {
                    TextEditor(text: $messageText)
                        .frame(minHeight: 40, maxHeight: 100)
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                    
                    Button(action: {
                        viewModel.messages.append(ChatMessage(role: "user", content: messageText))
                        messageText = ""
                        
                        Task {
                            await sendMessage()
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading ? .gray : .blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("Chat mit GPT")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Löschen") {
                        viewModel.clearChat()
                    }
                }
            }
        }
        .onAppear {
            checkAPIKey()
        }
    }
    
    private func sendMessage() async {
        guard !viewModel.messages.isEmpty else { return }
        
        do {
            let response = try await OpenAIClient.shared.sendMessage(
                messages: viewModel.messages.map { OpenAIMessage(role: $0.role, content: $0.content) },
                model: "gpt-4",
                temperature: 0.7
            )
            
            await MainActor.run {
                if let choice = response.choices.first {
                    let assistantMessage = ChatMessage(role: choice.message?.role ?? "assistant", content: choice.message?.content ?? "Keine Antwort erhalten")
                    self.viewModel.messages.append(assistantMessage)
                }
            }
        } catch {
            await MainActor.run {
                let errorMessage = ChatMessage(role: "system", content: "Fehler: \(error.localizedDescription)")
                self.viewModel.messages.append(errorMessage)
            }
        }
    }
    
    private func checkAPIKey() {
        if !OpenAIClient.shared.hasValidAPIKey() {
            let errorMessage = ChatMessage(role: "system", content: "Bitte konfigurieren Sie Ihren OpenAI API Key in den Einstellungen.")
            viewModel.messages.append(errorMessage)
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .frame(maxWidth: 300, alignment: .trailing)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: message.isAssistant ? "cpu" : "person.circle")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(message.isUser ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
                            .cornerRadius(20)
                            .frame(maxWidth: 300, alignment: .leading)
                    }
                    
                    if !message.isUser {
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 32)
                    }
                }
                
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Streaming Chat View

struct StreamingChatView: View {
    @StateObject private var streamHandler = OpenAIStreamHandler()
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Current Response
                if streamHandler.isStreaming {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GPT antwortet...")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text(streamHandler.currentResponse)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        
                        ProgressView(value: streamHandler.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                }
                
                Divider()
                
                // Input Section
                HStack(spacing: 12) {
                    TextField("Nachricht eingeben...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    Button(action: startStreaming) {
                        Image(systemName: streamHandler.isStreaming ? "stop.circle.fill" : "paperplane.fill")
                            .font(.title)
                            .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || streamHandler.isStreaming)
                }
                .padding()
            }
            .navigationTitle("Streaming Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Löschen") {
                        messages.removeAll()
                        inputText = ""
                        streamHandler.cancelCurrentStream()
                    }
                }
            }
        }
        .alert("Fehler", isPresented: .constant(streamHandler.errorMessage != nil)) {
            Button("OK") { }
        } message: {
            Text(streamHandler.errorMessage ?? "")
        }
    }
    
    private func startStreaming() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(role: "user", content: inputText)
        messages.append(userMessage)
        inputText = ""
        
        let messagesForAPI = messages.map { OpenAIMessage(role: $0.role, content: $0.content) }
        streamHandler.startStreaming(
            client: OpenAIClient.shared,
            messages: messagesForAPI,
            model: "gpt-4"
        )
    }
}

// MARK: - SwiftUI Previews

struct ContentGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        ContentGenerationView()
    }
}

struct EmailGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        EmailGenerationView()
    }
}

struct MeetingGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingGenerationView()
    }
}

struct ArticleGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleGenerationView()
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}