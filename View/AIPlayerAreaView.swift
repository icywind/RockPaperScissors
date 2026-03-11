import SwiftUI

struct AIPlayerAreaView: View {
    let move: HandMove?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Player 2 (AI)")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("Computer opponent")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.purple.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.purple.opacity(0.35), lineWidth: 1.5)
                    )

                VStack(spacing: 10) {
                    Image(systemName: move?.symbolName ?? "cpu")
                        .font(.system(size: 52))
                        .foregroundStyle(.purple)
                    Text(move?.rawValue ?? "Waiting for game")
                        .font(.headline)
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI move")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(move?.rawValue ?? "Pending")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

#Preview {
    AIPlayerAreaView(move:.paper)
}
