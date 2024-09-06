//
//  SettingsView.swift
//  Eyeze
//
//  Created by Yanay Hollander on 06/09/2024.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("enableVibration") private var enableVibration: Bool = false
    @AppStorage("obstacleDetectionThreshold") private var sliderValue: Double = 0.5
    
    var body: some View {
        Form {
            Toggle(isOn: $enableVibration) {
                Text("Enable Vibration")
            }
            
            Text("Detection Distance: \(sliderValue, specifier: "%.2f")")
            Slider(value: $sliderValue, in: 0...1, step: 0.01) {
                Text("Detection Distance")
            }
        }
    }
}
