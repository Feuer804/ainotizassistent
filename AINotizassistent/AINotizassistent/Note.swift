//
//  Note.swift
//  AINotizassistent
//
//  Created by AI Notizassistent Team on 31.10.2025.
//  Copyright © 2025 AI Notizassistent. All rights reserved.
//

import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    var content: String
    let timestamp: Date
    var source: String
    
    init(id: UUID = UUID(), content: String, timestamp: Date, source: String) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.source = source
    }
    
    // Formatted timestamp for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: timestamp)
    }
    
    // Word count
    var wordCount: Int {
        content.split { !$0.isLetter }.count
    }
}