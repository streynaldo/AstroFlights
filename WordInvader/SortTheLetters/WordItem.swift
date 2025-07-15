//
//  WordItem.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import Foundation
import SwiftData

@Model
final class WordItem {
    @Attribute(.unique) var text: String
    
    init(text: String) {
        self.text = text
    }
}
