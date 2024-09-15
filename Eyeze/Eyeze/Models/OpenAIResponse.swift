//
//  DescribeSceneResponse.swift
//  Eyeze
//
//  Created by Yanay Hollander on 09/09/2024.
//

struct OpenAIResponse: Codable {
    let peopleFacial: [Person]
    let obstacles: [String]
    let obstaclesKeywords: [String]
    let surrounding: [String]
    
    func buildResponseString() -> String {
        var result = ""
        
        // Iterate over the peopleFacial array with indices
        for (index, person) in peopleFacial.enumerated() {
            result += "person \(index + 1):\n"
            result += "location: \(person.location).\n"
            result += "expression: \(person.expression).\n"
        }
        
        // Add obstacles if there are any
        if !obstacles.isEmpty {
            result += "obstacles:\n"
            for obstacle in obstacles {
                result += "- \(obstacle).\n"
            }
        }
        
        // Add obstacle keywords if there are any
        if !obstaclesKeywords.isEmpty {
            result += "Obstacles Keywords: \(obstaclesKeywords.joined(separator: ", ")).\n"
        }
        
        // Add surrounding details if there are any
        if !surrounding.isEmpty {
            result += "Surrounding: \(surrounding.joined(separator: ", ")).\n"
        }
        
        return result
    }
}

struct Person: Codable {
    let location: String
    let expression: String
}
