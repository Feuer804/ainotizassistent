import SwiftUI

// MARK: - Todo List View

struct TodoListView: View {
    @StateObject private var todoViewModel = TodoViewModel()
    @State private var showingGenerator = false
    @State private var showingSettings = false
    @State private var selectedFilter: TodoFilter = .all
    @State private var showingExportOptions = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                AnimatedBackground()
                    .ignoresSafeArea()
                
                VStack {
                    // Header
                    HeaderView(showingSettings: $showingSettings, showingExportOptions: $showingExportOptions)
                    
                    // Filter and Search
                    FilterAndSearchView(
                        selectedFilter: $selectedFilter,
                        searchText: $searchText
                    )
                    
                    // Todo List
                    TodoList(
                        todos: filteredTodos,
                        onToggleComplete: todoViewModel.toggleCompletion,
                        onEdit: todoViewModel.editTodo,
                        onDelete: todoViewModel.deleteTodo
                    )
                    
                    // Add Todo Button
                    AddTodoButton(action: { showingGenerator = true })
                }
                .padding()
            }
            .navigationTitle("Intelligente Todos")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingGenerator) {
                TodoGeneratorSheet(
                    onGenerated: { tasks in
                        todoViewModel.addTodos(tasks)
                        showingGenerator = false
                    }
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(onExport: { format in
                    exportTodos(format: format)
                })
            }
        }
    }
    
    // Computed property for filtered todos
    private var filteredTodos: [TodoTask] {
        var filtered = todoViewModel.todos
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { todo in
                todo.title.localizedCaseInsensitiveContains(searchText) ||
                todo.description.localizedCaseInsensitiveContains(searchText) ||
                todo.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .work:
            filtered = filtered.filter { $0.category == .work }
        case .personal:
            filtered = filtered.filter { $0.category == .personal }
        case .urgent:
            filtered = filtered.filter { $0.priority == .critical || $0.urgencyScore > 0.8 }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        case .upcoming:
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Sort by priority and urgency
        return filtered.sorted { todo1, todo2 in
            if todo1.priority != todo2.priority {
                return priorityValue(todo1.priority) > priorityValue(todo2.priority)
            }
            return todo1.urgencyScore > todo2.urgencyScore
        }
    }
    
    private func priorityValue(_ priority: TodoTask.TaskPriority) -> Int {
        switch priority {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    private func exportTodos(format: ExportFormat) {
        do {
            let exportManager = TodoExportManager()
            let data = try exportManager.exportTodos(filteredTodos, format: format)
            
            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("todos.\(format.rawValue)")
            try data.write(to: tempURL)
            
            // Share the file
            let activityController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityController, animated: true)
            }
        } catch {
            print("Export failed: \(error)")
        }
    }
}

// MARK: - Animated Background

struct AnimatedBackground: View {
    @State private var gradientOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3),
                    Color.pink.opacity(0.3),
                    Color.cyan.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 100)
            
            // Animated Shapes
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 300, height: 300)
                .offset(x: gradientOffset * 2, y: gradientOffset * -1)
                .blur(radius: 80)
            
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 200, height: 200)
                .offset(x: gradientOffset * -1.5, y: gradientOffset * 1.2)
                .blur(radius: 60)
            
            RoundedRectangle(cornerRadius: 50)
                .fill(Color.white.opacity(0.05))
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(45))
                .offset(x: gradientOffset * 0.8, y: gradientOffset * 0.5)
                .blur(radius: 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                gradientOffset = 100
            }
        }
    }
}

// MARK: - Header View

struct HeaderView: View {
    @Binding var showingSettings: Bool
    @Binding var showingExportOptions: Bool
    @State private var showingStatistics = false
    
    var body: some View {
        HStack {
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Intelligente")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Todo-Liste")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: { showingStatistics = true }) {
                    Image(systemName: "chart.bar")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                
                Button(action: { showingExportOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(.bottom, 20)
        .sheet(isPresented: $showingStatistics) {
            StatisticsView()
        }
    }
}

// MARK: - Filter and Search View

struct FilterAndSearchView: View {
    @Binding var selectedFilter: TodoFilter
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.7))
                
                TextField("Todos durchsuchen...", text: $searchText)
                    .foregroundStyle(.white)
                    .tint(.white)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TodoFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.title,
                            isSelected: selectedFilter == filter,
                            action: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? 
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                    .ultraThinMaterial,
                    in: Capsule()
                )
                .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1), 
                       radius: isSelected ? 8 : 4, 
                       x: 0, 
                       y: isSelected ? 4 : 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Todo List

struct TodoList: View {
    let todos: [TodoTask]
    let onToggleComplete: (UUID) -> Void
    let onEdit: (TodoTask) -> Void
    let onDelete: (UUID) -> Void
    
    var body: some View {
        List {
            ForEach(todos) { todo in
                TodoRowView(
                    todo: todo,
                    onToggleComplete: onToggleComplete,
                    onEdit: onEdit,
                    onDelete: onDelete
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.horizontal)
            }
        }
        .listStyle(.plain)
        .background(Color.clear)
    }
}

// MARK: - Todo Row View

struct TodoRowView: View {
    let todo: TodoTask
    let onToggleComplete: (UUID) -> Void
    let onEdit: (TodoTask) -> Void
    let onDelete: (UUID) -> Void
    @State private var showingActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main Todo Card
            HStack(spacing: 16) {
                // Completion Toggle
                Button(action: { onToggleComplete(todo.id) }) {
                    ZStack {
                        Circle()
                            .fill(todo.isCompleted ? 
                                  LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing) :
                                  .ultraThinMaterial)
                            .frame(width: 32, height: 32)
                            .shadow(color: todo.isCompleted ? .green.opacity(0.3) : .black.opacity(0.1), 
                                   radius: 6, x: 0, y: 3)
                        
                        if todo.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                
                // Todo Content
                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    HStack {
                        Text(todo.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Urgency Indicator
                        UrgencyIndicator(score: todo.urgencyScore)
                    }
                    
                    // Metadata Row
                    HStack(spacing: 12) {
                        // Category Badge
                        CategoryBadge(category: todo.category)
                        
                        // Priority Badge
                        PriorityBadge(priority: todo.priority)
                        
                        // Time Estimate
                        TimeEstimateView(estimatedTime: todo.estimatedTime)
                        
                        Spacer()
                        
                        // Due Date
                        if let deadline = todo.deadline {
                            DueDateView(deadline: deadline)
                        }
                    }
                    
                    // Tags
                    if !todo.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(todo.tags, id: \.self) { tag in
                                    TagView(tag: tag)
                                }
                            }
                        }
                    }
                    
                    // Progress Bar for Completion Probability
                    if !todo.isCompleted && todo.completionProbability < 0.8 {
                        CompletionProbabilityBar(probability: todo.completionProbability)
                    }
                }
                
                // Actions Menu
                Menu {
                    Button("Bearbeiten", action: { onEdit(todo) })
                    Button("Löschen", role: .destructive, action: { onDelete(todo.id) })
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Dependencies Preview
            if !todo.dependencies.isEmpty {
                DependenciesPreview(dependencies: todo.dependencies)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Urgency Indicator

struct UrgencyIndicator: View {
    let score: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < Int(score * 5) ? urgencyColor : .white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private var urgencyColor: Color {
        if score > 0.8 {
            return .red
        } else if score > 0.6 {
            return .orange
        } else if score > 0.4 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: TodoTask.TaskCategory
    
    var body: some View {
        Text(category.rawValue.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor.opacity(0.3), in: Capsule())
    }
    
    private var categoryColor: Color {
        switch category {
        case .work: return .blue
        case .personal: return .green
        case .urgent: return .red
        case .meeting: return .purple
        case .project: return .orange
        case .health: return .pink
        case .shopping: return .yellow
        case .home: return .brown
        case .other: return .gray
        }
    }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
    let priority: TodoTask.TaskPriority
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index < priorityValue(priority) ? priorityColor : .white.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    private func priorityValue(_ priority: TodoTask.TaskPriority) -> Int {
        switch priority {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

// MARK: - Time Estimate View

struct TimeEstimateView: View {
    let estimatedTime: TimeInterval
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
            Text(formatTime(estimatedTime))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - Due Date View

struct DueDateView: View {
    let deadline: Date
    
    var body: some View {
        let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.caption)
            Text(daysUntilDeadline == 0 ? "Heute" : 
                 daysUntilDeadline == 1 ? "Morgen" : 
                 daysUntilDeadline < 0 ? "\(abs(daysUntilDeadline)) Tage überfällig" :
                 "In \(daysUntilDeadline) Tagen")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(deadlineColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(deadlineColor.opacity(0.2), in: Capsule())
    }
    
    private var deadlineColor: Color {
        let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        
        if daysUntilDeadline < 0 {
            return .red
        } else if daysUntilDeadline == 0 {
            return .orange
        } else if daysUntilDeadline <= 3 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Tag View

struct TagView: View {
    let tag: String
    
    var body: some View {
        Text("#\(tag)")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Completion Probability Bar

struct CompletionProbabilityBar: View {
    let probability: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Completion-Wahrscheinlichkeit")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(probability * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(probabilityColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(probabilityColor)
                        .frame(width: geometry.size.width * probability, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var probabilityColor: Color {
        if probability > 0.7 {
            return .green
        } else if probability > 0.5 {
            return .yellow
        } else {
            return .orange
        }
    }
}

// MARK: - Dependencies Preview

struct DependenciesPreview: View {
    let dependencies: [UUID]
    
    var body: some View {
        HStack {
            Image(systemName: "link")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Text("Wartet auf \(dependencies.count) Abhängigkeiten")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Add Todo Button

struct AddTodoButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus")
                Text("Intelligente Todos generieren")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                , in: Capsule()
            )
            .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 8)
        }
        .padding(.top, 20)
    }
}

// MARK: - Filter Enum

enum TodoFilter: CaseIterable {
    case all
    case work
    case personal
    case urgent
    case completed
    case upcoming
    
    var title: String {
        switch self {
        case .all: return "Alle"
        case .work: return "Arbeit"
        case .personal: return "Persönlich"
        case .urgent: return "Dringend"
        case .completed: return "Erledigt"
        case .upcoming: return "Anstehend"
        }
    }
}

// MARK: - Todo Generator Sheet

struct TodoGeneratorSheet: View {
    @State private var contentText = ""
    @State private var isGenerating = false
    @State private var generatedTodos: [TodoTask] = []
    @State private var showingPreview = false
    
    let onGenerated: ([TodoTask]) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    
                    Text("KI-gestützte Todo-Generierung")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Beschreiben Sie Ihre Aufgaben und lassen Sie die KI intelligente Todos generieren")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Content Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ihre Beschreibung")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    TextEditor(text: $contentText)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue.opacity(0.2), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)
                    
                    if !contentText.isEmpty {
                        Text("\(contentText.split(whereSeparator: { !$0.isLetter }).count) Wörter")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Generate Button
                Button(action: generateTodos) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isGenerating ? "Generiere..." : "Todos generieren")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        contentText.isEmpty ? 
                        LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .shadow(color: contentText.isEmpty ? .clear : .blue.opacity(0.3), 
                           radius: 12, x: 0, y: 8)
                }
                .disabled(contentText.isEmpty || isGenerating)
                .padding(.bottom, 20)
            }
            .navigationTitle("Todo-Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        if !generatedTodos.isEmpty {
                            onGenerated(generatedTodos)
                        }
                    }
                    .disabled(generatedTodos.isEmpty)
                }
            }
            .sheet(isPresented: $showingPreview) {
                GeneratedTodosPreview(todos: generatedTodos) { updatedTodos in
                    generatedTodos = updatedTodos
                }
            }
        }
    }
    
    private func generateTodos() {
        guard !contentText.isEmpty else { return }
        
        isGenerating = true
        
        // Simulate AI processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            Task {
                do {
                    let todoGenerator = TodoGenerator()
                    let analysis = try await todoGenerator.generateTodos(from: contentText)
                    generatedTodos = analysis.extractedTasks
                    showingPreview = true
                } catch {
                    print("Todo generation failed: \(error)")
                }
                isGenerating = false
            }
        }
    }
}

// MARK: - Generated Todos Preview

struct GeneratedTodosPreview: View {
    let todos: [TodoTask]
    let onUpdate: ([TodoTask]) -> Void
    @State private var updatedTodos: [TodoTask]
    @Environment(\.dismiss) private var dismiss
    
    init(todos: [TodoTask], onUpdate: @escaping ([TodoTask]) -> Void) {
        self.todos = todos
        self.onUpdate = onUpdate
        _updatedTodos = State(initialValue: todos)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(updatedTodos) { todo in
                    TodoEditRowView(todo: $updatedTodos[getIndex(for: todo.id)])
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle("Generierte Todos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zurück") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Übernehmen") {
                        onUpdate(updatedTodos)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getIndex(for id: UUID) -> Int {
        updatedTodos.firstIndex(where: { $0.id == id }) ?? 0
    }
}

// MARK: - Todo Edit Row View

struct TodoEditRowView: View {
    @Binding var todo: TodoTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Titel", text: $todo.title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            TextEditor(text: $todo.description)
                .frame(height: 60)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.primary)
            
            HStack {
                Picker("Kategorie", selection: $todo.category) {
                    ForEach(TodoTask.TaskCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Priorität", selection: $todo.priority) {
                    ForEach(TodoTask.TaskPriority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Settings View

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Darstellung") {
                    HStack {
                        Image(systemName: "paintbrush")
                        VStack(alignment: .leading) {
                            Text("Design")
                            Text("Moderne Glassmorphism-Optik")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Aktiv")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                Section("KI-Einstellungen") {
                    HStack {
                        Image(systemName: "brain")
                        VStack(alignment: .leading) {
                            Text("AI-Priorität")
                            Text("Automatische Urgency-Bewertung")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                    
                    HStack {
                        Image(systemName: "link")
                        VStack(alignment: .leading) {
                            Text("Abhängigkeits-Erkennung")
                            Text("Automatische Task-Dependencies")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                }
                
                Section("Export") {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        VStack(alignment: .leading) {
                            Text("Standard-Format")
                            Text("JSON, CSV, iCal, Markdown")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("JSON")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Export Options View

struct ExportOptionsView: View {
    let onExport: (ExportFormat) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Format wählen") {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            onExport(format)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(formatTitle(format))
                                        .foregroundStyle(.primary)
                                    Text(formatDescription(format))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTitle(_ format: ExportFormat) -> String {
        switch format {
        case .json: return "JSON"
        case .csv: return "CSV (Excel)"
        case .ical: return "iCal"
        case .markdown: return "Markdown"
        }
    }
    
    private func formatDescription(_ format: ExportFormat) -> String {
        switch format {
        case .json: return "Strukturierte Daten für Apps"
        case .csv: return "Tabellenkalkulation-kompatibel"
        case .ical: return "Calendar-Apps (Apple, Google)"
        case .markdown: return "Dokumentation & Notizen"
        }
    }
}

// MARK: - Statistics View

struct StatisticsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(title: "Gesamt", value: "24", icon: "list.bullet", color: .blue)
                        StatCard(title: "Erledigt", value: "18", icon: "checkmark.circle", color: .green)
                        StatCard(title: "Überfällig", value: "3", icon: "exclamationmark.triangle", color: .red)
                        StatCard(title: "Erfolgsrate", value: "87%", icon: "chart.bar", color: .purple)
                    }
                    
                    // Charts would go here
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kategorien-Verteilung")
                            .font(.headline)
                        CategoryDistributionChart()
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Produktivitäts-Trends")
                            .font(.headline)
                        ProductivityTrendChart()
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Statistiken")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct CategoryDistributionChart: View {
    var body: some View {
        // Placeholder for actual chart implementation
        Text("Chart Placeholder")
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct ProductivityTrendChart: View {
    var body: some View {
        // Placeholder for actual chart implementation
        Text("Trend Chart Placeholder")
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Todo ViewModel

class TodoViewModel: ObservableObject {
    @Published var todos: [TodoTask] = []
    
    func addTodos(_ newTodos: [TodoTask]) {
        todos.append(contentsOf: newTodos)
    }
    
    func toggleCompletion(_ id: UUID) {
        if let index = todos.firstIndex(where: { $0.id == id }) {
            todos[index].isCompleted.toggle()
            todos[index].updatedAt = Date()
        }
    }
    
    func editTodo(_ todo: TodoTask) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
            todos[index].updatedAt = Date()
        }
    }
    
    func deleteTodo(_ id: UUID) {
        todos.removeAll { $0.id == id }
    }
}

// MARK: - Preview

struct TodoListView_Previews: PreviewProvider {
    static var previews: some View {
        TodoListView()
    }
}