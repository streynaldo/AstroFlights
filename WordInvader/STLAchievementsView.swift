//
//  STLAchievementsView.swift
//  WordInvader
//
//  Created by Louis Fernando on 22/07/25.
//

import SwiftUI

struct STLAchievementsView: View {
    
    @ObservedObject var gameKitManager: GameKitManager
    
    let achievementFilter: String?
    
    let gridLayout = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            Color("background_color").ignoresSafeArea()
            
            if gameKitManager.achievements.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridLayout, spacing: 20) {
                        ForEach(gameKitManager.achievements) { achievement in
                            AchievementCardView(achievement: achievement)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            gameKitManager.fetchAchievements(filterBy: achievementFilter)
        }
        .navigationTitle("Pencapaian")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AchievementCardView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack {
            Image(systemName: achievement.isCompleted ? "star.fill" : "lock.fill")
                .font(.largeTitle)
                .foregroundColor(achievement.isCompleted ? .yellow : .gray)
                .padding()
            
            Text(achievement.title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
            
            Text("\(achievement.points) Poin")
                .font(.caption2).bold()
                .foregroundColor(achievement.isCompleted ? .yellow : .gray)
                .padding(.top, 4)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .opacity(achievement.isCompleted ? 1.0 : 0.7)
    }
}
