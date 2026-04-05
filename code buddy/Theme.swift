//
//  Theme.swift
//  code buddy
//
//  All cb* colors are adaptive — they automatically switch between
//  light and dark values based on the active color scheme.
//

import SwiftUI

extension Color {

    // MARK: - Adaptive palette

    /// Main page background
    static let cbBackground = Color(
        light: Color(hex: "#F5F7FA"),
        dark:  Color(hex: "#0D1117")
    )

    /// Sidebar / panel surface
    static let cbSurface = Color(
        light: Color(hex: "#FFFFFF"),
        dark:  Color(hex: "#161B22")
    )

    /// Card backgrounds
    static let cbCard = Color(
        light: Color(hex: "#FFFFFF"),
        dark:  Color(hex: "#1C2333")
    )

    /// Borders and dividers
    static let cbBorder = Color(
        light: Color(hex: "#E2E8F0"),
        dark:  Color(hex: "#2A3244")
    )

    /// Primary accent — blue
    static let cbAccent = Color(
        light: Color(hex: "#3B6BF5"),
        dark:  Color(hex: "#6B6BF5")
    )

    static let cbAccentHover = Color(
        light: Color(hex: "#2554D4"),
        dark:  Color(hex: "#8080FF")
    )

    /// Success green
    static let cbGreen = Color(
        light: Color(hex: "#16A34A"),
        dark:  Color(hex: "#3DDC84")
    )

    /// Primary text
    static let cbTextPrimary = Color(
        light: Color(hex: "#0F172A"),
        dark:  Color(hex: "#E6EDF3")
    )

    /// Secondary text
    static let cbTextSecondary = Color(
        light: Color(hex: "#64748B"),
        dark:  Color(hex: "#8B949E")
    )

    /// Muted / placeholder text
    static let cbTextMuted = Color(
        light: Color(hex: "#94A3B8"),
        dark:  Color(hex: "#484F58")
    )

    // MARK: - Adaptive initialiser

    init(light: Color, dark: Color) {
        self.init(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
    }

    // MARK: - Hex initialiser

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
