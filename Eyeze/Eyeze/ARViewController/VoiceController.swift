//
//  VoiceController.swift
//  Eyeze
//
//  Created by adam montlake on 16/09/2024.
//

import Foundation
import Speech

class VoiceController {
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest!
    private var recognitionTask: SFSpeechRecognitionTask!
    private var recognitionResult: SFSpeechRecognitionResult!
    
    private var isRunning = false

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized")
            case .denied, .restricted, .notDetermined:
                print("Speech recognition not authorized")
            @unknown default:
                fatalError("Unknown speech recognition authorization status")
            }
        }
    }

    func GetLatestsRecordingTranscription() -> String {
        return recognitionResult?.bestTranscription.formattedString ?? ""
    }
    
    func startRecordToTranscription(language: String = Language.english) {
        guard let recogniazer = SFSpeechRecognizer(locale:  Locale(identifier: "en-US")) else {
            print("Speech recognition is not available on this device")
            return
        }
        
        setupAudioSession()
        
        if (self.isRunning){
            stopRecording()
        }
        isRunning = true
        
        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        recognitionTask = recogniazer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.recognitionResult = result
            } else if let error = error {
                print("Error transcribing audio: \(error.localizedDescription)")
            }
        }
        
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest.append(buffer)
        }
        
        do {
            try audioEngine.start()
            print("Recording started. Say something!")
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        recognitionRequest.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        print("Recording stopped.")
    }
    
    private func setupAudioSession(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session")
            return
        }
    }
}
