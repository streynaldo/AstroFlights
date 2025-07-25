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
        let wordList =  [
            "AGREE", "ALONE", "ANGER", "AREA", "BABY", "BADGE", "BASIC", "BEACH", "BEGIN", "BELOW",
            "BIRD", "BLACK", "BLOCK", "BLOOD", "BOARD", "BRAIN", "BREAD", "BREAK", "BRICK", "BRIDGE",
            "BRING", "BROWN", "BUILD", "CABLE", "CARRY", "CATCH", "CHAIN", "CHAIR", "CHALK", "CHARM",
            "CHART", "CHECK", "CHEST", "CHILD", "CLEAN", "CLEAR", "CLOCK", "CLOSE", "CLOUD", "COACH",
            "COAST", "COLOR", "COUGH", "COUNT", "COURT", "COVER", "CRASH", "CREAM", "CROWD", "DANCE",
            "DEATH", "DEPTH", "DIRTY", "DREAM", "DRESS", "DRINK", "DRIVE", "EARLY", "EARTH", "EIGHT",
            "EMPTY", "ENJOY", "ENTER", "EQUAL", "ERROR", "EVENT", "EXACT", "EXIST", "EXTRA", "FIGHT",
            "FINAL", "FLOOR", "FOCUS", "FORCE", "FORGET", "FORTH", "FRAME", "FRESH", "FRONT", "FRUIT",
            "FUNNY", "GLASS", "GLOBE", "GRASS", "GREAT", "GREEN", "GROUP", "GUARD", "GUESS", "GUEST",
            "GUIDE", "HEART", "HEAVY", "HELLO", "HENNA", "HORSE", "HOTEL", "HOUSE", "HUMAN", "IMAGE"
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
