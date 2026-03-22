import SwiftUI

struct ResultBoxView: View {
    let resultText: String
    private let maxCardWidth: CGFloat = 350

    var body: some View {
        Text(resultText)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: maxCardWidth)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}


#Preview {
    ResultBoxView(resultText: "Show your hand to the camera. The first detected gesture starts a 3-second timer.")
}
