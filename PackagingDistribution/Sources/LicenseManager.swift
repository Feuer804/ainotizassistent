//
//  LicenseManager.swift
//  AINotizassistent - License Management System
//
//  Umfassende Lizenz- und Aktivierungsverwaltung
//

import Foundation
import CryptoKit
import Network

/// Verwaltet Lizenz-Keys und Validierung
class LicenseManager {
    
    // MARK: - Properties
    
    private let configuration: LicenseConfiguration
    private let keychain = KeychainManager()
    private let networkMonitor = NetworkMonitor()
    private let analytics: AnalyticsManager
    
    // License state
    @Published var licenseStatus: LicenseStatus = .unknown
    @Published var remainingTrialDays: Int?
    @Published var activationCount: Int = 0
    @Published var isValid: Bool = false
    
    // MARK: - Initialization
    
    init(configuration: LicenseConfiguration) {
        self.configuration = configuration
        self.analytics = AnalyticsManager()
        
        setupLicenseSystem()
    }
    
    // MARK: - License System Setup
    
    private func setupLicenseSystem() {
        print("🔑 Setup License System...")
        
        // Check existing license
        checkLicenseStatus()
        
        // Setup trial management
        if configuration.enableTrialMode {
            setupTrialMode()
        }
        
        // Setup activation tracking
        setupActivationTracking()
        
        // Setup offline validation
        if configuration.enableOfflineValidation {
            setupOfflineValidation()
        }
        
        analytics.trackEvent("license_system_configured", parameters: [
            "trial_mode": configuration.enableTrialMode,
            "offline_validation": configuration.enableOfflineValidation,
            "device_binding": configuration.enableDeviceBinding
        ])
    }
    
    // MARK: - License Generation
    
    /// Generiert neuen Lizenz-Key
    func generateLicenseKey(for email: String, plan: LicensePlan) async throws -> String {
        print("🔑 Generiere Lizenz-Key für \(email)")
        
        let keyData = LicenseKeyData(
            email: email,
            plan: plan,
            issuedDate: Date(),
            expiryDate: calculateExpiryDate(for: plan),
            features: plan.features,
            deviceLimit: plan.deviceLimit
        )
        
        let licenseKey = try generateSignedKey(data: keyData)
        
        // Store in database if server validation is enabled
        if configuration.enableServerValidation {
            try await uploadLicenseToServer(licenseKey: licenseKey, data: keyData)
        }
        
        analytics.trackEvent("license_key_generated", parameters: [
            "email": email,
            "plan": plan.rawValue,
            "key_format": configuration.keyFormat.rawValue
        ])
        
        return licenseKey
    }
    
    /// Generiert Test-Lizenz
    func generateTrialLicense() async throws -> String {
        let email = "trial@\(UUID().uuidString.lowercased()).example"
        let trialPlan = LicensePlan.trial(days: configuration.trialPeriodDays)
        
        return try await generateLicenseKey(for: email, plan: trialPlan)
    }
    
    /// Generiert Promo-Lizenz
    func generatePromoLicense(email: String, promoCode: String) async throws -> String {
        print("🎁 Generiere Promo-Lizenz für \(email)")
        
        // Validate promo code
        let promoInfo = try await validatePromoCode(promoCode)
        
        let promoPlan = LicensePlan.promo(
            days: promoInfo.duration,
            features: promoInfo.features,
            deviceLimit: promoInfo.deviceLimit
        )
        
        let licenseKey = try await generateLicenseKey(for: email, plan: promoPlan)
        
        // Mark promo code as used
        try await markPromoCodeAsUsed(promoCode)
        
        analytics.trackEvent("promo_license_generated", parameters: [
            "email": email,
            "promo_code": promoCode,
            "duration": promoInfo.duration,
            "features": promoInfo.features.joined(separator: ",")
        ])
        
        return licenseKey
    }
    
    // MARK: - License Validation
    
    /// Validiert Lizenz-Key
    func validateLicenseKey(_ licenseKey: String) async throws -> LicenseValidationResult {
        print("🔍 Validiere Lizenz-Key...")
        
        // Parse and verify key format
        let keyData = try parseLicenseKey(licenseKey)
        
        // Verify digital signature
        try verifyLicenseSignature(licenseKey, data: keyData)
        
        // Check expiration
        if keyData.expiryDate < Date() {
            throw LicenseError.expired
        }
        
        // Check device limit
        let currentActivation = try await getActivationCount(for: keyData.email)
        if currentActivation >= keyData.deviceLimit {
            throw LicenseError.deviceLimitExceeded
        }
        
        // Server validation if enabled
        if configuration.enableServerValidation {
            let serverResult = try await validateWithServer(licenseKey)
            guard serverResult.isValid else {
                throw LicenseError.serverInvalid
            }
        }
        
        // Store validated license
        try storeLicense(licenseKey, data: keyData)
        
        let result = LicenseValidationResult(
            isValid: true,
            plan: keyData.plan,
            features: keyData.features,
            expiryDate: keyData.expiryDate,
            deviceLimit: keyData.deviceLimit,
            remainingDays: calculateRemainingDays(expiryDate: keyData.expiryDate)
        )
        
        licenseStatus = .valid
        isValid = true
        
        analytics.trackEvent("license_validated", parameters: [
            "plan": keyData.plan.rawValue,
            "expiry_days_remaining": result.remainingDays,
            "device_limit": keyData.deviceLimit
        ])
        
        return result
    }
    
    /// Aktiviert Lizenz
    func activateLicense(_ licenseKey: String, deviceId: String? = nil) async throws {
        print("⚡ Aktiviere Lizenz...")
        
        let keyData = try parseLicenseKey(licenseKey)
        let currentDeviceId = deviceId ?? DeviceManager.currentDeviceId()
        
        // Check activation limit
        let activationCount = try await getActivationCount(for: keyData.email)
        guard activationCount < keyData.deviceLimit else {
            throw LicenseError.deviceLimitExceeded
        }
        
        // Check if already activated on this device
        if try isAlreadyActivated(licenseKey, deviceId: currentDeviceId) {
            print("✅ Lizenz bereits auf diesem Gerät aktiviert")
            return
        }
        
        // Register activation
        try await registerActivation(licenseKey, deviceId: currentDeviceId)
        
        // Store device binding if enabled
        if configuration.enableDeviceBinding {
            try await bindLicenseToDevice(licenseKey, deviceId: currentDeviceId)
        }
        
        // Update local state
        self.activationCount = activationCount + 1
        
        // Show success message
        showActivationSuccess(keyData.plan)
        
        analytics.trackEvent("license_activated", parameters: [
            "plan": keyData.plan.rawValue,
            "device_id": currentDeviceId,
            "total_activations": self.activationCount
        ])
    }
    
    // MARK: - Trial Management
    
    /// Prüft Testzeitraum-Status
    func checkTrialStatus() {
        guard configuration.enableTrialMode else { return }
        
        let trialStartDate = UserDefaults.standard.object(forKey: "trialStartDate") as? Date
        let trialUsed = UserDefaults.standard.bool(forKey: "trialUsed")
        
        if trialStartDate != nil && !trialUsed {
            remainingTrialDays = calculateTrialDaysRemaining(startDate: trialStartDate!)
            licenseStatus = .trial
        } else if trialUsed {
            licenseStatus = .trialExpired
        } else {
            licenseStatus = .trialNotStarted
        }
    }
    
    /// Startet Testzeitraum
    func startTrial() {
        print("⏱️ Starte Testzeitraum...")
        
        let startDate = Date()
        UserDefaults.standard.set(startDate, forKey: "trialStartDate")
        UserDefaults.standard.set(false, forKey: "trialUsed")
        
        remainingTrialDays = configuration.trialPeriodDays
        licenseStatus = .trial
        
        analytics.trackEvent("trial_started", parameters: [
            "trial_period_days": configuration.trialPeriodDays,
            "start_date": startDate.timeIntervalSince1970
        ])
    }
    
    /// Prüft ob Testzeitraum abgelaufen ist
    func isTrialExpired() -> Bool {
        guard let trialStartDate = UserDefaults.standard.object(forKey: "trialStartDate") as? Date else {
            return false
        }
        
        let trialEndDate = Calendar.current.date(byAdding: .day, value: configuration.trialPeriodDays, to: trialStartDate)!
        return Date() > trialEndDate
    }
    
    /// Zeigt Upgrade-Prompt
    func showTrialUpgradePrompt() {
        if configuration.showTrialUpgradePrompts {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .showTrialUpgradePrompt,
                    object: nil
                )
            }
        }
    }
    
    // MARK: - Serial Number Validation
    
    /// Validiert Seriennummer
    func validateSerialNumber(_ serialNumber: String) async throws -> SerialValidationResult {
        print("📝 Validiere Seriennummer...")
        
        // Parse serial number format
        let serialData = try parseSerialNumber(serialNumber)
        
        // Verify checksum
        try verifySerialChecksum(serialNumber, serialData: serialData)
        
        // Check against database
        if configuration.enableServerValidation {
            let serverResult = try await validateSerialWithServer(serialNumber)
            guard serverResult.isValid else {
                throw SerialError.serverInvalid
            }
        }
        
        // Generate activation key from serial
        let activationKey = try generateActivationKey(from: serialData)
        
        let result = SerialValidationResult(
            isValid: true,
            activationKey: activationKey,
            features: serialData.features,
            expiryDate: serialData.expiryDate,
            deviceLimit: serialData.deviceLimit
        )
        
        analytics.trackEvent("serial_validated", parameters: [
            "serial_prefix": serialData.prefix,
            "features_count": serialData.features.count,
            "expiry_days": calculateRemainingDays(expiryDate: serialData.expiryDate)
        ])
        
        return result
    }
    
    // MARK: - License Storage
    
    /// Speichert Lizenz sicher
    private func storeLicense(_ licenseKey: String, data: LicenseKeyData) throws {
        let licenseInfo = LicenseInfo(
            key: licenseKey,
            email: data.email,
            plan: data.plan,
            features: data.features,
            expiryDate: data.expiryDate,
            deviceLimit: data.deviceLimit,
            activationCount: 0
        )
        
        try keychain.store(data: try JSONEncoder().encode(licenseInfo), forKey: "license_info")
        
        // Store activation history
        let activationHistory = ActivationHistory(activations: [], lastActivation: nil)
        try keychain.store(data: try JSONEncoder().encode(activationHistory), forKey: "activation_history")
    }
    
    /// Lädt gespeicherte Lizenz
    func loadStoredLicense() throws -> LicenseInfo? {
        guard let data = try keychain.retrieveData(forKey: "license_info") else {
            return nil
        }
        
        return try JSONDecoder().decode(LicenseInfo.self, from: data)
    }
    
    // MARK: - Activation Management
    
    /// Registriert Geräte-Aktivierung
    private func registerActivation(_ licenseKey: String, deviceId: String) async throws {
        let activation = DeviceActivation(
            licenseKey: licenseKey,
            deviceId: deviceId,
            activationDate: Date(),
            lastUsed: Date()
        )
        
        var activations = try loadActivations()
        activations.append(activation)
        
        try keychain.store(data: try JSONEncoder().encode(activations), forKey: "device_activations")
        
        // Update activation count in license info
        if var licenseInfo = try loadStoredLicense() {
            licenseInfo.activationCount = activations.count
            try keychain.store(data: try JSONEncoder().encode(licenseInfo), forKey: "license_info")
        }
        
        analytics.trackEvent("activation_registered", parameters: [
            "device_id": deviceId,
            "total_activations": activations.count
        ])
    }
    
    /// Lädt Aktivierungen
    private func loadActivations() throws -> [DeviceActivation] {
        guard let data = try keychain.retrieveData(forKey: "device_activations") else {
            return []
        }
        
        return try JSONDecoder().decode([DeviceActivation].self, from: data)
    }
    
    /// Prüft Aktivierung auf Gerät
    private func isAlreadyActivated(_ licenseKey: String, deviceId: String) throws -> Bool {
        let activations = try loadActivations()
        return activations.contains { $0.licenseKey == licenseKey && $0.deviceId == deviceId }
    }
    
    /// Zählt Aktivierungen für Email
    private func getActivationCount(for email: String) async throws -> Int {
        if let licenseInfo = try loadStoredLicense(),
           licenseInfo.email == email {
            return licenseInfo.activationCount
        }
        
        // Query server if enabled
        if configuration.enableServerValidation {
            return try await queryActivationCountFromServer(email)
        }
        
        return 0
    }
    
    // MARK: - Utility Methods
    
    private func calculateExpiryDate(for plan: LicensePlan) -> Date {
        let calendar = Calendar.current
        
        switch plan {
        case .perpetual:
            return calendar.date(byAdding: .year, value: 50, to: Date())!
        case .subscription(let months):
            return calendar.date(byAdding: .month, value: months, to: Date())!
        case .trial(let days):
            return calendar.date(byAdding: .day, value: days, to: Date())!
        case .promo(let days, _, _):
            return calendar.date(byAdding: .day, value: days, to: Date())!
        }
    }
    
    private func calculateTrialDaysRemaining(startDate: Date) -> Int {
        let calendar = Calendar.current
        let trialEndDate = calendar.date(byAdding: .day, value: configuration.trialPeriodDays, to: startDate)!
        let remaining = calendar.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return max(0, remaining)
    }
    
    private func calculateRemainingDays(expiryDate: Date) -> Int {
        let calendar = Calendar.current
        let remaining = calendar.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        return max(0, remaining)
    }
    
    private func generateChecksum(for string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func showActivationSuccess(_ plan: LicensePlan) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .showActivationSuccess,
                object: ["plan": plan.rawValue]
            )
        }
    }
    
    private func setupTrialMode() {
        checkTrialStatus()
        
        // Show trial prompt if not started
        if licenseStatus == .trialNotStarted {
            showTrialStartPrompt()
        }
    }
    
    private func showTrialStartPrompt() {
        if configuration.showTrialPrompts {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .showTrialStartPrompt,
                    object: nil
                )
            }
        }
    }
    
    // MARK: - Server Communication
    
    private func uploadLicenseToServer(licenseKey: String, data: LicenseKeyData) async throws {
        guard let url = URL(string: configuration.licenseServerURL) else {
            throw LicenseError.invalidServerURL
        }
        
        var request = URLRequest(url: url.appendingPathComponent("/api/licenses"))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        
        let licenseData = [
            "licenseKey": licenseKey,
            "email": data.email,
            "plan": data.plan.rawValue,
            "features": data.features,
            "expiryDate": data.expiryDate.timeIntervalSince1970,
            "deviceLimit": data.deviceLimit
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: licenseData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LicenseError.serverError
        }
    }
    
    private func validateWithServer(_ licenseKey: String) async throws -> ServerValidationResult {
        guard let url = URL(string: configuration.licenseServerURL) else {
            throw LicenseError.invalidServerURL
        }
        
        var request = URLRequest(url: url.appendingPathComponent("/api/licenses/validate"))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        
        let body = ["licenseKey": licenseKey]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LicenseError.serverError
        }
        
        return try JSONDecoder().decode(ServerValidationResult.self, from: data)
    }
    
    // MARK: - Error Handling
    
    private func checkLicenseStatus() {
        do {
            if let licenseInfo = try loadStoredLicense() {
                let expiryDate = licenseInfo.expiryDate
                
                if Date() > expiryDate {
                    licenseStatus = .expired
                } else {
                    licenseStatus = .valid
                    isValid = true
                    activationCount = licenseInfo.activationCount
                }
            } else {
                licenseStatus = configuration.enableTrialMode ? .trialNotStarted : .unlicensed
            }
        } catch {
            print("⚠️ Fehler beim Prüfen des Lizenz-Status: \(error)")
            licenseStatus = .unknown
        }
    }
    
    private func setupActivationTracking() {
        // Track activation count
        activationCount = (try? loadStoredLicense()?.activationCount) ?? 0
    }
    
    private func setupOfflineValidation() {
        // Setup offline validation cache
        UserDefaults.standard.set(Date(), forKey: "lastOfflineValidation")
    }
}

// MARK: - Supporting Types

struct LicenseConfiguration {
    let enableTrialMode: Bool
    let trialPeriodDays: Int
    let enableOfflineValidation: Bool
    let enableServerValidation: Bool
    let enableDeviceBinding: Bool
    let apiKey: String
    let licenseServerURL: String
    let publicKey: String
    let keyFormat: LicenseKeyFormat
    let showTrialPrompts: Bool
    let showTrialUpgradePrompts: Bool
}

enum LicenseStatus {
    case unknown
    case trialNotStarted
    case trial
    case trialExpired
    case valid
    case expired
    case unlicensed
    case invalid
}

enum LicensePlan: String, Codable {
    case perpetual
    case subscription(months: Int)
    case trial(days: Int)
    case promo(days: Int, features: [String], deviceLimit: Int)
}

enum LicenseKeyFormat {
    case standard
    case grouped
    case compact
}

struct LicenseKeyData: Codable {
    let email: String
    let plan: LicensePlan
    let issuedDate: Date
    let expiryDate: Date
    let features: [String]
    let deviceLimit: Int
}

struct LicenseValidationResult {
    let isValid: Bool
    let plan: LicensePlan
    let features: [String]
    let expiryDate: Date
    let deviceLimit: Int
    let remainingDays: Int
}

struct LicenseInfo: Codable {
    let key: String
    let email: String
    let plan: LicensePlan
    let features: [String]
    let expiryDate: Date
    let deviceLimit: Int
    var activationCount: Int
}

struct DeviceActivation: Codable {
    let licenseKey: String
    let deviceId: String
    let activationDate: Date
    var lastUsed: Date
}

struct ActivationHistory: Codable {
    let activations: [DeviceActivation]
    let lastActivation: Date?
}

enum LicenseError: Error {
    case invalidKeyFormat
    case expired
    case deviceLimitExceeded
    case serverError
    case serverInvalid
    case invalidServerURL
    case signatureInvalid
}

enum SerialError: Error {
    case invalidFormat
    case checksumMismatch
    case serverInvalid
}

struct SerialValidationResult {
    let isValid: Bool
    let activationKey: String
    let features: [String]
    let expiryDate: Date
    let deviceLimit: Int
}

struct ServerValidationResult: Codable {
    let isValid: Bool
    let remainingActivations: Int
    let expiryDate: Date
}

// MARK: - Notification Names

extension Notification.Name {
    static let showTrialUpgradePrompt = Notification.Name("ShowTrialUpgradePrompt")
    static let showActivationSuccess = Notification.Name("ShowActivationSuccess")
    static let showTrialStartPrompt = Notification.Name("ShowTrialStartPrompt")
}

// MARK: - Keychain Manager

class KeychainManager {
    func store(data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status))
        }
    }
    
    func retrieveData(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status))
        }
        
        return (dataTypeRef as? Data)
    }
}

// MARK: - Device Manager

class DeviceManager {
    static func currentDeviceId() -> String {
        var deviceId = UserDefaults.standard.string(forKey: "deviceId")
        
        if deviceId == nil {
            deviceId = UUID().uuidString
            UserDefaults.standard.set(deviceId, forKey: "deviceId")
        }
        
        return deviceId!
    }
    
    static func hardwareFingerprint() -> String {
        // Generate hardware-specific fingerprint
        var fingerprint = ""
        
        // System name
        var systemInfo = utsname()
        uname(&systemInfo)
        fingerprint += String(cString: systemInfo.machine)
        
        // UUID
        fingerprint += DeviceManager.currentDeviceId()
        
        // Generate hash
        return generateChecksum(for: fingerprint)
    }
    
    private static func generateChecksum(for string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}