//
//  AzureAiService.swift
//  Eyeze
//
//  Created by Yanay Hollander on 09/09/2024.
//

import SwiftUI
import SwiftOpenAI

protocol AzureAiServiceProtocol {
    func describeScene(base64Image: String) async throws
}

@Observable class AzureAiService: AzureAiServiceProtocol {
    
    private let azureAiConfig = AzureAiConfig()
    
    private let service: OpenAIService
    
    var response: OpenAIResponse? = nil
    var errorMessage: String = ""
    var message: String = ""
    
    let prompt = """
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
    
    let promptEn = """
                        Consider that a blind person is looking at the picture and describe:
                            1) The potential obsticles
                            2) The people and their facial expressions
                            3) My surrounding
                            Provide a json response according to the following format:
                            {
                                peopleFacial: ""array of object for each person with his location in the picture and it's facial expression in keywords"",
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
    
    init() {
        let azureConfiguration = AzureOpenAIConfiguration(
            resourceName: azureAiConfig.resourceName,
            openAIAPIKey: .apiKey(azureAiConfig.apiKey),
            apiVersion: azureAiConfig.apiVersion)
        
        service = OpenAIServiceFactory.service(azureConfiguration: azureConfiguration)
    }
    
    func describeScene(base64Image: String) async throws {
        
        do {
            let messageContent: [ChatCompletionParameters.Message.ContentType.MessageContent] = [
                .text(prompt),
                .imageUrl(.init(url: URL(string: base64Image)!))
            ]
            let parameters = ChatCompletionParameters(
                messages: [.init(role: .user, content: .contentArray(messageContent))],
                model: .custom(azureAiConfig.deployment),
                logProbs: true,
                topLogprobs: 1)
            
            let choices = try await service.startChat(parameters: parameters).choices
            guard let rawResponse = choices.compactMap(\.message.content).first else {
                self.errorMessage = "Failed to get a valid response from the service."
                return
            }
            
            print(rawResponse)
            
            let cleanedResponse = rawResponse
                .replacingOccurrences(of: "json", with: "")
                .replacingOccurrences(of: "`", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let jsonData = cleanedResponse.data(using: .utf8) else {
                throw NSError(domain: "ParsingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Couldn't parse response"])
            }
            
            self.response = try JSONDecoder().decode(OpenAIResponse.self, from: jsonData)
            
        } catch APIError.responseUnsuccessful(let description) {
            self.errorMessage = "Network error with description: \(description)"
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
