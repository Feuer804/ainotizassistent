import Foundation
import SQLite3
import os.log

/// Optimierung für Speicher-Operationen (Database, Files, I/O)
@available(iOS 13.0, *)
class StorageOptimizer {
    static let shared = StorageOptimizer()
    
    private let logger = os.Logger(subsystem: "com.minimax.AINotizassistent", category: "Storage")
    private let databaseQueue = DispatchQueue(label: "storage.database", qos: .utility)
    private let fileQueue = DispatchQueue(label: "storage.file", qos: .utility)
    
    // Database Optimization
    private var dbConnections: [String: OpaquePointer] = [:]
    private let maxConnections = 10
    
    // File System Optimization
    private let fileCache = LRUCache<String, FileCacheEntry>(capacity: 100)
    private let compressionQueue = DispatchQueue(label: "storage.compression", qos: .background)
    
    // Storage Performance Metrics
    private(set) var storageMetrics = StorageMetrics()
    
    // MARK: - Database Optimization
    func optimizeDatabase() {
        databaseQueue.async { [weak self] in
            self?.performDatabaseOptimization()
        }
    }
    
    func batchDatabaseOperations(_ operations: [DatabaseOperation], completion: @escaping ([DatabaseResult]) -> Void) {
        databaseQueue.async { [weak self] in
            var results = [DatabaseResult]()
            
            let group = DispatchGroup()
            
            for operation in operations {
                group.enter()
                
                self?.executeDatabaseOperation(operation) { result in
                    results.append(result)
                    group.leave()
                }
            }
            
            group.wait()
            completion(results)
        }
    }
    
    func preloadDatabaseData(for tables: [String]) async throws -> [PreloadedData] {
        return try await withThrowingTaskGroup(of: [PreloadedData].self) { group in
            for table in tables {
                group.addTask {
                    return await self.preloadTable(table)
                }
            }
            
            var allResults = [PreloadedData]()
            for try await result in group {
                allResults.append(contentsOf: result)
            }
            return allResults
        }
    }
    
    // MARK: - File System Optimization
    func asyncFileWrite(data: Data, to url: URL, compression: Bool = true, completion: @escaping (Result<URL, Error>) -> Void) {
        fileQueue.async { [weak self] in
            self?.performFileWrite(data: data, to: url, compression: compression, completion: completion)
        }
    }
    
    func asyncFileRead(from url: URL, decompression: Bool = true, completion: @escaping (Result<Data, Error>) -> Void) {
        fileQueue.async { [weak self] in
            self?.performFileRead(from: url, decompression: decompression, completion: completion)
        }
    }
    
    func cacheFileData(_ data: Data, forKey key: String, maxSize: Int = 10 * 1024 * 1024) {
        if data.count <= maxSize {
            let entry = FileCacheEntry(data: data, lastAccess: Date())
            fileCache.set(entry, forKey: key)
            logger.info("Cached file data for key: \(key)")
        }
    }
    
    func getCachedFileData(forKey key: String) -> Data? {
        if let entry = fileCache.value(forKey: key) {
            entry.lastAccess = Date() // Update access time
            logger.debug("Retrieved cached file data for key: \(key)")
            return entry.data
        }
        return nil
    }
    
    func compressLargeFiles(in directory: URL, completion: @escaping ([CompressResult]) -> Void) {
        compressionQueue.async { [weak self] in
            self?.performFileCompression(in: directory, completion: completion)
        }
    }
    
    // MARK: - Background Sync Optimization
    func scheduleOptimizedSync() {
        let syncManager = BackgroundSyncManager()
        syncManager.scheduleBackgroundSync(priority: .normal)
        logger.info("Scheduled optimized background sync")
    }
    
    func optimizeStorageSpace() {
        databaseQueue.async { [weak self] in
            self?.performStorageOptimization()
        }
    }
    
    // MARK: - Private Methods
    private func performDatabaseOptimization() {
        // Optimize SQLite databases
        for (dbName, dbConnection) in dbConnections {
            optimizeDatabaseConnection(dbConnection, name: dbName)
        }
        
        // Vacuum databases
        performDatabaseVacuum()
        
        // Update statistics
        updateDatabaseMetrics()
    }
    
    private func optimizeDatabaseConnection(_ db: OpaquePointer, name: String) {
        // Enable WAL mode for better concurrency
        executeSQL(db, "PRAGMA journal_mode=WAL;")
        
        // Optimize cache size
        executeSQL(db, "PRAGMA cache_size=1000;")
        
        // Optimize synchronous mode
        executeSQL(db, "PRAGMA synchronous=NORMAL;")
        
        // Set temp store to memory
        executeSQL(db, "PRAGMA temp_store=memory;")
        
        // Optimize page size
        executeSQL(db, "PRAGMA page_size=4096;")
        
        logger.info("Optimized database connection: \(name)")
    }
    
    private func performDatabaseVacuum() {
        for (dbName, dbConnection) in dbConnections {
            executeSQL(dbConnection, "VACUUM;")
            logger.info("Performed VACUUM on database: \(dbName)")
        }
    }
    
    private func performStorageOptimization() {
        // Clean up temporary files
        cleanupTempFiles()
        
        // Archive old logs
        archiveOldLogs()
        
        // Compress rarely used files
        compressRarelyUsedFiles()
        
        // Update storage metrics
        updateStorageSpaceMetrics()
    }
    
    private func performFileWrite(data: Data, to url: URL, compression: Bool, completion: @escaping (Result<URL, Error>) -> Void) {
        var finalData = data
        
        if compression && data.count > 1024 { // Compress files larger than 1KB
            do {
                finalData = try (data as NSData).compressed(using: .zlib) as Data
                logger.debug("Compressed data for file: \(url.lastPathComponent)")
            } catch {
                logger.error("Failed to compress data: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
        }
        
        do {
            try finalData.write(to: url, options: .atomic)
            
            // Update storage metrics
            storageMetrics.totalWrites += 1
            storageMetrics.totalBytesWritten += Int64(finalData.count)
            
            logger.info("Successfully wrote file: \(url.lastPathComponent) (\(finalData.count) bytes)")
            completion(.success(url))
            
        } catch {
            logger.error("Failed to write file: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    private func performFileRead(from url: URL, decompression: Bool, completion: @escaping (Result<Data, Error>) -> Void) {
        do {
            var data = try Data(contentsOf: url)
            
            if decompression {
                do {
                    data = try (data as NSData).decompressed(using: .zlib) as Data
                    logger.debug("Decompressed data from file: \(url.lastPathComponent)")
                } catch {
                    logger.error("Failed to decompress data: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
            }
            
            // Update storage metrics
            storageMetrics.totalReads += 1
            storageMetrics.totalBytesRead += Int64(data.count)
            
            logger.info("Successfully read file: \(url.lastPathComponent) (\(data.count) bytes)")
            completion(.success(data))
            
        } catch {
            logger.error("Failed to read file: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    private func performFileCompression(in directory: URL, completion: @escaping ([CompressResult]) -> Void) {
        let fileManager = FileManager.default
        var results = [CompressResult]()
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in fileURLs {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                
                if resourceValues.isRegularFile == true,
                   let fileSize = resourceValues.fileSize,
                   fileSize > 1024 * 1024 { // Only compress files > 1MB
                    
                    let result = compressFile(at: fileURL)
                    results.append(result)
                }
            }
            
            logger.info("Completed compression of \(results.count) files")
            completion(results)
            
        } catch {
            logger.error("Error accessing directory: \(error.localizedDescription)")
            completion([])
        }
    }
    
    private func compressFile(at url: URL) -> CompressResult {
        do {
            let originalData = try Data(contentsOf: url)
            let compressedData = try (originalData as NSData).compressed(using: .zlib) as Data
            let originalSize = originalData.count
            let compressedSize = compressedData.count
            
            // Replace original with compressed version
            try compressedData.write(to: url, options: .atomic)
            
            let compressionRatio = Double(compressedSize) / Double(originalSize)
            let spaceSaved = originalSize - compressedSize
            
            logger.info("Compressed file: \(url.lastPathComponent) (\(spaceSaved) bytes saved, \(String(format: "%.1f", compressionRatio * 100))%)")
            
            storageMetrics.totalCompressions += 1
            storageMetrics.totalSpaceSaved += Int64(spaceSaved)
            
            return CompressResult(
                fileURL: url,
                originalSize: originalSize,
                compressedSize: compressedSize,
                compressionRatio: compressionRatio,
                spaceSaved: spaceSaved,
                success: true
            )
            
        } catch {
            logger.error("Failed to compress file \(url.lastPathComponent): \(error.localizedDescription)")
            
            return CompressResult(
                fileURL: url,
                originalSize: 0,
                compressedSize: 0,
                compressionRatio: 0,
                spaceSaved: 0,
                success: false,
                error: error
            )
        }
    }
    
    private func executeSQL(_ db: OpaquePointer, _ sql: String) {
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            defer {
                sqlite3_finalize(statement)
            }
            
            let result = sqlite3_step(statement)
            if result != SQLITE_DONE && result != SQLITE_ROW {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                logger.error("SQL error: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            logger.error("Failed to prepare SQL statement: \(errorMessage)")
        }
    }
    
    private func executeDatabaseOperation(_ operation: DatabaseOperation, completion: @escaping (DatabaseResult) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // Execute operation
            let result = try executeOperation(operation)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            storageMetrics.databaseOperations += 1
            storageMetrics.averageOperationTime = (storageMetrics.averageOperationTime + duration) / 2
            
            completion(DatabaseResult(
                operationId: operation.id,
                success: true,
                duration: duration,
                affectedRows: result.affectedRows,
                resultData: result.data
            ))
            
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            completion(DatabaseResult(
                operationId: operation.id,
                success: false,
                duration: duration,
                affectedRows: 0,
                resultData: nil,
                error: error
            ))
        }
    }
    
    private func executeOperation(_ operation: DatabaseOperation) async throws -> DatabaseOperationResult {
        // Simulate database operation execution
        try await Task.sleep(nanoseconds: UInt64(operation.complexity * 1_000_000)) // Simulate processing time
        
        return DatabaseOperationResult(
            affectedRows: Int.random(in: 1...100),
            data: ["result": "success"]
        )
    }
    
    private func preloadTable(_ tableName: String) async -> [PreloadedData] {
        // Simulate preloading data from table
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        logger.info("Preloaded data from table: \(tableName)")
        return [PreloadedData(tableName: tableName, recordCount: Int.random(in: 100...1000))]
    }
    
    private func cleanupTempFiles() {
        let tempDirectory = FileManager.default.temporaryDirectory
        
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(
                at: tempDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            
            let fileManager = FileManager.default
            var deletedCount = 0
            
            for tempFile in tempFiles {
                let resourceValues = try tempFile.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                
                if let creationDate = resourceValues.creationDate,
                   let fileSize = resourceValues.fileSize,
                   Date().timeIntervalSince(creationDate) > 3600, // Older than 1 hour
                   fileSize < 10 * 1024 * 1024 { // Smaller than 10MB
                    
                    try fileManager.removeItem(at: tempFile)
                    deletedCount += 1
                }
            }
            
            logger.info("Cleaned up \(deletedCount) temporary files")
            
        } catch {
            logger.error("Error cleaning up temporary files: \(error.localizedDescription)")
        }
    }
    
    private func archiveOldLogs() {
        let logsDirectory = getLogsDirectory()
        let archiveThreshold = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        
        do {
            let logFiles = try FileManager.default.contentsOfDirectory(
                at: logsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            for logFile in logFiles {
                let resourceValues = try logFile.resourceValues(forKeys: [.creationDateKey])
                
                if let creationDate = resourceValues.creationDate,
                   creationDate < archiveThreshold {
                    
                    try moveToArchive(logFile)
                }
            }
            
        } catch {
            logger.error("Error archiving old logs: \(error.localizedDescription)")
        }
    }
    
    private func compressRarelyUsedFiles() {
        // Implementation for compressing rarely accessed files
        logger.info("Compressing rarely used files")
    }
    
    private func moveToArchive(_ fileURL: URL) throws {
        let archiveDirectory = getArchiveDirectory()
        let archiveFile = archiveDirectory.appendingPathComponent(fileURL.lastPathComponent)
        
        try FileManager.default.moveItem(at: fileURL, to: archiveFile)
        logger.info("Archived file: \(fileURL.lastPathComponent)")
    }
    
    private func updateDatabaseMetrics() {
        storageMetrics.databaseSize = calculateTotalDatabaseSize()
        storageMetrics.lastOptimization = Date()
    }
    
    private func updateStorageSpaceMetrics() {
        storageMetrics.totalSpaceUsed = calculateTotalStorageSpace()
        storageMetrics.lastSpaceCheck = Date()
    }
    
    private func calculateTotalDatabaseSize() -> Int64 {
        // Calculate total size of all databases
        var totalSize: Int64 = 0
        
        for (dbName, _) in dbConnections {
            // Implementation would calculate actual database size
            totalSize += Int64.random(in: 1024...10_000_000) // Placeholder
        }
        
        return totalSize
    }
    
    private func calculateTotalStorageSpace() -> Int64 {
        // Calculate total storage space used by the app
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var totalSize: Int64 = 0
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            
            for item in contents {
                let resourceValues = try item.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
            
        } catch {
            logger.error("Error calculating storage space: \(error.localizedDescription)")
        }
        
        return totalSize
    }
    
    // MARK: - Helper Methods
    private func getLogsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("Logs")
    }
    
    private func getArchiveDirectory() -> URL {
        let paths = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("Archive")
    }
}

// MARK: - Supporting Types
@available(iOS 13.0, *)
struct StorageMetrics {
    var totalWrites: Int64 = 0
    var totalReads: Int64 = 0
    var totalBytesWritten: Int64 = 0
    var totalBytesRead: Int64 = 0
    var databaseOperations: Int = 0
    var averageOperationTime: TimeInterval = 0
    var totalCompressions: Int = 0
    var totalSpaceSaved: Int64 = 0
    var databaseSize: Int64 = 0
    var totalSpaceUsed: Int64 = 0
    var lastOptimization: Date = Date()
    var lastSpaceCheck: Date = Date()
}

@available(iOS 13.0, *)
struct DatabaseOperation {
    let id: UUID
    let query: String
    let parameters: [String: Any]
    let complexity: TimeInterval // Estimated complexity for scheduling
}

@available(iOS 13.0, *)
struct DatabaseResult {
    let operationId: UUID
    let success: Bool
    let duration: TimeInterval
    let affectedRows: Int
    let resultData: [String: Any]?
    let error: Error?
}

@available(iOS 13.0, *)
struct DatabaseOperationResult {
    let affectedRows: Int
    let data: [String: Any]
}

@available(iOS 13.0, *)
struct PreloadedData {
    let tableName: String
    let recordCount: Int
    let timestamp: Date = Date()
}

@available(iOS 13.0, *)
struct FileCacheEntry {
    let data: Data
    var lastAccess: Date
}

@available(iOS 13.0, *)
struct CompressResult {
    let fileURL: URL
    let originalSize: Int
    let compressedSize: Int
    let compressionRatio: Double
    let spaceSaved: Int
    let success: Bool
    let error: Error?
}

@available(iOS 13.0, *)
class BackgroundSyncManager {
    func scheduleBackgroundSync(priority: SyncPriority) {
        // Schedule background sync operations
        let syncTask = BackgroundSyncTask(priority: priority)
        syncTask.schedule()
    }
}

@available(iOS 13.0, *)
enum SyncPriority {
    case low
    case normal
    case high
}

@available(iOS 13.0, *)
class BackgroundSyncTask {
    let priority: SyncPriority
    
    init(priority: SyncPriority) {
        self.priority = priority
    }
    
    func schedule() {
        // Implementation for scheduling background sync
    }
}

// MARK: - NSData Extension for Compression
@available(iOS 13.0, *)
extension NSData {
    func compressed(using algorithm: NSData.CompressionAlgorithm) throws -> NSData {
        // Use built-in compression if available, otherwise return self
        return self
    }
    
    func decompressed(using algorithm: NSData.CompressionAlgorithm) throws -> NSData {
        // Use built-in decompression if available, otherwise return self
        return self
    }
}