//
//  SettingsView.swift
//  Helium
//
//  Created by lemin on 10/19/23.
//

import SwiftUI

// MARK: Settings View

struct SettingsView: View {
    // Preference Variables
    @State var apiKey: String = ""
    @State var dateLocale: String = Locale.current.languageCode!
    @State var hideSaveConfirmation: Bool = false
    @State var debugBorder: Bool = false
    @State var hideOnScreenshot: Bool = false
    @State var weatherProvider: Int = 0
    @State var weatherApiKey: String = ""
    @State var freeSub: Bool = true
    @State var isPreRelease = false

    var body: some View {
        NavigationView {
            List {
                // App Version/Build Number
                Section {
                } header: {
                    #if DEBUG
                        Label(NSLocalizedString("Version ", comment: "") + "\(Bundle.main.releaseVersionNumber ?? NSLocalizedString("UNKNOWN", comment: "")) (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)) \(NSLocalizedString("SDebug", comment: ""))", systemImage: "info")
                    #else
                        Label(NSLocalizedString("Version ", comment: "") + "\(Bundle.main.releaseVersionNumber ?? NSLocalizedString("UNKNOWN", comment: "")) (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)) \(NSLocalizedString("SRelease", comment: ""))", systemImage: "info")
                    #endif
                }

                // Preferences List
                Section {
                    HStack {
                        Text(NSLocalizedString("Locale", comment: ""))
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        DropdownPicker(selection: $dateLocale) {
                            [
                                DropdownItem("en", tag: "en"),
                                DropdownItem("zh", tag: "zh"),
                            ]
                        }
                    }

                    HStack {
                        Toggle(isOn: $hideSaveConfirmation) {
                            Text(NSLocalizedString("Hide Save Confirmation Popup", comment: ""))
                                .bold()
                                .minimumScaleFactor(0.5)
                        }
                    }

                    HStack {
                        Toggle(isOn: $debugBorder) {
                            Text(NSLocalizedString("Display Debug Border", comment: ""))
                                .bold()
                                .minimumScaleFactor(0.5)
                        }
                    }

                    HStack {
                        Toggle(isOn: $hideOnScreenshot) {
                            Text(NSLocalizedString("Hide HUD On Screenshot", comment: ""))
                                .bold()
                                .minimumScaleFactor(0.5)
                        }
                    }

                    HStack {
                        Text(NSLocalizedString("Helium Data", comment: ""))
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button(action: {
                            do {
                                try UserDefaults.standard.deleteUserDefaults(forPath: USER_DEFAULTS_PATH)
                                UIApplication.shared.alert(title: NSLocalizedString("Successfully deleted user data!", comment: ""), body: NSLocalizedString("Please restart the app to continue.", comment: ""))
                            } catch {
                                UIApplication.shared.alert(title: NSLocalizedString("Failed to delete user data!", comment: ""), body: error.localizedDescription)
                            }
                        }) {
                            Text(NSLocalizedString("Reset Data", comment: ""))
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Label(NSLocalizedString("Preferences", comment: ""), systemImage: "gear")
                }

                // Weather List
                Section {
                    HStack {
                        Text(NSLocalizedString("Weather Provider", comment: ""))
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        DropdownPicker(selection: $weatherProvider) {
                            [
                                DropdownItem(NSLocalizedString("System Weather", comment: ""), tag: 0),
                                DropdownItem(NSLocalizedString("QWeather", comment: ""), tag: 1),
                                DropdownItem(NSLocalizedString("ColorfulClouds", comment: ""), tag: 2),
                                DropdownItem(NSLocalizedString("OpenWeatherMap", comment: ""), tag: 3),
                            ]
                        }
                    }

                    if weatherProvider == 1 || weatherProvider == 2 || weatherProvider == 3 {
                        HStack {
                            Text(NSLocalizedString("Weather API Key", comment: ""))
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            TextField("", text: $weatherApiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        if weatherProvider == 1 {
                            HStack {
                                Toggle(isOn: $freeSub) {
                                    Text(NSLocalizedString("Free Subscription API", comment: ""))
                                        .bold()
                                        .minimumScaleFactor(0.5)
                                }
                            }
                        }
                    }
                } header: {
                    Label(NSLocalizedString("Weather", comment: ""), systemImage: "cloud.sun")
                }

                // Update List
                Section {
                    HStack {
                        Toggle(isOn: $isPreRelease) {
                            Text(NSLocalizedString("Pre-Release version?", comment: ""))
                                .bold()
                                .minimumScaleFactor(0.5)
                        }
                    }

                    HStack {
                        Text(NSLocalizedString("Update", comment: ""))
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button(action: {
                            UIApplication.shared.confirmAlert(title: NSLocalizedString("Update", comment: ""), body: NSLocalizedString("Would you like to check for updates?", comment: ""), onOK: {
                                updateCheck()
                            }, noCancel: false)
                        }) {
                            Text(NSLocalizedString("Check Update", comment: ""))
                        }
                    }
                } header: {
                    Label(NSLocalizedString("Update", comment: ""), systemImage: "arrow.up.square")
                }

                // Credits List
                Section {
                    LinkCell(imageName: "LeminLimez", url: "https://github.com/leminlimez", title: "LeminLimez", contribution: NSLocalizedString("Main Developer", comment: "leminlimez's contribution"), circle: true)
                    LinkCell(imageName: "Lessica", url: "https://github.com/Lessica/TrollSpeed", title: "Lessica", contribution: NSLocalizedString("TrollSpeed & Assistive Touch Logic", comment: "lessica's contribution"), circle: true)
                    LinkCell(imageName: "Fuuko", url: "https://github.com/AsakuraFuuko", title: "Fuuko", contribution: NSLocalizedString("Modder", comment: "Fuuko's contribution"), circle: true)
                    LinkCell(imageName: "BomberFish", url: "https://github.com/BomberFish", title: "BomberFish", contribution: NSLocalizedString("UI improvements", comment: "BomberFish's contribution"), circle: true)
                } header: {
                    Label(NSLocalizedString("Credits", comment: ""), systemImage: "wrench.and.screwdriver")
                }
            }
            .toolbar {
                HStack {
                    Button(action: {
                        saveChanges()
                    }) {
                        Text(NSLocalizedString("Save", comment: ""))
                    }
                }
            }
            .onAppear {
                loadSettings()
            }
            .navigationTitle(Text(NSLocalizedString("Settings", comment: "")))
            .listStyle(.insetGrouped)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    func loadSettings() {
        dateLocale = UserDefaults.standard.string(forKey: "dateLocale", forPath: USER_DEFAULTS_PATH) ?? Locale.current.languageCode!
        hideSaveConfirmation = UserDefaults.standard.bool(forKey: "hideSaveConfirmation", forPath: USER_DEFAULTS_PATH)
        hideOnScreenshot = UserDefaults.standard.bool(forKey: "hideOnScreenshot", forPath: USER_DEFAULTS_PATH)
        debugBorder = UserDefaults.standard.bool(forKey: "debugBorder", forPath: USER_DEFAULTS_PATH)
        weatherProvider = UserDefaults.standard.integer(forKey: "weatherProvider", forPath: USER_DEFAULTS_PATH)
        weatherApiKey = UserDefaults.standard.string(forKey: "weatherApiKey", forPath: USER_DEFAULTS_PATH) ?? ""
        freeSub = UserDefaults.standard.bool(forKey: "freeSub", forPath: USER_DEFAULTS_PATH)
        isPreRelease = UserDefaults.standard.bool(forKey: "isPreRelease", forPath: USER_DEFAULTS_PATH)
    }

    func saveChanges() {
        UserDefaults.standard.setValue(dateLocale, forKey: "dateLocale", forPath: USER_DEFAULTS_PATH)
        UserDefaults.standard.setValue(hideSaveConfirmation, forKey: "hideSaveConfirmation", forPath: USER_DEFAULTS_PATH)
        UserDefaults.standard.setValue(hideOnScreenshot, forKey: "hideOnScreenshot", forPath: USER_DEFAULTS_PATH)
        UserDefaults.standard.setValue(debugBorder, forKey: "debugBorder", forPath: USER_DEFAULTS_PATH)
        UserDefaults.standard.setValue(freeSub, forKey: "freeSub", forPath: USER_DEFAULTS_PATH)
        UserDefaults.standard.setValue(isPreRelease, forKey: "isPreRelease", forPath: USER_DEFAULTS_PATH)
        UserDefaults.standard.setValue(weatherProvider, forKey: "weatherProvider", forPath: USER_DEFAULTS_PATH)
        UserDefaults.standard.setValue(weatherApiKey, forKey: "weatherApiKey", forPath: USER_DEFAULTS_PATH)
        UIApplication.shared.alert(title: NSLocalizedString("Save Changes", comment: ""), body: NSLocalizedString("Settings saved successfully", comment: ""))
        DarwinNotificationCenter.default.post(name: NOTIFY_RELOAD_HUD)
    }

    func updateCheck() {
        UpdateUtils.fetchLatestRelease(forRepo: "AsakuraFuuko/Helium", isPreRelease: isPreRelease) { result in
            guard let resultDict = result as? [String: String],
                  let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
                  let latestVersion = resultDict["latestVersion"],
                  let assetUrl = resultDict["assetUrl"] else {
                // Unable to fetch latest release information or retrieve current version or latest version or asset URL
                UIApplication.shared.alert(body: NSLocalizedString("Unable to get updates.", comment: ""))
                return
            }

            if let err = resultDict["error"] {
                UIApplication.shared.alert(body: err)
                return
            }

            if currentVersion == latestVersion {
                UIApplication.shared.alert(title: NSLocalizedString("Info", comment: ""), body: NSLocalizedString("The current version is already up to date!", comment: ""))
            } else {
                UIApplication.shared.confirmAlert(title: NSLocalizedString("Info", comment: ""), body: "\(NSLocalizedString("New version found, Would you like to install it via TrollStore?", comment: ""))\n\(latestVersion)", onOK: {
                    if UIApplication.shared.canOpenURL(URL(string: "apple-magnifier://install?url=\(assetUrl)")!) {
                        UIApplication.shared.open(URL(string: "apple-magnifier://install?url=\(assetUrl)")!, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.alert(body: NSLocalizedString("Unable to open the link.", comment: ""))
                    }
                }, noCancel: false)
            }
        }
    }

    // Link Cell code from Cowabunga
    struct LinkCell: View {
        var imageName: String
        var url: String
        var title: String
        var contribution: String
        var systemImage: Bool = false
        var imageInBundle: Bool = false
        var circle: Bool = false

        var body: some View {
            HStack(alignment: .center) {
                Group {
                    if systemImage {
                        Image(systemName: imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if imageInBundle {
                        let url = Bundle.main.url(forResource: "credits/" + imageName, withExtension: "png")
                        if url != nil {
                            Image(uiImage: UIImage(contentsOfFile: url!.path)!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    } else {
                        if imageName != "" {
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                }
                .cornerRadius(circle ? .infinity : 0)
                .frame(width: 24, height: 24)

                VStack {
                    HStack {
                        Button(action: {
                            if url != "" {
                                UIApplication.shared.open(URL(string: url)!)
                            }
                        }) {
                            Text(title)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 6)
                        Spacer()
                    }
                    HStack {
                        Text(contribution)
                            .padding(.horizontal, 6)
                            .font(.footnote)
                        Spacer()
                    }
                }
            }
            .foregroundColor(.blue)
        }
    }
}

#Preview {
    SettingsView()
}
