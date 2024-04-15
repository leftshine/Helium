//
//  DisableWidgetSetIntentHandler.swift
//  Helium
//
//  Created by Fuuko on 2024/4/14.
//

import Foundation
import Intents

class DisableWidgetSetIntentHandler: NSObject, DisableWidgetSetIntentHandling {
    func handle(intent: DisableWidgetSetIntent, completion: @escaping (DisableWidgetSetIntentResponse) -> Void) {
        if let id = intent.id {
            WidgetManager().disableWidgetSetByID(id: id)
        }
        completion(DisableWidgetSetIntentResponse(code: .success, userActivity: nil))
    }
}
