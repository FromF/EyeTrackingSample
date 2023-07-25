//
//  EyeTrackingModel.swift
//  EyeTracking
//
//  Created by 藤治仁 on 2023/02/18.
//

import Foundation
import ARKit

protocol EyeTrackingModelDelegate: AnyObject {
    func eyeTracingDebug(x: Int, y: Int , distance: Int)
    func eyeTracingScreen(x: CGFloat, y: CGFloat)
}

class EyeTrackingModel: NSObject {
    weak var delegate: EyeTrackingModelDelegate?
    let sceneView = ARSCNView()
    private let defaultConfiguration: ARFaceTrackingConfiguration = {
        let configuration = ARFaceTrackingConfiguration()
        return configuration
    }()
    
    // 顔のNode
    private var faceNode: SCNNode = SCNNode()
    
    // 左目からレーザー光線出ているオブジェクト
    private var eyeLNode: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0, height: 0.2)
        geometry.radialSegmentCount = 3
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    // 右目からレーザー光線出ているオブジェクト
    private var eyeRNode: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0, height: 0.2)
        geometry.radialSegmentCount = 3
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    // 目の視線の先のNode
    private var lookAtTargetEyeLNode: SCNNode = SCNNode()
    private var lookAtTargetEyeRNode: SCNNode = SCNNode()
    
    // actual physical size of iPhoneX screen
    private let phoneScreenSize = CGSize(width: 0.0623908297, height: 0.135096943231532)
    
    // actual point size of iPhoneX screen
    private let phoneScreenPointSize = CGSize(width: 375, height: 812)
    
    // 仮想空間のiPhoneのNode
    private var virtualPhoneNode: SCNNode = SCNNode()
    
    // 仮想空間のiPhoneのScreenNode
    private var virtualScreenNode: SCNNode = {
        
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        
        return SCNNode(geometry: screenGeometry)
    }()
    
    // 目線の値を格納する配列
    private var eyeLookAtPositionXs: [CGFloat] = []
    
    private var eyeLookAtPositionYs: [CGFloat] = []
    
    override init() {
        super.init()
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Setup Scenegraph
        sceneView.scene.rootNode.addChildNode(faceNode)
        sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        faceNode.addChildNode(eyeLNode)
        faceNode.addChildNode(eyeRNode)
        eyeLNode.addChildNode(lookAtTargetEyeLNode)
        eyeRNode.addChildNode(lookAtTargetEyeRNode)
        
        // Set LookAtTargetEye at 2 meters away from the center of eyeballs to create segment vector
        lookAtTargetEyeLNode.position.z = 2
        lookAtTargetEyeRNode.position.z = 2
    }
    
    func start() {
        // Create a session configuration
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stop() {
        sceneView.session.pause()
    }
    
    // MARK: - update(ARFaceAnchor)
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        eyeRNode.simdTransform = anchor.rightEyeTransform
        eyeLNode.simdTransform = anchor.leftEyeTransform
        
        var eyeLLookAt = CGPoint()
        var eyeRLookAt = CGPoint()
        
        let heightCompensation: CGFloat = 0
        
        // Perform Hit test using the ray segments that are drawn by the center of the eyeballs to somewhere two meters away at direction of where users look at to the virtual plane that place at the same orientation of the phone screen
        let phoneScreenEyeRHitTestResults = virtualPhoneNode.hitTestWithSegment(from: lookAtTargetEyeRNode.worldPosition, to: eyeRNode.worldPosition, options: nil)
        let phoneScreenEyeLHitTestResults = virtualPhoneNode.hitTestWithSegment(from: lookAtTargetEyeLNode.worldPosition, to: eyeLNode.worldPosition, options: nil)
        
        for result in phoneScreenEyeRHitTestResults {
            eyeRLookAt.x = CGFloat(result.localCoordinates.x) / (phoneScreenSize.width / 2) * phoneScreenPointSize.width
            eyeRLookAt.y = CGFloat(result.localCoordinates.y) / (phoneScreenSize.height / 2) * phoneScreenPointSize.height + heightCompensation
        }
        
        for result in phoneScreenEyeLHitTestResults {
            eyeLLookAt.x = CGFloat(result.localCoordinates.x) / (phoneScreenSize.width / 2) * phoneScreenPointSize.width
            eyeLLookAt.y = CGFloat(result.localCoordinates.y) / (phoneScreenSize.height / 2) * phoneScreenPointSize.height + heightCompensation
        }
        
        // Add the latest position and keep up to 8 recent position to smooth with.
        let smoothThresholdNumber: Int = 10
        eyeLookAtPositionXs.append((eyeRLookAt.x + eyeLLookAt.x) / 2)
        eyeLookAtPositionYs.append(-(eyeRLookAt.y + eyeLLookAt.y) / 2)
        eyeLookAtPositionXs = Array(eyeLookAtPositionXs.suffix(smoothThresholdNumber))
        eyeLookAtPositionYs = Array(eyeLookAtPositionYs.suffix(smoothThresholdNumber))
        
        let smoothEyeLookAtPositionX = eyeLookAtPositionXs.average!
        let smoothEyeLookAtPositionY = eyeLookAtPositionYs.average!
        
        // update indicator position
        delegate?.eyeTracingScreen(x: smoothEyeLookAtPositionX, y: smoothEyeLookAtPositionY)
        
        // update eye look at labels values
        let lookAtPositonX = Int(round(smoothEyeLookAtPositionX + phoneScreenPointSize.width / 2))
        let lookAtPositonY = Int(round(smoothEyeLookAtPositionY + phoneScreenPointSize.height / 2))
        
        // Calculate distance of the eyes to the camera
        let distanceL = eyeLNode.worldPosition - SCNVector3Zero
        let distanceR = eyeRNode.worldPosition - SCNVector3Zero
        
        // Average distance from two eyes
        let distance = (distanceL.length() + distanceR.length()) / 2
        
        // Update distance label value
        let distancePerCM = Int(round(distance * 100))
        
        delegate?.eyeTracingDebug(x: lookAtPositonX, y: lookAtPositonY, distance: distancePerCM)
    }
}

extension EyeTrackingModel: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        errorLog(error)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        debugLog("")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        debugLog("")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        update(withFaceAnchor: faceAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        virtualPhoneNode.transform = (sceneView.pointOfView?.transform)!
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        update(withFaceAnchor: faceAnchor)
    }
}
