//
//  SoundManager.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 25/07/25.
//

import SpriteKit
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var bgmNode: SKAudioNode?
    private var isBGMPlaying = false
    private var currentBGM: String?
    
    private init() {}
    
    func playBGM(named name: String, on scene: SKScene, looped: Bool = true) {
        stopBGM()
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else { return }
        let node = SKAudioNode(url: url)
        node.autoplayLooped = looped
        scene.addChild(node)
        bgmNode = node
        isBGMPlaying = true
        currentBGM = name
    }
    
    func stopBGM() {
        bgmNode?.run(SKAction.stop())
        bgmNode?.removeFromParent()
        bgmNode = nil
        isBGMPlaying = false
        currentBGM = nil
    }
    
    func resumeBGM() {
        bgmNode?.run(SKAction.play())
        isBGMPlaying = true
    }
    
    func pauseBGM() {
        bgmNode?.run(SKAction.pause())
        isBGMPlaying = false
    }
    
    func playSoundEffect(named name: String, on scene: SKScene) {
        scene.run(SKAction.playSoundFileNamed(name, waitForCompletion: false))
    }
    
    func isPlayingBGM(named name: String) -> Bool {
        return isBGMPlaying && currentBGM == name
    }
}
