//
//  CachedAsyncImage.swift
//  EchoNotes
//
//  Cached image loader for podcast and episode artwork
//

import SwiftUI

/// Image cache manager
class ImageCache {
    static let shared = ImageCache()

    private var cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200  // Increased from 100
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB (increased from 50 MB)
    }

    func get(_ url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }

    func set(_ image: UIImage, forKey url: String) {
        cache.setObject(image, forKey: url as NSString)
    }
}

/// Cached async image view with content and placeholder
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    init(
        url: String?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    /// Convenience initializer accepting URL?
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url?.absoluteString
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let urlString = url, !urlString.isEmpty, !isLoading else {
            return
        }

        // Check cache first
        if let cachedImage = ImageCache.shared.get(urlString) {
            loadedImage = cachedImage
            return
        }

        // Download image
        isLoading = true
        Task {
            guard let url = URL(string: urlString) else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }

                // Cache the image
                ImageCache.shared.set(image, forKey: urlString)

                await MainActor.run {
                    loadedImage = image
                    isLoading = false
                }
            } catch {
                print("Error loading image: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Convenience initializer for just placeholder (no content transformation)

extension CachedAsyncImage where Content == Image {
    /// Initialize with just a URL and placeholder - returns the image directly with proper sizing
    init(
        url: URL?,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url?.absoluteString
        self.content = { $0 }
        self.placeholder = placeholder
    }

    /// Initialize with just a String URL and placeholder
    init(
        url: String?,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = { $0 }
        self.placeholder = placeholder
    }
}

// MARK: - SimpleCachedAsyncImage for placeholder-only usage with built-in sizing

/// Simple cached image view that applies .resizable() and .aspectRatio(contentMode: .fill) automatically
struct SimpleCachedAsyncImage<Placeholder: View>: View {
    let url: String?
    let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url?.absoluteString
        self.placeholder = placeholder
    }

    init(
        url: String?,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let urlString = url, !urlString.isEmpty, !isLoading else {
            return
        }

        // Check cache first
        if let cachedImage = ImageCache.shared.get(urlString) {
            loadedImage = cachedImage
            return
        }

        // Download image
        isLoading = true
        Task {
            guard let url = URL(string: urlString) else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }

                // Cache the image
                ImageCache.shared.set(image, forKey: urlString)

                await MainActor.run {
                    loadedImage = image
                    isLoading = false
                }
            } catch {
                print("Error loading image: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - DataCacheManager for caching Codable data

/// Cache entry for storing data with expiration
struct CacheEntry<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    let expirationSeconds: TimeInterval

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expirationSeconds
    }
}

/// Data cache manager for caching Codable models
@MainActor
class DataCacheManager: ObservableObject {
    static let shared = DataCacheManager()

    enum CacheDuration {
        case short      // 5 minutes
        case medium     // 30 minutes
        case long       // 2 hours
        case persistent // 24 hours

        var seconds: TimeInterval {
            switch self {
            case .short: return 300
            case .medium: return 1800
            case .long: return 7200
            case .persistent: return 86400
            }
        }
    }

    private let diskCacheDirectory: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("DataCache")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        print("💾 [DataCache] Initialized")
        cleanExpiredEntries()
    }

    func get<T: Codable>(key: String, as type: T.Type) -> T? {
        let cacheKey = sanitizeKey(key)
        let fileURL = diskCacheDirectory.appendingPathComponent("\(cacheKey).json")

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let entry = try? decoder.decode(CacheEntry<T>.self, from: data) else {
            print("❌ [DataCache] Miss: \(cacheKey)")
            return nil
        }

        if entry.isExpired {
            print("⏰ [DataCache] Expired: \(cacheKey)")
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        print("✅ [DataCache] Hit: \(cacheKey)")
        return entry.data
    }

    func set<T: Codable>(key: String, value: T, duration: CacheDuration = .medium) {
        let cacheKey = sanitizeKey(key)
        let entry = CacheEntry(data: value, timestamp: Date(), expirationSeconds: duration.seconds)

        guard let data = try? encoder.encode(entry) else {
            print("❌ [DataCache] Failed to encode: \(cacheKey)")
            return
        }

        let fileURL = diskCacheDirectory.appendingPathComponent("\(cacheKey).json")
        try? data.write(to: fileURL, options: .atomic)
        print("💾 [DataCache] Saved: \(cacheKey) (expires in \(Int(duration.seconds))s)")
    }

    func remove(key: String) {
        let cacheKey = sanitizeKey(key)
        let fileURL = diskCacheDirectory.appendingPathComponent("\(cacheKey).json")
        try? FileManager.default.removeItem(at: fileURL)
        print("🗑️ [DataCache] Removed: \(cacheKey)")
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        print("🗑️ [DataCache] All cache cleared")
    }

    func cleanExpiredEntries() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: nil) else { return }

        var expiredCount = 0
        for fileURL in files {
            guard let data = try? Data(contentsOf: fileURL),
                  let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let timestampString = jsonDict["timestamp"] as? String,
                  let expirationSeconds = jsonDict["expirationSeconds"] as? TimeInterval else { continue }

            let formatter = ISO8601DateFormatter()
            guard let timestamp = formatter.date(from: timestampString),
                  Date().timeIntervalSince(timestamp) > expirationSeconds else { continue }

            try? FileManager.default.removeItem(at: fileURL)
            expiredCount += 1
        }

        if expiredCount > 0 {
            print("🧹 [DataCache] Cleaned \(expiredCount) expired entries")
        }
    }

    private func sanitizeKey(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
           .replacingOccurrences(of: ":", with: "_")
           .replacingOccurrences(of: "?", with: "_")
           .replacingOccurrences(of: "&", with: "_")
    }
}
