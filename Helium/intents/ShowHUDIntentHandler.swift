//
//  ShowHUDIntentHandler.swift
//  Helium
//
//  Created by Fuuko on 2024/4/6.
//

import Foundation
import Intents

class ShowHUDIntentHandler: NSObject, ShowHUDIntentHandling {
    func handle(intent: ShowHUDIntent, completion: @escaping (ShowHUDIntentResponse) -> Void) {
        if !IsHUDEnabledBridger() {
            SetHUDEnabledBridger(true)
        }
        completion(ShowHUDIntentResponse(code: .success, userActivity: nil))
    }
}
