I am building an iOS app using SwiftUI and I need you to generate Swift code that integrates with the Taddy Podcast API (GraphQL).

Goal: create a reusable Swift networking layer that allows:

Searching for podcasts by text input

Returning metadata such as name, uuid, description, imageUrl, and itunesInfo.baseArtworkUrlOf(size:640)

Downloading and caching album art locally using FileManager

Returning Swift models that SwiftUI can easily render

I will provide my own Taddy API Key + User ID, stored securely inside an .xcconfig file or Info.plist.
DO NOT hard-code the API keys.

1. Requirements for Networking Code

Create a Swift class (e.g. TaddyAPI) that:

Uses URLSession with async/await

Sends POST requests to https://api.taddy.org

Uses GraphQL queries

Includes required headers:

"X-API-KEY" : value from config

"X-USER-ID" : value from config

"Content-Type": "application/json"

Implement 2 GraphQL operations:

A) Podcast search

Using the API documented here:
https://taddy.org/developers/podcast-api/search

GraphQL example (variable search term):

{
  search(term: "<TERM>", filterForTypes: PODCASTSERIES, limitPerPage: 15) {
    podcastSeries {
      uuid
      name
      description
      imageUrl
      itunesInfo {
        baseArtworkUrlOf(size: 640)
      }
    }
  }
}

B) Podcast series details (including episodes)

https://taddy.org/developers/podcast-api/get-podcast-series

Code should allow fetching episodes using:

{
  getPodcastSeries(uuid: "<UUID>") {
    uuid
    name
    imageUrl
    episodes {
      uuid
      title
      description
      audioUrl
      published
    }
  }
}

2. Album Art Caching

Add a Swift utility class (e.g. ImageCacheManager) that:

Downloads an image from a URL

Saves it in the app’s documents directory using <podcastUUID>.jpg

Checks cache before downloading

Returns a URL or UIImage

Provide functions like:

func cachedArtworkURL(for uuid: String) -> URL?
func fetchAndCacheArtwork(from remoteURL: String, for uuid: String) async throws -> UIImage

3. SwiftUI Models

Generate structs using Codable:

PodcastSeries

PodcastSearchResult

PodcastEpisode

They should match the GraphQL fields returned.

4. High-Level SwiftUI Interface

Create an async function:

func searchPodcasts(_ term: String) async throws -> [PodcastSeries]


Each PodcastSeries should include:

title

description

uuid

cachedArtworkURL (if exists)

And add:

func fetchEpisodes(for uuid: String) async throws -> [PodcastEpisode]

5. Additional Requirements

Use @MainActor where needed to update UI

Handle missing imageUrl safely

Use strongly typed GraphQL response models

Include good error handling (URLError, decoding errors, network failures)

6. Output

Provide:

All Swift code files (networking, models, caching)

Example usage in a SwiftUI SearchView with live search

Do NOT include mock API keys. Use placeholders like:

let apiKey = Bundle.main.object(forInfoDictionaryKey: "TADDY_API_KEY") as! String
