//
//  AzureAiService.swift
//  Eyeze
//
//  Created by Yanay Hollander on 09/09/2024.
//

import SwiftUI
import SwiftOpenAI

typealias AzureAIResponse<T> = (response: T?, errorMessage: String?)

protocol AzureAiServiceProtocol {
    func describeObstacles(base64Image: String, prompt: String) async throws -> AzureAIResponse<OpenAIObstaclesResponse>
    func describeScene(base64Image: String, prompt: String) async throws -> AzureAIResponse<OpenAISceneResponse>
}

@Observable class AzureAiService: AzureAiServiceProtocol {
    
    private let azureAiConfig = AzureAiConfig()
    private let service: OpenAIService
    
    init() {
        let azureConfiguration = AzureOpenAIConfiguration(
            resourceName: azureAiConfig.resourceName,
            openAIAPIKey: .apiKey(azureAiConfig.apiKey),
            apiVersion: azureAiConfig.apiVersion)
        
        service = OpenAIServiceFactory.service(azureConfiguration: azureConfiguration)
    }
    
    func describeObstacles(base64Image: String, prompt: String) async throws -> AzureAIResponse<OpenAIObstaclesResponse> {
        return try await describe(base64Image: base64Image, prompt: prompt)
    }

    func describeScene(base64Image: String, prompt: String) async throws -> AzureAIResponse<OpenAISceneResponse> {
        return try await describe(base64Image: base64Image, prompt: prompt)
    }
    
    private func describe<T: Decodable> (base64Image: String, prompt: String) async throws -> AzureAIResponse<T> {
        var errorMessage: String? = nil
        
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
                return (nil, "Failed to get a valid response from the service.")
            }
            
            print(rawResponse)
            
            let cleanedResponse = rawResponse
                .replacingOccurrences(of: "json", with: "")
                .replacingOccurrences(of: "`", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let jsonData = cleanedResponse.data(using: .utf8) else {
                throw NSError(domain: "ParsingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Couldn't parse response"])
            }
            
            let response = try JSONDecoder().decode(T.self, from: jsonData)
            return (response, errorMessage)
        } catch APIError.responseUnsuccessful(let description) {
            errorMessage = "Network error with description: \(description)"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        return (nil, errorMessage)
    }
}
