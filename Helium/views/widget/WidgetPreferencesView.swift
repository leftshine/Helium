//
//  WidgetPreferencesView.swift
//  Helium
//
//  Created by lemin on 10/18/23.
//

import Foundation
import SwiftUI

struct WidgetPreferencesView: View {
    @StateObject var widgetManager: WidgetManager
    @State var widgetSet: WidgetSetStruct
    @Binding var widgetID: WidgetIDStruct

    @State var text: String = NSLocalizedString("Example", comment: "")
    @State var dateFormat: String = NSLocalizedString("E MMM dd", comment: "")
    @State var networkUp: Int = 0
    @State var speedIcon: Int = 0
    @State var minUnit: Int = 1
    @State var hideSpeedWhenZero: Bool = false
    @State var useFahrenheit: Int = 0
    @State var batteryValueType: Int = 0
    @State var timeFormat: Int = 0
    @State var showPercentage: Bool = true
    @State var filledSymbol: Bool = true
    @State var weatherFormat: String = "{i}{n}{lt}°~{ht}°({t}°,{bt}°)💧{h}%"
    @State var weatherProvider: Int = 0
    @State var useCurrentLocation: Bool = false
    @State var useMetric: Int = 0
    @State var location: String = "116.40,39.90"
    @State var unsupported: Int = 0
    @State var unLyricsType: Int = 1
    @State var unBluetoothType: Int = 1
    @State var unWiredType: Int = 1
    @State var supported: Int = 0
    @State var lyricsType: Int = 0
    @State var bluetoothType: Int = 1
    @State var wiredType: Int = 1
    @State var displayType: Int = 0

    @State var modified: Bool = false
    @State private var isPresented = false

    let timeFormats: [String] = [
        "hh:mm",
        "hh:mm a",
        "hh:mm:ss",
        "hh",

        "HH:mm",
        "HH:mm:ss",
        "HH",

        "mm",
        "ss",
    ]

    let dateFormatter = DateFormatter()
    let currentDate = Date()

    var body: some View {
        VStack {
            // MARK: Preview

            WidgetPreviewsView(widget: $widgetID, previewColor: .white)

            switch widgetID.module {
            case .dateWidget:

                // MARK: Date Format Textbox

                HStack {
                    Text(NSLocalizedString("Date Format", comment: ""))
                        .foregroundColor(.primary)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField(NSLocalizedString("E MMM dd", comment: ""), text: $dateFormat.onChange { _ in
                        modified = true
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            case .network:

                // MARK: Network Type Choice

                VStack {
                    HStack {
                        Text(NSLocalizedString("Network Type", comment: ""))
                            .foregroundColor(.primary)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        DropdownPicker(selection: $networkUp.onChange { _ in
                            modified = true
                        }) {
                            [
                                DropdownItem(NSLocalizedString("Download", comment: ""), tag: 0),
                                DropdownItem(NSLocalizedString("Upload", comment: ""), tag: 1),
                            ]
                        }
                    }

                    // MARK: Speed Icon Choice

                    HStack {
                        Text(NSLocalizedString("Speed Icon", comment: ""))
                            .foregroundColor(.primary)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        DropdownPicker(selection: $speedIcon.onChange { _ in
                            modified = true
                        }) {
                            [
                                DropdownItem(speedIcon == 0 ? "▼" : "▲", tag: 0),
                                DropdownItem(speedIcon == 0 ? "↓" : "↑", tag: 1),
                            ]
                        }
                    }

                    // MARK: Minimum Unit Choice

                    HStack {
                        Text(NSLocalizedString("Minimum Unit", comment: ""))
                            .foregroundColor(.primary)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        DropdownPicker(selection: $minUnit.onChange { _ in
                            modified = true
                        }) {
                            [
                                DropdownItem("b", tag: 0),
                                DropdownItem("Kb", tag: 1),
                                DropdownItem("Mb", tag: 2),
                                DropdownItem("Gb", tag: 3),
                            ]
                        }
                    }

                    // MARK: Hide Speed When Zero

                    HStack {
                        Toggle(isOn: $hideSpeedWhenZero.onChange { _ in
                            modified = true
                        }) {
                            Text(NSLocalizedString("Hide Speed When 0", comment: ""))
                                .foregroundColor(.primary)
                                .bold()
                        }
                    }
                }
            case .temperature:

                // MARK: Battery Temperature Value

                HStack {
                    Text(NSLocalizedString("Temperature Unit", comment: ""))
                        .foregroundColor(.primary)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DropdownPicker(selection: $useFahrenheit.onChange { _ in
                        modified = true
                    }) {
                        [
                            DropdownItem(NSLocalizedString("Celcius", comment: ""), tag: 0),
                            DropdownItem(NSLocalizedString("Fahrenheit", comment: ""), tag: 1),
                        ]
                    }
                }
            case .battery:

                // MARK: Battery Value Type

                HStack {
                    Text(NSLocalizedString("Battery Option", comment: ""))
                        .foregroundColor(.primary)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DropdownPicker(selection: $batteryValueType.onChange { _ in
                        modified = true
                    }) {
                        [
                            DropdownItem(NSLocalizedString("Watts", comment: ""), tag: 0),
                            DropdownItem(NSLocalizedString("Charging Current", comment: ""), tag: 1),
                            DropdownItem(NSLocalizedString("Amperage", comment: ""), tag: 2),
                            DropdownItem(NSLocalizedString("Charge Cycles", comment: ""), tag: 3),
                        ]
                    }
                }
            case .timeWidget:

                // MARK: Time Format Selector

                HStack {
                    Text(NSLocalizedString("Time Format", comment: ""))
                        .foregroundColor(.primary)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DropdownPicker(selection: $timeFormat.onChange { _ in
                        modified = true
                    }) {
                        timeFormats.indices.map { index in
                            DropdownItem("\(getFormattedDate(timeFormats[index]))\n(\(timeFormats[index]))", tag: index)
                        }
                    }
                }
            case .textWidget:

                // MARK: Custom Text Label Textbox

                HStack {
                    Text(NSLocalizedString("Label Text", comment: ""))
                        .foregroundColor(.primary)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField(NSLocalizedString("Example", comment: ""), text: $text.onChange { _ in
                        modified = true
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            case .currentCapacity:

                // MARK: Current Capacity Choice

                HStack {
                    Toggle(isOn: $showPercentage.onChange { _ in
                        modified = true
                    }) {
                        Text(NSLocalizedString("Show Percent (%) Symbol", comment: ""))
                            .foregroundColor(.primary)
                            .bold()
                    }
                }
            case .chargeSymbol:

                // MARK: Charge Symbol Fill Option

                HStack {
                    Toggle(isOn: $filledSymbol.onChange { _ in
                        modified = true
                    }) {
                        Text(NSLocalizedString("Fill Symbol", comment: ""))
                            .foregroundColor(.primary)
                            .bold()
                    }
                }
            case .weather:
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        HStack {
                            Text(NSLocalizedString("Format", comment: ""))
                                .foregroundColor(.primary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            TextField("{i}{n}{lt}°~{ht}°({t}°,{bt}°)💧{h}%", text: $weatherFormat.onChange { _ in
                                modified = true
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        HStack {
                            Text(NSLocalizedString("Measurement System", comment: ""))
                                .foregroundColor(.primary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DropdownPicker(selection: $useMetric.onChange { _ in
                                modified = true
                            }) {
                                [
                                    DropdownItem(NSLocalizedString("Metric", comment: ""), tag: 0),
                                    DropdownItem(NSLocalizedString("US", comment: ""), tag: 1),
                                ]
                            }
                        }

                        HStack {
                            Text(NSLocalizedString("Temperature Unit", comment: ""))
                                .foregroundColor(.primary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DropdownPicker(selection: $useFahrenheit.onChange { _ in
                                modified = true
                            }) {
                                [
                                    DropdownItem(NSLocalizedString("Celcius", comment: ""), tag: 0),
                                    DropdownItem(NSLocalizedString("Fahrenheit", comment: ""), tag: 1),
                                ]
                            }
                        }

                        if weatherProvider == 0 {
                            HStack {
                                Text(NSLocalizedString("Weather Format System", comment: ""))
                                    .multilineTextAlignment(.leading)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        } else if weatherProvider != 0 {
                            HStack {
                                Toggle(isOn: $useCurrentLocation.onChange { _ in
                                    modified = true
                                }) {
                                    Text(NSLocalizedString("Use Current Location", comment: ""))
                                        .foregroundColor(.primary)
                                        .bold()
                                }.padding(.trailing, 4)
                            }

                            if !useCurrentLocation {
                                HStack {
                                    Text(NSLocalizedString("Location", comment: ""))
                                        .foregroundColor(.primary)
                                        .bold()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    TextField(NSLocalizedString("Input", comment: ""), text: $location.onChange { _ in
                                        modified = true
                                    })
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Button(NSLocalizedString("Get", comment: "")) {
                                        isPresented = true
                                    }
                                    .sheet(isPresented: $isPresented) {
                                        WeatherLocationView(location: self.$location, modified: self.$modified)
                                    }
                                }
                            }

                            if weatherProvider == 1 {
                                HStack {
                                    Text(NSLocalizedString("Weather Format QWeather", comment: ""))
                                        .multilineTextAlignment(.leading)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            } else if weatherProvider == 2 {
                                HStack {
                                    Text(NSLocalizedString("Weather Format ColorfulClouds", comment: ""))
                                        .multilineTextAlignment(.leading)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            case .lyrics:
                VStack {
                    HStack {
                        Text(NSLocalizedString("Unsupported Option", comment: ""))
                            .foregroundColor(.primary)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        DropdownPicker(selection: $unsupported.onChange { _ in
                            modified = true
                        }) {
                            [
                                DropdownItem(NSLocalizedString("Not Display", comment: ""), tag: 0),
                                DropdownItem(NSLocalizedString("Lock Screen Lyrics", comment: ""), tag: 1),
                                DropdownItem(NSLocalizedString("Online Lyrics", comment: ""), tag: 2),
                            ]
                        }
                    }

                    if unsupported == 1 {
                        HStack {
                            Text(NSLocalizedString("Lyrics Option", comment: ""))
                                .foregroundColor(.primary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DropdownPicker(selection: $unLyricsType.onChange { _ in
                                modified = true
                            }) {
                                [
                                    DropdownItem(NSLocalizedString("Title", comment: ""), tag: 1),
                                    DropdownItem(NSLocalizedString("Artist", comment: ""), tag: 2),
                                    DropdownItem(NSLocalizedString("Album", comment: ""), tag: 3),
                                ]
                            }
                        }

                        HStack {
                            Text(NSLocalizedString("Bluetooth Headset Option", comment: ""))
                                .foregroundColor(.primary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DropdownPicker(selection: $unBluetoothType.onChange { _ in
                                modified = true
                            }) {
                                [
                                    DropdownItem(NSLocalizedString("Title", comment: ""), tag: 1),
                                    DropdownItem(NSLocalizedString("Artist", comment: ""), tag: 2),
                                    DropdownItem(NSLocalizedString("Album", comment: ""), tag: 3),
                                ]
                            }
                        }

                        HStack {
                            Text(NSLocalizedString("Wired Headset Option", comment: ""))
                                .foregroundColor(.primary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DropdownPicker(selection: $unWiredType.onChange { _ in
                                modified = true
                            }) {
                                [
                                    DropdownItem(NSLocalizedString("Title", comment: ""), tag: 1),
                                    DropdownItem(NSLocalizedString("Artist", comment: ""), tag: 2),
                                    DropdownItem(NSLocalizedString("Album", comment: ""), tag: 3),
                                ]
                            }
                        }
                    }

                    HStack {
                        Text(NSLocalizedString("Supported Option", comment: ""))
                            .foregroundColor(.primary)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        DropdownPicker(selection: $supported.onChange { _ in
                            modified = true
                        }) {
                            [
                                DropdownItem(NSLocalizedString("Lock Screen Auto", comment: ""), tag: 0),
                                DropdownItem(NSLocalizedString("Lock Screen Manual", comment: ""), tag: 1),
                                DropdownItem(NSLocalizedString("Online Lyrics", comment: ""), tag: 2),
                            ]
                        }
                    }

                    if supported == 1 {
                        HStack {
                            Text(NSLocalizedString("Lyrics Option", comment: ""))
                                .foregroundColor(.primary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DropdownPicker(selection: $lyricsType.onChange { _ in
                                modified = true
                            }) {
                                [
                                    DropdownItem(NSLocalizedString("Title", comment: ""), tag: 1),
                                    DropdownItem(NSLocalizedString("Artist", comment: ""), tag: 2),
                                    DropdownItem(NSLocalizedString("Album", comment: ""), tag: 3),
                                ]
                            }
                        }

                        HStack {
                            Text(NSLocalizedString("Bluetooth Headset Option", comment: ""))
                                .foregroundColor(.primary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DropdownPicker(selection: $bluetoothType.onChange { _ in
                                modified = true
                            }) {
                                [
                                    DropdownItem(NSLocalizedString("Title", comment: ""), tag: 1),
                                    DropdownItem(NSLocalizedString("Artist", comment: ""), tag: 2),
                                    DropdownItem(NSLocalizedString("Album", comment: ""), tag: 3),
                                ]
                            }
                        }

                        HStack {
                            Text(NSLocalizedString("Wired Headset Option", comment: ""))
                                .foregroundColor(.primary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DropdownPicker(selection: $wiredType.onChange { _ in
                                modified = true
                            }) {
                                [
                                    DropdownItem(NSLocalizedString("Title", comment: ""), tag: 1),
                                    DropdownItem(NSLocalizedString("Artist", comment: ""), tag: 2),
                                    DropdownItem(NSLocalizedString("Album", comment: ""), tag: 3),
                                ]
                            }
                        }
                    }
                }
            case .cpumen:
                HStack {
                    Text(NSLocalizedString("Display Type", comment: ""))
                        .foregroundColor(.primary)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DropdownPicker(selection: $displayType.onChange { _ in
                        modified = true
                    }) {
                        [
                            DropdownItem(NSLocalizedString("System CPU Usage", comment: ""), tag: 0),
                            DropdownItem(NSLocalizedString("System Memory Total", comment: ""), tag: 1),
                            DropdownItem(NSLocalizedString("System Memory Usage", comment: ""), tag: 2),
                            DropdownItem(NSLocalizedString("Helium CPU Usage", comment: ""), tag: 3),
                            DropdownItem(NSLocalizedString("Helium Memory Usage", comment: ""), tag: 4),
                        ]
                    }
                }
//            default:
//                Text(NSLocalizedString("No Configurable Aspects", comment: ""))
            }
        }
        .padding(.horizontal, 15)
        .toolbar {
            HStack {
                // MARK: Save Button

                // only shows up if something is changed
                if modified {
                    Button(action: {
                        saveChanges()
                    }) {
                        Image(systemName: "checkmark.circle")
                    }
                }
            }
        }
        .onAppear {
            weatherProvider = UserDefaults.standard.integer(forKey: "weatherProvider", forPath: USER_DEFAULTS_PATH)

            // MARK: Date Format Handling

            if let format = widgetID.config["dateFormat"] as? String {
                dateFormat = format
                timeFormat = timeFormats.firstIndex(of: format) ?? 0
            }

            // MARK: Network Choices Handling

            if let netUp = widgetID.config["isUp"] as? Bool {
                networkUp = netUp ? 1 : 0
            }
            if let icon = widgetID.config["speedIcon"] as? Int {
                speedIcon = icon
            }
            if let unit = widgetID.config["minUnit"] as? Int {
                minUnit = unit
            }
            hideSpeedWhenZero = widgetID.config["hideSpeedWhenZero"] as? Bool ?? false

            // MARK: Temperature Unit Handling

            if widgetID.config["useFahrenheit"] as? Bool ?? false == true {
                useFahrenheit = 1
            }

            // MARK: Battery Value Type Handling

            if let batteryType = widgetID.config["batteryValueType"] as? Int {
                batteryValueType = batteryType
            }
            if let format = widgetID.config["text"] as? String {
                text = format
            }
            showPercentage = widgetID.config["showPercentage"] as? Bool ?? true
            filledSymbol = widgetID.config["filled"] as? Bool ?? true

            // MARK: Weather Handling

            if let format = widgetID.config["format"] as? String {
                weatherFormat = format
            }
            if let use = widgetID.config["useMetric"] as? Bool {
                useMetric = use ? 0 : 1
            }
            if let format = widgetID.config["location"] as? String {
                location = format
            }
            useCurrentLocation = widgetID.config["useCurrentLocation"] as? Bool ?? false

            // MARK: Lyrics Handling

            if let unsupp = widgetID.config["unsupported"] as? Int {
                unsupported = unsupp
            }
            if let ltype = widgetID.config["unLyricsType"] as? Int {
                unLyricsType = ltype
            }
            if let btype = widgetID.config["unBluetoothType"] as? Int {
                unBluetoothType = btype
            }
            if let wtype = widgetID.config["unWiredType"] as? Int {
                unWiredType = wtype
            }

            if let supp = widgetID.config["supported"] as? Int {
                supported = supp
            }
            if let ltype = widgetID.config["lyricsType"] as? Int {
                lyricsType = ltype
            }
            if let btype = widgetID.config["bluetoothType"] as? Int {
                bluetoothType = btype
            }
            if let wtype = widgetID.config["wiredType"] as? Int {
                wiredType = wtype
            }

            // MARK: CPU&MEM Handling

            if let dtype = widgetID.config["displayType"] as? Int {
                displayType = dtype
            }
        }
        .onDisappear {
            if modified {
                UIApplication.shared.confirmAlert(title: NSLocalizedString("Save Changes", comment: ""), body: NSLocalizedString("Would you like to save changes to the widget?", comment: ""), onOK: {
                    saveChanges()
                }, noCancel: false)
            }
        }
    }

    func getFormattedDate(_ format: String) -> String {
        let locale = UserDefaults.standard.string(forKey: "dateLocale", forPath: USER_DEFAULTS_PATH) ?? "en"
        dateFormatter.locale = Locale(identifier: locale)
        dateFormatter.dateFormat = format
        // dateFormatter.locale = Locale(identifier: NSLocalizedString("en_US", comment:""))
        return dateFormatter.string(from: currentDate)
    }

    func saveChanges() {
        var widgetStruct: WidgetIDStruct = .init(id: widgetID.id, module: widgetID.module, config: widgetID.config)

        switch widgetStruct.module {
        case .dateWidget:

            // MARK: Date Format Handling

            if dateFormat == "" {
                widgetStruct.config["dateFormat"] = nil
            } else {
                widgetStruct.config["dateFormat"] = dateFormat
            }
        case .textWidget:

            // MARK: Custom Text Handling

            if text == "" {
                widgetStruct.config["text"] = nil
            } else {
                widgetStruct.config["text"] = text
            }
        case .network:

            // MARK: Network Choices Handling

            widgetStruct.config["isUp"] = networkUp == 1 ? true : false
            widgetStruct.config["speedIcon"] = speedIcon
            widgetStruct.config["minUnit"] = minUnit
            widgetStruct.config["hideSpeedWhenZero"] = hideSpeedWhenZero
        case .temperature:

            // MARK: Temperature Unit Handling

            widgetStruct.config["useFahrenheit"] = useFahrenheit == 1 ? true : false
        case .battery:

            // MARK: Battery Value Type Handling

            widgetStruct.config["batteryValueType"] = batteryValueType
        case .timeWidget:

            // MARK: Time Format Handling

            widgetStruct.config["dateFormat"] = timeFormats[timeFormat]
        case .currentCapacity:

            // MARK: Current Capacity Handling

            widgetStruct.config["showPercentage"] = showPercentage
        case .chargeSymbol:

            // MARK: Charge Symbol Fill Handling

            widgetStruct.config["filled"] = filledSymbol
        case .weather:

            // MARK: Weather Handling

            widgetStruct.config["useFahrenheit"] = useFahrenheit == 1 ? true : false
            widgetStruct.config["useMetric"] = useMetric == 0 ? true : false
            if weatherFormat == "" {
                widgetStruct.config["format"] = nil
            } else {
                widgetStruct.config["format"] = weatherFormat
            }
            if location == "" {
                widgetStruct.config["location"] = nil
            } else {
                widgetStruct.config["location"] = location
            }
            widgetStruct.config["useCurrentLocation"] = useCurrentLocation
        case .lyrics:

            // MARK: Lyrics Handling

            widgetStruct.config["unsupported"] = unsupported
            widgetStruct.config["unLyricsType"] = unLyricsType
            widgetStruct.config["unBluetoothType"] = unBluetoothType
            widgetStruct.config["unWiredType"] = unWiredType

            widgetStruct.config["supported"] = supported
            widgetStruct.config["lyricsType"] = lyricsType
            widgetStruct.config["bluetoothType"] = bluetoothType
            widgetStruct.config["wiredType"] = wiredType
        case .cpumen:

            // MARK: CPU&MEM Handling

            widgetStruct.config["displayType"] = displayType
//        default:
//            return
        }

        widgetManager.updateWidgetConfig(widgetSet: widgetSet, id: widgetID, newID: widgetStruct)
        widgetID.config = widgetStruct.config
        modified = false
    }
}

struct Location: Identifiable {
    var id = UUID()
    var name: String?
    var country: String?
    var province: String?
    var city: String?
    var area: String?
    var location: CLLocation?
}

struct WeatherLocationView: View {
    @State var searchString = ""
    @Binding var location: String
    @Binding var modified: Bool
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State var locations: [Location] = []

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    if #available(iOS 15.0, *) {
                        TextField("", text: $searchString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                search()
                            }
                    } else {
                        TextField("", text: $searchString, onCommit: {
                            search()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    Button(NSLocalizedString("Search", comment: "")) {
                        search()
                        hideKeyboard()
                    }
                }
                .padding()
                Spacer()
                List(locations) { item in
                    ListCell(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let loc = item.location!
                            self.location = "\(loc.coordinate.longitude),\(loc.coordinate.latitude)"
                            modified = true
                            presentationMode.wrappedValue.dismiss()
                        }
                }
                .listStyle(PlainListStyle())
                .padding(.vertical, 0)
                .navigationBarTitle(Text(NSLocalizedString("Get Location ID", comment: "")))
            }
        }
    }

    func search() {
        if !searchString.isEmpty {
            DispatchQueue.global().async {
                locations.removeAll()
                let array = WeatherUtils.getGeocodeByName(searchString)
                // let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                // if json["status"] as? String == "1" {
                //     let array = json["geocodes"] as! [Dictionary<String, Any>]
                //     for item in array {
                //         let name = item["formatted_address"] as! String
                //         let country = item["country"] as! String
                //         let province = item["province"] as! String
                //         let city = item["city"] as! String
                //         let location = item["location"] as! String
                //         locations.append(Location(name: name, country: country, province: province, city: city, location: location))
                //     }
                // }
                if array != nil {
                    for item in array! {
                        let l = item as! CLPlacemark
                        locations.append(Location(name: l.name, country: l.country, province: l.administrativeArea, city: l.locality, area: l.subLocality, location: l.location))
                    }
                }
            }
        }
    }
}

struct ListCell: View {
    var item: Location

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(item.name ?? "--"),\(item.area ?? "--"),\(item.city ?? "--"),\(item.province ?? "--"),\(item.country ?? "--")")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            HStack {
                Text("\(item.location!.coordinate.longitude),\(item.location!.coordinate.latitude)")
                    .lineLimit(1)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
}

#if canImport(UIKit)
    extension View {
        func hideKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
#endif