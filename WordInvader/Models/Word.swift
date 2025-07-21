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
class Word {
    var text: String
    
    init(text: String) {
        self.text = text.uppercased()
    }
}
