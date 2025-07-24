//
//  GameManager.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import Foundation

class GameManager: ObservableObject {
    @Published var currentTaskText: String = ""
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var health: Int = 5

    // Singleton / inject ke scene
    static let shared = GameManager()
}
