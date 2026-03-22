import SwiftUI

struct TieEffectView: View {
    let isShowing: Bool
    
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 2.0
    
    var body: some View {
        ZStack {
            if isShowing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                Text("TIE!")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundStyle(.white)
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
    }
    
    private func resetAnimation() {
        print("resetting. previous opacity = \(opacity)")
        opacity = 0
        scale = 2.0
    }
}

#Preview {
    TieEffectView(isShowing: true)
}

