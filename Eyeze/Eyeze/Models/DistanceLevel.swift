//
//  DistanceLevel.swift
//  Eyeze
//
//  Created by Yanay Hollander on 15/09/2024.
//

import Foundation

enum DistanceLevel: String, CaseIterable, Identifiable {
    case detection = "Detection"
    case warning = "Warning"
    case alert = "Alert"
    
    static let DETECTION_DEFAULT_VALUE = 1.5
    static let DETECTION_WARNING_VALUE = 1.0
    static let DETECTION_ALERT_VALUE = 0.5
    
    var id: String { rawValue }
}
