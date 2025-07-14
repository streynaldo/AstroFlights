//
//  WordItem.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import Foundation
import SwiftData

// Mendefinisikan model untuk setiap kata dalam database
@Model
final class WordItem {
    // Atribut unik memastikan tidak ada kata yang duplikat
    @Attribute(.unique) var text: String
    
    init(text: String) {
        self.text = text
    }
}
