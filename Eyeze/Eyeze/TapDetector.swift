//
//  File.swift
//  Eyeze
//
//  Created by Yanay Hollander on 17/09/2024.
//

import UIKit
import CoreMotion

protocol TapDetectorDelegate: AnyObject {
    func tapDetectorDidDetectDoubleTap(_ tapDetector: TapDetector)
}

class TapDetector {
    private let motionManager = CMMotionManager()
    private var tapCount = 0
    private var tapTimer: Timer?
    private var lastTapDate: Date?
    private var lastAcceleration: CMAcceleration?
    private var lastDoubleTapDate: Date? // Added to track the last double-tap
    weak var delegate: TapDetectorDelegate?
    
    init() {
//        startDetectingTaps()
    }

    private func startDetectingTaps() {
        if motionManager.isAccelerometerAvailable {
            // Increase update frequency for more sensitivity
            motionManager.accelerometerUpdateInterval = 0.05 // More frequent updates
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data else { return }
                let acceleration = data.acceleration

                // Check for significant change from the last acceleration
                if let lastAcceleration = self.lastAcceleration {
                    let deltaX = abs(acceleration.x - lastAcceleration.x)
                    let deltaY = abs(acceleration.y - lastAcceleration.y)
                    let deltaZ = abs(acceleration.z - lastAcceleration.z)

                    // Adjust these values based on your testing
                    if deltaX > 0.25 || deltaY > 0.25 || deltaZ > 0.25 {
                        self.detectTap()
                    }
                }

                // Store the current acceleration for the next update
                self.lastAcceleration = acceleration
            }
        }
    }

    private func detectTap() {
 
        
        let currentTime = Date()
        if let lastTapDate = self.lastTapDate, currentTime.timeIntervalSince(lastTapDate) < 0.5 {
            // Increment tap count if within double/triple tap time frame
            tapCount += 1
        } else {
            // Reset tap count and start new tap sequence
            tapCount = 1
        }
        print("tapCount = \(tapCount)")

        // Update last tap date
        lastTapDate = currentTime

        // Cancel any existing timer and start a new one
        tapTimer?.invalidate()
        tapTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.handleTaps()
        }
    }

    private func handleTaps() {
        print("handleTaps - Tap Count: \(tapCount)")
        if tapCount >= 2 && tapCount <= 4 {
            // Check if the last double-tap was detected more than 5 seconds ago
            let currentTime = Date()
            if let lastDoubleTapDate = self.lastDoubleTapDate, currentTime.timeIntervalSince(lastDoubleTapDate) < 5.0 {
                // If not enough time has passed, ignore the tap
                print("Ignoring double tap due to cooldown period")
                return
            }

            handleDoubleTap()
            // Update last double-tap date
            lastDoubleTapDate = currentTime
        } else {
            // Optionally handle or ignore other tap counts if needed
            print("Tap count out of range: \(tapCount)")
        }
        // Reset tap count after handling
        tapCount = 0
    }

    private func handleDoubleTap() {
        // Handle the double tap logic here
        print("Double tap detected!")
        
        // Notify the delegate about the double tap
        delegate?.tapDetectorDidDetectDoubleTap(self)
    }

    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}
