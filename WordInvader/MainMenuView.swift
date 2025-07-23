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
    
    var body: some View {
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
                            .font(.system(size: 48, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                            .shadow(color: .black, radius: 2, x: 2, y: 2)
                        
                        Text("INVADERS")
                            .font(.system(size: 48, weight: .black, design: .monospaced))
                            .foregroundColor(.yellow)
                            .shadow(color: .black, radius: 2, x: 2, y: 2)
                    }
                    
                    Spacer()
                    
                    // GAME MODE SELECTION
                    VStack(spacing: 30) {
                        Text("SELECT GAME MODE")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                        
                        VStack(spacing: 20) {
                            // FILL IN THE BLANKS MODE
                            Button(action: {
                                showFITBGame = true
                            }) {
                                VStack(spacing: 8) {
                                    Text("FILL IN THE BLANKS")
                                        .font(.system(size: 18, weight: .black, design: .monospaced))
                                        .foregroundColor(.black)
                                    
                                    Text("Complete missing letters")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .opacity(0.8)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 30)
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
                                        .font(.system(size: 18, weight: .black, design: .monospaced))
                                        .foregroundColor(.black)
                                    
                                    Text("Spell words by shooting")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .opacity(0.8)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 30)
                                .background(Color.yellow)
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
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
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
            STLGameLayout()
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
