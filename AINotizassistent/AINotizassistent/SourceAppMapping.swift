//
//  SourceAppMapping.swift
//  AINotizassistent
//
//  App-Type Definitions für Quell-App-Erkennung
//

import Foundation
import AppKit

// MARK: - App Category Types
enum AppCategory: String, CaseIterable {
    case email = "email"
    case browser = "browser"
    case editor = "editor"
    case ide = "ide"
    case office = "office"
    case design = "design"
    case communication = "communication"
    case productivity = "productivity"
    case development = "development"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .email: return "E-Mail"
        case .browser: return "Browser"
        case .editor: return "Editor"
        case .ide: return "IDE"
        case .office: return "Office"
        case .design: return "Design"
        case .communication: return "Kommunikation"
        case .productivity: return "Produktivität"
        case .development: return "Entwicklung"
        case .other: return "Andere"
        }
    }
}

// MARK: - App Type Definition
struct AppTypeDefinition {
    let bundleIdentifier: String
    let displayName: String
    let category: AppCategory
    let version: String
    let isSystemApp: Bool
    let accessibilityEnabled: Bool
    
    init(bundleIdentifier: String, displayName: String, category: AppCategory, version: String = "1.0", isSystemApp: Bool = false, accessibilityEnabled: Bool = true) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.category = category
        self.version = version
        self.isSystemApp = isSystemApp
        self.accessibilityEnabled = accessibilityEnabled
    }
}

// MARK: - Known App Mappings
class SourceAppMapping {
    
    // Bekannte macOS Apps mit Bundle IDs
    static let knownApps: [String: AppTypeDefinition] = [
        // E-Mail Apps
        "com.apple.Mail": AppTypeDefinition(
            bundleIdentifier: "com.apple.Mail",
            displayName: "Mail",
            category: .email,
            isSystemApp: true,
            accessibilityEnabled: true
        ),
        "com.microsoft.Outlook": AppTypeDefinition(
            bundleIdentifier: "com.microsoft.Outlook",
            displayName: "Microsoft Outlook",
            category: .email,
            accessibilityEnabled: true
        ),
        "com.google.Gmail": AppTypeDefinition(
            bundleIdentifier: "com.google.Gmail",
            displayName: "Gmail",
            category: .email,
            accessibilityEnabled: true
        ),
        "com.sparkmailapp.Spark": AppTypeDefinition(
            bundleIdentifier: "com.sparkmailapp.Spark",
            displayName: "Spark",
            category: .email,
            accessibilityEnabled: true
        ),
        
        // Browser
        "com.apple.Safari": AppTypeDefinition(
            bundleIdentifier: "com.apple.Safari",
            displayName: "Safari",
            category: .browser,
            isSystemApp: true,
            accessibilityEnabled: true
        ),
        "com.google.Chrome": AppTypeDefinition(
            bundleIdentifier: "com.google.Chrome",
            displayName: "Google Chrome",
            category: .browser,
            accessibilityEnabled: true
        ),
        "org.mozilla.firefox": AppTypeDefinition(
            bundleIdentifier: "org.mozilla.firefox",
            displayName: "Mozilla Firefox",
            category: .browser,
            accessibilityEnabled: true
        ),
        "com.microsoft.Edge": AppTypeDefinition(
            bundleIdentifier: "com.microsoft.Edge",
            displayName: "Microsoft Edge",
            category: .browser,
            accessibilityEnabled: true
        ),
        "com.brave.Browser": AppTypeDefinition(
            bundleIdentifier: "com.brave.Browser",
            displayName: "Brave Browser",
            category: .browser,
            accessibilityEnabled: true
        ),
        
        // Editoren
        "com.apple.TextEdit": AppTypeDefinition(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            category: .editor,
            isSystemApp: true,
            accessibilityEnabled: true
        ),
        "com.sublimetext.3": AppTypeDefinition(
            bundleIdentifier: "com.sublimetext.3",
            displayName: "Sublime Text",
            category: .editor,
            accessibilityEnabled: true
        ),
        "com.microsoft.VSCode": AppTypeDefinition(
            bundleIdentifier: "com.microsoft.VSCode",
            displayName: "Visual Studio Code",
            category: .editor,
            accessibilityEnabled: true
        ),
        "com.apple.dt.Xcode": AppTypeDefinition(
            bundleIdentifier: "com.apple.dt.Xcode",
            displayName: "Xcode",
            category: .ide,
            isSystemApp: true,
            accessibilityEnabled: true
        ),
        
        // Office Apps
        "com.microsoft.Word": AppTypeDefinition(
            bundleIdentifier: "com.microsoft.Word",
            displayName: "Microsoft Word",
            category: .office,
            accessibilityEnabled: true
        ),
        "com.microsoft.Excel": AppTypeDefinition(
            bundleIdentifier: "com.microsoft.Excel",
            displayName: "Microsoft Excel",
            category: .office,
            accessibilityEnabled: true
        ),
        "com.microsoft.Powerpoint": AppTypeDefinition(
            bundleIdentifier: "com.microsoft.Powerpoint",
            displayName: "Microsoft PowerPoint",
            category: .office,
            accessibilityEnabled: true
        ),
        "com.apple.Pages": AppTypeDefinition(
            bundleIdentifier: "com.apple.Pages",
            displayName: "Pages",
            category: .office,
            isSystemApp: true,
            accessibilityEnabled: true
        ),
        "com.apple.Numbers": AppTypeDefinition(
            bundleIdentifier: "com.apple.Numbers",
            displayName: "Numbers",
            category: .office,
            isSystemApp: true,
            accessibilityEnabled: true
        ),
        "com.apple.Keynote": AppTypeDefinition(
            bundleIdentifier: "com.apple.Keynote",
            displayName: "Keynote",
            category: .office,
            isSystemApp: true,
            accessibilityEnabled: true
        ),
        
        // Design Apps
        "com.adobe.Photoshop": AppTypeDefinition(
            bundleIdentifier: "com.adobe.Photoshop",
            displayName: "Adobe Photoshop",
            category: .design,
            accessibilityEnabled: true
        ),
        "com.adobe.Illustrator": AppTypeDefinition(
            bundleIdentifier: "com.adobe.Illustrator",
            displayName: "Adobe Illustrator",
            category: .design,
            accessibilityEnabled: true
        ),
        "com.sketch.Sketch": AppTypeDefinition(
            bundleIdentifier: "com.sketch.Sketch",
            displayName: "Sketch",
            category: .design,
            accessibilityEnabled: true
        ),
        "com.figma.Desktop": AppTypeDefinition(
            bundleIdentifier: "com.figma.Desktop",
            displayName: "Figma",
            category: .design,
            accessibilityEnabled: true
        ),
        
        // Kommunikation
        "com.apple.iChat": AppTypeDefinition(
            bundleIdentifier: "com.apple.iChat",
            displayName: "Messages",
            category: .communication,
            isSystemApp: true,
            accessibilityEnabled: true
        ),
        "com.tinyspeck.slackmacgap": AppTypeDefinition(
            bundleIdentifier: "com.tinyspeck.slackmacgap",
            displayName: "Slack",
            category: .communication,
            accessibilityEnabled: true
        ),
        "com.microsoft.Teams": AppTypeDefinition(
            bundleIdentifier: "com.microsoft.Teams",
            displayName: "Microsoft Teams",
            category: .communication,
            accessibilityEnabled: true
        ),
        "us.zoom.xos": AppTypeDefinition(
            bundleIdentifier: "us.zoom.xos",
            displayName: "Zoom",
            category: .communication,
            accessibilityEnabled: true
        ),
        
        // Entwicklung
        "com.jetbrains.AppCode": AppTypeDefinition(
            bundleIdentifier: "com.jetbrains.AppCode",
            displayName: "AppCode",
            category: .ide,
            accessibilityEnabled: true
        ),
        "com.jetbrains.CLion": AppTypeDefinition(
            bundleIdentifier: "com.jetbrains.CLion",
            displayName: "CLion",
            category: .ide,
            accessibilityEnabled: true
        ),
        "com.jetbrains.IntelliJ IDEA": AppTypeDefinition(
            bundleIdentifier: "com.jetbrains.IntelliJ IDEA",
            displayName: "IntelliJ IDEA",
            category: .ide,
            accessibilityEnabled: true
        ),
        "com.jetbrains.WebStorm": AppTypeDefinition(
            bundleIdentifier: "com.jetbrains.WebStorm",
            displayName: "WebStorm",
            category: .ide,
            accessibilityEnabled: true
        ),
        "com.jetbrains.PyCharm": AppTypeDefinition(
            bundleIdentifier: "com.jetbrains.PyCharm",
            displayName: "PyCharm",
            category: .ide,
            accessibilityEnabled: true
        ),
        "com.apple.dt.SoftwareUpdate": AppTypeDefinition(
            bundleIdentifier: "com.apple.dt.SoftwareUpdate",
            displayName: "Software Update",
            category: .productivity,
            isSystemApp: true,
            accessibilityEnabled: false
        )
    ]
    
    // MARK: - App Resolution
    
    /// Findet App-Definition anhand von Bundle ID
    static func findApp(by bundleIdentifier: String) -> AppTypeDefinition? {
        return knownApps[bundleIdentifier]
    }
    
    /// Findet App-Definitionen anhand von App-Name
    static func findApps(by displayName: String) -> [AppTypeDefinition] {
        return knownApps.values.filter { $0.displayName.lowercased().contains(displayName.lowercased()) }
    }
    
    /// Findet App-Definitionen nach Kategorie
    static func findApps(by category: AppCategory) -> [AppTypeDefinition] {
        return knownApps.values.filter { $0.category == category }
    }
    
    /// Erstellt dynamische App-Definition für unbekannte Apps
    static func createDynamicDefinition(for bundleIdentifier: String, displayName: String) -> AppTypeDefinition {
        // App-Typ basierend auf Bundle ID oder Namen erraten
        let category = guessAppCategory(for: bundleIdentifier, displayName: displayName)
        
        return AppTypeDefinition(
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            category: category,
            version: "1.0",
            isSystemApp: bundleIdentifier.hasPrefix("com.apple."),
            accessibilityEnabled: true
        )
    }
    
    // MARK: - Category Guessing
    
    private static func guessAppCategory(for bundleIdentifier: String, displayName: String) -> AppCategory {
        let name = displayName.lowercased()
        let bundleId = bundleIdentifier.lowercased()
        
        // E-Mail Indikatoren
        if name.contains("mail") || name.contains("email") || name.contains("outlook") || bundleId.contains("mail") || bundleId.contains("email") {
            return .email
        }
        
        // Browser Indikatoren
        if name.contains("browser") || name.contains("chrome") || name.contains("safari") || name.contains("firefox") || name.contains("edge") {
            return .browser
        }
        
        // IDE/Editor Indikatoren
        if name.contains("xcode") || name.contains("intellij") || name.contains("pycharm") || name.contains("vscode") || name.contains("sublime") {
            return .ide
        }
        
        // Office Indikatoren
        if name.contains("word") || name.contains("excel") || name.contains("powerpoint") || name.contains("pages") || name.contains("numbers") {
            return .office
        }
        
        // Design Indikatoren
        if name.contains("photoshop") || name.contains("illustrator") || name.contains("sketch") || name.contains("figma") {
            return .design
        }
        
        // Kommunikation Indikatoren
        if name.contains("slack") || name.contains("teams") || name.contains("zoom") || name.contains("messages") || name.contains("discord") {
            return .communication
        }
        
        // Standard-Kategorie
        return .other
    }
    
    // MARK: - App Statistics
    
    static var totalKnownApps: Int {
        return knownApps.count
    }
    
    static var appsByCategory: [AppCategory: Int] {
        var result: [AppCategory: Int] = [:]
        for app in knownApps.values {
            result[app.category, default: 0] += 1
        }
        return result
    }
    
    static func categoryPercentage(for category: AppCategory) -> Double {
        let count = appsByCategory[category, default: 0]
        return Double(count) / Double(totalKnownApps) * 100.0
    }
}

// MARK: - Content Source Attribution
struct ContentSource {
    let appId: String
    let displayName: String
    let category: AppCategory
    let windowTitle: String?
    let processName: String
    let isActive: Bool
    let accessibilityEnabled: Bool
    let extractedMetadata: [String: String]?
    
    var isSystemApp: Bool {
        return bundleId.hasPrefix("com.apple.")
    }
    
    var bundleId: String {
        return processName.lowercased()
    }
    
    var attributionSummary: String {
        let appName = displayName
        let windowInfo = windowTitle != nil ? " - \(windowTitle!)" : ""
        return "\(appName)\(windowInfo)"
    }
}

// MARK: - App-Specific Content Parsing
protocol AppContentParser {
    func parseContent(from windowTitle: String, appType: AppTypeDefinition) -> [String: String]?
}

// Mail App Parser
struct MailContentParser: AppContentParser {
    func parseContent(from windowTitle: String, appType: AppTypeDefinition) -> [String: String]? {
        // Mail Subject extraction aus Window Title
        // Format: "Subject - Email Address (X Nachrichten) - Mail"
        let pattern = "^(.*?)\\s*-\\s*([^\\s]+)\\s*-\\s*Mail"
        let regex = try? NSRegularExpression(pattern: pattern)
        
        if let match = regex?.firstMatch(in: windowTitle, range: NSRange(location: 0, length: windowTitle.utf16.count)) {
            if let subjectRange = Range(match.range(at: 1), in: windowTitle),
               let emailRange = Range(match.range(at: 2), in: windowTitle) {
                let subject = String(windowTitle[subjectRange])
                let email = String(windowTitle[emailRange])
                
                return [
                    "contentType": "email",
                    "subject": subject,
                    "sender": email,
                    "isUnread": windowTitle.contains("(") && windowTitle.contains("Nachrichten") ? "true" : "false"
                ]
            }
        }
        
        return ["contentType": "email"]
    }
}

// Browser Parser
struct BrowserContentParser: AppContentParser {
    func parseContent(from windowTitle: String, appType: AppTypeDefinition) -> [String: String]? {
        // Website Title extraction
        // Meistens: "Page Title - Browser Name"
        let components = windowTitle.components(separatedBy: " - ")
        let pageTitle = components.dropLast().joined(separator: " - ")
        let browserName = components.last ?? appType.displayName
        
        if !pageTitle.isEmpty && pageTitle != windowTitle {
            return [
                "contentType": "webpage",
                "pageTitle": pageTitle,
                "browser": browserName,
                "fullTitle": windowTitle
            ]
        }
        
        return ["contentType": "webpage", "browser": browserName]
    }
}

// Editor Parser
struct EditorContentParser: AppContentParser {
    func parseContent(from windowTitle: String, appType: AppTypeDefinition) -> [String: String]? {
        // Document Name extraction
        // Format: "Document Name - App Name"
        let components = windowTitle.components(separatedBy: " - ")
        let documentName = components.dropLast().joined(separator: " - ")
        let editorName = components.last ?? appType.displayName
        
        if !documentName.isEmpty && documentName != windowTitle {
            return [
                "contentType": "document",
                "documentName": documentName,
                "editor": editorName,
                "fullTitle": windowTitle
            ]
        }
        
        return ["contentType": "document", "editor": editorName]
    }
}
