//
//  AzureAiService.swift
//  Eyeze
//
//  Created by Yanay Hollander on 09/09/2024.
//

import SwiftUI
import SwiftOpenAI

@Observable class AzureAiService {
    
    private let azureAiConfig = AzureAiConfig()
    private let service: OpenAIService
    var message: String = ""
    var errorMessage: String? = nil
    
    init() {
        let azureConfiguration = AzureOpenAIConfiguration(
            resourceName: azureAiConfig.resourceName,
            openAIAPIKey: .apiKey(azureAiConfig.apiKey),
            apiVersion: azureAiConfig.apiVersion)
        
        service = OpenAIServiceFactory.service(azureConfiguration: azureConfiguration)
    }

    public func describeStream(base64Image: String, prompt: String) async throws {
        do {
            self.message = ""
            let messageContent: [ChatCompletionParameters.Message.ContentType.MessageContent] = [
                .text(prompt),
                .imageUrl(.init(url: URL(string: base64Image)!))
            ]
            let parameters = ChatCompletionParameters(
                messages: [.init(role: .user, content: .contentArray(messageContent))],
                model: .custom(azureAiConfig.deployment),
                logProbs: true,
                topLogprobs: 1)
            
            let stream = try await service.startStreamedChat(parameters: parameters)
            for try await result in stream {
                let content = result.choices.first?.delta.content ?? ""
                self.message += content
           }

        } catch APIError.responseUnsuccessful(let description) {
            self.errorMessage = "Network error with description: \(description)"
            self.message = ""
        } catch {
            self.errorMessage = error.localizedDescription
            self.message = ""
        }
    }
}

