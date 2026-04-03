import SwiftUI

struct AIPlayerAreaView: View {
    let move: HandMove?
    let isShuffling: Bool
    let shufflingMove: HandMove?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.purple.opacity(0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.purple.opacity(0.65), lineWidth: 1.5)
                )

            VStack(spacing: 10) {
                if isShuffling, let shuffleMove = shufflingMove {
                    Image("\(petName)-\(shuffleMove.imageName)")
                        .resizable()
                        .scaledToFit()
                } else if let move = move {
                    Image("\(petName)-\(move.imageName)")
                        .resizable()
                        .scaledToFit()
                } else {
                    bearImage(height: 90)
                }
            }
            .padding(10)
        }
    }
}

#Preview {
    // AIPlayerAreaView(move: .paper, isShuffling: false, shufflingMove: nil)
    HStack(spacing: 10) {
        VideoContainerView(uiView: UIView())
            .background(Color.white)
            .cornerRadius(8)
            .frame(maxWidth: .infinity)
            .frame(height: 220)
        
        AIPlayerAreaView(
            move: .rock,
            isShuffling: false,
            shufflingMove: .paper
        )
    }
}
