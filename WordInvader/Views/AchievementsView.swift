//
//  STLAchievementsView.swift
//  WordInvader
//
//  Created by Louis Fernando on 22/07/25.
//

import SwiftUI
import SpriteKit

struct AchievementsView: View {
    @ObservedObject var gameKitManager: GameKitManager
    
    let stlAchievementFilter: String
    let fitbAchievementFilter: String
    
    @State private var selectedGameMode: GameMode = .stl
    
    let gridLayout = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    
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
                            Text("Fetching Achievements...")
                                .font(.custom("VTF MisterPixel", size:20))
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
                        }
                        .padding(.horizontal)
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
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack {
            Image(systemName: "star.slash")
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
        if achievement.id.contains("1000") && achievement.isCompleted {
            return "1000_score_card"
        } else if achievement.id.contains("100") && achievement.isCompleted {
            return "100_score_card"
        } else if achievement.id.contains("personal_record") && achievement.isCompleted {
            return "new_personal_record_card"
        }
        return "locked_achievement_card"
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
        ZStack(alignment: .center, content: {
            Image(cardBackgroundImageName)
                .resizable()
                .scaledToFill()
            
            VStack(spacing: 16) {
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
                    .font(.custom("VTF MisterPixel", size:18))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                
                Text(achievement.description)
                    .font(.custom("VTF MisterPixel", size:16))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        })
        .opacity(achievement.isCompleted ? 1.0 : 0.5)
    }
}
