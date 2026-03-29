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
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("Front camera hand gesture recognition")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.blue.opacity(0.12))

                if viewModel.viewContentKind == .FrozenImage, let frozenFrameImage = viewModel.frozenFrameImage {
                    Image(uiImage: frozenFrameImage)
                        .resizable()
                        .scaledToFit()
                    // Pink tint overlay for lose state
                    if player1Outcome == .lose {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.pink.opacity(0.4))
                    }
                    // Save button overlay
                    saveButtonOverlayView()

                } else if viewModel.authorizationStatus == .authorized {
                    CameraPreviewView(session: viewModel.session)
                } else {
                    CameraStatusPlaceholder(message: viewModel.cameraOverlayText)
                        .padding()
                }

                if let countdownRemaining = viewModel.countdownRemaining {
                    countdownOverlayView(countdownRemaining: countdownRemaining)
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

//            VStack(alignment: .leading, spacing: 4) {
//                Text("Player move")
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//                Text(viewModel.playerMoveLabel)
//                    .font(.headline)
//            }
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
    
    // MARK: - Helper Functions
    
    private func saveButtonOverlayView() -> some View {
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
    }
    
    private func countdownOverlayView(countdownRemaining: Int) -> some View {
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
}
