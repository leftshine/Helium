//
//  EnableWidgetSetIntentHandler.swift
//  Helium
//
//  Created by Fuuko on 2024/4/14.
//

import Foundation
import Intents

class EnableWidgetSetIntentHandler: NSObject, EnableWidgetSetIntentHandling {
    func handle(intent: EnableWidgetSetIntent, completion: @escaping (EnableWidgetSetIntentResponse) -> Void) {
        if let id = intent.id {
            WidgetManager().enableWidgetSetByID(id: id)
        }
        completion(EnableWidgetSetIntentResponse(code: .success, userActivity: nil))
    }
}
