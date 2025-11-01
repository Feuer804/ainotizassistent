//
//  RichTextConverter.swift
//  Markdown zu Apple Notes Format Konverter
//

import Foundation

@available(iOS 15.0, macOS 12.0, *)
class RichTextConverter {
    
    // MARK: - Hauptkonvertierung
    
    func markdownToAppleNotesFormat(_ markdown: String) -> String {
        
        var content = markdown
        
        // Verschiedene Markdown-Elemente konvertieren
        content = convertHeaders(content)
        content = convertBoldText(content)
        content = convertItalicText(content)
        content = convertStrikethrough(content)
        content = convertInlineCode(content)
        content = convertCodeBlocks(content)
        content = convertLists(content)
        content = convertLinks(content)
        content = convertImages(content)
        content = convertTables(content)
        content = convertBlockquotes(content)
        
        // Finale Bereinigung
        content = cleanUpFormatting(content)
        
        return content
    }
    
    func appleNotesFormatToMarkdown(_ appleNotes: String) -> String {
        
        var content = appleNotes
        
        // Apple Notes Format zu Markdown konvertieren
        content = convertAppleNotesHeaders(content)
        content = convertAppleNotesFormatting(content)
        content = convertAppleNotesLists(content)
        content = convertAppleNotesLinks(content)
        content = convertAppleNotesImages(content)
        
        return content
    }
    
    // MARK: - Header Konvertierung
    
    private func convertHeaders(_ content: String) -> String {
        
        var result = content
        var lines = result.components(separatedBy: .newlines)
        
        for i in 0..<lines.count {
            let line = lines[i]
            
            // # Header1, ## Header2, etc.
            if line.hasPrefix("#") {
                let headerLevel = line.prefix(while: { $0 == "#" }).count
                let text = String(line.dropFirst(headerLevel)).trimmingCharacters(in: .whitespaces)
                
                if headerLevel <= 3 { // Notes unterstützt nur begrenzte Header-Level
                    lines[i] = text
                    if i > 0 && lines[i-1] != "" {
                        lines.insert("", at: i)
                    }
                }
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func convertAppleNotesHeaders(_ content: String) -> String {
        
        var lines = content.components(separatedBy: .newlines)
        var result = ""
        
        for i in 0..<lines.count {
            let line = lines[i]
            
            if i == 0 && line != "" {
                // Erste Zeile wird zum Haupt-Header
                result += "# \(line)\n\n"
            } else if line != "" && i > 0 {
                result += "\(line)\n"
            } else {
                result += "\n"
            }
        }
        
        return result
    }
    
    // MARK: - Text Formatierung
    
    private func convertBoldText(_ content: String) -> String {
        
        var result = content
        
        // **Bold** oder __Bold__
        result = result.replacingOccurrences(
            of: "\\*\\*(.*?)\\*\\*",
            with: " Bold: $1 ", // Apple Notes Style
            options: .regularExpression
        )
        
        result = result.replacingOccurrences(
            of: "__([^_]+)__",
            with: " Bold: $1 ",
            options: .regularExpression
        )
        
        return result
    }
    
    private func convertItalicText(_ content: String) -> String {
        
        var result = content
        
        // *Italic* oder _Italic_
        result = result.replacingOccurrences(
            of: "\\*([^*]+)\\*",
            with: " Italic: $1 ",
            options: .regularExpression
        )
        
        result = result.replacingOccurrences(
            of: "_(.+?)_",
            with: " Italic: $1 ",
            options: .regularExpression
        )
        
        return result
    }
    
    private func convertStrikethrough(_ content: String) -> String {
        
        var result = content
        
        // ~~Strikethrough~~
        result = result.replacingOccurrences(
            of: "~~(.*?)~~",
            with: " Strikethrough: $1 ",
            options: .regularExpression
        )
        
        return result
    }
    
    private func convertInlineCode(_ content: String) -> String {
        
        var result = content
        
        // `code`
        result = result.replacingOccurrences(
            of: "`([^`]+)`",
            with: " Code: $1 ",
            options: .regularExpression
        )
        
        return result
    }
    
    private func convertAppleNotesFormatting(_ content: String) -> String {
        
        var result = content
        
        // Bold: Text zu **Text**
        result = result.replacingOccurrences(
            of: "Bold: (.*?)(?= \\w+:|$)",
            with: "**$1**",
            options: .regularExpression
        )
        
        // Italic: Text zu *Text*
        result = result.replacingOccurrences(
            of: "Italic: (.*?)(?= \\w+:|$)",
            with: "*$1*",
            options: .regularExpression
        )
        
        // Code: Text zu `Text`
        result = result.replacingOccurrences(
            of: "Code: (.*?)(?= \\w+:|$)",
            with: "`$1`",
            options: .regularExpression
        )
        
        return result
    }
    
    // MARK: - Code Blocks
    
    private func convertCodeBlocks(_ content: String) -> String {
        
        var result = content
        
        // ```code```
        if let regex = try? NSRegularExpression(pattern: "```(.*?)```", options: .dotMatchesLineSeparators) {
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            
            var offset = 0
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: content) {
                    let codeContent = String(content[range])
                    let replacement = " Code Block: \(codeContent) Code End "
                    let nsRange = NSRange(location: match.range.location + offset, length: match.range.length)
                    result.replaceSubrange(Range(nsRange, in: result)!, with: replacement)
                    offset += replacement.count - match.range.length
                }
            }
        }
        
        return result
    }
    
    // MARK: - Listen
    
    private func convertLists(_ content: String) -> String {
        
        var result = content
        var lines = result.components(separatedBy: .newlines)
        
        for i in 0..<lines.count {
            var line = lines[i]
            
            // Ungeordnete Listen: - oder *
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                line = "• " + String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                lines[i] = line
            }
            // Nummerierte Listen: 1. 2. etc.
            else if let regex = try? NSRegularExpression(pattern: "^(\\d+)\\. (.*)"),
                    let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
                    let range = Range(match.range(at: 2), in: line) {
                let text = String(line[range])
                lines[i] = "\(text)" // Einfacher Text ohne Nummer für Notes
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func convertAppleNotesLists(_ content: String) -> String {
        
        var result = content
        var lines = result.components(separatedBy: .newlines)
        
        for i in 0..<lines.count {
            var line = lines[i]
            
            // • zu -
            if line.hasPrefix("• ") {
                line = "- " + String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                lines[i] = line
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Links und Bilder
    
    private func convertLinks(_ content: String) -> String {
        
        var result = content
        
        // [Link Text](URL)
        if let regex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") {
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            
            var offset = 0
            for match in matches.reversed() {
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                
                if let textString = Range(textRange, in: content),
                   let urlString = Range(urlRange, in: content) {
                    let text = String(content[textString])
                    let url = String(content[urlString])
                    let replacement = " Link: \(text) (\(url)) Link End "
                    let nsRange = NSRange(location: match.range.location + offset, length: match.range.length)
                    result.replaceSubrange(Range(nsRange, in: result)!, with: replacement)
                    offset += replacement.count - match.range.length
                }
            }
        }
        
        return result
    }
    
    private func convertAppleNotesLinks(_ content: String) -> String {
        
        var result = content
        
        // Link: Text (URL) zu [Text](URL)
        if let regex = try? NSRegularExpression(pattern: "Link: ([^(]+) \\(([^)]+)\\) Link End") {
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            
            var offset = 0
            for match in matches.reversed() {
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                
                if let textString = Range(textRange, in: content),
                   let urlString = Range(urlRange, in: content) {
                    let text = String(content[textString]).trimmingCharacters(in: .whitespaces)
                    let url = String(content[urlString])
                    let replacement = "[\(text)](\(url))"
                    let nsRange = NSRange(location: match.range.location + offset, length: match.range.length)
                    result.replaceSubrange(Range(nsRange, in: result)!, with: replacement)
                    offset += replacement.count - match.range.length
                }
            }
        }
        
        return result
    }
    
    private func convertImages(_ content: String) -> String {
        
        var result = content
        
        // ![Alt Text](Image URL)
        if let regex = try? NSRegularExpression(pattern: "!\\[([^\\]]*?)\\]\\(([^)]+)\\)") {
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            
            var offset = 0
            for match in matches.reversed() {
                let altRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                
                if let altString = Range(altRange, in: content),
                   let urlString = Range(urlRange, in: content) {
                    let altText = String(content[altString])
                    let imageUrl = String(content[urlString])
                    let replacement = " Image: \(altText) from \(imageUrl) Image End "
                    let nsRange = NSRange(location: match.range.location + offset, length: match.range.length)
                    result.replaceSubrange(Range(nsRange, in: result)!, with: replacement)
                    offset += replacement.count - match.range.length
                }
            }
        }
        
        return result
    }
    
    private func convertAppleNotesImages(_ content: String) -> String {
        
        var result = content
        
        // Image: Alt from URL zu ![Alt](URL)
        if let regex = try? NSRegularExpression(pattern: "Image: ([^f]+) from ([^i]+) Image End") {
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            
            var offset = 0
            for match in matches.reversed() {
                let altRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                
                if let altString = Range(altRange, in: content),
                   let urlString = Range(urlRange, in: content) {
                    let altText = String(content[altString]).trimmingCharacters(in: .whitespaces)
                    let imageUrl = String(content[urlString]).trimmingCharacters(in: .whitespaces)
                    let replacement = "![\(altText)](\(imageUrl))"
                    let nsRange = NSRange(location: match.range.location + offset, length: match.range.length)
                    result.replaceSubrange(Range(nsRange, in: result)!, with: replacement)
                    offset += replacement.count - match.range.length
                }
            }
        }
        
        return result
    }
    
    // MARK: - Tabellen
    
    private func convertTables(_ content: String) -> String {
        
        var result = content
        var lines = result.components(separatedBy: .newlines)
        var inTable = false
        var tableLines: [String] = []
        
        for i in 0..<lines.count {
            let line = lines[i]
            
            // Erkenne Tabellen-Separatoren
            if line.contains("|") && line.contains("---") {
                if !inTable {
                    inTable = true
                    tableLines = []
                }
                tableLines.append(line)
            } else if inTable {
                if line.contains("|") {
                    tableLines.append(line)
                } else {
                    // Tabellen Ende
                    let tableContent = formatTableForNotes(tableLines)
                    lines[i - tableLines.count - 1] = tableContent
                    
                    // Entferne Tabellen-Zeilen
                    lines.removeSubrange((i - tableLines.count)...(i - 1))
                    inTable = false
                    tableLines = []
                }
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func formatTableForNotes(_ tableLines: [String]) -> String {
        
        guard tableLines.count >= 3 else { return tableLines.joined(separator: "\n") }
        
        // Entferne Header und Separator Zeilen für einfache Darstellung
        let headerLine = tableLines[0]
        let dataLines = Array(tableLines.dropFirst(2))
        
        var formattedContent = "Tabelle:\n"
        
        // Parse Header
        let headers = headerLine.components(separatedBy: "|").dropFirst().dropLast().map { $0.trimmingCharacters(in: .whitespaces) }
        formattedContent += "Spalten: \(headers.joined(separator: ", "))\n\n"
        
        // Parse Daten
        for dataLine in dataLines {
            let cells = dataLine.components(separatedBy: "|").dropFirst().dropLast()
            for (index, cell) in cells.enumerated() {
                if index < headers.count {
                    formattedContent += "\(headers[index]): \(cell.trimmingCharacters(in: .whitespaces))\n"
                }
            }
            formattedContent += "\n"
        }
        
        return formattedContent
    }
    
    // MARK: - Blockquotes
    
    private func convertBlockquotes(_ content: String) -> String {
        
        var result = content
        var lines = result.components(separatedBy: .newlines)
        
        for i in 0..<lines.count {
            var line = lines[i]
            
            if line.hasPrefix(">") {
                let quoteText = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                line = "Zitat: \(quoteText)"
                lines[i] = line
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Cleanup
    
    private func cleanUpFormatting(_ content: String) -> String {
        
        var result = content
        
        // Entferne übermäßige Leerzeilen
        result = result.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )
        
        // Entferne führende/trailing Leerzeichen
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return result
    }
    
    // MARK: - Format Detection
    
    func detectTextFormat(_ text: String) -> TextFormat {
        
        if text.contains("```") || text.contains("`") {
            return .markdown
        }
        
        if text.contains("Bold:") || text.contains("Italic:") {
            return .appleNotes
        }
        
        // Heuristik für Standard-Text
        if text.contains("#") || text.contains("*") {
            return .markdown
        }
        
        return .plain
    }
    
    func convertBetweenFormats(_ text: String, from: TextFormat, to: TextFormat) -> String {
        
        switch (from, to) {
        case (.markdown, .appleNotes):
            return markdownToAppleNotesFormat(text)
        case (.appleNotes, .markdown):
            return appleNotesFormatToMarkdown(text)
        case (.plain, .appleNotes), (.plain, .markdown):
            return text // Plain Text bleibt unverändert
        default:
            return text // Identische Formate oder ungeannte Konvertierungen
        }
    }
}

// MARK: - Enums

enum TextFormat {
    case markdown
    case appleNotes
    case plain
}