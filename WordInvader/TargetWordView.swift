//
//  TargetWordView.swift
//  WordInvader
//
//  Created by Louis Fernando on 15/07/25.
//

import SwiftUI

struct TargetWordView: View {
    let targetWord: String
    let highlightedUntilIndex: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(targetWord.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .tracking(5)
                    .foregroundColor(index < highlightedUntilIndex ? .yellow : .white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 2, y: 2)
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            TargetWordView(targetWord: "SWIFTUI", highlightedUntilIndex: 0)
            TargetWordView(targetWord: "SWIFTUI", highlightedUntilIndex: 3)
            TargetWordView(targetWord: "SWIFTUI", highlightedUntilIndex: 7)
        }
    }
}
