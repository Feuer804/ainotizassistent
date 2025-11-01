//
//  NotesView.swift
//  Apple Notes Integration für AINotizassistent
//

import SwiftUI
import OSLog

@available(iOS 15.0, macOS 12.0, *)
struct NotesView: View {
    
    // MARK: - State Properties
    @StateObject private var notesIntegration = NotesIntegration()
    @StateObject private var noteViewModel = NoteViewModel()
    @State private var isCreatingNote = false
    @State private var selectedNote: AppleNotesNote?
    @State private var searchQuery = ""
    @State private var selectedCategory = "All Notes"
    @State private var showSyncStatus = false
    @State private var syncInProgress = false
    
    // MARK: - Computed Properties
    var filteredNotes: [AppleNotesNote] {
        var notes = selectedCategory == "All Notes" ? noteViewModel.notes : 
                   noteViewModel.notes.filter { $0.category == selectedCategory }
        
        if !searchQuery.isEmpty {
            notes = notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchQuery) ||
                note.content.localizedCaseInsensitiveContains(searchQuery) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }
        
        return notes.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    var availableCategories: [String] {
        let categories = notesIntegration.availableCategories.map { $0.name }
        return ["All Notes"] + categories
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header mit Connection Status
                    headerSection
                    
                    // Suchbar und Filter
                    searchAndFilterSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Notes Liste
                    notesListSection
                }
                .padding(.horizontal)
            }
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Apple Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSyncStatus = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: notesIntegration.isConnected ? "checkmark.circle.fill" : "exclamationmark.circle")
                                .foregroundColor(notesIntegration.isConnected ? .green : .orange)
                            if notesIntegration.syncInProgress {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isCreatingNote = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $isCreatingNote) {
                createNoteSheet
            }
            .sheet(item: $selectedNote) { note in
                noteDetailSheet(note)
            }
            .alert("Sync Status", isPresented: $showSyncStatus) {
                Button("OK") { }
            } message: {
                Text("Zuletzt synchronisiert: \(notesIntegration.lastSyncDate?.description ?? "Nie")\nVerbindung: \(notesIntegration.isConnected ? "Verbunden" : "Nicht verbunden")")
            }
        }
        .onAppear {
            Task {
                await loadNotes()
            }
        }
        .task {
            await notesIntegration.syncWithAppleNotes()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Notes Integration")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(filteredNotes.count) Notizen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Connection Status Indicator
                VStack {
                    Circle()
                        .fill(notesIntegration.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                    
                    Text(notesIntegration.isConnected ? "Online" : "Offline")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if notesIntegration.syncInProgress {
                ProgressView("Synchronisiere...")
                    .progressViewStyle(LinearProgressViewStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(radius: 5)
        )
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Suchbar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Notizen durchsuchen...", text: $searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            
            // Kategorien Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableCategories, id: \.self) { category in
                        categoryFilterChip(category)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func categoryFilterChip(_ category: String) -> some View {
        Button(action: { selectedCategory = category }) {
            Text(category)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(selectedCategory == category ? .white : .primary)
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            
            quickActionButton(
                icon: "plus.circle.fill",
                title: "Neue Notiz",
                color: .blue
            ) {
                isCreatingNote = true
            }
            
            quickActionButton(
                icon: "arrow.clockwise.circle.fill",
                title: "Sync",
                color: .green
            ) {
                Task {
                    await performSync()
                }
            }
            
            quickActionButton(
                icon: "folder.circle.fill",
                title: "Kategorien",
                color: .orange
            ) {
                // Zeige Kategorien Management
            }
            
            quickActionButton(
                icon: "magnifyingglass.circle.fill",
                title: "Suche",
                color: .purple
            ) {
                // Fokussiere Suchfeld
            }
        }
    }
    
    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .shadow(radius: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Notes List Section
    private var notesListSection: some View {
        VStack(spacing: 12) {
            ForEach(filteredNotes) { note in
                noteCard(note)
            }
            
            if filteredNotes.isEmpty {
                emptyStateView
            }
        }
    }
    
    private func noteCard(_ note: AppleNotesNote) -> some View {
        Button(action: { selectedNote = note }) {
            VStack(alignment: .leading, spacing: 12) {
                // Notiz Header
                HStack {
                    Text(note.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text(note.category)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                
                // Notiz Inhalt
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Tags und Metadaten
                HStack {
                    if !note.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(note.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.gray)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text(formatDate(note.updatedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Keine Notizen gefunden")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(searchQuery.isEmpty ? "Erstelle deine erste Notiz oder führe eine Synchronisation durch." : "Versuche einen anderen Suchbegriff.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Erste Notiz erstellen") {
                isCreatingNote = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Sheets
    
    private var createNoteSheet: some View {
        CreateNoteSheet(
            isPresented: $isCreatingNote,
            integration: notesIntegration
        ) { note in
            noteViewModel.addNote(NoteModel(from: note.content, contentType: .text))
            Task {
                await loadNotes()
            }
        }
    }
    
    private func noteDetailSheet(_ note: AppleNotesNote) -> some View {
        NoteDetailSheet(
            note: note,
            integration: notesIntegration
        ) { updatedNote in
            if let index = noteViewModel.notes.firstIndex(where: { $0.id == UUID(uuidString: updatedNote.id) }) {
                noteViewModel.notes[index] = AppleNotesNote(id: updatedNote.id, title: updatedNote.title, content: updatedNote.content, tags: updatedNote.tags)
            }
            Task {
                await loadNotes()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadNotes() async {
        do {
            let notes = try await notesIntegration.getAllNotes()
            // Konvertiere AppleNotesNote zu NoteModel für lokale Verwaltung
            let convertedNotes = notes.map { note in
                NoteModel(
                    id: UUID(uuidString: note.id) ?? UUID(),
                    title: note.title,
                    content: note.content,
                    contentType: .text,
                    tags: note.tags
                )
            }
            
            await MainActor.run {
                self.noteViewModel.notes = convertedNotes
            }
        } catch {
            print("Fehler beim Laden der Notizen: \(error)")
        }
    }
    
    private func performSync() async {
        do {
            syncInProgress = true
            let result = try await notesIntegration.syncWithAppleNotes()
            print("Sync erfolgreich: \(result.notesCount) Notizen synchronisiert")
            await loadNotes()
        } catch {
            print("Sync fehlgeschlagen: \(error)")
        }
        syncInProgress = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Create Note Sheet
@available(iOS 15.0, macOS 12.0, *)
struct CreateNoteSheet: View {
    
    @Binding var isPresented: Bool
    let integration: NotesIntegration
    let onNoteCreated: (AppleNotesNote) -> Void
    
    @State private var title = ""
    @State private var content = ""
    @State private var tags = ""
    @State private var selectedCategory = "Notes"
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Titel Eingabe
                VStack(alignment: .leading, spacing: 8) {
                    Text("Titel")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Notiz Titel eingeben...", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Kategorie Auswahl
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kategorie")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Picker("Kategorie", selection: $selectedCategory) {
                        Text("Notes").tag("Notes")
                        Text("Work").tag("Work")
                        Text("Personal").tag("Personal")
                        Text("Ideas").tag("Ideas")
                        Text("Projects").tag("Projects")
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Tags Eingabe
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags (durch Komma getrennt)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("arbeit, wichtig, projekt", text: $tags)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Inhalt
                VStack(alignment: .leading, spacing: 8) {
                    Text("Inhalt")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .textFieldStyle(.roundedBorder)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Neue Notiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await saveNote() } }) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Speichern")
                        }
                    }
                    .disabled(isSaving || title.isEmpty)
                }
            }
        }
        .alert("Fehler", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveNote() async {
        isSaving = true
        
        do {
            let tagArray = tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            
            let note = try await integration.createNote(
                title: title,
                content: content,
                tags: tagArray,
                category: selectedCategory
            )
            
            onNoteCreated(note)
            isPresented = false
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isSaving = false
    }
}

// MARK: - Note Detail Sheet
@available(iOS 15.0, macOS 12.0, *)
struct NoteDetailSheet: View {
    
    let note: AppleNotesNote
    let integration: NotesIntegration
    let onNoteUpdated: (AppleNotesNote) -> Void
    
    @State private var isEditing = false
    @State private var title: String
    @State private var content: String
    @State private var tags: [String]
    @State private var selectedCategory: String
    @State private var isUpdating = false
    @State private var showingShareSheet = false
    @State private var shareMethod: ShareMethod = .copyLink
    
    init(note: AppleNotesNote, integration: NotesIntegration, onNoteUpdated: @escaping (AppleNotesNote) -> Void) {
        self.note = note
        self.integration = integration
        self.onNoteUpdated = onNoteUpdated
        
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
        _tags = State(initialValue: note.tags)
        _selectedCategory = State(initialValue: note.category)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Titel (editable)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Titel")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isEditing {
                            TextField("Titel bearbeiten...", text: $title)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Text(title)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    // Kategorie (editable)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kategorie")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isEditing {
                            Picker("Kategorie", selection: $selectedCategory) {
                                Text("Notes").tag("Notes")
                                Text("Work").tag("Work")
                                Text("Personal").tag("Personal")
                                Text("Ideas").tag("Ideas")
                                Text("Projects").tag("Projects")
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Text(selectedCategory)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    // Tags (editable)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isEditing {
                            TextField("Tags durch Komma getrennt", text: .constant(tags.joined(separator: ", ")))
                                .textFieldStyle(.roundedBorder)
                        } else {
                            if !tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 4) {
                                        ForEach(tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.gray.opacity(0.2))
                                                .foregroundColor(.gray)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            } else {
                                Text("Keine Tags")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Inhalt (editable)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Inhalt")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isEditing {
                            TextEditor(text: $content)
                                .frame(minHeight: 200)
                                .textFieldStyle(.roundedBorder)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Text(content)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    // Metadaten
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metadaten")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Erstellt: \(formatDate(note.createdAt))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Zuletzt aktualisiert: \(formatDate(note.updatedAt))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("ID: \(note.id)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(note.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isEditing.toggle() }) {
                        Text(isEditing ? "Fertig" : "Bearbeiten")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        if isEditing {
                            Button(action: { Task { await updateNote() } }) {
                                if isUpdating {
                                    ProgressView()
                                } else {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }
        .shareSheet(isPresented: $showingShareSheet) {
            ShareNoteSheet(
                note: note,
                integration: integration,
                onShare: { method in
                    shareMethod = method
                }
            )
        }
    }
    
    private func updateNote() async {
        isUpdating = true
        
        do {
            let tagArray = tags.joined(separator: ", ").components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            
            try await integration.updateNote(
                note,
                title: title,
                content: content,
                tags: tagArray,
                category: selectedCategory
            )
            
            let updatedNote = AppleNotesNote(
                id: note.id,
                title: title,
                content: content,
                tags: tagArray,
                category: selectedCategory
            )
            
            onNoteUpdated(updatedNote)
            isEditing = false
            
        } catch {
            print("Fehler beim Aktualisieren der Notiz: \(error)")
        }
        
        isUpdating = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Share Note Sheet
@available(iOS 15.0, macOS 12.0, *)
struct ShareNoteSheet: View {
    
    let note: AppleNotesNote
    let integration: NotesIntegration
    let onShare: (ShareMethod) -> Void
    
    @State private var isSharing = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Notiz teilen")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                shareButton(
                    icon: "link",
                    title: "Link kopieren",
                    subtitle: "Share-Link in Zwischenablage kopieren"
                ) {
                    onShare(.copyLink)
                }
                
                shareButton(
                    icon: "icloud",
                    title: "iCloud Link",
                    subtitle: "Link über iCloud teilen"
                ) {
                    onShare(.icloudLink)
                }
                
                shareButton(
                    icon: "envelope",
                    title: "Per E-Mail",
                    subtitle: "Notiz per E-Mail versenden"
                ) {
                    onShare(.email)
                }
            }
        }
        .padding()
    }
    
    private func shareButton(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Preview
@available(iOS 15.0, *)
#Preview {
    NotesView()
}