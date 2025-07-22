//
//  GameSession.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 18/07/25.
//

import SwiftData
import Foundation

@Model
class GameSession {
    var score: Int
    var wordsCompleted: Int
    var dateStarted: Date
    var duration: TimeInterval
    var difficulty: String

    init(score: Int = 0, difficulty: String = "normal") {
        self.score = score
        self.wordsCompleted = 0
        self.dateStarted = Date()
        self.duration = 0
        self.difficulty = difficulty
    }
}
