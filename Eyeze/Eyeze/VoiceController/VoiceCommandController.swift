//
//  VoiceController.swift
//  Eyeze
//
//  Created by adam montlake on 17/09/2024.
//

import Foundation
import AVFoundation

@objc class VoiceCommandController: NSObject {
    private var voiceRecognaizer = VoiceRecognaizer()
    private var commands: [String: () -> Void]
    private var onCommandNotFound: () -> Void
    
    override init() {
        self.commands = [:]
        onCommandNotFound = {}
        super.init()
    }
    
    func setOnCommandNotFound(defultAction: @escaping () -> Void ){
        onCommandNotFound = defultAction
    }
    
    func addCommand(_ command: String, action: @escaping () -> Void) {
        commands[command] = action
    }
    
    @objc func startListening(languege: String = Language.english) {
        voiceRecognaizer.startRecordToTranscription()
    }
    
    func execute(transcription: String) {
        voiceRecognaizer.stopRecording()
        let command = voiceRecognaizer.GetLatestsRecordingTranscription()
        
        if let action = commands[command] {
            action()
        } else {
            onCommandNotFound()
        }
    }
}
