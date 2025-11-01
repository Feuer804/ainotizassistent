import SwiftUI

@main
struct TextInputDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Haupt-Text-Input
            SmartTextInputView()
                .background(LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("🖋️ Smart Text Input System")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("v1.0")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}