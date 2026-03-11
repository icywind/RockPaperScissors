import SwiftUI
import AVFoundation

struct PlayerCameraAreaView: View {
    @ObservedObject var viewModel: PlayerCameraViewModel
    let player1Outcome: Player1Outcome?
    @State private var showSaveAlert = false
    @State private var alertMessage = ""
    @State private var showConfetti = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Player 1")
                    .font(.title3.weight(.semibold))
                Text("Front camera hand gesture recognition")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.blue.opacity(0.12))

                if let frozenFrameImage = viewModel.frozenFrameImage {
                    Image(uiImage: frozenFrameImage)
                        .resizable()
                        .scaledToFit()
                    // Pink tint overlay for lose state
                    if player1Outcome == .lose {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.pink.opacity(0.4))
                    }
                    // Save button overlay
                    VStack {
                        HStack {
                            Spacer()
                            if viewModel.isFrozenImageSaved {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(.green)
                                    .padding(10)
                                    .background(.white.opacity(0.65))
                                    .clipShape(Circle())
                                    .padding(16)
                            } else {
                                Button(action: {
                                    viewModel.saveFrozenFrame { message in
                                        alertMessage = message
                                        showSaveAlert = true
                                    }
                                }) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.title3.weight(.medium))
                                        .foregroundStyle(.white)
                                        .padding(10)
                                        .background(.black.opacity(0.65))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .padding(16)
                            }
                        }
                        Spacer()
                    }

                } else if viewModel.authorizationStatus == .authorized {
                    CameraPreviewView(session: viewModel.session)
                } else {
                    CameraStatusPlaceholder(message: viewModel.cameraOverlayText)
                        .padding()
                }

                if let countdownRemaining = viewModel.countdownRemaining {
                    VStack {
                        HStack {
                            Spacer()

                            Text("\(countdownRemaining)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.black.opacity(0.65))
                                .clipShape(Capsule())
                        }

                        Spacer()
                    }
                    .padding(16)
                }



                // Confetti effect for win state
                if showConfetti {
                    ConfettiView(isAnimating: showConfetti)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.blue.opacity(0.35), lineWidth: 1.5)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .alert("Saved Image", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Player move")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.playerMoveLabel)
                    .font(.headline)
            }
        }
        .onChange(of: player1Outcome) { newValue in
            if newValue == .win {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showConfetti = false
                }
            }
        }
    }
}

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
