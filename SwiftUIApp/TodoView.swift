import SwiftUI

struct TodoView: View {
    @State private var todoItems: [TodoItem] = []
    @State private var newTodoText = ""
    @State private var showingAddTodo = false
    @State private var selectedPriority: TodoPriority = .mittel
    @State private var selectedFilter: TodoFilter = .alle
    @State private var searchText = ""
    
    let priorities: [TodoPriority] = [.niedrig, .mittel, .hoch]
    let filters: [TodoFilter] = [.alle, .offen, .erledigt, .heute]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.4),
                    Color.pink.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("To-Do Liste")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(filteredTodos.count) von \(todoItems.count)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.15))
                                .cornerRadius(12)
                        }
                        
                        Text("Organisiere deine Aufgaben")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top)
                    
                    // Suchfeld
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("Aufgaben durchsuchen...", text: $searchText)
                            .textFieldStyle(SearchTextFieldStyle())
                            .autocorrectionDisabled()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Filter Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                FilterButton(
                                    filter: filter,
                                    isSelected: selectedFilter == filter
                                ) {
                                    withAnimation(.spring()) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Statistiken
                    if !todoItems.isEmpty {
                        TodoStatisticsView(todoItems: todoItems)
                    }
                    
                    // Add Todo Button
                    Button(action: { showingAddTodo = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Neue Aufgabe")
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    
                    // Todo Items
                    if filteredTodos.isEmpty {
                        EmptyStateView(
                            icon: "checkmark.circle",
                            title: "Keine Aufgaben",
                            subtitle: todoItems.isEmpty ? "Erstelle deine erste Aufgabe" : "Keine Aufgaben für den gewählten Filter"
                        )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredTodos) { todo in
                                TodoItemView(
                                    todo: todo,
                                    onToggle: toggleTodo,
                                    onDelete: deleteTodo,
                                    onEdit: editTodo
                                )
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingAddTodo) {
            AddTodoView(
                isPresented: $showingAddTodo,
                onAdd: addTodo
            )
        }
    }
    
    // Filtered todos basierend auf Suchtext und Filter
    var filteredTodos: [TodoItem] {
        var filtered = todoItems
        
        // Filter nach Suchtext
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter nach Kategorie
        switch selectedFilter {
        case .alle:
            break
        case .offen:
            filtered = filtered.filter { !$0.isCompleted }
        case .erledigt:
            filtered = filtered.filter { $0.isCompleted }
        case .heute:
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            filtered = filtered.filter { item in
                if let dueDate = item.dueDate {
                    return dueDate >= today && dueDate < tomorrow
                }
                return false
            }
        }
        
        return filtered
    }
    
    func addTodo(text: String, priority: TodoPriority, dueDate: Date?) {
        let newTodo = TodoItem(
            text: text,
            isCompleted: false,
            priority: priority,
            createdAt: Date(),
            dueDate: dueDate
        )
        todoItems.append(newTodo)
    }
    
    func toggleTodo(_ todo: TodoItem) {
        if let index = todoItems.firstIndex(where: { $0.id == todo.id }) {
            todoItems[index].isCompleted.toggle()
        }
    }
    
    func deleteTodo(_ todo: TodoItem) {
        todoItems.removeAll { $0.id == todo.id }
    }
    
    func editTodo(_ todo: TodoItem, newText: String) {
        if let index = todoItems.firstIndex(where: { $0.id == todo.id }) {
            todoItems[index].text = newText
        }
    }
}

// TodoItem Model
struct TodoItem: Identifiable {
    let id = UUID()
    var text: String
    var isCompleted: Bool
    var priority: TodoPriority
    var createdAt: Date
    var dueDate: Date?
}

// Todo Priority Enum
enum TodoPriority: String, CaseIterable {
    case niedrig = "Niedrig"
    case mittel = "Mittel"
    case hoch = "Hoch"
    
    var color: Color {
        switch self {
        case .niedrig: return Color.green.opacity(0.8)
        case .mittel: return Color.yellow.opacity(0.8)
        case .hoch: return Color.red.opacity(0.8)
        }
    }
    
    var icon: String {
        switch self {
        case .niedrig: return "arrow.down.circle.fill"
        case .mittel: return "minus.circle.fill"
        case .hoch: return "arrow.up.circle.fill"
        }
    }
}

// Todo Filter Enum
enum TodoFilter: String, CaseIterable {
    case alle = "Alle"
    case offen = "Offen"
    case erledigt = "Erledigt"
    case heute = "Heute"
}

// Filter Button Komponente
struct FilterButton: View {
    let filter: TodoFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filterIcon(filter))
                    .font(.system(size: 12))
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                .white.opacity(0.2) :
                .white.opacity(0.1)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .white.opacity(0.4) : .white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func filterIcon(_ filter: TodoFilter) -> String {
        switch filter {
        case .alle: return "list.bullet"
        case .offen: return "circle"
        case .erledigt: return "checkmark.circle.fill"
        case .heute: return "calendar.today"
        }
    }
}

// Suchfeld Style
struct SearchTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundColor(.white)
            .autocorrectionDisabled()
    }
}

// Todo Item View Komponente
struct TodoItemView: View {
    let todo: TodoItem
    let onToggle: (TodoItem) -> Void
    let onDelete: (TodoItem) -> Void
    let onEdit: (TodoItem, String) -> Void
    
    @State private var showingEditSheet = false
    @State private var editText = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            // Checkbox
            Button(action: { onToggle(todo) }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(todo.isCompleted ? .green.opacity(0.8) : .white.opacity(0.7))
                    .overlay(
                        todo.isCompleted ?
                        Circle()
                            .stroke(.green.opacity(0.3), lineWidth: 2)
                        : nil
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.text)
                    .font(.body)
                    .fontWeight(todo.isCompleted ? .regular : .semibold)
                    .foregroundColor(todo.isCompleted ? .white.opacity(0.6) : .white)
                    .strikethrough(todo.isCompleted)
                    .lineLimit(2)
                
                HStack {
                    // Priorität
                    HStack(spacing: 4) {
                        Image(systemName: todo.priority.icon)
                            .font(.caption2)
                            .foregroundColor(todo.priority.color)
                        
                        Text(todo.priority.rawValue)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Fälligkeitsdatum
                    if let dueDate = todo.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(dueDate, style: .date)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            
            Spacer()
            
            // Aktionen
            HStack(spacing: 8) {
                Button(action: {
                    editText = todo.text
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption)
                }
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.7))
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .alert("Aufgabe löschen?", isPresented: $showingDeleteAlert) {
            Button("Löschen", role: .destructive) {
                onDelete(todo)
            }
            Button("Abbrechen", role: .cancel) { }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTodoView(
                isPresented: $showingEditSheet,
                currentText: editText,
                onSave: { newText in
                    onEdit(todo, newText)
                }
            )
        }
    }
}

// Todo Statistiken View
struct TodoStatisticsView: View {
    let todoItems: [TodoItem]
    
    var completedCount: Int {
        todoItems.filter { $0.isCompleted }.count
    }
    
    var openCount: Int {
        todoItems.filter { !$0.isCompleted }.count
    }
    
    var completionRate: Double {
        guard !todoItems.isEmpty else { return 0 }
        return Double(completedCount) / Double(todoItems.count) * 100
    }
    
    var body: some View {
        HStack {
            // Erledigt
            VStack(spacing: 4) {
                Text("\(completedCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green.opacity(0.9))
                
                Text("Erledigt")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Offen
            VStack(spacing: 4) {
                Text("\(openCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange.opacity(0.9))
                
                Text("Offen")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Fortschritt
            VStack(spacing: 4) {
                Text("\(Int(completionRate))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue.opacity(0.9))
                
                Text("Fortschritt")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// Add Todo Sheet View
struct AddTodoView: View {
    @Binding var isPresented: Bool
    let onAdd: (String, TodoPriority, Date?) -> Void
    
    @State private var todoText = ""
    @State private var selectedPriority: TodoPriority = .mittel
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Text Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aufgabe")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Beschreibe deine Aufgabe...", text: $todoText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Priorität
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priorität")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach([TodoPriority.niedrig, .mittel, .hoch], id: \.self) { priority in
                            Button(action: {
                                selectedPriority = priority
                            }) {
                                HStack {
                                    Image(systemName: priority.icon)
                                        .foregroundColor(priority.color)
                                    Text(priority.rawValue)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedPriority == priority ? priority.color.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
                
                // Fälligkeitsdatum
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Fälligkeitsdatum setzen", isOn: $hasDueDate)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if hasDueDate {
                        DatePicker("Fällig am", selection: $dueDate, displayedComponents: [.date, .hour])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Neue Aufgabe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hinzufügen") {
                        onAdd(todoText, selectedPriority, hasDueDate ? dueDate : nil)
                        isPresented = false
                    }
                    .disabled(todoText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// Edit Todo Sheet View
struct EditTodoView: View {
    @Binding var isPresented: Bool
    let currentText: String
    let onSave: (String) -> Void
    
    @State private var editText: String
    
    init(isPresented: Binding<Bool>, currentText: String, onSave: @escaping (String) -> Void) {
        self._isPresented = isPresented
        self.currentText = currentText
        self._editText = State(initialValue: currentText)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Aufgabe bearbeiten...", text: $editText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
            .navigationTitle("Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        onSave(editText)
                        isPresented = false
                    }
                    .disabled(editText.trimmingCharacters(in: .whitespaces).isEmpty || editText == currentText)
                }
            }
        }
    }
}

#Preview {
    TodoView()
        .preferredColorScheme(.dark)
}