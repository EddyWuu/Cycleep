//
//  Theme.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-08-30.
//

import SwiftUI
import UIKit

/// Central color palette + styling for Cycleep's dark, cool-toned look.
///
/// Palette (from the app's chosen scheme):
/// - `background` 354458  (darkest — app background)
/// - `surface`    4b5a6d  (cards / rows)
/// - `accent`     7b8da4  (buttons, strokes, selection)
/// - `textSecondary` 939cac
/// - `textPrimary`   c7d8e8  (near-white, high contrast)
enum Theme {
    static let background = Color(hex: 0x354458)
    static let backgroundDeep = Color(hex: 0x2B3849)
    static let surface = Color(hex: 0x4B5A6D)
    static let surfaceRaised = Color(hex: 0x54637A)
    static let accent = Color(hex: 0x7B8DA4)
    static let textSecondary = Color(hex: 0x939CAC)
    static let textPrimary = Color(hex: 0xC7D8E8)

    /// Warm pop used to distinguish wake-up alarms from bedtimes.
    static let wake = Color(hex: 0xE7C27D)
    /// Cool tone for bedtime / sleep alarms.
    static let sleep = Color(hex: 0xC7D8E8)

    /// Subtle top-to-bottom background gradient for depth.
    static let backgroundGradient = LinearGradient(
        colors: [background, backgroundDeep],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Configures global UIKit chrome (nav bar, tab bar, list cells, segmented
    /// control) so the whole app adopts the palette. Call once at launch.
    static func configureAppearance() {
        let bg = UIColor(background)
        let surfaceColor = UIColor(surface)
        let primary = UIColor(textPrimary)
        let secondary = UIColor(textSecondary)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = bg
        nav.titleTextAttributes = [.foregroundColor: primary]
        nav.largeTitleTextAttributes = [.foregroundColor: primary]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = primary

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = bg
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        UITableViewCell.appearance().backgroundColor = surfaceColor

        let seg = UISegmentedControl.appearance()
        seg.selectedSegmentTintColor = UIColor(accent)
        seg.backgroundColor = surfaceColor
        seg.setTitleTextAttributes([.foregroundColor: primary], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: secondary], for: .normal)
    }
}

extension Color {
    /// Creates a color from a 24-bit RGB hex value, e.g. `0x4B5A6D`.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

extension View {
    /// Places the themed gradient behind a scrolling List/Form and hides the
    /// default system background so the palette shows through.
    func cycleepListBackground() -> some View {
        self.scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient.ignoresSafeArea())
    }
}
