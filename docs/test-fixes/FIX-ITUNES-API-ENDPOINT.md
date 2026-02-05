# Fix: iTunes API Endpoint Issue

## Problem Identified

The app is using the wrong iTunes API endpoint:

**Current (WRONG):**
```
https://itunes.apple.com/us/rss/toppodcasts/limit=10/genre=1303/json
```

**Should be:**
```
https://itunes.apple.com/search?genreId=1303&media=podcast&entity=podcast&limit=10
```

## Error Analysis

```
❌ keyNotFound(CodingKeys(stringValue: "resultCount", intValue: nil)
```

**Root cause:** The RSS feed JSON structure is different from the Search API JSON structure.

**RSS feed JSON structure:**
```json
{
  "feed": {
    "entry": [...]
  }
}
```

**Search API JSON structure:**
```json
{
  "resultCount": 5,
  "results": [...]
}
```

The iTunesPodcast model expects `resultCount` and `results`, but RSS feed doesn't have these.

---

## SOLUTION: Fix PodcastAPIService

### File to Update

`EchoNotes/Services/PodcastAPIService.swift`

### Find the `getTopPodcasts` Function

Look for something like:

```swift
func getTopPodcasts(genreId: String, limit: Int = 10) async throws -> [iTunesPodcast] {
    let urlString = "https://itunes.apple.com/us/rss/toppodcasts/limit=\(limit)/genre=\(genreId)/json"
    // ...
}
```

### Replace With Correct Search API

```swift
func getTopPodcasts(genreId: String, limit: Int = 10) async throws -> [iTunesPodcast] {
    print("📡 [PodcastAPI] Fetching top \(limit) podcasts for genre ID: \(genreId)")
    
    // FIXED: Use Search API instead of RSS feed
    var components = URLComponents(string: "https://itunes.apple.com/search")
    components?.queryItems = [
        URLQueryItem(name: "media", value: "podcast"),
        URLQueryItem(name: "entity", value: "podcast"),
        URLQueryItem(name: "genreId", value: genreId),
        URLQueryItem(name: "limit", value: "\(limit)"),
        URLQueryItem(name: "explicit", value: "Yes")
    ]
    
    guard let url = components?.url else {
        print("❌ [PodcastAPI] Failed to construct URL")
        throw PodcastAPIError.invalidURL
    }
    
    print("📡 [PodcastAPI] Fetching from: \(url.absoluteString)")
    
    let request = URLRequest(url: url)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ [PodcastAPI] Invalid response")
        throw PodcastAPIError.networkError(NSError(domain: "Invalid response", code: 0))
    }
    
    print("📡 [PodcastAPI] Response status: \(httpResponse.statusCode)")
    
    guard (200...299).contains(httpResponse.statusCode) else {
        print("❌ [PodcastAPI] Server error: \(httpResponse.statusCode)")
        throw PodcastAPIError.serverError(statusCode: httpResponse.statusCode)
    }
    
    do {
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(iTunesSearchResponse.self, from: data)
        
        print("✅ [PodcastAPI] Successfully decoded \(searchResponse.results.count) podcasts")
        
        // Log first podcast for debugging
        if let first = searchResponse.results.first {
            print("📋 [PodcastAPI] First podcast: \(first.collectionName)")
            print("📋 [PodcastAPI] Artwork URL: \(first.artworkUrl600 ?? "nil")")
        }
        
        return searchResponse.results
        
    } catch {
        print("❌ [PodcastAPI] Failed to decode: \(error)")
        
        // Print raw JSON for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 [PodcastAPI] Raw JSON (first 500 chars):")
            print(String(jsonString.prefix(500)))
        }
        
        throw PodcastAPIError.decodingError(error)
    }
}
```

---

## Verify iTunesSearchResponse Model

Make sure this struct exists and matches the Search API format:

```swift
struct iTunesSearchResponse: Codable {
    let resultCount: Int
    let results: [iTunesPodcast]
}
```

---

## Verify iTunesPodcast Model

Make sure it matches the Search API fields:

```swift
struct iTunesPodcast: Codable, Identifiable {
    let collectionId: Int
    let trackId: Int
    let collectionName: String
    let artistName: String
    let artworkUrl600: String?
    let artworkUrl100: String?
    let feedUrl: String?
    let trackViewUrl: String?
    let collectionViewUrl: String?
    let primaryGenreName: String?
    let genreIds: [String]?
    let genres: [String]?
    
    var id: String {
        String(collectionId)
    }
    
    enum CodingKeys: String, CodingKey {
        case collectionId
        case trackId
        case collectionName
        case artistName
        case artworkUrl600
        case artworkUrl100
        case feedUrl
        case trackViewUrl
        case collectionViewUrl
        case primaryGenreName
        case genreIds
        case genres
    }
}
```

---

## Alternative: Search by Genre Name

If genre ID search doesn't work well, use genre name search:

```swift
func getTopPodcasts(genreId: String, limit: Int = 10) async throws -> [iTunesPodcast] {
    // Get genre name from ID
    let genreName = getGenreName(from: genreId)
    
    print("📡 [PodcastAPI] Fetching top \(limit) podcasts for genre: \(genreName)")
    
    var components = URLComponents(string: "https://itunes.apple.com/search")
    components?.queryItems = [
        URLQueryItem(name: "term", value: genreName),
        URLQueryItem(name: "media", value: "podcast"),
        URLQueryItem(name: "entity", value: "podcast"),
        URLQueryItem(name: "limit", value: "\(limit)"),
        URLQueryItem(name: "explicit", value: "Yes")
    ]
    
    // ... rest of the code
}

private func getGenreName(from genreId: String) -> String {
    switch genreId {
    case "1303": return "comedy"
    case "1489": return "news"
    case "1488": return "true crime"
    case "1545": return "sports"
    case "1321": return "business"
    case "1304": return "education"
    case "1318": return "technology"
    default: return "podcast"
    }
}
```

---

## Testing

After fix, you should see:

```
📡 [PodcastAPI] Fetching from: https://itunes.apple.com/search?media=podcast&entity=podcast&genreId=1303&limit=10
📡 [PodcastAPI] Response status: 200
✅ [PodcastAPI] Successfully decoded 10 podcasts
📋 [PodcastAPI] First podcast: Stand up Comedy
📋 [PodcastAPI] Artwork URL: https://is1-ssl.mzstatic.com/image/thumb/...
✅ [BrowseViewModel] Loaded 10 podcasts for Comedy
```

And the UI should show podcasts!

---

## Git Commit

After fix works:

```bash
git add .
git commit -m "Fix: Use iTunes Search API instead of RSS feed API

- Changed endpoint from /us/rss/toppodcasts to /search
- Fixed JSON parsing to expect resultCount and results keys
- Added comprehensive logging for debugging
- Podcasts now load correctly in browse view"

git push origin after-laptop-crash-recovery
```

---

## Summary

**Problem:** Using RSS feed endpoint that returns different JSON structure  
**Solution:** Use Search API endpoint that returns expected structure  
**Impact:** Browse screen will now load podcasts correctly

---

**END OF FIX GUIDE**
