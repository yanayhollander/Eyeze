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
    @AppStorage("selectedLanguage") private var selectedLanguage: String = LanguageManager.shared.currentLanguage

    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        Form {
            Section(header: Text(languageManager.localizedString(forKey: "Settings"))) {
                Toggle(isOn: $enableVibration) {
                    Text(languageManager.localizedString(forKey: "Enable Vibration"))
                }
                
                Text("\(languageManager.localizedString(forKey: "Detection Distance")): \(sliderValue, specifier: "%.2f")")
                Slider(value: $sliderValue, in: 0...1, step: 0.01) {
                    Text(languageManager.localizedString(forKey: "Detection Distance"))
                }
            }
            
            Section(header: Text(languageManager.localizedString(forKey: "Language"))) {
                Picker(languageManager.localizedString(forKey: "Select Language"), selection: $selectedLanguage) {
                    Text("English").tag("en")
                    Text("Hebrew").tag("he")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedLanguage) { newLanguage in
                    languageManager.setLanguage(newLanguage)
                }
            }
        }
    }
}
