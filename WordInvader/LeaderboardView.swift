//
//  STLLeaderboardView.swift
//  WordInvader
//
//  Created by Louis Fernando on 22/07/25.
//

import SwiftUI

enum GameMode: String, CaseIterable, Identifiable {
    case stl = "Sort The Letters"
    case fitb = "Fill In The Blank"
    var id: Self { self }
}

struct LeaderboardView: View {
    @ObservedObject var gameKitManager: GameKitManager
    
    let stlLeaderboardID: String
    let fitbLeaderboardID: String
    
    @State private var selectedGameMode: GameMode = .stl
    
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color("background_color").ignoresSafeArea()
            
            VStack {
                Picker("Game Mode", selection: $selectedGameMode) {
                    ForEach(GameMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if isLoading {
                    ProgressView {
                        Text("Fetching Scores...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxHeight: .infinity)
                } else if gameKitManager.leaderboardEntries.isEmpty {
                    emptyStateView(message: "No scores yet.\nBe the first to set a record!")
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(gameKitManager.leaderboardEntries) { entry in
                                LeaderboardRowView(entry: entry)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            fetchDataForSelectedMode()
        }
        .onChange(of: selectedGameMode) { _, _ in
            fetchDataForSelectedMode()
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack {
            Image(systemName: "list.star")
                .font(.largeTitle)
                .padding(.bottom, 8)
            Text(message)
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.gray)
        .frame(maxHeight: .infinity)
    }
    
    private func fetchDataForSelectedMode() {
        isLoading = true
        
        let leaderboardID = (selectedGameMode == .stl) ? stlLeaderboardID : fitbLeaderboardID
        
        Task {
            await gameKitManager.fetchLeaderboardEntries(id: leaderboardID)
            await MainActor.run {
                isLoading = false
            }
        }
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
            
            Text(entry.score.components(separatedBy: " ").first ?? entry.score)
                .font(.title2).bold()
                .foregroundColor(.white)
            
            Image("coin")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}
