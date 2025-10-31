import SwiftUI

struct MeetingView: View {
    @State private var meetingTitle = ""
    @State private var meetingDate = Date()
    @State private var participants: [String] = []
    @State private var newParticipant = ""
    @State private var agenda = ""
    @State private var decisions = ""
    @State private var actionItems = ""
    @State private var notes = ""
    @State private var showingSaveAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meeting Recap")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Dokumentiere wichtige Meeting-Details")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top)
                
                // Meeting Details
                VStack(alignment: .leading, spacing: 16) {
                    // Titel
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meeting-Titel")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        TextField("z.B. Sprint Planning Meeting", text: $meetingTitle)
                            .textFieldStyle(MeetingTextFieldStyle())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.sentences)
                    }
                    
                    // Datum und Uhrzeit
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Datum und Uhrzeit")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        HStack {
                            DatePicker("", selection: $meetingDate, displayedComponents: [.date, .hour])
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                
                // Teilnehmer
                VStack(alignment: .leading, spacing: 12) {
                    Text("Teilnehmer")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    // Aktuelle Teilnehmer
                    if !participants.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(participants, id: \.self) { participant in
                                ParticipantChip(
                                    name: participant,
                                    onRemove: { removeParticipant(participant) }
                                )
                            }
                        }
                    }
                    
                    // Neuen Teilnehmer hinzufügen
                    HStack {
                        TextField("Name eingeben...", text: $newParticipant)
                            .textFieldStyle(ParticipantTextFieldStyle())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                        
                        Button(action: addParticipant) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .disabled(newParticipant.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                
                // Agenda
                VStack(alignment: .leading, spacing: 8) {
                    Text("Agenda")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $agenda)
                        .frame(height: 100)
                        .scrollContentBackground(.hidden)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            agenda.isEmpty ? PlaceholderText("Besprechungspunkte und Themen...") : nil,
                            alignment: .topLeading
                        )
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.sentences)
                }
                
                // Entscheidungen
                VStack(alignment: .leading, spacing: 8) {
                    Text("Entscheidungen")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $decisions)
                        .frame(height: 100)
                        .scrollContentBackground(.hidden)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            decisions.isEmpty ? PlaceholderText("Wichtige Entscheidungen und Beschlüsse...") : nil,
                            alignment: .topLeading
                        )
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.sentences)
                }
                
                // Action Items
                VStack(alignment: .leading, spacing: 8) {
                    Text("Action Items")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $actionItems)
                        .frame(height: 100)
                        .scrollContentBackground(.hidden)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            actionItems.isEmpty ? PlaceholderText("Zu erledigende Aufgaben mit Verantwortlichen...") : nil,
                            alignment: .topLeading
                        )
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.sentences)
                }
                
                // Notizen
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notizen")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $notes)
                        .frame(height: 120)
                        .scrollContentBackground(.hidden)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            notes.isEmpty ? PlaceholderText("Zusätzliche Notizen, Diskussionspunkte oder wichtige Informationen...") : nil,
                            alignment: .topLeading
                        )
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.sentences)
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: generateRecap) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Auto Recap")
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    
                    Button(action: saveRecap) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Speichern")
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                }
                .padding(.bottom)
            }
            .padding(.horizontal)
        }
        .background(.clear)
        .alert("Meeting Recap gespeichert!", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    func addParticipant() {
        let name = newParticipant.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty && !participants.contains(name) {
            participants.append(name)
            newParticipant = ""
        }
    }
    
    func removeParticipant(_ participant: String) {
        participants.removeAll { $0 == participant }
    }
    
    func generateRecap() {
        // Auto-generate meeting recap based on input
        let recap = """
        MEETING RECAP
       ━━━━━━━━━━━━━
        
        Titel: \(meetingTitle.isEmpty ? "Untitled Meeting" : meetingTitle)
        Datum: \(meetingDate.formatted(date: .abbreviated, time: .shortened))
        
        TEILNEHMER
        \(participants.joined(separator: ", "))
        
        BESPROCHENE THEMEN
        \(agenda.isEmpty ? "Keine Agenda angegeben" : agenda)
        
        ENTSCHEIDUNGEN
        \(decisions.isEmpty ? "Keine Entscheidungen dokumentiert" : decisions)
        
        ACTION ITEMS
        \(actionItems.isEmpty ? "Keine Action Items definiert" : actionItems)
        
        ZUSÄTZLICHE NOTIZEN
        \(notes.isEmpty ? "Keine zusätzlichen Notizen" : notes)
        
       ━━━━━━━━━━━━━
        """
        
        UIPasteboard.general.string = recap
    }
    
    func saveRecap() {
        showingSaveAlert = true
        // Hier würde die tatsächliche Speicherung stattfinden
    }
}

// Meeting TextField Style
struct MeetingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.title3)
            .foregroundColor(.white)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// Participant TextField Style
struct ParticipantTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundColor(.white)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// Participant Chip Komponente
struct ParticipantChip: View {
    let name: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            // Avatar Circle
            Circle()
                .fill(avatarColor(for: name))
                .frame(width: 24, height: 24)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.15))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    func avatarColor(for name: String) -> Color {
        let colors: [Color] = [
            .blue.opacity(0.8),
            .green.opacity(0.8),
            .purple.opacity(0.8),
            .orange.opacity(0.8),
            .pink.opacity(0.8),
            .indigo.opacity(0.8)
        ]
        
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}

// Placeholder Text
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

// Meeting Template Picker
struct MeetingTemplatePicker: View {
    let templates = [
        MeetingTemplate(name: "Sprint Planning", icon: "calendar.badge.plus"),
        MeetingTemplate(name: "Standup", icon: "person.2"),
        MeetingTemplate(name: "Retrospektive", icon: "chart.line.uptrend.xyaxis"),
        MeetingTemplate(name: "Review", icon: "checkmark.seal")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(templates, id: \.name) { template in
                    Button(action: {
                        // Apply template
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: template.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(template.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .frame(width: 80)
                        .background(.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MeetingTemplate {
    let name: String
    let icon: String
}

// Quick Actions Toolbar
struct MeetingQuickActions: View {
    @State private var showingShareSheet = false
    @State private var showingExportOptions = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Teilen
            Button(action: { showingShareSheet = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    Text("Teilen")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
            }
            
            // Exportieren
            Button(action: { showingExportOptions = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "doc.export")
                        .font(.system(size: 16))
                    Text("Export")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
            }
            
            // Kopieren
            Button(action: {
                // Copy to clipboard
                UIPasteboard.general.string = "Meeting Recap copied to clipboard"
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16))
                    Text("Kopieren")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
            }
            
            // Kalender
            Button(action: {
                // Add to calendar
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16))
                    Text("Kalender")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    MeetingView()
        .preferredColorScheme(.dark)
}