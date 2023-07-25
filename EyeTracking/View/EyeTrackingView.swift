//
//  EyeTrackingView.swift
//  EyeTracking
//
//  Created by 藤治仁 on 2023/02/18.
//

import SwiftUI

struct EyeTrackingView: View {
    @StateObject private var viewModel = EyeTrackingViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let sceneView = viewModel.sceneView {
                    ARSceneView(sceneView: sceneView)
                        .opacity(0.3)
                }
                
                if let message = viewModel.message {
                    Text(message)
                        .font(.largeTitle)
                }
                // Color(.white)
                
                if let debugText = viewModel.debugText {
                    VStack {
                        Spacer()
                        HStack {
                            Text(debugText)
                            Spacer()
                        }
                    }
                }
                
                Image(systemName: "scope")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .position(viewModel.pointerLocation)
            }
            .onAppear {
                viewModel.screenSize.width = geometry.size.width
                viewModel.screenSize.height = geometry.size.height
                viewModel.pointerLocation = CGPoint(x: viewModel.screenSize.width / 2.0, y: viewModel.screenSize.height / 2.0)
                viewModel.centerLocation = CGPoint(x: viewModel.screenSize.width / 2.0, y: viewModel.screenSize.height / 2.0)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EyeTrackingView()
    }
}
