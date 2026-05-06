//
//  ImageCache.swift
//  Road Tribe
//

import UIKit

/// NSCache-backed image cache to avoid repeated JPEG/PNG decompression during scroll.
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSNumber, UIImage>()

    private init() {
        cache.countLimit = 80
    }

    /// Returns a cached UIImage for the given data, decoding and force-decompressing on first access.
    func image(from data: Data) -> UIImage? {
        let key = NSNumber(value: data.hashValue)
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let image = UIImage(data: data) else { return nil }
        let decompressed = Self.forceDecompress(image)
        cache.setObject(decompressed, forKey: key)
        return decompressed
    }

    /// Force-decompresses a UIImage so pixel data is ready before the GPU needs it.
    /// Prevents frame drops when images first appear on screen.
    private static func forceDecompress(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
        }
    }
}
