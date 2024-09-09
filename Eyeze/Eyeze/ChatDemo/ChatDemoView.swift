//
//  ChatDemoView.swift
//  Eyeze
//
//  Created by Yanay Hollander on 09/09/2024.
//

import SwiftUI
import SwiftOpenAI

struct ChatDemoView: View {
    
    @State private var chatProvider: ChatProvider
    @State private var isLoading = false
    @State private var prompt = """
                        Consider that a blind person is looking at the picture and describe:
                            1) The potential obsticles
                            2) The people and their facial expressions
                            3) My surrounding
                            Provide a json response according to the following format:
                            {{
                                peopleFacial: ""key value pairs of each person with his location in the picture and it's facial expression in keywords"",
                                obstacles: ""Describe the obstacles in the picture"",
                                obstaclesKeywords: ""Describe the obstacles in keywords""
                                surrounding: ""Describe the surrounding in keywords"",
                            }}
                    """
    @State private var selectedSegment: ChatConfig = .chatCompletion
    @State private var azureAiDeployment = ""
    
    // Add a state variable to hold the base64 string
    @State private var base64ImageString: String?
    
    enum ChatConfig {
        case chatCompletion
        case chatCompeltionStream
    }
    
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
        
        self.azureAiDeployment = azureAiDeployment
        
        let azureConfiguration = AzureOpenAIConfiguration(
            resourceName: azureAiResourceName,
            openAIAPIKey: .apiKey(azureAiApiKey),
            apiVersion: azureAiApiVersion)
        
        let service = OpenAIServiceFactory.service(azureConfiguration: azureConfiguration)
        _chatProvider = State(initialValue: ChatProvider(service: service))
    }
    
    var body: some View {
        ScrollView {
            VStack {
                picker
                textArea
                if let base64String = base64ImageString {
                    // Display the image
                    if let uiImage = UIImage(base64String: base64String) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200) // Adjust the size as needed
                            .padding()
                    } else {
                        Text("Failed to load image")
                    }
                }
                Text(chatProvider.errorMessage)
                    .foregroundColor(.red)
                switch selectedSegment {
                case .chatCompeltionStream:
                    streamedChatResultView
                case .chatCompletion:
                    chatCompletionResultView
                }
            }
        }
        .overlay(
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    EmptyView()
                }
            }
        )
    }
    
    var picker: some View {
        Picker("Options", selection: $selectedSegment) {
            Text("Chat Completion").tag(ChatConfig.chatCompletion)
            Text("Chat Completion stream").tag(ChatConfig.chatCompeltionStream)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    var textArea: some View {
        HStack(spacing: 4) {
            Button {
                Task {
                    isLoading = true
                    defer { isLoading = false }  // ensure isLoading is set to false when the task completes
                    
                    let image = loadTestImage(name: "testImage2")
                    base64ImageString = image // Store the base64 string
                    
                    let messageContent: [ChatCompletionParameters.Message.ContentType.MessageContent] = [.text(prompt), .imageUrl(.init(url: URL(string: image)!))]
                    let parameters = ChatCompletionParameters(messages: [.init(role: .user, content: .contentArray(messageContent))],
                                                              model: .custom(azureAiDeployment),
                                                              logProbs: true,
                                                              topLogprobs: 1)
                    
                    prompt = ""
                    switch selectedSegment {
                    case .chatCompletion:
                        try await chatProvider.startChat(parameters: parameters)
                    case .chatCompeltionStream:
                        try await chatProvider.startStreamedChat(parameters: parameters)
                    }
                }
            } label: {
                Image(systemName: "paperplane")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    /// stream = `false`
    var chatCompletionResultView: some View {
        ForEach(Array(chatProvider.messages.enumerated()), id: \.offset) { idx, val in
            VStack(spacing: 0) {
                Text("\(val)")
            }
        }
    }
    
    /// stream = `true`
    var streamedChatResultView: some View {
        VStack {
            Button("Cancel stream") {
                chatProvider.cancelStream()
            }
            Text(chatProvider.message)
        }
    }
    
    func loadTestImage(name: String) -> String {
        guard let image = UIImage(named: name) else {
            fatalError("Image not found in assets")
        }
        
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            fatalError("Failed to convert image to JPEG data")
        }
        
        let mediaType = "image/jpeg"
        let dataUrlString = "data:\(mediaType);base64,\(imageData.base64EncodedString())"
        return dataUrlString
    }
}

extension UIImage {
    convenience init?(base64String: String) {
        let components = base64String.components(separatedBy: ",")
        guard components.count == 2, let data = Data(base64Encoded: components[1]) else {
            return nil
        }
        self.init(data: data)
    }
}
