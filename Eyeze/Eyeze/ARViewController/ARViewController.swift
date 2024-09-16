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

class ARViewController: UIViewController, ARSessionDelegate {
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @AppStorage("enableVibration") private var enableVibration: Bool = true
    @AppStorage("detectionDistance") private var detectionDistance: Double = DistanceLevel.DETECTION_DEFAULT_VALUE
    @AppStorage("warningDistance") private var warningDistance: Double = DistanceLevel.DETECTION_WARNING_VALUE
    @AppStorage("alertDistance") private var alertDistance: Double = DistanceLevel.DETECTION_ALERT_VALUE
    
    private var azureAiService: AzureAiService = AzureAiService()
    
    private var arView: ARSCNView!
    private var hapticFeedbackGenerator: UIImpactFeedbackGenerator?
    private var distanceLabels: [UILabel] = []
    private let audioSession = AVAudioSession.sharedInstance()
    
    private var captureContainer: UIView!
    private var captureButton: UIButton!
    private var responseTextView: UITextView!
    
    private var responseText: String = ""
    private var processingText: String = ""
    private var promptText: String = ""
    
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
        distanceLabels = labelPoints.all.map { createDistanceLabel(for: view, at: $0) }
        distanceLabels.forEach {
            view.addSubview($0)
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
        
        // Setup Response TextView
        responseTextView = UITextView()
        responseTextView.translatesAutoresizingMaskIntoConstraints = false
        responseTextView.isEditable = false
        responseTextView.isScrollEnabled = true
        responseTextView.backgroundColor = .lightGray
        responseTextView.textColor = .black
        responseTextView.font = UIFont.systemFont(ofSize: 16)
        responseTextView.isHidden = false  // Make sure it's not hidden
        responseTextView.alpha = 0.7
        captureContainer.addSubview(responseTextView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            captureContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            captureContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            captureContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            captureContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16), // Ensure it stretches to the bottom
            
            captureButton.topAnchor.constraint(equalTo: captureContainer.topAnchor),
            captureButton.trailingAnchor.constraint(equalTo: captureContainer.trailingAnchor, constant: -30),
            captureButton.heightAnchor.constraint(equalToConstant: 50),
            captureButton.widthAnchor.constraint(equalToConstant: 200),
            
            responseTextView.topAnchor.constraint(equalTo: captureButton.bottomAnchor, constant: 16),
            responseTextView.leadingAnchor.constraint(equalTo: captureContainer.leadingAnchor, constant: 16),
            responseTextView.trailingAnchor.constraint(equalTo: captureContainer.trailingAnchor, constant: -16),
            responseTextView.bottomAnchor.constraint(equalTo: captureContainer.bottomAnchor, constant: -16)
        ])
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
        guard let arFrame = captureCurrentFrame() else {
            print("Failed to capture image.")
            return
        }

        startTimer()
        
        Task {
            do {
                guard let image = convertFrameToUIImage(arFrame),
                      let base64Image = image.toBase64String() else {
                    print("Failed to capture image.")
                    return
                }
                let distanceArray = self.detectedResults.map { distanceResult in
                    Float(distanceResult.distance)
                }
                let prompt = Prompt.obstacles(distancesArray: distanceArray).text()
                
                DispatchQueue.main.async {
                    self.responseTextView.isHidden = false
                    self.promptText = prompt
                    self.responseText = ""
                    self.updateResponseTextView()
                }
                
                let azureAIResponse = try await azureAiService.describeObstacles(base64Image: base64Image, prompt: prompt)
     
                print("describeObstacles description successfully retrieved.")
                
                DispatchQueue.main.async {
                    self.stopTimer() // Stop the timer when the response is received
                    if let response = azureAIResponse.response {
                        let responseString = response
                        self.responseText = responseString
                        self.updateResponseTextView()
                        responseString.speak(speechSynthesizer: self.speechSynthesizer)
                    }
                }
            } catch {
                print("Failed to describe obstacles: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.responseTextView.text = "\(self.processingText)\nFailed to describe obstacles: \(error.localizedDescription)"
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
        processingText = String(format: "Processing... %.1f seconds", elapsedTime)
        updateResponseTextView()
        
    }
    
    func updateResponseTextView() {
        responseTextView.text = """
                                \(processingText)
                                Prompt:\n
                                \(promptText)
                                \n\n
                                Response:\n
                                \(responseText)
                                """
        responseTextView.scrollRangeToVisible(NSRange(location: responseTextView.text.count - 1, length: 1))
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func capureButtonTappedRapper() -> MPRemoteCommandHandlerStatus{
        captureButtonTapped()
        return .success
    }
    
    private func setupRemoteCommandCenter() {
        MPRemoteCommandCenter.shared()
            .playCommand.addTarget(self, action: #selector(capureButtonTappedRapper))
        MPRemoteCommandCenter.shared()
            .stopCommand.addTarget(self, action: #selector(capureButtonTappedRapper))
    }
 }
