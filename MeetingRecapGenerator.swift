import Foundation
import NaturalLanguage

// MARK: - Meeting Types
enum MeetingType: String, CaseIterable {
    case planning = "Planungsmeeting"
    case review = "Review-Meeting"
    case brainstorming = "Brainstorming"
    case statusUpdate = "Status Update"
    case decisionMaking = "Entscheidungsfindung"
    case retrospective = "Retrospektive"
    case standup = "Daily Standup"
    case oneOnOne = "1:1 Gespräch"
    case projectKickoff = "Projekt Kick-off"
    case training = "Schulung"
    case troubleshooting = "Problemlösung"
    case strategic = "Strategische Besprechung"
    
    var description: String {
        switch self {
        case .planning: return "Planung von Aktivitäten und Zielen"
        case .review: return "Überprüfung von Fortschritten und Ergebnissen"
        case .brainstorming: return "Kreative Ideenfindung und Problemlösung"
        case .statusUpdate: return "Aktueller Status und Fortschrittsbericht"
        case .decisionMaking: return "Entscheidungen treffen und vereinbaren"
        case .retrospective: return "Reflexion und Verbesserungsplanung"
        case .standup: return "Kurzer täglicher Austausch"
        case .oneOnOne: return "Persönliches Einzelgespräch"
        case .projectKickoff: return "Projektstart und初次 Ausrichtung"
        case .training: return "Wissensvermittlung und Schulung"
        case .troubleshooting: return "Probleme identifizieren und lösen"
        case .strategic: return "Strategische Ausrichtung und Vision"
        }
    }
}

// MARK: - Impact Assessment
enum ImpactLevel: String, CaseIterable {
    case low = "Niedrig"
    case medium = "Mittel"
    case high = "Hoch"
    case critical = "Kritisch"
    
    var color: String {
        switch self {
        case .low: return "grün"
        case .medium: return "gelb"
        case .high: return "orange"
        case .critical: return "rot"
        }
    }
}

// MARK: - Core Data Models
struct Participant: Identifiable, Codable {
    let id = UUID()
    var name: String
    var role: String?
    var department: String?
    var email: String?
    var phone: String?
    var participationLevel: ParticipationLevel = .normal
    var contactInfo: [String: String] = [:]
    
    enum ParticipationLevel: String, CaseIterable {
        case low = "Passiv"
        case normal = "Normal"
        case active = "Aktiv"
        case dominant = "Dominant"
        
        var color: String {
            switch self {
            case .low: return "grau"
            case .normal: return "blau"
            case .active: return "grün"
            case .dominant: return "orange"
            }
        }
    }
}

struct AgendaItem: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var duration: TimeInterval?
    var priority: Priority = .medium
    var presenter: String?
    var outcomes: [String] = []
    var isCompleted: Bool = false
    
    enum Priority: String, CaseIterable {
        case low = "Niedrig"
        case medium = "Mittel"
        case high = "Hoch"
        case urgent = "Dringend"
    }
}

struct DecisionPoint: Identifiable, Codable {
    let id = UUID()
    var description: String
    var participants: [String]
    var impact: ImpactLevel
    var rationale: String
    var consequences: String?
    var implementationPlan: String?
    var nextSteps: [String] = []
    var requiresFollowUp: Bool = false
    var followUpDate: Date?
}

struct ActionItem: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var assignedTo: String
    var priority: Priority
    var dueDate: Date?
    var status: Status = .pending
    var category: ActionCategory = .general
    var estimatedEffort: TimeInterval?
    var dependencies: [String] = []
    var progress: Double = 0.0
    
    enum Status: String, CaseIterable {
        case pending = "Ausstehend"
        case inProgress = "In Bearbeitung"
        case completed = "Abgeschlossen"
        case blocked = "Blockiert"
        case cancelled = "Storniert"
    }
    
    enum ActionCategory: String, CaseIterable {
        case development = "Entwicklung"
        case testing = "Test"
        case documentation = "Dokumentation"
        case research = "Recherche"
        case review = "Review"
        case planning = "Planung"
        case communication = "Kommunikation"
        case general = "Allgemein"
    }
    
    enum Priority: String, CaseIterable {
        case low = "Niedrig"
        case medium = "Mittel"
        case high = "Hoch"
        case urgent = "Dringend"
    }
}

struct TimelineEvent: Identifiable, Codable {
    let id = UUID()
    var timestamp: Date
    var event: String
    var participants: [String]
    var duration: TimeInterval?
    var category: TimelineCategory
    var importance: Importance
    
    enum TimelineCategory: String, CaseIterable {
        case agenda = "Agenda"
        case discussion = "Diskussion"
        case decision = "Entscheidung"
        case action = "Aktion"
        case conflict = "Konflikt"
        case agreement = "Einigung"
        case break = "Pause"
        case technical = "Technisch"
    }
    
    enum Importance: String, CaseIterable {
        case low = "Niedrig"
        case medium = "Mittel"
        case high = "Hoch"
        case critical = "Kritisch"
    }
}

struct DiscussionPoint: Identifiable, Codable {
    let id = UUID()
    var title: String
    var content: String
    var category: DiscussionCategory
    var participants: [String]
    var sentiment: Sentiment
    var keyInsights: [String] = []
    var actionItems: [String] = []
    
    enum DiscussionCategory: String, CaseIterable {
        case technical = "Technisch"
        case business = "Business"
        case process = "Prozess"
        case people = "Personal"
        case strategy = "Strategie"
        case budget = "Budget"
        case timeline = "Zeitplan"
        case quality = "Qualität"
    }
    
    enum Sentiment: String, CaseIterable {
        case positive = "Positiv"
        case neutral = "Neutral"
        case negative = "Negativ"
        case mixed = "Gemischt"
    }
}

struct Risk: Identifiable, Codable {
    let id = UUID()
    var description: String
    var category: RiskCategory
    var probability: Probability
    var impact: ImpactLevel
    var mitigationStrategies: [String]
    var owner: String?
    var status: RiskStatus = .identified
    
    enum RiskCategory: String, CaseIterable {
        case technical = "Technisch"
        case schedule = "Zeitplan"
        case budget = "Budget"
        case resources = "Ressourcen"
        case stakeholder = "Stakeholder"
        case external = "Extern"
        case compliance = "Compliance"
    }
    
    enum Probability: String, CaseIterable {
        case veryLow = "Sehr niedrig"
        case low = "Niedrig"
        case medium = "Mittel"
        case high = "Hoch"
        case veryHigh = "Sehr hoch"
    }
    
    enum RiskStatus: String, CaseIterable {
        case identified = "Identifiziert"
        case assessed = "Bewertet"
        case mitigated = "Gemindert"
        case accepted = "Akzeptiert"
        case closed = "Geschlossen"
    }
}

// MARK: - Meeting Recap Structure
struct MeetingRecap: Identifiable, Codable {
    let id = UUID()
    var title: String
    var date: Date
    var duration: TimeInterval
    var type: MeetingType
    var location: String?
    var platform: String? // For virtual meetings
    var facilitator: String?
    
    // Core content
    var participants: [Participant]
    var agenda: [AgendaItem]
    var decisions: [DecisionPoint]
    var actionItems: [ActionItem]
    var timeline: [TimelineEvent]
    var discussionPoints: [DiscussionPoint]
    var risks: [Risk]
    
    // Analysis and insights
    var meetingEffectiveness: MeetingEffectiveness
    var keyThemes: [String]
    var nextMeeting: NextMeetingSuggestion?
    var followUpReminders: [FollowUpReminder]
    var summary: String
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct MeetingEffectiveness: Codable {
    var participationScore: Double // 0-100
    var decisionMakingScore: Double // 0-100
    var actionItemsScore: Double // 0-100
    var overallScore: Double // 0-100
    var attendanceRate: Double // 0-100
    var engagementLevel: Double // 0-100
    var efficiencyRating: Double // 0-100
    
    var recommendations: [String]
}

struct NextMeetingSuggestion: Codable {
    var suggestedDate: Date
    var suggestedDuration: TimeInterval
    var topics: [String]
    var requiredParticipants: [String]
    var meetingType: MeetingType
    var objectives: [String]
}

struct FollowUpReminder: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var dueDate: Date
    var assignedTo: String
    var priority: Priority
    var isCompleted: Bool = false
    
    enum Priority: String, CaseIterable {
        case low = "Niedrig"
        case medium = "Mittel"
        case high = "Hoch"
        case urgent = "Dringend"
    }
}

// MARK: - Main Meeting Recap Generator
class MeetingRecapGenerator {
    private let nlp = NLTagger(tagSchemes: [.nameType, .lexicalClass, .language])
    
    // MARK: - Public Interface
    
    func generateMeetingRecap(from content: String, metadata: MeetingMetadata) -> MeetingRecap {
        let sentences = content.components(separatedBy: .punctuationCharacters).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        let participants = extractParticipants(from: content)
        let agenda = extractAgenda(from: sentences)
        let decisions = extractDecisions(from: sentences, participants: participants)
        let actionItems = extractActionItems(from: sentences, participants: participants)
        let timeline = extractTimeline(from: sentences)
        let discussionPoints = categorizeDiscussionPoints(from: sentences, participants: participants)
        let risks = identifyRisks(from: sentences)
        let effectiveness = calculateMeetingEffectiveness(
            participants: participants,
            decisions: decisions,
            actionItems: actionItems,
            timeline: timeline
        )
        let keyThemes = extractKeyThemes(from: sentences)
        let nextMeeting = suggestNextMeeting(from: agenda, decisions: decisions, actionItems: actionItems)
        let followUpReminders = generateFollowUpReminders(actionItems: actionItems, decisions: decisions)
        let summary = generateSummary(
            title: metadata.title,
            participants: participants,
            decisions: decisions,
            actionItems: actionItems,
            keyThemes: keyThemes
        )
        
        return MeetingRecap(
            title: metadata.title,
            date: metadata.date,
            duration: metadata.duration,
            type: classifyMeetingType(from: content),
            location: metadata.location,
            platform: metadata.platform,
            facilitator: metadata.facilitator,
            participants: participants,
            agenda: agenda,
            decisions: decisions,
            actionItems: actionItems,
            timeline: timeline,
            discussionPoints: discussionPoints,
            risks: risks,
            meetingEffectiveness: effectiveness,
            keyThemes: keyThemes,
            nextMeeting: nextMeeting,
            followUpReminders: followUpReminders,
            summary: summary
        )
    }
    
    // MARK: - Metadata Structure
    struct MeetingMetadata {
        var title: String
        var date: Date
        var duration: TimeInterval
        var location: String?
        var platform: String?
        var facilitator: String?
    }
    
    // MARK: - Participant Management
    
    private func extractParticipants(from content: String) -> [Participant] {
        var participants: [Participant] = []
        
        // Common patterns for participant identification
        let patterns = [
            #"([A-Z][a-z]+ [A-Z][a-z]+)"#,
            #"([A-Z][a-z]+,\s*[A-Z][a-z]+)"#,
            #"(?:anwesend|teilnehmer|an der Besprechung nehmen teil)[:\s]+([A-Za-z\s,]+)"#
        ]
        
        var foundNames = Set<String>()
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: content) {
                        let name = String(content[range]).trimmingCharacters(in: .whitespaces)
                        if !name.isEmpty && name.count < 50 {
                            foundNames.insert(name)
                        }
                    }
                }
            }
        }
        
        // Create Participant objects
        for name in foundNames {
            let participant = Participant(
                name: name,
                role: extractRole(for: name, from: content),
                department: extractDepartment(for: name, from: content),
                email: extractEmail(for: name, from: content),
                phone: extractPhone(for: name, from: content)
            )
            participants.append(participant)
        }
        
        return participants.sorted { $0.name < $1.name }
    }
    
    private func extractRole(for name: String, from content: String) -> String? {
        let patterns = [
            #"(?i)#(name)[:\s]+([A-Za-z\s]+)"#,
            #"(?i)([A-Za-z\s]+)\s+(?:als|als)\s+([A-Za-z\s]+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 2), in: content) {
                        return String(content[range]).trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractDepartment(for name: String, from content: String) -> String? {
        let departmentKeywords = ["Entwicklung", "Marketing", "Vertrieb", "HR", "Finanzen", "IT", "Produkt", "Design"]
        
        for keyword in departmentKeywords {
            if content.localizedCaseInsensitiveContains(keyword) {
                return keyword
            }
        }
        
        return nil
    }
    
    private func extractEmail(for name: String, from content: String) -> String? {
        let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        
        if let regex = try? NSRegularExpression(pattern: emailPattern) {
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            
            for match in matches {
                if let range = Range(match.range, in: content) {
                    return String(content[range])
                }
            }
        }
        
        return nil
    }
    
    private func extractPhone(for name: String, from content: String) -> String? {
        let phonePattern = #"(\+?\d[\d\s\-\(\)]{7,}\d)"#
        
        if let regex = try? NSRegularExpression(pattern: phonePattern) {
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: content) {
                    return String(content[range]).trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Agenda Management
    
    private func extractAgenda(from sentences: [String]) -> [AgendaItem] {
        var agendaItems: [AgendaItem] = []
        var currentItem: AgendaItem?
        
        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespaces)
            
            // Identify agenda item headers
            if isAgendaHeader(trimmedSentence) {
                if let item = currentItem {
                    agendaItems.append(item)
                }
                
                currentItem = AgendaItem(
                    title: extractAgendaTitle(from: trimmedSentence),
                    description: "",
                    priority: extractPriority(from: trimmedSentence),
                    presenter: extractPresenter(from: trimmedSentence)
                )
            } else if var item = currentItem {
                // Add content to current agenda item
                item.description += (item.description.isEmpty ? "" : " ") + trimmedSentence
                currentItem = item
            }
        }
        
        if let item = currentItem {
            agendaItems.append(item)
        }
        
        return agendaItems
    }
    
    private func isAgendaHeader(_ sentence: String) -> Bool {
        let agendaPatterns = [
            #"(?i)^\d+[\.\)]\s*"#,
            #"(?i)^agenda"#,
            #"(?i)^thema"#,
            #"(?i)^punkt"#,
            #"(?i)agenda[:\s]"#
        ]
        
        for pattern in agendaPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.utf16.count))
                if !matches.isEmpty {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func extractAgendaTitle(from sentence: String) -> String {
        // Remove common agenda prefixes and clean up
        let cleaned = sentence.replacingOccurrences(of: #"(?i)^(\d+[\.\)]\s*)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)^agenda[:\s]*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        return cleaned.isEmpty ? "Untitled Agenda Item" : cleaned
    }
    
    private func extractPriority(from sentence: String) -> AgendaItem.Priority {
        if sentence.localizedCaseInsensitiveContains("dringend") || sentence.localizedCaseInsensitiveContains("urgent") {
            return .urgent
        } else if sentence.localizedCaseInsensitiveContains("wichtig") || sentence.localizedCaseInsensitiveContains("hoch") {
            return .high
        } else if sentence.localizedCaseInsensitiveContains("niedrig") {
            return .low
        }
        
        return .medium
    }
    
    private func extractPresenter(from sentence: String) -> String? {
        let presenterPatterns = [
            #"(?i)(?:präsentiert von|vortragend|referent)[:\s]+([A-Za-z\s]+)"#
        ]
        
        for pattern in presenterPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: sentence) {
                        return String(sentence[range]).trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Decision Point Documentation
    
    private func extractDecisions(from sentences: [String], participants: [Participant]) -> [DecisionPoint] {
        var decisions: [DecisionPoint] = []
        
        for sentence in sentences {
            if isDecisionStatement(sentence) {
                let decision = DecisionPoint(
                    description: extractDecisionDescription(from: sentence),
                    participants: findParticipants(in: sentence, from: participants),
                    impact: assessDecisionImpact(from: sentence),
                    rationale: extractDecisionRationale(from: sentence),
                    consequences: extractConsequences(from: sentence),
                    implementationPlan: extractImplementationPlan(from: sentence),
                    requiresFollowUp: requiresFollowUp(sentence),
                    followUpDate: extractFollowUpDate(from: sentence)
                )
                decisions.append(decision)
            }
        }
        
        return decisions
    }
    
    private func isDecisionStatement(_ sentence: String) -> Bool {
        let decisionKeywords = [
            "entschieden", "beschlossen", "genehmigt", "abgelehnt",
            "vereinbart", "festgelegt", "bestätigt", "akzeptiert",
            "decided", "approved", "rejected", "agreed", "confirmed"
        ]
        
        return decisionKeywords.contains { sentence.localizedCaseInsensitiveContains($0) }
    }
    
    private func extractDecisionDescription(from sentence: String) -> String {
        // Remove decision keywords and clean up
        let cleaned = sentence.replacingOccurrences(of: #"(?i)(?:wir|man)\s+(?:entschieden|beschlossen|genehmigt|vereinbart)"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        return cleaned.isEmpty ? sentence : cleaned
    }
    
    private func assessDecisionImpact(from sentence: String) -> ImpactLevel {
        if sentence.localizedCaseInsensitiveContains("kritisch") || sentence.localizedCaseInsensitiveContains("重大") {
            return .critical
        } else if sentence.localizedCaseInsensitiveContains("hoch") || sentence.localizedCaseInsensitiveContains("signifikant") {
            return .high
        } else if sentence.localizedCaseInsensitiveContains("niedrig") {
            return .low
        }
        
        return .medium
    }
    
    private func extractDecisionRationale(from sentence: String) -> String {
        // Look for reasoning keywords
        let rationalePatterns = [
            #"(?i)(?:weil|da|daher|deshalb)[:\s]+([^.!?]+)"#,
            #"(?i)(?:grund|ursache)[:\s]+([^.!?]+)"#
        ]
        
        for pattern in rationalePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: sentence) {
                        return String(sentence[range]).trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        return "Keine Begründung angegeben"
    }
    
    private func extractConsequences(from sentence: String) -> String? {
        let consequencePatterns = [
            #"(?i)(?:folgen|auswirkung|konsequenz)[:\s]+([^.!?]+)"#
        ]
        
        for pattern in consequencePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: sentence) {
                        return String(sentence[range]).trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractImplementationPlan(from sentence: String) -> String? {
        let implementationPatterns = [
            #"(?i)(?:umsetzung|durchführung|implementierung)[:\s]+([^.!?]+)"#
        ]
        
        for pattern in implementationPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: sentence) {
                        return String(sentence[range]).trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func requiresFollowUp(_ sentence: String) -> Bool {
        let followUpKeywords = ["nachfassen", "follow-up", "review", "überprüfung", "kontrollieren"]
        return followUpKeywords.contains { sentence.localizedCaseInsensitiveContains($0) }
    }
    
    private func extractFollowUpDate(from sentence: String) -> Date? {
        // Simple date extraction - in a real implementation, you'd use a more sophisticated date parser
        let datePatterns = [
            #"(?i)(\d{1,2}\.\d{1,2}\.\d{4})"#,
            #"(?i)(\d{4}-\d{2}-\d{2})"#
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: sentence) {
                        let dateString = String(sentence[range])
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd.MM.yyyy"
                        if let date = formatter.date(from: dateString) {
                            return date
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Action Item Management
    
    private func extractActionItems(from sentences: [String], participants: [Participant]) -> [ActionItem] {
        var actionItems: [ActionItem] = []
        
        for sentence in sentences {
            if isActionItem(sentence) {
                let actionItem = ActionItem(
                    title: extractActionTitle(from: sentence),
                    description: extractActionDescription(from: sentence),
                    assignedTo: extractAssignedTo(from: sentence, participants: participants),
                    priority: extractActionPriority(from: sentence),
                    dueDate: extractActionDueDate(from: sentence),
                    category: extractActionCategory(from: sentence)
                )
                actionItems.append(actionItem)
            }
        }
        
        return actionItems
    }
    
    private func isActionItem(_ sentence: String) -> Bool {
        let actionKeywords = [
            "todo", "aufgabe", "erledigen", "umsetzen", "durchführen",
            "bearbeiten", "klären", "prüfen", "erstellen", "vorbereiten",
            "reviewen", "testen", "implementieren"
        ]
        
        return actionKeywords.contains { sentence.localizedCaseInsensitiveContains($0) }
    }
    
    private func extractActionTitle(from sentence: String) -> String {
        // Extract the main action verb and object
        let cleaned = sentence.trimmingCharacters(in: .whitespaces)
        if cleaned.count > 100 {
            return String(cleaned.prefix(100)) + "..."
        }
        return cleaned
    }
    
    private func extractActionDescription(from sentence: String) -> String {
        // For now, return the full sentence as description
        // In a real implementation, you'd parse this more sophisticatedly
        return sentence.trimmingCharacters(in: .whitespaces)
    }
    
    private func extractAssignedTo(from sentence: String, participants: [Participant]) -> String {
        let assignmentPatterns = [
            #"(?i)(?:zuständig|verantwortlich|assigned to)[:\s]+([A-Za-z\s]+)"#,
            #"(?i)([A-Za-z\s]+)\s+(?:macht|übernimmt|ist zuständig)"#
        ]
        
        for pattern in assignmentPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: sentence) {
                        let assignedPerson = String(sentence[range]).trimmingCharacters(in: .whitespaces)
                        
                        // Check if this matches a known participant
                        if participants.contains(where: { $0.name.localizedCaseInsensitiveContains(assignedPerson) }) {
                            return participants.first { $0.name.localizedCaseInsensitiveContains(assignedPerson) }?.name ?? assignedPerson
                        }
                        
                        return assignedPerson
                    }
                }
            }
        }
        
        return "Unassigned"
    }
    
    private func extractActionPriority(from sentence: String) -> ActionItem.Priority {
        if sentence.localizedCaseInsensitiveContains("dringend") || sentence.localizedCaseInsensitiveContains("urgent") {
            return .urgent
        } else if sentence.localizedCaseInsensitiveContains("hoch") {
            return .high
        } else if sentence.localizedCaseInsensitiveContains("niedrig") {
            return .low
        }
        
        return .medium
    }
    
    private func extractActionDueDate(from sentence: String) -> Date? {
        // Simple due date extraction
        let datePatterns = [
            #"(?i)(?:bis|deadline|fällig)[:\s]+(\d{1,2}\.\d{1,2}\.\d{4})"#,
            #"(?i)(?:bis|deadline|fällig)[:\s]+(\d{4}-\d{2}-\d{2})"#
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: sentence) {
                        let dateString = String(sentence[range])
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd.MM.yyyy"
                        if let date = formatter.date(from: dateString) {
                            return date
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractActionCategory(from sentence: String) -> ActionItem.ActionCategory {
        if sentence.localizedCaseInsensitiveContains("entwickeln") || sentence.localizedCaseInsensitiveContains("code") {
            return .development
        } else if sentence.localizedCaseInsensitiveContains("test") {
            return .testing
        } else if sentence.localizedCaseInsensitiveContains("dokument") {
            return .documentation
        } else if sentence.localizedCaseInsensitiveContains("recherche") {
            return .research
        } else if sentence.localizedCaseInsensitiveContains("review") {
            return .review
        } else if sentence.localizedCaseInsensitiveContains("plan") {
            return .planning
        } else if sentence.localizedCaseInsensitiveContains("kommunik") {
            return .communication
        }
        
        return .general
    }
    
    // MARK: - Timeline Extraction
    
    private func extractTimeline(from sentences: [String]) -> [TimelineEvent] {
        var timeline: [TimelineEvent] = []
        var currentTime = Date()
        
        for sentence in sentences {
            if let timeEvent = parseTimelineEvent(from: sentence, timestamp: currentTime) {
                timeline.append(timeEvent)
                currentTime = currentTime.addingTimeInterval(300) // Add 5 minutes default
            }
        }
        
        return timeline
    }
    
    private func parseTimelineEvent(from sentence: String, timestamp: Date) -> TimelineEvent? {
        let category = determineTimelineCategory(from: sentence)
        let importance = determineImportance(from: sentence)
        let participants = findParticipants(in: sentence, from: [])
        
        return TimelineEvent(
            timestamp: timestamp,
            event: sentence.trimmingCharacters(in: .whitespaces),
            participants: participants,
            category: category,
            importance: importance
        )
    }
    
    private func determineTimelineCategory(from sentence: String) -> TimelineEvent.TimelineCategory {
        if isDecisionStatement(sentence) {
            return .decision
        } else if isActionItem(sentence) {
            return .action
        } else if sentence.localizedCaseInsensitiveContains("pause") {
            return .break
        } else if sentence.localizedCaseInsensitiveContains("konflikt") || sentence.localizedCaseInsensitiveContains("disagreement") {
            return .conflict
        } else if sentence.localizedCaseInsensitiveContains("einigung") || sentence.localizedCaseInsensitiveContains("agreement") {
            return .agreement
        } else if isAgendaHeader(sentence) {
            return .agenda
        }
        
        return .discussion
    }
    
    private func determineImportance(from sentence: String) -> TimelineEvent.Importance {
        if sentence.localizedCaseInsensitiveContains("kritisch") || sentence.localizedCaseInsensitiveContains("entscheidend") {
            return .critical
        } else if sentence.localizedCaseInsensitiveContains("wichtig") {
            return .high
        } else if sentence.localizedCaseInsensitiveContains("niedrig") {
            return .low
        }
        
        return .medium
    }
    
    // MARK: - Discussion Points Categorization
    
    private func categorizeDiscussionPoints(from sentences: [String], participants: [Participant]) -> [DiscussionPoint] {
        var discussionPoints: [DiscussionPoint] = []
        
        for sentence in sentences {
            if !isDecisionStatement(sentence) && !isActionItem(sentence) && !isAgendaHeader(sentence) {
                let discussionPoint = DiscussionPoint(
                    title: extractDiscussionTitle(from: sentence),
                    content: sentence.trimmingCharacters(in: .whitespaces),
                    category: categorizeDiscussionContent(sentence),
                    participants: findParticipants(in: sentence, from: participants),
                    sentiment: analyzeSentiment(sentence),
                    keyInsights: extractKeyInsights(sentence)
                )
                discussionPoints.append(discussionPoint)
            }
        }
        
        return discussionPoints
    }
    
    private func extractDiscussionTitle(from sentence: String) -> String {
        // Extract first 50 characters as title
        let trimmed = sentence.trimmingCharacters(in: .whitespaces)
        if trimmed.count > 50 {
            return String(trimmed.prefix(50)) + "..."
        }
        return trimmed
    }
    
    private func categorizeDiscussionContent(_ content: String) -> DiscussionPoint.DiscussionCategory {
        if content.localizedCaseInsensitiveContains("technisch") || content.localizedCaseInsensitiveContains("code") || content.localizedCaseInsensitiveContains("system") {
            return .technical
        } else if content.localizedCaseInsensitiveContains("business") || content.localizedCaseInsensitiveContains("verkauf") {
            return .business
        } else if content.localizedCaseInsensitiveContains("prozess") || content.localizedCaseInsensitiveContains("workflow") {
            return .process
        } else if content.localizedCaseInsensitiveContains("personal") || content.localizedCaseInsensitiveContains("team") {
            return .people
        } else if content.localizedCaseInsensitiveContains("strategie") || content.localizedCaseInsensitiveContains("vision") {
            return .strategy
        } else if content.localizedCaseInsensitiveContains("budget") || content.localizedCaseInsensitiveContains("kosten") {
            return .budget
        } else if content.localizedCaseInsensitiveContains("zeit") || content.localizedCaseInsensitiveContains("deadline") {
            return .timeline
        } else if content.localizedCaseInsensitiveContains("qualität") || content.localizedCaseInsensitiveContains("standard") {
            return .quality
        }
        
        return .general
    }
    
    private func analyzeSentiment(_ content: String) -> DiscussionPoint.Sentiment {
        let positiveWords = ["gut", "toll", "erfolgreich", "positiv", "einverstanden", "zustimmung"]
        let negativeWords = ["schlecht", "problem", "kritik", "negativ", "ablehnung", "schwierig"]
        
        let lowercased = content.lowercased()
        let positiveCount = positiveWords.filter { lowercased.contains($0) }.count
        let negativeCount = negativeWords.filter { lowercased.contains($0) }.count
        
        if positiveCount > negativeCount {
            return .positive
        } else if negativeCount > positiveCount {
            return .negative
        } else if !positiveCount.isEmpty && !negativeCount.isEmpty {
            return .mixed
        }
        
        return .neutral
    }
    
    private func extractKeyInsights(_ content: String) -> [String] {
        var insights: [String] = []
        
        // Look for insight keywords
        let insightPatterns = [
            #"(?i)(?:erkenntnis|einsicht|fazit|feststellung)[:\s]+([^.!?]+)"#
        ]
        
        for pattern in insightPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: content) {
                        let insight = String(content[range]).trimmingCharacters(in: .whitespaces)
                        insights.append(insight)
                    }
                }
            }
        }
        
        return insights
    }
    
    // MARK: - Risk Identification
    
    private func identifyRisks(from sentences: [String]) -> [Risk] {
        var risks: [Risk] = []
        
        for sentence in sentences {
            if isRiskStatement(sentence) {
                let risk = Risk(
                    description: sentence.trimmingCharacters(in: .whitespaces),
                    category: categorizeRisk(sentence),
                    probability: assessRiskProbability(sentence),
                    impact: assessRiskImpact(sentence),
                    mitigationStrategies: extractMitigationStrategies(sentence),
                    owner: extractRiskOwner(sentence)
                )
                risks.append(risk)
            }
        }
        
        return risks
    }
    
    private func isRiskStatement(_ sentence: String) -> Bool {
        let riskKeywords = [
            "risiko", "gefahr", "problem", "schwierigkeit", "herausforderung",
            "verzögerung", "ausfall", "fehler", "mangel", "schwachstelle"
        ]
        
        return riskKeywords.contains { sentence.localizedCaseInsensitiveContains($0) }
    }
    
    private func categorizeRisk(_ sentence: String) -> Risk.RiskCategory {
        if sentence.localizedCaseInsensitiveContains("technisch") || sentence.localizedCaseInsensitiveContains("system") {
            return .technical
        } else if sentence.localizedCaseInsensitiveContains("zeit") || sentence.localizedCaseInsensitiveContains("deadline") {
            return .schedule
        } else if sentence.localizedCaseInsensitiveContains("kosten") || sentence.localizedCaseInsensitiveContains("budget") {
            return .budget
        } else if sentence.localizedCaseInsensitiveContains("personal") || sentence.localizedCaseInsensitiveContains("ressourcen") {
            return .resources
        } else if sentence.localizedCaseInsensitiveContains("kunde") || sentence.localizedCaseInsensitiveContains("stakeholder") {
            return .stakeholder
        } else if sentence.localizedCaseInsensitiveContains("extern") || sentence.localizedCaseInsensitiveContains("lieferant") {
            return .external
        } else if sentence.localizedCaseInsensitiveContains("recht") || sentence.localizedCaseInsensitiveContains("compliance") {
            return .compliance
        }
        
        return .technical
    }
    
    private func assessRiskProbability(_ sentence: String) -> Risk.Probability {
        if sentence.localizedCaseInsensitiveContains("wahrscheinlich") || sentence.localizedCaseInsensitiveContains("sicher") {
            return .veryHigh
        } else if sentence.localizedCaseInsensitiveContains("möglich") {
            return .medium
        } else if sentence.localizedCaseInsensitiveContains("unwahrscheinlich") {
            return .low
        }
        
        return .medium
    }
    
    private func assessRiskImpact(_ sentence: String) -> ImpactLevel {
        if sentence.localizedCaseInsensitiveContains("kritisch") || sentence.localizedCaseInsensitiveContains("schwerwiegend") {
            return .critical
        } else if sentence.localizedCaseInsensitiveContains("beträchtlich") || sentence.localizedCaseInsensitiveContains("signifikant") {
            return .high
        } else if sentence.localizedCaseInsensitiveContains("gering") {
            return .low
        }
        
        return .medium
    }
    
    private func extractMitigationStrategies(_ sentence: String) -> [String] {
        var strategies: [String] = []
        
        let mitigationPatterns = [
            #"(?i)(?:lösung|maßnahme|strategie)[:\s]+([^.!?]+)"#
        ]
        
        for pattern in mitigationPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: sentence) {
                        let strategy = String(sentence[range]).trimmingCharacters(in: .whitespaces)
                        strategies.append(strategy)
                    }
                }
            }
        }
        
        return strategies
    }
    
    private func extractRiskOwner(_ sentence: String) -> String? {
        let ownerPatterns = [
            #"(?i)(?:zuständig|verantwortlich|owner)[:\s]+([A-Za-z\s]+)"#
        ]
        
        for pattern in ownerPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: sentence) {
                        return String(sentence[range]).trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Meeting Effectiveness Metrics
    
    private func calculateMeetingEffectiveness(
        participants: [Participant],
        decisions: [DecisionPoint],
        actionItems: [ActionItem],
        timeline: [TimelineEvent]
    ) -> MeetingEffectiveness {
        let participationScore = calculateParticipationScore(participants)
        let decisionMakingScore = calculateDecisionMakingScore(decisions)
        let actionItemsScore = calculateActionItemsScore(actionItems)
        let attendanceRate = 100.0 // Would calculate from actual attendance data
        let engagementLevel = calculateEngagementLevel(participants, timeline)
        let efficiencyRating = calculateEfficiencyRating(timeline)
        
        let overallScore = (participationScore + decisionMakingScore + actionItemsScore + engagementLevel + efficiencyRating) / 5.0
        
        let recommendations = generateEffectivenessRecommendations(
            participationScore: participationScore,
            decisionMakingScore: decisionMakingScore,
            actionItemsScore: actionItemsScore,
            engagementLevel: engagementLevel,
            efficiencyRating: efficiencyRating
        )
        
        return MeetingEffectiveness(
            participationScore: participationScore,
            decisionMakingScore: decisionMakingScore,
            actionItemsScore: actionItemsScore,
            overallScore: overallScore,
            attendanceRate: attendanceRate,
            engagementLevel: engagementLevel,
            efficiencyRating: efficiencyRating,
            recommendations: recommendations
        )
    }
    
    private func calculateParticipationScore(_ participants: [Participant]) -> Double {
        guard !participants.isEmpty else { return 0.0 }
        
        let activeParticipants = participants.filter { 
            $0.participationLevel == .active || $0.participationLevel == .dominant 
        }.count
        
        return min(100.0, (Double(activeParticipants) / Double(participants.count)) * 100.0)
    }
    
    private func calculateDecisionMakingScore(_ decisions: [DecisionPoint]) -> Double {
        guard !decisions.isEmpty else { return 50.0 }
        
        let impactSum = decisions.reduce(0) { sum, decision in
            switch decision.impact {
            case .critical: return sum + 4
            case .high: return sum + 3
            case .medium: return sum + 2
            case .low: return sum + 1
            }
        }
        
        return min(100.0, (Double(impactSum) / Double(decisions.count * 4)) * 100.0)
    }
    
    private func calculateActionItemsScore(_ actionItems: [ActionItem]) -> Double {
        guard !actionItems.isEmpty else { return 50.0 }
        
        let completedItems = actionItems.filter { $0.status == .completed }.count
        
        return min(100.0, (Double(completedItems) / Double(actionItems.count)) * 100.0)
    }
    
    private func calculateEngagementLevel(_ participants: [Participant], _ timeline: [TimelineEvent]) -> Double {
        // Calculate based on discussion frequency and participant diversity
        guard !timeline.isEmpty else { return 50.0 }
        
        let discussionEvents = timeline.filter { $0.category == .discussion }.count
        let uniqueParticipants = timeline.flatMap { $0.participants }.count
        
        let engagement = Double(discussionEvents) * Double(uniqueParticipants) / Double(max(participants.count, 1))
        
        return min(100.0, engagement * 10.0)
    }
    
    private func calculateEfficiencyRating(_ timeline: [TimelineEvent]) -> Double {
        guard !timeline.isEmpty else { return 50.0 }
        
        let importantEvents = timeline.filter { 
            $0.importance == .high || $0.importance == .critical 
        }.count
        
        let totalEvents = timeline.count
        
        return min(100.0, (Double(importantEvents) / Double(totalEvents)) * 100.0)
    }
    
    private func generateEffectivenessRecommendations(
        participationScore: Double,
        decisionMakingScore: Double,
        actionItemsScore: Double,
        engagementLevel: Double,
        efficiencyRating: Double
    ) -> [String] {
        var recommendations: [String] = []
        
        if participationScore < 60 {
            recommendations.append("Mehr Teilnehmeraktivität fördern - alle Beteiligten sollten sich stärker einbringen")
        }
        
        if decisionMakingScore < 70 {
            recommendations.append("Entscheidungsprozess verbessern - klarere Beschlüsse und deren Umsetzung")
        }
        
        if actionItemsScore < 80 {
            recommendations.append("Action Items sollten regelmäßiger verfolgt und abgeschlossen werden")
        }
        
        if engagementLevel < 60 {
            recommendations.append("Diskussionsqualität erhöhen - mehr Fokus auf wichtige Themen")
        }
        
        if efficiencyRating < 70 {
            recommendations.append("Meeting-Effizienz steigern - bessere Zeitnutzung und Fokus")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Ausgezeichnetes Meeting! Alle Effizienzmetriken sind auf hohem Niveau")
        }
        
        return recommendations
    }
    
    // MARK: - Key Themes and Suggestions
    
    private func extractKeyThemes(from sentences: [String]) -> [String] {
        // Extract frequently mentioned topics
        let words = sentences.joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
            .map { $0.lowercased() }
        
        let wordCounts = Dictionary(grouping: words, by: { $0 })
            .mapValues { $0.count }
            .filter { $0.key.count > 3 }
            .sorted { $0.value > $1.value }
        
        let themes = wordCounts.prefix(10).map { $0.key }
        
        // Filter out common words
        let stopWords = ["der", "die", "das", "und", "oder", "aber", "ist", "sind", "war", "waren", "haben", "hat", "hatte", "hatten"]
        
        return themes.filter { !stopWords.contains($0) }
    }
    
    private func suggestNextMeeting(
        from agenda: [AgendaItem],
        decisions: [DecisionPoint],
        actionItems: [ActionItem]
    ) -> NextMeetingSuggestion? {
        let pendingActionItems = actionItems.filter { $0.status != .completed }
        let decisionsRequiringFollowUp = decisions.filter { $0.requiresFollowUp }
        
        guard !pendingActionItems.isEmpty || !decisionsRequiringFollowUp.isEmpty else { return nil }
        
        let suggestedDate = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date())!
        let suggestedDuration: TimeInterval = 60 * 60 // 1 hour
        
        var topics: [String] = []
        if !pendingActionItems.isEmpty {
            topics.append("Review der ausstehenden Action Items")
        }
        if !decisionsRequiringFollowUp.isEmpty {
            topics.append("Follow-up zu getroffenen Entscheidungen")
        }
        
        // Add high priority agenda items for next meeting
        let highPriorityAgenda = agenda.filter { $0.priority == .high }.prefix(3)
        topics.append(contentsOf: highPriorityAgenda.map { $0.title })
        
        let requiredParticipants = Array(Set(
            pendingActionItems.compactMap { $0.assignedTo } +
            decisionsRequiringFollowUp.flatMap { $0.participants } +
            highPriorityAgenda.compactMap { $0.presenter }
        )).filter { $0 != "Unassigned" }
        
        let objectives = [
            "Review des Fortschritts",
            "Entscheidungen überprüfen",
            "Neue Aufgaben definieren"
        ]
        
        return NextMeetingSuggestion(
            suggestedDate: suggestedDate,
            suggestedDuration: suggestedDuration,
            topics: Array(topics.prefix(10)),
            requiredParticipants: Array(requiredParticipants.prefix(10)),
            meetingType: .statusUpdate,
            objectives: objectives
        )
    }
    
    private func generateFollowUpReminders(
        actionItems: [ActionItem],
        decisions: [DecisionPoint]
    ) -> [FollowUpReminder] {
        var reminders: [FollowUpReminder] = []
        
        // Create reminders for action items
        for actionItem in actionItems {
            if actionItem.status != .completed {
                let priority: FollowUpReminder.Priority
                switch actionItem.priority {
                case .urgent:
                    priority = .urgent
                case .high:
                    priority = .high
                case .medium:
                    priority = .medium
                case .low:
                    priority = .low
                }
                
                let reminder = FollowUpReminder(
                    title: "Action Item: \(actionItem.title)",
                    description: actionItem.description,
                    dueDate: actionItem.dueDate ?? Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                    assignedTo: actionItem.assignedTo,
                    priority: priority
                )
                reminders.append(reminder)
            }
        }
        
        // Create reminders for decisions requiring follow-up
        for decision in decisions {
            if decision.requiresFollowUp {
                let reminder = FollowUpReminder(
                    title: "Entscheidung Follow-up: \(decision.description.prefix(50))...",
                    description: "Überprüfung der Entscheidung und deren Umsetzung",
                    dueDate: decision.followUpDate ?? Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!,
                    assignedTo: decision.participants.first ?? "Team",
                    priority: .medium
                )
                reminders.append(reminder)
            }
        }
        
        return reminders.sorted { $0.dueDate < $1.dueDate }
    }
    
    private func classifyMeetingType(from content: String) -> MeetingType {
        let contentLower = content.lowercased()
        
        if contentLower.contains("plan") || contentLower.contains("planung") {
            return .planning
        } else if contentLower.contains("review") || contentLower.contains("überprüfung") {
            return .review
        } else if contentLower.contains("brainstorm") || contentLower.contains("ideen") {
            return .brainstorming
        } else if contentLower.contains("status") || contentLower.contains("fortschritt") {
            return .statusUpdate
        } else if contentLower.contains("entscheid") || contentLower.contains("beschlu") {
            return .decisionMaking
        } else if contentLower.contains("retro") || contentLower.contains("reflexion") {
            return .retrospective
        } else if contentLower.contains("standup") || contentLower.contains("täglich") {
            return .standup
        } else if contentLower.contains("kick-off") || contentLower.contains("start") {
            return .projectKickoff
        } else if contentLower.contains("schulung") || contentLower.contains("training") {
            return .training
        } else if contentLower.contains("problem") || contentLower.contains("lösung") {
            return .troubleshooting
        } else if contentLower.contains("strategie") || contentLower.contains("vision") {
            return .strategic
        }
        
        return .statusUpdate // Default
    }
    
    private func generateSummary(
        title: String,
        participants: [Participant],
        decisions: [DecisionPoint],
        actionItems: [ActionItem],
        keyThemes: [String]
    ) -> String {
        let participantCount = participants.count
        let decisionCount = decisions.count
        let actionItemCount = actionItems.count
        
        let summary = """
        \(title) fand am \(Date().formatted(date: .abbreviated, time: .shortened)) statt 
        mit \(participantCount) Teilnehmer\(participantCount == 1 ? "" : "n"). 
        
        \(decisionCount > 0 ? "\(decisionCount) Entscheidung\(decisionCount == 1 ? "" : "en") wurden getroffen." : "Keine formalen Entscheidungen dokumentiert.")\n
        \(actionItemCount > 0 ? "\(actionItemCount) Action Item\(actionItemCount == 1 ? "" : "s") wurden definiert." : "Keine Action Items definiert."}\n
        
        \(keyThemes.isEmpty ? "" : "Hauptthemen: \(keyThemes.joined(separator: ", ")).")
        
        Das Meeting bot eine gute Gelegenheit für Austausch und Planung.
        """
        
        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Helper Methods
    
    private func findParticipants(in text: String, from participants: [Participant]) -> [String] {
        var foundParticipants: [String] = []
        
        for participant in participants {
            if text.localizedCaseInsensitiveContains(participant.name) {
                foundParticipants.append(participant.name)
            }
        }
        
        return Array(Set(foundParticipants))
    }
}