//
//  ARViewController.swift
//  Eyeze
//
//  Created by Yanay Hollander on 03/09/2024.
//

import UIKit
import ARKit
import SwiftUI
import MediaPlayer

struct ARViewContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ARViewController {
        return ARViewController()
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
    }
}

class ARViewController: UIViewController, ARSessionDelegate, AVSpeechSynthesizerDelegate {
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @AppStorage("enableVibration") private var enableVibration: Bool = true
    @AppStorage("enableDebug") private var enableDebug: Bool = false
    @AppStorage("detectionDistance") private var detectionDistance: Double = DistanceLevel.DETECTION_DEFAULT_VALUE
    @AppStorage("warningDistance") private var warningDistance: Double = DistanceLevel.DETECTION_WARNING_VALUE
    @AppStorage("alertDistance") private var alertDistance: Double = DistanceLevel.DETECTION_ALERT_VALUE
    
    private var azureAiService: AzureAiService = AzureAiService()
    
    private var arView: ARSCNView!
    private var hapticFeedbackGenerator: UIImpactFeedbackGenerator?
    private var distanceLabels: [UILabel] = []
    private let audioSession = AVAudioSession.sharedInstance()
    
    private var captureContainer: UIView!
    private var distanceLabelsContainer: UIView!
    private var captureButton: UIButton!
    private var captureButtonS: UIButton!
    private var responseTextView: UITextView!
    
    private var processingText: String = ""
    
    // Store the last notification times for different texts
    private var lastNotificationTimes: [String: Date] = [:]
    private let DEBOUNCE_INTERVAL = 1.0
    
    private var hasDrawnDistanceLabels = false
    var detectedResults: [DistanceResult] = []
    
    private var timer: Timer?
    private var elapsedTime: TimeInterval = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupHapticFeedback()
        setupCaptureContainer()
        setupRemoteCommandCenter()
        speechSynthesizer.delegate = self
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Re-enable the idle timer
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !hasDrawnDistanceLabels {
            drawDistanceLabels()
            hasDrawnDistanceLabels = true
        }
    }
    
    // MARK: - ARSessionDelegate Methods
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        detectMultiplePoints()
    }
    
    // MARK: - Setup Methods
    private func setupARView() {
        arView = ARSCNView()
        arView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arView)
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            arView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            arView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)
        arView.session.delegate = self
    }
    
    private func setupHapticFeedback() {
        hapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        hapticFeedbackGenerator?.prepare()
    }
    
    private func drawDistanceLabels() {
        let labelPoints = DistanceUtils.getScreenPoints(for: view)
        distanceLabelsContainer = UIView()
        view.addSubview(distanceLabelsContainer)
        
        distanceLabels = labelPoints.all.map { createDistanceLabel(for: view, at: $0) }
        distanceLabels.forEach {
            distanceLabelsContainer.addSubview($0)
        }
    }
    
    private func setupCaptureContainer() {
        captureContainer = UIView()
        captureContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureContainer)
        
        // Setup Capture Button
        captureButton = UIButton(type: .system)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.setTitle("Capture Frame", for: .normal)
        captureButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold) // Larger font for accessibility
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.backgroundColor = .systemBlue
        captureButton.layer.cornerRadius = 10
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        captureContainer.addSubview(captureButton)
        
        captureButtonS = UIButton(type: .system)
        captureButtonS.translatesAutoresizingMaskIntoConstraints = false
        captureButtonS.setTitle("Capture Scene", for: .normal)
        captureButtonS.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold) // Larger font for accessibility
        captureButtonS.setTitleColor(.white, for: .normal)
        captureButtonS.backgroundColor = .systemBlue
        captureButtonS.layer.cornerRadius = 10
        captureButtonS.addTarget(self, action: #selector(describeScene), for: .touchUpInside)
        captureContainer.addSubview(captureButtonS)
        
        // Setup Response TextView
        responseTextView = UITextView()
        responseTextView.translatesAutoresizingMaskIntoConstraints = false
        responseTextView.isEditable = false
        responseTextView.isScrollEnabled = true
        responseTextView.backgroundColor = .lightGray
        responseTextView.textColor = .black
        responseTextView.font = UIFont.systemFont(ofSize: 16)
        responseTextView.isHidden = false  // Make sure it's not hidden
        responseTextView.alpha = 0.0
        responseTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        captureContainer.addSubview(responseTextView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            captureContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            captureContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            captureContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            captureContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0), // Ensure it stretches to the bottom
            
            captureButton.topAnchor.constraint(equalTo: captureContainer.topAnchor),
            captureButton.trailingAnchor.constraint(equalTo: captureContainer.trailingAnchor, constant: -30),
            captureButton.heightAnchor.constraint(equalToConstant: 50),
            captureButton.widthAnchor.constraint(equalToConstant: 200),

            captureButtonS.topAnchor.constraint(equalTo: captureContainer.topAnchor, constant: 55),
            captureButtonS.trailingAnchor.constraint(equalTo: captureContainer.trailingAnchor, constant: -30),
            captureButtonS.heightAnchor.constraint(equalToConstant: 50),
            captureButtonS.widthAnchor.constraint(equalToConstant: 200),
            
            responseTextView.leadingAnchor.constraint(equalTo: captureContainer.leadingAnchor, constant: 0),
            responseTextView.trailingAnchor.constraint(equalTo: captureContainer.trailingAnchor, constant: 0),
            responseTextView.heightAnchor.constraint(equalToConstant: 100),
            responseTextView.bottomAnchor.constraint(equalTo: captureContainer.bottomAnchor, constant: 100) // Position it off-screen
        ])
        
        captureContainer.layoutIfNeeded()
    }
    
    func showResponseTextView(withText text: String) {
        // Set the text
        responseTextView.text = text
        responseTextView.textColor = .black
        responseTextView.textAlignment = .left
        view.bringSubviewToFront(captureContainer)

        // Update the bottom constraint to bring the view into view
        for constraint in captureContainer.constraints {
            if constraint.firstItem as? UITextView == responseTextView && constraint.firstAttribute == .bottom {
                constraint.constant = 0
            }
        }

        // Animate the transition
        UIView.animate(withDuration: 0.5, animations: {
            self.captureContainer.layoutIfNeeded()
            self.responseTextView.alpha = 0.9 // Animate alpha
        })
    }
    
    func hideResponseTextView() {
        responseTextView.text = ""
        responseTextView.alpha = 0.0

        // Update the bottom constraint to bring the view into view
        for constraint in captureContainer.constraints {
            if constraint.firstItem as? UITextView == responseTextView && constraint.firstAttribute == .bottom {
                constraint.constant = 100
            }
        }

        // Animate the transition
        UIView.animate(withDuration: 0.5, animations: {
            self.captureContainer.layoutIfNeeded()
            self.responseTextView.alpha = 0.0 // Animate alpha
        })
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        hideResponseTextView()
    }
    
    // MARK: - Detection and Feedback Methods
    private func detectMultiplePoints() {
        let screenPoints = DistanceUtils.getScreenPoints(for: view)
        var closestDistance: Float = .infinity
        self.detectedResults = []
        
        // Iterate through all screen points
        for (index, point) in screenPoints.all.enumerated() {
            let hitTestResults = arView.hitTest(point, types: [.existingPlaneUsingExtent, .featurePoint])
            if let result = hitTestResults.first {
                let distance = Float(result.distance)
                closestDistance = min(closestDistance, distance)
                
                // Get distance result
                let distanceResult = DistanceUtils.onDistanceUpdate(
                    distance: Double(distance),
                    detectionDistance: detectionDistance,
                    warningDistance: warningDistance,
                    alertDistance: alertDistance,
                    screenPoints: screenPoints,
                    point: point
                )
                
                self.detectedResults.append(distanceResult)
            }
        }
        
        DispatchQueue.main.async {
            for(index, point) in self.detectedResults.enumerated() {
                // Update the distance label
                DistanceUtils.updateDistanceLabel(self.distanceLabels[index], distance: point.distance, distanceLevel: point.level)
            }
            
            if (self.detectedResults.shouldAlert(distance: self.alertDistance)) {
                self.triggerHapticFeedback()
            }
            // Process the detectedResults as needed, e.g., triggering haptic feedback for certain cells
            //            if self.detectedResults.isTop() {
            //                self.notify("TOP")
            //            }
            //
            //            if detectedResults.isCenter() {
            //                self.notify("Center")
            //            }
            //
            //            if detectedResults.isBottom() {
            //                self.notify("Bottom")
            //            }
        }
    }
    
    private func notify(_ text: String) {
        let now = Date()
        if let lastTime = lastNotificationTimes[text], now.timeIntervalSince(lastTime) < DEBOUNCE_INTERVAL {
            // If the same text was notified less than an interval, ignore it
            return
        }
        
        // Update the last notification time for this text
        lastNotificationTimes[text] = now
        
        // Perform the notification
        print(text)
    }
    
    private func triggerHapticFeedback() {
        if enableVibration {
            self.notify("FIRE!!")
            hapticFeedbackGenerator?.impactOccurred()
        }
    }
    
    // MARK: - Helper Methods
    private func createDistanceLabel(for view: UIView, at point: CGPoint) -> UILabel {
        let layoutFrame = view.safeAreaLayoutGuide.layoutFrame
        
        // Calculate the width and height of each square in the 4x4 grid
        let squareWidth = layoutFrame.width / 4
        let squareHeight = layoutFrame.height / 8
        
        let label = UILabel()
        label.frame = CGRect(x: point.x, y: point.y, width: squareWidth, height: squareHeight)
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }
    
    private func captureCurrentFrame() -> ARFrame? {
        guard let currentFrame = arView.session.currentFrame else {
            print("No current frame available.")
            return nil
        }
        
        return currentFrame
    }
    
    private func convertFrameToUIImage(_ arFrame: ARFrame) -> UIImage? {
        let pixelBuffer = arFrame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage.")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    @objc private func captureButtonTapped() {
        
        Task {
            do {
                let distanceArray = self.detectedResults.map { distanceResult in
                    Float(distanceResult.distance)
                }
                let prompt = Prompt.obstacles(distancesArray: distanceArray).text()
                
                try await TriggerPromptOnCurrentScreen(prompt: prompt)
                
            } catch {
                print("Failed to describe obstacles: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.responseTextView.text = "\(self.processingText)\nFailed to describe obstacles: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func TriggerPromptOnCurrentScreen(prompt: String) async throws {
        guard let arFrame = captureCurrentFrame() else {
            print("Failed to capture image.")
            return
        }
        
        DispatchQueue.main.async {
            self.showResponseTextView(withText: "Processing...")
            self.startTimer()
        }
        
        Task {
            guard let image = convertFrameToUIImage(arFrame),
                  let base64Image = image.toBase64String() else {
                print("Failed to capture image.")
                return
            }
            

            try await azureAiService.describeStream(base64Image: base64Image, prompt: prompt)
            
            print("description successfully retrieved.")
            
            DispatchQueue.main.async {
                self.stopTimer() // Stop the timer when the response is received
                if !self.azureAiService.message.isEmpty {
                    self.showResponseTextView(withText: self.azureAiService.message)
                    self.azureAiService.message.speak(speechSynthesizer: self.speechSynthesizer)
                }
                
                if let error = self.azureAiService.errorMessage {
                    self.showResponseTextView(withText: error)
                }
            }
        }
    }
    
    private func startTimer() {
        elapsedTime = 0.0
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    @objc private func updateTimer() {
        elapsedTime += 0.1
        responseTextView.text = String(format: "Processing... %.1f seconds", elapsedTime)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func setupRemoteCommandCenter() {
        MPRemoteCommandCenter.shared()
            .playCommand.addTarget(self, action: #selector(capureButtonTappedRapper))
        MPRemoteCommandCenter.shared()
            .stopCommand.addTarget(self, action: #selector(capureButtonTappedRapper))
        MPRemoteCommandCenter.shared()
            .togglePlayPauseCommand.addTarget(self, action: #selector(capureButtonTappedRapper))
        MPRemoteCommandCenter.shared()
            .pauseCommand.addTarget(self, action: #selector(capureButtonTappedRapper))
        MPRemoteCommandCenter.shared()
            .nextTrackCommand.addTarget(self, action: #selector(describeSceneRapper))
        MPRemoteCommandCenter.shared()
            .previousTrackCommand.addTarget(self, action: #selector(describeSceneRapper))
    }
    
    @objc private func capureButtonTappedRapper() -> MPRemoteCommandHandlerStatus{
        captureButtonTapped()
        return .success
    }
    
    @objc private func describeScene() {
        Task {
            do {
                try await TriggerPromptOnCurrentScreen(prompt: Prompt.scene.text())
            } catch {
                print("Failed to describe scenes: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.responseTextView.text = "\(self.processingText)\nFailed to describe obstacles: \(error.localizedDescription)"
                }
            }
        }
    }
    
    @objc private func describeSceneRapper() -> MPRemoteCommandHandlerStatus {
        describeScene()
        return .success
    }
}
