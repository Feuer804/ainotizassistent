import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Obsidian Vault Management View
struct ObsidianView: View {
    @StateObject private var obsidian = ObsidianIntegration()
    @State private var showingCreateVault = false
    @State private var showingSettings = false
    @State private var showingProjectCreator = false
    @State private var selectedVault: ObsidianVault?
    @State private var searchText = ""
    @State private var selectedFolder = "All"
    @State private var showingSyncStatus = false
    @State private var currentView: ObsidianViewType = .overview
    
    enum ObsidianViewType {
        case overview
        case dailyNotes
        case projects
        case vaultSettings
        case syncStatus
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // View Selector
                viewSelectorView
                
                // Content
                switch currentView {
                case .overview:
                    overviewView
                case .dailyNotes:
                    dailyNotesView
                case .projects:
                    projectsView
                case .vaultSettings:
                    vaultSettingsView
                case .syncStatus:
                    syncStatusView
                }
            }
            .navigationTitle("Obsidian Vault")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingSyncStatus = true }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingCreateVault) {
                CreateVaultView()
                    .environmentObject(obsidian)
            }
            .sheet(isPresented: $showingSettings) {
                ObsidianSettingsView()
                    .environmentObject(obsidian)
            }
            .sheet(isPresented: $showingProjectCreator) {
                ProjectCreationView()
                    .environmentObject(obsidian)
            }
            .sheet(isPresented: $showingSyncStatus) {
                SyncStatusView()
                    .environmentObject(obsidian)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            if let vault = obsidian.activeVault {
                vaultInfoView(vault)
            } else {
                noVaultView
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private func vaultInfoView(_ vault: ObsidianVault) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vault.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(vault.path.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Sync Status Indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(syncStatusColor)
                    .frame(width: 8, height: 8)
                
                Text(syncStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var noVaultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Kein Vault ausgewählt")
                    .font(.headline)
                
                Text("Erstellen Sie ein neues Vault oder wählen Sie ein existierendes aus")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Vault erstellen") {
                showingCreateVault = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - View Selector
    private var viewSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ObsidianViewType.allCases, id: \.self) { type in
                    Button(action: { currentView = type }) {
                        HStack(spacing: 8) {
                            Image(systemName: viewTypeIcon(type))
                            Text(viewTypeTitle(type))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(currentView == type ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .foregroundColor(currentView == type ? .blue : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private func viewTypeIcon(_ type: ObsidianViewType) -> String {
        switch type {
        case .overview: return "house"
        case .dailyNotes: return "calendar"
        case .projects: return "folder"
        case .vaultSettings: return "gear"
        case .syncStatus: return "arrow.clockwise"
        }
    }
    
    private func viewTypeTitle(_ type: ObsidianViewType) -> String {
        switch type {
        case .overview: return "Übersicht"
        case .dailyNotes: return "Tagesnotizen"
        case .projects: return "Projekte"
        case .vaultSettings: return "Einstellungen"
        case .syncStatus: return "Sync"
        }
    }
    
    // MARK: - Overview View
    private var overviewView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let vault = obsidian.activeVault {
                    statisticsCardsView(vault)
                    recentNotesView
                    quickActionsView
                } else {
                    emptyOverviewView
                }
            }
            .padding()
        }
    }
    
    private func statisticsCardsView(_ vault: ObsidianVault) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatCardView(
                title: "Notizen",
                value: "127",
                icon: "doc.text",
                color: .blue
            )
            
            StatCardView(
                title: "Projekte",
                value: "8",
                icon: "folder",
                color: .green
            )
            
            StatCardView(
                title: "Tags",
                value: "34",
                icon: "tag",
                color: .orange
            )
            
            StatCardView(
                title: "Backlinks",
                value: "89",
                icon: "link",
                color: .purple
            )
        }
    }
    
    private var recentNotesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Zuletzt bearbeitet")
                    .font(.headline)
                Spacer()
                Button("Alle anzeigen") {
                    // Navigation zu allen Notizen
                }
            }
            
            // Hier würden die zuletzt bearbeiteten Notizen angezeigt
            ForEach(0..<5, id: \.self) { index in
                NoteRowView(
                    title: "Notiz \(index + 1)",
                    lastModified: Date().addingTimeInterval(-Double(index) * 3600),
                    tags: index % 2 == 0 ? ["Wichtig", "Projekt"] : ["Persönlich"]
                )
            }
        }
    }
    
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schnellaktionen")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Tagesnotiz",
                    icon: "calendar.badge.plus",
                    color: .blue
                ) {
                    createDailyNote()
                }
                
                QuickActionButton(
                    title: "Neue Notiz",
                    icon: "doc.badge.plus",
                    color: .green
                ) {
                    // Neue Notiz erstellen
                }
                
                QuickActionButton(
                    title: "Projekt",
                    icon: "folder.badge.plus",
                    color: .orange
                ) {
                    showingProjectCreator = true
                }
                
                QuickActionButton(
                    title: "Template",
                    icon: "doc.text",
                    color: .purple
                ) {
                    // Template auswählen
                }
            }
        }
    }
    
    private var emptyOverviewView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Vault auswählen")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Wählen Sie ein Vault aus oder erstellen Sie ein neues, um zu beginnen")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Vault erstellen") {
                showingCreateVault = true
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
    }
    
    // MARK: - Daily Notes View
    private var dailyNotesView: some View {
        VStack(spacing: 16) {
            // Date Selector
            dateSelectorView
            
            // Today's Note
            todaysNoteView
        }
        .padding()
    }
    
    private var dateSelectorView: some View {
        HStack {
            Button(action: { /* Previous day */ }) {
                Image(systemName: "chevron.left")
            }
            
            Text(DateFormatter.mediumDate.string(from: Date()))
                .font(.title2)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
            
            Button(action: { /* Next day */ }) {
                Image(systemName: "chevron.right")
            }
        }
    }
    
    private var todaysNoteView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tagesnotiz für heute")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { createDailyNote() }) {
                    Image(systemName: "plus")
                }
            }
            
            if let note = dailyNotes.first {
                NoteCardView(note: note)
            } else {
                emptyDailyNoteView
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var emptyDailyNoteView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            Text("Keine Tagesnotiz für heute")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Tagesnotiz erstellen") {
                createDailyNote()
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Projects View
    private var projectsView: some View {
        VStack(spacing: 16) {
            // Project Filter
            projectFilterView
            
            // Project List
            projectListView
        }
        .padding()
    }
    
    private var projectFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "Alle",
                    isSelected: selectedFolder == "All",
                    action: { selectedFolder = "All" }
                )
                
                FilterChip(
                    title: "Aktiv",
                    isSelected: selectedFolder == "active",
                    action: { selectedFolder = "active" }
                )
                
                FilterChip(
                    title: "Geplant",
                    isSelected: selectedFolder == "planning",
                    action: { selectedFolder = "planning" }
                )
                
                FilterChip(
                    title: "Abgeschlossen",
                    isSelected: selectedFolder == "completed",
                    action: { selectedFolder = "completed" }
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var projectListView: some View {
        List {
            ForEach(projects, id: \.id) { project in
                ProjectRowView(project: project)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Vault Settings View
    private var vaultSettingsView: some View {
        Form {
            Section("Allgemein") {
                NavigationLink("Tagesnotizen-Template") {
                    TemplateEditorView(
                        template: $obsidian.activeVault?.settings.dailyNotesTemplate ?? .constant("")
                    )
                }
                
                NavigationLink("Projekt-Template") {
                    TemplateEditorView(
                        template: $obsidian.activeVault?.settings.projectTemplate ?? .constant("")
                    )
                }
            }
            
            Section("Dateibenennung") {
                Picker("Konvention", selection: $fileNamingConvention) {
                    Text("Kebab-Case").tag(FileNamingConvention.kebabCase)
                    Text("Snake_Case").tag(FileNamingConvention.snakeCase)
                    Text("CamelCase").tag(FileNamingConvention.camelCase)
                    Text("Datums-basiert").tag(FileNamingConvention.dateBased)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section("Funktionen") {
                Toggle("Automatische Backlinks", isOn: $autoCreateBacklinks)
                Toggle("Automatische Tags", isOn: $autoCreateTags)
                Toggle("Git-Integration", isOn: $enableGitIntegration)
            }
            
            Section("Sync") {
                Picker("Sync-Service", selection: $syncService) {
                    Text("Keine").tag(SyncService.none)
                    Text("Obsidian Sync").tag(SyncService.obsidianSync)
                    Text("iCloud").tag(SyncService.icloud)
                    Text("Dropbox").tag(SyncService.dropbox)
                    Text("OneDrive").tag(SyncService.onedrive)
                }
            }
            
            Section("Git") {
                Button("Git-Repository initialisieren") {
                    Task {
                        do {
                            try obsidian.initializeGitRepository()
                        } catch {
                            print("Git-Initialisierung fehlgeschlagen: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sync Status View
    private var syncStatusView: some View {
        VStack(spacing: 16) {
            // Sync Status Indicator
            VStack(spacing: 8) {
                Image(systemName: syncStatusIcon)
                    .font(.system(size: 48))
                    .foregroundColor(syncStatusColor)
                
                Text(syncStatusTitle)
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(syncStatusDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Sync Actions
            VStack(spacing: 12) {
                Button("Sync starten") {
                    Task {
                        await obsidian.startSync()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Konflikte lösen") {
                    // Konflikt-Lösung anzeigen
                }
                .buttonStyle(.bordered)
                .disabled(obsidian.conflicts.isEmpty)
            }
            
            // Conflicts List
            if !obsidian.conflicts.isEmpty {
                conflictsListView
            }
        }
        .padding()
    }
    
    private var conflictsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Konflikte")
                .font(.headline)
            
            ForEach(obsidian.conflicts, id: \.localPath) { conflict in
                ConflictRowView(conflict: conflict)
            }
        }
    }
    
    // MARK: - Helper Properties
    private var syncStatusColor: Color {
        switch obsidian.syncStatus {
        case .idle: return .gray
        case .scanning, .syncing: return .blue
        case .resolvingConflicts: return .orange
        case .completed: return .green
        case .error: return .red
        }
    }
    
    private var syncStatusText: String {
        switch obsidian.syncStatus {
        case .idle: return "Bereit"
        case .scanning: return "Scanne..."
        case .syncing: return "Sync..."
        case .resolvingConflicts: return "Konflikte"
        case .completed: return "Synchronisiert"
        case .error(let message): return "Fehler"
        }
    }
    
    private var syncStatusIcon: String {
        switch obsidian.syncStatus {
        case .idle: return "clock"
        case .scanning, .syncing: return "arrow.clockwise"
        case .resolvingConflicts: return "exclamationmark.triangle"
        case .completed: return "checkmark.circle"
        case .error: return "xmark.circle"
        }
    }
    
    private var syncStatusTitle: String {
        switch obsidian.syncStatus {
        case .idle: return "Synchronisation bereit"
        case .scanning: return "Scanning..."
        case .syncing: return "Synchronisation läuft"
        case .resolvingConflicts: return "Konflikte werden gelöst"
        case .completed: return "Synchronisation abgeschlossen"
        case .error(let message): return "Fehler bei der Synchronisation"
        }
    }
    
    private var syncStatusDescription: String {
        switch obsidian.syncStatus {
        case .idle: return "Ihr Vault ist bereit für die Synchronisation"
        case .scanning: return "Suche nach Änderungen..."
        case .syncing: return "Dateien werden synchronisiert..."
        case .resolvingConflicts: return "Konfliktdateien werden identifiziert..."
        case .completed: return "Alle Dateien sind synchronisiert"
        case .error(let message): return "Fehler: \(message)"
        }
    }
    
    // MARK: - Mock Data
    private var dailyNotes: [ObsidianNote] {
        // Hier würde die echte Logik für das Laden von Tagesnotizen implementiert
        []
    }
    
    private var projects: [Project] {
        // Hier würde die echte Logik für das Laden von Projekten implementiert
        []
    }
    
    @State private var fileNamingConvention: FileNamingConvention = .kebabCase
    @State private var autoCreateBacklinks = true
    @State private var autoCreateTags = true
    @State private var enableGitIntegration = false
    @State private var syncService: SyncService = .none
    
    // MARK: - Actions
    private func createDailyNote() {
        Task {
            do {
                try obsidian.createDailyNote()
            } catch {
                print("Fehler beim Erstellen der Tagesnotiz: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct NoteRowView: View {
    let title: String
    let lastModified: Date
    let tags: [String]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            Text(DateFormatter.timeRange.string(from: lastModified))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

struct NoteCardView: View {
    let note: ObsidianNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.displayName)
                .font(.headline)
            
            Text(note.content.prefix(100) + (note.content.count > 100 ? "..." : ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(projectStatusText(project.status))
                    .font(.caption)
                    .foregroundColor(statusColor(project.status))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(project.notes.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Notizen")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func projectStatusText(_ status: Project.ProjectStatus) -> String {
        switch status {
        case .planning: return "Geplant"
        case .active: return "Aktiv"
        case .paused: return "Pausiert"
        case .completed: return "Abgeschlossen"
        case .archived: return "Archiviert"
        }
    }
    
    private func statusColor(_ status: Project.ProjectStatus) -> Color {
        switch status {
        case .planning: return .orange
        case .active: return .green
        case .paused: return .yellow
        case .completed: return .blue
        case .archived: return .gray
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(16)
        }
    }
}

struct ConflictRowView: View {
    let conflict: FileConflict
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                
                Text(conflict.localPath.lastPathComponent)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text("Konflikttyp: \(conflictTypeText(conflict.conflictType))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func conflictTypeText(_ type: FileConflict.ConflictType) -> String {
        switch type {
        case .timestamp: return "Zeitstempel"
        case .content: return "Inhalt"
        case .metadata: return "Metadaten"
        }
    }
}

// MARK: - Template Editor
struct TemplateEditorView: View {
    @Binding var template: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            TextEditor(text: $template)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(8)
        }
        .navigationTitle("Template bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fertig") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .padding()
    }
}

// MARK: - Create Vault View
struct CreateVaultView: View {
    @EnvironmentObject var obsidian: ObsidianIntegration
    @Environment(\.presentationMode) var presentationMode
    @State private var vaultName = ""
    @State private var selectedPath: URL?
    @State private var showingPathPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Vault-Details") {
                    TextField("Vault-Name", text: $vaultName)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    Button("Pfad auswählen") {
                        showingPathPicker = true
                    }
                    
                    if let path = selectedPath {
                        Text(path.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Vault erstellen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Erstellen") {
                        createVault()
                    }
                    .disabled(vaultName.isEmpty || selectedPath == nil)
                }
            }
        }
    }
    
    private func createVault() {
        guard let path = selectedPath else { return }
        
        do {
            let vault = try obsidian.createVault(name: vaultName, at: path)
            print("Vault erstellt: \(vault.name)")
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Fehler beim Erstellen des Vaults: \(error)")
        }
    }
}

// MARK: - Project Creation View
struct ProjectCreationView: View {
    @EnvironmentObject var obsidian: ObsidianIntegration
    @Environment(\.presentationMode) var presentationMode
    @State private var projectName = ""
    @State private var projectDescription = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Projekt-Details") {
                    TextField("Projekt-Name", text: $projectName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Beschreibung", text: $projectDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Projekt erstellen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Erstellen") {
                        createProject()
                    }
                    .disabled(projectName.isEmpty)
                }
            }
        }
    }
    
    private func createProject() {
        do {
            let project = try obsidian.createProject(
                name: projectName,
                description: projectDescription
            )
            print("Projekt erstellt: \(project.name)")
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Fehler beim Erstellen des Projekts: \(error)")
        }
    }
}

struct ObsidianSettingsView: View {
    @EnvironmentObject var obsidian: ObsidianIntegration
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("Vault-Informationen") {
                    if let vault = obsidian.activeVault {
                        Text("Name: \(vault.name)")
                        Text("Pfad: \(vault.path.path)")
                        Text("Erstellt: \(DateFormatter.mediumDate.string(from: vault.createdDate))")
                    } else {
                        Text("Kein Vault ausgewählt")
                    }
                }
                
                Section("Sync-Einstellungen") {
                    Picker("Sync-Service", selection: $obsidian.activeVault?.settings.syncService ?? .constant(.none)) {
                        Text("Keine").tag(SyncService.none)
                        Text("Obsidian Sync").tag(SyncService.obsidianSync)
                        Text("iCloud").tag(SyncService.icloud)
                        Text("Dropbox").tag(SyncService.dropbox)
                        Text("OneDrive").tag(SyncService.onedrive)
                    }
                    
                    Toggle("Automatische Backlinks", isOn: $obsidian.activeVault?.settings.autoCreateBacklinks ?? .constant(true))
                    Toggle("Automatische Tags", isOn: $obsidian.activeVault?.settings.autoCreateTags ?? .constant(true))
                    Toggle("Git-Integration", isOn: $obsidian.activeVault?.settings.enableGitIntegration ?? .constant(false))
                }
            }
            .navigationTitle("Obsidian Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct SyncStatusView: View {
    @EnvironmentObject var obsidian: ObsidianIntegration
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 16) {
            // Sync Status
            VStack(spacing: 8) {
                Image(systemName: syncStatusIcon)
                    .font(.system(size: 48))
                    .foregroundColor(syncStatusColor)
                
                Text(syncStatusTitle)
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(syncStatusDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Sync Actions
            VStack(spacing: 12) {
                Button("Sync starten") {
                    Task {
                        await obsidian.startSync()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Fertig") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sync-Status")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var syncStatusColor: Color {
        switch obsidian.syncStatus {
        case .idle: return .gray
        case .scanning, .syncing: return .blue
        case .resolvingConflicts: return .orange
        case .completed: return .green
        case .error: return .red
        }
    }
    
    private var syncStatusIcon: String {
        switch obsidian.syncStatus {
        case .idle: return "clock"
        case .scanning, .syncing: return "arrow.clockwise"
        case .resolvingConflicts: return "exclamationmark.triangle"
        case .completed: return "checkmark.circle"
        case .error: return "xmark.circle"
        }
    }
    
    private var syncStatusTitle: String {
        switch obsidian.syncStatus {
        case .idle: return "Synchronisation bereit"
        case .scanning: return "Scanning..."
        case .syncing: return "Synchronisation läuft"
        case .resolvingConflicts: return "Konflikte werden gelöst"
        case .completed: return "Synchronisation abgeschlossen"
        case .error(let message): return "Fehler bei der Synchronisation"
        }
    }
    
    private var syncStatusDescription: String {
        switch obsidian.syncStatus {
        case .idle: return "Ihr Vault ist bereit für die Synchronisation"
        case .scanning: return "Suche nach Änderungen..."
        case .syncing: return "Dateien werden synchronisiert..."
        case .resolvingConflicts: return "Konfliktdateien werden identifiziert..."
        case .completed: return "Alle Dateien sind synchronisiert"
        case .error(let message): return "Fehler: \(message)"
        }
    }
}

// MARK: - Preview
struct ObsidianView_Previews: PreviewProvider {
    static var previews: some View {
        ObsidianView()
    }
}