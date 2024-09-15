//
//  DistanceLabelUtils.swift
//  Eyeze
//
//  Created by Yanay Hollander on 07/09/2024.
//

import UIKit
import ARKit

struct ScreenPoints {
    var top: [CGPoint]
    var center: [CGPoint]
    var bottom: [CGPoint]
    var left: [CGPoint]
    var right: [CGPoint]
    var all: [CGPoint] {
        return top + center + bottom
    }
}

struct DistanceResult {
    
}

/// Utility class for managing distance labels.
class DistanceUtils {
    /// Returns an array of CGPoint for placing distance labels on the screen.
    static func getScreenPoints(for view: UIView) -> ScreenPoints {
        let safeAreaInsets = view.safeAreaInsets
        let bottomInset = safeAreaInsets.bottom

        let topPoints = [
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.minX, y: view.safeAreaLayoutGuide.layoutFrame.minY + 80),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.midX, y: view.safeAreaLayoutGuide.layoutFrame.minY + 80),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.maxX - 80, y: view.safeAreaLayoutGuide.layoutFrame.minY + 80)
        ]

        let centerPoints = [
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.minX, y: view.safeAreaLayoutGuide.layoutFrame.midY),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.midX, y: view.safeAreaLayoutGuide.layoutFrame.midY),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.maxX - 80, y: view.safeAreaLayoutGuide.layoutFrame.midY)
        ]

        let bottomPoints = [
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.minX, y: view.safeAreaLayoutGuide.layoutFrame.maxY - 120 - bottomInset),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.midX, y: view.safeAreaLayoutGuide.layoutFrame.maxY - 120 - bottomInset),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.maxX - 80, y: view.safeAreaLayoutGuide.layoutFrame.maxY - 120 - bottomInset)
        ]

        return ScreenPoints(top: topPoints, center: centerPoints, bottom: bottomPoints, left: [topPoints[0], centerPoints[0], bottomPoints[0]], right: [topPoints[2], centerPoints[2], bottomPoints[2]])
    }
    
    static func onDistanceUpdate(distance: Double, detectionDistance: Double, warningDistance: Double, alertDistance: Double, screenPoints: ScreenPoints, point: CGPoint) -> DistanceLevel? {
        
        var distanceLevel: DistanceLevel? = nil
        
        if (distance < alertDistance) {
            distanceLevel = .alert
        } else if distance < warningDistance {
            distanceLevel = .warning
        } else if distance < detectionDistance {
            distanceLevel = .detection
        }
        
//        // Check if the point is in the top group and is below the threshold
//        if screenPoints.top.contains(point), distanceLevel == .alert {
//            topPointDetectedBelowThreshold = true
//        }
        
        return distanceLevel
    }
    
    /// Updates the distance label's text and color based on the distance.
    static func updateDistanceLabel(_ label: UILabel, distance: CGFloat, distanceLevel: DistanceLevel?) {
        
        label.text = String(format: "%.2f m", distance)
        
        var textColor = UIColor.white
        var alpha = 0.3
        
        switch distanceLevel {
        case .detection:
            break
        case .warning:
            textColor = UIColor.orange
            alpha = 0.7
            break
        case .alert:
            textColor = UIColor.red
            alpha = 1.0
            break
        default:
            break
        }
        
        
        label.textColor = textColor
        label.alpha = alpha
        
    }
}
