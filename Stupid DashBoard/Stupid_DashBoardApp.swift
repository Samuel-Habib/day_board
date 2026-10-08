//
//  Stupid_DashBoardApp.swift
//  Stupid DashBoard
//
//  Created by Samuel Fahim on 8/22/26.
//

import SwiftUI

@main
struct Stupid_DashBoardApp: App {
    init() {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
