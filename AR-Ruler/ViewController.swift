//
//  ViewController.swift
//  AR-Ruler
//
//  Created by Vardhan Agrawal on 1/5/18.
//  Copyright © 2018 Vardhan Agrawal. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Interface Builder Connections
    @IBOutlet var sceneView: ARSCNView!
    
    // Spheres nodes
    var spheres: [SCNNode] = []
    
    // Measurement label
    var measurementLabel = UILabel()
    
    
    fileprivate lazy var session = ARSession()
    fileprivate lazy var sessionConfiguration = ARWorldTrackingConfiguration()
    fileprivate lazy var isMeasuring = false;
    fileprivate lazy var vectorZero = SCNVector3()
    fileprivate lazy var startValue = SCNVector3()
    fileprivate lazy var endValue = SCNVector3()
    fileprivate lazy var lines: [Line] = []
    fileprivate var currentLine: Line?
    fileprivate lazy var unit: DistanceUnit = .centimeter
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        // Creates a background for the label
        measurementLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height-100, width: view.frame.size.width, height: 100)
        
        // Makes the background white
        measurementLabel.backgroundColor = .white
        
        // Sets some default text
       // measurementLabel.isHidden = true
        measurementLabel.text = "0 inches"
        measurementLabel.textColor = .red
        
        // Centers the text
        measurementLabel.textAlignment = .center
        
        // Adds the text to the
        view.addSubview(measurementLabel)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
                        
        // Creates a tap handler and then sets it to a constant
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        
        // Sets the amount of taps needed to trigger the handler
        tapRecognizer.numberOfTapsRequired = 1
        
        // Adds the handler to the scene view
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
       
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    // Called when tap is detected
    @objc func handleTap(sender: UITapGestureRecognizer) {
        
        
        
        // Gets the location of the tap and assigns it to a constant
        let location = sender.location(in: sceneView)
        
        // Searches for real world objects such as surfaces and filters out flat surfaces
        let hitTest = sceneView.hitTest(location, types: [ARHitTestResult.ResultType.featurePoint])
        
        // Assigns the most accurate result to a constant if it is non-nil
        guard let result = hitTest.last else { return }
        
        // Converts the matrix_float4x4 to an SCNMatrix4 to be used with SceneKit
        let transform = SCNMatrix4.init(result.worldTransform)
        
        // Creates an SCNVector3 with certain indexes in the matrix
        let vector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
        
        // Makes a new sphere with the created method
        let sphere = newSphere(at: vector)
        
        // Checks if there is at least one sphere in the array
        if let first = spheres.first {
            
            
            
            // Adds a second sphere to the array
            spheres.append(sphere)
            measurementLabel.text = "\(sphere.distance(to: first)) inches"
            
            // If more that two are present...
            if spheres.count > 2
            {
                
                for sphere in spheres
                {
                    sphere.removeFromParentNode()
                }
                
                // Remove extraneous spheres
                spheres = [spheres[2]]
            }
            
            if spheres.count == 2
            {
                //remove line
                isMeasuring = false
                if let line = currentLine
                {
                    lines.append(line)
                    currentLine = nil
                }
            }
        
        // If there are no spheres...
        }
        else
        {
            
            // Add the sphere
            spheres.append(sphere)

            resetValues()
            isMeasuring = true
            
        }
        
        // Iterate through spheres array
        for sphere in spheres {
            
            
            // Add all spheres in the array
            self.sceneView.scene.rootNode.addChildNode(sphere)
        }
        
        
    }
    
    // Creates measuring endpoints
    func newSphere(at position: SCNVector3) -> SCNNode {
        
        // Creates an SCNSphere with a radius of 0.4
        let sphere = SCNSphere(radius: 0.01)
        
        // Converts the sphere into an SCNNode
        let node = SCNNode(geometry: sphere)
        
        // Positions the node based on the passed in position
        node.position = position
        
        // Creates a material that is recognized by SceneKit
        let material = SCNMaterial()
        
        // Converts the contents of the PNG file into the material
        material.diffuse.contents = UIColor.orange
        
        // Creates realistic shadows around the sphere
        material.lightingModel = .blinn
        
        // Wraps the newly made material around the sphere
        sphere.firstMaterial = material
        
        // Returns the node to the function
        return node
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
}

extension ViewController {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            self?.detectObjects()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        //messageLabel.text = "Error occurred"
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
       // messageLabel.text = "Interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
       // messageLabel.text = "Interruption ended"
    }
}

// MARK: - Users Interactions

extension ViewController {
    @IBAction func meterButtonTapped(button: UIButton) {
        let alertVC = UIAlertController(title: "Settings", message: "Please select distance unit options", preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: DistanceUnit.centimeter.title, style: .default) { [weak self] _ in
            self?.unit = .centimeter
        })
        alertVC.addAction(UIAlertAction(title: DistanceUnit.inch.title, style: .default) { [weak self] _ in
            self?.unit = .inch
        })
        alertVC.addAction(UIAlertAction(title: DistanceUnit.meter.title, style: .default) { [weak self] _ in
            self?.unit = .meter
        })
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    @IBAction func resetButtonTapped(button: UIButton) {
       // resetButton.isHidden = true
       // resetImageView.isHidden = true
        for line in lines {
            line.removeFromParentNode()
        }
        lines.removeAll()
    }
}

// MARK: - Extensions
extension SCNNode {
    
    // Gets distance between two SCNNodes
    func distance(to destination: SCNNode) -> CGFloat {
        
        // Meters to inches conversion
        let inches: Float = 39.3701
        
        // Difference between x-positions
        let dx = destination.position.x - position.x
        
        // Difference between x-positions
        let dy = destination.position.y - position.y
        
        // Difference between x-positions
        let dz = destination.position.z - position.z
        
        // Formula to get meters
        let meters = sqrt(dx*dx + dy*dy + dz*dz)
        
        // Returns inches
        return CGFloat(meters * inches)
    }
}
extension ViewController {
    fileprivate func setupScene() {
        //targetImageView.isHidden = true
        sceneView.delegate = self
        sceneView.session = session
        //resetImageView.isHidden = true
        session.run(sessionConfiguration, options: [.resetTracking, .removeExistingAnchors])
        resetValues()
    }
    
    fileprivate func resetValues() {
        isMeasuring = false
        startValue = SCNVector3()
        endValue =  SCNVector3()
    }
    
    fileprivate func detectObjects() {
        guard let worldPosition = sceneView.realWorldVector(screenPosition: view.center) else { return }
       // targetImageView.isHidden = false
       // meterImageView.isHidden = false
        if lines.isEmpty {
           // messageLabel.text = "Hold screen & move your phone…"
        }
        //loadingView.stopAnimating()
        if isMeasuring {
            if startValue == vectorZero {
                startValue = worldPosition
                currentLine = Line(sceneView: sceneView, startVector: startValue, unit: unit)
            }
            endValue = worldPosition
            currentLine?.update(to: endValue)
           // messageLabel.text = currentLine?.distance(to: endValue) ?? "Calculating…"
        }
    }
}
