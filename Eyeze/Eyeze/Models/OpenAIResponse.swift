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
}

struct Person: Codable {
    let location: String
    let expression: String
}
