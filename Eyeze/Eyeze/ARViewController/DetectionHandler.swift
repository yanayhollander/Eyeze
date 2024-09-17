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
    
    @AppStorage("detectionDistance") private var detectionDistance: Double = DistanceLevel.DETECTION_DEFAULT_VALUE
    @AppStorage("warningDistance") private var warningDistance: Double = DistanceLevel.DETECTION_WARNING_VALUE
    @AppStorage("alertDistance") private var alertDistance: Double = DistanceLevel.DETECTION_ALERT_VALUE
    @AppStorage("enableVibration") private var enableVibration: Bool = true
    
    private let DEBOUNCE_INTERVAL: TimeInterval = 2.0
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
        
        // Ensure at least 1 second has passed since the last check
        if now.timeIntervalSince(lastUpdate) < DEBOUNCE_INTERVAL {
            // Not enough time has passed, ignore this call
            return
        }
        
        // Update the lastUpdate to the current time
        lastUpdate = now
        
        
        let checkDistance = detectedResults.checkDistances(alertDistance: alertDistance, warningDistance: warningDistance)
        
        if checkDistance.shouldAlert {
            triggerHapticFeedback()
            
            var text = ""
            if checkDistance.level == .alert {
                text = checkDistance.location
            } else if checkDistance.level == .warning {
                text = "Warning \(checkDistance.location)"
            }
            
            // Perform the notification
            print(text)
            //            if !text.isEmpty {
            //                speak(text)
            //            }
        }
        
    }
    
    func triggerHapticFeedback() {
        if enableVibration {
            hapticFeedbackGenerator?.impactOccurred()
        }
    }
    
    private func speak(_ text: String) {
        let now = Date()
        if let lastTime = lastNotificationTimes[text], now.timeIntervalSince(lastTime) < DEBOUNCE_INTERVAL {
            // If the same text was notified less than an interval, ignore it
            return
        }
        
        // Update the last notification time for this text
        lastNotificationTimes[text] = now
        
        
        
        let utterance = AVSpeechUtterance(string: text)
        speechSynthesizer.speak(utterance)
    }
    
}
