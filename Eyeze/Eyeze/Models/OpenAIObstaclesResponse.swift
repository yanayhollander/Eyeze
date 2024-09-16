//
//  OpenAIObstaclesResponse.swift
//  Eyeze
//
//  Created by Yanay Hollander on 16/09/2024.
//

import Foundation

struct OpenAIObstaclesResponse: Codable {

    let obstaclesKeywords: [String]
    let obstaclesAvoid: String
    
    func buildResponseString() -> String {
        var result = ""

        if !obstaclesKeywords.isEmpty {
            result += "Careful from obstacles: \(obstaclesKeywords.joined(separator: ", ")).\n"
        }

        if !obstaclesAvoid.isEmpty {
            result += "Avoid them by: \(obstaclesAvoid).\n"
        }
        
        return result
    }
}
