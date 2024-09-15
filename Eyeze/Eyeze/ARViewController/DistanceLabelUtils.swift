//
//  DistanceLabelUtils.swift
//  Eyeze
//
//  Created by Yanay Hollander on 07/09/2024.
//

import UIKit
import ARKit

/// Utility class for managing distance labels.
class DistanceLabelUtils {
    /// Returns an array of CGPoint for placing distance labels on the screen.
    static func getScreenPoints(for view: UIView) -> [CGPoint] {
        let safeAreaInsets = view.safeAreaInsets
        let bottomInset = safeAreaInsets.bottom

        return [
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.minX, y: view.safeAreaLayoutGuide.layoutFrame.minY + 80),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.midX, y: view.safeAreaLayoutGuide.layoutFrame.minY + 80),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.maxX - 80, y: view.safeAreaLayoutGuide.layoutFrame.minY + 80),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.minX, y: view.safeAreaLayoutGuide.layoutFrame.midY),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.midX, y: view.safeAreaLayoutGuide.layoutFrame.midY),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.maxX - 80, y: view.safeAreaLayoutGuide.layoutFrame.midY),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.minX, y: view.safeAreaLayoutGuide.layoutFrame.maxY - 120 - bottomInset),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.midX, y: view.safeAreaLayoutGuide.layoutFrame.maxY - 120 - bottomInset),
            CGPoint(x: view.safeAreaLayoutGuide.layoutFrame.maxX - 80, y: view.safeAreaLayoutGuide.layoutFrame.maxY - 120 - bottomInset)
        ]
    }

    static func onDistanceUpdate(distance: Double, detectionDistance: Double, warningDistance: Double, alertDistance: Double) -> DistanceLevel? {
        if (distance < alertDistance) {
            return .alert
        } else if distance < warningDistance {
            return .warning
        } else if distance < detectionDistance {
            return .detection
        }
        
        return nil
    }
    
    /// Updates the distance label's text and color based on the distance.
    static func updateDistanceLabel(_ label: UILabel, distance: Float, distanceLevel: DistanceLevel?) {
 
        label.text = String(format: "%.2f m", distance)
        
        var textColor = UIColor.white
        var alpha = 0.3
        
        switch distanceLevel {
        case .alert:
            textColor = UIColor.red
            alpha = 1.0
            break
        case .warning:
            textColor = UIColor.orange
            alpha = 0.7
            break
        default:
            break
        }
        
        label.textColor = textColor
        label.alpha = alpha
       
    }
}
