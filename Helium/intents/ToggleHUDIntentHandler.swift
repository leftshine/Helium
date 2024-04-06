//
//  ToggleHUDIntentHandler.swift
//  Helium
//
//  Created by Fuuko on 2024/4/6.
//

import Foundation
import Intents

class ToggleHUDIntentHandler: NSObject, ToggleHUDIntentHandling {
    func handle(intent: ToggleHUDIntent, completion: @escaping (ToggleHUDIntentResponse) -> Void) {
        SetHUDEnabledBridger(!IsHUDEnabledBridger())
        completion(ToggleHUDIntentResponse(code: .success, userActivity: nil))
    }
}
