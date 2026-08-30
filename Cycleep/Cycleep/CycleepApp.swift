//
//  CycleepApp.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-05-22.
//

import SwiftUI

@main
struct CycleepApp: App {
    init() {
        Theme.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .tint(Theme.textPrimary)
        }
    }
}
