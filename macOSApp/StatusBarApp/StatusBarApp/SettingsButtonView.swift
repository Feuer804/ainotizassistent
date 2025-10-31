//
//  SettingsButtonView.swift
//  StatusBarApp
//
//  Glassmorphism Settings Button für Quick Access
//

import SwiftUI

struct SettingsButtonView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon mit Glassmorphism Effect
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered || isPressed ? 0.3 : 0.2),
                                    Color.white.opacity(isHovered || isPressed ? 0.1 : 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                }
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered || isPressed ? 0.4 : 0.2),
                                    Color.white.opacity(isHovered || isPressed ? 0.1 : 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered || isPressed ? 0.15 : 0.08),
                                Color.black.opacity(isHovered || isPressed ? 0.05 : 0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered || isPressed ? 0.3 : 0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(isHovered || isPressed ? 0.15 : 0.08),
                radius: isHovered || isPressed ? 8 : 4,
                x: 0,
                y: isHovered || isPressed ? 4 : 2
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Preview

struct SettingsButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    SettingsButtonView(
                        icon: "brain.head.profile",
                        title: "KI-Provider",
                        subtitle: "OpenAI, Local",
                        action: { print("KI Settings") }
                    )
                    
                    SettingsButtonView(
                        icon: "internaldrive",
                        title: "Storage",
                        subtitle: "iCloud, Local",
                        action: { print("Storage Settings") }
                    )
                }
                
                HStack {
                    SettingsButtonView(
                        icon: "doc.richtext",
                        title: "Auto-Save",
                        subtitle: "Aktiv",
                        action: { print("Auto Save Settings") }
                    )
                    
                    SettingsButtonView(
                        icon: "keyboard",
                        title: "Shortcuts",
                        subtitle: "⌘⇧N",
                        action: { print("Shortcuts Settings") }
                    )
                }
            }
            .padding()
        }
    }
}