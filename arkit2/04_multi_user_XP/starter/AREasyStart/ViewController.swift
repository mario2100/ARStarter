//
//  ViewController.swift
//  AREasyStart
//
//  Created by Manuela Rink on 01.06.18.
//  Copyright © 2018 Manuela Rink. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var saveWorldButton: UIButton!
    @IBOutlet weak var loadWorldButton: UIButton!
    @IBOutlet weak var sendWorldButton: UIButton!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    
    var sunshineSystem : SCNParticleSystem?
    var timer : Timer?
    
    var postitIndex = 0
    var alert : UIAlertController?
    
    var multipeerSession: MultipeerSession!
    
    
    var worldFileURL : URL?
    
    var screenCenter: CGPoint {
        let screenSize = view.bounds
        return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        
        let scene = SCNScene()
        sceneView.scene = scene
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func saveWorldMap (_ sendToPeers: Bool? = false) {
        
    }
    
    func openWorldMap () throws {
        
    }
    
    @IBAction func runSessionTapped(_ sender: Any) {
        runSession()
    }
    
    @IBAction func saveWorldTapped(_ sender: Any) {
        saveWorldMap()
        alert = UIAlertController(title: "World saved", message: "The ARWorldMap and all elements were sucessfully saved.", preferredStyle: .alert)
        self.present(alert!, animated: true)
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { timer in
            self.alert?.dismiss(animated: true, completion: nil)
        })
    }
    
    @IBAction func openWorldTapped(_ sender: Any) {
        try? openWorldMap()
        alert = UIAlertController(title: "World loading...", message: "Loading a map works best when you explore the environment. \nMove your phone around and we'll be up in a second!", preferredStyle: .alert)
        self.present(alert!, animated: true)
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { timer in
            self.alert?.dismiss(animated: true, completion: nil)
        })
    }
    
    @IBAction func sendWorldTapped(_ sender: Any) {
        saveWorldMap(true)
    }
    
    var mapProvider: MCPeerID?
    
    //get data from the multipeer connection - either a world or
    //new items in the form of ARAnchors
    func receivedData(_ data: Data, from peer: MCPeerID) {
        if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(of: ARWorldMap.classForKeyedUnarchiver(), from: data),
            let worldMap = unarchived as? ARWorldMap {
            runSession(worldMap)
            mapProvider = peer
        }
        else {
            if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(of: ARAnchor.classForKeyedUnarchiver(), from: data),
                let anchor = unarchived as? ARAnchor {
                sceneView.session.add(anchor: anchor)
            }
            else {
                print("unknown data recieved from \(peer)")
            }
        }
    }
    
    @IBAction func sceneTapped(_ sender: UITapGestureRecognizer) {

    }
    
    func runSession(_ map: ARWorldMap? = nil) {

    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {

    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            sendWorldButton.isEnabled = false
        case .extending:
            sendWorldButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        case .mapped:
            sendWorldButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        }
        print(frame.worldMappingStatus)
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        sessionInfoLabel.text = message
    }
    
}
