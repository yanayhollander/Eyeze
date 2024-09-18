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
    
    private let SPEAK_DEBOUNCE_INTERVAL: TimeInterval = 4.0
    private let DISTANCE_INTERVAL = 0.1
    private let MAX_HAPTIC_INTERVAL: TimeInterval = 5.0
    private let MIN_HAPTIC_INTERVAL: TimeInterval = 0.005
    
    private var hapticFeedbackGenerator: UIImpactFeedbackGenerator?
    private var lastNotificationTimes: [String: Date] = [:]
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastMinDistance: Double?
    private var lastHapticTime: Date?
    
    init() {
        hapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        hapticFeedbackGenerator?.prepare()
    }
    
    func handleDistanceResults(_ detectedResults: [DistanceResult]) {
        let checkDistance = detectedResults.checkDistances()
        
        if !checkDistance.shouldAlert {
            return
        }
        
        guard let minDistance = detectedResults.compactMap({ $0.distance }).min() else {
            return
        }
        
        if isDistanceChanged(for: minDistance) {
            lastMinDistance = minDistance
            
            let text = checkDistance.location
            
            // Perform the notification
            speak(text, force: checkDistance.level == .alert)
        }
        
        // Adjust haptic feedback interval
        let interval = calculateHapticInterval(for: minDistance)
        maybeTriggerHapticFeedback(withInterval: interval)
    }
    
    private func calculateHapticInterval(for distance: Double) -> TimeInterval {
        // Invert the distance to make the interval shorter as the distance decreases
        let maxDistance = max(detectionDistance, warningDistance, alertDistance)
        
        // Normalize the distance to a value between 0 and 1 for mapping to haptic interval
        let normalizedDistance = min(max(distance / maxDistance, 0.0), 1.0)
        
        let adjust = pow(normalizedDistance, 2)
        
        // Invert the normalized distance so that a smaller distance results in a shorter interval
        let invertedDistance = 1.0 - adjust
        
        // Map the inverted distance to the haptic interval range
        return MIN_HAPTIC_INTERVAL + (MAX_HAPTIC_INTERVAL - MIN_HAPTIC_INTERVAL) * (1.0 - invertedDistance)
    }
    
    private func maybeTriggerHapticFeedback(withInterval interval: TimeInterval) {
          guard enableVibration else { return }
          
          let now = Date()
          
          // Check if enough time has passed since the last haptic feedback
          if let lastTime = lastHapticTime, now.timeIntervalSince(lastTime) < interval {
              return // Not enough time has passed, skip triggering haptic feedback
          }
          
          // Trigger haptic feedback and update the last haptic time
          triggerHapticFeedback()
          
          // Calculate the interval in milliseconds
          if let lastTime = lastHapticTime {
              let intervalMilliseconds = now.timeIntervalSince(lastTime) * 1000
              print("Haptic interval: \(intervalMilliseconds) ms")
          }
          
          lastHapticTime = now
      }
    
    private func triggerHapticFeedback() {
        hapticFeedbackGenerator?.impactOccurred()
    }
    
    private func isDistanceChanged(for newDistance: Double) -> Bool {
        // If this is the first check, we should alert
        guard let lastDistance = lastMinDistance else {
            return true
        }
        
        // Check if the new distance decreased or increased by at least the DISTANCE_INTERVAL
        return abs(lastDistance - newDistance) >= DISTANCE_INTERVAL
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
