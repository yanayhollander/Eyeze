//
//  SettingsView.swift
//  Eyeze
//
//  Created by Yanay Hollander on 06/09/2024.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("enableVibration") private var enableVibration: Bool = true
    @AppStorage("detectionDistance") private var detectionDistance: Double = DistanceLevel.DETECTION_DEFAULT_VALUE
    @AppStorage("warningDistance") private var warningDistance: Double = DistanceLevel.DETECTION_WARNING_VALUE
    @AppStorage("alertDistance") private var alertDistance: Double = DistanceLevel.DETECTION_ALERT_VALUE
    @AppStorage("selectedLanguage") private var selectedLanguage: String = LanguageManager.shared.currentLanguage
    
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        Form {
            Section(header: Text(languageManager.localizedString(forKey: "Settings"))) {
                Toggle(isOn: $enableVibration) {
                    Text(languageManager.localizedString(forKey: "Enable Vibration"))
                }
                
                // Distance Thresholds
                ForEach(DistanceLevel.allCases) { level in
                    VStack(alignment: .leading) {
                        Text("\(languageManager.localizedString(forKey: "\(level.rawValue) Distance")): \(distance(for: level), specifier: "%.2f")")
                        Slider(value: distanceBinding(for: level), in: 0...5, step: 0.1) {
                            Text(languageManager.localizedString(forKey: "\(level.rawValue) Distance"))
                        }
                    }
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
    
    private func distance(for level: DistanceLevel) -> Double {
        switch level {
        case .detection:
            return detectionDistance
        case .warning:
            return warningDistance
        case .alert:
            return alertDistance
        }
    
    }
    
    private func distanceBinding(for level: DistanceLevel) -> Binding<Double> {
        switch level {
        case .detection:
            return Binding<Double>(get: { detectionDistance }, set: { detectionDistance = $0 })
        case .warning:
            return Binding<Double>(get: { warningDistance }, set: { warningDistance = $0 })
        case .alert:
            return Binding<Double>(get: { alertDistance }, set: { alertDistance = $0 })
        }
    }
}
