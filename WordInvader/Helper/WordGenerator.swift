//
//  WordGenerator.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//
import Foundation

struct WordGenerator {
    let wordList: [String]

    init() {
        if let path = Bundle.main.path(forResource: "words_alpha", ofType: "txt"),
           let content = try? String(contentsOfFile: path, encoding: .utf8) {
            wordList = content.components(separatedBy: .newlines)
        } else {
            wordList = []
        }
    }

    func randomWord(ofLength length: Int) -> String? {
        let filtered = wordList.filter { $0.count == length }
        return filtered.randomElement()
    }
}
