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
        print("start listening")
    }
    
    @objc func execute() {
        DispatchQueue.global(qos: .background).async {
            self.voiceRecognaizer.stopRecording()
            
            while !self.voiceRecognaizer.isProccesingEnd(){
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
            }
            
            DispatchQueue.main.async {
                let command = self.voiceRecognaizer.GetLatestsRecordingTranscription()
                if let action = self.commands[command] {
                    print("executing command \(command)")
                    action()
                } else {
                    print("failed to find command")
                    self.onCommandNotFound()
                }
            }
        }
    }
}
