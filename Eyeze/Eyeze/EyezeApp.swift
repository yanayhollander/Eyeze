//
//  EyezeApp.swift
//  Eyeze
//
//  Created by Yanay Hollander on 06/09/2024.
//

import SwiftUI

@main
struct EyezeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Disable screen dimming and locking
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onDisappear {
                    // Enable screen dimming and locking
                    UIApplication.shared.isIdleTimerDisabled = false
                }
        }
    }
}
