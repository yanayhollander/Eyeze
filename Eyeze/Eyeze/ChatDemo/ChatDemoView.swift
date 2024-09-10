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
    
    @State private var speechSynthesizer = AVSpeechSynthesizer() // Initialize directly
    @State private var azureAiService: AzureAiService
    @State private var isLoading = false
    @State private var selectedSegment: ChatConfig = .chatCompletion
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
                    defer { isLoading = false }
                    
                    let image = loadTestImage(name: "testImage2")
                    base64ImageString = image
                    
                    switch selectedSegment {
                    case .chatCompletion:
                        try await azureAiService.describeScene(base64Image: image)
                    case .chatCompeltionStream:
                        try await azureAiService.describeScene(base64Image: image)
                    }
                    
                    if let response = azureAiService.response {
                        speak(response: response) // Call the text-to-speech function
                    }
                }
            } label: {
                Image(systemName: "paperplane")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    var chatCompletionResultView: some View {
        if let response = azureAiService.response {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    // Iterate over peopleFacial
                    ForEach(response.peopleFacial.indices, id: \.self) { index in
                        let person = response.peopleFacial[index]
                        Text("איש \(index + 1):")
                            .font(.subheadline)
                            .bold()
                        Text("מיקום: \(person.location)")
                            .padding(.leading, 8)
                        Text("הבעת פנים: \(person.expression)")
                            .padding(.leading, 8)
                    }
                    
                    if !response.obstacles.isEmpty {
                        Text("מכשולים:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        ForEach(response.obstacles, id: \.self) { obstacle in
                            Text("- \(obstacle)")
                                .padding(.leading, 8)
                        }
                    }
                    
                    if !response.obstaclesKeywords.isEmpty {
                        Text("מכשולים פוטנציאלים:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        Text(response.obstaclesKeywords.joined(separator: ", "))
                            .padding(.leading, 8)
                    }
                    
                    if !response.surrounding.isEmpty {
                        Text("סביבה:")
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
    
    var streamedChatResultView: some View {
        VStack {
            Button("Cancel stream") {
                // Cancel stream logic
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
    
    func speak(response: OpenAIResponse) {
        
        let text = buildResponseString(response: response)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "he-IL")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(utterance)
    }
    
    func buildResponseString(response: OpenAIResponse) -> String {
        var result = ""
        
        // Iterate over the peopleFacial array with indices
        for (index, person) in response.peopleFacial.enumerated() {
            result += "איש \(index + 1):\n"
            result += "מיקום: \(person.location).\n"
            result += "הבעת פנים: \(person.expression).\n"
        }
        
        // Add obstacles if there are any
        if !response.obstacles.isEmpty {
            result += "מכשולים:\n"
            for obstacle in response.obstacles {
                result += "- \(obstacle).\n"
            }
        }
        
        // Add obstacle keywords if there are any
        if !response.obstaclesKeywords.isEmpty {
            result += "מכשולים פוטנציאלים: \(response.obstaclesKeywords.joined(separator: ", ")).\n"
        }
        
        // Add surrounding details if there are any
        if !response.surrounding.isEmpty {
            result += "סביבה: \(response.surrounding.joined(separator: ", ")).\n"
        }
        
        return result
    }
}
