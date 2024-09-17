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
    var all: [CGPoint] {
        return top + center + bottom
    }
}

struct DistanceResult {
    var level: DistanceLevel?
    var distance: Double
    var detectedCells: [Int] = []
}

/// Utility class for managing distance labels.
class DistanceUtils {
    static func getScreenPoints(for view: UIView) -> ScreenPoints {
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
        
        let topPoints = Array(points[0...7])
        let centerPoints = Array(points[8...23])
        let bottomPoints = Array(points[24...31])
        
        return ScreenPoints(top: topPoints, center: centerPoints, bottom: bottomPoints)
    }
    
    static func onDistanceUpdate(distance: Double, detectionDistance: Double, warningDistance: Double, alertDistance: Double, screenPoints: ScreenPoints, point: CGPoint) -> DistanceResult {
        
        var distanceResult = DistanceResult(
            level: nil,
            distance: distance
        )
        
        // Determine the distance level
        if distance < alertDistance {
            distanceResult.level = .alert
        } else if distance < warningDistance {
            distanceResult.level = .warning
        } else if distance < detectionDistance {
            distanceResult.level = .detection
        }
        
        // Check which cell the point belongs to and add it to the detectedCells
        if let cellIndex = getCellIndex(for: point, in: screenPoints) {
            distanceResult.detectedCells.append(cellIndex)
        }
        
        return distanceResult
    }
    
    private static func getCellIndex(for point: CGPoint, in screenPoints: ScreenPoints) -> Int? {
        // Mapping each point to its corresponding cell index (1-9)
        let allPoints = screenPoints.top + screenPoints.center + screenPoints.bottom
        if let index = allPoints.firstIndex(of: point) {
            return index + 1 // Convert zero-based index to 1-based
        }
        return nil
    }
    
    /// Updates the distance label's text and color based on the distance.
    static func updateDistanceLabel(_ label: UILabel, distance: Double, distanceLevel: DistanceLevel?) {
        // Update the label text to show the distance
        label.text = String(format: "%.2f m", distance)
        
        // Set default values for background color and text color
        var bgColor = UIColor(white: 1.0, alpha: 0.0) // Light gray background with some transparency
        var textColor = UIColor.white
        // Ensure distance is clamped to a range of [0.0, 1.0] for color interpolation
        let clampedDistance = max(0.0, min(1.0, CGFloat(distance)))
        let intensity = 1.0 - clampedDistance // Invert distance for intensity
        
        switch distanceLevel {
        case .alert:
            // In alert mode, use a gradient from orange to light red to strong red
            textColor = UIColor.white
            // Gradient from orange to light red to strong red
            let redComponent = min(1.0, intensity + 1.0) // Red increases with lower distance
            let greenComponent = max(0.0, 0.5 - intensity) // Green decreases with lower distance
            let blueComponent = max(0.0, 0.5 - intensity) // Blue decreases with lower distance
            bgColor = UIColor(red: redComponent, green: greenComponent, blue: blueComponent, alpha: 0.5)
            break
            
        case .warning:
            // In warning mode, use a gradient from light yellow to orange
            textColor = UIColor.black
            // Gradient from light yellow to orange
            let redComponent = min(1.0, 1.0 - (0.5 - intensity)) // Red increases with lower distance
            let greenComponent = min(1.0, 1.0 - (0.5 - intensity)) // Green increases with lower distance
            let blueComponent = 0.0 // Blue stays at 0
            bgColor = UIColor(red: redComponent, green: greenComponent, blue: blueComponent, alpha: 0.5)
            break
            
        default:
            // Default mode, no changes
            break
        }
        
        // Apply the colors and transparency to the label
        label.backgroundColor = bgColor
        label.textColor = textColor
    }
}
//[[ 0,  1,  2,  3],
// [ 4,  5,  6,  7],
// [ 8,  9, 10, 11],
// [12, 13, 14, 15],
// [16, 17, 18, 19],
// [20, 21, 22, 23],
// [24, 25, 26, 27],
// [28, 29, 30, 31]].
extension [DistanceResult] {
    private func contains(indices: Set<Int>, belowDistance: Double) -> Int {
        let detectedCellsSet = Set(self.flatMap { $0.detectedCells })
        // Count how many cells are in the detected set and are below the given distance
        return detectedCellsSet.intersection(indices).count
    }

        // Grid area definitions
        private enum GridArea: String {
            case topLeft = "Top Left"
            case topRight = "Top Right"
            case top = "Top"
            case left = "Left"
            case center = "Center"
            case right = "Right"
            case bottomRight = "Bottom Right"
            case bottomLeft = "Bottom Left"
            case bottom = "Bottom"
        }

    private var gridAreas: [GridArea: Set<Int>] {
        return [
            .topLeft: [0, 1, 4, 5],
            .topRight: [2, 3, 6, 7],
            .top: [0, 1, 2, 3, 4, 5, 6, 7],
            .left: [0, 4, 8, 12, 16, 20],
            .center: [9, 10, 13, 14, 17, 18, 21, 22],
            .right: [11, 15, 19, 23],
            .bottomRight: [26, 27, 30, 31],
            .bottomLeft: [24, 25, 28, 29],
            .bottom: [24, 25, 26, 27, 28, 29, 30, 31]
        ]
    }

    func checkDistances(alertDistance: Double, warningDistance: Double) -> CheckDistanceResult {
        var maxAlertCount = 0
        var maxWarningCount = 0
        var alertLocation: String? = nil
        var warningLocation: String? = nil
        
        for (area, indices) in gridAreas {
            let alertCount = contains(indices: indices, belowDistance: alertDistance)
            let warningCount = contains(indices: indices, belowDistance: warningDistance)
            
            // Debugging output
            print("Area: \(area.rawValue), Alert Count: \(alertCount), Warning Count: \(warningCount)")
            
            if alertCount > maxAlertCount {
                maxAlertCount = alertCount
                alertLocation = "\(area)"
            }
            
            if warningCount > maxWarningCount {
                maxWarningCount = warningCount
                warningLocation = "\(area)"
            }
        }
        
        if maxAlertCount > 0 {
            return CheckDistanceResult(shouldAlert: true, level: .alert, location: alertLocation ?? "")
        } else if maxWarningCount > 0 {
            return CheckDistanceResult(shouldAlert: true, level: .warning, location: warningLocation ?? "")
        }
        
        return CheckDistanceResult(shouldAlert: false, level: .detection, location: "")
    }
}

struct CheckDistanceResult {
    var shouldAlert: Bool
    var level: DistanceLevel
    var location: String
    
}
