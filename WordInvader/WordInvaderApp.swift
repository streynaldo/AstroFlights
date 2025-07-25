//
//  WordInvaderApp.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import SwiftUI
import SwiftData

@main
struct WordInvaderApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
        .modelContainer(for: [Word.self, GameSession.self])
    }
}
