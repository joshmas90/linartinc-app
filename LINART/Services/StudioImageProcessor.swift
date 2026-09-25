import Foundation
import ImageIO
import UniformTypeIdentifiers

struct NormalizedStudioImage: Sendable {
    let full: Data
    let thumbnail: Data
}

enum StudioImageError: LocalizedError {
    case invalidImage, tooLarge
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "This photo could not be read. Choose a JPEG, HEIC or PNG image."
        case .tooLarge: return "Choose a photo smaller than 25 MB."
        }
    }
}

enum StudioImageProcessor {
    static func normalize(_ data: Data) throws -> NormalizedStudioImage {
        guard data.count <= 25_000_000 else { throw StudioImageError.tooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            throw StudioImageError.invalidImage
        }
        return try NormalizedStudioImage(full: thumbnail(source, pixels: 1600), thumbnail: thumbnail(source, pixels: 240))
    }

    private static func thumbnail(_ source: CGImageSource, pixels: Int) throws -> Data {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: pixels,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { throw StudioImageError.invalidImage }
        let result = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(result, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw StudioImageError.invalidImage
        }
        // Re-encoding a new CGImage omits the source's location and other EXIF metadata.
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw StudioImageError.invalidImage }
        return result as Data
    }
}
