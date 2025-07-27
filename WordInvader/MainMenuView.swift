//
//  MainMenuView.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 23/07/25.
//

import SwiftUI
import SpriteKit

struct MainMenuView: View {
    @State private var showFITBGame = false
    @State private var showSTLGame = false
    @State private var gameKitManager = GameKitManager()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background with MainMenuScene
                    SpriteView(scene: {
                        let scene = MainMenuScene()
                        scene.size = geometry.size
                        scene.scaleMode = .aspectFill
                        return scene
                    }())
                    .ignoresSafeArea()
                    
                    // Main Menu Overlay
                    VStack(spacing: 40) {
                        Spacer()
                        
                        // GAME TITLE
                        VStack(spacing: 10) {
                            Text("WORD")
                                .font(.custom("VTF MisterPixel", size:48))
                                .foregroundColor(.cyan)
                                .shadow(color: .black, radius: 2, x: 2, y: 2)
                            
                            Text("INVADERS")
                                .font(.custom("VTF MisterPixel", size:48))
                                .foregroundColor(.yellow)
                                .shadow(color: .black, radius: 2, x: 2, y: 2)
                        }
                        
                        Spacer()
                        
                        // GAME MODE SELECTION
                        VStack(spacing: 30) {
                            Text("SELECT GAME MODE")
                                .font(.custom("VTF MisterPixel", size:16))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                            
                            VStack(spacing: 20) {
                                // FILL IN THE BLANKS MODE
                                Button(action: {
                                    showFITBGame = true
                                }) {
                                    VStack(spacing: 8) {
                                        Text("FILL IN THE BLANKS")
                                            .font(.custom("VTF MisterPixel", size:18))
                                            .foregroundColor(.black)
                                        
                                        Text("Complete missing letters")
                                            .font(.custom("VTF MisterPixel", size:12))
                                            .foregroundColor(.black)
                                            .opacity(0.8)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 30)
                                    .frame(maxWidth: 260)
                                    .background(Color.green)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 0)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(color: .white, radius: 0, x: 3, y: 3)
                                }
                                
                                // SHOOT THE LETTERS MODE
                                Button(action: {
                                    showSTLGame = true
                                }) {
                                    VStack(spacing: 8) {
                                        Text("SHOOT THE LETTERS")
                                            .font(.custom("VTF MisterPixel", size:18))
                                            .foregroundColor(.black)
                                        
                                        Text("Spell words by shooting")
                                            .font(.custom("VTF MisterPixel", size:12))
                                            .foregroundColor(.black)
                                            .opacity(0.8)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 30)
                                    .frame(maxWidth: 260)
                                    .background(Color.yellow)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 0)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(color: .white, radius: 0, x: 3, y: 3)
                                }
                                
                                // LEADERBOARD BUTTON
                                NavigationLink(destination: LeaderboardView(gameKitManager: gameKitManager, stlLeaderboardID: "sort_the_letters_leaderboard", fitbLeaderboardID: "fill_in_the_blank_leaderboard")) {
                                    Text("LEADERBOARD")
                                        .font(.custom("VTF MisterPixel", size:18))
                                        .foregroundColor(.black)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 30)
                                        .frame(maxWidth: 260)
                                        .background(Color.blue)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 0)
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                        .shadow(color: .white, radius: 0, x: 3, y: 3)
                                }
                                
                                // ACHIEVEMENTS BUTTON
                                NavigationLink(destination: AchievementsView(gameKitManager: gameKitManager, stlAchievementFilter: "sort_the_letters", fitbAchievementFilter: "fill_in_the_blank")) {
                                    Text("ACHIEVEMENTS")
                                        .font(.custom("VTF MisterPixel", size:18))
                                        .foregroundColor(.black)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 30)
                                        .frame(maxWidth: 260)
                                        .background(Color.purple)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 0)
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                        .shadow(color: .white, radius: 0, x: 3, y: 3)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // RETRO FOOTER TEXT
                        Text("CHOOSE YOUR BATTLE MODE, CAPTAIN!")
                            .font(.custom("VTF MisterPixel", size:12))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                    .background(Color.black.opacity(0.7))
                }
            }
            .fullScreenCover(isPresented: $showFITBGame) {
                FITBGameView()
            }
            .fullScreenCover(isPresented: $showSTLGame) {
//                STLGameView()
            }
        }
        .onAppear() {
            gameKitManager.authenticatePlayer()
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
