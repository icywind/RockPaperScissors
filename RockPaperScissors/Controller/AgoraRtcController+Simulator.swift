//
//  AgoraRtcController+Simulator.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/21/26.
//  Moved by BLACKBOXAI
//

import UIKit

#if targetEnvironment(simulator)

let PlaceHolderImageName = "bear-head"

extension AgoraRtcController {
    func startSimulatorVideo() {
        guard let image = UIImage(named: PlaceHolderImageName) else {
            print("Failed to load \(PlaceHolderImageName) image")
            return
        }
        
        guard let pixelBuffer = createPixelBuffer(from: image) else {
            print("Failed to create pixel buffer from image")
            return
        }
        
        simulatorVideoTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            self?.pushVideoFrame(pixelBuffer: pixelBuffer)
        }
    }
    
    func stopSimulatorVideo() {
        simulatorVideoTimer?.invalidate()
        simulatorVideoTimer = nil
    }
    
    private func createPixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )
        
        guard let cgContext = context, let cgImage = image.cgImage else {
            return nil
        }
        
        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }
}

#endif

