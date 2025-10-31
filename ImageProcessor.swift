//
//  ImageProcessor.swift
//  Bildoptimierung für Apple Notes Attachments
//

import Foundation
import UIKit

@available(iOS 15.0, macOS 12.0, *)
class ImageProcessor {
    
    // MARK: - Bildoptimierung für Notes
    
    static func optimizeImageForNotes(_ imageData: Data, filename: String) async throws -> Data {
        
        let optimizedData = try await withThrowingTaskGroup(of: Data.self) { group in
            
            group.addTask {
                return try await optimizeImage(data: imageData, filename: filename, targetSize: .small)
            }
            
            group.addTask {
                return try await optimizeImage(data: imageData, filename: filename, targetSize: .medium)
            }
            
            group.addTask {
                return try await optimizeImage(data: imageData, filename: filename, targetSize: .large)
            }
            
            // Gib die mittlere Größe zurück
            guard let result = try await group.next() else {
                throw ImageProcessingError.optimizationFailed
            }
            
            return result
        }
        
        return optimizedData
    }
    
    static func optimizeImage(data: Data, filename: String, targetSize: ImageTargetSize) async throws -> Data {
        
        guard let image = UIImage(data: data) else {
            throw ImageProcessingError.invalidImageData
        }
        
        // Berechne Ziel-Dimensionen
        let targetDimensions = calculateTargetDimensions(for: image.size, targetSize: targetSize)
        
        // Skaliere das Bild
        let scaledImage = await scaleImage(image, to: targetDimensions)
        
        // Komprimiere mit passender Qualität
        let compressionQuality = getCompressionQuality(for: targetSize)
        
        // Konvertiere zu Data mit optimierter Format
        let optimizedData = scaledImage.jpegData(compressionQuality: compressionQuality) ??
                           scaledImage.pngData()
        
        guard let result = optimizedData else {
            throw ImageProcessingError.compressionFailed
        }
        
        return result
    }
    
    // MARK: - Bild-Kategorisierung
    
    static func categorizeImage(_ imageData: Data, filename: String) -> ImageCategory {
        
        let lowercasedFilename = filename.lowercased()
        
        // Kategorien basierend auf Dateinamen
        if lowercasedFilename.contains("screenshot") || lowercasedFilename.contains("bildschirm") {
            return .screenshot
        }
        
        if lowercasedFilename.contains("photo") || lowercasedFilename.contains("bild") {
            return .photo
        }
        
        if lowercasedFilename.contains("document") || lowercasedFilename.contains("dokument") {
            return .document
        }
        
        if lowercasedFilename.contains("qr") {
            return .qrCode
        }
        
        if lowercasedFilename.contains("graph") || lowercasedFilename.contains("chart") {
            return .chart
        }
        
        // Fallback basierend auf Dateigröße
        if imageData.count > 5_000_000 { // > 5MB
            return .largeImage
        } else if imageData.count < 100_000 { // < 100KB
            return .smallImage
        }
        
        return .general
    }
    
    // MARK: - Attachment-Erstellung für Notes
    
    static func createAttachmentForNotes(from imageData: Data, filename: String) async throws -> AppleNotesAttachment {
        
        // Optimiere Bild für Notes
        let optimizedData = try await optimizeImageForNotes(imageData, filename: filename)
        
        // Bestimme MIME Type
        let mimeType = determineMimeType(for: filename)
        
        // Kategorisiere Bild für bessere Organisation
        let category = categorizeImage(imageData, filename: filename)
        
        return AppleNotesAttachment(
            filename: filename,
            data: optimizedData,
            mimeType: mimeType
        )
    }
    
    // MARK: - Batch-Verarbeitung
    
    static func processMultipleImages(_ imageDatas: [(Data, String)]) async throws -> [AppleNotesAttachment] {
        
        return try await withThrowingTaskGroup(of: AppleNotesAttachment.self) { group in
            
            for (imageData, filename) in imageDatas {
                group.addTask {
                    return try await createAttachmentForNotes(from: imageData, filename: filename)
                }
            }
            
            var attachments: [AppleNotesAttachment] = []
            
            for try await attachment in group {
                attachments.append(attachment)
            }
            
            return attachments
        }
    }
    
    // MARK: - Private Helper Methods
    
    private static func calculateTargetDimensions(for originalSize: CGSize, targetSize: ImageTargetSize) -> CGSize {
        
        let maxDimension: CGFloat
        let maintainAspectRatio = true
        
        switch targetSize {
        case .small:
            maxDimension = 800
        case .medium:
            maxDimension = 1500
        case .large:
            maxDimension = 2500
        }
        
        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
        
        if maintainAspectRatio {
            return CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        } else {
            return CGSize(width: maxDimension, height: maxDimension)
        }
    }
    
    private static func scaleImage(_ image: UIImage, to targetSize: CGSize) async -> UIImage {
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                
                // Erstelle neuen Image Context
                UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
                
                // Zeichne das Bild neu
                image.draw(in: CGRect(origin: .zero, size: targetSize))
                
                // Hole das skalierte Bild
                let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                DispatchQueue.main.async {
                    continuation.resume(returning: scaledImage ?? image)
                }
            }
        }
    }
    
    private static func getCompressionQuality(for targetSize: ImageTargetSize) -> CGFloat {
        
        switch targetSize {
        case .small:
            return 0.8
        case .medium:
            return 0.75
        case .large:
            return 0.7
        }
    }
    
    private static func determineMimeType(for filename: String) -> String {
        
        let fileExtension = filename.lowercased().components(separatedBy: ".").last ?? ""
        
        switch fileExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "bmp":
            return "image/bmp"
        default:
            return "application/octet-stream"
        }
    }
    
    // MARK: - Format-Konvertierung
    
    static func convertImageFormat(_ imageData: Data, from format: ImageFormat, to targetFormat: ImageFormat, quality: CGFloat = 0.8) async throws -> Data {
        
        guard let image = UIImage(data: imageData) else {
            throw ImageProcessingError.invalidImageData
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                
                var convertedData: Data?
                
                switch targetFormat {
                case .jpeg:
                    convertedData = image.jpegData(compressionQuality: quality)
                case .png:
                    convertedData = image.pngData()
                case .webp:
                    if #available(iOS 14.0, *) {
                        convertedData = image.webData(from: quality)
                    }
                }
                
                DispatchQueue.main.async {
                    if let data = convertedData {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: ImageProcessingError.conversionFailed)
                    }
                }
            }
        }
    }
    
    // MARK: - Metadaten-Extraktion
    
    static func extractImageMetadata(_ imageData: Data) async throws -> ImageMetadata {
        
        guard let image = UIImage(data: imageData) else {
            throw ImageProcessingError.invalidImageData
        }
        
        return ImageMetadata(
            width: Int(image.size.width),
            height: Int(image.size.height),
            fileSize: imageData.count,
            format: detectImageFormat(imageData),
            hasAlphaChannel: image.cgImage?.alphaInfo != .none
        )
    }
    
    private static func detectImageFormat(_ imageData: Data) -> ImageFormat {
        
        // Prüfe Magic Numbers für verschiedene Bildformate
        if imageData.count >= 4 {
            let bytes = imageData.prefix(4)
            
            if bytes == Data([0xFF, 0xD8, 0xFF]) {
                return .jpeg
            }
            
            if bytes == Data([0x89, 0x50, 0x4E, 0x47]) {
                return .png
            }
            
            if bytes == Data([0x47, 0x49, 0x46, 0x38]) {
                return .gif
            }
            
            if bytes == Data([0x52, 0x49, 0x46, 0x46]) {
                return .webp
            }
        }
        
        return .unknown
    }
}

// MARK: - Supporting Types

enum ImageTargetSize {
    case small
    case medium
    case large
}

enum ImageCategory {
    case screenshot
    case photo
    case document
    case qrCode
    case chart
    case largeImage
    case smallImage
    case general
}

enum ImageFormat {
    case jpeg
    case png
    case gif
    case webp
    case unknown
}

struct ImageMetadata {
    let width: Int
    let height: Int
    let fileSize: Int
    let format: ImageFormat
    let hasAlphaChannel: Bool
}

enum ImageProcessingError: Error, LocalizedError {
    case invalidImageData
    case compressionFailed
    case conversionFailed
    case optimizationFailed
    case unsupportedFormat
    case fileTooLarge
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Ungültige Bilddaten"
        case .compressionFailed:
            return "Bildkomprimierung fehlgeschlagen"
        case .conversionFailed:
            return "Format-Konvertierung fehlgeschlagen"
        case .optimizationFailed:
            return "Bildoptimierung fehlgeschlagen"
        case .unsupportedFormat:
            return "Nicht unterstütztes Bildformat"
        case .fileTooLarge:
            return "Datei zu groß für Verarbeitung"
        }
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    
    @available(iOS 14.0, *)
    func webData(from quality: CGFloat) -> Data? {
        // WebP Konvertierung würde hier implementiert werden
        // Für jetzt fallback zu JPEG
        return self.jpegData(compressionQuality: quality)
    }
}