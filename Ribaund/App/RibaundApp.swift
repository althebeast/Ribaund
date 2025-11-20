//
//  RibaundApp.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 28/10/25.
//

import SwiftUI

@main
struct RibaundApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(WordPressService())
        }
    }
}
