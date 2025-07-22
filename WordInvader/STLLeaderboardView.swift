//
//  STLLeaderboardView.swift
//  WordInvader
//
//  Created by Louis Fernando on 22/07/25.
//

import SwiftUI

struct STLLeaderboardView: View {
    
    @ObservedObject var gameKitManager: GameKitManager
    
    let leaderboardID: String
    
    var body: some View {
        ZStack {
            Color("background_color").ignoresSafeArea()
            
            if gameKitManager.leaderboardEntries.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        Text("Papan Skor")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        ForEach(gameKitManager.leaderboardEntries) { entry in
                            LeaderboardRowView(entry: entry)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            gameKitManager.fetchLeaderboardEntries(id: leaderboardID)
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack {
            Text("\(entry.rank)")
                .font(.headline)
                .foregroundColor(.yellow)
                .frame(width: 40)
            
            Text(entry.playerName)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(entry.score)
                .font(.title2).bold()
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}
