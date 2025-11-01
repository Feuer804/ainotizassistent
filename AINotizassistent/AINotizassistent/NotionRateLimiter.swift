//
//  NotionRateLimiter.swift
//  AINotizassistent
//
//  Rate Limiting und Retry-Mechanismen für Notion API
//

import Foundation

// MARK: - Rate Limiting Error
struct RateLimitError: Error {
    let retryAfter: TimeInterval
    let message: String
    
    init(retryAfter: TimeInterval, message: String = "Rate limit überschritten") {
        self.retryAfter = retryAfter
        self.message = message
    }
}

// MARK: - Rate Limit Manager
class NotionRateLimiter: ObservableObject {
    private let requestsPerSecond: Double = 3.0 // Notion erlaubt ~3 Requests/Sekunde
    private let requestsPerMinute: Double = 100.0 // ~100 Requests/Minute
    private var requestTimes: [Date] = []
    private let queue = DispatchQueue(label: "notion.ratelimiter", qos: .utility)
    
    // MARK: - Request Throttling
    func waitForRateLimit() async {
        await withCheckedContinuation { continuation in
            queue.async {
                self.enforceRateLimit()
                continuation.resume()
            }
        }
    }
    
    private func enforceRateLimit() {
        let now = Date()
        
        // Remove old timestamps (older than 1 minute)
        requestTimes.removeAll { $0.timeIntervalSince(now) < -60 }
        
        // Check per-minute limit
        if requestTimes.count >= Int(requestsPerMinute) {
            let oldestRequest = requestTimes.first!
            let waitTime = 60 - now.timeIntervalSince(oldestRequest)
            if waitTime > 0 {
                Thread.sleep(forTimeInterval: waitTime)
            }
        }
        
        // Check per-second limit
        if !requestTimes.isEmpty {
            let latestRequest = requestTimes.last!
            let timeSinceLastRequest = now.timeIntervalSince(latestRequest)
            if timeSinceLastRequest < (1.0 / requestsPerSecond) {
                let waitTime = (1.0 / requestsPerSecond) - timeSinceLastRequest
                Thread.sleep(forTimeInterval: waitTime)
            }
        }
        
        requestTimes.append(now)
    }
    
    // MARK: - Retry Mechanism
    func executeWithRetry<T>(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        exponentialBackoff: Bool = true,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                // Rate limit vor Request
                await waitForRateLimit()
                
                let result = try await operation()
                return result
                
            } catch let error as RateLimitError {
                let delay = calculateDelay(
                    for: attempt,
                    baseDelay: baseDelay,
                    exponentialBackoff: exponentialBackoff,
                    retryAfter: error.retryAfter
                )
                
                if attempt == maxRetries {
                    throw error
                }
                
                await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                lastError = error
                
            } catch let error as NotionError {
                switch error.code {
                case "internal_server_error", "service_unavailable":
                    let delay = calculateDelay(
                        for: attempt,
                        baseDelay: baseDelay,
                        exponentialBackoff: exponentialBackoff
                    )
                    
                    if attempt == maxRetries {
                        throw error
                    }
                    
                    await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    lastError = error
                    
                case "unauthorized", "forbidden":
                    // No retry for auth errors
                    throw error
                    
                default:
                    throw error
                }
            } catch {
                // Other errors - no retry
                throw error
            }
        }
        
        throw lastError ?? NotionError(code: "UNKNOWN_ERROR", message: "Unbekannter Fehler")
    }
    
    private func calculateDelay(
        for attempt: Int,
        baseDelay: TimeInterval,
        exponentialBackoff: Bool,
        retryAfter: TimeInterval? = nil
    ) -> TimeInterval {
        
        // Use server-provided retry-after if available
        if let retryAfter = retryAfter {
            return min(retryAfter, 60) // Cap at 60 seconds
        }
        
        // Exponential backoff
        if exponentialBackoff {
            return baseDelay * pow(2.0, Double(attempt))
        }
        
        // Fixed delay
        return baseDelay
    }
    
    // MARK: - Status Monitoring
    func getRateLimitStatus() -> RateLimitStatus {
        queue.sync {
            let now = Date()
            let recentRequests = requestTimes.filter { 
                now.timeIntervalSince($0) < 60 
            }
            
            return RateLimitStatus(
                requestsInLastMinute: recentRequests.count,
                maxRequestsPerMinute: Int(requestsPerMinute),
                requestsPerSecond: requestsPerSecond,
                canMakeRequest: recentRequests.count < Int(requestsPerMinute)
            )
        }
    }
}

// MARK: - Rate Limit Status
struct RateLimitStatus {
    let requestsInLastMinute: Int
    let maxRequestsPerMinute: Int
    let requestsPerSecond: Double
    let canMakeRequest: Bool
    
    var minuteUsagePercentage: Double {
        Double(requestsInLastMinute) / Double(maxRequestsPerMinute) * 100
    }
}

// MARK: - Enhanced Notion Integration mit Rate Limiting
extension NotionIntegration {
    private let rateLimiter = NotionRateLimiter()
    
    func getRateLimitStatus() -> RateLimitStatus {
        return rateLimiter.getRateLimitStatus()
    }
    
    func createDatabaseWithRetry(
        title: String,
        parentDatabaseId: String,
        properties: [String: NotionProperty]
    ) async throws -> NotionDatabase {
        
        return try await rateLimiter.executeWithRetry { [self] in
            return try await createDatabase(title: title, parentDatabaseId: parentDatabaseId, properties: properties)
        }
    }
    
    func queryDatabaseWithRetry(
        databaseId: String,
        filter: FilterObject? = nil,
        sorts: [SortObject]? = nil
    ) async throws -> ([NotionPage], String?, Bool) {
        
        return try await rateLimiter.executeWithRetry { [self] in
            return try await queryDatabase(databaseId: databaseId, filter: filter, sorts: sorts)
        }
    }
    
    func createPageWithRetry(
        databaseId: String,
        properties: [String: NotionPropertyValue],
        blocks: [NotionBlock]? = nil
    ) async throws -> NotionPage {
        
        return try await rateLimiter.executeWithRetry { [self] in
            return try await createPage(databaseId: databaseId, properties: properties, blocks: blocks)
        }
    }
    
    func updatePageWithRetry(
        pageId: String,
        properties: [String: NotionPropertyValue]
    ) async throws -> NotionPage {
        
        return try await rateLimiter.executeWithRetry { [self] in
            return try await updatePage(pageId: pageId, properties: properties)
        }
    }
    
    func searchWithRetry(
        query: String,
        filter: [String: Any]? = nil
    ) async throws -> ([SearchResult], String?, Bool) {
        
        return try await rateLimiter.executeWithRetry { [self] in
            return try await search(query: query, filter: filter)
        }
    }
    
    // MARK: - Batch Operations mit Rate Limiting
    func createMultiplePagesWithRetry(
        databaseId: String,
        pages: [(properties: [String: NotionPropertyValue], blocks: [NotionBlock]?)]
    ) async throws -> [NotionPage] {
        
        return try await rateLimiter.executeWithRetry(maxRetries: 2) { [self] in
            var results: [NotionPage] = []
            
            for (index, pageData) in pages.enumerated() {
                do {
                    let page = try await createPage(
                        databaseId: databaseId,
                        properties: pageData.properties,
                        blocks: pageData.blocks
                    )
                    results.append(page)
                    
                    // Progress callback
                    print("Erstelle Seite \(index + 1) von \(pages.count)")
                    
                } catch {
                    print("Fehler beim Erstellen der Seite \(index + 1): \(error)")
                    // Continue with next page, don't stop entire batch
                }
            }
            
            return results
        }
    }
}

// MARK: - Request Retry Decorator
class NotionRequestDecorator {
    private let rateLimiter: NotionRateLimiter
    
    init(rateLimiter: NotionRateLimiter = NotionRateLimiter()) {
        self.rateLimiter = rateLimiter
    }
    
    func executeRequest<T>(
        request: @escaping () async throws -> T,
        maxRetries: Int = 3
    ) async throws -> T {
        
        return try await rateLimiter.executeWithRetry(
            maxRetries: maxRetries,
            operation: request
        )
    }
    
    func executeBatchRequest<T>(
        requests: [() async throws -> T],
        batchName: String = "Batch Operation"
    ) async throws -> [T] {
        
        print("Starte Batch Operation: \(batchName)")
        
        return try await rateLimiter.executeWithRetry(maxRetries: 2) {
            var results: [T] = []
            var errorCount = 0
            
            for (index, request) in requests.enumerated() {
                do {
                    let result = try await request()
                    results.append(result)
                    print("Request \(index + 1) von \(requests.count) erfolgreich")
                    
                } catch {
                    errorCount += 1
                    print("Request \(index + 1) fehlgeschlagen: \(error)")
                    
                    // Continue with next request, don't stop entire batch
                }
                
                // Rate limiting between batch requests
                await rateLimiter.waitForRateLimit()
            }
            
            if errorCount > 0 {
                print("Batch Operation abgeschlossen mit \(errorCount) Fehlern")
            } else {
                print("Batch Operation erfolgreich abgeschlossen")
            }
            
            return results
        }
    }
}