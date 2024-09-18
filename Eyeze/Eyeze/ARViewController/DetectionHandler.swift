//
//  DetectionHandler.swift
//  Eyeze
//
//  Created by Yanay Hollander on 17/09/2024.
//

import Foundation
import SwiftUI
import UIKit
import AVFoundation

class DetectionHandler {
    
    @AppStorage("enableAlerts") private var enableAlerts: Bool = true
    @AppStorage("detectionDistance") private var detectionDistance: Double = DistanceLevel.DETECTION_DEFAULT_VALUE
    @AppStorage("warningDistance") private var warningDistance: Double = DistanceLevel.DETECTION_WARNING_VALUE
    @AppStorage("alertDistance") private var alertDistance: Double = DistanceLevel.DETECTION_ALERT_VALUE
    @AppStorage("enableVibration") private var enableVibration: Bool = true
    
    private let DEBOUNCE_INTERVAL: TimeInterval = 1.0
    private let SPEAK_DEBOUNCE_INTERVAL: TimeInterval = 4.0
    private var hapticFeedbackGenerator: UIImpactFeedbackGenerator?
    private var lastNotificationTimes: [String: Date] = [:]
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastUpdate: Date = Date(timeIntervalSince1970: 0)
    
    
    init() {
        hapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        hapticFeedbackGenerator?.prepare()
    }
    
    func handleDistanceResults(_ detectedResults: [DistanceResult]) {
        let now = Date()
        
        // Ensure at least x second has passed since the last check
        if now.timeIntervalSince(lastUpdate) < DEBOUNCE_INTERVAL {
            // Not enough time has passed, ignore this call
            return
        }
        
        // Update the lastUpdate to the current time
        lastUpdate = now
        
        
        let checkDistance = detectedResults.checkDistances()
        
        if checkDistance.shouldAlert {
            triggerHapticFeedback()
            
            var text = checkDistance.location
            
            // Perform the notification
            speak(text, force: checkDistance.level == .alert)
        }
        
    }
    
    func triggerHapticFeedback() {
        if enableVibration {
            hapticFeedbackGenerator?.impactOccurred()
        }
    }
    
    private func speak(_ text: String, force: Bool) {
        if !enableAlerts {
            return
        }
        
        let now = Date()
        if let lastTime = lastNotificationTimes[text], now.timeIntervalSince(lastTime) < SPEAK_DEBOUNCE_INTERVAL, !force {
            // If the same text was notified less than an interval, ignore it
            return
        }
        
        // Update the last notification time for this text
        lastNotificationTimes[text] = now
        
        DispatchQueue.global(qos: .userInitiated).async {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            
            // Execute speech on the main thread
            DispatchQueue.main.async {
                self.speechSynthesizer.speak(utterance)
            }
        }
    }
    
}
