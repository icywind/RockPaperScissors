import SwiftUI
import AVFoundation

struct PlayerCameraAreaView: View {
    @ObservedObject var cameraClassifier: CameraHandPoseClassifier

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

                if let frozenFrameImage = cameraClassifier.frozenFrameImage {
                    Image(uiImage: frozenFrameImage)
                        .resizable()
                        .scaledToFill()
                } else if cameraClassifier.authorizationStatus == .authorized {
                    CameraPreviewView(session: cameraClassifier.session)
                } else {
                    CameraStatusPlaceholder(message: cameraClassifier.cameraOverlayText)
                        .padding()
                }

                if let countdownRemaining = cameraClassifier.countdownRemaining {
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
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.blue.opacity(0.35), lineWidth: 1.5)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 4) {
                Text("Player move")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(cameraClassifier.playerMoveLabel)
                    .font(.headline)
            }
        }
    }
}
