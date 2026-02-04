# PodcastIndex Integration for Vibe App

## Overview

We integrate with PodcastIndex.org to enable fast podcast discovery, metadata lookup, and album-art retrieval. This document describes how to build requests, authorize them, and use the responses in our app.

Base API URL: `https://api.podcastindex.org/api/1.0` :contentReference[oaicite:1]{index=1}

## Authentication

Every request must include the following HTTP headers: :contentReference[oaicite:2]{index=2}

| Header | Value / Purpose |
|--------|-----------------|
| `User-Agent` | A string identifying your app (e.g. `"VibeApp/0.1"`) :contentReference[oaicite:3]{index=3} |
| `X-Auth-Key` | Your API key (provided by PodcastIndex) :contentReference[oaicite:4]{index=4} |
| `X-Auth-Date` | Current time as a unix-epoch integer (in seconds) :contentReference[oaicite:5]{index=5} |
| `Authorization` | SHA-1 hash of the concatenation: `apiKey + apiSecret + X-Auth-Date`, hex-encoded. :contentReference[oaicite:6]{index=6} |

> **Pseudo-code (Node.js / JS example):**  
> ```js
> const ts = Math.floor(Date.now() / 1000);  
> const authString = API_KEY + API_SECRET + ts;  
> const authHeader = crypto.createHash('sha1').update(authString).digest('hex');
>  
> fetch(url, {
>   method: 'GET',
>   headers: {
>     'User-Agent': 'VibeApp/0.1',
>     'X-Auth-Key': API_KEY,
>     'X-Auth-Date': ts.toString(),
>     'Authorization': authHeader
>   }
> })
> ```

## Core Endpoints / Use Cases

Here are some of the core endpoints you’ll likely use in Vibe to build a podcast directory / metadata fetching system. :contentReference[oaicite:7]{index=7}

| Use Case | Endpoint (HTTP GET) | Query Params / Notes |
|----------|--------------------|---------------------|
| **Search for podcasts by keyword** | `/api/1.0/search/byterm` | `?q=[search terms]` — URL-encoded search string. :contentReference[oaicite:8]{index=8} |
| **Get feed metadata by feed URL** | `/api/1.0/podcast/byfeedurl` | `?url=[feed URL]` (URL-encoded) :contentReference[oaicite:9]{index=9} |
| **Get feed metadata/search by internal feed ID** | `/api/1.0/podcast/byid` | `?id=[feed id]` :contentReference[oaicite:10]{index=10} |
| **Get feed metadata/search by iTunes ID** | `/api/1.0/podcast/byitunesid` | `?id=[iTunes ID]` :contentReference[oaicite:11]{index=11} |
| **Fetch episodes for a feed (by feed URL or feed ID)** | `/api/1.0/episodes/byfeedurl?url=[feed URL]` or `/api/1.0/episodes/byfeedid?id=[feed ID]` | Returns list of episodes known for that feed, in reverse-chronological order. :contentReference[oaicite:12]{index=12} |

### Example (search + metadata fetch)

1. **Search**  
   ```http
   GET https://api.podcastindex.org/api/1.0/search/byterm?q=some%20podcast
   <with auth headers>
