//
//  STLAchievementsView.swift
//  WordInvader
//
//  Created by Louis Fernando on 22/07/25.
//

import SwiftUI

struct AchievementsView: View {
    @ObservedObject var gameKitManager: GameKitManager
    
    let stlAchievementFilter: String
    let fitbAchievementFilter: String
    
    @State private var selectedGameMode: GameMode = .stl
    
    let gridLayout = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    
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
                        Text("Fetching Achievements...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxHeight: .infinity)
                } else if gameKitManager.achievements.isEmpty && isLoading {
                    emptyStateView(message: "No achievements to show.\nKeep playing to unlock them!")
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridLayout, spacing: 16) {
                            ForEach(gameKitManager.achievements) { achievement in
                                AchievementCardView(achievement: achievement)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            fetchDataForSelectedMode()
            isLoading = false
        }
        .onChange(of: selectedGameMode) { _, _ in
            fetchDataForSelectedMode()
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack {
            Image(systemName: "star.slash")
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
        
        let filter = (selectedGameMode == .stl) ? stlAchievementFilter : fitbAchievementFilter
        
        Task {
            await gameKitManager.fetchAchievements(filterBy: filter)
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct AchievementCardView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 20) {
            Group {
                if let uiImage = achievement.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "shield.slash")
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(Circle().stroke(achievement.isCompleted ? Color.yellow : Color.gray, lineWidth: 2))
            
            Text(achievement.title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .opacity(achievement.isCompleted ? 1.0 : 0.5)
    }
}
