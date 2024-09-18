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

    let audioSession = AVAudioSession.sharedInstance()
    
    private let DISTANCE_INTERVAL = 0.1
    private let MAX_HAPTIC_INTERVAL: TimeInterval = 5.0
    private let MIN_HAPTIC_INTERVAL: TimeInterval = 0.005
    
    private var hapticFeedbackGenerator: UIImpactFeedbackGenerator?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastMinDistance: Double?
    private var lastHapticTime: Date?

    private let MIN_SPEAK_INTERVAL: TimeInterval = 2.0

    private let SPEAK_DEBOUNCE_DISTANCE: Double = 10.0
       private var useRightSpeaker: Bool = true
    // Store the last spoken texts with their distance and time
     private var lastSpokenData: [String: (distance: Double, time: Date)] = [:]
     
    
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
        

        // Adjust haptic feedback interval
        let interval = calculateHapticInterval(for: minDistance)
        maybeTriggerHapticFeedback(withInterval: interval)
        
        // Perform the notification
                speak(checkDistance.location, force: checkDistance.level == .alert, distance: minDistance)
        
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
          
          lastHapticTime = now
      }
    
    private func triggerHapticFeedback() {
        hapticFeedbackGenerator?.impactOccurred()
    }

    
    private func speak(_ text: String, force: Bool, distance: Double) {
        guard enableAlerts else { return }
        
        let now = Date()
        
        // Check if this text was spoken before
        if let lastData = lastSpokenData[text] {
            // Calculate the distance difference
            let distanceDifference = lastData.distance - distance
            // Check if the distance has decreased by more than the debounce distance
            if distanceDifference < SPEAK_DEBOUNCE_DISTANCE { 
 
//                // If the distance has not decreased enough, and not enough time has passed
//                if now.timeIntervalSince(lastData.time) < MIN_SPEAK_INTERVAL {
//                    return // Ignore if the change is less than debounce distance and not enough time has passed
//                }
                return
            }
        }
        
        // Update the last spoken data
        lastSpokenData[text] = (distance: distance, time: now)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            
            // Alternate between right and left speakers
            self.useRightSpeaker.toggle()
            
            // Update audio session category
            do {
                try self.audioSession.setCategory(.playback, options: self.useRightSpeaker ? .defaultToSpeaker : .mixWithOthers)
                try self.audioSession.setActive(true)
            } catch {
                print("Failed to set audio session category: \(error)")
            }
            
            // Execute speech on the main thread
            DispatchQueue.main.async {
                print("SPEAK \(text)")
//                self.speechSynthesizer.speak(utterance)
            }
        }
    }
}


//print("SPEAK \(text)")
//print("SPEAK \(text)")
//print("SPEAK \(text)")
//print("SPEAK \(text)")

