//
//  NoteCardView.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import SwiftUI

struct NoteCardView: View {
    let note: Note
    let onDelete: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.source)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .withHoverEffect()
                    
                    Text(note.content)
                        .font(.body)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .withHoverEffect()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(note.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .withEaseAnimation(type: .easeIn, duration: 0.3)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isPressed = false
                            }
                        }
                        
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(isHovered ? .red.opacity(0.8) : .red)
                            .font(.caption)
                            .scaleEffect(isPressed ? 0.8 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHovered = hovering
                        }
                    }
                    .withHoverEffect(scale: 1.1)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(
                    color: isHovered ? .black.opacity(0.15) : .black.opacity(0.1),
                    radius: isHovered ? 4 : 2,
                    x: 0,
                    y: isHovered ? 2 : 1
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .withSpringAnimation()
    }
}

struct NoteCardView_Previews: PreviewProvider {
    static var previews: some View {
        NoteCardView(
            note: Note(
                content: "Dies ist eine Beispiel-Notiz mit mehr Text, um die Darstellung zu testen.",
                timestamp: Date(),
                source: "Transkription"
            ),
            onDelete: {}
        )
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}