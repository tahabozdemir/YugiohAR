//
//  ViewController.swift
//  YugiohAR
//
//  Created by Taha Bozdemir on 21.02.2023.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var blueEyesNode: SCNNode?
    var darkHoleNode: SCNNode?
    var burstNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //  SceneKit automatically adds lights to a scene.
        sceneView.autoenablesDefaultLighting = true
        
        let blueEyesScene = SCNScene(named: "art.scnassets/BlueEyes.scn")
        let darkHoleScene = SCNScene(named: "art.scnassets/DarkHole.scn")
        let burstScene = SCNScene(named: "art.scnassets/Burst.scn")
        
        blueEyesNode = blueEyesScene?.rootNode
        darkHoleNode = darkHoleScene?.rootNode
        burstNode = burstScene?.rootNode
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        if let imageToTrack = ARReferenceImage.referenceImages(inGroupNamed: "Yugioh Cards", bundle: Bundle.main)  {
            configuration.trackingImages = imageToTrack
            configuration.maximumNumberOfTrackedImages = 3
        }
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    enum YugiCard: String {
        case blueEyes = "blueEyes"
        case darkHole = "darkHole"
        case burst = "burst"
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        let shapeSpin = SCNAction.rotateBy(x: 0, y: 0, z: .pi, duration: 2)
        let repeatSpin = SCNAction.repeatForever(shapeSpin)
        
        
        if let imageAnchor = anchor as? ARImageAnchor {
            
            let size = imageAnchor.referenceImage.physicalSize
            let plane = SCNPlane(width: size.width, height: size.height)
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)
            
            let planeNode = SCNNode(geometry: plane)
            let ninetyDegree = Float.pi / 2
            
            planeNode.eulerAngles.x = -ninetyDegree
            node.addChildNode(planeNode)
            
            var shapeNode: SCNNode?
            
            switch imageAnchor.referenceImage.name {
                
            case YugiCard.blueEyes.rawValue :
                shapeNode = blueEyesNode
                
            case YugiCard.darkHole.rawValue :
                darkHoleNode?.runAction(repeatSpin)
                shapeNode = darkHoleNode
                
            case YugiCard.burst.rawValue :
                shapeNode = burstNode
                
            default:
                break
            }
            
            guard let shape = shapeNode else {return nil}
            planeNode.addChildNode(shape)
        }
        
        return node
    }
    
    func calculateNodeDistance(_ firstNode: SCNNode?, _ secondNode: SCNNode?) -> Float {
        guard let firstNode = firstNode else {return 0}
        guard let secondNode = secondNode else {return 0}
        
        let positionFirstNode = SCNVector3ToGLKVector3(firstNode.position)
        let positionSecondNode = SCNVector3ToGLKVector3(secondNode.position)
        let distance = GLKVector3Distance(positionFirstNode, positionSecondNode)
        
        return distance
    }
    
    func resetBurstStreamNode(_ distance: Float, _ node:SCNNode?) {
        guard let node = node else {return}
        
        if distance >= 9 {
            node.removeAllActions()
            node.position.y = -0.5
            node.isHidden = true
        }
    }
    
    func addBurstStreamNode() {
        let burstStreamAction = SCNAction.moveBy(x: 0, y: -10, z: 0, duration: 7)
        let waitBurstStream = SCNAction.sequence([.wait(duration: 1), burstStreamAction])
        
        if let burstNode,
           let blueEyesNode {
            blueEyesNode.addChildNode(burstNode)
            let burstStreamChildNode = blueEyesNode.childNode(withName: "burst", recursively: true)
            burstStreamChildNode?.isHidden = false
            burstStreamChildNode?.runAction(waitBurstStream)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let burstStreamChildNode = blueEyesNode?.childNode(withName: "burst", recursively: true)
        let distance = calculateNodeDistance(blueEyesNode, burstStreamChildNode)
        resetBurstStreamNode(distance, burstStreamChildNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor,
           imageAnchor.isTracked == true,
           imageAnchor.referenceImage.name == "burst" {
            addBurstStreamNode()
        }
    }
}

