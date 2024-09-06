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
    @AppStorage("enableVibration") private var enableVibration: Bool = false
    @AppStorage("obstacleDetectionThreshold") private var obstacleDetectionThreshold: Double = 0.7

    private var arView: ARSCNView!
    private var hapticFeedbackGenerator: UIImpactFeedbackGenerator?
    private var distanceLabels: [UILabel] = []
    private let audioSession = AVAudioSession.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupHapticFeedback()
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
        let labelPoints = DistanceLabelUtils.getScreenPoints(for: view)
        distanceLabels = labelPoints.map { createDistanceLabel(at: $0) }
        distanceLabels.forEach { view.addSubview($0) }
    }

    // MARK: - Detection and Feedback Methods
    private func detectMultiplePoints() {
        let screenPoints = DistanceLabelUtils.getScreenPoints(for: view)
        var closestDistance: Float = .infinity

        for (index, point) in screenPoints.enumerated() {
            let hitTestResults = arView.hitTest(point, types: [.existingPlaneUsingExtent, .featurePoint])
            if let result = hitTestResults.first {
                let distance = Float(result.distance)
                closestDistance = min(closestDistance, distance)
                
                DistanceLabelUtils.updateDistanceLabel(distanceLabels[index], with: result, threshold: obstacleDetectionThreshold)
            }
        }
        
        if closestDistance < Float(obstacleDetectionThreshold) {
            triggerHapticFeedback()
        }
    }

    private func triggerHapticFeedback() {
        if enableVibration {
            hapticFeedbackGenerator?.impactOccurred()
        }
    }

    // MARK: - Helper Methods
    private func createDistanceLabel(at point: CGPoint) -> UILabel {
        let label = UILabel()
        label.frame = CGRect(x: point.x, y: point.y, width: 100, height: 20)
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.text = "0.00 m"
        return label
    }
}
