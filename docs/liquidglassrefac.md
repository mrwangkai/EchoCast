To prompt Claude Code (or a similar coding simulator) to use the **iOS 26 Liquid Glass UI** comprehensively across an entire application, you need to provide it with three key components: **context and intent**, **specific API references/code snippets**, and a **structured plan** for applying the style globally.

The Liquid Glass design language, which involves **depth-aware, translucent, and reflective surfaces** (a form of modern glassmorphism), is primarily implemented in **SwiftUI** using dedicated modifiers and containers like `.glassEffect()` and `GlassEffectContainer`.

Here is an extensive prompt template you can use:

-----

## 🎨 iOS 26 Liquid Glass App Redesign Prompt

**Goal:** Refactor the existing SwiftUI application (or build a new one) to fully adopt the **iOS 26 Liquid Glass UI** design language across all main navigation, controls, and relevant surfaces. The Liquid Glass aesthetic must be integrated coherently into the whole app structure, not just isolated components.

### 1\. 📋 Context and Intent

  * **Target Platform:** iOS 26.0+ (SwiftUI and modern Xcode 26+ APIs).
  * **Design Philosophy:** Implement the **Liquid Glass** aesthetic as defined by Apple's Human Interface Guidelines (HIG) for iOS 26. This means **content resides on the base layer**, and **controls/navigation float above** on translucent, blurred glass surfaces that reflect and refract the underlying content (e.g., background images, scrolling lists).
  * **Whole App Scope:** This style should be applied to the **Navigation Bar/Toolbar**, **Tab Bar**, **Buttons**, **Overlays/Sheets**, and **Card-like components**.

### 2\. 📚 API and Code Snippet Reference

To ensure accurate implementation, reference these core SwiftUI components and modifiers introduced in iOS 26 for Liquid Glass:

  * **Liquid Glass Modifier:**

    ```swift
    // Apply to standard controls and small surfaces (Buttons, Menu items)
    .glassEffect()

    // Use with variants for different transparencies/behaviors
    .glassEffect(.regular) 
    .glassEffect(.clear) // For more background-heavy elements
    .glassEffect(.regular.tint(.blue)) // For semantic color tinting
    .glassEffect(.regular.interactive()) // For touch-responsive scaling/shimmering
    ```

  * **Glass Cohesion and Morphing Container:**

    ```swift
    // Use this to group related glass elements (like segmented controls or a cluster of action buttons) so they visually blend and morph into a cohesive shape.
    GlassEffectContainer(spacing: 20) {
        // ... Glass elements here ...
    }

    // For elements that need to smoothly transition between states (e.g., a button expanding into a set of buttons), use a Namespace and ID.
    @Namespace private var namespace
    .glassEffectID("uniqueID", in: namespace)
    ```

  * **System Controls:**

    ```swift
    // Use the dedicated button styles where appropriate (e.g., for primary/secondary actions)
    .buttonStyle(.glass) // Translucent glass button (secondary actions)
    .buttonStyle(.glassProminent) // Opaque prominent glass button (primary actions)
    ```

### 3\. 🏗️ Implementation Strategy (Full App Conversion)

Provide the following step-by-step instructions to guide the model through an extensive application of the style:

1.  **Root View Background:** Ensure the main content view sits over a **dynamic, visually rich background** (e.g., a full-screen image or a complex gradient) to maximize the Liquid Glass effect's visual appeal.
2.  **Navigation Bar/Toolbar:** Apply the glass effect to the navigation components. Replace standard background materials where necessary.
      * **Instruction:** Ensure the `Toolbar` and `NavigationBar` backgrounds automatically render with the appropriate system-default Liquid Glass material. If the background requires manual control, specify that all elements within the navigation area (e.g., action buttons) should use `.glassEffect()`.
3.  **Tab Bar (or Sidebar):** Apply the system's Liquid Glass background material to the bottom `TabView` bar to ensure it is translucent and reflects content scrolling underneath it.
      * **Instruction:** All `TabView` and `Toolbar` elements should default to the Liquid Glass material.
4.  **Main Controls (Buttons, Toggles):** Convert all significant interactive controls to use the new glass styles.
      * **Instruction:** Apply `.buttonStyle(.glass)` or `.buttonStyle(.glassProminent)` to primary and secondary action buttons, respectively. For small, circular icon-only buttons, use `.glassEffect()` directly on the `Button`'s label.
5.  **Overlays/Sheets:** All modal presentations (e.g., `sheet`, `popover`) should use the system's Liquid Glass for their card backgrounds.
      * **Instruction:** Ensure all presented views utilize the system's default material for sheets/modals, which should be the Liquid Glass style on iOS 26.
6.  **Card Components and Groups:** For any card-like containers, use `GlassEffectContainer` to unify the appearance of multiple internal controls and enable smooth blending and morphing.
      * **Instruction:** Group related controls (e.g., filters, action clusters) within a `GlassEffectContainer` and apply `.glassEffect()` to the individual controls inside it. Use the `spacing` parameter to control the blending of elements.

-----

**Example of a Top-Level Prompt for a Social App:**

> **"Refactor the provided SwiftUI code for a multi-tab social app to fully adopt the iOS 26 Liquid Glass UI. Start by making the main `TabView` and all `NavigationBar` elements use the system's new glass material for translucency. Next, convert all major buttons on the 'Profile' and 'Settings' views to use `.buttonStyle(.glassProminent)`. Finally, on the 'Feed' view, wrap the like/comment/share buttons for each post in a `GlassEffectContainer(spacing: 15)` and apply `.glassEffect()` to the individual buttons so they blend together."**
