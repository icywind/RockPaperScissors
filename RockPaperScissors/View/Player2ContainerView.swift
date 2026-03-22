//
//  Player2ContainerView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/20/26.
//

import SwiftUI

struct Player2ContainerView<Content: View>: View {
    @State var player2Name: String
    @State var player2Description: String
    @State var subView : Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(player2Name)
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(player2Description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            subView
        }
    }
}
