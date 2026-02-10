//
//  EchoCastDesignTokens.swift
//  EchoNotes
//
//  Design tokens for visual consistency across the app
//

import SwiftUI

// MARK: - Color Extensions

extension Color {
    // Primary accent color - Mint
    static let mintAccent = Color(red: 0.647, green: 0.898, blue: 0.847)

    // Semantic colors for dark theme
    static let echoBackground = Color(red: 0.149, green: 0.149, blue: 0.149)
    static let echoTextPrimary = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let echoTextSecondary = Color(red: 0.6, green: 0.6, blue: 0.6)
    static let echoTextTertiary = Color(red: 0.4, green: 0.4, blue: 0.4)

    // Card backgrounds
    static let noteCardBackground = Color(red: 0.118, green: 0.118, blue: 0.118)

    // Button colors
    static let mintButtonBackground = Color(red: 0.647, green: 0.898, blue: 0.847)
    static let mintButtonText = Color(red: 0.102, green: 0.235, blue: 0.204)
    static let darkGreenButton = Color(hex: "1a3c34")

    // UI element colors
    static let menuIndicatorBackground = Color(red: 0.071, green: 0.071, blue: 0.071)
    static let playerProgressBackground = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let searchFieldBackground = Color(red: 0.22, green: 0.22, blue: 0.22)
}

// MARK: - Color Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Font Extensions

extension Font {
    // Title fonts
    static func largeTitleEcho() -> Font { .system(size: 34, weight: .bold) }
    static func title2Echo() -> Font { .system(size: 22, weight: .bold) }

    // Body fonts
    static func bodyEcho() -> Font { .system(size: 17) }
    static func bodyRoundedMedium() -> Font { .system(size: 17, weight: .medium, design: .rounded) }

    // Subheading fonts
    static func subheadlineRounded() -> Font { .system(size: 15, weight: .medium, design: .rounded) }

    // Caption fonts
    static func captionRounded() -> Font { .system(size: 13, design: .rounded) }
    static func caption2Medium() -> Font { .system(size: 11, weight: .medium) }
    static func caption2Rounded() -> Font { .system(size: 11, design: .rounded) }

    // Tab fonts
    static func tabLabel() -> Font { .system(size: 10, weight: .semibold) }
    static func tabLabelMedium() -> Font { .system(size: 10, weight: .medium) }
}

// MARK: - Spacing Tokens

struct EchoSpacing {
    static let screenPadding: CGFloat = 16
    static let headerTopPadding: CGFloat = 16
    static let noteCardPadding: CGFloat = 16
    static let noteCardCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 6
}

// MARK: - Spacing Standard Values

extension CGFloat {
    static let echoSpacing4: CGFloat = 4
    static let echoSpacing8: CGFloat = 8
    static let echoSpacing12: CGFloat = 12
    static let echoSpacing16: CGFloat = 16
    static let echoSpacing24: CGFloat = 24
    static let echoSpacing32: CGFloat = 32
}

// MARK: - View Modifiers

struct EchoCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.noteCardBackground)
            .cornerRadius(EchoSpacing.noteCardCornerRadius)
    }
}

extension View {
    func echoCardStyle() -> some View {
        modifier(EchoCardStyle())
    }
}
