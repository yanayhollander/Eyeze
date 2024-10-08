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
    The given image is logically divide into 8x4 grid as:
    [[ 0,  1,  2,  3],
     [ 4,  5,  6,  7],
     [ 8,  9, 10, 11],
     [12, 13, 14, 15],
     [16, 17, 18, 19],
     [20, 21, 22, 23],
     [24, 25, 26, 27],
     [28, 29, 30, 31]].
    All the cells are size equal.
    Image left side is [0, 4, 8, 12, 16, 20, 24, 28]
    Image left center side is: [1, 5, 9, 13, 17, 21, 25, 29]
    Image right center side is: [2, 6, 10, 14, 18, 22, 26, 30]
    Image right side is: [3, 7, 11, 15, 19, 23, 27, 31]
    Image top is: [0, 1, 2, 3]
    Image bottom is: [28, 29, 30, 31]

    DistanceArray = [DISTANCES_ARRAY]
    The DistanceArray above includes 32 cells corresponding to the grid above by index. Each cell in the DistanceArray contain
    the distance of the nearest obstcale in the cell frame.
    
    Your target is to help blind people to navigate around obstacles.
    You should detrmine obstacle by determine the nearest object in the image which you can do it by the DistanceArray data.
    - Don't mention cells in your response
    - Do guide only for the nearest obstacle
    - Do use human step instead of meter
    - Do mention the obstcale title like its name (e.g. Table, Banana)
    - Do short guidance
    - Don't guide to step back if you see something in front of you, give guide to move around it from left or right instead
    - Don't mirror the image

    Guidance example: You have a table in your center left side, pls move one step to the right
"""



let SCENE = """
    Describe the image for your's blind friend. He is in the same room and needs your description to understand his surrounding.
    Guidance:
    - Don't repeat yourself
    - Don't use the word image and blind
    - Write it short, 2 sentence max.
    - Describe the facial expressions generally
    - Don't describe your's friend feelings
    - Don't replace the friend with any person in the image
    - Don't assume anything about the blind friend
"""
