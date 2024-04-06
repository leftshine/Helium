//
//  SceneDelegate.swift
//  Helium
//
//  Created by Fuuko on 2024/4/6.
//

// https://qiita.com/ichikawa7ss/items/8d06d1dd23950162f436

import SwiftUI
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        if let shortcutItem = connectionOptions.shortcutItem {
            handlerShortcut(shortcutItem)
        }

        if let url = connectionOptions.urlContexts.first?.url {
            handlerURL(url)
        }

        window = UIWindow(windowScene: windowScene)
//        window = UIWindow(frame: UIScreen.main.bounds)
        let hostingController = UIHostingController(rootView: MainAppView())
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        handlerShortcut(shortcutItem)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        handlerURL(url)
    }

    func handlerShortcut(_ shortcutItem: UIApplicationShortcutItem) {
        if shortcutItem.type == "com.leemin.helium.shortcut.toggle-hud" {
            SetHUDEnabledBridger(!IsHUDEnabledBridger())
            exitApp()
        }
    }

    func handlerURL(_ url: URL) {
        if url.scheme == "helium" {
            if url.host == "toggle" {
                SetHUDEnabledBridger(!IsHUDEnabledBridger())
            } else if url.host == "on" && !IsHUDEnabledBridger() {
                SetHUDEnabledBridger(true)
            } else if url.host == "off" && IsHUDEnabledBridger() {
                SetHUDEnabledBridger(false)
            }
            exitApp()
        }
    }

    func exitApp() {
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        sleep(1)
        exit(0)
    }
}
