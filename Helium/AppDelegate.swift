//
//  AppDelegate.swift
//  Helium
//
//  Created by Fuuko on 2024/3/27.
//

import Intents
import SwiftUI
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Load fonts from app
        if let appFontsPath = Bundle.main.resourcePath?.appending("/fonts") {
            FontUtils.shared().loadFonts(fromFolder: appFontsPath)
        }

        // Load fonts from documents
        if let documentsFontsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            FontUtils.shared().loadFonts(fromFolder: documentsFontsPath)
        }

//        window = UIWindow(frame: UIScreen.main.bounds)
//        let hostingController = UIHostingController(rootView: MainAppView())
//        window?.rootViewController = hostingController
//        window?.makeKeyAndVisible()
        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == "com.leemin.helium.shortcut.toggle-hud" {
            SetHUDEnabledBridger(!IsHUDEnabledBridger())
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.scheme == "helium" {
            if url.host == "toggle" {
                SetHUDEnabledBridger(!IsHUDEnabledBridger())
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            } else if url.host == "on" && !IsHUDEnabledBridger() {
                SetHUDEnabledBridger(true)
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            } else if url.host == "off" && IsHUDEnabledBridger() {
                SetHUDEnabledBridger(false)
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            } else {
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            }
        }
        return false
    }

//    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
//        if userActivity.activityType == String(describing: ToggleHUDIntent.self) {
//            SetHUDEnabledBridger(!IsHUDEnabledBridger())
//            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
//        } else if userActivity.activityType == String(describing: ShowHUDIntent.self) && !IsHUDEnabledBridger() {
//            SetHUDEnabledBridger(true)
//            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
//        } else if userActivity.activityType == String(describing: HideHUDIntent.self) && IsHUDEnabledBridger() {
//            SetHUDEnabledBridger(false)
//            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
//        } else {
//            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
//        }
//
//        return true
//    }

    func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
        switch intent {
        case is ToggleHUDIntent:
            return ToggleHUDIntentHandler()
        case is ShowHUDIntent:
            return ShowHUDIntentHandler()
        case is HideHUDIntent:
            return HideHUDIntentHandler()
        default:
            return nil
        }
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
