//
//  ARViewController.swift
//  Eyeze
//
//  Created by Yanay Hollander on 03/09/2024.
//

import UIKit
import ARKit
import SwiftUI

struct ARViewContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ARViewController {
        return ARViewController()
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
    }
}

class ARViewController: UIViewController, ARSessionDelegate {
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @AppStorage("enableVibration") private var enableVibration: Bool = false
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
    
    // Store the last notification times for different texts
    private var lastNotificationTimes: [String: Date] = [:]
    private let DEBOUNCE_INTERVAL = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupHapticFeedback()
        setupCaptureContainer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        drawDistanceLabels()
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
        hapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
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
        responseTextView.isHidden = true
        responseTextView.alpha = 0.7
        captureContainer.addSubview(responseTextView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            captureContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            captureContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            captureContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            
            captureButton.topAnchor.constraint(equalTo: captureContainer.topAnchor),
            captureButton.rightAnchor.constraint(equalTo: captureContainer.rightAnchor, constant: -30),
            captureButton.heightAnchor.constraint(equalToConstant: 50),
            captureButton.widthAnchor.constraint(equalToConstant: 200),
            captureButton.bottomAnchor.constraint(equalTo: captureContainer.bottomAnchor, constant: -10), // Added bottom constraint
            
            responseTextView.topAnchor.constraint(equalTo: captureButton.bottomAnchor, constant: 16),
            responseTextView.leftAnchor.constraint(equalTo: captureContainer.leftAnchor, constant: 30),
            responseTextView.heightAnchor.constraint(equalToConstant: 180),
            responseTextView.rightAnchor.constraint(equalTo: captureContainer.rightAnchor, constant: -30)
        ])
    }
    
    // MARK: - Detection and Feedback Methods
    private func detectMultiplePoints() {
        let screenPoints = DistanceUtils.getScreenPoints(for: view)
        var closestDistance: Float = .infinity
        
        var detectedResults: [DistanceResult] = []
        
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
                                
                detectedResults.append(distanceResult)
            }
        }
        
        DispatchQueue.main.async {
            for(index, point) in detectedResults.enumerated() {
                // Update the distance label
                DistanceUtils.updateDistanceLabel(self.distanceLabels[index], distance: point.distance ?? .infinity, distanceLevel: point.level)
            }
        
            // Process the detectedResults as needed, e.g., triggering haptic feedback for certain cells
            if detectedResults.isTop() {
                self.notify("TOP")
            }
            
            if detectedResults.isCenter() {
                self.notify("Center")
            }
            
            if detectedResults.isBottom() {
                self.notify("Bottom")
            }
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
        
        Task {
            do {
                guard let image = convertFrameToUIImage(arFrame),
                      let base64Image = image.toBase64String() else {
                    print("Failed to capture image.")
                    return
                }
                
                DispatchQueue.main.async {
                    self.responseTextView.isHidden = false
                    self.responseTextView.text = "Loading..."
                }
                try await azureAiService.describeScene(base64Image: base64Image)
                print("Scene description successfully retrieved.")
                if let response = azureAiService.response {
                    DispatchQueue.main.async {
                        let responseString = response.buildResponseString()
                        self.responseTextView.text = responseString
                        responseString.speak(speechSynthesizer: self.speechSynthesizer)
                    }
                    
                }
                // Update the TextView with the response
            } catch {
                print("Failed to describe scene: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.responseTextView.text = "Failed to describe scene: \(error.localizedDescription)"
                }
            }
        }
    }
}
