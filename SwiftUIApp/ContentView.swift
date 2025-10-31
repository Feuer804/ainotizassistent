import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Hintergrund mit Gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.pink.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Hauptinhalt mit TabView
                TabView(selection: $selectedTab) {
                    NotizView()
                        .tabItem {
                            Image(systemName: "note.text")
                            Text("Notizen")
                        }
                        .tag(0)
                    
                    SummaryView()
                        .tabItem {
                            Image(systemName: "doc.text")
                            Text("Zusammenfassung")
                        }
                        .tag(1)
                    
                    TodoView()
                        .tabItem {
                            Image(systemName: "checklist")
                            Text("To-Do")
                        }
                        .tag(2)
                    
                    MeetingView()
                        .tabItem {
                            Image(systemName: "person.3")
                            Text("Meeting")
                        }
                        .tag(3)
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text("Einstellungen")
                        }
                        .tag(4)
                }
                .tint(.white)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Glassmorphism Tab Bar
                VStack(spacing: 0) {
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    HStack {
                        TabBarButton(
                            icon: "note.text",
                            title: "Notizen",
                            isSelected: selectedTab == 0
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 0
                            }
                        }
                        
                        TabBarButton(
                            icon: "doc.text",
                            title: "Summary",
                            isSelected: selectedTab == 1
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 1
                            }
                        }
                        
                        TabBarButton(
                            icon: "checklist",
                            title: "To-Do",
                            isSelected: selectedTab == 2
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 2
                            }
                        }
                        
                        TabBarButton(
                            icon: "person.3",
                            title: "Meeting",
                            isSelected: selectedTab == 3
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 3
                            }
                        }
                        
                        TabBarButton(
                            icon: "gearshape",
                            title: "Einstellungen",
                            isSelected: selectedTab == 4
                        ) {
                            withAnimation(.spring()) {
                                selectedTab = 4
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

// Tab Bar Button Komponente mit Glassmorphism
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.2))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .white.opacity(0.1), radius: 10, x: 0, y: 2)
                : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}