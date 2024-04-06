//
//  SceneDelegate.swift
//  Helium
//
//  Created by Fuuko on 2024/4/6.
//

import SwiftUI
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        window = UIWindow(windowScene: windowScene)
//        window = UIWindow(frame: UIScreen.main.bounds)
        let hostingController = UIHostingController(rootView: MainAppView())
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
    }
}
