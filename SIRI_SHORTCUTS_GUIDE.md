# Siri Shortcuts Guide for EchoNotes

This guide explains how to use Siri shortcuts to add notes while listening to podcasts in EchoNotes.

## Overview

EchoNotes now supports Siri integration, allowing you to quickly add notes at the current timestamp using voice commands while listening to podcasts.

## Prerequisites

- iOS 16.0 or later
- EchoNotes installed and running
- A podcast must be actively playing

## Available Siri Commands

You can use any of these phrases to trigger the "Add Note" shortcut:

- **"Add a note in EchoNotes"**
- **"Add note in EchoNotes"**
- **"Take a note in EchoNotes"**
- **"Note this in EchoNotes"**
- **"Save a note in EchoNotes"**

## How to Use

### Method 1: Quick Voice Note (Recommended)

1. **Start playing a podcast** in EchoNotes
2. **Activate Siri** by saying "Hey Siri" or holding the side button
3. **Say one of the commands** above, for example:
   ```
   "Hey Siri, add a note in EchoNotes"
   ```
4. **Siri will ask**: "What would you like to note?"
5. **Speak your note content**, for example:
   ```
   "Great insight about machine learning applications"
   ```
6. **Done!** Your note is saved at the current timestamp

### Method 2: Open Note Capture

1. **Start playing a podcast** in EchoNotes
2. **Activate Siri** and say:
   ```
   "Hey Siri, add a note in EchoNotes"
   ```
3. **Skip Siri's question** by saying "Skip" or pressing the home button
4. **The app opens** to the note capture screen at the current timestamp
5. **Type or speak** your note in the app

## First-Time Setup

### Discovering the Shortcut

The first time you want to use Siri shortcuts with EchoNotes:

1. **Open the Shortcuts app** on your iPhone
2. **Go to the "App Shortcuts" tab** (bottom navigation)
3. **Look for EchoNotes** in the list of apps
4. You should see **"Add Note"** listed as an available shortcut
5. The shortcut is automatically available - no manual setup required!

### Alternative Discovery Method

If you don't see the shortcut in the Shortcuts app:

1. **Open EchoNotes**
2. **Play any podcast episode**
3. **Try the Siri command once**:
   ```
   "Hey Siri, add a note in EchoNotes"
   ```
4. This should register the shortcut with the system
5. The shortcut will now appear in the Shortcuts app

## Troubleshooting

### "I can't find the shortcut in the Shortcuts app"

**Solution:**
1. Make sure you've built and installed the latest version of EchoNotes
2. Launch the app at least once
3. Try running the Siri command - it should work even if not visible in Shortcuts app
4. Check Settings > Siri & Search > EchoNotes and ensure "Learn from this App" is enabled

### "Siri says no podcast is playing"

**Solution:**
1. Make sure a podcast episode is actively loaded in EchoNotes
2. The mini player should be visible at the bottom of the screen
3. You don't need to be actively playing - just having an episode loaded is sufficient
4. If the issue persists, try playing the episode for a few seconds first

### "The note wasn't saved"

**Solution:**
1. Check the "Recent Notes" section on the Home tab
2. Look in the full Notes list (tap "view all" from Recent Notes)
3. The note should be timestamped with the exact time you made the Siri request
4. If still not visible, check that you granted the app storage permissions

### "Siri doesn't recognize my command"

**Solutions:**
1. Make sure to include "in EchoNotes" at the end of your command
2. Try the exact phrases listed above
3. Speak clearly and not too fast
4. Check that Siri is enabled: Settings > Siri & Search
5. Make sure "Listen for 'Hey Siri'" is enabled if using voice activation

## Best Practices

### When to Use Siri Shortcuts

- **Driving or commuting**: Hands-free note taking while on the go
- **Exercising**: Quick notes during workout podcasts
- **Cooking**: Capture recipe tips while following along
- **Walking**: Jot down ideas without stopping

### Tips for Better Voice Notes

1. **Be concise**: Shorter notes are easier to speak and review later
2. **Use timestamps**: The timestamp is automatic, so just focus on content
3. **Review later**: Check your notes in the app to ensure accuracy
4. **Speak clearly**: Enunciate for better speech recognition
5. **Avoid background noise**: Find a quiet moment when possible

## Technical Details

### How It Works

1. **App Intents Framework**: EchoNotes uses Apple's App Intents framework
2. **Automatic Timestamping**: Notes are tagged with the exact playback position
3. **Context Aware**: The shortcut automatically detects the current episode
4. **Privacy First**: All notes are stored locally on your device

### What Gets Saved

Each note captured via Siri includes:
- **Note content**: Your spoken/typed text
- **Timestamp**: Exact position in the episode (e.g., "12:34")
- **Episode title**: Which episode you were listening to
- **Podcast name**: The series/show name
- **Creation date**: When the note was created

### Permissions Required

- **Siri & Search**: To process voice commands
- **Speech Recognition**: To convert speech to text (handled by iOS)
- **No internet required**: All processing happens on-device

## Advanced Usage

### Creating Custom Shortcuts

You can create more advanced shortcuts in the Shortcuts app:

1. **Open Shortcuts app** > "+" to create new shortcut
2. **Add Action** > Search for "EchoNotes"
3. **Select "Add Note"** from the list
4. **Configure**:
   - Add text before/after the note
   - Set up automation triggers
   - Combine with other actions
5. **Name and save** your custom shortcut

### Example Custom Shortcuts

**"Quick Insight"**
- Trigger: "Quick insight"
- Action: Add note in EchoNotes
- Pre-fill: "💡 Insight: " + your text

**"Important Point"**
- Trigger: "Important point"
- Action: Add note in EchoNotes
- Pre-fill: "⭐ IMPORTANT: " + your text

**"Question"**
- Trigger: "I have a question"
- Action: Add note in EchoNotes
- Pre-fill: "❓ Question: " + your text

## Privacy & Data

- **All notes are private**: Stored only on your device
- **No cloud sync**: Your data never leaves your iPhone
- **No analytics**: We don't track what you say to Siri
- **Siri privacy**: Apple's standard Siri privacy policies apply

## Support

If you encounter issues with Siri shortcuts:

1. **Check app version**: Make sure you have the latest build
2. **Restart the app**: Force quit and relaunch EchoNotes
3. **Restart device**: Sometimes iOS needs a fresh start
4. **Reinstall app**: As a last resort, reinstall EchoNotes

## Future Enhancements

Potential future Siri shortcuts could include:
- "Play my last podcast"
- "Show my recent notes"
- "Jump to timestamp"
- "Search notes for..."

---

**Version**: 1.0
**Last Updated**: November 2025
**Compatible with**: iOS 16.0+

Enjoy hands-free note taking with EchoNotes! 🎙️📝
