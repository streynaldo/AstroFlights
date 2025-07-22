//
//  WordGenerator.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//
import Foundation
import SwiftData

@MainActor
class WordDataManager: ObservableObject {
    private var modelContext: ModelContext
    private var usedWords: Set<String> = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupInitialWords()
    }

    private func setupInitialWords() {
        let descriptor = FetchDescriptor<Word>()
        let existingWords = try? modelContext.fetch(descriptor)

        if existingWords?.isEmpty ?? true {
            insertInitialWords()
        }
    }

    private func insertInitialWords() {
        let wordList = [
            "ayam", "bebek", "cicak", "domba", "elang", "flamingo", "gajah", "harimau", "iguana", "jerapah",
            "kucing", "lumba", "monyet", "naga", "orang", "panda", "quokka", "rusa", "singa", "tupai",
            "ular", "viper", "walrus", "xenops", "yak", "zebra", "badak", "cumi", "duyung", "echidna",
            "ferret", "gecko", "hiu", "ikan", "jaguar", "kura", "lemur", "macan", "nuri", "onta",
            "paus", "quail", "rajawali", "sapi", "tikus", "udang", "vole", "wombat", "xerus", "yeti",
            "anjing", "babi", "cacing", "dodo", "elang", "flamingo", "gorila", "hamster", "iguana", "jalak"
        ]

        for wordText in wordList {
            // Word model akan otomatis uppercase
            let word = Word(text: wordText)
            modelContext.insert(word)
        }

        try? modelContext.save()
    }

    func getRandomWord(difficulty: Int? = nil) -> Word? {
        let descriptor = FetchDescriptor<Word>()
        guard let allWords = try? modelContext.fetch(descriptor) else { return nil }

        let availableWords = allWords.filter { !usedWords.contains($0.text.uppercased()) }

        if let difficulty = difficulty {
            let filteredWords = availableWords.filter { $0.text.count == difficulty }
            if let selectedWord = filteredWords.randomElement() {
                // Create new Word with uppercase text
                let uppercaseWord = Word(text: selectedWord.text.uppercased())
                return uppercaseWord
            }
            return nil
        } else {
            if let selectedWord = availableWords.randomElement() {
                // Create new Word with uppercase text
                let uppercaseWord = Word(text: selectedWord.text.uppercased())
                return uppercaseWord
            }
            return nil
        }
    }

    func markWordAsUsed(_ word: Word) {
        usedWords.insert(word.text.uppercased())
    }

    func resetWordUsage() {
        usedWords.removeAll()
    }

    func saveGameSession(_ session: GameSession) {
        modelContext.insert(session)
        try? modelContext.save()
    }

    func getGameStats() -> (totalGames: Int, bestScore: Int, averageScore: Double) {
        let descriptor = FetchDescriptor<GameSession>()
        guard let sessions = try? modelContext.fetch(descriptor) else {
            return (0, 0, 0.0)
        }

        let totalGames = sessions.count
        let bestScore = sessions.map(\.score).max() ?? 0
        let averageScore = sessions.isEmpty ? 0 : Double(sessions.map(\.score).reduce(0, +)) / Double(sessions.count)

        return (totalGames, bestScore, averageScore)
    }
}
