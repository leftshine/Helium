//
//  HideHUDIntentHandler.swift
//  Helium
//
//  Created by Fuuko on 2024/4/6.
//

import Foundation
import Intents

class HideHUDIntentHandler: NSObject, HideHUDIntentHandling {
    func handle(intent: HideHUDIntent, completion: @escaping (HideHUDIntentResponse) -> Void) {
        if IsHUDEnabledBridger() {
            SetHUDEnabledBridger(false)
        }
        completion(HideHUDIntentResponse(code: .success, userActivity: nil))
    }
}
