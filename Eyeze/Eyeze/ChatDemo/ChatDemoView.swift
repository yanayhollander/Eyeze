//
//  ChatDemoView.swift
//  Eyeze
//
//  Created by Yanay Hollander on 09/09/2024.
//
import SwiftUI
import SwiftOpenAI
import AVFoundation

struct ChatDemoView: View {
    
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var azureAiService: AzureAiService
    @State private var isLoading = false
    @State private var base64ImageString: String?
    @State private var errorMessage: String = ""
    // Replace T with the expected response type, e.g., OpenAISceneResponse
    @State private var azureAIResponse: OpenAISceneResponse? = nil

    enum ChatConfig {
        case chatCompletion
        case chatCompletionStream
    }
    
    init() {
        _azureAiService = State(initialValue: AzureAiService())
    }
    
    var body: some View {
        ScrollView {
            VStack {
                textArea
                if let base64String = base64ImageString {
                    if let uiImage = UIImage(base64String: base64String) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .padding()
                    } else {
                        Text("Failed to load image")
                    }
                }
                Text(errorMessage)
                    .foregroundColor(.red)
                chatCompletionResultView
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

    
    var textArea: some View {
        HStack(spacing: 4) {
            Button {
                Task {
//                    isLoading = true
//                    defer { isLoading = false }
//                    
//                    let image = loadTestImage(name: "testImage2")
//                    base64ImageString = image
//  
//                    let result = try await azureAiService.describeScene(base64Image: image, prompt: Prompt.scene.text())
//                    
//                    if let response = result.response {
//                        azureAIResponse = response
//                        response.buildResponseString().speak(speechSynthesizer: speechSynthesizer)
//                    } else if let error = result.errorMessage {
//                        errorMessage = error
//                    }
                }
            } label: {
                Image(systemName: "paperplane")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    var chatCompletionResultView: some View {
        if let response = azureAIResponse {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    // Iterate over peopleFacial
                    ForEach(response.peopleFacial.indices, id: \.self) { index in
                        let person = response.peopleFacial[index]
                        Text("\(String(localized: "person")) \(index + 1):")
                            .font(.subheadline)
                            .bold()
                        Text("\(String(localized: "location")): \(person.location)")
                            .padding(.leading, 8)
                        Text("\(String(localized: "expression")): \(person.expression)")
                            .padding(.leading, 8)
                    }
                    
                    if !response.obstacles.isEmpty {
                        Text("\(String(localized: "obstacles")):")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        ForEach(response.obstacles, id: \.self) { obstacle in
                            Text("- \(obstacle)")
                                .padding(.leading, 8)
                        }
                    }
                    
                    if !response.obstaclesKeywords.isEmpty {
                        Text("\(String(localized: "obstacles_keywords_title")):")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        Text(response.obstaclesKeywords.joined(separator: ", "))
                            .padding(.leading, 8)
                    }
                    
                    if !response.surrounding.isEmpty {
                        Text("\(String(localized: "surrounding")):")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        Text(response.surrounding.joined(separator: ", "))
                            .padding(.leading, 8)
                    }
                    
                    Divider()
                }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding(.horizontal)
            )
        } else {
            return AnyView(Text(""))
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
