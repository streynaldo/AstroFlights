//
//  GameManager.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import Foundation

class GameManager: ObservableObject {
    @Published var currentTaskText: String = ""

    // Singleton / inject ke scene
    static let shared = GameManager()
}
