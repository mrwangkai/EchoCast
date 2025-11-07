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
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    func get(_ url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }

    func set(_ image: UIImage, forKey url: String) {
        cache.setObject(image, forKey: url as NSString)
    }
}

/// Cached async image view
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
