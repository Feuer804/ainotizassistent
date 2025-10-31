import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("language") private var language = "Deutsch"
    @AppStorage("fontSize") private var fontSize: Double = 16
    @AppStorage("backupEnabled") private var backupEnabled = true
    @AppStorage("biometricAuth") private var biometricAuth = false
    
    @State private var showingLanguagePicker = false
    @State private var showingAboutSheet = false
    @State private var showingContactSheet = false
    @State private var showingExportData = false
    @State private var showingDeleteData = false
    
    let languages = ["Deutsch", "English", "Español", "Français", "Italiano"]
    
    var body: some View {
        ZStack {
            // Background mit Animation
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.4),
                    Color.pink.opacity(0.3),
                    Color.indigo.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .hueRotation(.degrees(isDarkMode ? 180 : 0))
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Einstellungen")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Personalisiere deine App-Erfahrung")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            // App Icon
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "gearshape.2.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .white.opacity(0.1), radius: 10, x: 0, y: 4)
                        }
                    }
                    .padding(.top)
                    
                    // Darstellung
                    SettingsSection(title: "Darstellung") {
                        SettingsToggleRow(
                            icon: "moon.fill",
                            title: "Dunkler Modus",
                            subtitle: "Elegantes dunkles Design",
                            isOn: $isDarkMode
                        )
                        
                        SettingsSliderRow(
                            icon: "textformat.size",
                            title: "Schriftgröße",
                            subtitle: "\(Int(fontSize))pt",
                            value: $fontSize,
                            range: 12...24
                        )
                    }
                    
                    // Benachrichtigungen
                    SettingsSection(title: "Benachrichtigungen") {
                        SettingsToggleRow(
                            icon: "bell.fill",
                            title: "Push-Benachrichtigungen",
                            subtitle: "Erhalte wichtige Updates",
                            isOn: $notificationsEnabled
                        )
                        
                        SettingsToggleRow(
                            icon: "checkmark.circle",
                            title: "Auto-Speichern",
                            subtitle: "Automatische Speicherung",
                            isOn: $autoSave
                        )
                    }
                    
                    // Datenschutz & Sicherheit
                    SettingsSection(title: "Datenschutz & Sicherheit") {
                        SettingsToggleRow(
                            icon: "faceid",
                            title: "Biometrische Authentifizierung",
                            subtitle: "Touch ID oder Face ID verwenden",
                            isOn: $biometricAuth
                        )
                        
                        SettingsToggleRow(
                            icon: "icloud.fill",
                            title: "Cloud-Backup",
                            subtitle: "Daten in der Cloud sichern",
                            isOn: $backupEnabled
                        )
                        
                        SettingsRow(
                            icon: "globe",
                            title: "Sprache",
                            subtitle: language,
                            destination: { LanguagePickerView(selectedLanguage: $language) }
                        )
                    }
                    
                    // App-Info
                    SettingsSection(title: "App-Info") {
                        SettingsRow(
                            icon: "info.circle",
                            title: "Über diese App",
                            subtitle: "Version und Informationen",
                            destination: { AboutView() }
                        )
                        
                        SettingsRow(
                            icon: "envelope",
                            title: "Kontakt",
                            subtitle: "Support und Feedback",
                            destination: { ContactView() }
                        )
                        
                        SettingsRow(
                            icon: "star",
                            title: "App bewerten",
                            subtitle: "Deine Meinung ist wichtig",
                            action: { rateApp() }
                        )
                    }
                    
                    // Datenverwaltung
                    SettingsSection(title: "Datenverwaltung") {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "Daten exportieren",
                            subtitle: "Sichere deine Daten",
                            action: { showingExportData = true }
                        )
                        
                        SettingsRow(
                            icon: "trash",
                            title: "Alle Daten löschen",
                            subtitle: "Irreversibel alle Daten entfernen",
                            iconColor: .red.opacity(0.8),
                            action: { showingDeleteData = true }
                        )
                    }
                    
                    // App Version
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text("All-in-One App")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("Version 1.0.0")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("Entwickelt mit ❤️")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView(selectedLanguage: $language)
        }
        .sheet(isPresented: $showingAboutSheet) {
            AboutView()
        }
        .sheet(isPresented: $showingContactSheet) {
            ContactView()
        }
        .alert("Daten exportieren", isPresented: $showingExportData) {
            Button("OK") { }
        } message: {
            Text("Deine Daten werden als JSON-Datei exportiert.")
        }
        .alert("Alle Daten löschen?", isPresented: $showingDeleteData) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden. Alle deine Notizen, To-Dos und anderen Daten werden permanent gelöscht.")
        }
    }
    
    func rateApp() {
        // Rate app functionality - would typically open App Store
    }
    
    func deleteAllData() {
        // Delete all app data
    }
}

// Settings Section Wrapper
struct SettingsSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                content()
            }
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    @AppStorage("accentColor") private var accentColor = "Blue"
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isOn ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(12)
    }
}

// Slider Row
struct SettingsSliderRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Slider
            Slider(
                value: $value,
                in: range,
                step: 1
            )
            .tint(.purple)
            .frame(width: 100)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.clear)
        .cornerRadius(12)
    }
}

// Navigation Row
struct SettingsRow<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let destination: () -> Destination
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        iconColor: Color = .blue.opacity(0.2),
        destination: @escaping () -> Destination,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self._destination = State(initialValue: destination())
        self.destination = destination
        self.action = action
    }
    
    @State private var showingDestination = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(iconColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Chevron or Icon
            if action != nil {
                Image(systemName: "checkmark")
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.clear)
        .cornerRadius(12)
        .onTapGesture {
            if let action = action {
                action()
            } else {
                showingDestination = true
            }
        }
        .sheet(isPresented: $showingDestination) {
            destination()
                .preferredColorScheme(.dark)
        }
    }
    
    @ViewBuilder
    var destination: some View {
        destination()
    }
}

// Language Picker View
struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss
    
    let languages = ["Deutsch", "English", "Español", "Français", "Italiano", "Português", "中文", "日本語", "한국어"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                        dismiss()
                    }) {
                        HStack {
                            Text(language)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sprache auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon Large
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 8)
                
                VStack(spacing: 8) {
                    Text("All-in-One App")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Version 1.0.0")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "note.text", title: "Notizen", description: "Erstelle und organisiere deine Gedanken")
                    FeatureRow(icon: "doc.text", title: "Zusammenfassungen", description: "Automatische Textzusammenfassungen")
                    FeatureRow(icon: "checklist", title: "To-Do Listen", description: "Verwalte deine Aufgaben effizient")
                    FeatureRow(icon: "person.3", title: "Meeting Recaps", description: "Dokumentiere wichtige Meeting-Details")
                    FeatureRow(icon: "gearshape", title: "Anpassungen", description: "Vollständig anpassbare Benutzeroberfläche")
                }
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Text("Entwickelt mit ❤️ für maximale Produktivität")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("Besuche unsere Website für Updates und Support")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("Über die App")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fertig") {
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// Contact View
struct ContactView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var message = ""
    
    let supportEmail = "support@app.com"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Contact Options
                    VStack(spacing: 12) {
                        ContactOptionRow(
                            icon: "envelope.fill",
                            title: "E-Mail senden",
                            subtitle: supportEmail,
                            action: { openEmail() }
                        )
                        
                        ContactOptionRow(
                            icon: "message.fill",
                            title: "Feedback",
                            subtitle: "Teile deine Meinung mit",
                            action: { sendFeedback() }
                        )
                        
                        ContactOptionRow(
                            icon: "questionmark.circle.fill",
                            title: "Hilfe & FAQ",
                            subtitle: "Häufige Fragen beantwortet",
                            action: { openHelp() }
                        )
                    }
                    
                    // Feedback Form
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Schnelles Feedback")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Betreff")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Feedback Betreff", text: $subject)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nachricht")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextEditor(text: $message)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Button(action: { sendFormFeedback() }) {
                            Text("Feedback senden")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled(subject.isEmpty || message.isEmpty)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("Kontakt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    func openEmail() {
        // Open email client
    }
    
    func sendFeedback() {
        // Navigate to feedback screen
    }
    
    func openHelp() {
        // Open help documentation
    }
    
    func sendFormFeedback() {
        // Send feedback form
    }
}

// Contact Option Row Component
struct ContactOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}