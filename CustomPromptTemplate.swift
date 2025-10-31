//
//  CustomPromptTemplate.swift
//  Intelligente Notizen App
//

import Foundation

// MARK: - Custom Prompt Template Protocol
protocol CustomPromptTemplateManaging: AnyObject {
    func createTemplate(from template: CustomPromptTemplate) async throws -> String
    func validateTemplate(_ template: CustomPromptTemplate) async -> TemplateValidation
    func getAvailableTemplates() async -> [CustomPromptTemplate]
    func saveTemplate(_ template: CustomPromptTemplate) async throws
    func deleteTemplate(id: String) async throws
    func duplicateTemplate(id: String) async throws -> CustomPromptTemplate
    func exportTemplate(id: String) async -> Data?
    func importTemplate(from data: Data) async throws -> CustomPromptTemplate
}

// MARK: - Custom Prompt Template
struct CustomPromptTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: TemplateCategory
    let basePrompt: String
    var parameters: [String: String] // Parameter name -> description
    let contentTypes: [ContentType]
    let languages: [PromptLanguage]
    let createdAt: Date
    var lastModified: Date
    let tags: [String]
    let isPublic: Bool
    let author: String
    let version: String
    var usageCount: Int = 0
    var rating: Double = 0.0
    
    enum TemplateCategory: String, CaseIterable, Codable {
        case business = "Business"
        case technical = "Technisch"
        case creative = "Kreativ"
        case academic = "Akademisch"
        case general = "Allgemein"
        case custom = "Benutzerdefiniert"
        
        var displayName: String {
            return rawValue
        }
        
        var icon: String {
            switch self {
            case .business: return "💼"
            case .technical: return "⚙️"
            case .creative: return "🎨"
            case .academic: return "📚"
            case .general: return "📝"
            case .custom: return "🔧"
            }
        }
    }
}

// MARK: - Template Validation
struct TemplateValidation {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]
    let suggestions: [TemplateSuggestion]
    
    static var valid: TemplateValidation {
        return TemplateValidation(isValid: true, errors: [], warnings: [], suggestions: [])
    }
}

struct ValidationError: Identifiable {
    let id = UUID()
    let field: String
    let message: String
    let severity: ErrorSeverity
    
    enum ErrorSeverity {
        case critical, error, warning
    }
}

struct ValidationWarning: Identifiable {
    let id = UUID()
    let field: String
    let message: String
    let suggestion: String?
}

struct TemplateSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let message: String
    let action: String
    
    enum SuggestionType {
        case optimization, bestPractice, enhancement
    }
}

// MARK: - Template Builder
final class CustomPromptTemplateBuilder {
    
    func createTemplate(
        name: String,
        description: String,
        category: CustomPromptTemplate.TemplateCategory,
        basePrompt: String,
        parameters: [String: String] = [:],
        contentTypes: [ContentType] = [.article],
        languages: [PromptLanguage] = [.german, .english],
        tags: [String] = [],
        isPublic: Bool = false
    ) -> CustomPromptTemplate {
        
        return CustomPromptTemplate(
            id: UUID().uuidString,
            name: name,
            description: description,
            category: category,
            basePrompt: basePrompt,
            parameters: parameters,
            contentTypes: contentTypes,
            languages: languages,
            createdAt: Date(),
            lastModified: Date(),
            tags: tags,
            isPublic: isPublic,
            author: "User", // Would be current user in real app
            version: "1.0"
        )
    }
    
    func addParameter(to template: CustomPromptTemplate, name: String, description: String) -> CustomPromptTemplate {
        var updatedTemplate = template
        updatedTemplate.parameters[name] = description
        updatedTemplate.lastModified = Date()
        return updatedTemplate
    }
    
    func removeParameter(from template: CustomPromptTemplate, parameterName: String) -> CustomPromptTemplate {
        var updatedTemplate = template
        updatedTemplate.parameters.removeValue(forKey: parameterName)
        updatedTemplate.lastModified = Date()
        return updatedTemplate
    }
    
    func updateBasePrompt(_ template: CustomPromptTemplate, newPrompt: String) -> CustomPromptTemplate {
        var updatedTemplate = template
        updatedTemplate.basePrompt = newPrompt
        updatedTemplate.lastModified = Date()
        return updatedTemplate
    }
}

// MARK: - Template Manager Implementation
final class CustomPromptTemplateManager: CustomPromptTemplateManaging {
    
    private let storage = TemplateStorage()
    private let validator = TemplateValidator()
    private var templates: [CustomPromptTemplate] = []
    
    init() {
        loadTemplates()
    }
    
    func createTemplate(from template: CustomPromptTemplate) async throws -> String {
        // Validate template
        let validation = await validator.validate(template)
        guard validation.isValid else {
            throw TemplateError.invalidTemplate(validation.errors)
        }
        
        // Save template
        try await saveTemplate(template)
        
        // Generate executable prompt by substituting parameters
        return await generateExecutablePrompt(template, parameters: template.parameters)
    }
    
    func validateTemplate(_ template: CustomPromptTemplate) async -> TemplateValidation {
        return await validator.validate(template)
    }
    
    func getAvailableTemplates() async -> [CustomPromptTemplate] {
        return templates.filter { $0.isPublic || $0.author == "User" } // Filter by user permissions
    }
    
    func saveTemplate(_ template: CustomPromptTemplate) async throws {
        // Validate before saving
        let validation = await validator.validate(template)
        guard validation.isValid else {
            throw TemplateError.invalidTemplate(validation.errors)
        }
        
        // Update timestamp
        var updatedTemplate = template
        updatedTemplate.lastModified = Date()
        
        // Save to storage
        try await storage.saveTemplate(updatedTemplate)
        
        // Update in-memory cache
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = updatedTemplate
        } else {
            templates.append(updatedTemplate)
        }
    }
    
    func deleteTemplate(id: String) async throws {
        guard let index = templates.firstIndex(where: { $0.id == id }) else {
            throw TemplateError.templateNotFound
        }
        
        try await storage.deleteTemplate(id: id)
        templates.remove(at: index)
    }
    
    func duplicateTemplate(id: String) async throws -> CustomPromptTemplate {
        guard let originalTemplate = templates.first(where: { $0.id == id }) else {
            throw TemplateError.templateNotFound
        }
        
        var duplicatedTemplate = originalTemplate
        duplicatedTemplate.id = UUID().uuidString
        duplicatedTemplate.name = "\(originalTemplate.name) (Kopie)"
        duplicatedTemplate.createdAt = Date()
        duplicatedTemplate.lastModified = Date()
        duplicatedTemplate.usageCount = 0
        
        try await saveTemplate(duplicatedTemplate)
        return duplicatedTemplate
    }
    
    func exportTemplate(id: String) async -> Data? {
        guard let template = templates.first(where: { $0.id == id }) else {
            return nil
        }
        
        return try? JSONEncoder().encode(template)
    }
    
    func importTemplate(from data: Data) async throws -> CustomPromptTemplate {
        let template = try JSONDecoder().decode(CustomPromptTemplate.self, from: data)
        
        // Validate imported template
        let validation = await validator.validate(template)
        guard validation.isValid else {
            throw TemplateError.invalidTemplate(validation.errors)
        }
        
        // Assign new ID to avoid conflicts
        var importedTemplate = template
        importedTemplate.id = UUID().uuidString
        importedTemplate.createdAt = Date()
        importedTemplate.lastModified = Date()
        
        try await saveTemplate(importedTemplate)
        return importedTemplate
    }
    
    // MARK: - Private Methods
    private func loadTemplates() {
        Task {
            templates = await storage.loadAllTemplates()
        }
    }
    
    private func generateExecutablePrompt(_ template: CustomPromptTemplate, parameters: [String: String]) async -> String {
        var prompt = template.basePrompt
        
        // Substitute parameters
        for (key, value) in parameters {
            prompt = prompt.replacingOccurrences(of: "{\(key)}", with: value)
        }
        
        // Add metadata if needed
        if prompt.contains("{template_info}") {
            let info = """
            Template: \(template.name)
            Kategorie: \(template.category.displayName)
            Version: \(template.version)
            """
            prompt = prompt.replacingOccurrences(of: "{template_info}", with: info)
        }
        
        return prompt
    }
}

// MARK: - Template Validator
final class TemplateValidator {
    
    func validate(_ template: CustomPromptTemplate) async -> TemplateValidation {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        var suggestions: [TemplateSuggestion] = []
        
        // Validate name
        if template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "name",
                message: "Template-Name ist erforderlich",
                severity: .critical
            ))
        }
        
        if template.name.count > 100 {
            errors.append(ValidationError(
                field: "name",
                message: "Template-Name ist zu lang (max. 100 Zeichen)",
                severity: .error
            ))
        }
        
        // Validate base prompt
        if template.basePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "basePrompt",
                message: "Base-Prompt ist erforderlich",
                severity: .critical
            ))
        }
        
        if template.basePrompt.count > 10000 {
            warnings.append(ValidationWarning(
                field: "basePrompt",
                message: "Base-Prompt ist sehr lang",
                suggestion: "Erwägen Sie die Aufteilung in kleinere Templates"
            ))
        }
        
        // Validate parameters
        for (paramName, paramDesc) in template.parameters {
            if paramName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(ValidationError(
                    field: "parameters",
                    message: "Parameter-Name darf nicht leer sein",
                    severity: .error
                ))
            }
            
            if paramDesc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                warnings.append(ValidationWarning(
                    field: "parameters",
                    message: "Parameter '\(paramName)' hat keine Beschreibung",
                    suggestion: "Fügen Sie eine Beschreibung hinzu"
                ))
            }
        }
        
        // Check parameter usage in base prompt
        let usedParameters = extractUsedParameters(from: template.basePrompt)
        let declaredParameters = Set(template.parameters.keys)
        
        for param in usedParameters {
            if !declaredParameters.contains(param) {
                warnings.append(ValidationWarning(
                    field: "basePrompt",
                    message: "Parameter '\(param)' wird im Prompt verwendet, aber nicht deklariert",
                    suggestion: "Fügen Sie '\(param)' zu den Parametern hinzu"
                ))
            }
        }
        
        for param in declaredParameters {
            if !usedParameters.contains(param) {
                suggestions.append(TemplateSuggestion(
                    type: .optimization,
                    message: "Parameter '\(param)' wird nicht im Prompt verwendet",
                    action: "Entfernen Sie nicht verwendete Parameter oder verwenden Sie sie im Prompt"
                ))
            }
        }
        
        // Check for common issues
        if template.basePrompt.lowercased().contains("{{") || template.basePrompt.lowercased().contains("}}") {
            errors.append(ValidationError(
                field: "basePrompt",
                message: "Fehlerhafte Parameter-Syntax gefunden",
                severity: .error
            ))
        }
        
        // Generate optimization suggestions
        if template.basePrompt.count < 100 {
            suggestions.append(TemplateSuggestion(
                type: .enhancement,
                message: "Template könnte detaillierter sein",
                action: "Fügen Sie mehr Struktur und Beispiele hinzu"
            ))
        }
        
        let isValid = errors.filter { $0.severity == .critical }.isEmpty
        
        return TemplateValidation(
            isValid: isValid,
            errors: errors,
            warnings: warnings,
            suggestions: suggestions
        )
    }
    
    private func extractUsedParameters(from prompt: String) -> Set<String> {
        let pattern = #"\{(\w+)\}"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: prompt, range: NSRange(prompt.startIndex..., in: prompt)) ?? []
        
        var parameters: Set<String> = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: prompt) {
                parameters.insert(String(prompt[range]))
            }
        }
        
        return parameters
    }
}

// MARK: - Template Storage
final class TemplateStorage {
    private let userDefaults = UserDefaults.standard
    private let templatesKey = "CustomPromptTemplates"
    
    func saveTemplate(_ template: CustomPromptTemplate) async throws {
        var templates = loadAllTemplates()
        
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
        
        let data = try JSONEncoder().encode(templates)
        userDefaults.set(data, forKey: templatesKey)
    }
    
    func loadAllTemplates() -> [CustomPromptTemplate] {
        guard let data = userDefaults.data(forKey: templatesKey),
              let templates = try? JSONDecoder().decode([CustomPromptTemplate].self, from: data) else {
            return getDefaultTemplates()
        }
        return templates
    }
    
    func deleteTemplate(id: String) async throws {
        var templates = loadAllTemplates()
        templates.removeAll { $0.id == id }
        
        let data = try JSONEncoder().encode(templates)
        userDefaults.set(data, forKey: templatesKey)
    }
    
    private func getDefaultTemplates() -> [CustomPromptTemplate] {
        // Return some default templates
        return [
            CustomPromptTemplate(
                id: "default_summary",
                name: "Artikel Zusammenfassung",
                description: "Template für Artikel-Zusammenfassungen",
                category: .general,
                basePrompt: """
                Bitte erstelle eine Zusammenfassung des folgenden Artikels:
                
                {content}
                
                Strukturiere die Antwort so:
                ## Zusammenfassung
                [Kurze Zusammenfassung]
                
                ## Hauptpunkte
                - [Punkt 1]
                - [Punkt 2]
                - [Punkt 3]
                
                ## Fazit
                [Abschließende Bewertung]
                """,
                parameters: ["content": "Der zu zusammenfassende Artikel-Inhalt"],
                contentTypes: [.article],
                languages: [.german],
                createdAt: Date(),
                lastModified: Date(),
                tags: ["zusammenfassung", "artikel"],
                isPublic: true,
                author: "System",
                version: "1.0"
            )
        ]
    }
}

// MARK: - Template Error
enum TemplateError: Error {
    case invalidTemplate([ValidationError])
    case templateNotFound
    case saveFailed(underlying: Error)
    case loadFailed(underlying: Error)
}