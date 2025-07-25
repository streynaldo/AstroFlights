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
                } else if gameKitManager.achievements.isEmpty {
                    emptyStateView(message: "No achievements to show.\nKeep playing to unlock them!")
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridLayout, spacing: 16) {
                            ForEach(gameKitManager.achievements) { achievement in
                                AchievementCardView(achievement: achievement)
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
    
    private var cardBackgroundImageName: String {
        if achievement.id.contains("1000") {
            return "1000_score_card"
        } else if achievement.id.contains("100") {
            return "100_score_card"
        } else if achievement.id.contains("personal_record") {
            return "new_personal_record_card"
        }
        return "achievement_card"
    }
    
    private var circleFrameImageName: String {
        if achievement.id.contains("1000") && achievement.isCompleted {
            return "1000_score_badge_ring"
        } else if achievement.id.contains("100") && achievement.isCompleted {
            return "100_score_badge_ring"
        } else if achievement.id.contains("personal_record") && achievement.isCompleted {
            return "new_personal_record_badge_ring"
        }
        return "locked_badge_ring"
    }
    
    var body: some View {
        ZStack {
            Image(cardBackgroundImageName)
                .resizable()
                .scaledToFill()
            
            VStack(spacing: 8) {
                ZStack {
                    Group {
                        if let uiImage = achievement.image {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: "shield.slash")
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    
                    Image(circleFrameImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                }
                
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Spacer(minLength: 0)
                
                Text(achievement.description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 24)
        }
        .opacity(achievement.isCompleted ? 1.0 : 0.5)
    }
}
