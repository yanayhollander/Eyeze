//
//  DistanceResultsExtensions.swift
//  Eyeze
//
//  Created by Yanay Hollander on 18/09/2024.
//

import Foundation


let MAX_SQUARE_THRESHOLD = 15

//[[ 0,  1,  2,  3],
// [ 4,  5,  6,  7],
// [ 8,  9, 10, 11],
// [12, 13, 14, 15],
// [16, 17, 18, 19],
// [20, 21, 22, 23],
// [24, 25, 26, 27],
// [28, 29, 30, 31]].
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
        case center = "Forward"
        case right = "Right"
        case bottomRight = "Bottom Right"
        case bottomLeft = "Bottom Left"
        case bottom = "Bottom"
    }
    
    private var gridAreas: [GridArea: Set<Int>] {
        return [
            .topLeft: [0,1,4,5,8,9],
            .topRight: [2,3,6,7,10,11],
            .top: [1,2],
            .left: [8,12,16,20],
            .center: [13,14,17,18],
            .right: [11,15,19,23],
            .bottomRight: [22,23,26,27,30,31],
            .bottomLeft: [20,21,24,25,28,29],
            .bottom: [29,30]
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
