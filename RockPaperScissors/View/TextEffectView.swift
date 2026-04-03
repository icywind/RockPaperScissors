import SwiftUI

struct TextEffectView: View {
    let showText: String
    let isShowing: Bool
    var onDismiss: (() -> Void)? = nil
    
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 2.0
    
    var body: some View {
        ZStack {
            if isShowing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                Text(showText)
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1) // Constrain text to a single line
                    .minimumScaleFactor(0.1) // Allow text to shrink if it's too long
                    .padding(.horizontal) // Add horizontal padding to prevent text from touching edges
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isShowing) { newValue in
            if newValue {
                startAnimation()
            } else {
                resetAnimation()
            }
        }
    }
    
    private func startAnimation() {
        opacity = 0.8
        scale = 2.0
        
        withAnimation(.easeIn(duration: 1.0)) {
            scale = 1.0
            opacity = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 1.0)) {
                opacity = 0
                scale = 0.5
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onDismiss?()
        }
    }
    
    private func resetAnimation() {
        print("resetting. previous opacity = \(opacity)")
        opacity = 0
        scale = 2.0
    }
}

#Preview {
    TextEffectView(showText: "WINNER!", isShowing: true)
}
