//
//  AgoraVideoView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/20/26.
//
import Foundation
import SwiftUI

// UIViewRepresentable wrapper for UIView
struct VideoContainerView: UIViewRepresentable {
    let uiView: UIView
    
    func makeUIView(context: Context) -> UIView {
        return uiView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}
