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

    private let SPEAK_DEBOUNCE_DISTANCE: Double = 0.1
    private var useRightSpeaker: Bool = true
    private var lastSpeakTime: Date?
    
    // Store the last spoken texts with their distance and time
     private var lastSpokenData: [String: (distance: Double, time: Date)] = [:]
     
    private var previousDetectedResults: [DistanceResult] = []
    
    init() {
        hapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        hapticFeedbackGenerator?.prepare()
        
        // Pre-warm the AVSpeechSynthesizer on the main thread
        prepareSpeechSynthesizer()
        
        // Pre-set the audio session on the background thread
        prepareAudioSession()
    }

    private func prepareSpeechSynthesizer() {
        // Call a silent utterance on the main thread to prepare the AVSpeechSynthesizer
        DispatchQueue.main.async {
            let silentUtterance = AVSpeechUtterance(string: " ")
            self.speechSynthesizer.speak(silentUtterance)
        }
    }

    private func prepareAudioSession() {
        DispatchQueue.global(qos: .background).async {
            do {
                // Use playAndRecord category with defaultToSpeaker option
                try self.audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
                try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to set audio session category: \(error)")
            }
        }
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
        
        if hasSignificantChanges(from: previousDetectedResults, to: detectedResults) {
            previousDetectedResults = detectedResults

            // Perform the notification
            speak(checkDistance.location, distance: minDistance)
        }

        
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

    
    private func speak(_ text: String, distance: Double) {
        guard enableAlerts else { return }
        
        let now = Date()

        if let lastTime = lastSpeakTime, now.timeIntervalSince(lastTime) < 1 {
            // If the same text was notified less than an interval, ignore it
            return
        }

        lastSpeakTime = now

        DispatchQueue.global(qos: .userInitiated).async {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            
            // Alternate between right and left speakers
            self.useRightSpeaker.toggle()
            
            // Execute speech on the main thread
            DispatchQueue.main.async {
                self.speechSynthesizer.speak(utterance)
            }
        }
    }
    
    private func hasSignificantChanges(from oldResults: [DistanceResult], to newResults: [DistanceResult]) -> Bool {
        // Find the minimum distance from the old results
        guard let oldMinDistance = oldResults.compactMap({ $0.distance }).min() else {
            return true // If no valid minimum distance in old results, consider it a significant change
        }

        // Find the minimum distance from the new results
        guard let newMinDistance = newResults.compactMap({ $0.distance }).min() else {
            return true // If no valid minimum distance in new results, consider it a significant change
        }

        // Sensitivity factor increases as the distance decreases, capped at a maximum value
        let maxSensitivityFactor: Double = 10.0 // Cap the sensitivity factor to avoid excessive sensitivity
        let sensitivityFactor = min(1 / max(newMinDistance, 0.1), maxSensitivityFactor) // Avoid division by zero and excessive sensitivity

        // Define a base threshold
        let baseThreshold = 0.1
        
        // Adjust threshold based on sensitivity
        let adjustedThreshold = baseThreshold * sensitivityFactor

        // Check if the difference between the minimum distances is significant
        return abs(oldMinDistance - newMinDistance) > adjustedThreshold
    }
}

