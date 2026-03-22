import SwiftUI

struct AIPlayerAreaView: View {
    let move: HandMove?
    let isShuffling: Bool
    let shufflingMove: HandMove?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.purple.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.purple.opacity(0.35), lineWidth: 1.5)
                    )

                VStack(spacing: 10) {
                    if isShuffling, let shuffleMove = shufflingMove {
                        Image(shuffleMove.imageName)
                            .resizable()
                            .scaledToFit()
                    } else if let move = move {
                        Image(move.imageName)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "cpu")
                            .font(.system(size: 52))
                            .foregroundStyle(.purple)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)

        }
    }
}

#Preview {
    AIPlayerAreaView(move: .paper, isShuffling: false, shufflingMove: nil)
}
