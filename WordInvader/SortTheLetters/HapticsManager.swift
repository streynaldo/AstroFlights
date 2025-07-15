//
//  HapticsManager.swift
//  WordInvaders
//
//  Created by Louis Fernando on 10/07/25.
//

import Foundation
import UIKit

final class HapticsManager {
    static let shared = HapticsManager()
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    private init() {}
    
    func trigger(_ notificationType: UINotificationFeedbackGenerator.FeedbackType) {
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(notificationType)
    }
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
