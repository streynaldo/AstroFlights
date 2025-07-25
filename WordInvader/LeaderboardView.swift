//
//  STLLeaderboardView.swift
//  WordInvader
//
//  Created by Louis Fernando on 22/07/25.
//

import SwiftUI
import SpriteKit

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
        GeometryReader { geometry in
            ZStack {
                SpriteView(scene: {
                    let scene = MainMenuScene()
                    scene.size = geometry.size
                    scene.scaleMode = .aspectFill
                    return scene
                }())
                .ignoresSafeArea()
                
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack {
                    Picker("Game Mode", selection: $selectedGameMode) {
                        ForEach(GameMode.allCases) { mode in
                            Text(mode.rawValue)
                                .font(.custom("VTF MisterPixel", size:20))
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if isLoading {
                        ProgressView {
                            Text("Fetching Scores...")
                                .font(.custom("VTF MisterPixel", size:20))
                                .foregroundColor(.white)
                        }
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxHeight: .infinity)
                    } else if gameKitManager.leaderboardEntries.isEmpty {
                        emptyStateView(message: "No scores yet.\nBe the first to set a record!")
                    } else {
                        ScrollView {
                            VStack(spacing: 26) {
                                ForEach(gameKitManager.leaderboardEntries) { entry in
                                    LeaderboardRowView(entry: entry)
                                }
                            }
                            .padding(.all)
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
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack {
            Image(systemName: "list.star")
                .font(.largeTitle)
                .padding(.bottom, 2)
            Text(message)
                .font(.custom("Born2bSporty FS", size:24))
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
    
    private var rankBackgroundImageName: String {
        switch entry.rank {
        case 1:
            return "leaderboard_row_1st"
        case 2:
            return "leaderboard_row_2nd"
        case 3:
            return "leaderboard_row_3rd"
        default:
            return "leaderboard_row_default"
        }
    }
    
    var body: some View {
        HStack {
            Text("\(entry.rank)")
                .font(.custom("VTF MisterPixel", size:24))
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .padding(.trailing, 12)
            
            Text(entry.playerName)
                .font(.custom("VTF MisterPixel", size:24))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(entry.score.components(separatedBy: " ").first ?? entry.score)
                .font(.custom("VTF MisterPixel", size:30))
                .foregroundColor(.white)
            
            Image("coin")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .padding(.all, 30)
        .background(
            Image(rankBackgroundImageName)
                .resizable()
        )
        .frame(height: 70)
        .padding(.horizontal, 2)
    }
}
