//
//  NotionWebhooks.swift
//  AINotizassistent
//
//  Webhook Support für real-time Sync mit Notion
//

import Foundation
import Network

// MARK: - Webhook Event Types
enum NotionWebhookEvent: String, Codable {
    case page_created = "page.created"
    case page_updated = "page.updated"
    case page_archived = "page.archived"
    case page_restored = "page.restored"
    case database_created = "database.created"
    case database_updated = "database.updated"
    case database_archived = "database.archived"
    case database_restored = "database.restored"
}

// MARK: - Webhook Event Structure
struct NotionWebhookEventData: Codable {
    let object: String
    let type: NotionWebhookEvent
    let event_time: String
    let data: NotionWebhookData
}

struct NotionWebhookData: Codable {
    let object: String
    let id: String
    let url: String?
    let parent: PageParent?
    let properties: [String: NotionPropertyValue]?
    let created_time: String
    let last_edited_time: String
}

// MARK: - Webhook Manager
class NotionWebhookManager: ObservableObject {
    private var webSocket: NWWebSocket?
    private var webhookEndpoint: String?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var reconnectTimer: Timer?
    
    @Published var isConnected = false
    @Published var events: [NotionWebhookEventData] = []
    @Published var connectionError: Error?
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "network.monitor", qos: .utility)
    
    init() {
        setupNetworkMonitor()
    }
    
    // MARK: - Connection Management
    func connect(endpoint: String) async throws {
        guard let url = URL(string: endpoint) else {
            throw NotionError(code: "INVALID_ENDPOINT", message: "Ungültige Webhook-URL")
        }
        
        webhookEndpoint = endpoint
        
        do {
            webSocket = NWWebSocket(url: url)
            try await setupWebSocket()
            await monitorNetworkChanges()
        } catch {
            throw error
        }
    }
    
    func disconnect() {
        webSocket?.cancel()
        webSocket = nil
        isConnected = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - WebSocket Setup
    private func setupWebSocket() async throws {
        guard let webSocket = webSocket else { return }
        
        let connectionResult = await withCheckedContinuation { continuation in
            webSocket.connect { result in
                continuation.resume(returning: result)
            }
        }
        
        switch connectionResult {
        case .success:
            await MainActor.run {
                isConnected = true
                connectionError = nil
                reconnectAttempts = 0
            }
            startListening()
            
        case .failure(let error):
            await MainActor.run {
                self.connectionError = error
                self.isConnected = false
            }
            throw error
        }
    }
    
    private func startListening() {
        webSocket?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.isConnected = true
                    self?.connectionError = nil
                    
                case .failed(let error):
                    self?.isConnected = false
                    self?.connectionError = error
                    self?.scheduleReconnect()
                    
                case .cancelled:
                    self?.isConnected = false
                    
                default:
                    break
                }
            }
        }
        
        webSocket?.messageHandler = { [weak self] message in
            self?.handleIncomingMessage(message)
        }
    }
    
    // MARK: - Message Handling
    private func handleIncomingMessage(_ message: NWProtocolWebSocket.Message) {
        switch message {
        case .string(let text):
            parseWebhookEvent(text)
            
        case .binary(let data):
            parseWebhookEvent(String(data: data, encoding: .utf8) ?? "")
            
        @unknown default:
            print("Unbekannte Nachrichtenart empfangen")
        }
    }
    
    private func parseWebhookEvent(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }
        
        do {
            let event = try JSONDecoder().decode(NotionWebhookEventData.self, from: data)
            Task { @MainActor in
                events.insert(event, at: 0) // Neueste Events zuerst
                
                // Limit memory usage - keep only latest 100 events
                if events.count > 100 {
                    events = Array(events.prefix(100))
                }
                
                // Trigger event handlers
                self.handleEvent(event)
            }
        } catch {
            print("Fehler beim Parsen des Webhook-Events: \(error)")
        }
    }
    
    // MARK: - Event Handling
    private func handleEvent(_ event: NotionWebhookEventData) {
        switch event.type {
        case .page_created:
            NotificationCenter.default.post(
                name: .notionPageCreated,
                object: event
            )
            
        case .page_updated:
            NotificationCenter.default.post(
                name: .notionPageUpdated,
                object: event
            )
            
        case .database_created:
            NotificationCenter.default.post(
                name: .notionDatabaseCreated,
                object: event
            )
            
        case .database_updated:
            NotificationCenter.default.post(
                name: .notionDatabaseUpdated,
                object: event
            )
            
        default:
            print("Event behandelt: \(event.type.rawValue)")
        }
    }
    
    // MARK: - Reconnection Logic
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("Maximale Reconnect-Versuche erreicht")
            return
        }
        
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30) // Exponential backoff, max 30s
        reconnectAttempts += 1
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task {
                await self?.attemptReconnect()
            }
        }
    }
    
    private func attemptReconnect() async {
        guard let endpoint = webhookEndpoint else { return }
        
        do {
            try await connect(endpoint: endpoint)
        } catch {
            print("Reconnect fehlgeschlagen: \(error)")
            scheduleReconnect()
        }
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                if path.status == .satisfied {
                    if !(self?.isConnected ?? false) {
                        await self?.attemptReconnect()
                    }
                } else {
                    self?.isConnected = false
                }
            }
        }
        
        monitor.start(queue: monitorQueue)
    }
    
    private func monitorNetworkChanges() async {
        // Start continuous monitoring
        while true {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            if webSocket == nil {
                break
            }
        }
    }
    
    // MARK: - Event Filtering
    func subscribeToDatabase(databaseId: String) {
        // Notion Webhook subscription logic
        // This would be implemented based on your webhook endpoint
    }
    
    func unsubscribeFromDatabase(databaseId: String) {
        // Unsubscribe from database events
    }
    
    func clearEvents() {
        events.removeAll()
    }
}

// MARK: - Notion Integration Webhook Extension
extension NotionIntegration {
    private var webhookManager: NotionWebhookManager? {
        // This would typically be injected or accessed via a shared instance
        return sharedWebhookManager
    }
    
    func setupWebhookListener(endpoint: String) async throws {
        try await webhookManager?.connect(endpoint: endpoint)
    }
    
    func enableRealTimeSync(for databaseId: String) {
        webhookManager?.subscribeToDatabase(databaseId: databaseId)
    }
    
    func disableRealTimeSync(for databaseId: String) {
        webhookManager?.unsubscribeFromDatabase(databaseId: databaseId)
    }
    
    // MARK: - Event Listeners
    func onPageCreated(handler: @escaping (NotionPage) -> Void) {
        NotificationCenter.default.addObserver(
            forName: .notionPageCreated,
            object: nil,
            queue: .main
        ) { notification in
            if let event = notification.object as? NotionWebhookEventData {
                Task {
                    do {
                        let page = try await self.getPage(pageId: event.data.id)
                        await MainActor.run {
                            handler(page)
                        }
                    } catch {
                        print("Fehler beim Laden der erstellten Seite: \(error)")
                    }
                }
            }
        }
    }
    
    func onPageUpdated(handler: @escaping (NotionPage) -> Void) {
        NotificationCenter.default.addObserver(
            forName: .notionPageUpdated,
            object: nil,
            queue: .main
        ) { notification in
            if let event = notification.object as? NotionWebhookEventData {
                Task {
                    do {
                        let page = try await self.getPage(pageId: event.data.id)
                        await MainActor.run {
                            handler(page)
                        }
                    } catch {
                        print("Fehler beim Laden der aktualisierten Seite: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let notionPageCreated = Notification.Name("NotionPageCreated")
    static let notionDatabaseCreated = Notification.Name("NotionDatabaseCreated")
    static let notionPageUpdated = Notification.Name("NotionPageUpdated")
    static let notionDatabaseUpdated = Notification.Name("NotionDatabaseUpdated")
}

// MARK: - Shared Webhook Manager
private var sharedWebhookManager: NotionWebhookManager?

extension NotionIntegration {
    static var sharedWebhookManager: NotionWebhookManager {
        get {
            if sharedWebhookManager == nil {
                sharedWebhookManager = NotionWebhookManager()
            }
            return sharedWebhookManager!
        }
    }
    
    static func sharedWebhookManager(_ manager: NotionWebhookManager) {
        sharedWebhookManager = manager
    }
}

// MARK: - WebSocket Implementation (Simplified)
class NWWebSocket: NSObject {
    private var url: URL
    private var connection: NWConnection?
    private var connectCompletion: ((Result<Void, Error>) -> Void)?
    private var stateUpdateHandler: ((NWConnection.State) -> Void)?
    private var messageHandler: ((NWProtocolWebSocket.Message) -> Void)?
    
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    func connect(completion: @escaping (Result<Void, Error>) -> Void) {
        self.connectCompletion = completion
        
        connection = NWConnection(host: url.host ?? "", port: url.port ?? 80, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.connectCompletion?(.success(()))
                
            case .failed(let error):
                self?.connectCompletion?(.failure(error))
                
            default:
                break
            }
            
            self?.stateUpdateHandler?(state)
        }
        
        connection?.start(queue: .global())
    }
    
    func cancel() {
        connection?.cancel()
    }
    
    func send(_ message: NWProtocolWebSocket.Message) {
        // Implementation depends on your WebSocket library
        // This is a simplified version
    }
}