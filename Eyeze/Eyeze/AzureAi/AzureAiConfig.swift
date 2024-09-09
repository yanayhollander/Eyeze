//
//  AzureAiConfig.swift
//  Eyeze
//
//  Created by Yanay Hollander on 09/09/2024.
//

import SwiftUI
import SwiftOpenAI

struct AzureAiConfig {
    let resourceName: String
    let apiKey: String
    let apiVersion: String
    let deployment: String
    
    init() {
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else {
            fatalError("Info.plist file not found")
        }
        guard let azureAiResourceName: String = infoDictionary["AzureAiResourceName"] as? String else {
            fatalError("AzureAIResourceName was not set in Info.plist")
        }
        guard let azureAiApiKey: String = infoDictionary["AzureAiApiKey"] as? String else {
            fatalError("AzureAIApiKey was not set in Info.plist")
        }
        guard let azureAiApiVersion: String = infoDictionary["AzureAiApiVersion"] as? String else {
            fatalError("AzureAIApiVersion was not set in Info.plist")
        }
        
        guard let azureAiDeployment: String = infoDictionary["AzureAiDeployment"] as? String else {
            fatalError("AzureAiDeployment was not set in Info.plist")
        }
        
        self.resourceName = azureAiResourceName
        self.apiKey = azureAiApiKey
        self.apiVersion = azureAiApiVersion
        self.deployment = azureAiDeployment
    }
}
