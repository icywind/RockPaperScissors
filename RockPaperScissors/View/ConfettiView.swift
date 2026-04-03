//
//  ConfettiView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/29/26.
//
import SwiftUI

// Confetti effect view
struct ConfettiView: View {
    let isAnimating: Bool
    @State private var particles: [ConfettiParticle] = []
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle, progress: animationProgress)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                withAnimation(.linear(duration: 3.0)) {
                    animationProgress = 1.0
                }
            }
            .onChange(of: isAnimating) { newValue in
                if newValue {
                    animationProgress = 0
                    createParticles(in: geometry.size)
                    withAnimation(.linear(duration: 3.0)) {
                        animationProgress = 1.0
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        particles = (0..<60).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -50...0),
                color: colors.randomElement() ?? .red,
                size: CGFloat.random(in: 6...12),
                speed: CGFloat.random(in: 150...300),
                rotation: Double.random(in: 0...360),
                endXOffset: CGFloat.random(in: -30...30)
            )
        }
    }

}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let startY: CGFloat
    let color: Color
    let size: CGFloat
    let speed: CGFloat
    let rotation: Double
    let endXOffset: CGFloat
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let progress: CGFloat

    var body: some View {
        let currentY = particle.startY + (progress * 400)
        let currentX = particle.x + (particle.endXOffset * progress)
        let currentRotation = particle.rotation + (progress * 720)
        
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.6)
            .position(x: currentX, y: currentY)
            .rotationEffect(.degrees(currentRotation))
    }
}
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ConfettiView(isAnimating: true)
    }
}

