//
//  File.swift
//  Eyeze
//
//  Created by Yanay Hollander on 16/09/2024.
//

import Foundation

enum Prompt {
    case obstacles(distancesArray: [Float])
    case scene
    
    func text() -> String {
        switch self {
        case .obstacles(let distancesArray):
            // Format each distance to one decimal place
            let formattedDistances = distancesArray.map { String(format: "%.2f", $0) }
            // Join the formatted distances into a single string
            let distancesString = "[" + formattedDistances.joined(separator: ", ") + "]"
            // Replace the placeholder with the formatted distances
            return OBSTACLE.replacingOccurrences(of: "[DISTANCES_ARRAY]", with: distancesString)
        case .scene:
            return SCENE
        }
    }
}

private let OBSTACLE = """
You are provided with an image divided into a 4x8 grid, resulting in 32 equal squares. Each square corresponds to a specific position within the grid:
Square 1: top-left, Square 4: top-right, Square 29: bottom-left, Square 32: bottom-right
Given an array [DISTANCES_ARRAY] representing estimated distances in meters for each square, your task is to generate a JSON response to assist a blind person navigating potential obstacles in the image. The distances in the array correspond to the squares in the grid as follows:
1.Detailed Instructions:
a. Only Return JSON: Provide the output strictly in JSON format as shown above. Do not include any additional text, explanations, or comments outside of the JSON response.
b. Identify the Two Closest Obstacles: Determine the two obstacles with the shortest distances from the viewer. Sort them from the closest to the farthest.
c. Describe Obstacles: For each obstacle, create a string that includes the obstacle's type and its relative angle in degrees. For example, 'Chair 45 degrees to your left.'
d. Determine Avoidance Direction: Based on the closest obstacle, suggest whether to move left or right to avoid it. Provide a clear explanation of why this direction is chosen, considering the obstacle's position relative to the viewer.
2. Provide a JSON response with the following structure:
    {
        "obstaclesKeywords": "array of strings describing the two closest obstacles, sorted from nearest to farthest. Include the obstacle's keyword, his approximate distance in meter and its direction from my point of view (left/right/forward). Example: 'Chair in 0.20m to your left.'",
        "obstaclesAvoid": "a string indicating the direction to move (left/right/forward) to avoid the closest obstacle. Include an explanation for the chosen direction based on the obstacle's location. Example: 'Move right because the chair is on the left.'"
    }
"""



let SCENE = """
    Consider that a blind person is looking at the picture and describe:
        1) The potential obsticles
        2) The people and their facial expressions
        3) My surrounding
        Provide a json response according to the following format:
        {
            peopleFacial: "array of object for each person with his location in the picture and it's facial expression in keywords",
            obstacles: "array of strings describe the obstacles in the picture",
            obstaclesKeywords: "array of strings describes the obstacles in keywords"
            surrounding: "array of strings describe the surrounding in keywords",
        }

        for example:
        {
            peopleFacial: [{
                location: "top left",
                expression: "focused"
            }],
            obstacles: ["The desktop computer and surroundings might create a cluttered space", "potentially limiting movement.", "The robot's presence could also be intimidating."],
            obstaclesKeywords: ["desktop computer", "clutter", "robot presence"],
            surrounding: ["modern office environment", "city skyline view", "high tech decor", "blue lighting"]
        }
"""


let promptHe = """
    Consider that a blind person speak in Hebrew is looking at the picture and describe:
        1) The potential obsticles
        2) The people and their facial expressions
        3) My surrounding
        Provide a json response in Hebrew according to the following format:
        {
            peopleFacial: "array of object for each person with his location in the picture and it's facial expression in keywords",
            obstacles: "array of strings describe the obstacles in the picture",
            obstaclesKeywords: "array of strings describes the obstacles in keywords"
            surrounding: "array of strings describe the surrounding in keywords",
        }

        for example:
        {
            peopleFacial: [{
                location: "ימין למעלה",
                expression: "מפוקס"
            }],
            obstacles: ["נוכחות של רובוט עלולה לבלבל", "המחשב יכול לגרום לקושי בהנחה על השולחן.", "הדלת של הארון. פתוחה."],
            obstaclesKeywords: ["מחשב שולחני", "מחשב", "דגל של ארון"],
            surrounding: ["סביבה משרדית מודרנית", "נוף של קו השמיים של העיר", "עיצוב טכנולוגי מתוחכם", "תאורה כחולה"]
        }
"""
