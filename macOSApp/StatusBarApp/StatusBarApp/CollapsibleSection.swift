//
//  CollapsibleSection.swift
//  StatusBarApp
//
//  Collapsible Section Component für erweiterte Einstellungen
//

import SwiftUI

struct CollapsibleSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.vertical, 4)
                    
                    content()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isExpanded ? Color.white.opacity(0.05) : Color.clear)
        )
    }
}

// MARK: - Preview

struct CollapsibleSection_Previews: PreviewProvider {
    static var previews: some View {
        CollapsibleSection(title: "Erweiterte Einstellungen") {
            VStack(alignment: .leading) {
                Text("Diese Einstellungen sind für erweiterte Benutzer gedacht.")
                    .font(.caption)
                
                Toggle("Erweiterte Option 1", isOn: .constant(true))
                Toggle("Erweiterte Option 2", isOn: .constant(false))
            }
        }
        .padding()
        .frame(width: 400)
        .background(Color.gray.opacity(0.1))
    }
}