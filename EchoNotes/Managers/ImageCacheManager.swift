//
//  ImageCacheManager.swift
//  EchoNotes
//
//  Production-ready image caching using:
//  - NSCache (Apple standard) for memory layer
//  - Custom disk caching for persistence
//

import SwiftUI
import Foundation

@MainActor
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()

    // MARK: - Memory Cache (Apple's NSCache)
    private let memoryCache = NSCache<NSString, UIImage>()

    // MARK: - Disk Cache (Custom persistence)
    private let diskCacheDirectory: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("PodcastArtwork")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()

    private init() {
        // Configure NSCache limits
        memoryCache.countLimit = 50              // Max 50 images
        memoryCache.totalCostLimit = 50_000_000  // 50 MB

        print("🖼️ [ImageCache] Initialized with NSCache (Apple) + disk persistence")
        print("🖼️ [ImageCache] Cache dir: \(diskCacheDirectory.path)")
    }

    // MARK: - Public API

    /// Get cached image from memory or disk
    func getCachedImage(for urlString: String) -> UIImage? {
        let cacheKey = urlString as NSString

        // Check NSCache first (Apple's standard - super fast)
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            print("✅ [ImageCache] NSCache hit (memory)")
            return cachedImage
        }

        // Check disk cache (custom logic)
        let diskKey = cacheKey(from: urlString)
        if let diskImage = loadFromDisk(cacheKey: diskKey) {
            print("💾 [ImageCache] Disk hit - loading to NSCache")

            // Store in NSCache for faster next access
            let cost = Int(diskImage.size.width * diskImage.size.height * 4)
            memoryCache.setObject(diskImage, forKey: cacheKey, cost: cost)

            return diskImage
        }

        print("❌ [ImageCache] Cache miss: \(diskKey)")
        return nil
    }

    /// Save image to both memory (NSCache) and disk
    func cacheImage(_ image: UIImage, for urlString: String) {
        let cacheKey = urlString as NSString

        // Save to NSCache (Apple's standard)
        let cost = Int(image.size.width * image.size.height * 4)
        memoryCache.setObject(image, forKey: cacheKey, cost: cost)

        // Save to disk asynchronously (custom persistence)
        let diskKey = self.cacheKey(from: urlString)
        Task.detached(priority: .background) {
            await self.saveToDisk(image: image, cacheKey: diskKey)
        }

        print("💾 [ImageCache] Cached in NSCache + queued for disk")
    }

    /// Clear all cached images
    func clearCache() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        print("🗑️ [ImageCache] All caches cleared")
    }

    // MARK: - Private Helpers

    private func cacheKey(from urlString: String) -> String {
        urlString.hash.description
    }

    private func diskCacheURL(for cacheKey: String) -> URL {
        diskCacheDirectory.appendingPathComponent("\(cacheKey).jpg")
    }

    private func loadFromDisk(cacheKey: String) -> UIImage? {
        let fileURL = diskCacheURL(for: cacheKey)

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }

        return image
    }

    private func saveToDisk(image: UIImage, cacheKey: String) async {
        let fileURL = diskCacheURL(for: cacheKey)

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("⚠️ [ImageCache] Failed to convert image to JPEG data")
            return
        }

        do {
            try imageData.write(to: fileURL, options: .atomic)
            print("💾 [ImageCache] Saved to disk: \(cacheKey)")
        } catch {
            print("❌ [ImageCache] Disk save failed: \(error)")
        }
    }
}

// MARK: - Cached AsyncImage View

/// Drop-in replacement for AsyncImage with built-in caching
struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @StateObject private var cacheManager = ImageCacheManager.shared
    @State private var cachedImage: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                placeholder()
            } else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard let url = url else { return }

        // Check cache first
        if let cached = cacheManager.getCachedImage(for: url.absoluteString) {
            cachedImage = cached
            return
        }

        // Download if not cached
        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let image = UIImage(data: data) {
                // Cache the image
                await MainActor.run {
                    cacheManager.cacheImage(image, for: url.absoluteString)
                    cachedImage = image
                }
            }
        } catch {
            print("❌ [CachedAsyncImage] Failed to load: \(error)")
        }
    }
}

// MARK: - Convenience Initializer

extension CachedAsyncImage where Placeholder == Color {
    init(url: URL?) {
        self.init(url: url) {
            Color.gray.opacity(0.2)
        }
    }
}
