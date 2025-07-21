//
//  WordTask.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import Foundation

class WordTask {
    let word: Word
    let blankIndexes: [Int]
    var guessedLetters: Set<Character> = []

    init(word: Word, blanks: [Int]) {
        self.word = word
        self.blankIndexes = blanks
    }

    var remainingLetters: [Character] {
        blankIndexes.map {
            let letter = word.text[word.text.index(word.text.startIndex, offsetBy: $0)]
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
        String(word.text.enumerated().map {
            blankIndexes.contains($0.offset) && !guessedLetters.contains($0.element) ? "_" : $0.element
        })
    }
}
