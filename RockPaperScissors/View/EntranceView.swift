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
                    
                    // Player vs AI Button
                    Button {
                        roomName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if isRoomNameValid {
                            navigateToAI = true
                        } else {
                            showInvalidRoomAlert = true
                        }
                    } label: {
                        HStack {
                            humanImage()
                            Text("vs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "cpu").font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .background(
                        NavigationLink("", destination: P1vsAIView(roomName: roomName.trimmingCharacters(in: .whitespacesAndNewlines)), isActive: $navigateToAI)
                            .hidden()
                    )
                    
                    // Bear vs Player Button
                    Button {
                        roomName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if isRoomNameValid {
                            navigateToBear = true
                        } else {
                            showInvalidRoomAlert = true
                        }
                    } label: {
                        HStack {
                            bearImage()
                            Text("vs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            humanImage()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.accentColor.opacity(0.7))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .background(
                        NavigationLink("", destination: BvsP1View(roomName: roomName.trimmingCharacters(in: .whitespacesAndNewlines)), isActive: $navigateToBear)
                            .hidden()
                    )
                    
                    // Player vs Bear Button
                    Button {
                        roomName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if isRoomNameValid {
                            navigateToP2 = true
                        } else {
                            showInvalidRoomAlert = true
                        }
                    } label: {
                        HStack {
                            humanImage()
                            Text("vs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            bearImage()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.accentColor.opacity(0.85))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .background(
                        NavigationLink("", destination: P1vsBView(roomName: roomName.trimmingCharacters(in: .whitespacesAndNewlines)), isActive: $navigateToP2)
                            .hidden()
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

func bearImage() -> some View {
    Image("bear_")
        .resizable()
        .scaledToFit()
        .frame(width: 32, height: 32)
    // Image(systemName: "teddybear.fill").font(.title2)
}

func humanImage() -> some View {
    Image("daughter_")
        .resizable()
        .scaledToFit()
        .frame(width: 32, height: 32)
    //Image(systemName: "figure.child.circle.fill").font(.title2)
}

#Preview {
    EntranceView()
}