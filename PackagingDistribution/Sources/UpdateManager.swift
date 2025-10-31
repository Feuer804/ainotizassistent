//
//  UpdateManager.swift
//  AINotizassistent - Automatic Update Management
//
//  Verwaltet automatische Updates und delta updates
//

import Foundation
import Sparkle
import BackgroundTasks

/// Verwaltet automatische App-Updates
class UpdateManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published var updateAvailable: Bool = false
    @Published var updateProgress: Double = 0.0
    @Published var currentVersion: String = ""
    @Published var latestVersion: String = ""
    @Published var downloadInProgress: Bool = false
    @Published var installScheduled: Bool = false
    
    private let configuration: UpdateConfiguration
    private let sparkeUpdater: SPUUpdater
    private let networkMonitor = NetworkMonitor()
    private let analytics: AnalyticsManager
    private let notificationManager: UpdateNotificationManager
    private let deltaUpdateManager: DeltaUpdateManager
    
    // Update scheduling
    private var updateCheckTimer: Timer?
    private let backgroundTaskManager = BackgroundTaskManager()
    
    // MARK: - Initialization
    
    init(configuration: UpdateConfiguration) {
        self.configuration = configuration
        self.sparkeUpdater = SPUUpdater()
        self.analytics = AnalyticsManager()
        self.notificationManager = UpdateNotificationManager()
        self.deltaUpdateManager = DeltaUpdateManager()
        
        setupUpdateSystem()
    }
    
    // MARK: - Setup Methods
    
    private func setupUpdateSystem() {
        print("🔄 Setup Update System...")
        
        configureSparkle()
        setupUpdateCheckScheduling()
        configureBackgroundUpdates()
        setupNetworkMonitoring()
        
        // Schedule initial update check
        scheduleUpdateCheck(delay: 30) // Check after 30 seconds
        
        analytics.trackEvent("update_system_configured", parameters: [
            "auto_check_enabled": configuration.autoCheckEnabled,
            "download_background": configuration.downloadInBackground,
            "silent_installs": configuration.silentInstalls,
            "delta_updates": configuration.enableDeltaUpdates
        ])
    }
    
    private func configureSparkle() {
        // Configure Sparkle updater
        sparkeUpdater.feedURL = URL(string: configuration.updateFeedURL)
        sparkeUpdater.publicDSAKey = configuration.publicDSAKey
        sparkeUpdater.updateCheckInterval = configuration.checkInterval
        
        // Update check behavior
        sparkeUpdater.automaticallyChecksForUpdates = configuration.autoCheckEnabled
        sparkeUpdater.downloadsInBackground = configuration.downloadInBackground
        sparkeUpdater.showsReleasesNotes = configuration.showsReleaseNotes
        sparkeUpdater.showsUpdateAlert = configuration.showsUpdateAlert
        
        // System integration
        sparkeUpdater.enableInfoPlistKey = true
        sparkeUpdater.embedSignature = true
    }
    
    private func setupUpdateCheckScheduling() {
        if configuration.enableScheduledUpdates {
            scheduleRegularUpdates()
        }
    }
    
    private func configureBackgroundUpdates() {
        if configuration.enableBackgroundUpdates {
            backgroundTaskManager.registerBackgroundTask(
                identifier: "com.yourapp.updatecheck",
                launchHandler: { task in
                    self.performBackgroundUpdateCheck(task: task)
                }
            )
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.startMonitoring { [weak self] isConnected in
            if isConnected && self?.configuration.enableNetworkDependentUpdates == true {
                self?.scheduleUpdateCheck(delay: 5)
            }
        }
    }
    
    // MARK: - Update Checking
    
    /// Führt manuelle Update-Überprüfung durch
    func checkForUpdatesManually() async {
        print("🔍 Manuelle Update-Überprüfung...")
        
        do {
            let updateInfo = try await fetchUpdateInfo()
            
            DispatchQueue.main.async {
                self.updateAvailable = updateInfo.isUpdateAvailable
                self.latestVersion = updateInfo.latestVersion
                self.currentVersion = updateInfo.currentVersion
                
                if updateInfo.isUpdateAvailable {
                    self.handleUpdateAvailable(updateInfo)
                } else {
                    self.handleNoUpdatesAvailable()
                }
            }
            
            // Track analytics
            analytics.trackEvent("manual_update_check", parameters: [
                "update_available": updateInfo.isUpdateAvailable,
                "current_version": updateInfo.currentVersion,
                "latest_version": updateInfo.latestVersion
            ])
            
        } catch {
            print("❌ Fehler bei Update-Überprüfung: \(error)")
            handleUpdateCheckError(error)
        }
    }
    
    /// Führt automatische Update-Überprüfung durch
    func checkForUpdatesAutomatically() async {
        guard configuration.autoCheckEnabled else { return }
        guard networkMonitor.isConnected else { return }
        
        print("🔄 Automatische Update-Überprüfung...")
        
        await checkForUpdatesManually()
    }
    
    /// Perform background update check
    private func performBackgroundUpdateCheck(task: BGAppRefreshTask) async {
        print("📋 Background Update-Überprüfung...")
        
        guard configuration.enableBackgroundUpdates else {
            task.setTaskCompleted(success: false)
            return
        }
        
        await checkForUpdatesAutomatically()
        
        // Schedule next check
        if configuration.enableScheduledUpdates {
            backgroundTaskManager.scheduleBackgroundTask(
                identifier: "com.yourapp.updatecheck",
                after: configuration.backgroundCheckInterval
            )
        }
        
        task.setTaskCompleted(success: true)
    }
    
    // MARK: - Update Downloading
    
    /// Startet Download des Updates
    func startUpdateDownload() async {
        print("⬇️ Starte Update-Download...")
        
        downloadInProgress = true
        updateProgress = 0.0
        
        do {
            if configuration.enableDeltaUpdates {
                try await downloadDeltaUpdate()
            } else {
                try await downloadFullUpdate()
            }
            
            DispatchQueue.main.async {
                self.downloadInProgress = false
                self.updateProgress = 1.0
            }
            
            // Handle update ready
            handleUpdateDownloaded()
            
            analytics.trackEvent("update_downloaded", parameters: [
                "delta_update": configuration.enableDeltaUpdates,
                "version": latestVersion,
                "download_duration": Date().timeIntervalSince1970 - Date().timeIntervalSince1970 // Placeholder
            ])
            
        } catch {
            print("❌ Fehler beim Update-Download: \(error)")
            handleUpdateDownloadError(error)
        }
    }
    
    private func downloadDeltaUpdate() async throws {
        let deltaInfo = try await deltaUpdateManager.getLatestDeltaUpdate()
        
        try await deltaUpdateManager.downloadDeltaUpdate(
            deltaInfo: deltaInfo,
            progressHandler: { progress in
                DispatchQueue.main.async {
                    self.updateProgress = progress
                }
            }
        )
    }
    
    private func downloadFullUpdate() async throws {
        try await sparkeUpdater.downloadUpdate(
            with: latestVersion,
            progress: { progress in
                DispatchQueue.main.async {
                    self.updateProgress = progress
                }
            }
        )
    }
    
    // MARK: - Update Installation
    
    /// Installiert heruntergeladenes Update
    func installUpdate() async {
        print("⚡ Installiere Update...")
        
        do {
            try await sparkeUpdater.installUpdate()
            
            if configuration.enableSilentInstalls {
                // Silent installation for background updates
                await performSilentInstallation()
            } else {
                // User-prompted installation
                await showInstallationPrompt()
            }
            
            analytics.trackEvent("update_installed", parameters: [
                "silent_install": configuration.enableSilentInstalls,
                "version": latestVersion,
                "user_initiated": !installScheduled
            ])
            
        } catch {
            print("❌ Fehler bei Update-Installation: \(error)")
            handleUpdateInstallationError(error)
        }
    }
    
    /// Automatische Installation im Hintergrund
    private func performSilentInstallation() async {
        if configuration.silentInstallSchedule == .immediate {
            try? await installUpdate()
        } else if configuration.silentInstallSchedule == .onQuit {
            // Schedule installation on quit
            await scheduleInstallationOnQuit()
        }
    }
    
    /// Zeigt Installation-Dialog an
    private func showInstallationPrompt() async {
        await MainActor.run {
            notificationManager.showUpdateReadyPrompt(
                version: latestVersion,
                changelog: try? await getLatestChangelog()
            ) { shouldInstall in
                if shouldInstall {
                    Task {
                        await self.installUpdate()
                    }
                }
            }
        }
    }
    
    // MARK: - Scheduling Methods
    
    /// Planed regelmäßige Update-Überprüfungen
    func scheduleRegularUpdates() {
        if updateCheckTimer != nil {
            updateCheckTimer?.invalidate()
        }
        
        updateCheckTimer = Timer.scheduledTimer(withTimeInterval: configuration.checkInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.checkForUpdatesAutomatically()
            }
        }
        
        print("⏰ Regelmäßige Update-Überprüfung aktiviert (\(configuration.checkInterval)s)")
    }
    
    /// Planed Update-Download
    func scheduleUpdateDownload(timeInterval: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            Task {
                await self?.startUpdateDownload()
            }
        }
        
        print("⏰ Update-Download geplant für \(timeInterval) Sekunden")
    }
    
    /// Planed Update-Installation
    func scheduleUpdateInstallation(timeInterval: TimeInterval) {
        installScheduled = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            Task {
                await self?.installUpdate()
            }
        }
        
        print("⏰ Update-Installation geplant für \(timeInterval) Sekunden")
    }
    
    /// Führt sofortige Update-Überprüfung durch
    func scheduleUpdateCheck(delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            Task {
                await self?.checkForUpdatesAutomatically()
            }
        }
    }
    
    // MARK: - Update Notifications
    
    private func handleUpdateAvailable(_ updateInfo: UpdateInfo) {
        print("🎉 Update verfügbar: \(updateInfo.latestVersion)")
        
        // Show update notification
        notificationManager.showUpdateAvailableNotification(
            currentVersion: updateInfo.currentVersion,
            latestVersion: updateInfo.latestVersion,
            changelog: updateInfo.releaseNotes,
            size: updateInfo.updateSize
        )
        
        // Trigger in-app update prompt
        if configuration.enableInAppPrompts {
            triggerInAppUpdatePrompt(updateInfo)
        }
        
        // Schedule automatic download if enabled
        if configuration.downloadInBackground && !downloadInProgress {
            scheduleUpdateDownload(timeInterval: configuration.autoDownloadDelay)
        }
    }
    
    private func handleNoUpdatesAvailable() {
        print("✅ Keine Updates verfügbar")
        
        if configuration.showNoUpdateNotification {
            notificationManager.showNoUpdateAvailableNotification()
        }
    }
    
    private func handleUpdateCheckError(_ error: Error) {
        print("❌ Update-Überprüfung fehlgeschlagen: \(error)")
        
        if configuration.showErrorNotifications {
            notificationManager.showUpdateCheckError(error)
        }
        
        analytics.trackEvent("update_check_error", parameters: [
            "error": error.localizedDescription
        ])
    }
    
    private func handleUpdateDownloaded() {
        print("✅ Update-Download abgeschlossen")
        
        if configuration.showDownloadCompletedNotification {
            notificationManager.showUpdateDownloadedNotification(latestVersion)
        }
    }
    
    private func handleUpdateDownloadError(_ error: Error) {
        print("❌ Update-Download fehlgeschlagen: \(error)")
        
        downloadInProgress = false
        updateProgress = 0.0
        
        if configuration.showDownloadErrorNotification {
            notificationManager.showUpdateDownloadError(error)
        }
        
        analytics.trackEvent("update_download_error", parameters: [
            "error": error.localizedDescription
        ])
    }
    
    private func handleUpdateInstallationError(_ error: Error) {
        print("❌ Update-Installation fehlgeschlagen: \(error)")
        
        if configuration.showInstallationErrorNotification {
            notificationManager.showUpdateInstallationError(error)
        }
        
        analytics.trackEvent("update_install_error", parameters: [
            "error": error.localizedDescription
        ])
    }
    
    // MARK: - In-App Update UI
    
    private func triggerInAppUpdatePrompt(_ updateInfo: UpdateInfo) {
        // Dispatch to main thread for UI updates
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .showUpdatePrompt,
                object: updateInfo
            )
        }
    }
    
    // MARK: - Update Feed Generation
    
    /// Generiert Sparkle Appcast Feed
    func generateAppcast() async throws {
        print("📡 Generiere Appcast Feed...")
        
        let appcast = AppcastGenerator()
        
        let feed = try await appcast.generateFeed(
            for: latestVersion,
            withAssets: await collectDistributionAssets(),
            releaseNotes: try await getLatestReleaseNotes(),
            deltaUpdates: configuration.enableDeltaUpdates
        )
        
        try await uploadAppcast(feed)
        
        print("✅ Appcast Feed generiert und hochgeladen")
    }
    
    // MARK: - Utility Methods
    
    private func fetchUpdateInfo() async throws -> UpdateInfo {
        let url = URL(string: "\(configuration.updateFeedURL)/latest")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(currentVersion, forHTTPHeaderField: "X-App-Version")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UpdateError.networkError
        }
        
        return try JSONDecoder().decode(UpdateInfo.self, from: data)
    }
    
    private func getLatestChangelog() async throws -> String {
        // Fetch latest release notes
        return try await GitHubManager().getLatestReleaseNotes()
    }
    
    private func getLatestReleaseNotes() async throws -> String {
        return try await getLatestChangelog()
    }
    
    private func collectDistributionAssets() async -> [UpdateAsset] {
        // Collect DMG, PKG, ZIP assets with checksums
        return await UpdateAssetManager().collectAssets(
            version: latestVersion,
            platforms: ["macosx", "universal"]
        )
    }
    
    private func uploadAppcast(_ feed: String) async throws {
        let uploadURL = URL(string: configuration.appcastUploadURL)!
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.httpBody = feed.data(using: .utf8)
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.addValue(configuration.uploadAPIKey, forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UpdateError.uploadFailed
        }
    }
    
    private func scheduleInstallationOnQuit() {
        // Save installation schedule to UserDefaults
        UserDefaults.standard.set(true, forKey: "ScheduledInstallOnQuit")
        UserDefaults.standard.set(latestVersion, forKey: "ScheduledInstallVersion")
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Supporting Types

struct UpdateConfiguration {
    let updateFeedURL: String
    let publicDSAKey: String
    let checkInterval: TimeInterval
    let autoCheckEnabled: Bool
    let downloadInBackground: Bool
    let showsReleaseNotes: Bool
    let showsUpdateAlert: Bool
    let enableScheduledUpdates: Bool
    let backgroundCheckInterval: TimeInterval
    let enableBackgroundUpdates: Bool
    let enableNetworkDependentUpdates: Bool
    let enableDeltaUpdates: Bool
    let enableSilentInstalls: Bool
    let silentInstallSchedule: SilentInstallSchedule
    let enableInAppPrompts: Bool
    let autoDownloadDelay: TimeInterval
    let showNoUpdateNotification: Bool
    let showErrorNotifications: Bool
    let showDownloadCompletedNotification: Bool
    let showDownloadErrorNotification: Bool
    let showInstallationErrorNotification: Bool
    let appcastUploadURL: String
    let uploadAPIKey: String
}

enum SilentInstallSchedule {
    case immediate
    case onQuit
    case scheduled(date: Date)
}

struct UpdateInfo: Codable {
    let isUpdateAvailable: Bool
    let currentVersion: String
    let latestVersion: String
    let releaseNotes: String
    let updateSize: Int
    let minimumOSVersion: String
    let releaseDate: String
    let assets: [UpdateAsset]
}

struct UpdateAsset: Codable {
    let filename: String
    let url: String
    let size: Int
    let sha256: String
    let type: AssetType
}

enum AssetType: String, Codable {
    case dmg
    case pkg
    case zip
    case delta
}

enum UpdateError: Error {
    case networkError
    case downloadFailed
    case installFailed
    case uploadFailed
    case invalidSignature
    case checksumMismatch
}

// MARK: - Notification Extensions

extension UpdateNotificationManager {
    func showUpdateAvailableNotification(
        currentVersion: String,
        latestVersion: String,
        changelog: String,
        size: Int
    ) {
        let notification = UpdateNotification(
            type: .updateAvailable,
            title: "Update verfügbar",
            message: "Version \(latestVersion) ist verfügbar (\(formatFileSize(size)))",
            actions: [.download, .later, .skipVersion],
            priority: .normal,
            userInfo: [
                "currentVersion": currentVersion,
                "latestVersion": latestVersion,
                "changelog": changelog,
                "size": size
            ]
        )
        
        deliver(notification)
    }
}

// MARK: - Background Task Manager

class BackgroundTaskManager {
    func registerBackgroundTask(
        identifier: String,
        launchHandler: @escaping (BGAppRefreshTask) -> Void
    ) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            if let appRefreshTask = task as? BGAppRefreshTask {
                appRefreshTask.setTaskCompleted(success: false)
                appRefreshTask.expirationHandler = {
                    appRefreshTask.setTaskCompleted(success: false)
                }
                
                launchHandler(appRefreshTask)
            }
        }
    }
    
    func scheduleBackgroundTask(identifier: String, after: TimeInterval) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: after)
        
        try? BGTaskScheduler.shared.submit(request)
    }
}

// MARK: - Network Monitor

class NetworkMonitor {
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")
    var isConnected: Bool = false
    
    func startMonitoring(changeHandler: @escaping (Bool) -> Void) {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { path in
            let isConnected = path.status == .satisfied
            DispatchQueue.main.async {
                self.isConnected = isConnected
                changeHandler(isConnected)
            }
        }
        monitor?.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor?.cancel()
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let showUpdatePrompt = Notification.Name("ShowUpdatePrompt")
}

extension UpdateManager {
    func formatFileSize(_ bytes: Int) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var size = Double(bytes)
        var unitIndex = 0
        
        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.1f %@", size, units[unitIndex])
    }
}

// MARK: - Main Actor for UI updates

@MainActor
class UpdateUIManager {
    static let shared = UpdateUIManager()
    
    func showUpdateDialog(updateInfo: UpdateInfo) {
        // UI update implementation
        print("📱 Zeige Update-Dialog für Version \(updateInfo.latestVersion)")
    }
}