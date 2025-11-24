# Feature Spec: iOS Note Tagging UX & Implementation

Design and implement a reusable tagging component for an iOS notes app, used in both **Create Note** and **Edit Note** screens. A single note can have multiple tags. Tagging is optional.

## Core Requirements

1. Support **multiple tags per note**.
2. Support both:
   - **Creating new tags**.
   - **Selecting from existing tags**.
3. Use **common iOS UX conventions**:
   - Token-style “pill” chips for each tag.
   - Clear affordance to add tags.
   - Autocomplete for existing tags.
4. Same interaction model in:
   - New note form.
   - Edit note form.

## UX Behavior

### Tag Input Area

- Display a dedicated tag area, e.g.:
  - A token field or horizontal wrap layout of tag chips.
  - An inline text field with placeholder: `"Add tag"` (or similar).
- The input field should:
  - Show as a tappable area with clear affordance (border, background, or leading “#” / “+ Tag” label).
  - Support free text entry.
  - Convert entered text into a **tag token** when:
    - User presses return.
    - User taps a suggestion.
    - User types a separator (e.g., comma) if desired.

### Creating New Tags

- When the user types text that does **not** match any existing tag:
  - Show a suggestion row like: `Create tag "…"` at the top or bottom of the suggestion list.
  - On selection, create a **new tag object** and immediately attach it to the note.
- After creation:
  - Render the new tag as a pill-shaped token.
  - Clear the text input for the next tag.
- Allow multiple new tags in one session.

### Selecting Existing Tags

- Maintain a list of **existing tags** (from the user’s prior notes).
- As the user types:
  - Filter and show **autocomplete suggestions** of existing tags matching the current query.
  - Support tapping a suggestion to add it as a token.
- If the user hasn’t typed anything:
  - Optionally show a short list of **recent or frequently used tags** for quick selection.
- Prevent duplicates:
  - If a tag is already attached to the note, either:
    - Do not show it in suggestions, or
    - Show it as “selected” and ignore re-selection.

### Tag Tokens (Chips)

- Each tag is rendered as a pill-shaped token with:
  - Tag name label.
  - A small clear/remove control (e.g., “×” icon) on the right.
- Tapping the remove icon:
  - Removes the tag from the current note.
  - Does **not** delete the tag from the global tag list (it remains available as an existing tag for other notes).
- Layout:
  - Tokens should wrap to multiple lines as needed.
  - The input field should appear:
    - Inline with tokens (at the end of the last line), or
    - Below the token list, as long as it’s visually connected.

### Create vs Edit Flows

- **Create Note:**
  - Show an empty tag area with an `"Add tag"` placeholder.
  - Allow zero or more tags to be added before save.
- **Edit Note:**
  - Pre-populate the tag area with existing tag tokens for that note.
  - Allow:
    - Adding new tags (create or attach existing).
    - Removing existing tags via the “×” on the token.
  - Same interaction patterns as in Create Note.

## Data & API Expectations

- Each tag has at minimum:
  - `id` (stable identifier).
  - `name` (string, user-facing label).
- Each note has:
  - `tags: [Tag]` (list of associated tags).
- Behavior:
  - On creating a new tag:
    - Persist the new tag in the global tags collection.
    - Attach it to the current note.
  - On selecting an existing tag:
    - Attach the existing tag to the current note.
  - On removing a tag token:
    - Detach it from the note’s tags.
    - Do not delete it globally unless a separate admin action exists.

## Accessibility & Keyboard

- Tag input should:
  - Support hardware/software keyboard return key to confirm a tag.
  - Expose tokens and remove buttons with accessible labels (e.g., “Remove tag <name>”).
- Ensure VoiceOver users can:
  - Navigate between tag tokens.
  - Add and remove tags.
  - Use suggestions.

## Output Needed from Coding Engine

- A reusable SwiftUI or UIKit component (specify one) that:
  - Renders tag tokens and input as described.
  - Accepts:
    - `allTags: [Tag]`
    - `selectedTags: Binding<[Tag]>`
  - Exposes callbacks for:
    - `onCreateTag(name: String) -> Tag`
    - `onSelectExistingTag(tag: Tag)`
    - `onRemoveTag(tag: Tag)`
- Example integration in:
  - Create Note screen.
  - Edit Note screen.

