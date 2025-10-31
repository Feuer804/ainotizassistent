//
//  NotificationSettingsView.swift
//  StatusBarApp
//
//  Notifications and Privacy Settings
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @ObservedObject var coordinator: SettingsCoordinator
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var testNotificationInProgress = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Notification Permissions
                GroupBox("Benachrichtigungs-Berechtigungen") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Benachrichtigungen aktiviert", isOn: $coordinator.settings.notifications.enabled)
                        
                        if coordinator.settings.notifications.enabled {
                            HStack {
                                PermissionStatusView(status: permissionStatus)
                                
                                Spacer()
                                
                                if permissionStatus != .authorized {
                                    Button("Berechtigung anfordern") {
                                        requestNotificationPermission()
                                    }
                                    .buttonStyle(RequestButtonStyle())
                                } else {
                                    Button("Berechtigung entfernen") {
                                        removeNotificationPermission()
                                    }
                                    .buttonStyle(DestructiveButtonStyle())
                                }
                            }
                            
                            if permissionStatus == .denied {
                                Text("Berechtigungen wurden abgelehnt. Aktivieren Sie sie in den Systemeinstellungen.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                            }
                        } else {
                            Text("Benachrichtigungen sind deaktiviert. Aktivieren Sie sie, um wichtige Updates zu erhalten.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                
                // Notification Types
                if coordinator.settings.notifications.enabled {
                    GroupBox("Benachrichtigungstypen") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Fehler-Benachrichtigungen", isOn: $coordinator.settings.notifications.errorNotifications)
                            Toggle("Erfolgs-Benachrichtigungen", isOn: $coordinator.settings.notifications.successNotifications)
                            Toggle("Auto-Save Benachrichtigungen", isOn: $coordinator.settings.notifications.autoSaveNotifications)
                            Toggle("Sync-Benachrichtigungen", isOn: $coordinator.settings.notifications.syncNotifications)
                        }
                    }
                }
                
                // Sound & Visual
                GroupBox("Ton & Visuell") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Sounds aktiviert", isOn: $coordinator.settings.notifications.soundEnabled)
                        
                        if coordinator.settings.notifications.soundEnabled {
                            VStack(alignment: .leading) {
                                Text("Sound-Einstellungen")
                                    .font(.headline)
                                
                                HStack {
                                    Button("Test-Sound") {
                                        playTestSound()
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        
                        Toggle("Toast-Benachrichtigungen anzeigen", isOn: $coordinator.settings.notifications.showToast)
                        Toggle("Badge anzeigen", isOn: $coordinator.settings.notifications.showBadge)
                        
                        if coordinator.settings.notifications.showToast {
                            ToastPreviewView()
                        }
                    }
                }
                
                // Privacy Levels
                GroupBox("Datenschutz-Level") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wählen Sie das Datenschutz-Level für Benachrichtigungen:")
                            .font(.subheadline)
                        
                        VStack(spacing: 8) {
                            ForEach(PrivacyLevel.allCases, id: \.self) { level in
                                PrivacyLevelRow(
                                    level: level,
                                    isSelected: coordinator.settings.notifications.privacyLevel == level,
                                    onSelect: {
                                        coordinator.settings.notifications.privacyLevel = level
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Notification Schedule
                GroupBox("Benachrichtigungs-Zeitplan") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Do Not Disturb Zeiten")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                ForEach(dndSchedule.indices, id: \.self) { index in
                                    DNDRow(
                                        schedule: $dndSchedule[index],
                                        onDelete: { dndSchedule.remove(at: index) }
                                    )
                                }
                                
                                Button("Zeit hinzufügen") {
                                    addDNDSlot()
                                }
                                .buttonStyle(AddButtonStyle())
                            }
                        }
                    }
                }
                
                // Test & Preview
                GroupBox("Test & Vorschau") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Button("Test-Benachrichtigung senden") {
                                sendTestNotification()
                            }
                            .disabled(testNotificationInProgress || !coordinator.settings.notifications.enabled)
                            
                            if testNotificationInProgress {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            
                            Spacer()
                        }
                        
                        Text("Senden Sie eine Test-Benachrichtigung, um die Einstellungen zu überprüfen.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Notification History
                        if !notificationHistory.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Benachrichtigungsverlauf")
                                    .font(.headline)
                                
                                ForEach(notificationHistory.prefix(5), id: \.id) { notification in
                                    NotificationHistoryRow(notification: notification)
                                }
                            }
                        }
                    }
                }
                
                // System Integration
                GroupBox("System-Integration") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("macOS System-Integration")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .font(.caption)
                                Text("Notification Center")
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text("Aktiv")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                    .font(.caption)
                                Text("Sound System")
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(coordinator.settings.notifications.soundEnabled ? "Aktiv" : "Deaktiviert")
                                    .font(.caption)
                                    .foregroundColor(coordinator.settings.notifications.soundEnabled ? .green : .secondary)
                            }
                            
                            HStack {
                                Image(systemName: "rectangle.badge.more")
                                    .font(.caption)
                                Text("App Badge")
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(coordinator.settings.notifications.showBadge ? "Aktiv" : "Deaktiviert")
                                    .font(.caption)
                                    .foregroundColor(coordinator.settings.notifications.showBadge ? .green : .secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            checkNotificationPermission()
        }
        .onChange(of: coordinator.settings.notifications) { _ in
            saveSettings()
        }
    }
    
    // MARK: - State Properties
    
    @State private var dndSchedule: [DNDSlot] = [
        DNDSlot(start: "22:00", end: "07:00", days: "Mo-Fr"),
        DNDSlot(start: "00:00", end: "24:00", days: "So")
    ]
    
    @State private var notificationHistory: [NotificationHistory] = [
        NotificationHistory(id: "1", type: "success", title: "Auto-Save erfolgreich", time: Date().addingTimeInterval(-300)),
        NotificationHistory(id: "2", type: "info", title: "Einstellungen gespeichert", time: Date().addingTimeInterval(-600))
    ]
    
    // MARK: - Methods
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                permissionStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                permissionStatus = granted ? .authorized : .denied
            }
        }
    }
    
    private func removeNotificationPermission() {
        // This would typically involve removing the notification permissions from system
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
    }
    
    private func playTestSound() {
        // Play test notification sound
        NSSound(named: "Purr")?.play()
    }
    
    private func addDNDSlot() {
        dndSchedule.append(DNDSlot(start: "00:00", end: "00:00", days: ""))
    }
    
    private func sendTestNotification() {
        testNotificationInProgress = true
        
        let content = UNMutableNotificationContent()
        content.title = "Test-Benachrichtigung"
        content.body = "Dies ist eine Test-Benachrichtigung von StatusBarApp"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                testNotificationInProgress = false
                if error == nil {
                    // Add to history
                    let newNotification = NotificationHistory(
                        id: UUID().uuidString,
                        type: "test",
                        title: "Test-Benachrichtigung gesendet",
                        time: Date()
                    )
                    notificationHistory.insert(newNotification, at: 0)
                }
            }
        }
    }
    
    private func saveSettings() {
        do {
            try SettingsPersistence.shared.save(coordinator.settings)
            print("Notification Settings gespeichert")
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct PermissionStatusView: View {
    let status: UNAuthorizationStatus
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.caption)
            
            VStack(alignment: .leading) {
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(statusDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .authorized: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        @unknown default: return "questionmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .orange
        }
    }
    
    private var statusText: String {
        switch status {
        case .authorized: return "Autorisiert"
        case .denied: return "Abgelehnt"
        case .notDetermined: return "Nicht bestimmt"
        @unknown default: return "Unbekannt"
        }
    }
    
    private var statusDescription: String {
        switch status {
        case .authorized: return "Benachrichtigungen sind aktiviert"
        case .denied: return "Benachrichtigungen sind blockiert"
        case .notDetermined: return "Berechtigung noch nicht angefordert"
        @unknown default: return "Status unbekannt"
        }
    }
}

struct PrivacyLevelRow: View {
    let level: PrivacyLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(level.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(levelDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isSelected
                        ? Color.blue.opacity(0.1)
                        : Color.clear
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected ? Color.blue.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var levelDescription: String {
        switch level {
        case .minimal:
            return "Nur kritische Benachrichtigungen"
        case .balanced:
            return "Ausgewogene Benachrichtigungen"
        case .detailed:
            return "Alle Benachrichtigungen mit Details"
        }
    }
}

struct DNDRow: View {
    @Binding var schedule: DNDSlot
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            TextField("Start", text: $schedule.start)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
            
            Text("-")
                .font(.caption)
            
            TextField("Ende", text: $schedule.end)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
            
            TextField("Tage", text: $schedule.days)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
            
            Button("Löschen") {
                onDelete()
            }
            .buttonStyle(TextButtonStyle())
        }
    }
}

struct ToastPreviewView: View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            VStack(alignment: .leading) {
                Text("Toast Vorschau")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("So sehen Toast-Benachrichtigungen aus")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct NotificationHistoryRow: View {
    let notification: NotificationHistory
    
    var body: some View {
        HStack {
            Image(systemName: notificationTypeIcon)
                .foregroundColor(notificationTypeColor)
                .font(.caption)
            
            VStack(alignment: .leading) {
                Text(notification.title)
                    .font(.caption)
                Text(formatDate(notification.time))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var notificationTypeIcon: String {
        switch notification.type {
        case "success": return "checkmark.circle.fill"
        case "error": return "xmark.circle.fill"
        case "info": return "info.circle.fill"
        case "test": return "wrench.and.screwdriver.fill"
        default: return "bell.circle.fill"
        }
    }
    
    private var notificationTypeColor: Color {
        switch notification.type {
        case "success": return .green
        case "error": return .red
        case "info": return .blue
        case "test": return .orange
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Data Models

struct DNDSlot: Identifiable {
    let id = UUID()
    var start: String
    var end: String
    var days: String
}

struct NotificationHistory: Identifiable {
    let id: String
    let type: String
    let title: String
    let time: Date
}

// MARK: - Button Styles

struct RequestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.blue.opacity(0.3)
                        : Color.blue.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

struct AddButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                        ? Color.green.opacity(0.3)
                        : Color.green.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Preview

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView(coordinator: SettingsCoordinator())
            .frame(width: 500, height: 700)
    }
}