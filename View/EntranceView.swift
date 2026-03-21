//
//  EntranceView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/20/26.
//

import SwiftUI

struct EntranceView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // App Title
                VStack(spacing: 12) {
                    Text("✊📄✂️")
                        .font(.system(size: 60))
                    
                    Text("Rock Paper Scissors")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Game Mode Selection
                VStack(spacing: 16) {
                    Text("Choose Game Mode")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    // Player vs AI Button
                    NavigationLink {
                        P1vsAIView()
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.title2)
                            Text("vs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "cpu")
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    // Player vs Player Button
                    NavigationLink {
                        P1vsP2View()
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.title2)
                            Text("vs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "person.fill")
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.accentColor.opacity(0.85))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    EntranceView()
}