//
//  NetworkModel.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/22/26.
//
import Foundation

struct GameMessage : Codable, Identifiable {
    var id = UUID()
    let requiredP1Mode :  PlayerType
    let remoteP2Mode : PlayerType
    let remoteP2Move : HandMove?
}

struct NameMessage: Codable, Identifiable {
    var id = UUID()
    let playerName: String
}
