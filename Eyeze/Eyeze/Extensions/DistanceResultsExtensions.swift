//
//  DistanceResultsExtensions.swift
//  Eyeze
//
//  Created by Yanay Hollander on 18/09/2024.
//

import Foundation


let MAX_SQUARE_THRESHOLD = 15

//[[ 1,  2,  3,  4],
// [ 5,  6,  7,  8],
// [ 9,  10, 11, 12],
// [13, 14, 15, 16],
// [17, 18, 19, 20],
// [21, 22, 23, 24],
// [25, 26, 27, 28],
// [29, 30, 31, 32]].
extension [DistanceResult] {
    private func contains(indices: Set<Int>, level: DistanceLevel) -> Int {
        let filtered = self.filter { $0.level == level}
        let detectedCellsSet = Set(filtered.flatMap { $0.detectedCells })
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
            .topLeft: [1,2,5,6,9,10],
            .topRight: [3,4,7,8,11,12],
            .top: [2,3],
            .left: [9,13,17,21],
            .center: [14,15,18,19],
            .right: [12,16,20,24],
            .bottomRight: [23,24,27,28,31,32],
            .bottomLeft: [21,22,25,26,29,30],
            .bottom: [30,31]
        ]
    }
    
    func checkDistances() -> CheckDistanceResult {
        var alertCount = 0
        var warningCount = 0
        var maxAlertCount = 0
        var maxWarningCount = 0
        var alertLocation: String = ""
        var warningLocation: String = ""
        
        for (area, indices) in gridAreas {
            let areaAlertCount = contains(indices: indices, level: .alert)
            let areaWarningCount = contains(indices: indices, level: .warning)
            
            alertCount += areaAlertCount
            warningCount += areaWarningCount
            
            if areaAlertCount > maxAlertCount {
                maxAlertCount = areaAlertCount
                alertLocation = "\(area)"
            }
            
            if areaWarningCount > maxWarningCount {
                maxWarningCount = areaWarningCount
                warningLocation = "\(area)"
            }
        }
        
        if alertCount > MAX_SQUARE_THRESHOLD {
            return CheckDistanceResult(shouldAlert: true, level: .alert, location: "STOP")
        }
        
        if warningCount > MAX_SQUARE_THRESHOLD {
            return CheckDistanceResult(shouldAlert: true, level: .warning, location: "Careful")
        }
        
        if maxAlertCount > 0 {
            return CheckDistanceResult(shouldAlert: true, level: .alert, location: "STOP \(alertLocation))")
        } else if maxWarningCount > 0 {
            return CheckDistanceResult(shouldAlert: true, level: .warning, location: "Careful \(warningLocation))")
        }
        
        return CheckDistanceResult(shouldAlert: false, level: .detection, location: "")
    }
}

struct CheckDistanceResult {
    var shouldAlert: Bool
    var level: DistanceLevel
    var location: String
    
}
