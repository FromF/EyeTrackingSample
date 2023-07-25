//
//  ARSceneView.swift
//  EyeTracking
//
//  Created by 藤治仁 on 2023/02/18.
//

import SwiftUI
import ARKit

struct ARSceneView: UIViewRepresentable {
    let sceneView: ARSCNView
    func makeUIView(context: Context) -> ARSCNView {
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
}
