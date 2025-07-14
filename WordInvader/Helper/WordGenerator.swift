//
//  WordGenerator.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//
import Foundation

struct WordGenerator {
    let wordList: [String] = [
        "ant", "bear", "cat", "dog", "eagle", "fox", "goat", "hawk", "ibis", "jaguar",
        "koala", "lion", "monkey", "newt", "otter", "panda", "quail", "rabbit", "sheep", "tiger",
        "urchin", "viper", "wolf", "yak", "zebra", "bat", "crow", "deer", "emu", "ferret",
        "gecko", "heron", "iguana", "jay", "kangaroo", "lemur", "mole", "narwhal", "owl", "penguin",
        "quokka", "rat", "seal", "toad", "urchin", "vole", "weasel", "xenops", "yak", "zebu",
        "alpaca", "buffalo", "camel", "dolphin", "elephant", "flamingo", "gazelle", "hyena", "impala", "jackal",
        "kiwi", "llama", "meerkat", "narwhal", "octopus", "parrot", "quail", "raccoon", "shark", "tapir",
        "urchin", "vulture", "walrus", "xerus", "yak", "zorilla", "badger", "cheetah", "donkey", "eel",
        "falcon", "giraffe", "hamster", "ibex", "jellyfish", "kingfisher", "lemur", "moose", "newt", "orca"
    ]
    
    func randomWord() -> String? {
        return wordList.randomElement()
    }
}
