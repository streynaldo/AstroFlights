//
//  HapticsManager.swift
//  WordInvaders
//
//  Created by Louis Fernando on 10/07/25.
//

import Foundation
import UIKit

// Class untuk mengelola semua feedback haptic
final class HapticsManager {
    static let shared = HapticsManager() // Singleton pattern
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    private init() {}
    
    // Haptic untuk notifikasi (sukses, error, warning)
    func trigger(_ notificationType: UINotificationFeedbackGenerator.FeedbackType) {
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(notificationType)
    }
    
    // Haptic untuk impact/benturan (ringan, medium, berat)
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
