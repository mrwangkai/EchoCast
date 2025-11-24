# Deep Linking Setup Guide

This guide will help you set up deep linking for sharing episode notes with timestamps in EchoNotes.

## Features Implemented

✅ Custom domain URL support (format: `customdomain.com/episodeID?t=seconds`)
✅ URL routing and deep link handling
✅ Timestamp parsing from URL parameters
✅ Integration with GlobalPlayerManager for automatic playback
✅ Share functionality in note detail view
✅ Universal links and custom URL scheme support

## Setup Steps

### 1. Add DeepLinkManager to Xcode Project

The file `DeepLinkManager.swift` has been created in the `Services` folder but needs to be added to the Xcode project:

1. Open `EchoNotes.xcodeproj` in Xcode
2. Right-click on the `Services` folder in the Project Navigator
3. Select "Add Files to EchoNotes..."
4. Navigate to and select `Services/DeepLinkManager.swift`
5. Ensure "Add to targets: EchoNotes" is checked
6. Click "Add"

### 2. Configure Your Custom Domain

In `Views/AudioPlayerView.swift` (line 699), update the custom domain:

```swift
// Replace "yourdomain.com" with your actual custom domain
let customDomain = "yourdomain.com"
```

Change `"yourdomain.com"` to your actual domain (e.g., `"echonotes.app"`)

### 3. Set Up Universal Links (Optional but Recommended)

For production use with your custom domain:

1. Create an `apple-app-site-association` file on your server at `https://yourdomain.com/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.yourcompany.EchoNotes",
        "paths": ["/*"]
      }
    ]
  }
}
```

2. Add Associated Domains capability in Xcode:
   - Select your project in Project Navigator
   - Select the EchoNotes target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Associated Domains"
   - Add domain: `applinks:yourdomain.com`

### 4. Update Bundle Identifier (if needed)

The Info.plist already includes the custom URL scheme `echonotes://`, but you may want to update it:

- Current scheme: `echonotes://episode/episodeID?t=123`
- Universal link: `https://yourdomain.com/episodeID?t=123`

## How It Works

### URL Format

Generated URLs follow this format:
```
https://yourdomain.com/episodeID?t=123.5
```

Where:
- `episodeID` is the unique identifier for the episode
- `t` is the timestamp in seconds (can include decimals)

### Deep Link Flow

1. User taps a shared link (e.g., `https://yourdomain.com/abc-123?t=45.5`)
2. iOS opens the app via the registered URL scheme or universal link
3. `DeepLinkManager` parses the URL and extracts:
   - Episode ID: `abc-123`
   - Timestamp: `45.5` seconds
4. `ContentView` receives the deep link and calls `GlobalPlayerManager`
5. Player loads the episode from playback history and seeks to the timestamp
6. Mini player appears with the episode playing at the correct position

### Sharing a Note

1. User opens a note in detail view
2. Taps the share button (↑) in the top right
3. Share sheet appears with the generated URL
4. User can share via Messages, Mail, Copy, etc.

## Testing

### Test with Custom URL Scheme

You can test deep linking without setting up a custom domain using the built-in URL scheme:

```bash
xcrun simctl openurl booted "echonotes://episode/EPISODE_ID?t=30"
```

Replace `EPISODE_ID` with an actual episode ID from your playback history.

### Test with Safari (Universal Links)

Once universal links are configured:

1. Create a test HTML page with a link: `<a href="https://yourdomain.com/episodeID?t=30">Test Link</a>`
2. Open the page in Mobile Safari on your test device
3. Tap the link
4. The app should open and start playing at 30 seconds

## Troubleshooting

### "Episode not found" error

The deep linking system requires the episode to be in playback history. Make sure:
- You've played the episode at least once before sharing
- The episode ID matches an entry in `PlaybackHistoryManager`

### Deep link not opening the app

- Verify the URL scheme is registered in Info.plist (already done)
- For universal links, check that the `apple-app-site-association` file is accessible
- Ensure Associated Domains are properly configured in Xcode

### Share button not working

- Check that the note has an episode title
- Verify the episode exists in playback history
- Check console logs for debugging messages (they start with 📤, ❌, or ✅)

## Future Enhancements

Consider these improvements:

1. **Store Episode ID in Notes**: Currently, notes don't store episode IDs directly. Adding an `episodeID` field to `NoteEntity` would make sharing more reliable.

2. **Fallback Episode Loading**: If episode isn't in history, fetch it from the podcast feed.

3. **Rich Preview**: Generate Open Graph meta tags on your server for rich link previews.

4. **Analytics**: Track how often notes are shared and which episodes get the most shares.

5. **Custom Share Message**: Allow users to add a custom message when sharing.

## Configuration Checklist

- [ ] Add DeepLinkManager.swift to Xcode project
- [ ] Update custom domain in AudioPlayerView.swift
- [ ] Build and run the app
- [ ] Play an episode to add it to history
- [ ] Create a note with a timestamp
- [ ] Test sharing from note detail view
- [ ] Test opening a shared link
- [ ] (Optional) Set up universal links for production

## Code Changes Summary

### Files Created
- `Services/DeepLinkManager.swift` - Deep link parsing and URL generation

### Files Modified
- `EchoNotesApp.swift` - Added deep link handling via `.onOpenURL()`
- `ContentView.swift` - Added deep link processing logic
- `Services/GlobalPlayerManager.swift` - Added `loadEpisodeByID()` method
- `Services/PlaybackHistoryManager.swift` - Added `getPlaybackHistory()` method
- `Views/AudioPlayerView.swift` - Added share button and ShareSheet
- `Info.plist` - Added custom URL scheme configuration

## Questions?

If you have any questions or need help with the setup, check the inline comments in the code or refer to Apple's documentation on Universal Links.
