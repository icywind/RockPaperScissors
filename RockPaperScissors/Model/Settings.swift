//
//  Settings.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/22/26.
//
import SwiftUI
import Combine

class Settings: ObservableObject {
    static let shared = Settings()
    @AppStorage("isAutoMode") var isAutoMode: Bool = false
    @AppStorage("isSoundEnabled") var isSoundEnabled: Bool = true
    @AppStorage("username") var username: String = ""
}
