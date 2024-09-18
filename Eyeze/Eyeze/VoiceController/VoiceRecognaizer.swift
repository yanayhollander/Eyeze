//
//  VoiceController.swift
//  Eyeze
//
//  Created by adam montlake on 16/09/2024.
//

import Foundation
import Speech

class VoiceRecognaizer {
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
         recognitionResult?.bestTranscription.formattedString ?? ""
    }
    
    func isProccesingEnd() -> Bool {
        return recognitionTask.state == .completed
    }
    
    func resetSavedTranscription() {
        recognitionResult = nil
    }
    
    func startRecordToTranscription(language: String = Language.english) {
        guard let recogniazer = SFSpeechRecognizer(locale:  Locale(identifier: language)) else {
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
        recognitionTask?.finish()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        resetAudioSession()
        isRunning = false
        print("Recording stopped.")
    }
    
    private func setupAudioSession(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session")
            return
        }
    }
    
    private func resetAudioSession(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session")
        }
    }
}
