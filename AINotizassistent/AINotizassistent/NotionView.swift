//
//  NotionView.swift
//  AINotizassistent
//
//  Notion Database Management UI
//

import SwiftUI
import Combine

// MARK: - Notion Database View
struct NotionDatabaseView: View {
    @StateObject private var notionIntegration = NotionIntegration()
    @StateObject private var webhookManager = NotionWebhookManager.shared
    @State private var selectedDatabase: NotionDatabase?
    @State private var pages: [NotionPage] = []
    @State private var filteredPages: [NotionPage] = []
    @State private var showCreateDatabase = false
    @State private var showCreatePage = false
    @State private var showSettings = false
    @State private var searchText = ""
    @State private var selectedFilter: String = "all"
    @State private var isLoading = false
    @State private var showWebhookSetup = false
    
    let templateManager = NotionTemplateManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                // Connection Status
                connectionStatusHeader
                
                // Search and Filter Bar
                searchFilterBar
                
                // Database List or Page List
                if selectedDatabase == nil {
                    databaseListView
                } else {
                    pageListView
                }
            }
            .navigationTitle(selectedDatabase?.title.first?.text.content ?? "Notion Datenbanken")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedDatabase != nil {
                        Button("Zurück") {
                            selectedDatabase = nil
                            pages.removeAll()
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if selectedDatabase != nil {
                        Button(action: { showCreatePage = true }) {
                            Image(systemName: "plus")
                        }
                    } else {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                        }
                    }
                    
                    Button(action: { showWebhookSetup = true }) {
                        Image(systemName: "link")
                    }
                }
            }
            .sheet(isPresented: $showCreateDatabase) {
                CreateDatabaseView(notionIntegration: notionIntegration) { database in
                    selectedDatabase = database
                    loadPages(for: database.id)
                }
            }
            .sheet(isPresented: $showCreatePage) {
                CreatePageView(
                    notionIntegration: notionIntegration,
                    database: selectedDatabase!,
                    templates: templateManager.getAllTemplates()
                ) { page in
                    pages.insert(page, at: 0)
                    filteredPages = filterPages(pages)
                }
            }
            .sheet(isPresented: $showSettings) {
                NotionSettingsView(notionIntegration: notionIntegration)
            }
            .sheet(isPresented: $showWebhookSetup) {
                WebhookSetupView(webhookManager: webhookManager)
            }
            .searchable(text: $searchText, prompt: "Seiten durchsuchen")
            .onChange(of: searchText) { _ in
                filteredPages = filterPages(pages)
            }
            .onChange(of: selectedFilter) { _ in
                filteredPages = filterPages(pages)
            }
            .onAppear {
                notionIntegration.loadApiKey()
                if notionIntegration.isAuthenticated {
                    loadDatabases()
                }
                
                setupWebhookListeners()
            }
        }
    }
    
    // MARK: - Header Views
    private var connectionStatusHeader: some View {
        HStack {
            Circle()
                .fill(notionIntegration.isAuthenticated ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            
            Text(notionIntegration.isAuthenticated ? "Verbunden" : "Nicht verbunden")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if webhookManager.isConnected {
                Text("Live Sync")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var searchFilterBar: some View {
        HStack {
            if selectedDatabase != nil {
                Picker("Filter", selection: $selectedFilter) {
                    Text("Alle").tag("all")
                    Text("Aktiv").tag("active")
                    Text("Abgeschlossen").tag("completed")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Database List View
    private var databaseListView: some View {
        VStack {
            if !notionIntegration.isAuthenticated {
                connectionPromptView
            } else if isLoading {
                loadingView
            } else if let currentDatabase = notionIntegration.currentDatabase {
                databaseCardView(database: currentDatabase)
            } else {
                emptyDatabaseView
            }
        }
    }
    
    private var connectionPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Notion API Key erforderlich")
                .font(.headline)
            
            Text("Verbinden Sie sich mit Notion, um auf Ihre Datenbanken zuzugreifen")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Verbinden") {
                showSettings = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView("Lade Datenbanken...")
                .progressViewStyle(CircularProgressViewStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyDatabaseView: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Keine Datenbanken gefunden")
                .font(.headline)
            
            Text("Erstellen Sie eine neue Notion-Datenbank, um loszulegen")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Datenbank erstellen") {
                showCreateDatabase = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func databaseCardView(database: NotionDatabase) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                databaseHeader(database: database)
                
                Text(database.title.first?.text.content ?? "Unbenannte Datenbank")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                databasePropertiesView(database: database)
                
                HStack {
                    Button("Öffnen") {
                        selectedDatabase = database
                        loadPages(for: database.id)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Text(database.properties.count.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private func databaseHeader(database: NotionDatabase) -> some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.blue)
            
            Text("Notion Datenbank")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(database.created_time.formattedDate)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func databasePropertiesView(database: NotionDatabase) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Eigenschaften:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(database.properties.keys.prefix(3), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(database.properties[key]?.type.rawValue ?? "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Page List View
    private var pageListView: some View {
        List {
            ForEach(filteredPages) { page in
                PageRowView(page: page) { updatedPage in
                    updatePageInList(updatedPage)
                }
            }
            .onDelete(perform: deletePages)
        }
        .listStyle(.plain)
    }
    
    private func deletePages(at offsets: IndexSet) {
        let indices = Array(offsets)
        for index in indices {
            let page = filteredPages[index]
            Task {
                do {
                    // Archive the page instead of deleting
                    try await notionIntegration.updatePage(
                        pageId: page.id,
                        properties: [:] // Would update archive status
                    )
                    
                    await MainActor.run {
                        pages.removeAll { $0.id == page.id }
                        filteredPages = filterPages(pages)
                    }
                } catch {
                    print("Fehler beim Archivieren der Seite: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadDatabases() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                // Load user's databases (this would be implemented in NotionIntegration)
                // For now, we'll simulate with a search
                let results = try await notionIntegration.search(query: "", filter: ["object": "database"])
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    notionIntegration.errorMessage = "Fehler beim Laden der Datenbanken: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadPages(for databaseId: String) {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                let (pageResults, _, _) = try await notionIntegration.queryDatabaseWithRetry(
                    databaseId: databaseId
                )
                
                await MainActor.run {
                    self.pages = pageResults
                    self.filteredPages = self.filterPages(pageResults)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    notionIntegration.errorMessage = "Fehler beim Laden der Seiten: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func filterPages(_ pages: [NotionPage]) -> [NotionPage] {
        var filtered = pages
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { page in
                page.properties["Title"]?.title?.contains { richText in
                    richText.text.content.localizedCaseInsensitiveContains(searchText)
                } ?? false
            }
        }
        
        // Apply status filter
        if selectedFilter != "all" {
            filtered = filtered.filter { page in
                if let status = page.properties["Status"]?.select {
                    return status.name.lowercased() == selectedFilter
                }
                return true
            }
        }
        
        return filtered
    }
    
    private func updatePageInList(_ updatedPage: NotionPage) {
        if let index = pages.firstIndex(where: { $0.id == updatedPage.id }) {
            pages[index] = updatedPage
        }
        if let index = filteredPages.firstIndex(where: { $0.id == updatedPage.id }) {
            filteredPages[index] = updatedPage
        }
    }
    
    private func setupWebhookListeners() {
        notionIntegration.onPageCreated { page in
            pages.insert(page, at: 0)
            filteredPages = filterPages(pages)
        }
        
        notionIntegration.onPageUpdated { page in
            updatePageInList(page)
        }
    }
}

// MARK: - Page Row View
struct PageRowView: View {
    let page: NotionPage
    let onUpdate: (NotionPage) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Page icon if available
                if let icon = page.properties["Icon"]?.rich_text?.first?.text.content {
                    Text(icon)
                        .font(.title3)
                }
                
                Text(pageTitle)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                // Status indicator
                if let status = page.properties["Status"]?.select {
                    Text(status.name)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            
            // Additional properties preview
            if let dueDate = page.properties["Due Date"]?.date?.start {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    
                    Text("Fällig: \(dueDate.formattedDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let assigned = page.properties["Assigned"]?.people?.first?.name {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.secondary)
                    
                    Text("Zugewiesen: \(assigned)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(page.last_edited_time.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Öffnen") {
                    openInNotion()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var pageTitle: String {
        page.properties["Title"]?.title?.first?.text.content ?? 
        page.properties["Name"]?.title?.first?.text.content ??
        "Unbenannte Seite"
    }
    
    private func openInNotion() {
        if let url = URL(string: page.url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Create Database View
struct CreateDatabaseView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var notionIntegration: NotionIntegration
    let onCreated: (NotionDatabase) -> Void
    
    @State private var title = ""
    @State private var template: NotionTemplate?
    @State private var showTemplatePicker = false
    
    let templates = NotionTemplateManager.shared.getAllTemplates()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basis-Informationen") {
                    TextField("Datenbank-Titel", text: $title)
                    
                    Button("Template wählen") {
                        showTemplatePicker = true
                    }
                    
                    if let template = template {
                        Text("Template: \(template.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let template = template {
                    Section("Template-Vorschau") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Eigenschaften:")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            ForEach(template.createProperties().keys.prefix(5), id: \.self) { key in
                                Text("• \(key)")
                                    .font(.caption2)
                            }
                            
                            if template.createProperties().count > 5 {
                                Text("... und \(template.createProperties().count - 5) weitere")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Neue Datenbank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Erstellen") {
                        createDatabase()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerView(templates: templates) { selectedTemplate in
                template = selectedTemplate
                showTemplatePicker = false
            }
        }
    }
    
    private func createDatabase() {
        Task {
            do {
                let properties = template?.createProperties() ?? [:]
                let database = try await notionIntegration.createDatabase(
                    title: title,
                    parentDatabaseId: "", // Would need parent database ID
                    properties: properties
                )
                
                await MainActor.run {
                    onCreated(database)
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    notionIntegration.errorMessage = "Fehler beim Erstellen der Datenbank: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Create Page View
struct CreatePageView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var notionIntegration: NotionIntegration
    let database: NotionDatabase
    let templates: [NotionTemplate]
    let onCreated: (NotionPage) -> Void
    
    @State private var title = ""
    @State private var selectedTemplate: NotionTemplate?
    @State private var additionalProperties: [String: NotionPropertyValue] = [:]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basis-Informationen") {
                    TextField("Seiten-Titel", text: $title)
                    
                    if !templates.isEmpty {
                        Picker("Template", selection: $selectedTemplate) {
                            Text("Kein Template").tag(Optional<NotionTemplate>.none)
                            ForEach(templates, id: \.name) { template in
                                Text(template.name).tag(Optional(template))
                            }
                        }
                    }
                }
                
                // Custom properties based on database schema
                ForEach(database.properties.keys.filter { $0 != "Title" }, id: \.self) { key in
                    CustomPropertyRow(
                        property: database.properties[key]!,
                        value: Binding(
                            get: { additionalProperties[key] },
                            set: { additionalProperties[key] = $0 }
                        )
                    )
                }
            }
            .navigationTitle("Neue Seite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Erstellen") {
                        createPage()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func createPage() {
        Task {
            do {
                var properties: [String: NotionPropertyValue] = [:]
                
                // Add title
                properties["Title"] = NotionPropertyValue(
                    id: "title",
                    type: .title,
                    title: [RichText(text: TextContent(content: title, link: nil), annotations: TextAnnotations(bold: false, italic: false, strikethrough: false, underline: false, code: false, color: "default"), href: nil)],
                    rich_text: nil,
                    number: nil,
                    select: nil,
                    multi_select: nil,
                    date: nil,
                    people: nil,
                    files: nil,
                    checkbox: nil,
                    url: nil,
                    email: nil,
                    phone_number: nil,
                    created_time: nil,
                    created_by: nil,
                    last_edited_time: nil,
                    last_edited_by: nil,
                    formula: nil,
                    relation: nil,
                    rollup: nil,
                    status: nil,
                    button: nil,
                    unique_id: nil,
                    verification: nil
                )
                
                // Add additional properties
                properties.merge(additionalProperties) { _, new in new }
                
                let blocks = selectedTemplate?.createBlocks()
                
                let page = try await notionIntegration.createPage(
                    databaseId: database.id,
                    properties: properties,
                    blocks: blocks
                )
                
                await MainActor.run {
                    onCreated(page)
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    notionIntegration.errorMessage = "Fehler beim Erstellen der Seite: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Custom Property Row
struct CustomPropertyRow: View {
    let property: NotionProperty
    @Binding var value: NotionPropertyValue?
    
    var body: some View {
        switch property.type {
        case .title, .rich_text:
            PropertyTextField(property: property, value: $value)
            
        case .select:
            PropertySelectView(property: property, value: $value)
            
        case .multi_select:
            PropertyMultiSelectView(property: property, value: $value)
            
        case .date:
            PropertyDateView(value: $value)
            
        case .checkbox:
            PropertyCheckboxView(value: $value)
            
        case .people:
            PropertyPeopleView(value: $value)
            
        case .number:
            PropertyNumberView(value: $value)
            
        case .url:
            PropertyURLView(value: $value)
            
        default:
            Text("\(property.type.rawValue) - nicht unterstützt")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Views
struct PropertyTextField: View {
    let property: NotionProperty
    @Binding var value: NotionPropertyValue?
    
    var body: some View {
        TextField(property.id, text: .constant(value?.title?.first?.text.content ?? ""))
            .onTapGesture {
                // Would open text input
            }
    }
}

struct PropertySelectView: View {
    let property: NotionProperty
    @Binding var value: NotionPropertyValue?
    
    var body: some View {
        // Would implement select dropdown
        Text("Select property - not implemented")
            .font(.caption)
    }
}

struct PropertyMultiSelectView: View {
    let property: NotionProperty
    @Binding var value: NotionPropertyValue?
    
    var body: some View {
        // Would implement multi-select
        Text("Multi-select property - not implemented")
            .font(.caption)
    }
}

struct PropertyDateView: View {
    @Binding var value: NotionPropertyValue?
    
    var body: some View {
        // Would implement date picker
        Text("Date property - not implemented")
            .font(.caption)
    }
}

struct PropertyCheckboxView: View {
    @Binding var value: NotionPropertyValue?
    
    var body: some View {
        // Would implement checkbox
        Text("Checkbox property - not implemented")
            .font(.caption)
    }
}

struct PropertyPeopleView: View {
    @Binding var value: NotionPropertyValue?
    
    var body: some View {
        // Would implement people picker
        Text("People property - not implemented")
            .font(.caption)
    }
}

struct PropertyNumberView: View {
    @Binding var value: NotionPropertyValue?
    
    var body: some View {
        // Would implement number input
        Text("Number property - not implemented")
            .font(.caption)
    }
}

struct PropertyURLView: View {
    @Binding var value: NotionPropertyValue?
    
    var body: some View {
        // Would implement URL input
        Text("URL property - not implemented")
            .font(.caption)
    }
}

// MARK: - Settings Views
struct NotionSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var notionIntegration: NotionIntegration
    
    @State private var apiKey = ""
    @State private var showApiKey = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("API-Konfiguration") {
                    HStack {
                        if showApiKey {
                            TextField("API-Schlüssel", text: $apiKey)
                        } else {
                            SecureField("API-Schlüssel", text: $apiKey)
                        }
                        
                        Button(showApiKey ? "Verstecken" : "Anzeigen") {
                            showApiKey.toggle()
                        }
                    }
                    
                    Button("Speichern") {
                        saveApiKey()
                    }
                    .disabled(apiKey.isEmpty)
                }
                
                Section("Information") {
                    Text("Der Notion API-Schlüssel ist in Ihren Einstellungen gespeichert.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("API-Schlüssel in Notion erstellen", 
                         destination: URL(string: "https://www.notion.so/my-integrations")!)
                        .font(.caption)
                }
                
                Section("Rate Limit Status") {
                    Text("Max 100 Requests/Minute")
                        .font(.caption)
                    
                    Text("Max 3 Requests/Sekunde")
                        .font(.caption)
                }
            }
            .navigationTitle("Notion Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            apiKey = UserDefaults.standard.string(forKey: "NotionAPIKey") ?? ""
        }
    }
    
    private func saveApiKey() {
        notionIntegration.setApiKey(apiKey)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Template Picker View
struct TemplatePickerView: View {
    let templates: [NotionTemplate]
    let onSelect: (NotionTemplate) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templates, id: \.name) { template in
                    VStack(alignment: .leading) {
                        Text(template.name)
                            .font(.headline)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        onSelect(template)
                    }
                }
            }
            .navigationTitle("Template wählen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Webhook Setup View
struct WebhookSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var webhookManager: NotionWebhookManager
    
    @State private var webhookUrl = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "link")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Webhook Setup")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Konfigurieren Sie einen Webhook für Echtzeit-Synchronisation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Webhook URL:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("https://your-webhook-url.com", text: $webhookUrl)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                Button("Verbinden") {
                    connectToWebhook()
                }
                .disabled(webhookUrl.isEmpty)
                .buttonStyle(.borderedProminent)
                
                if webhookManager.isConnected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Verbunden")
                            .foregroundColor(.green)
                    }
                } else if let error = webhookManager.connectionError {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Verbindung fehlgeschlagen")
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Webhooks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func connectToWebhook() {
        Task {
            do {
                try await webhookManager.connect(endpoint: webhookUrl)
            } catch {
                webhookManager.connectionError = error
            }
        }
    }
}

// MARK: - Preview
struct NotionDatabaseView_Previews: PreviewProvider {
    static var previews: some View {
        NotionDatabaseView()
    }
}