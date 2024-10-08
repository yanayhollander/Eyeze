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

class ARViewController: UIViewController, ARSessionDelegate, AVSpeechSynthesizerDelegate, TapDetectorDelegate {
    private var detectionHandler = DetectionHandler()
    private var isProcessing = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @AppStorage("enableVibration") private var enableVibration: Bool = true
    @AppStorage("enableDebug") private var enableDebug: Bool = false
    @AppStorage("detectionDistance") private var detectionDistance: Double = DistanceLevel.DETECTION_DEFAULT_VALUE
    @AppStorage("warningDistance") private var warningDistance: Double = DistanceLevel.DETECTION_WARNING_VALUE
    @AppStorage("alertDistance") private var alertDistance: Double = DistanceLevel.DETECTION_ALERT_VALUE
    
    private var azureAiService: AzureAiService = AzureAiService()
    private var tapDetector: TapDetector = TapDetector()
    private var arView: ARSCNView!
    private var hapticFeedbackGenerator: UIImpactFeedbackGenerator?
    private var distanceLabels: [UILabel] = []
    private let audioSession = AVAudioSession.sharedInstance()
    
    private var buttonsContainer: UIView!
    private var distanceLabelsContainer: UIView!
    private var describeObstaclesButton: UIButton!
    private var describeSceneButton: UIButton!
    private var responseTextView: UITextView!
    
    private var processingText: String = ""

    private var hasDrawnDistanceLabels = false
    var detectedResults: [DistanceResult] = []
    
    private var timer: Timer?
    private var elapsedTime: TimeInterval = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupHapticFeedback()
      
        setupRemoteCommandCenter()
        speechSynthesizer.delegate = self
        
        tapDetector.delegate = self
        setupButtonsContainer()
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
        
        view.bringSubviewToFront(buttonsContainer)
    }
    
    private func setupButtonsContainer() {
        buttonsContainer = UIView()
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsContainer)

        // Setup Describe Scene Button
        describeSceneButton = UIButton(type: .system)
        describeSceneButton.translatesAutoresizingMaskIntoConstraints = false
        describeSceneButton.setTitleColor(.systemGray, for: .normal)
        describeSceneButton.backgroundColor = .clear
        describeSceneButton.layer.cornerRadius = 0
        describeSceneButton.addTarget(self, action: #selector(describeScene), for: .touchUpInside)
        
        // Single-tap action using the existing target
        describeSceneButton.addTarget(self, action: #selector(describeScene), for: .touchUpInside)

        // Double-tap action
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(describeObstacles))
        doubleTapGesture.numberOfTapsRequired = 2
        describeSceneButton.addGestureRecognizer(doubleTapGesture)

        // Single-tap gesture (to differentiate between single and double taps)
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(describeScene))
        singleTapGesture.numberOfTapsRequired = 1
        // Ensure the single tap is recognized only if the double tap fails
        singleTapGesture.require(toFail: doubleTapGesture)
        describeSceneButton.addGestureRecognizer(singleTapGesture)
        
        buttonsContainer.addSubview(describeSceneButton)
        
        // Setup Response TextView
        responseTextView = UITextView()
        responseTextView.translatesAutoresizingMaskIntoConstraints = false
        responseTextView.isEditable = false
        responseTextView.isScrollEnabled = true
        responseTextView.backgroundColor = .lightGray
        responseTextView.textColor = .black
        responseTextView.font = UIFont.systemFont(ofSize: 16)
        responseTextView.isHidden = false
        responseTextView.alpha = 0.0
        responseTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        buttonsContainer.addSubview(responseTextView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            buttonsContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            buttonsContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            buttonsContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            buttonsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // describeSceneButton Constraints
            describeSceneButton.topAnchor.constraint(equalTo: buttonsContainer.topAnchor), // Align to the top of the container
            describeSceneButton.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor), // Place next to describeObstaclesButton
            describeSceneButton.heightAnchor.constraint(equalTo: buttonsContainer.heightAnchor),
            describeSceneButton.widthAnchor.constraint(equalTo: buttonsContainer.widthAnchor),// Set width to 50% of the container
            
            responseTextView.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor),
            responseTextView.trailingAnchor.constraint(equalTo: buttonsContainer.trailingAnchor),
            responseTextView.heightAnchor.constraint(equalToConstant: 100),
            responseTextView.bottomAnchor.constraint(equalTo: buttonsContainer.bottomAnchor, constant: 100) // Position it off-screen
        ])
        
        // Bring buttonsContainer to front
        view.bringSubviewToFront(buttonsContainer)
    }
    
    func showResponseTextView(withText text: String) {
        // Set the text
        responseTextView.text = text
        responseTextView.textColor = .black
        responseTextView.textAlignment = .left
        view.bringSubviewToFront(buttonsContainer)
        
        // Update the bottom constraint to bring the view into view
        for constraint in buttonsContainer.constraints {
            if constraint.firstItem as? UITextView == responseTextView && constraint.firstAttribute == .bottom {
                constraint.constant = 0
            }
        }
        
        // Animate the transition
        UIView.animate(withDuration: 0.5, animations: {
            self.buttonsContainer.layoutIfNeeded()
            self.responseTextView.alpha = 0.9 // Animate alpha
        })
    }
    
    func hideResponseTextView() {
        responseTextView.text = ""
        responseTextView.alpha = 0.0
        
        // Update the bottom constraint to bring the view into view
        for constraint in buttonsContainer.constraints {
            if constraint.firstItem as? UITextView == responseTextView && constraint.firstAttribute == .bottom {
                constraint.constant = 100
            }
        }
        
        // Animate the transition
        UIView.animate(withDuration: 0.5, animations: {
            self.buttonsContainer.layoutIfNeeded()
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
        for (_, point) in screenPoints.all.enumerated() {
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
            
            self.detectionHandler.handleDistanceResults(self.detectedResults)
        }
    }
    

    private func triggerHapticFeedback() {
        if enableVibration {
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
    
    @objc private func describeObstacles() {
        
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
        
        guard !isProcessing else {
            print("Operation already in progress.")
            return
        }
        
        isProcessing = true // Set flag to indicate processing has started
        
        guard let arFrame = captureCurrentFrame() else {
            print("Failed to capture image.")
            return
        }
        
        DispatchQueue.main.async {
            self.showResponseTextView(withText: "Processing...")
            self.startTimer()
        }
        
        
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
                self.azureAiService.message.speak(onEnd: self.hideResponseTextView)
            }
            
            if let error = self.azureAiService.errorMessage {
                self.showResponseTextView(withText: error)
            }
            
            self.isProcessing = false
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
        describeObstacles()
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
    
    func tapDetectorDidDetectDoubleTap(_ tapDetector: TapDetector) {
        // Handle the double tap event in your view controller
        //        describeObstacles()
    }
}
