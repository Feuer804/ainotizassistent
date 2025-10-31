import SwiftUI
import UniformTypeIdentifiers

struct MeetingRecapView: View {
    @StateObject private var generator = MeetingRecapGenerator()
    @State private var meetingContent = ""
    @State private var meetingMetadata = MeetingRecapGenerator.MeetingMetadata(
        title: "",
        date: Date(),
        duration: 3600, // 1 hour
        location: nil,
        platform: nil,
        facilitator: nil
    )
    
    // Generated recap data
    @State private var currentRecap: MeetingRecap?
    @State private var isGenerating = false
    @State private var showingSaveSheet = false
    @State private var showingExportSheet = false
    @State private var showingAnalytics = false
    
    // Filter states
    @State private var selectedTab = 0
    @State private var filterCategory = "Alle"
    @State private var sortBy = "Datum"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    meetingHeaderSection
                    
                    // Input Section
                    meetingInputSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Generated Recap Display
                    if let recap = currentRecap {
                        meetingRecapSection(recap)
                    }
                    
                    // Templates Section
                    templatesSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(LinearGradient(colors: [
                Color.black.opacity(0.9),
                Color.blue.opacity(0.3),
                Color.purple.opacity(0.3)
            ], startPoint: .topLeading, endPoint: .bottomTrailing))
            .navigationTitle("Meeting Recap")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentRecap != nil {
                        Button("Analysieren") {
                            showingAnalytics = true
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveRecapSheet(recap: currentRecap)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportOptionsSheet(recap: currentRecap)
        }
        .sheet(isPresented: $showingAnalytics) {
            MeetingAnalyticsView(recap: currentRecap)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Meeting Header Section
    private var meetingHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Meeting Recap Generator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if currentRecap != nil {
                    Button(action: { showingAnalytics = true }) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            
            Text("Generiere automatisch umfassende Meeting-Zusammenfassungen mit allen wichtigen Details")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - Meeting Input Section
    private var meetingInputSection: some View {
        VStack(spacing: 16) {
            // Meeting Metadata
            meetingMetadataSection
            
            // Content Input
            meetingContentInputSection
        }
    }
    
    private var meetingMetadataSection: some View {
        VStack(spacing: 12) {
            Text("Meeting Details")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Title
                TextField("Meeting-Titel", text: $meetingMetadata.title)
                    .textFieldStyle(GlassTextFieldStyle())
                    .autocorrectionDisabled()
                
                // Date and Duration
                HStack {
                    VStack(alignment: .leading) {
                        Text("Datum")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        DatePicker("", selection: $meetingMetadata.date, displayedComponents: [.date])
                            .labelsHidden()
                            .colorScheme(.dark)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Dauer (Minuten)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("60", value: Binding(
                            get: { Int(meetingMetadata.duration / 60) },
                            set: { meetingMetadata.duration = TimeInterval($0 * 60) }
                        ), format: .number)
                        .textFieldStyle(GlassTextFieldStyle())
                        .frame(width: 80)
                    }
                }
                
                // Location and Platform
                HStack {
                    TextField("Ort (optional)", text: Binding(
                        get: { meetingMetadata.location ?? "" },
                        set: { meetingMetadata.location = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(GlassTextFieldStyle())
                    
                    TextField("Plattform (optional)", text: Binding(
                        get: { meetingMetadata.platform ?? "" },
                        set: { meetingMetadata.platform = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(GlassTextFieldStyle())
                }
                
                // Facilitator
                TextField("Moderator (optional)", text: Binding(
                    get: { meetingMetadata.facilitator ?? "" },
                    set: { meetingMetadata.facilitator = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(GlassTextFieldStyle())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var meetingContentInputSection: some View {
        VStack(spacing: 12) {
            Text("Meeting-Inhalt")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                TextEditor(text: $meetingContent)
                    .frame(minHeight: 200, maxHeight: 400)
                    .scrollContentBackground(.hidden)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
                    .overlay(
                        meetingContent.isEmpty ? PlaceholderText("Füge hier den Meeting-Text ein oder nutze Voice-to-Text...") : nil,
                        alignment: .topLeading
                    )
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.sentences)
                
                // Input helpers
                HStack {
                    Button("Voice Input") {
                        // Implement voice input
                    }
                    .buttonStyle(GlassButtonStyle(icon: "mic"))
                    
                    Button("Template laden") {
                        loadTemplate()
                    }
                    .buttonStyle(GlassButtonStyle(icon: "doc.text"))
                    
                    Spacer()
                    
                    Button("Generieren") {
                        generateRecap()
                    }
                    .disabled(meetingContent.isEmpty || meetingMetadata.title.isEmpty || isGenerating)
                    .buttonStyle(GlassButtonStyle(icon: "wand.and.stars", variant: .primary))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ActionButton(title: "Auto-Zusammenfassung", icon: "wand.and.stars", action: generateRecap)
                ActionButton(title: "Exportieren", icon: "square.and.arrow.up", action: { showingExportSheet = true })
                ActionButton(title: "Speichern", icon: "checkmark.circle", action: { showingSaveSheet = true })
                ActionButton(title: "Kalender", icon: "calendar.badge.plus", action: addToCalendar)
                ActionButton(title: "Teilen", icon: "person.2", action: shareRecap)
                ActionButton(title: "Analysieren", icon: "chart.bar.xaxis", action: { showingAnalytics = true })
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Meeting Recap Section
    private func meetingRecapSection(_ recap: MeetingRecap) -> some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Generierte Zusammenfassung", subtitle: "Automatisch erstellt")
            
            // Tab Selection
            Picker("Ansicht", selection: $selectedTab) {
                Text("Übersicht").tag(0)
                Text("Teilnehmer").tag(1)
                Text("Entscheidungen").tag(2)
                Text("Action Items").tag(3)
                Text("Timeline").tag(4)
                Text("Analyse").tag(5)
            }
            .pickerStyle(SegmentedPickerStyle())
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            
            // Tab Content
            switch selectedTab {
            case 0:
                meetingOverviewTab(recap)
            case 1:
                participantsTab(recap)
            case 2:
                decisionsTab(recap)
            case 3:
                actionItemsTab(recap)
            case 4:
                timelineTab(recap)
            case 5:
                analyticsTab(recap)
            default:
                meetingOverviewTab(recap)
            }
        }
    }
    
    private func meetingOverviewTab(_ recap: MeetingRecap) -> some View {
        VStack(spacing: 16) {
            // Basic Info
            InfoCard(title: "Meeting Details") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "Titel", value: recap.title)
                    InfoRow(label: "Datum", value: recap.date.formatted(date: .abbreviated, time: .shortened))
                    InfoRow(label: "Typ", value: recap.type.rawValue)
                    InfoRow(label: "Dauer", value: "\(Int(recap.duration / 60)) Minuten")
                    if let location = recap.location {
                        InfoRow(label: "Ort", value: location)
                    }
                    if let platform = recap.platform {
                        InfoRow(label: "Plattform", value: platform)
                    }
                }
            }
            
            // Key Statistics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                StatCard(title: "Teilnehmer", value: "\(recap.participants.count)", icon: "person.2")
                StatCard(title: "Entscheidungen", value: "\(recap.decisions.count)", icon: "checkmark.seal")
                StatCard(title: "Action Items", value: "\(recap.actionItems.count)", icon: "checklist")
                StatCard(title: "Diskussionen", value: "\(recap.discussionPoints.count)", icon: "bubble.left.and.bubble.right")
                StatCard(title: "Risiken", value: "\(recap.risks.count)", icon: "exclamationmark.triangle")
                StatCard(title: "Effizienz", value: "\(Int(recap.meetingEffectiveness.overallScore))%", icon: "chart.line.uptrend.xyaxis")
            }
            
            // Summary
            InfoCard(title: "Zusammenfassung") {
                Text(recap.summary)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private func participantsTab(_ recap: MeetingRecap) -> some View {
        VStack(spacing: 16) {
            InfoCard(title: "Teilnehmer (\(recap.participants.count))") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(recap.participants) { participant in
                        ParticipantDetailCard(participant: participant)
                    }
                }
            }
            
            if !recap.followUpReminders.isEmpty {
                InfoCard(title: "Follow-up Erinnerungen") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recap.followUpReminders.prefix(5)) { reminder in
                            ReminderRow(reminder: reminder)
                        }
                    }
                }
            }
        }
    }
    
    private func decisionsTab(_ recap: MeetingRecap) -> some View {
        VStack(spacing: 16) {
            ForEach(recap.decisions) { decision in
                DecisionCard(decision: decision)
            }
        }
    }
    
    private func actionItemsTab(_ recap: MeetingRecap) -> some View {
        VStack(spacing: 16) {
            // Filter and Sort
            HStack {
                Picker("Kategorie", selection: $filterCategory) {
                    Text("Alle").tag("Alle")
                    Text("Entwicklung").tag("development")
                    Text("Test").tag("testing")
                    Text("Dokumentation").tag("documentation")
                }
                .pickerStyle(MenuPickerStyle())
                .textFieldStyle(GlassTextFieldStyle())
                
                Picker("Sortierung", selection: $sortBy) {
                    Text("Priorität").tag("Priorität")
                    Text("Fälligkeit").tag("Fälligkeit")
                    Text("Status").tag("Status")
                }
                .pickerStyle(MenuPickerStyle())
                .textFieldStyle(GlassTextFieldStyle())
            }
            
            // Action Items
            ForEach(filteredActionItems(recap)) { actionItem in
                ActionItemCard(actionItem: actionItem)
            }
        }
    }
    
    private func timelineTab(_ recap: MeetingRecap) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(recap.timeline) { event in
                    TimelineEventCard(event: event)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func analyticsTab(_ recap: MeetingRecap) -> some View {
        VStack(spacing: 16) {
            // Effectiveness Metrics
            InfoCard(title: "Meeting-Effektivität") {
                VStack(spacing: 12) {
                    EffectivenessBar(label: "Teilnahme", value: recap.meetingEffectiveness.participationScore)
                    EffectivenessBar(label: "Entscheidungen", value: recap.meetingEffectiveness.decisionMakingScore)
                    EffectivenessBar(label: "Action Items", value: recap.meetingEffectiveness.actionItemsScore)
                    EffectivenessBar(label: "Engagement", value: recap.meetingEffectiveness.engagementLevel)
                    EffectivenessBar(label: "Effizienz", value: recap.meetingEffectiveness.efficiencyRating)
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    EffectivenessBar(label: "Gesamtbewertung", value: recap.meetingEffectiveness.overallScore, showTotal: true)
                }
            }
            
            // Key Themes
            if !recap.keyThemes.isEmpty {
                InfoCard(title: "Hauptthemen") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(recap.keyThemes, id: \.self) { theme in
                            ThemeChip(theme: theme)
                        }
                    }
                }
            }
            
            // Recommendations
            if !recap.meetingEffectiveness.recommendations.isEmpty {
                InfoCard(title: "Empfehlungen") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recap.meetingEffectiveness.recommendations, id: \.self) { recommendation in
                            RecommendationRow(recommendation: recommendation)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Templates Section
    private var templatesSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Meeting Templates", subtitle: "Schnellstart für häufige Meeting-Typen")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    TemplateCard(
                        title: "Sprint Planning",
                        icon: "calendar.badge.plus",
                        description: "Planung des nächsten Sprints",
                        onTap: { applyTemplate(.planning) }
                    )
                    TemplateCard(
                        title: "Daily Standup",
                        icon: "person.2",
                        description: "Täglicher Status Update",
                        onTap: { applyTemplate(.standup) }
                    )
                    TemplateCard(
                        title: "Retrospektive",
                        icon: "chart.line.uptrend.xyaxis",
                        description: "Reflexion und Verbesserungen",
                        onTap: { applyTemplate(.retrospective) }
                    )
                    TemplateCard(
                        title: "Review",
                        icon: "checkmark.seal",
                        description: "Review von Deliverables",
                        onTap: { applyTemplate(.review) }
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateRecap() {
        guard !meetingContent.isEmpty && !meetingMetadata.title.isEmpty else { return }
        
        isGenerating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let recap = generator.generateMeetingRecap(
                from: meetingContent,
                metadata: meetingMetadata
            )
            
            DispatchQueue.main.async {
                self.currentRecap = recap
                self.isGenerating = false
            }
        }
    }
    
    private func loadTemplate() {
        // Load a template into the content field
        meetingContent = """
        AGENDA:
        1. Status Updates
        2. Aktuelle Herausforderungen
        3. Nächste Schritte
        
        TEILNEHMER:
        John Doe (Product Manager)
        Jane Smith (Development Lead)
        
        BESPRECHUNG:
        Der aktuelle Sprint läuft gut. Wir haben 80% der geplanten Features abgeschlossen.
        Es gibt ein technisches Problem mit der Datenbank-Performance.
        
        ENTSCHEIDUNGEN:
        Wir haben beschlossen, die Performance-Optimierung vorzuziehen.
        
        ACTION ITEMS:
        - Jane erstellt einen Plan für die Performance-Optimierung (bis Freitag)
        - John klärt mit dem Kunden den neuen Zeitplan
        """
    }
    
    private func applyTemplate(_ type: MeetingType) {
        meetingMetadata.title = type.rawValue
        meetingMetadata.facilitator = "Team Lead"
        
        switch type {
        case .planning:
            meetingContent = "Meeting zur Planung der nächsten Projektphase..."
        case .standup:
            meetingContent = "Daily Standup - Status Updates aller Teammitglieder..."
        case .retrospective:
            meetingContent = "Retrospektive - Was lief gut, was kann verbessert werden..."
        case .review:
            meetingContent = "Review Meeting - Bewertung der erledigten Arbeit..."
        default:
            break
        }
    }
    
    private func filteredActionItems(_ recap: MeetingRecap) -> [ActionItem] {
        let filtered = recap.actionItems.filter { actionItem in
            filterCategory == "Alle" || actionItem.category.rawValue.lowercased() == filterCategory.lowercased()
        }
        
        return filtered.sorted { action1, action2 in
            switch sortBy {
            case "Priorität":
                return action1.priority.rawValue > action2.priority.rawValue
            case "Fälligkeit":
                return (action1.dueDate ?? Date.distantFuture) < (action2.dueDate ?? Date.distantFuture)
            case "Status":
                return action1.status.rawValue < action2.status.rawValue
            default:
                return true
            }
        }
    }
    
    private func addToCalendar() {
        // Add to calendar functionality
        print("Adding to calendar...")
    }
    
    private func shareRecap() {
        // Share recap functionality
        print("Sharing recap...")
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, subtitle: nil)
            content
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundColor(.white)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct GlassButtonStyle: ButtonStyle {
    let icon: String
    let variant: ButtonVariant
    
    enum ButtonVariant {
        case primary
        case secondary
    }
    
    init(icon: String, variant: ButtonVariant = .secondary) {
        self.icon = icon
        self.variant = variant
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                variant == .primary ?
                LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)], startPoint: .leading, endPoint: .trailing) :
                .ultraThinMaterial
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ParticipantDetailCard: View {
    let participant: Participant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(participant.name.prefix(1)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if let role = participant.role {
                        Text(role)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                ParticipationLevelIndicator(level: participant.participationLevel)
            }
            
            if let department = participant.department {
                HStack {
                    Text("Abteilung:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(department)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ParticipationLevelIndicator: View {
    let level: Participant.ParticipationLevel
    
    var body: some View {
        Text(level.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(level.color == "grün" ? Color.green.opacity(0.3) :
                          level.color == "orange" ? Color.orange.opacity(0.3) :
                          level.color == "grau" ? Color.gray.opacity(0.3) :
                          Color.blue.opacity(0.3))
            )
            .foregroundColor(.white)
    }
}

struct DecisionCard: View {
    let decision: DecisionPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ImpactLevelIndicator(level: decision.impact)
                
                Spacer()
                
                if decision.requiresFollowUp {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Text(decision.description)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            if !decision.rationale.isEmpty && decision.rationale != "Keine Begründung angegeben" {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Begründung:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(decision.rationale)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
            }
            
            if !decision.consequences.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auswirkungen:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(decision.consequences!)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ImpactLevelIndicator: View {
    let level: ImpactLevel
    
    var body: some View {
        Text(level.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(level.color == "grün" ? Color.green.opacity(0.3) :
                          level.color == "gelb" ? Color.yellow.opacity(0.3) :
                          level.color == "orange" ? Color.orange.opacity(0.3) :
                          Color.red.opacity(0.3))
            )
            .foregroundColor(.white)
    }
}

struct ActionItemCard: View {
    let actionItem: ActionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PriorityIndicator(priority: actionItem.priority)
                
                Spacer()
                
                StatusIndicator(status: actionItem.status)
            }
            
            Text(actionItem.title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            HStack {
                Text("Zugewiesen:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(actionItem.assignedTo)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let dueDate = actionItem.dueDate {
                HStack {
                    Text("Fällig:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            
            // Progress bar
            if actionItem.progress > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fortschritt")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    ProgressView(value: actionItem.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct PriorityIndicator: View {
    let priority: ActionItem.Priority
    
    var body: some View {
        Text(priority.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(priority == .urgent ? Color.red.opacity(0.3) :
                          priority == .high ? Color.orange.opacity(0.3) :
                          priority == .medium ? Color.yellow.opacity(0.3) :
                          Color.gray.opacity(0.3))
            )
            .foregroundColor(.white)
    }
}

struct StatusIndicator: View {
    let status: ActionItem.Status
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status == .completed ? Color.green.opacity(0.3) :
                          status == .inProgress ? Color.blue.opacity(0.3) :
                          status == .blocked ? Color.red.opacity(0.3) :
                          Color.gray.opacity(0.3))
            )
            .foregroundColor(.white)
    }
}

struct TimelineEventCard: View {
    let event: TimelineEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                CategoryIndicator(category: event.category)
            }
            
            Text(event.event)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            
            if !event.participants.isEmpty {
                HStack {
                    Image(systemName: "person.2")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(event.participants.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
        }
        .frame(width: 200)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct CategoryIndicator: View {
    let category: TimelineEvent.TimelineCategory
    
    var body: some View {
        Text(category.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(categoryColor(for: category))
            )
            .foregroundColor(.white)
    }
    
    private func categoryColor(for category: TimelineEvent.TimelineCategory) -> Color {
        switch category {
        case .decision: return Color.green.opacity(0.3)
        case .action: return Color.blue.opacity(0.3)
        case .conflict: return Color.red.opacity(0.3)
        case .agreement: return Color.green.opacity(0.3)
        case .agenda: return Color.purple.opacity(0.3)
        case .break: return Color.gray.opacity(0.3)
        case .technical: return Color.orange.opacity(0.3)
        case .discussion: return Color.blue.opacity(0.3)
        }
    }
}

struct EffectivenessBar: View {
    let label: String
    let value: Double
    let showTotal: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(value))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            ProgressView(value: value, total: 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: showTotal ? .yellow : .white))
                .scaleEffect(y: showTotal ? 1.5 : 1.0)
        }
    }
}

struct ThemeChip: View {
    let theme: String
    
    var body: some View {
        Text(theme)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.purple.opacity(0.3))
            )
            .foregroundColor(.white)
    }
}

struct RecommendationRow: View {
    let recommendation: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)
                .frame(width: 16, height: 16)
            
            Text(recommendation)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct ReminderRow: View {
    let reminder: FollowUpReminder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Fällig: \(reminder.dueDate, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            PriorityIndicator(priority: reminder.priority)
        }
    }
}

struct TemplateCard: View {
    let title: String
    let icon: String
    let description: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 120)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sheet Views

struct SaveRecapSheet: View {
    let recap: MeetingRecap?
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let recap = recap {
                    Text("Meeting Recap speichern")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Titel: \(recap.title)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button("Als PDF speichern") {
                        saveAsPDF(recap)
                    }
                    .buttonStyle(GlassButtonStyle(icon: "doc", variant: .primary))
                    
                    Button("In Datei speichern") {
                        saveAsFile(recap)
                    }
                    .buttonStyle(GlassButtonStyle(icon: "folder"))
                    
                    Button("Schließen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(GlassButtonStyle(icon: "xmark", variant: .secondary))
                } else {
                    Text("Kein Recap verfügbar")
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding()
            .background(.black.opacity(0.9))
        }
        .preferredColorScheme(.dark)
    }
    
    private func saveAsPDF(_ recap: MeetingRecap) {
        // Implement PDF saving
        print("Saving as PDF...")
        showingSuccess = true
    }
    
    private func saveAsFile(_ recap: MeetingRecap) {
        // Implement file saving
        print("Saving as file...")
        showingSuccess = true
    }
}

struct ExportOptionsSheet: View {
    let recap: MeetingRecap?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export-Optionen")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let recap = recap {
                    Button("Als Text teilen") {
                        shareAsText(recap)
                    }
                    .buttonStyle(GlassButtonStyle(icon: "text.alignleft", variant: .primary))
                    
                    Button("Als PDF exportieren") {
                        exportAsPDF(recap)
                    }
                    .buttonStyle(GlassButtonStyle(icon: "doc.pdf"))
                    
                    Button("Kalendereintrag erstellen") {
                        createCalendarEvent(recap)
                    }
                    .buttonStyle(GlassButtonStyle(icon: "calendar"))
                    
                    Button("E-Mail versenden") {
                        sendAsEmail(recap)
                    }
                    .buttonStyle(GlassButtonStyle(icon: "envelope"))
                }
                
                Button("Schließen") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(GlassButtonStyle(icon: "xmark", variant: .secondary))
                
                Spacer()
            }
            .padding()
            .background(.black.opacity(0.9))
        }
        .preferredColorScheme(.dark)
    }
    
    private func shareAsText(_ recap: MeetingRecap) {
        let text = generateTextExport(recap)
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
    
    private func exportAsPDF(_ recap: MeetingRecap) {
        // Implement PDF export
        print("Exporting as PDF...")
    }
    
    private func createCalendarEvent(_ recap: MeetingRecap) {
        // Implement calendar event creation
        print("Creating calendar event...")
    }
    
    private func sendAsEmail(_ recap: MeetingRecap) {
        // Implement email sending
        print("Sending as email...")
    }
    
    private func generateTextExport(_ recap: MeetingRecap) -> String {
        var export = "MEETING RECAP - \(recap.title)\n"
        export += "=====================================\n\n"
        export += "Datum: \(recap.date.formatted(date: .abbreviated, time: .shortened))\n"
        export += "Typ: \(recap.type.rawValue)\n"
        export += "Dauer: \(Int(recap.duration / 60)) Minuten\n\n"
        
        export += "TEILNEHMER (\(recap.participants.count)):\n"
        for participant in recap.participants {
            export += "• \(participant.name)"
            if let role = participant.role {
                export += " (\(role))"
            }
            export += "\n"
        }
        export += "\n"
        
        export += "ENTSCHEIDUNGEN (\(recap.decisions.count)):\n"
        for decision in recap.decisions {
            export += "• \(decision.description) [\(decision.impact.rawValue)]\n"
        }
        export += "\n"
        
        export += "ACTION ITEMS (\(recap.actionItems.count)):\n"
        for actionItem in recap.actionItems {
            export += "• \(actionItem.title) - \(actionItem.assignedTo) [\(actionItem.priority.rawValue)]\n"
        }
        export += "\n"
        
        export += "ZUSAMMENFASSUNG:\n\(recap.summary)\n\n"
        export += "EFFEKTIVITÄT: \(Int(recap.meetingEffectiveness.overallScore))%\n"
        
        return export
    }
}

struct MeetingAnalyticsView: View {
    let recap: MeetingRecap?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let recap = recap {
                    VStack(spacing: 20) {
                        Text("Meeting-Analyse")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Detailed Analytics
                        AnalyticsSection(title: "Teilnehmer-Analyse") {
                            VStack(alignment: .leading, spacing: 8) {
                                AnalyticsRow(label: "Gesamt Teilnehmer", value: "\(recap.participants.count)")
                                AnalyticsRow(label: "Aktive Teilnehmer", value: "\(recap.participants.filter { $0.participationLevel == .active || $0.participationLevel == .dominant }.count)")
                                AnalyticsRow(label: "Teilnahme-Rate", value: "\(Int(recap.meetingEffectiveness.attendanceRate))%")
                            }
                        }
                        
                        AnalyticsSection(title: "Entscheidungs-Analyse") {
                            VStack(alignment: .leading, spacing: 8) {
                                AnalyticsRow(label: "Gesamt Entscheidungen", value: "\(recap.decisions.count)")
                                AnalyticsRow(label: "Kritische Entscheidungen", value: "\(recap.decisions.filter { $0.impact == .critical }.count)")
                                AnalyticsRow(label: "Follow-up erforderlich", value: "\(recap.decisions.filter { $0.requiresFollowUp }.count)")
                            }
                        }
                        
                        AnalyticsSection(title: "Action Items Analyse") {
                            VStack(alignment: .leading, spacing: 8) {
                                AnalyticsRow(label: "Gesamt Action Items", value: "\(recap.actionItems.count)")
                                AnalyticsRow(label: "Hohe Priorität", value: "\(recap.actionItems.filter { $0.priority == .high || $0.priority == .urgent }.count)")
                                AnalyticsRow(label: "Zugewiesen", value: "\(recap.actionItems.filter { $0.assignedTo != "Unassigned" }.count)")
                            }
                        }
                        
                        AnalyticsSection(title: "Risiko-Analyse") {
                            VStack(alignment: .leading, spacing: 8) {
                                AnalyticsRow(label: "Identifizierte Risiken", value: "\(recap.risks.count)")
                                AnalyticsRow(label: "Hohe Wahrscheinlichkeit", value: "\(recap.risks.filter { $0.probability == .high || $0.probability == .veryHigh }.count)")
                                AnalyticsRow(label: "Hoher Impact", value: "\(recap.risks.filter { $0.impact == .high || $0.impact == .critical }.count)")
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    Text("Keine Analysedaten verfügbar")
                        .foregroundColor(.white)
                }
            }
            .background(.black.opacity(0.9))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct AnalyticsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            content
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct AnalyticsRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Placeholder Text
struct PlaceholderText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.body)
            .foregroundColor(.white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    MeetingRecapView()
        .preferredColorScheme(.dark)
}