//
//  Const.swift
//  Helium
//
//  Created by Fuuko on 2024/3/25.
//

import Foundation

let buildNumber: Int = 0
let configVersion: Int = 1
let NOTIFY_RELOAD_HUD = "com.leemin.notification.hud.reload"

#if DEBUG
    let DEBUG_MODE_ENABLED = true
#else
    let DEBUG_MODE_ENABLED = false
#endif

#if targetEnvironment(simulator)
    let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
    let USER_DEFAULTS_PATH = libraryDirectory + "/Preferences/com.leemin.helium.plist"
#else
    let USER_DEFAULTS_PATH = "/var/mobile/Library/Preferences/com.leemin.helium.plist"
#endif
