//
//  TargetWordView.swift
//  WordInvaders
//
//  Created by Louis Fernando on 14/07/25.
//

import SwiftUI

struct TargetWordView: View {
    let targetWord: String
    let highlightedUntilIndex: Int
    
    var body: some View {
        HStack(spacing: 2) {
            let characters = Array(targetWord)
            
            ForEach(0..<characters.count, id: \.self) { index in
                let character = characters[index]
                
                Text(String(character))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(index < highlightedUntilIndex ? .green : .white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}
