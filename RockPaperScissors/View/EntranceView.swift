//
//  EntranceView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/20/26.
//

import SwiftUI

struct EntranceView: View {
    @AppStorage("roomName") private var roomName: String = ""
    @State private var showInvalidRoomAlert = false
    @State private var navigateToAI = false
    @State private var navigateToBear = false
    @State private var navigateToP2 = false
    
    private var isRoomNameValid: Bool {
        roomName.count > 3
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
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
                
                // Room Input
                VStack(spacing: 12) {
                    Text("Room")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter room name", text: $roomName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 32)
                }
                
                // Game Mode Selection
                VStack(spacing: 16) {
                    Text("Choose Game Mode")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    gameModeButton(
                        leftImage: humanImage(),
                        rightImage: AnyView(Image(systemName: "cpu").font(.title2)),
                        backgroundColor: Color.accentColor,
                        action: {
                            roomName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if isRoomNameValid {
                                navigateToAI = true
                            } else {
                                showInvalidRoomAlert = true
                            }
                        },
                        navigationLink: NavigationLink("", destination: P1vsAIView(roomName: roomName), isActive: $navigateToAI)
                    )
                    
                    gameModeButton(
                        leftImage: bearImage(),
                        rightImage: humanImage(),
                        backgroundColor: Color.accentColor.opacity(0.7),
                        action: {
                            roomName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if isRoomNameValid {
                                navigateToBear = true
                            } else {
                                showInvalidRoomAlert = true
                            }
                        },
                        navigationLink: NavigationLink("", destination: BvsP1View(roomName: roomName), isActive: $navigateToBear)
                    )
                    
                    gameModeButton(
                        leftImage: humanImage(),
                        rightImage: bearImage(),
                        backgroundColor: Color.accentColor.opacity(0.85),
                        action: {
                            roomName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if isRoomNameValid {
                                navigateToP2 = true
                            } else {
                                showInvalidRoomAlert = true
                            }
                        },
                        navigationLink: NavigationLink("", destination: P1vsBView(roomName: roomName), isActive: $navigateToP2)
                    )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Invalid Room Name", isPresented: $showInvalidRoomAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Room name must be at least 3 characters long.")
            }
        }
    }
}

func bearImage(height: CGFloat = 32) -> some View {
    Image("bear_icon")
        .resizable()
        .scaledToFit()
        .frame(width: height, height: height)
    // Image(systemName: "teddybear.fill").font(.title2)
}

func humanImage(height: CGFloat = 32) -> some View {
    Image("daughter_icon")
        .resizable()
        .scaledToFit()
        .frame(width: height, height: height)
    //Image(systemName: "figure.child.circle.fill").font(.title2)
}

func gameModeButton<L: View, R: View, N: View>(
    leftImage: L,
    rightImage: R,
    backgroundColor: Color,
    action: @escaping () -> Void,
    navigationLink: N
) -> some View {
    Button(action: action) {
        HStack {
            leftImage
            Text("vs")
                .font(.caption)
                .foregroundStyle(.secondary)
            rightImage
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(backgroundColor)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .background(navigationLink.hidden())
}

#Preview {
    EntranceView()
}
