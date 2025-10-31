import Foundation
import NaturalLanguage
import CoreML

// MARK: - Models

struct TodoTask: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var category: TaskCategory
    var priority: TaskPriority
    var urgencyScore: Double // 0-1, AI-calculated
    var estimatedTime: TimeInterval
    var deadline: Date?
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    var dependencies: [UUID]
    var participants: [String]
    var completionProbability: Double // 0-1
    var tags: [String]
    var sourceContent: String?
    var createdAt: Date
    var updatedAt: Date
    var isCompleted: Bool
    
    enum TaskCategory: String, CaseIterable, Codable {
        case work = "work"
        case personal = "personal"
        case urgent = "urgent"
        case meeting = "meeting"
        case project = "project"
        case health = "health"
        case shopping = "shopping"
        case home = "home"
        case other = "other"
    }
    
    enum TaskPriority: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    enum RecurrencePattern: String, CaseIterable, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
        case custom = "custom"
    }
}

struct TaskDependency {
    let taskId: UUID
    let dependsOnTaskId: UUID
    let type: DependencyType
    
    enum DependencyType: String, CaseIterable, Codable {
        case mustComplete = "must_complete"
        case shouldComplete = "should_complete"
        case canOverlap = "can_overlap"
    }
}

struct ContentAnalysis {
    let extractedTasks: [TodoTask]
    let detectedParticipants: [String]
    let deadlines: [DateInference]
    let urgencyIndicators: [UrgencyIndicator]
    let timeEstimates: [TimeEstimate]
    let patterns: [TaskPattern]
}

struct DateInference {
    let inferredDate: Date
    let confidence: Double
    let sourceText: String
    let context: String
}

struct UrgencyIndicator {
    let score: Double
    let keywords: [String]
    let context: String
}

struct TimeEstimate {
    let taskId: UUID
    let estimatedMinutes: Int
    let confidence: Double
    let basis: String
}

struct TaskPattern {
    let patternType: PatternType
    let frequency: Double
    let description: String
    let relatedTasks: [UUID]
    
    enum PatternType: String, CaseIterable {
        case recurring = "recurring"
        case batch = "batch"
        case seasonal = "seasonal"
        case projectPhase = "project_phase"
    }
}

// MARK: - AI-Powered Todo Generator

class TodoGenerator {
    
    // MARK: - Core AI Components
    
    private let nlp = NLTagger(tagSchemes: [.tokenType, .nameType, .language, .lexicalClass])
    private var urgencyKeywords: [String: Double] = [:]
    private var categoryKeywords: [String: String] = [:]
    private var timeIndicatorKeywords: [String: Int] = [:]
    
    // MARK: - Initialization
    
    init() {
        setupAILanguageModels()
        loadKnowledgeBase()
    }
    
    // MARK: - Public Methods
    
    /// Generiert intelligente Todos aus Content
    func generateTodos(from content: String, context: AnalysisContext = AnalysisContext()) async throws -> ContentAnalysis {
        print("🤖 Starte AI-gestützte Todo-Generierung...")
        
        // 1. Content-Analyse
        let tokenizedContent = tokenizeContent(content)
        let participants = detectParticipants(tokenizedContent)
        let deadlines = extractDeadlines(tokenizedContent)
        let urgencyIndicators = analyzeUrgency(tokenizedContent)
        
        // 2. Action Item Extraction
        let potentialTasks = extractActionItems(tokenizedContent)
        
        // 3. Task Processing
        var processedTasks: [TodoTask] = []
        for potentialTask in potentialTasks {
            let task = try await processTask(potentialTask, 
                                          urgencyIndicators: urgencyIndicators,
                                          context: context)
            processedTasks.append(task)
        }
        
        // 4. Smart Merging & Deduplication
        let mergedTasks = smartMergeTasks(processedTasks)
        
        // 5. Dependencies Detection
        let dependencies = detectDependencies(mergedTasks)
        
        // 6. Pattern Recognition
        let patterns = recognizePatterns(mergedTasks)
        
        // 7. Time Estimation
        let timeEstimates = estimateTaskTimes(mergedTasks)
        
        // 8. Completion Probability Assessment
        let tasksWithProbability = calculateCompletionProbability(mergedTasks)
        
        // 9. Final Assembly
        let finalTasks = addDependenciesToTasks(tasksWithProbability, dependencies: dependencies)
        
        print("✅ Todo-Generierung abgeschlossen: \(finalTasks.count) Tasks erstellt")
        
        return ContentAnalysis(
            extractedTasks: finalTasks,
            detectedParticipants: participants,
            deadlines: deadlines,
            urgencyIndicators: urgencyIndicators,
            timeEstimates: timeEstimates,
            patterns: patterns
        )
    }
    
    // MARK: - Private Methods
    
    private func setupAILanguageModels() {
        // Initialisiere Natural Language Processing
        nlp.string = ""
        
        // Setup Urgency Keywords
        urgencyKeywords = [
            "sofort": 1.0, "urgent": 0.9, "wichtig": 0.8, "kritisch": 1.0,
            "bald": 0.6, "dringend": 0.9, "asap": 0.95, "heute": 0.8,
            "morgen": 0.7, "diese Woche": 0.6, "nächste Woche": 0.4,
            "überfällig": 1.0, "verspätet": 0.9, "dringend": 0.9
        ]
        
        // Setup Category Keywords
        categoryKeywords = [
            "meeting": "meeting", "termin": "meeting", "besprechung": "meeting",
            "arbeit": "work", "büro": "work", "projekt": "project",
            "einkaufen": "shopping", "shop": "shopping", "supermarkt": "shopping",
            "arzt": "health", "gesundheit": "health", "medizin": "health",
            "haushalt": "home", "reinigung": "home", "kochen": "home",
            "schule": "personal", "ausbildung": "personal", "lernen": "personal"
        ]
        
        // Setup Time Indicators
        timeIndicatorKeywords = [
            "minute": 1, "minuten": 1, "stunde": 60, "stunden": 60,
            "tag": 1440, "tage": 1440, "woche": 10080, "wochen": 10080
        ]
    }
    
    private func loadKnowledgeBase() {
        // Lade weitere AI-Modelle und Knowledge Base
        // Hier könnten Core ML Models, XML-Dateien etc. geladen werden
    }
    
    private func tokenizeContent(_ content: String) -> [String] {
        nlp.string = content
        var tokens: [String] = []
        
        nlp.enumerateTags(in: content.startIndex..<content.endIndex, 
                         unit: .word, 
                         scheme: .tokenType) { tag, tokenRange in
            if let tag = tag, tag == .word {
                let word = String(content[tokenRange])
                tokens.append(word)
            }
            return true
        }
        
        return tokens
    }
    
    private func detectParticipants(_ tokens: [String]) -> [String] {
        // Erweiterte Teilnehmer-Erkennung
        var participants: [String] = []
        var potentialNames: [String] = []
        
        // Suche nach Personennamen (vereinfacht)
        for i in 0..<tokens.count {
            let token = tokens[i]
            if isLikelyName(token) {
                // Prüfe ob nächster Token auch ein Name ist (Vor- und Nachname)
                if i + 1 < tokens.count && isLikelyName(tokens[i + 1]) {
                    let fullName = "\(token) \(tokens[i + 1])"
                    participants.append(fullName)
                    potentialNames.append(fullName)
                } else {
                    participants.append(token)
                    potentialNames.append(token)
                }
            }
        }
        
        // Erweiterte Erkennung für Pronomen und Possessivpronomen
        let participantPronouns = extractParticipantPronouns(tokens)
        participants.append(contentsOf: participantPronouns)
        
        return Array(Set(participants))
    }
    
    private func isLikelyName(_ word: String) -> Bool {
        // Vereinfachte Heuristik für Namen
        return word.count > 1 && 
               word.first?.isUppercase == true && 
               !isCommonWord(word.lowercased())
    }
    
    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = ["der", "die", "das", "und", "oder", "aber", "in", "auf", "ist", "sind", "war", "waren", "haben", "hat"]
        return commonWords.contains(word)
    }
    
    private func extractParticipantPronouns(_ tokens: [String]) -> [String] {
        var pronouns: [String] = []
        let pronounPatterns = [
            "ich", "du", "er", "sie", "es", "wir", "ihr",
            "meine", "deine", "seine", "ihre", "unsere", "eure"
        ]
        
        for token in tokens {
            if pronounPatterns.contains(token.lowercased()) {
                pronouns.append(token)
            }
        }
        
        return pronouns
    }
    
    private func extractDeadlines(_ tokens: [String]) -> [DateInference] {
        var deadlines: [DateInference] = []
        let currentDate = Date()
        
        // Zeitliche Ausdrücke erkennen
        let timePatterns = [
            (pattern: #"heute"# , days: 0),
            (pattern: #"morgen"# , days: 1),
            (pattern: #"übermorgen"# , days: 2),
            (pattern: #"nächste Woche"# , days: 7),
            (pattern: #"diese Woche"# , days: 0),
            (pattern: #"Montag"# , weekday: 2),
            (pattern: #"Dienstag"# , weekday: 3),
            (pattern: #"Mittwoch"# , weekday: 4),
            (pattern: #"Donnerstag"# , weekday: 5),
            (pattern: #"Freitag"# , weekday: 6),
            (pattern: #"Samstag"# , weekday: 7),
            (pattern: #"Sonntag"# , weekday: 1)
        ]
        
        for (index, token) in tokens.enumerated() {
            for timePattern in timePatterns {
                if let range = token.range(of: timePattern.pattern, options: .regularExpression) {
                    var inferredDate = currentDate
                    
                    if let days = timePattern.days {
                        inferredDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate)!
                    } else if let weekday = timePattern.weekday {
                        let calendar = Calendar.current
                        let currentWeekday = calendar.component(.weekday, from: currentDate)
                        let daysToAdd = (weekday - currentWeekday + 7) % 7
                        inferredDate = calendar.date(byAdding: .day, value: daysToAdd, to: currentDate)!
                    }
                    
                    let context = extractContext(for: index, in: tokens)
                    
                    deadlines.append(DateInference(
                        inferredDate: inferredDate,
                        confidence: 0.8,
                        sourceText: token,
                        context: context
                    ))
                    break
                }
            }
        }
        
        return deadlines
    }
    
    private func extractContext(for index: Int, in tokens: [String]) -> String {
        let startIndex = max(0, index - 3)
        let endIndex = min(tokens.count, index + 4)
        let contextTokens = Array(tokens[startIndex..<endIndex])
        return contextTokens.joined(separator: " ")
    }
    
    private func analyzeUrgency(_ tokens: [String]) -> [UrgencyIndicator] {
        var indicators: [UrgencyIndicator] = []
        
        for (index, token) in tokens.enumerated() {
            let lowerToken = token.lowercased()
            
            for (keyword, score) in urgencyKeywords {
                if lowerToken.contains(keyword) {
                    let context = extractContext(for: index, in: tokens)
                    
                    indicators.append(UrgencyIndicator(
                        score: score,
                        keywords: [keyword],
                        context: context
                    ))
                }
            }
        }
        
        return indicators
    }
    
    private func extractActionItems(_ tokens: [String]) -> [String] {
        var actionItems: [String] = []
        var currentAction = ""
        let actionVerbs = [
            "erledigen", "machen", "tun", "umsetzen", "durchführen",
            "organisieren", "planen", "vorbereiten", "fertigstellen",
            "kontrollieren", "überprüfen", "anrufen", "schreiben",
            "besuchen", "kaufen", "verkaufen", "installieren",
            "konfigurieren", "testen", "dokumentieren", "presentieren"
        ]
        
        // Verb-Phrase Pattern Matching
        for i in 0..<tokens.count {
            let token = tokens[i].lowercased()
            
            // Prüfe auf Aktionsverben
            if actionVerbs.contains(token) {
                // Sammle Kontext vor und nach dem Verb
                let beforeContext = extractContext(for: max(0, i-5), in: tokens)
                let afterContext = extractContext(for: min(tokens.count-1, i+1), in: tokens)
                
                // Forme potentielle Task
                let taskCandidate = "\(beforeContext) \(token) \(afterContext)".trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !taskCandidate.isEmpty {
                    actionItems.append(taskCandidate)
                }
            }
        }
        
        // Imperativ-Formen Erkennung
        for i in 0..<tokens.count {
            let token = tokens[i]
            if isImperativeForm(token) {
                let context = extractContext(for: i, in: tokens)
                actionItems.append(context)
            }
        }
        
        return actionItems
    }
    
    private func isImperativeForm(_ word: String) -> Bool {
        // Vereinfachte Imperativ-Erkennung
        let imperativePatterns = [
            "machen", "tun", "erledigen", "bitte", "sollte", "muss",
            "könnte", "soll", "werden", "wird", "geht", "kann"
        ]
        return imperativePatterns.contains(word.lowercased())
    }
    
    private func categorizeTask(_ taskDescription: String, tokens: [String]) -> TodoTask.TaskCategory {
        let lowerDescription = taskDescription.lowercased()
        
        for (keyword, category) in categoryKeywords {
            if lowerDescription.contains(keyword) {
                return TodoTask.TaskCategory(rawValue: category) ?? .other
            }
        }
        
        // Fallback: Textanalyse für Kategorisierung
        if tokens.contains("meeting") || tokens.contains("besprechung") || tokens.contains("termin") {
            return .meeting
        } else if tokens.contains("projekt") || tokens.contains("arbeit") {
            return .work
        } else if tokens.contains("einkaufen") || tokens.contains("shop") {
            return .shopping
        } else if tokens.contains("arzt") || tokens.contains("gesundheit") {
            return .health
        } else if tokens.contains("haushalt") || tokens.contains("home") {
            return .home
        } else {
            return .personal
        }
    }
    
    private func calculateUrgencyScore(_ taskDescription: String, urgencyIndicators: [UrgencyIndicator]) -> Double {
        var totalScore = 0.0
        var weightSum = 0.0
        
        let lowerDescription = taskDescription.lowercased()
        
        for indicator in urgencyIndicators {
            let indicatorRelevance = calculateRelevance(indicator.context, to: taskDescription)
            totalScore += indicator.score * indicatorRelevance
            weightSum += indicatorRelevance
        }
        
        // Zusätzliche Keywords im Task selbst prüfen
        for (keyword, score) in urgencyKeywords {
            if lowerDescription.contains(keyword) {
                totalScore += score * 0.5
                weightSum += 0.5
            }
        }
        
        return weightSum > 0 ? min(1.0, totalScore / max(weightSum, 1.0)) : 0.5
    }
    
    private func calculateRelevance(_ context: String, to task: String) -> Double {
        // Einfache Relevanz-Berechnung basierend auf gemeinsamen Wörtern
        let contextWords = Set(context.lowercased().split(whereSeparator: { !$0.isLetter }))
        let taskWords = Set(task.lowercased().split(whereSeparator: { !$0.isLetter }))
        
        let intersection = contextWords.intersection(taskWords)
        let union = contextWords.union(taskWords)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func determinePriority(_ urgencyScore: Double, category: TodoTask.TaskCategory) -> TodoTask.TaskPriority {
        // Kombiniere Urgency Score mit Kategorie für Priorität
        let categoryWeight: Double
        
        switch category {
        case .urgent:
            categoryWeight = 0.9
        case .work, .project:
            categoryWeight = 0.7
        case .meeting:
            categoryWeight = 0.8
        case .health:
            categoryWeight = 0.8
        case .personal, .home:
            categoryWeight = 0.4
        case .shopping:
            categoryWeight = 0.5
        case .other:
            categoryWeight = 0.3
        }
        
        let combinedScore = (urgencyScore * 0.7) + (categoryWeight * 0.3)
        
        switch combinedScore {
        case 0.8...1.0:
            return .critical
        case 0.6..<0.8:
            return .high
        case 0.4..<0.6:
            return .medium
        default:
            return .low
        }
    }
    
    private func estimateTime(_ taskDescription: String, tokens: [String]) -> TimeInterval {
        // KI-basierte Zeitschätzung
        let lowerDescription = taskDescription.lowercased()
        
        // Explizite Zeitangaben erkennen
        for (keyword, minutes) in timeIndicatorKeywords {
            if lowerDescription.contains(keyword) {
                // Versuche Zahl vor dem Zeitkeyword zu finden
                if let number = extractNumber(from: lowerDescription) {
                    return TimeInterval(number * minutes)
                }
                return TimeInterval(minutes)
            }
        }
        
        // Keyword-basierte Schätzung
        let timeEstimates: [String: Int] = [
            "kurz": 15, "schnell": 30, "kurzfristig": 60,
            "mittel": 120, "normal": 180, "länger": 240,
            "komplex": 480, "aufwändig": 360, "einfach": 30
        ]
        
        for (keyword, minutes) in timeEstimates {
            if lowerDescription.contains(keyword) {
                return TimeInterval(minutes * 60)
            }
        }
        
        // Fallback: Basierend auf Kategorie
        let category = categorizeTask(taskDescription, tokens: tokens)
        let categoryTimeEstimates: [TodoTask.TaskCategory: Int] = [
            .urgent: 30, .meeting: 60, .work: 120, .personal: 90,
            .project: 240, .health: 45, .shopping: 30, .home: 60, .other: 60
        ]
        
        let estimatedMinutes = categoryTimeEstimates[category] ?? 60
        return TimeInterval(estimatedMinutes * 60)
    }
    
    private func extractNumber(from text: String) -> Int? {
        let pattern = #"(\d+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        if let match = matches?.first, let range = Range(match.range(at: 1), in: text) {
            return Int(text[range])
        }
        
        return nil
    }
    
    private func processTask(_ taskDescription: String, 
                           urgencyIndicators: [UrgencyIndicator], 
                           context: AnalysisContext) async throws -> TodoTask {
        
        let tokens = tokenizeContent(taskDescription)
        let category = categorizeTask(taskDescription, tokens: tokens)
        let urgencyScore = calculateUrgencyScore(taskDescription, urgencyIndicators: urgencyIndicators)
        let priority = determinePriority(urgencyScore, category: category)
        let estimatedTime = estimateTime(taskDescription, tokens: tokens)
        
        // Deadline Inference
        let deadlines = extractDeadlines(tokens)
        let deadline = deadlines.first?.inferredDate
        
        // Completion Probability Assessment
        let completionProbability = calculateTaskCompletionProbability(
            taskDescription, 
            urgencyScore: urgencyScore, 
            estimatedTime: estimatedTime
        )
        
        // Tag Extraction
        let tags = extractTags(tokens)
        
        // Recurring Pattern Detection
        let (isRecurring, pattern) = detectRecurringPattern(taskDescription, tokens: tokens)
        
        return TodoTask(
            title: taskDescription,
            description: taskDescription,
            category: category,
            priority: priority,
            urgencyScore: urgencyScore,
            estimatedTime: estimatedTime,
            deadline: deadline,
            isRecurring: isRecurring,
            recurrencePattern: pattern,
            dependencies: [],
            participants: [],
            completionProbability: completionProbability,
            tags: tags,
            sourceContent: taskDescription,
            createdAt: Date(),
            updatedAt: Date(),
            isCompleted: false
        )
    }
    
    private func calculateTaskCompletionProbability(_ taskDescription: String, 
                                                  urgencyScore: Double, 
                                                  estimatedTime: TimeInterval) -> Double {
        // Faktoren für Completion Probability:
        // - Urgency Score (hohe Dringlichkeit = höhere Completion Probability)
        // - Task Complexity (kürzere Tasks haben höhere Completion Probability)
        // - Clarity (konkrete Tasks haben höhere Probability)
        
        let urgencyFactor = urgencyScore * 0.4
        let complexityFactor: Double
        
        // Komplexität basierend auf Zeit und Wörtern
        let wordCount = taskDescription.split(whereSeparator: { !$0.isLetter }).count
        if wordCount <= 5 {
            complexityFactor = 0.9 // Sehr konkrete, kurze Tasks
        } else if wordCount <= 15 {
            complexityFactor = 0.7 // Mittlere Komplexität
        } else {
            complexityFactor = 0.5 // Komplexe Tasks
        }
        
        // Zeitfaktor (kürzere Tasks = höhere Wahrscheinlichkeit)
        let timeFactor: Double
        let hours = estimatedTime / 3600
        if hours <= 0.5 {
            timeFactor = 0.9
        } else if hours <= 2 {
            timeFactor = 0.8
        } else if hours <= 4 {
            timeFactor = 0.6
        } else {
            timeFactor = 0.4
        }
        
        let baseProbability = (urgencyFactor + (complexityFactor * 0.4) + (timeFactor * 0.2))
        return min(0.95, max(0.1, baseProbability))
    }
    
    private func extractTags(_ tokens: [String]) -> [String] {
        var tags: [String] = []
        
        // Hashtag-ähnliche Patterns
        for token in tokens {
            if token.hasPrefix("#") {
                tags.append(String(token.dropFirst()))
            }
        }
        
        // Keywords als Tags
        let relevantKeywords = tokens.filter { token in
            token.count > 3 && 
            !isCommonWord(token.lowercased()) && 
            token.first?.isUppercase == false
        }
        
        tags.append(contentsOf: relevantKeywords.prefix(5))
        
        return Array(Set(tags))
    }
    
    private func detectRecurringPattern(_ taskDescription: String, 
                                      tokens: [String]) -> (Bool, TodoTask.RecurrencePattern?) {
        
        let lowerDescription = taskDescription.lowercased()
        
        // Explizite Wiederholungsangaben
        if lowerDescription.contains("täglich") || lowerDescription.contains("jeden tag") {
            return (true, .daily)
        } else if lowerDescription.contains("wöchentlich") || lowerDescription.contains("jede woche") {
            return (true, .weekly)
        } else if lowerDescription.contains("monatlich") || lowerDescription.contains("jeden monat") {
            return (true, .monthly)
        } else if lowerDescription.contains("jährlich") || lowerDescription.contains("jedes jahr") {
            return (true, .yearly)
        }
        
        // Zeit-basierte Patterns
        let timeWords = ["montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag", "sonntag"]
        if timeWords.contains(where: { lowerDescription.contains($0) }) {
            return (true, .weekly)
        }
        
        return (false, nil)
    }
    
    private func smartMergeTasks(_ tasks: [TodoTask]) -> [TodoTask] {
        var mergedTasks: [TodoTask] = []
        var processedIndices: Set<Int> = []
        
        for i in 0..<tasks.count {
            if processedIndices.contains(i) { continue }
            
            var currentTask = tasks[i]
            var similarTasks: [TodoTask] = []
            
            // Finde ähnliche Tasks
            for j in (i + 1)..<tasks.count {
                if processedIndices.contains(j) { continue }
                
                if tasks[i].title.lowercased().contains(tasks[j].title.lowercased()) ||
                   tasks[j].title.lowercased().contains(tasks[i].title.lowercased()) ||
                   calculateSimilarity(tasks[i].title, tasks[j].title) > 0.7 {
                    similarTasks.append(tasks[j])
                    processedIndices.insert(j)
                }
            }
            
            // Merge ähnliche Tasks
            if !similarTasks.isEmpty {
                currentTask = mergeTaskWithSimilarities(currentTask, similarTasks)
            }
            
            mergedTasks.append(currentTask)
        }
        
        return mergedTasks
    }
    
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let set1 = Set(str1.lowercased().split(whereSeparator: { !$0.isLetter }))
        let set2 = Set(str2.lowercased().split(whereSeparator: { !$0.isLetter }))
        
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func mergeTaskWithSimilarities(_ mainTask: TodoTask, _ similarTasks: [TodoTask]) -> TodoTask {
        var mergedTask = mainTask
        
        // Sammle alle Teilnehmer
        var allParticipants = mainTask.participants
        for task in similarTasks {
            allParticipants.append(contentsOf: task.participants)
        }
        mergedTask.participants = Array(Set(allParticipants))
        
        // Sammle alle Tags
        var allTags = mainTask.tags
        for task in similarTasks {
            allTags.append(contentsOf: task.tags)
        }
        mergedTask.tags = Array(Set(allTags))
        
        // Verwende höchste Urgency und beste Completion Probability
        mergedTask.urgencyScore = similarTasks.map { $0.urgencyScore }.max() ?? mainTask.urgencyScore
        mergedTask.completionProbability = similarTasks.map { $0.completionProbability }.max() ?? mainTask.completionProbability
        
        return mergedTask
    }
    
    private func detectDependencies(_ tasks: [TodoTask]) -> [TaskDependency] {
        var dependencies: [TaskDependency] = []
        
        // Vereinfachte Dependency-Erkennung basierend auf Keywords
        for task in tasks {
            let lowerTitle = task.title.lowercased()
            
            if lowerTitle.contains("nach") || lowerTitle.contains("dann") || lowerTitle.contains("anschließend") {
                // Finde vorausgehende Tasks
                for otherTask in tasks where otherTask.id != task.id {
                    if isPredecessor(otherTask.title, of: task.title) {
                        dependencies.append(TaskDependency(
                            taskId: task.id,
                            dependsOnTaskId: otherTask.id,
                            type: .mustComplete
                        ))
                    }
                }
            }
        }
        
        return dependencies
    }
    
    private func isPredecessor(_ predecessorTitle: String, of taskTitle: String) -> Bool {
        // Vereinfachte Logik für Voraus-Geling-Prüfung
        let preLower = predecessorTitle.lowercased()
        let taskLower = taskTitle.lowercased()
        
        // Gleiche Kategorie und ähnliche Keywords deuten auf Abhängigkeit hin
        return calculateSimilarity(preLower, taskLower) > 0.5
    }
    
    private func recognizePatterns(_ tasks: [TodoTask]) -> [TaskPattern] {
        var patterns: [TaskPattern] = []
        
        // Recurring Pattern Analysis
        let recurringTasks = tasks.filter { $0.isRecurring }
        if !recurringTasks.isEmpty {
            let patternTypes = Dictionary(grouping: recurringTasks, by: { $0.recurrencePattern })
            for (patternType, tasksWithPattern) in patternTypes {
                if let patternType = patternType {
                    let frequency = Double(tasksWithPattern.count) / Double(tasks.count)
                    let taskIds = tasksWithPattern.map { $0.id }
                    
                    patterns.append(TaskPattern(
                        patternType: .recurring,
                        frequency: frequency,
                        description: "\(patternType.rawValue) tasks detected",
                        relatedTasks: taskIds
                    ))
                }
            }
        }
        
        // Project Phase Pattern Analysis
        let projectTasks = tasks.filter { $0.category == .project }
        if projectTasks.count > 1 {
            patterns.append(TaskPattern(
                patternType: .projectPhase,
                frequency: Double(projectTasks.count) / Double(tasks.count),
                description: "Project workflow detected",
                relatedTasks: projectTasks.map { $0.id }
            ))
        }
        
        return patterns
    }
    
    private func estimateTaskTimes(_ tasks: [TodoTask]) -> [TimeEstimate] {
        return tasks.map { task in
            let estimatedMinutes = Int(task.estimatedTime / 60)
            let confidence = calculateTimeEstimationConfidence(task)
            
            return TimeEstimate(
                taskId: task.id,
                estimatedMinutes: estimatedMinutes,
                confidence: confidence,
                basis: "AI-based estimation using task complexity and category"
            )
        }
    }
    
    private func calculateTimeEstimationConfidence(_ task: TodoTask) -> Double {
        var confidence = 0.5 // Base confidence
        
        // Higher confidence for tasks with clear time indicators
        if task.title.lowercased().contains("stunde") || 
           task.title.lowercased().contains("minute") ||
           task.title.lowercased().contains("tag") {
            confidence += 0.3
        }
        
        // Lower confidence for very complex or vague tasks
        let wordCount = task.title.split(whereSeparator: { !$0.isLetter }).count
        if wordCount > 15 {
            confidence -= 0.2
        }
        
        // Category-based adjustment
        switch task.category {
        case .meeting:
            confidence += 0.2 // Meetings have predictable duration
        case .urgent:
            confidence -= 0.1 // Urgent tasks might need more time
        case .project:
            confidence -= 0.15 // Projects are often complex
        default:
            break
        }
        
        return max(0.1, min(0.95, confidence))
    }
    
    private func calculateCompletionProbability(_ tasks: [TodoTask]) -> [TodoTask] {
        return tasks.map { task in
            var updatedTask = task
            updatedTask.completionProbability = calculateTaskCompletionProbability(
                task.title,
                urgencyScore: task.urgencyScore,
                estimatedTime: task.estimatedTime
            )
            return updatedTask
        }
    }
    
    private func addDependenciesToTasks(_ tasks: [TodoTask], dependencies: [TaskDependency]) -> [TodoTask] {
        var taskDict = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        
        for dependency in dependencies {
            if var dependentTask = taskDict[dependency.taskId] {
                dependentTask.dependencies.append(dependency.dependsOnTaskId)
                taskDict[dependency.taskId] = dependentTask
            }
        }
        
        return Array(taskDict.values)
    }
}

// MARK: - Analysis Context

struct AnalysisContext {
    let userPreferences: UserPreferences?
    let historicalData: [TodoTask]?
    let calendarEvents: [CalendarEvent]?
    let workingHours: WorkingHours?
    
    init(userPreferences: UserPreferences? = nil, 
         historicalData: [TodoTask]? = nil, 
         calendarEvents: [CalendarEvent]? = nil,
         workingHours: WorkingHours? = nil) {
        self.userPreferences = userPreferences
        self.historicalData = historicalData
        self.calendarEvents = calendarEvents
        self.workingHours = workingHours
    }
}

struct UserPreferences {
    let preferredCategories: [TodoTask.TaskCategory]
    let workingHours: WorkingHours
    let delegationRules: [DelegationRule]
    let timePreferences: TimePreferences
}

struct WorkingHours {
    let startHour: Int
    let endHour: Int
    let workingDays: [Int] // 1 = Monday, 7 = Sunday
    
    func isWorkingTime(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let weekday = calendar.component(.weekday, from: date)
        
        return workingDays.contains(weekday) && 
               hour >= startHour && 
               hour < endHour
    }
}

struct DelegationRule {
    let category: TodoTask.TaskCategory
    let participants: [String]
    let conditions: [String]
}

struct TimePreferences {
    let preferredTaskDuration: TimeInterval
    let breakIntervals: [TimeInterval]
    let focusTimeBlocks: [TimeInterval]
}

struct CalendarEvent {
    let title: String
    let startDate: Date
    let endDate: Date
    let isBusy: Bool
}

// MARK: - Calendar Integration

class CalendarIntegration {
    
    private let calendar = Calendar.current
    
    func integrateTodosWithCalendar(_ todos: [TodoTask]) async throws {
        // Placeholder für Calendar-Integration
        print("📅 Integriere \(todos.count) Todos mit Calendar...")
        
        for task in todos {
            if let deadline = task.deadline {
                try await createCalendarEvent(for: task, at: deadline)
            }
        }
    }
    
    private func createCalendarEvent(for task: TodoTask, at deadline: Date) async throws {
        // Hier würde die tatsächliche Calendar-Erstellung stattfinden
        // z.B. mit EventKit in iOS
        print("📅 Erstelle Calendar-Event für: \(task.title) am \(deadline)")
    }
    
    func suggestOptimalTaskSlots(_ todos: [TodoTask], dateRange: DateInterval) async throws -> [TaskSlotSuggestion] {
        var suggestions: [TaskSlotSuggestion] = []
        
        for task in todos {
            let optimalSlot = try await findOptimalTimeSlot(for: task, in: dateRange)
            suggestions.append(optimalSlot)
        }
        
        return suggestions
    }
    
    private func findOptimalTimeSlot(for task: TodoTask, in dateRange: DateInterval) async throws -> TaskSlotSuggestion {
        // KI-basierte Zeitplanung
        let duration = task.estimatedTime
        let urgencyWeight = task.urgencyScore
        let priorityWeight = getPriorityWeight(task.priority)
        
        // Vereinfachte Slot-Findung
        let slotStart = dateRange.start
        let slotEnd = dateRange.end
        
        return TaskSlotSuggestion(
            taskId: task.id,
            recommendedStart: slotStart,
            recommendedEnd: slotStart.addingTimeInterval(duration),
            confidence: (urgencyWeight + priorityWeight) / 2,
            reasoning: "AI-optimized scheduling based on urgency and priority"
        )
    }
    
    private func getPriorityWeight(_ priority: TodoTask.TaskPriority) -> Double {
        switch priority {
        case .critical: return 1.0
        case .high: return 0.8
        case .medium: return 0.6
        case .low: return 0.3
        }
    }
}

struct TaskSlotSuggestion {
    let taskId: UUID
    let recommendedStart: Date
    let recommendedEnd: Date
    let confidence: Double
    let reasoning: String
}

// MARK: - Export/Import Functionality

class TodoExportManager {
    
    func exportTodos(_ todos: [TodoTask], format: ExportFormat) throws -> Data {
        switch format {
        case .json:
            return try JSONEncoder().encode(todos)
        case .csv:
            return csvData(from: todos)
        case .ical:
            return icalData(from: todos)
        case .markdown:
            return markdownData(from: todos).data(using: .utf8) ?? Data()
        }
    }
    
    private func csvData(from todos: [TodoTask]) -> Data {
        var csv = "Titel,Priorität,Kategorie,Urgency,Zeit-Schätzung,Fälligkeitsdatum\n"
        
        for task in todos {
            let deadline = task.deadline?.description ?? ""
            csv += "\"\(task.title)\",\(task.priority.rawValue),\(task.category.rawValue),\(task.urgencyScore),\(task.estimatedTime),\(deadline)\n"
        }
        
        return csv.data(using: .utf8) ?? Data()
    }
    
    private func icalData(from todos: [TodoTask]) -> Data {
        var ical = "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//TodoGenerator//TodoGenerator//EN\n"
        
        for task in todos {
            ical += "BEGIN:VTODO\n"
            ical += "UID:\(task.id.uuidString)\n"
            ical += "SUMMARY:\(task.title)\n"
            ical += "DESCRIPTION:\(task.description)\n"
            ical += "PRIORITY:\(getICalPriority(task.priority))\n"
            
            if let deadline = task.deadline {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
                ical += "DUE:\(dateFormatter.string(from: deadline))\n"
            }
            
            ical += "STATUS:\(task.isCompleted ? "COMPLETED" : "NEEDS-ACTION")\n"
            ical += "END:VTODO\n"
        }
        
        ical += "END:VCALENDAR"
        return ical.data(using: .utf8) ?? Data()
    }
    
    private func getICalPriority(_ priority: TodoTask.TaskPriority) -> String {
        switch priority {
        case .critical: return "1"
        case .high: return "5"
        case .medium: return "7"
        case .low: return "9"
        }
    }
    
    private func markdownData(from todos: [TodoTask]) -> String {
        var markdown = "# Todo-Liste\n\n"
        
        let groupedByPriority = Dictionary(grouping: todos) { $0.priority }
        let sortedPriorities: [TodoTask.TaskPriority] = [.critical, .high, .medium, .low]
        
        for priority in sortedPriorities {
            guard let tasks = groupedByPriority[priority] else { continue }
            
            markdown += "## \(priority.rawValue.uppercased()) Priorität\n\n"
            
            for task in tasks {
                let checkbox = task.isCompleted ? "- [x]" : "- [ ]"
                let urgency = String(format: "%.2f", task.urgencyScore)
                let estimatedTime = formatTimeInterval(task.estimatedTime)
                
                markdown += "\(checkbox) **\(task.title)**\n"
                markdown += "   - Kategorie: \(task.category.rawValue)\n"
                markdown += "   - Urgency Score: \(urgency)\n"
                markdown += "   - Geschätzte Zeit: \(estimatedTime)\n"
                
                if let deadline = task.deadline {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    markdown += "   - Fällig: \(dateFormatter.string(from: deadline))\n"
                }
                
                if !task.tags.isEmpty {
                    markdown += "   - Tags: \(task.tags.joined(separator: ", "))\n"
                }
                
                markdown += "\n"
            }
        }
        
        return markdown
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)min"
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case json = "json"
    case csv = "csv"
    case ical = "ical"
    case markdown = "markdown"
}