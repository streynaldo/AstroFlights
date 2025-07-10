//
//  WordTask.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import Foundation

class WordTask {
    let word: String
    let blankIndexes: [Int]
    var guessedLetters: Set<Character> = []

    init(word: String, blanks: [Int]) {
        self.word = word
        self.blankIndexes = blanks
    }

    var remainingLetters: [Character] {
        blankIndexes.map {
            let letter = word[word.index(word.startIndex, offsetBy: $0)]
            return letter
        }.filter { !guessedLetters.contains($0) }
    }

    var isComplete: Bool {
        remainingLetters.isEmpty
    }

    func fill(letter: Character) {
        guessedLetters.insert(letter)
    }

    var display: String {
        String(word.enumerated().map {
            blankIndexes.contains($0.offset) && !guessedLetters.contains($0.element) ? "_" : $0.element
        })
    }
}
