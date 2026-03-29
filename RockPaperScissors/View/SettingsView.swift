//
//  SettingsView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/22/26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    SettingsToggleRow(
                        title: "Player 2 Mode",
                        isOn: $settings.isAutoMode,
                        description: settings.isAutoMode ? "Auto: Tap AI area to randomly select a move" : "Manual: Select your move using the buttons"
                    )
                    
                    SettingsToggleRow(
                        title: "Sound Effects",
                        isOn: $settings.isSoundEnabled,
                        description: settings.isSoundEnabled ? "Sound effects are enabled" : "Sound effects are disabled"
                    )
                } header: {
                    Text("Game Settings")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }.navigationViewStyle(.stack)
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.body)
                Spacer()
                Toggle("", isOn: $isOn)
                    .toggleStyle(.switch)
            }
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}

