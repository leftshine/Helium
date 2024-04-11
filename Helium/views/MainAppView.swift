//
//  MainAppView.swift
//  Helium
//
//  Created by lemin on 10/11/23.
//

import Foundation
import SwiftUI

var firstRun = true

// MARK: Root View

struct MainAppView: View {
    @State var debugMode = false
    @State var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Page
            HomePageView()
                .tabItem {
                    Label(NSLocalizedString("Home", comment: ""), systemImage: "house")
                }
                .tag(Tab.home)

            // Widget Customization
            WidgetCustomizationView()
                .tabItem {
                    Label(NSLocalizedString("Customize", comment: ""), systemImage: "paintbrush")
                }
                .tag(Tab.customization)

            // Settings
            SettingsView()
                .tabItem {
                    Label(NSLocalizedString("Settings", comment: ""), systemImage: "gear")
                }
                .tag(Tab.settings)

            if debugMode {
                // Debug
                DebugPageView()
                    .tabItem {
                        Label(NSLocalizedString("Debug", comment: ""), systemImage: "ladybug")
                    }
                    .tag(Tab.debug)
            }
        }
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            } else {
                // Fallback on earlier versions
            }

            do {
                try FileManager.default.contentsOfDirectory(atPath: "/var/mobile")
                // warn to turn on developer mode if iOS 16+
                if #available(iOS 16.0, *), !UserDefaults.standard.bool(forKey: "hasWarnedOfDevMode", forPath: USER_DEFAULTS_PATH) {
                    UIApplication.shared.confirmAlert(title: NSLocalizedString("Info", comment: ""), body: NSLocalizedString("Make sure you enable developer mode before using! This will not work otherwise.", comment: ""), onOK: {
                        UserDefaults.standard.setValue(true, forKey: "hasWarnedOfDevMode", forPath: USER_DEFAULTS_PATH)
                    }, noCancel: true)
                }
                firstRun = UserDefaults.standard.loadUserDefaults(forPath: USER_DEFAULTS_PATH).count == 0
                return
            } catch {
                UIApplication.shared.alert(title: NSLocalizedString("Not Supported", comment: ""), body: NSLocalizedString("This app must be installed with TrollStore.", comment: ""))
            }
        }
        .onTapGesture(count: 5) {
            if self.selectedTab == .settings {
                debugMode = true
            }
        }
    }
}

extension MainAppView {
    enum Tab: Hashable {
        case home
        case customization
        case settings
        case debug
    }
}

#Preview {
    MainAppView()
}
