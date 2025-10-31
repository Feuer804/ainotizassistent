//
//  PromptCache.swift
//  Intelligente Notizen App
//

import Foundation

// MARK: - Prompt Cache Protocol
protocol PromptCacheProtocol: AnyObject {
    func cache(_ prompt: String, key: String) async
    func getCachedPrompt(for key: String) async -> String?
    func clearCache() async
    func getCacheStats() async -> CacheStats
    func removeCachedPrompt(for key: String) async
}

// MARK: - Prompt Cache Implementation
final class PromptCache: PromptCacheProtocol {
    
    private let memoryCache = NSCache<NSString, CachedPrompt>()
    private let diskCache = DiskPromptCache()
    private let maxMemoryCacheSize = 50 // Maximum cached prompts in memory
    private let maxCacheAge: TimeInterval = 3600 * 24 * 7 // 7 days
    
    init() {
        memoryCache.countLimit = maxMemoryCacheSize
        memoryCache.totalCostLimit = 1024 * 1024 * 10 // 10MB
    }
    
    func cache(_ prompt: String, key: String) async {
        let cachedPrompt = CachedPrompt(
            prompt: prompt,
            timestamp: Date(),
            key: key,
            size: prompt.count
        )
        
        // Store in memory cache
        memoryCache.setObject(cachedPrompt, forKey: NSString(string: key))
        
        // Store in disk cache asynchronously
        await diskCache.cache(prompt, key: key)
        
        // Clean up old entries
        await cleanupCache()
    }
    
    func getCachedPrompt(for key: String) async -> String? {
        // Try memory cache first
        if let cachedPrompt = memoryCache.object(forKey: NSString(string: key)) {
            // Check if cache is still valid
            if Date().timeIntervalSince(cachedPrompt.timestamp) < maxCacheAge {
                return cachedPrompt.prompt
            } else {
                // Remove expired entry
                memoryCache.removeObject(forKey: NSString(string: key))
                await diskCache.removeCachedPrompt(for: key)
            }
        }
        
        // Try disk cache
        return await diskCache.getCachedPrompt(for: key)
    }
    
    func clearCache() async {
        memoryCache.removeAllObjects()
        await diskCache.clearCache()
    }
    
    func getCacheStats() async -> CacheStats {
        let memoryCount = memoryCache.countLimit
        let diskCount = await diskCache.getCachedPromptCount()
        
        return CacheStats(
            memoryCacheCount: memoryCount,
            diskCacheCount: diskCount,
            maxMemoryCacheSize: maxMemoryCacheSize,
            maxCacheAge: maxCacheAge
        )
    }
    
    func removeCachedPrompt(for key: String) async {
        memoryCache.removeObject(forKey: NSString(string: key))
        await diskCache.removeCachedPrompt(for: key)
    }
    
    private func cleanupCache() async {
        // Clean up expired entries from memory cache
        let allKeys = memoryCache.objectEnumerator()?.allObjects as? [NSString] ?? []
        
        for key in allKeys {
            if let cachedPrompt = memoryCache.object(forKey: key) {
                if Date().timeIntervalSince(cachedPrompt.timestamp) > maxCacheAge {
                    memoryCache.removeObject(forKey: key)
                }
            }
        }
        
        // Clean up disk cache
        await diskCache.cleanupExpiredEntries()
    }
}

// MARK: - Cached Prompt Model
class CachedPrompt: NSObject, NSCoding {
    let prompt: String
    let timestamp: Date
    let key: String
    let size: Int
    
    init(prompt: String, timestamp: Date, key: String, size: Int) {
        self.prompt = prompt
        self.timestamp = timestamp
        self.key = key
        self.size = size
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(prompt, forKey: "prompt")
        coder.encode(timestamp, forKey: "timestamp")
        coder.encode(key, forKey: "key")
        coder.encode(size, forKey: "size")
    }
    
    required init?(coder: NSCoder) {
        prompt = coder.decodeObject(forKey: "prompt") as? String ?? ""
        timestamp = coder.decodeObject(forKey: "timestamp") as? Date ?? Date()
        key = coder.decodeObject(forKey: "key") as? String ?? ""
        size = coder.decodeInteger(forKey: "size")
    }
}

// MARK: - Disk Cache
final class DiskPromptCache {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("PromptCache")
        
        createCacheDirectoryIfNeeded()
    }
    
    func cache(_ prompt: String, key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        do {
            let data = try JSONEncoder().encode(CacheFile(prompt: prompt, timestamp: Date()))
            try data.write(to: fileURL)
        } catch {
            print("Failed to cache prompt to disk: \(error)")
        }
    }
    
    func getCachedPrompt(for key: String) async -> String? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let cacheFile = try JSONDecoder().decode(CacheFile.self, from: data)
            
            // Check if cache is still valid (7 days)
            let maxAge: TimeInterval = 3600 * 24 * 7
            if Date().timeIntervalSince(cacheFile.timestamp) > maxAge {
                try fileManager.removeItem(at: fileURL)
                return nil
            }
            
            return cacheFile.prompt
        } catch {
            print("Failed to read cached prompt: \(error)")
            return nil
        }
    }
    
    func clearCache() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
    
    func getCachedPromptCount() -> Int {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            return files.count
        } catch {
            return 0
        }
    }
    
    func removeCachedPrompt(for key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            print("Failed to remove cached prompt: \(error)")
        }
    }
    
    func cleanupExpiredEntries() async {
        let maxAge: TimeInterval = 3600 * 24 * 7 // 7 days
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            for file in files {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let modificationDate = attributes[.modificationDate] as? Date {
                    
                    if Date().timeIntervalSince(modificationDate) > maxAge {
                        try fileManager.removeItem(at: file)
                    }
                }
            }
        } catch {
            print("Failed to cleanup expired cache entries: \(error)")
        }
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Cache File Model
struct CacheFile: Codable {
    let prompt: String
    let timestamp: Date
}

// MARK: - Cache Statistics
struct CacheStats {
    let memoryCacheCount: Int
    let diskCacheCount: Int
    let maxMemoryCacheSize: Int
    let maxCacheAge: TimeInterval
    
    var hitRate: Double {
        // Calculate cache hit rate (would need hit/miss tracking for real implementation)
        return 0.85 // Placeholder
    }
    
    var totalEntries: Int {
        return memoryCacheCount + diskCacheCount
    }
    
    var cacheSize: String {
        let totalSize = memoryCacheCount + diskCacheCount
        if totalSize < 1000 {
            return "\(totalSize) entries"
        } else {
            return String(format: "%.1fK entries", Double(totalSize) / 1000.0)
        }
    }
}