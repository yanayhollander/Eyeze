//
//  ChatDemoView.swift
//  Eyeze
//
//  Created by Yanay Hollander on 09/09/2024.
//

import SwiftUI
import SwiftOpenAI

struct ChatDemoView: View {
    
    @State private var azureAiService: AzureAiService
    @State private var isLoading = false

    @State private var selectedSegment: ChatConfig = .chatCompletion
    
    // Add a state variable to hold the base64 string
    @State private var base64ImageString: String?
    
    enum ChatConfig {
        case chatCompletion
        case chatCompeltionStream
    }
    
    init() {
        _azureAiService = State(initialValue: AzureAiService())
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
                Text(azureAiService.errorMessage)
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
                  
                    switch selectedSegment {
                    case .chatCompletion:
                        try await azureAiService.describeScene(base64Image: image)
                    case .chatCompeltionStream:
                        try await azureAiService.describeScene(base64Image: image)
//                        try await chatProvider.startStreamedChat(parameters: parameters)
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
        if let response = azureAiService.response {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    // Iterate over peopleFacial
                    ForEach(response.peopleFacial.indices, id: \.self) { index in
                        let person = response.peopleFacial[index]
                        Text("Person \(index + 1):")
                            .font(.subheadline)
                            .bold()
                        Text("Location: \(person.location)")
                            .padding(.leading, 8)
                        Text("Expression: \(person.expression)")
                            .padding(.leading, 8)
                    }
                    
                    // Display Obstacles
                    if !response.obstacles.isEmpty {
                        Text("Obstacles:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        ForEach(response.obstacles, id: \.self) { obstacle in
                            Text("- \(obstacle)")
                                .padding(.leading, 8)
                        }
                    }
                    
                    // Display Obstacles Keywords
                    if !response.obstaclesKeywords.isEmpty {
                        Text("Obstacles Keywords:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        Text(response.obstaclesKeywords.joined(separator: ", "))
                            .padding(.leading, 8)
                    }
                    
                    // Display Surrounding
                    if !response.surrounding.isEmpty {
                        Text("Surrounding:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        Text(response.surrounding.joined(separator: ", "))
                            .padding(.leading, 8)
                    }
                    
                    Divider() // Adds a separator line between each response
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground)) // Optional: Background color for clarity
                .cornerRadius(8)
                .shadow(radius: 2)
                .padding(.horizontal)
            )
        } else {
            return AnyView(Text("")) // Wrap the Text view with AnyView
        }
    }

    
    /// stream = `true`
    var streamedChatResultView: some View {
        VStack {
            Button("Cancel stream") {
//                azureAiService.cancelStream()
            }
            Text(azureAiService.message)
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


