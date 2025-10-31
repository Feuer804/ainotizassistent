import SwiftUI

struct NotizView: View {
    @State private var notizText = ""
    @State private var notizTitel = ""
    @State private var selectedKategorie = "Persönlich"
    @State private var showingSaveAlert = false
    
    let kategorien = ["Persönlich", "Arbeit", "Ideen", "Einkaufsliste", "Termine"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Neue Notiz")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Erstelle und organisiere deine Gedanken")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Kategorie Dropdown
                    Menu {
                        ForEach(kategorien, id: \.self) { kategorie in
                            Button(kategorie) {
                                selectedKategorie = kategorie
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.white)
                            Text(selectedKategorie)
                                .foregroundColor(.white)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.15))
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.top)
                
                // Titel Eingabe
                VStack(alignment: .leading, spacing: 8) {
                    Text("Titel")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    TextField("Gib einen Titel ein...", text: $notizTitel)
                        .textFieldStyle(NotizTextFieldStyle())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.sentences)
                }
                
                // Kategorien Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(kategorien, id: \.self) { kategorie in
                        CategoryCard(
                            kategorie: kategorie,
                            isSelected: selectedKategorie == kategorie
                        ) {
                            selectedKategorie = kategorie
                        }
                    }
                }
                
                // Haupttext Bereich
                VStack(alignment: .leading, spacing: 8) {
                    Text("Inhalt")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    ZStack {
                        if notizText.isEmpty {
                            TextEditor(text: .constant(""))
                                .frame(minHeight: 200)
                                .disabled(true)
                                .overlay {
                                    Text("Beschreibe deine Ideen, Gedanken oder wichtige Informationen...")
                                        .foregroundColor(.white.opacity(0.5))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                        }
                        
                        TextEditor(text: $notizText)
                            .frame(minHeight: 200)
                            .opacity(notizText.isEmpty ? 0 : 1)
                            .scrollContentBackground(.hidden)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.1), lineWidth: 2)
                            )
                    }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.sentences)
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        saveNotiz()
                    }) {
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
                    
                    Button(action: {
                        notizText = ""
                        notizTitel = ""
                        selectedKategorie = "Persönlich"
                    }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                            Text("Löschen")
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                }
                .padding(.bottom)
            }
            .padding(.horizontal)
        }
        .background(.clear)
        .alert("Notiz gespeichert!", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    func saveNotiz() {
        showingSaveAlert = true
        // Hier würde die tatsächliche Speicherung stattfinden
    }
}

// Benutzerdefiniertes TextField-Style
struct NotizTextFieldStyle: TextFieldStyle {
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
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.1), lineWidth: 2)
            )
    }
}

// Kategorien Card Komponente
struct CategoryCard: View {
    let kategorie: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: categoryIcon(kategorie))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Text(kategorie)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .multilineTextAlignment(.center)
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
    
    func categoryIcon(_ kategorie: String) -> String {
        switch kategorie {
        case "Persönlich": return "person.crop.circle"
        case "Arbeit": return "briefcase.fill"
        case "Ideen": return "lightbulb.fill"
        case "Einkaufsliste": return "cart.fill"
        case "Termine": return "calendar.fill"
        default: return "folder.fill"
        }
    }
}

#Preview {
    NotizView()
        .preferredColorScheme(.dark)
}