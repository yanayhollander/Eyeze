//
//  File.swift
//  Eyeze
//
//  Created by Yanay Hollander on 16/09/2024.
//

import Foundation

enum Prompt {
    case obstacles(square: Int, distance: Float)
    case scene
    
    func text() -> String {
        switch self {
        case .obstacles(let square, let distance):
            return OBSTACLE
                .replacingOccurrences(of: "SQUARE_INDEX", with: "\(square)")
                .replacingOccurrences(of: "ESTIMATE_DISTANCE", with: String(format: "%.1f", distance))
        case .scene:
            return SCENE
        }
    }
}

private let OBSTACLE = """
    Given an image, logically divide it into 32 equal squares, like a 4x8 grid, and assume the image is divided as follows:
    Square 1: top-left
    Square 4: top-right
    Square 29: bottom-left
    Square 32: bottom-right
    and so on.
    Focus on square SQUARE_INDEX estimated distance ESTIMATE_DISTANCEm, based on this section, please provide a json response according to the following format:
        {
            obstaclesKeywords: "array of strings describes the two main obstacles in keywords that a blind man should watchout if there are"
            obstaclesAvoid: "a string indicating the direction to avoid the obstacles, including the angle in degrees (0 is forward, 0-90 to the right, and 0-90 to the left) and the distance in meters to proceed, if possible. Example: 'Move right at 45 degrees for 2 meters.', another example 'Move left at 10 degrees for 1.5 meters.'"
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
