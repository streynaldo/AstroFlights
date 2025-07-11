//
//  Item.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
