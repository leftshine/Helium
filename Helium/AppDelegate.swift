//
//  AppDelegate.swift
//  Helium
//
//  Created by Fuuko on 2024/3/27.
//

import Intents
import Sentry
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

        SentrySDK.start { options in
            options.dsn = SENTRY_DSN
            options.debug = true // Enabled debug when first installing is always helpful
            options.environment = SENTRY_ENV

            // Enable all experimental features
            options.attachViewHierarchy = true
            options.enablePreWarmedAppStartTracing = true
            options.enableTimeToFullDisplayTracing = true
            options.swiftAsyncStacktraces = true
//            options.tracesSampleRate = 1.0
        }

        return true
    }

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
