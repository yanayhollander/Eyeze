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
        let layoutFrame = view.safeAreaLayoutGuide.layoutFrame

        // Calculate the width and height of each square in the 4x4 grid
        let squareWidth = layoutFrame.width / 4
        let squareHeight = layoutFrame.height / 8

        // Generate the 4x4 grid points
        var points: [CGPoint] = []
        for j in 0..<8 { // Iterate over rows
            for i in 0..<4 { // Iterate over columns
                // Calculate the center of each square
                let centerX = layoutFrame.minX + (squareWidth * CGFloat(i))
                let centerY = layoutFrame.minY + (squareHeight * CGFloat(j))
                points.append(CGPoint(x: centerX, y: centerY))
            }
        }
        
        return points
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
        // Update the label text to show the distance
        label.text = String(format: "%.2f m", distance)
        
        // Set default values for background color and text color
        var bgColor = UIColor(white: 1.0, alpha: 0.5) // Light gray background with some transparency
        var textColor = UIColor.white
        var alpha = 0.3
        
        // Ensure distance is clamped to a range of [0.0, 1.0] for color interpolation
        let clampedDistance = max(0.0, min(1.0, CGFloat(distance)))
        
        switch distanceLevel {
        case .alert:
            // In alert mode, use a shade of red that changes with distance
            textColor = UIColor.red
            alpha = 1.0
            // Darker red for lower distances, lighter red for higher distances
            bgColor = UIColor(red: 1.0, green: 1.0 - clampedDistance, blue: 1.0 - clampedDistance, alpha: 0.5)
            
        case .warning:
            // In warning mode, use a shade of orange that changes with distance
            textColor = UIColor.orange
            alpha = 0.7
            // Darker orange for lower distances, lighter orange for higher distances
            bgColor = UIColor(red: 1.0, green: 0.5 + 0.5 * clampedDistance, blue: 0.0, alpha: 0.5)
            
        default:
            // Default mode, no changes
            break
        }
        
        // Apply the colors and transparency to the label
        label.backgroundColor = bgColor
        label.textColor = textColor
        label.alpha = alpha
    }

}
